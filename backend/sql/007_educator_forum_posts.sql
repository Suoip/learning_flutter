-- Educator-authored forum posts for SmartAcademy (idempotent)
-- Run after 006_educator_videos.sql - reuses public.set_updated_at(),
-- defined in 001_notes_profiles_storage.sql.
--
-- Same shape/rationale as educator_videos: educator_id references
-- public.educators(id), not auth.users(id) directly, so a row can only
-- exist once the owning account is already a real educator.

create table if not exists public.educator_forum_posts (
  id uuid primary key default gen_random_uuid(),
  educator_id uuid not null references public.educators(id) on delete cascade,
  title text not null default '',
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists educator_forum_posts_educator_updated_idx
  on public.educator_forum_posts (educator_id, updated_at desc);

drop trigger if exists trg_educator_forum_posts_set_updated_at on public.educator_forum_posts;
create trigger trg_educator_forum_posts_set_updated_at
before update on public.educator_forum_posts
for each row execute function public.set_updated_at();

alter table public.educator_forum_posts enable row level security;

drop policy if exists "educator_forum_posts_select_own" on public.educator_forum_posts;
create policy "educator_forum_posts_select_own"
on public.educator_forum_posts
for select
using (auth.uid() = educator_id);

drop policy if exists "educator_forum_posts_insert_own" on public.educator_forum_posts;
create policy "educator_forum_posts_insert_own"
on public.educator_forum_posts
for insert
with check (auth.uid() = educator_id);

drop policy if exists "educator_forum_posts_update_own" on public.educator_forum_posts;
create policy "educator_forum_posts_update_own"
on public.educator_forum_posts
for update
using (auth.uid() = educator_id)
with check (auth.uid() = educator_id);

drop policy if exists "educator_forum_posts_delete_own" on public.educator_forum_posts;
create policy "educator_forum_posts_delete_own"
on public.educator_forum_posts
for delete
using (auth.uid() = educator_id);
