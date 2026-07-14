-- Notes + Profiles + Avatar Storage bootstrap (idempotent)
-- Run in Supabase SQL editor for your project.

create extension if not exists pgcrypto;

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  is_pinned boolean not null default false,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format_check
    check (username ~ '^[a-zA-Z0-9_.-]{3,30}$')
);

alter table public.notes
  add column if not exists id uuid,
  add column if not exists user_id uuid,
  add column if not exists title text,
  add column if not exists content text,
  add column if not exists is_pinned boolean,
  add column if not exists is_favorite boolean,
  add column if not exists created_at timestamptz,
  add column if not exists updated_at timestamptz;

alter table public.notes
  alter column id set default gen_random_uuid(),
  alter column title set default '',
  alter column content set default '',
  alter column is_pinned set default false,
  alter column is_favorite set default false,
  alter column created_at set default now(),
  alter column updated_at set default now();

update public.notes
set
  id = coalesce(id, gen_random_uuid()),
  title = coalesce(title, ''),
  content = coalesce(content, ''),
  is_pinned = coalesce(is_pinned, false),
  is_favorite = coalesce(is_favorite, false),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.notes
  alter column id set not null,
  alter column user_id set not null,
  alter column title set not null,
  alter column content set not null,
  alter column is_pinned set not null,
  alter column is_favorite set not null,
  alter column created_at set not null,
  alter column updated_at set not null;

alter table public.profiles
  add column if not exists id uuid,
  add column if not exists username text,
  add column if not exists avatar_url text,
  add column if not exists created_at timestamptz,
  add column if not exists updated_at timestamptz;

alter table public.profiles
  alter column created_at set default now(),
  alter column updated_at set default now();

update public.profiles
set
  username = coalesce(
    nullif(username, ''),
    lower(split_part(coalesce((select email from auth.users where id = profiles.id), ''), '@', 1)),
    'user_' || left(id::text, 8)
  ),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.profiles
  alter column id set not null,
  alter column username set not null,
  alter column created_at set not null,
  alter column updated_at set not null;

create unique index if not exists profiles_username_unique_idx
  on public.profiles (username);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_username_format_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_username_format_check
      check (username ~ '^[a-zA-Z0-9_.-]{3,30}$');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'notes_pkey'
      and conrelid = 'public.notes'::regclass
  ) then
    alter table public.notes
      add constraint notes_pkey primary key (id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'notes_user_id_fkey'
      and conrelid = 'public.notes'::regclass
  ) then
    alter table public.notes
      add constraint notes_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_pkey'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_pkey primary key (id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_id_fkey'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_id_fkey
      foreign key (id) references auth.users(id) on delete cascade;
  end if;
end
$$;

create index if not exists notes_user_updated_idx
  on public.notes (user_id, updated_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_notes_set_updated_at on public.notes;
create trigger trg_notes_set_updated_at
before update on public.notes
for each row execute function public.set_updated_at();

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  fallback_username text;
begin
  fallback_username := lower(split_part(coalesce(new.email, ''), '@', 1));
  if fallback_username = '' then
    fallback_username := 'user_' || left(new.id::text, 8);
  end if;

  insert into public.profiles (id, username)
  values (new.id, fallback_username)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.notes enable row level security;
alter table public.profiles enable row level security;

drop policy if exists "notes_select_own" on public.notes;
create policy "notes_select_own"
on public.notes
for select
using (auth.uid() = user_id);

drop policy if exists "notes_insert_own" on public.notes;
create policy "notes_insert_own"
on public.notes
for insert
with check (auth.uid() = user_id);

drop policy if exists "notes_update_own" on public.notes;
create policy "notes_update_own"
on public.notes
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "notes_delete_own" on public.notes;
create policy "notes_delete_own"
on public.notes
for delete
using (auth.uid() = user_id);

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
on public.profiles
for select
using (auth.uid() is not null);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-pictures',
  'profile-pictures',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "profile_pictures_select_public" on storage.objects;
create policy "profile_pictures_select_public"
on storage.objects
for select
using (bucket_id = 'profile-pictures');

drop policy if exists "profile_pictures_insert_own" on storage.objects;
create policy "profile_pictures_insert_own"
on storage.objects
for insert
with check (
  bucket_id = 'profile-pictures'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "profile_pictures_update_own" on storage.objects;
create policy "profile_pictures_update_own"
on storage.objects
for update
using (
  bucket_id = 'profile-pictures'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'profile-pictures'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "profile_pictures_delete_own" on storage.objects;
create policy "profile_pictures_delete_own"
on storage.objects
for delete
using (
  bucket_id = 'profile-pictures'
  and auth.uid()::text = (storage.foldername(name))[1]
);
