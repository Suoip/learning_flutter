-- Educator profile editing: avatar column + avatar storage bootstrap (idempotent)
-- Run after 007_educator_forum_posts.sql. Reuses public.set_updated_at()
-- (trigger already attached to public.educators in 005_educators.sql) and
-- mirrors the profile-pictures bucket/RLS shape from
-- 001_notes_profiles_storage.sql, scoped to a separate 'educator-avatars'
-- bucket and public.educators instead of public.profiles.

alter table public.educators
  add column if not exists avatar_url text;

-- No changes to public.educators' existing RLS policies (educators_select_own/
-- educators_insert_own/educators_update_own, all `auth.uid() = id`, defined
-- in 005_educators.sql): RLS policies are row-level, not column-level, so the
-- new nullable column is automatically covered by every existing policy.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'educator-avatars',
  'educator-avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "educator_avatars_select_public" on storage.objects;
create policy "educator_avatars_select_public"
on storage.objects
for select
using (bucket_id = 'educator-avatars');

drop policy if exists "educator_avatars_insert_own" on storage.objects;
create policy "educator_avatars_insert_own"
on storage.objects
for insert
with check (
  bucket_id = 'educator-avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "educator_avatars_update_own" on storage.objects;
create policy "educator_avatars_update_own"
on storage.objects
for update
using (
  bucket_id = 'educator-avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'educator-avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "educator_avatars_delete_own" on storage.objects;
create policy "educator_avatars_delete_own"
on storage.objects
for delete
using (
  bucket_id = 'educator-avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);
