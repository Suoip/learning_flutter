-- Comments and likes on SmartAcademy forum posts (idempotent)
-- Run after 009_educator_public_read.sql. Mirrors shared_note_likes/
-- shared_note_comments' shape, simplified: no friend/recipient visibility
-- check needed since the parent educator_forum_posts row is already
-- unconditionally public. user_id references auth.users(id) directly (not
-- educators/profiles) since any signed-in account - Notes user or educator
-- - is eligible to comment/like.

create table if not exists public.educator_forum_post_likes (
  forum_post_id uuid not null references public.educator_forum_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (forum_post_id, user_id)
);

create table if not exists public.educator_forum_post_comments (
  id uuid primary key default gen_random_uuid(),
  forum_post_id uuid not null references public.educator_forum_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  created_at timestamptz not null default now()
);

create index if not exists educator_forum_post_comments_post_created_idx
  on public.educator_forum_post_comments (forum_post_id, created_at asc);

alter table public.educator_forum_post_likes enable row level security;
alter table public.educator_forum_post_comments enable row level security;

-- Defensive GRANTs, same rationale as 009: this project's Supabase defaults
-- don't auto-expose new tables to Data API roles without an explicit GRANT.
-- anon is intentionally excluded from insert/update/delete - auth.uid() is
-- always null for anon, so it could never satisfy these policies' WITH
-- CHECK/USING clauses regardless of grants.
grant select on public.educator_forum_post_likes, public.educator_forum_post_comments
  to anon, authenticated;
grant insert, delete on public.educator_forum_post_likes to authenticated;
grant insert, update, delete on public.educator_forum_post_comments to authenticated;

drop policy if exists "educator_forum_post_likes_select_public" on public.educator_forum_post_likes;
create policy "educator_forum_post_likes_select_public"
on public.educator_forum_post_likes
for select
using (true);

drop policy if exists "educator_forum_post_likes_insert_self" on public.educator_forum_post_likes;
create policy "educator_forum_post_likes_insert_self"
on public.educator_forum_post_likes
for insert
with check (auth.uid() = user_id);

drop policy if exists "educator_forum_post_likes_delete_self" on public.educator_forum_post_likes;
create policy "educator_forum_post_likes_delete_self"
on public.educator_forum_post_likes
for delete
using (auth.uid() = user_id);

drop policy if exists "educator_forum_post_comments_select_public" on public.educator_forum_post_comments;
create policy "educator_forum_post_comments_select_public"
on public.educator_forum_post_comments
for select
using (true);

drop policy if exists "educator_forum_post_comments_insert_self" on public.educator_forum_post_comments;
create policy "educator_forum_post_comments_insert_self"
on public.educator_forum_post_comments
for insert
with check (auth.uid() = user_id);

drop policy if exists "educator_forum_post_comments_update_self" on public.educator_forum_post_comments;
create policy "educator_forum_post_comments_update_self"
on public.educator_forum_post_comments
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "educator_forum_post_comments_delete_self" on public.educator_forum_post_comments;
create policy "educator_forum_post_comments_delete_self"
on public.educator_forum_post_comments
for delete
using (auth.uid() = user_id);
