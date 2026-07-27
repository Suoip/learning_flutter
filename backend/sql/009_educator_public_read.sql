-- Public read access for educator channel pages (idempotent)
-- Run after 008_educator_profile.sql.
--
-- Lets anyone - including a fully anonymous/unauthenticated visitor - view
-- an educator's public identity and content. Required for the public
-- educator channel page and the hub's educator-search lookup. Write access
-- is unchanged (still owner-only via the insert/update/delete policies from
-- 005/006/007).
--
-- Defensive GRANTs: this project's local supabase/config.toml shows
-- auto_expose_new_tables unset (new-default behavior does not auto-grant
-- anon/authenticated Data API access without an explicit GRANT), and the
-- actual remote project's grant state can't be confirmed from the repo.
-- Harmless no-op if these roles already have SELECT.

grant select on public.educators, public.educator_videos, public.educator_forum_posts
  to anon, authenticated;

drop policy if exists "educators_select_own" on public.educators;
drop policy if exists "educators_select_public" on public.educators;
create policy "educators_select_public"
on public.educators
for select
using (true);

drop policy if exists "educator_videos_select_own" on public.educator_videos;
drop policy if exists "educator_videos_select_public" on public.educator_videos;
create policy "educator_videos_select_public"
on public.educator_videos
for select
using (true);

drop policy if exists "educator_forum_posts_select_own" on public.educator_forum_posts;
drop policy if exists "educator_forum_posts_select_public" on public.educator_forum_posts;
create policy "educator_forum_posts_select_public"
on public.educator_forum_posts
for select
using (true);
