# Backend setup (Supabase)

This project's Supabase backend depends on:

1. `public.notes`
2. `public.profiles` (with `avatar_url`)
3. Storage bucket `profile-pictures`
4. RLS + storage policies
5. `public.educators` (SmartAcademy's educator accounts - separate table/RLS from Notes' `profiles`, sharing the same `auth.users` pool)
6. `public.educator_videos` (SmartAcademy educator-authored video metadata, RLS scoped to the owning educator)
7. `public.educator_forum_posts` (SmartAcademy educator-authored forum posts, RLS scoped to the owning educator)

Run this SQL in your Supabase project SQL editor:

`backend/sql/001_notes_profiles_storage.sql`
`backend/sql/002_social_friends_and_shared_notes.sql`
`backend/sql/003_friendships_delete_policy.sql`
`backend/sql/004_shared_notes_recipients_redesign.sql` (**destructive** - drops and recreates `shared_notes`, `shared_note_likes`, and `shared_note_comments`; existing published-notes/likes/comments test data is lost)
`backend/sql/005_educators.sql` (adds `public.educators` and rewrites `handle_new_auth_user()` to branch on a new `app` signup-metadata tag; safe to run against existing data - existing Notes signups have no `app` tag and fall through to the unchanged Notes/profiles branch)
`backend/sql/006_educator_videos.sql` (adds `public.educator_videos`; safe to run against existing data, purely additive)
`backend/sql/007_educator_forum_posts.sql` (adds `public.educator_forum_posts`; safe to run against existing data, purely additive)
`backend/sql/012_feed_read_state.sql` (adds `public.feed_read_state`, tracking when each user last viewed their Notes friends feed for the unseen-post badge; safe to run against existing data, purely additive)

## Required Supabase Auth settings

1. Auth -> Providers -> Email:
   - Enable provider.
   - Turn **Confirm email** ON.
   - Configure SMTP (custom SMTP provider) so confirmation emails can be delivered to real user inboxes.
2. Auth -> URL Configuration:
   - Add your confirmation redirect URL to **Redirect URLs**.
   - Use the same URL in app env as `SUPABASE_EMAIL_REDIRECT_TO`.
   - This needs a separate entry **per platform**: the web dev/prod URLs, and also the mobile deep-link scheme from the Makefile's `MOBILE_EMAIL_REDIRECT_TO` (default `com.example.new_project://login-callback`, used automatically by `make build-apk`) - without this allow-listed too, password-reset/signup-confirmation links opened from the Android app will fail.
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
- Educator accounts (`public.educators`) for SmartAcademy, gated through the same `auth.users` trigger via an `app` metadata tag (`'notes'` vs `'smart_academy'`), so one Supabase Auth pool serves both features without cross-creating profile/educator rows
- Educator-authored video content (`public.educator_videos`), RLS scoped to the owning educator via a foreign key to `public.educators`
- Educator-authored forum posts (`public.educator_forum_posts`), same ownership/RLS shape as `educator_videos`
