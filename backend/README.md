# Backend setup (Supabase)

The Notes app now depends on:

1. `public.notes`
2. `public.profiles` (with `avatar_url`)
3. Storage bucket `profile-pictures`
4. RLS + storage policies

Run this SQL in your Supabase project SQL editor:

`backend/sql/001_notes_profiles_storage.sql`

## Required Supabase Auth settings

- Email confirmation should be disabled for this username/password flow, because usernames are mapped to synthetic emails (`<username>@notesapp.dev`).

## What this SQL config includes

- Idempotent creation of Notes/Profile tables
- Username constraint (`3-30`, `[a-zA-Z0-9_.-]`)
- `updated_at` triggers
- Auto profile creation trigger on `auth.users` insert
- RLS for notes/profiles (each user only touches their own data)
- Public bucket for profile pictures with folder-based ownership policies (`<user_id>/...`)
