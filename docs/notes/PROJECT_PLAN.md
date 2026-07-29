# Notes App — Project Plan

**Status:** Retroactive pre-project plan, written after extensive development (PR #1–#28+) to
formalize direction for everything ahead. Where this doc describes something already shipped,
that's noted explicitly — treat those sections as "confirm this is still true" rather than
"design from scratch."

This document is written to be **fully self-contained**: Part I is the high-level plan (vision,
goals, roadmap); Part II is an exhaustive specification of every screen, field, validation rule,
data table, and business rule, detailed enough that someone who has never opened the codebase
could understand exactly how the app behaves.

---

# PART I — HIGH-LEVEL PLAN

## 1. Vision

Notes is the flagship mini-project in the `learning_flutter` app: a personal note-taking app with
a social layer. A user writes private notes, organizes them (pin/favorite), and can optionally
publish a note to share with friends — who can then like and comment on it, feed-style. It's the
original project the rest of the app's engineering patterns (testable business logic via a
`*Logic` + `*DataSource` pair, Supabase auth/RLS conventions, the dark theme system) were
established on, and later reused by SmartAcademy.

## 2. Problem / motivation

This is a learning repo — the motivation is to practice building a realistic full-stack CRUD app
with auth, authorization, and a social graph (friends, shared content, engagement) on top of
Supabase, and to keep it maintainable as it grows through many small, sequential PRs. There is no
external user base; scope and sequencing are driven by what's useful to build and learn next,
decided collaboratively PR by PR, informed by periodic feature audits of what a real user would
expect.

## 3. Goals

- Let a user register, log in, and manage their own private notes (create/edit/delete, pin,
  favorite, search/filter).
- Let a user build a friend graph: send/accept/decline/cancel requests, unfriend.
- Let a user publish a note to share with all their friends, and see a combined feed of their own
  and friends' published notes.
- Let feed participants like and comment on published notes.
- Support the full account lifecycle: signup with email confirmation, forgot/reset password,
  username/avatar/password changes.
- Work correctly on both web and mobile (Android), including email deep-link flows.

### Non-goals (for now)

