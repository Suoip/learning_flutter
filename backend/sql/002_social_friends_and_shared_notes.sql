-- Social layer bootstrap: friends, requests, shared feed, likes, comments
-- Run after 001_notes_profiles_storage.sql

create extension if not exists pgcrypto;

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (sender_id <> receiver_id)
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_low_id uuid not null references auth.users(id) on delete cascade,
  user_high_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_low_id < user_high_id),
  unique (user_low_id, user_high_id)
);

create table if not exists public.shared_notes (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.notes(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  published_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (author_id <> recipient_id),
  unique (note_id, author_id, recipient_id)
);

create table if not exists public.shared_note_likes (
  shared_note_id uuid not null references public.shared_notes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (shared_note_id, user_id)
);

create table if not exists public.shared_note_comments (
  id uuid primary key default gen_random_uuid(),
  shared_note_id uuid not null references public.shared_notes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  created_at timestamptz not null default now()
);

create unique index if not exists friend_requests_pending_unique_idx
  on public.friend_requests (sender_id, receiver_id)
  where status = 'pending';

create index if not exists friend_requests_receiver_status_idx
  on public.friend_requests (receiver_id, status, created_at desc);

create index if not exists friend_requests_sender_status_idx
  on public.friend_requests (sender_id, status, created_at desc);

create index if not exists friendships_user_low_idx
  on public.friendships (user_low_id, created_at desc);

create index if not exists friendships_user_high_idx
  on public.friendships (user_high_id, created_at desc);

create index if not exists shared_notes_recipient_published_idx
  on public.shared_notes (recipient_id, published_at desc);

create index if not exists shared_notes_author_published_idx
  on public.shared_notes (author_id, published_at desc);

create index if not exists shared_note_comments_shared_note_created_idx
  on public.shared_note_comments (shared_note_id, created_at asc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_friend_requests_set_updated_at on public.friend_requests;
create trigger trg_friend_requests_set_updated_at
before update on public.friend_requests
for each row execute function public.set_updated_at();

drop trigger if exists trg_shared_notes_set_updated_at on public.shared_notes;
create trigger trg_shared_notes_set_updated_at
before update on public.shared_notes
for each row execute function public.set_updated_at();

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.shared_notes enable row level security;
alter table public.shared_note_likes enable row level security;
alter table public.shared_note_comments enable row level security;

drop policy if exists "friend_requests_select_self" on public.friend_requests;
create policy "friend_requests_select_self"
on public.friend_requests
for select
using (auth.uid() = sender_id or auth.uid() = receiver_id);

drop policy if exists "friend_requests_insert_sender" on public.friend_requests;
create policy "friend_requests_insert_sender"
on public.friend_requests
for insert
with check (auth.uid() = sender_id and sender_id <> receiver_id);

drop policy if exists "friend_requests_update_self" on public.friend_requests;
create policy "friend_requests_update_self"
on public.friend_requests
for update
using (auth.uid() = sender_id or auth.uid() = receiver_id)
with check (auth.uid() = sender_id or auth.uid() = receiver_id);

drop policy if exists "friendships_select_member" on public.friendships;
create policy "friendships_select_member"
on public.friendships
for select
using (auth.uid() = user_low_id or auth.uid() = user_high_id);

drop policy if exists "friendships_insert_member" on public.friendships;
create policy "friendships_insert_member"
on public.friendships
for insert
with check (auth.uid() = user_low_id or auth.uid() = user_high_id);

drop policy if exists "shared_notes_select_member" on public.shared_notes;
create policy "shared_notes_select_member"
on public.shared_notes
for select
using (auth.uid() = author_id or auth.uid() = recipient_id);

drop policy if exists "shared_notes_insert_author" on public.shared_notes;
create policy "shared_notes_insert_author"
on public.shared_notes
for insert
with check (auth.uid() = author_id and author_id <> recipient_id);

drop policy if exists "shared_notes_update_author" on public.shared_notes;
create policy "shared_notes_update_author"
on public.shared_notes
for update
using (auth.uid() = author_id)
with check (auth.uid() = author_id);

drop policy if exists "shared_notes_delete_author" on public.shared_notes;
create policy "shared_notes_delete_author"
on public.shared_notes
for delete
using (auth.uid() = author_id);

drop policy if exists "shared_note_likes_select_visible" on public.shared_note_likes;
create policy "shared_note_likes_select_visible"
on public.shared_note_likes
for select
using (
  exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_likes.shared_note_id
      and (sn.author_id = auth.uid() or sn.recipient_id = auth.uid())
  )
);

drop policy if exists "shared_note_likes_insert_self" on public.shared_note_likes;
create policy "shared_note_likes_insert_self"
on public.shared_note_likes
for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_likes.shared_note_id
      and (sn.author_id = auth.uid() or sn.recipient_id = auth.uid())
  )
);

drop policy if exists "shared_note_likes_delete_self" on public.shared_note_likes;
create policy "shared_note_likes_delete_self"
on public.shared_note_likes
for delete
using (auth.uid() = user_id);

drop policy if exists "shared_note_comments_select_visible" on public.shared_note_comments;
create policy "shared_note_comments_select_visible"
on public.shared_note_comments
for select
using (
  exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_comments.shared_note_id
      and (sn.author_id = auth.uid() or sn.recipient_id = auth.uid())
  )
);

drop policy if exists "shared_note_comments_insert_self" on public.shared_note_comments;
create policy "shared_note_comments_insert_self"
on public.shared_note_comments
for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_comments.shared_note_id
      and (sn.author_id = auth.uid() or sn.recipient_id = auth.uid())
  )
);

drop policy if exists "shared_note_comments_update_self" on public.shared_note_comments;
create policy "shared_note_comments_update_self"
on public.shared_note_comments
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "shared_note_comments_delete_self" on public.shared_note_comments;
create policy "shared_note_comments_delete_self"
on public.shared_note_comments
for delete
using (auth.uid() = user_id);
