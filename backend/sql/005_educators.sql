-- Educator accounts for SmartAcademy (idempotent)
-- Run after 001_notes_profiles_storage.sql - reuses public.set_updated_at()
-- and rewrites public.handle_new_auth_user(), both defined there.

create table if not exists public.educators (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint educators_username_format_check
    check (username ~ '^[a-zA-Z0-9_.-]{3,30}$')
);

drop trigger if exists trg_educators_set_updated_at on public.educators;
create trigger trg_educators_set_updated_at
before update on public.educators
for each row execute function public.set_updated_at();

-- Rewrites the shared auth.users trigger function from
-- 001_notes_profiles_storage.sql to branch on the `app` tag written into
-- raw_user_meta_data at sign-up time ('notes' from NotesLogic.signUpWithUsername,
-- 'smart_academy' from EducatorLogic.signUpWithUsername). Only the function
-- body changes - on_auth_user_created's trigger-to-function binding is by
-- name, so the existing trigger does not need to be dropped/recreated.
--
-- Every signup that predates this tag (all pre-existing Notes accounts) -
-- and any signup that somehow omits it - has raw_user_meta_data->>'app' =
-- null, which falls through to the `else` branch below and is treated as
-- Notes, preserving today's behavior exactly. An unrecognized tag value
-- (neither 'notes' nor 'smart_academy') falls through to that same else
-- branch too, rather than raising - a bad/unexpected tag must never be able
-- to block the auth.users insert this trigger runs on.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  fallback_username text;
  signup_app text;
begin
  fallback_username := lower(trim(coalesce(new.raw_user_meta_data->>'username', '')));
  if fallback_username = '' then
    fallback_username := lower(split_part(coalesce(new.email, ''), '@', 1));
  end if;
  if fallback_username = '' then
    fallback_username := 'user_' || left(new.id::text, 8);
  end if;

  signup_app := lower(trim(coalesce(new.raw_user_meta_data->>'app', '')));

  if signup_app = 'smart_academy' then
    insert into public.educators (id, username)
    values (new.id, fallback_username)
    on conflict (id) do nothing;
  else
    insert into public.profiles (id, username)
    values (new.id, fallback_username)
    on conflict (id) do nothing;
  end if;

  return new;
end;
$$;

alter table public.educators enable row level security;

drop policy if exists "educators_select_own" on public.educators;
create policy "educators_select_own"
on public.educators
for select
using (auth.uid() = id);

drop policy if exists "educators_insert_own" on public.educators;
create policy "educators_insert_own"
on public.educators
for insert
with check (auth.uid() = id);

drop policy if exists "educators_update_own" on public.educators;
create policy "educators_update_own"
on public.educators
for update
using (auth.uid() = id)
with check (auth.uid() = id);
