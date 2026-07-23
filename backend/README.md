# Backend setup (Supabase)

The Notes app now depends on:

1. `public.notes`
2. `public.profiles` (with `avatar_url`)
3. Storage bucket `profile-pictures`
4. RLS + storage policies

Run this SQL in your Supabase project SQL editor:

`backend/sql/001_notes_profiles_storage.sql`
`backend/sql/002_social_friends_and_shared_notes.sql`
`backend/sql/003_friendships_delete_policy.sql`
`backend/sql/004_shared_notes_recipients_redesign.sql` (**destructive** - drops and recreates `shared_notes`, `shared_note_likes`, and `shared_note_comments`; existing published-notes/likes/comments test data is lost)

## Required Supabase Auth settings

1. Auth -> Providers -> Email:
   - Enable provider.
   - Turn **Confirm email** ON.
   - Configure SMTP (custom SMTP provider) so confirmation emails can be delivered to real user inboxes.
2. Auth -> URL Configuration:
   - Add your confirmation redirect URL to **Redirect URLs**.
   - Use the same URL in app env as `SUPABASE_EMAIL_REDIRECT_TO`.
3. Auth -> Templates -> Confirm signup:
   - Keep `{{ .ConfirmationURL }}` in the template body.
4. App flow:
   - New registrations use real email + username.
   - Login is email/password.
   - Profile rows are created from username metadata.

## What this SQL config includes

- Idempotent creation of Notes/Profile tables
- Username constraint (`3-30`, `[a-zA-Z0-9_.-]`)
- `updated_at` triggers
- Auto profile creation trigger on `auth.users` insert
- RLS for notes/profiles (each user only touches their own data)
- Public bucket for profile pictures with folder-based ownership policies (`<user_id>/...`)
- Social model tables: friend requests, friendships, shared notes, likes, comments
- RLS for social features so feed is read-only for recipients and editable by authors only
- RLS delete policy so either member of a friendship can unfriend (remove) it
- `shared_notes` redesigned to one row per published note (not per recipient), with a `shared_note_recipients` join table, so likes/comments aggregate correctly and the author can see engagement on their own posts
