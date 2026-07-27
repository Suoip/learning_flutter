-- Educator-authored video content for SmartAcademy (idempotent)
-- Run after 005_educators.sql - reuses public.set_updated_at(), defined in
-- 001_notes_profiles_storage.sql.
--
-- educator_id references public.educators(id), not auth.users(id) directly
-- (unlike notes.user_id): a row can only exist once the owning account is
-- already a real educator, enforced at the FK level - "only educators can
-- own video content" as a data-integrity guarantee, not just an app-level
-- rule. Since public.educators.id IS auth.users.id for that account,
-- `auth.uid() = educator_id` in the policies below still works identically
-- either way.

create table if not exists public.educator_videos (
  id uuid primary key default gen_random_uuid(),
  educator_id uuid not null references public.educators(id) on delete cascade,
  title text not null default '',
  description text not null default '',
  duration_label text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists educator_videos_educator_updated_idx
  on public.educator_videos (educator_id, updated_at desc);

drop trigger if exists trg_educator_videos_set_updated_at on public.educator_videos;
create trigger trg_educator_videos_set_updated_at
before update on public.educator_videos
for each row execute function public.set_updated_at();

alter table public.educator_videos enable row level security;

drop policy if exists "educator_videos_select_own" on public.educator_videos;
create policy "educator_videos_select_own"
on public.educator_videos
for select
using (auth.uid() = educator_id);

drop policy if exists "educator_videos_insert_own" on public.educator_videos;
create policy "educator_videos_insert_own"
on public.educator_videos
for insert
with check (auth.uid() = educator_id);

drop policy if exists "educator_videos_update_own" on public.educator_videos;
create policy "educator_videos_update_own"
on public.educator_videos
for update
using (auth.uid() = educator_id)
with check (auth.uid() = educator_id);

drop policy if exists "educator_videos_delete_own" on public.educator_videos;
create policy "educator_videos_delete_own"
on public.educator_videos
for delete
using (auth.uid() = educator_id);
