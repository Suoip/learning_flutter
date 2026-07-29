-- Feed read-state tracking: when did each user last view their friends feed
-- (backs the unseen-post-count badge). Run after
-- 011_educator_video_engagement.sql.
--
-- Brand new, single-user-owned table with no relationship to any other
-- RLS-sensitive table, so the shared_notes/shared_note_recipients circular-
-- RLS concern from 004_shared_notes_recipients_redesign.sql (and its
-- SECURITY DEFINER workaround) does not apply here.
--
-- Primary-keyed directly by user_id (exactly one row per user, always
-- upserted onto user_id - never multiple rows per user). No delete policy:
-- rows are only ever removed via `on delete cascade` when the owning
-- auth.users row is deleted, mirroring public.profiles/public.educators,
-- which also omit a delete policy for the same reason.

create table if not exists public.feed_read_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_seen_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_feed_read_state_set_updated_at on public.feed_read_state;
create trigger trg_feed_read_state_set_updated_at
before update on public.feed_read_state
for each row execute function public.set_updated_at();

alter table public.feed_read_state enable row level security;

-- Defensive GRANTs, same rationale as 009/010/011: this project's
-- supabase/config.toml leaves auto_expose_new_tables unset, so new tables
-- are not auto-exposed to Data API roles without an explicit GRANT - this
-- applies to any new table, not just ones opening public/anon read (see
-- 010/011, which grant to owner-scoped tables too). anon is intentionally
-- excluded entirely: every policy below checks auth.uid() = user_id, and
-- auth.uid() is always null for anon, so an anon grant would be a no-op it
-- could never use.
grant select, insert, update on public.feed_read_state to authenticated;

drop policy if exists "feed_read_state_select_own" on public.feed_read_state;
create policy "feed_read_state_select_own"
on public.feed_read_state
for select
using (auth.uid() = user_id);

drop policy if exists "feed_read_state_insert_own" on public.feed_read_state;
create policy "feed_read_state_insert_own"
on public.feed_read_state
for insert
with check (auth.uid() = user_id);

drop policy if exists "feed_read_state_update_own" on public.feed_read_state;
create policy "feed_read_state_update_own"
on public.feed_read_state
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