- Rich text / attachments / images inside notes (plain text only).
- Real-time (live) feed or comment updates — data is fetched, not subscribed.
- Comment editing or deletion.
- Notifications for new likes/comments/friend requests beyond the incoming-friend-request badge.
- Account deletion (self-service).
- Public/discoverable notes beyond the friends-only feed (no global public feed, unlike
  SmartAcademy's hub model).
- Choosing a subset of friends to publish to — publishing always targets *all* current friends.

## 4. Target users

| Persona | Description | Needs |
|---|---|---|
| **Note-taker** | The default use case — someone using Notes purely privately. | Fast, reliable CRUD; pin/favorite/search to manage a growing list; never lose a note. |
| **Social publisher** | A note-taker who shares some notes with friends. | One-step publish, confidence that only friends see it, visibility into engagement on their own posts. |
| **Feed participant** | Anyone with friends who've published notes. | A combined feed (not fragmented per-friend), like/comment, manage the friend graph itself. |

## 5. Scope

### 5.1 In scope, already shipped

- **Auth** — signup with username, email confirmation, login, self-service forgot/reset password
  (web and, unverified, Android deep links), sign-out, resend confirmation email.
- **Notes CRUD** — create/edit/delete, pin, favorite, search/filter (title only), backed by a
  testable `NotesDataSource`.
- **Profile** — username, avatar upload, password change.
- **Friends** — search by username, send request, accept/decline, cancel a sent request,
  unfriend, full duplicate/self-request/already-friends guard rails, incoming-request count badge.
- **Publishing & feed** — publish a note to all friends at once (one row per note, not one per
  recipient — redesigned in PR #13 to fix a duplication bug), a combined feed showing both your
  own and friends' published notes with "You" labeling for your own.
- **Engagement** — likes and comments on published/shared notes, inline display via a bottom
  sheet.
- **Dark theme** (Discord/Telegram-inspired design system) — applied app-wide; only the notes
  list screen itself has been fully migrated onto it so far.
- **Testing infrastructure** — the `NotesDataSource` pattern (Notes → Profiles → Friends → Feed →
  Auth) is complete across all five logic domains, ~300+ unit tests total using fakes.

### 5.2 In scope, not yet started / known gaps

- **View another user's profile** — tapping a friend's avatar currently does nothing. Identified
  as the next social feature to build (from a full feature audit before PR #9), not yet started.
- **Edit/delete your own posted comments** — no path exists today, at either the UI or the RLS
  layer beyond a raw delete policy (`shared_note_comments_delete_self` exists at the DB level, but
  no UI calls it).
- **Search notes by content**, not just title.
- **Self-service account deletion.**
- **Notifications for new likes/comments** on your own published notes (only the friend-request
  badge exists).
- **Choosing which friends to publish to** — currently all-or-nothing.
- **Verify PR #15's Android deep-link fix on a real device/emulator** — implemented but never
  actually tested on Android hardware; also confirm the mobile redirect URL is registered in the
  Supabase dashboard's allow-list.
- **UI redesign rollout** — the dark theme system exists and covers every component type Notes
  uses, but only the notes-list screen has been migrated; editor, social/feed/friends, and
  profile/auth screens are still on old, partly-hardcoded styling.
- **`updateUsername`/`uploadProfileAvatar` full-path unit test coverage** — only their
  signed-out/invalid-input guard clauses are unit-tested today; the real Supabase-touching paths
  are integration-tested only (a deliberate, accepted gap, not an oversight).

### 5.3 Explicitly out of scope

See Non-goals (§3). Additionally not planned: rich content, real-time sync, a public/global feed,
or comment moderation.

## 6. Feature breakdown

| Area | Capability | Status |
|---|---|---|
| Auth | Signup / login / email confirmation | ✅ Shipped |
| Auth | Forgot/reset password (web) | ✅ Shipped |
| Auth | Forgot/reset password (Android deep link) | ⚠️ Implemented, unverified on real hardware |
| Profile | Avatar, username, password | ✅ Shipped |
| Profile | View another user's profile | ⬜ Not started |
| Notes | CRUD, pin, favorite | ✅ Shipped |
| Notes | Search by title | ✅ Shipped |
| Notes | Search by content | ⬜ Not started |
| Friends | Search / send / accept / decline / cancel / unfriend | ✅ Shipped |
| Feed | Combined own + friends' published notes | ✅ Shipped |
| Feed | Likes | ✅ Shipped |
| Feed | Comments (bottom-sheet) | ✅ Shipped |
| Feed | Comment edit/delete | ⬜ Not started |
| Feed | Selective (not all-friends) publish | ⬜ Not started |
| Growth | Notifications (likes/comments) | ⬜ Not planned yet |
| Growth | Account deletion | ⬜ Not planned yet |
| UI | Dark theme system built | ✅ Shipped |
| UI | Dark theme rollout (editor/social/profile/auth) | ⬜ Partial — list screen only |

## 7. Key decisions already made (and why)

- **One `shared_notes` row per published note, not per recipient** — the original per-recipient
  model made the poster unable to see engagement on their own post and would have shown
  duplicate/fragmented feed cards. Redesigned in PR #13 into a note row (`shared_notes`) plus a
  recipients join table (`shared_note_recipients`) instead of patching around the original shape.
- **`friend_requests`/`friendships` status transitions reuse existing schema states** —
  e.g. cancel-a-sent-request uses a `'cancelled'` status the check constraint already allowed for
  but no code path used, avoiding an unnecessary migration.
- **Auth's decision logic is unit-tested via extracted pure functions, not a full fake client** —
  Supabase's `signUp`/`signInWithPassword` responses carry session/identity semantics that don't
  fake meaningfully; only the "what does this response mean" branching (`interpretSignUpResponse`,
  `shouldRejectSignIn`) was worth isolating into pure, testable functions.
- **Error messages match on Supabase's stable `code` field where possible, not message text** — a
  prior bug (same-password changes showing "Incorrect email or password") came from matching on
  message substrings; message text isn't a stable contract, error codes are (see the
  `same_password` special-case in `userMessageForError`).
- **Global dark theme applied at the MaterialApp root**, not scoped to Notes' navigator subtree —
  because `ResetPasswordPage` is pushed directly onto the root navigator for the password-recovery
  deep link, bypassing Notes' own navigation stack; a scoped theme override would've left that
  screen unthemed.
- **`SECURITY DEFINER` helper function for recipient-visibility RLS** — `is_shared_note_author()`
  exists purely to avoid a circular RLS reference (a recipients-select policy that needs to check
  "is this user the note's author" without triggering infinite recursion through `shared_notes`'
  own RLS).
- **Publishing always targets the entire friends list**, not a chosen subset — simpler model,
  accepted as a real limitation (see backlog).
- **Password-reset error messages are deliberately non-revealing** — `sendPasswordResetEmail`
  always appears to succeed, regardless of whether the email is registered, to avoid leaking
  account existence.

## 8. Risks & open questions

| Risk / question | Notes |
|---|---|
| Android deep-link flow unverified | No Android SDK/emulator available in the current dev environment; treat as implemented-but-unverified until tested on real hardware. |
| RLS bugs aren't caught by unit tests | Already happened once (PR #13's author-can't-see-own-shared-recipient-row bug) — only live testing surfaced it. Any new INSERT/UPDATE policy on a table an author needs to read back should be sanity-checked live, not just reviewed. |
| UI redesign is partial | Users see visibly inconsistent styling across notes screens until the rollout (editor → social/feed/friends → profile/auth) is finished; no timeline forces this, but it's a known rough edge. |
| No content search | Users with many notes can only search by title; may become a real usability gap as note counts grow. |
| Recipient insert has no DB-level friend check | `shared_note_recipients_insert_author` only verifies the inserter authored the shared note — it does *not* re-verify recipients are actually friends at the DB layer (an earlier check was removed while debugging the PR #13 RLS recursion issue). The only gate on "who can be a recipient" today is the app's own `fetchFriends()`-driven UI. Not currently exploitable through the app's own UI, but worth knowing if a new write path to `shared_note_recipients` is ever added. |

## 9. Suggested roadmap (next steps, unsequenced)

The user sequences PRs one at a time rather than committing to a fixed order; known candidates,
not a committed sequence:

1. View another user's (friend's) profile — the top item from the last full feature audit.
2. Finish the dark-theme rollout across editor/social/friends/profile/auth screens.
3. Comment edit/delete.
4. Verify the Android deep-link flow on real hardware once available.
5. Content search, notifications, selective-friend publishing, or self-service account deletion,
   if priorities shift that way.

## 10. Success criteria

Since this is a learning project with no external users, "success" is defined qualitatively:

- A user can manage notes and their social graph with no dead ends or silent failures.
- Every account/auth edge case (duplicate email, wrong password, unconfirmed email, same-password
  change) shows an accurate, specific message — not a generic or misleading one.
- Each shipped increment stays small, is unit-tested where the logic is pure, and is live-verified
  (not just reviewed) before merge — the collaboration pattern already established for this repo.
- Changes to shared infrastructure (the `auth.users` trigger, the root deep-link listener) are
  explicitly regression-checked against Notes even when the PR's primary purpose is SmartAcademy,
  and vice versa.

---

# PART II — DETAILED SPECIFICATION

*Everything below documents the app exactly as it behaves today (current source), not aspiration.
Field names, button labels, and error strings are copied verbatim from the code so this section
can serve as a functional spec in its own right.*

## 11. App shell & entry point

- `main.dart` initializes Supabase, then runs `LearningFlutterApp`, whose `home` is
  `ProjectsHomePage` (the app's overall dashboard of mini-projects — Notes is one entry among
  several, reached by tapping into it from there, not the app's direct home route).
- The whole app runs under a single global dark theme (`AppTheme.dark`, `themeMode: ThemeMode.dark`
  — no light mode/toggle exists anywhere in the app).
- `LearningFlutterApp` holds one long-lived subscription to
  `AppSupabase.client.auth.onAuthStateChange`, active regardless of which screen is currently
  shown. When it observes an `AuthChangeEvent.passwordRecovery` event (fired the moment a user
  taps a password-reset email link and Supabase establishes a "recovery" session), it:
  1. Reads `user.userMetadata['app']` off that recovery session (a tag set at signup time — either
     `'notes'` or `'smart_academy'`; older accounts predating the tag have it absent).
  2. If the tag is `'smart_academy'`, pushes SmartAcademy's own reset-password page; otherwise
     (including untagged/legacy accounts) pushes Notes' `ResetPasswordPage`.
  3. This is a global-navigator push (`_navigatorKey.currentState?.push(...)`), so it works no
     matter what screen the user was on when the link opened the app.

## 12. Data model (Supabase / Postgres)

All tables live in the `public` schema; `auth.users` is Supabase's built-in user table. Every
table has Row-Level Security (RLS) enabled — a row is only visible/writable to a given user if a
matching policy allows it, enforced by Postgres itself, independent of app code.

### 12.1 `public.notes` — a user's private notes

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key, auto-generated. |
| `user_id` | uuid | Owner; foreign key to `auth.users`, cascades on user deletion. |
| `title` | text | Not null, defaults to `''`. |
| `content` | text | Not null, defaults to `''`. |
| `is_pinned` | boolean | Not null, default `false`. |
| `is_favorite` | boolean | Not null, default `false`. |
| `created_at` | timestamptz | Set on insert. |
| `updated_at` | timestamptz | Auto-bumped to `now()` on every UPDATE by a trigger. |

Indexed by `(user_id, updated_at desc)` for fast per-user, recency-ordered listing.

**RLS:** a user can SELECT/INSERT/UPDATE/DELETE only rows where `user_id` equals their own auth
id — strictly private, no exceptions, no sharing at the table level (sharing happens by *copying*
into `shared_notes`, described below, not by exposing this table).

### 12.2 `public.profiles` — one row per user, public identity

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key, same as the `auth.users` id. |
| `username` | text | Not null, **globally unique**, must match `^[a-zA-Z0-9_.-]{3,30}$` (3–30 chars: letters, digits, underscore, dot, hyphen). |
| `avatar_url` | text | Nullable — null until the user uploads a picture. |
| `created_at` / `updated_at` | timestamptz | Standard. |

**Auto-creation:** a database trigger fires on every new `auth.users` row and inserts a matching
`profiles` row automatically, deriving a starting username from (in order of preference): the
`username` passed in signup metadata → the part of the email before `@` → `user_<first 8 chars
of the user's id>`. This means every user always has *some* profile row, even before the app-level
`ensureProfileForCurrentUser` logic runs.

**RLS:** any signed-in user can read *any* profile (needed for username search and friend
lookups) — profiles are not private. A user can only insert/update their own profile row.

### 12.3 `public.friend_requests` — the friend-request lifecycle

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `sender_id` | uuid | Who sent the request. |
| `receiver_id` | uuid | Who it was sent to. Table-level check: cannot equal `sender_id`. |
| `status` | text | One of `'pending'`, `'accepted'`, `'declined'`, `'cancelled'`. Default `'pending'`. |
| `created_at` / `updated_at` | timestamptz | Standard. |

A partial unique index prevents two *simultaneous pending* requests in the exact same direction
(same sender → same receiver) — the app's own logic separately checks both directions before
allowing a new request (see §13.4).

**RLS:** a user can see a request only if they're the sender or receiver. Only the sender can
create a request (and not to themselves). Either sender or receiver can update a request's status
(covers accept, decline, and cancel — all are just status changes performed by whichever side is
allowed to make that particular transition, enforced in application logic, not by separate RLS
rules per transition).

### 12.4 `public.friendships` — confirmed friendships

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `user_low_id` | uuid | The lexicographically smaller of the two friend ids. |
| `user_high_id` | uuid | The lexicographically larger. |
| `created_at` | timestamptz | When the friendship was formed. |

Friendships are stored in **canonical order** (`user_low_id < user_high_id`, enforced by a table
check and used consistently by the app when reading/writing) so each friendship exists as exactly
one row regardless of who's "looking it up," with a uniqueness constraint on the pair.

**RLS:** a user can see a friendship row only if they're one of the two parties. Either party can
insert (used when a request is accepted) or delete (unfriend) the row.

### 12.5 Sharing/feed tables (current schema — redesigned once, see §12.6 for history)

**`public.shared_notes`** — one row per *published note* (not per recipient):

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `note_id` | uuid | The original note being shared; foreign key to `notes`, cascades on delete. |
| `author_id` | uuid | Who published it. |
| `title` / `content` | text | A **copy** of the note's title/content at publish time (re-copied on republish). |
| `published_at` | timestamptz | Set/refreshed each time the note is (re-)published. |
| `updated_at` | timestamptz | Auto-bumped on update. |

Unique on `(note_id, author_id)` — a given note can only have one active "published" row at a
time; republishing updates that row in place rather than creating a duplicate.

**`public.shared_note_recipients`** — join table, who can see a given shared note:

| Column | Type | Notes |
|---|---|---|
| `shared_note_id` | uuid | Foreign key to `shared_notes`, cascades. |
| `recipient_id` | uuid | A friend who can see this post. |
| `created_at` | timestamptz | When they were added as a recipient. |

Primary key is the pair `(shared_note_id, recipient_id)`. Recipient rows are only ever added, never
removed by the app (publishing to an already-covered friend is a harmless no-op upsert).

**`public.shared_note_likes`** — one row per (post, liker):

| Column | Type |
|---|---|
| `shared_note_id` | uuid, FK to `shared_notes`, cascades |
| `user_id` | uuid, who liked it |
| `created_at` | timestamptz |

Primary key `(shared_note_id, user_id)` — a user can only like a given post once (liking twice is
a no-op/toggle-off, handled in app logic as delete-if-exists-else-insert).

**`public.shared_note_comments`** — one row per comment:

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `shared_note_id` | uuid | FK to `shared_notes`, cascades. |
| `user_id` | uuid | Commenter. |
| `content` | text | Not null; **must be 1–500 characters** (enforced by a database CHECK constraint, mirrored in app-level validation before the insert is even attempted). |
| `created_at` | timestamptz | Standard. |

**RLS across all four sharing tables** follows one consistent rule: a shared note (and its likes/
comments) is visible to its author **and** anyone listed as a recipient; nobody else can see it at
all, at the database level, regardless of what the app's UI does or doesn't show. Writes (insert)
are gated to "you must be the author" (for the note itself and recipient rows) or "you must be
acting as yourself" (for your own likes/comments). A helper database function
(`is_shared_note_author`) exists specifically to let the recipients table's visibility check
include "or you're the author" without triggering a circular RLS reference back through
`shared_notes`' own policy.

**Known DB-level gap:** the policy that allows inserting a recipient row only checks "did you
author this shared note" — it does **not** re-verify at the database layer that the recipient is
actually your friend. That check exists only in the Dart app logic (`publishNoteToFriends` only
ever iterates your real friends list). Not exploitable through the app's normal UI, but worth
knowing before adding any new code path that writes to `shared_note_recipients`.

### 12.6 Schema history note

An earlier version of the sharing tables (migration `002`) modeled `shared_notes` with **one row
per (note, author, recipient) triple** — i.e., publishing to 5 friends created 5 separate rows for
the same note. This caused a real bug: the author of a note could never see likes/comments on
their *own* post, because every query filtered by `recipient_id = you`, and a naive fix would have
shown 5 duplicate, fragmented feed cards instead of one. Migration `004` destructively redesigned
this into the current one-row-per-note-plus-join-table shape described in §12.5. This history
matters context-wise (it's why the "why" in §7 mentions it) but the *old* shape no longer exists
in the live schema.

### 12.7 Storage

**Bucket `profile-pictures`** — public bucket, 5 MB file-size limit, accepts only
`image/jpeg`/`image/png`/`image/webp`. Anyone can read any file in it (avatars are public by
design). A user may only upload/update/delete files whose path starts with their own user id as
the first folder segment (the app's convention is `<user_id>/avatar.<ext>`) — enforced by RLS on
`storage.objects`, not just app convention.

## 13. Business rules by domain

*(`NotesLogic` is the single class the UI calls into; it delegates persistence to swappable
data-source classes, each with a real-Supabase implementation and a fake used only in tests.)*

### 13.1 Email & username validity (used everywhere)

- **Valid email**: must match `^[^\s@]+@[^\s@]+\.[^\s@]+$` (something@something.something, no
  spaces).
- **Valid username**: trimmed and lowercased, then must match `^[a-zA-Z0-9_.-]{3,30}$` — 3 to 30
  characters, letters/digits/underscore/dot/hyphen only.

### 13.2 Registration (`signUpWithUsername`)

1. Username must be valid, else: *"Use 3-30 chars: letters, numbers, _, -, ."*
2. Email must be valid, else: *"Enter a valid email address."*
3. Calls Supabase sign-up, tagging the account's metadata with `app: 'notes'` (so the shared
   `auth.users` pool can tell Notes and SmartAcademy accounts apart later) and a redirect URL for
   the confirmation email.
4. Interprets the response:
   - If Supabase reports the email is **already a registered, confirmed account** (detected via
     an empty `identities` list on the returned user — Supabase's deliberately indirect way of
     signaling this without letting an attacker enumerate registered emails via error messages):
     *"That email is already registered. Try logging in, or use \"Forgot password\" if you don't
     remember your password."*
   - If the new account still needs email confirmation: any session Supabase handed back is
     immediately signed out again (so an unconfirmed user is never left half-logged-in), and the
     UI is told "not yet complete" — the app then shows a "check your email" message and offers to
     resend the confirmation email.
   - If the account is fully confirmed and active immediately (rare — only if email confirmation
     is disabled project-wide): a profile row is ensured to exist, and the UI proceeds as if login
     succeeded.

### 13.3 Login (`signInWithEmail`)

1. Email must be valid, else *"Enter a valid email address."*
2. Calls Supabase sign-in with password.
3. If the resulting account's email isn't confirmed, the user is immediately signed back out and
   shown: *"Please confirm your email to activate your account."*
4. Any other Supabase auth error is translated via the shared error-humanizer (§13.8) — e.g. wrong
   password/email shows *"Incorrect email or password. Please try again."*, not a raw Supabase
   error string.

### 13.4 Friend requests (`sendFriendRequestByUsername` and related)

Sending a request, in order, fails fast at the first violated rule:

1. Must be signed in, else *"You are not logged in."*
2. Username must be valid, else *"Enter a valid username."*
3. A profile with that username must exist, else *"No user found with that username."*
4. Can't be yourself, else *"You cannot send a friend request to yourself."*
5. Can't already be friends, else *"You are already friends."*
6. Can't already have a pending request between the two of you (checked in **either** direction),
   else *"A pending friend request already exists."*
7. Otherwise, inserts a new pending request.

**Responding to a request** (accept/decline): only the *receiver* of a still-*pending* request may
respond; any other case (already responded to, wrong user, request no longer exists) shows the
same message: *"This request can no longer be updated."* Accepting also creates the corresponding
`friendships` row (in canonical low/high order) in the same operation.

**Cancelling a sent request**: only the *sender* of a still-pending request may cancel; otherwise
*"This request can no longer be cancelled."* Cancelling sets status to `'cancelled'` rather than
deleting the row (a status the schema already allowed for).

**Removing a friend**: deletes the friendship row outright; either party may do this (enforced by
RLS, not re-checked separately in app logic).

### 13.5 Publishing notes to friends (`publishNoteToFriends` / `unpublishNoteFromFriends`)

- **You cannot publish a note if you have zero friends** — attempting to shows *"Add at least one
  friend before publishing notes."*
- Publishing copies the note's *current* title/content into `shared_notes` and adds every one of
  your current friends as a recipient. There's no way to publish to a subset — it's always
  "everyone who is currently my friend."
- Republishing an already-published note updates the existing shared copy's title/content/
  timestamp in place, rather than creating a duplicate; it also (re-)adds any friends gained since
  the last publish, but never removes a recipient who's since been unfriended.
- Unpublishing deletes the `shared_notes` row entirely, which cascades to delete its recipients,
  likes, and comments too (nothing is "soft-deleted").

### 13.6 The feed (`fetchFriendsFeed`)

- Shows: every post you authored, plus every post where you're a listed recipient, merged into one
  list (deduplicated by post id, sorted newest-first, capped at the 100 most recent).
- Each item is tagged `isOwnPost` so the UI can show "You" instead of a username for your own
  posts.
- Each item carries a like count, comment count, and whether *you* currently like it.

### 13.7 Comments (`addFeedComment`)

- Must be signed in, else *"You are not logged in."*
- Cannot be blank (after trimming), else *"Comment cannot be empty."*
- Cannot exceed 500 characters, else *"Comment is too long (max 500 characters)."* — this mirrors
  a hard database constraint, so it can never be bypassed even if a client skipped this check.

### 13.8 The shared error-humanizer (`userMessageForError`)

Every low-level error (from Supabase Auth, Postgrest/database, or Storage) is translated through
one central function before ever reaching the user, so raw technical errors are never shown
directly. Rules, checked in order:

- A password-change rejected specifically because it matches your *current* password →
  *"Your new password must be different from your current password."* (matched on Supabase's
  stable `same_password` error **code**, not message text — a deliberate fix for an earlier bug
  where matching on the word "password" in the message caused this exact case to be
  misreported as "Incorrect email or password.")
- Anything that looks like a bad login (invalid credentials/password) →
  *"Incorrect email or password. Please try again."*
- Anything about a duplicate email → *"That email is already registered."*; duplicate username →
  *"That username is already taken."*
- Unconfirmed-email errors → *"Your account needs email confirmation before login."*
- Rate-limiting → *"Too many attempts. Please wait a moment and try again."*
- Email delivery/provider misconfiguration → *"Registration email could not be sent. Please ask
  the app admin to finish Supabase email provider/SMTP setup."*
- Any other auth error → generic *"Authentication failed. Please try again."*
- A database unique-constraint violation → *"That value is already in use."*; a permission/RLS
  denial → *"You do not have permission to do that."*
- A file-storage rejection due to size or type → *"That file is not supported. Use JPG, PNG, or
  WEBP up to 5MB."*; any other storage failure → *"Unable to upload file right now. Please try
  again."*
- Anything else falls back to a plain, stripped version of the error message, or a caller-supplied
  fallback string if the message is empty.

## 14. Screen-by-screen walkthrough

### 14.1 Notes home (`NotesPage`)

The main screen once logged in and confirmed. App bar titled **"Notes"**, with three icon buttons:
a **Friends & feed** button (shows a numeric badge when you have pending incoming friend
requests), a **Profile** button (shows your avatar), and a **Sign out** button.

Below that: a search box (placeholder *"Search by title"*) and three filter chips — **All**,
**Pinned**, **Favorites** — plus a **New** button that opens a small dialog (title *"New Note"*,
one text field labeled *"Title"*) to create a note; leaving the title blank silently cancels
creation. On success, it jumps straight into the note editor for the new note.

The list itself shows one row per note (pinned notes always sort first, then by most-recently-
updated). Each row shows the title, a two-line content preview (or *"No additional text"* if
empty), the last-updated time, and three icon toggles: **favorite** (star), **pin**, and
**publish/share to friends** (globe icon — filled if currently published). A published note also
shows a small **"Shared with friends"** badge. Swiping a row left reveals a delete action, which
asks for confirmation (*"Delete Note"* — *"Delete "<title>"? This action cannot be undone."*)
before actually deleting.

If notes fail to load, an error card shows the raw failure reason. If there are simply no notes
yet (or none match the current search/filter), an empty-state card reads **"No notes yet — Create
your first note to get started."**

### 14.2 Login / register (`NotesAuthPage`)

A single card headed **"Welcome to Notes"** with a **Login / Register** segmented toggle.

Both modes ask for **Email** and **Password**. Register mode additionally asks for a **Username**
(above the email field) and a **Confirm password** field (below). Client-side validation before
submit: username 3–30 chars of letters/digits/`_`/`-`/`.`; a plausible email shape; password at
least 6 characters; confirm-password must match.

Login mode has a **"Forgot password?"** link that opens a small dialog asking for an email
address and sends a reset link — the response is always the same neutral message (**"If an
account exists for that email, a reset link has been sent."**) regardless of whether that email is
actually registered, so the flow can't be used to check who has an account.

After registering, if the account needs email confirmation, the page switches back to Login mode
and shows: **"Account created. Check your email to confirm it, then log in with your email."**,
plus a **"Resend confirmation email"** button that appears from then on.

Any auth failure shows the humanized message from §13.8 in a red banner.

### 14.3 "Confirm your email" gate (`NotesActivationRequiredPage`)

Shown instead of the notes list if you're logged in but haven't confirmed your email yet. A single
card: **"Please confirm your email to activate your account."** and a **"Back to login"** button
that signs you out.

### 14.4 Set a new password (`ResetPasswordPage`)

Only reached via a password-reset email link (see §11). Asks for **New password** and **Confirm
new password** (6-char minimum, must match). On success, pops back and shows a confirmation
snackbar: **"Password updated. You can now log in with it."**

### 14.5 Note editor (`NoteEditorPage`)

A borderless, document-like editor: a large title field at top, a divider, then a full-height
content field with placeholder **"Start writing..."**. A **Save** button (with a checkmark icon)
and a **Delete** button (trash icon) sit in the app bar. Attempting to save with a blank title
shows a snackbar **"Title cannot be empty."** and doesn't save. After a successful save, a small
**"Saved"** pill briefly appears. Navigating away from the editor always attempts to save first.
Deleting asks for confirmation (**"Delete Note"** — **"Are you sure you want to delete this
note?"**).

### 14.6 Friends & Feed (`NotesSocialPage`)

A two-tab screen: **Friends** and **Feed**.

**Friends tab:**
- A search box (**"Find users by username"**) with a **Search** button; results list matching
  users with an **Add** button next to each to send a request. No matches shows **"No users
  found. Make sure the username is correct."**
- **Incoming requests** section (with a count badge) — each shows the requester's username with
  **Accept**/**Decline** buttons. Empty state: **"No pending incoming requests."**
- **Sent requests** section — shown as removable chips (one per pending outgoing request); tapping
  the chip's delete icon cancels that request. Empty state: **"No pending outgoing requests."**
- **Friends** section (with your current friend count in the heading) — each row shows a friend's
  avatar/username and how long you've been friends, with a **remove-friend** icon that opens a
  confirmation dialog (**"Remove Friend"** — *"Remove @username from your friends? You'll need to
  send a new friend request to reconnect."*). Empty state: **"No friends yet."**

**Feed tab:** a scrolling list of published-note cards. Each card shows the author (**"You"** for
your own posts, otherwise **@username**), when it was published, the title and content, and a
footer with a **like** button + count and a **comment** button + count. Every card also shows a
**"Read-only"** badge, signaling you're viewing a shared copy, not the live original note. Tapping
the comment icon opens a bottom sheet titled **"Comments"** listing every comment (author, text,
date) with a text box at the bottom to add your own (blocked client-side if empty; the 500-char
cap is enforced by the logic layer and, ultimately, the database itself). Empty feed shows: **"No
shared notes yet — When your friends publish notes, they will appear here."**

### 14.7 Profile (`NotesProfilePage`)

Reached from the Notes home app bar. Three sections:
- **Avatar** — current picture plus a **"Change profile picture"** button (opens the device's
  photo gallery; picked images are resized/compressed before upload). Success shows **"Profile
  picture updated."**
- **Username** — a single field, save button labeled **"Save username"**; success shows
  **"Username updated."**
- **Password** — new/confirm password fields, save button labeled **"Update password"**; success
  shows **"Password updated."** and clears both fields.

Every section validates client-side using the same rules as §13.1, and shows the §13.8 humanized
message on any failure (e.g. uploading an unsupported file type shows *"That file is not
supported. Use JPG, PNG, or WEBP up to 5MB."*).

## 15. End-to-end user flows (worked examples)

**A. New user signs up, writes a note, and shares it:**
1. Opens Notes → sees `NotesAuthPage` (not logged in).
2. Switches to Register, enters username/email/password/confirm, submits.
3. Gets *"Account created. Check your email to confirm it..."*, follows the email link (which
   also confirms the account), returns and logs in.
4. Lands on the empty notes list, taps **New**, types a title, is dropped into the editor, writes
   content, backs out (auto-saves).
5. Adds a friend first (Friends tab → search username → Add → friend accepts), since publishing
   with zero friends is blocked.
6. Back on the notes list, taps the globe/publish icon on their note → *"Note published to your
   friends feed."* The note now shows the **"Shared with friends"** badge.
7. Their friend opens their own Feed tab and sees the new post, can like/comment on it.

**B. Forgotten password (web):**
1. On `NotesAuthPage`, taps **"Forgot password?"**, enters email, gets the neutral
   "if an account exists..." message regardless of outcome.
2. Follows the emailed link → app opens, the root auth listener detects the recovery event, reads
   the `app` metadata tag (`'notes'`), and pushes `ResetPasswordPage` directly, bypassing whatever
   screen was open.
3. Sets a new password, confirmation snackbar shown, returns to the app and logs in normally with
   the new password.

**C. Friend-request lifecycle:**
1. A sends B a request → B sees it under "Incoming requests" with a badge; A sees it under "Sent
   requests" as a chip.
2. B declines → request status becomes `declined`; it disappears from both lists (only *pending*
   requests are shown).
3. A can send a new request to B any time after that (no cooldown), repeating step 1.
4. Alternatively, A could have cancelled the request themselves before B responded, which also
   just changes the status (to `cancelled`) rather than deleting the row.

## 16. Glossary

- **Shared note**: the *published copy* of a note visible in the feed — distinct from the private
  original in `notes`; editing the original after publishing does not update the shared copy
  unless you republish.
- **Recipient**: a friend who can see a specific published note; recipients are only ever added
  during publish, never removed automatically (e.g. unfriending someone doesn't retroactively hide
  old shared posts from them).
- **Own post**: a feed item where you are the author, shown labeled "You" rather than a username.
- **Activation** / **confirmed email**: Supabase's built-in email-confirmation state; the app
  treats an unconfirmed account as functionally logged-out (auto-signs-out and shows the
  activation gate) even though Supabase itself did issue a session.
