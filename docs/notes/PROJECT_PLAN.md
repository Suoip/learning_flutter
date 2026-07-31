# Notes App — Project Plan

**Status:** Retroactive project plan, most recently refreshed after PR #57 (2026-07-30). Where this
doc describes something already shipped, that's noted explicitly — treat those sections as
"confirm this is still true" rather than "design from scratch." This revision adds product-level
sections (vision, UX analysis, competitive landscape) and a formal, three-tier acceptance-criteria
framework (page / module / project) that didn't exist in earlier drafts, on top of refreshing every
part of the spec that had gone stale across the PR #30–#57 UI-overhaul and feature arc.

This document is written to be **fully self-contained**: Part I is the high-level plan (vision,
UX thinking, competitive context, goals, scope, roadmap); Part II is an exhaustive specification of
every screen, field, validation rule, data table, and business rule; Part III inventories every
page as a product artifact (purpose, content, user actions, acceptance criteria); Part IV states
what "done" means at the module and whole-project level; Part V walks through worked end-to-end
flows.

---

# PART I — HIGH-LEVEL PLAN

## 1. Vision

Notes is the flagship mini-project in the `learning_flutter` app (user-facing app name: **Mini
Projects**, see §12): a personal note-taking app with a social layer built on top of it. At its
best, Notes should feel like two honest things stitched together, not compromised by each other —

- **A fast, trustworthy private notebook.** Writing, organizing (pin/favorite), and finding a note
  again should never feel slower or less reliable than reaching for a plain-text file. Nothing
  about the social layer should tax the private-notes experience.
- **A small, deliberate act of sharing.** Publishing a note is a conscious, visible, reversible
  choice — not an ambient broadcast. The friend graph is closed (mutual, request-based) rather than
  a public follow model, and every published note is visible only to the exact set of people who
  were your friends at publish time.

It's also the original project the rest of the `learning_flutter` app's engineering patterns were
established on — the testable `*Logic` + `*DataSource` pair, Supabase auth/RLS conventions, the
dark "playful & rounded" theme system, the skeleton-loading/crossfade/haptic motion language — and
later reused (Notes' patterns first, SmartAcademy's variations second) across the rest of the app.

## 2. Problem / motivation

This is a learning repo — the motivation is to practice building a realistic full-stack CRUD app
with auth, authorization, a social graph, and real product-design decision-making (not just
backend plumbing) on top of Supabase, and to keep it maintainable as it grows through many small,
sequential PRs. There is no external user base; scope and sequencing are driven by what's useful to
build and learn next, decided collaboratively PR by PR, informed by periodic feature/UX audits of
what a real user would expect.

## 3. UX principles & analysis

This section is a retrospective, honest self-assessment of the shipped product against standard
usability heuristics (Nielsen's) and this project's own stated design values — not a marketing
pitch. Graded qualitatively, since there's no analytics/user-testing pipeline on a project with no
external users.

| Heuristic | Where it's strong | Where it's still weak |
|---|---|---|
| **Visibility of system status** | Every list has a loading skeleton shaped like its real content, not a bare spinner (PR #47); a "Saved"/"Unsaved changes" pill in the editor (§7.4 of the UI plan); an unseen-post badge on the Feed tab. | The feed's hard 100-item cap is invisible to the user — nothing tells them older posts exist but aren't shown (§10, risks). |
| **Match between system and the real world** | "Liked by," "mutual friends," "Friends"/"Requested"/"Add Friend" labels all use plain, familiar social-app vocabulary rather than database terms (no "recipient," "shared_note," etc. ever surface in UI copy). | — |
| **User control and freedom** | Delete-then-undo-snackbar (not an immediate, final delete) for the common case; cancel a sent friend request; unpublish a note at any time. | Comments can't be edited or deleted once posted (§7.2, a tracked gap) — a real "no way back" spot. |
| **Consistency and standards** | One shared `NotesErrorBanner`, one shared `NotesEmptyState`, one shared `PopOnChange` bounce, one shared `AnimatedSwitcher`/`AnimatedSize` crossfade idiom reused everywhere a value or section appears/disappears — an explicit, repeated engineering convention, not one-off animations per screen. | — |
| **Error prevention** | The friend-status button (Friends tick / Requested / Add Friend) prevents ever showing an actionable "Add" control for someone already a friend or already pending — a real error (a redundant/rejected request) is prevented at the UI layer instead of just being handled gracefully after the fact. | Publishing is still all-or-nothing to every current friend with no way to preview/exclude specific people beforehand (only a post-hoc confirmation listing who it'll reach). |
| **Recognition rather than recall** | The "liked by" list surfaces mutual-friend counts so a user can recognize a potential connection without having to recall their own friend list from memory; likewise the friend-status button removes the need to remember who you've already requested. | — |
| **Aesthetic and minimalist design** | One accent color (`#5865F2`) used consistently everywhere status/emphasis is needed (favorite gold is the one deliberate, justified exception — "star = gold" is too strong a convention to break); no competing visual systems across screens. | — |
| **Help users recognize, diagnose, and recover from errors** | A single central error-humanizer (`userMessageForError`, §14.9) translates every raw Supabase/Postgrest error into a specific, actionable message — this was iterated on more than once after real bugs surfaced (e.g. the same-password/wrong-password message collision). | — |

**Motion as a UX tool, not decoration.** A deliberate, repeated pattern across the PR #47–#56 arc:
every state transition that used to *snap* (a badge appearing, a pill swapping text, a list
reordering, a value changing) was identified and given a short (200–300ms), purposeful animation —
either reinforcing that a state genuinely changed (the `PopOnChange` bounce on becoming liked/
favorited/pinned) or smoothing a layout change that would otherwise read as a jump cut
(`AnimatedSize` on a conditionally-appearing pill or section). This was treated as a UX correctness
concern, not a cosmetic one — the working rule adopted mid-project: *if a value can change while a
screen is visible, its appearance/disappearance/reordering should never be an instant cut.*

## 4. Competitive landscape

Honest positioning, not a pitch: Notes doesn't compete head-on with any single existing product —
it sits at an intersection nothing mainstream directly occupies, which is either a genuine (if
niche) angle or evidence of why nobody's built it at scale. Both readings are worth holding at
once for a learning project.

| Product | Private notes | Organize (pin/favorite/search) | Closed friend-graph | Publish/share content | Like/comment engagement | Discover mutual connections |
|---|---|---|---|---|---|---|
| **Google Keep / Apple Notes** | ✅ | ✅ (labels, pins) | ❌ (link-share only, no graph) | ⚠️ link-sharing, not a feed | ❌ | ❌ |
| **Notion** | ✅ (much richer) | ✅ | ⚠️ (workspace members, not a personal friend graph) | ⚠️ (page sharing/publishing) | ❌ | ❌ |
| **Instagram Close Friends / BeReal** | ❌ (not note-taking) | ❌ | ✅ | ✅ (feed-style) | ✅ | ⚠️ (not framed around mutuals) |
| **This app (Notes)** | ✅ | ✅ | ✅ (mutual, request-based) | ✅ (to your whole friend graph) | ✅ (likes + comments) | ✅ (mutual-friend count + one-tap add, PR #57) |

**Takeaways used to inform scope decisions:**
- The pure-notes apps (Keep/Notes/Notion) are unambiguously more mature at the *notes* half of the
  product — richer formatting, attachments, multi-device sync polish. Notes deliberately doesn't
  compete there (see Non-goals, §5) — plain text only, by design, not by current limitation.
- The social-feed apps (BeReal/Close Friends) are more mature at *engagement* at scale (stories,
  reactions beyond like/comment, notifications). Notes' explicit non-goal of push notifications
  (§5) is a real, current gap relative to that category, not a stylistic choice.
- **The mutual-friend-discovery angle (PR #57) is closer to what a friend-graph product like
  Facebook popularized than anything a notes app typically does** — deliberately borrowed because
  it directly serves this app's actual differentiator (a real, closed friend graph), rather than
  imitating a notes competitor's feature for its own sake.

## 5. Goals

- Let a user register, log in, and manage their own private notes (create/edit/delete, pin,
  favorite, search by title or content).
- Let a user build a friend graph: send/accept/decline/cancel requests, unfriend, and discover new
  connections via mutual friends surfaced through shared engagement (who liked a post you can see).
- Let a user publish a note to share with all their friends, and see a combined feed of their own
  and friends' published notes.
- Let feed participants like and comment on published notes, and see who liked a given post.
- Support the full account lifecycle: signup with email confirmation, forgot/reset password,
  username/avatar/password changes.
- Present a cohesive, animated, on-brand dark UI across every screen — not just the notes list.
- Work correctly on both web and mobile (Android), including email deep-link flows.

### Non-goals (for now)

- Rich text / attachments / images inside notes (plain text only).
- Real-time (live) feed or comment updates — data is fetched, not subscribed.
- Rich comment features beyond plain text (threading, reactions beyond like/comment). Basic
  edit/delete of your own comment is *not* a non-goal — it's a tracked gap, see §7.2/§11.
- Push notifications for new likes/comments/friend requests beyond in-app badges.
- Account deletion (self-service).
- Public/discoverable notes beyond the friends-only feed (no global public feed, unlike
  SmartAcademy's hub model).
- Choosing a subset of friends to publish to — publishing always targets *all* current friends.
- Light theme / theme toggle — the app is dark-only by design (§12).
- Desktop/wide-viewport-optimized layout — explicitly deferred twice (UI plan §7.1/§8); mobile is
  the confirmed primary target, web exists for faster local development only.

## 6. Target users

| Persona | Description | Needs |
|---|---|---|
| **Note-taker** | The default use case — someone using Notes purely privately. | Fast, reliable CRUD; pin/favorite/search to manage a growing list; never lose a note; autosave so nothing is lost to a forgotten manual save. |
| **Social publisher** | A note-taker who shares some notes with friends. | One-step publish, confidence that only friends see it (reinforced by a pre-publish confirmation listing recipients), visibility into engagement (likes/comments/who-liked) on their own posts. |
| **Feed participant** | Anyone with friends who've published notes. | A combined feed (not fragmented per-friend), like/comment, see who else liked something, manage the friend graph itself, discover new mutual connections without manually cross-referencing friend lists. |

## 7. Scope

### 7.1 In scope, shipped

- **Auth** — signup with username, email confirmation, login, self-service forgot/reset password
  (web and, unverified on real hardware, Android deep links), sign-out, resend confirmation email,
  password-visibility toggles on every password field.
- **Notes CRUD** — create/edit/delete (delete via swipe-with-undo-snackbar *or* an overflow-menu
  item, PR #38/#51), pin, favorite, search/filter by **title or content** (PR #36), autosave while
  typing (1.5s debounce), live word/character count, backed by a testable `NotesDataSource`.
  Deleting from the overflow menu and swiping both funnel through the same delete-with-undo logic.
- **Profile** — username, avatar upload (crossfades on change, PR #55), password change.
- **Friends** — search by username, send request, accept/decline, cancel a sent request, unfriend,
  full duplicate/self-request/already-friends guard rails, incoming-request count badge, and a
  three-state **friend-status button** (Friends / Requested / Add Friend, PR #57) on every person
  row so search results never show a misleadingly-actionable "Add" for someone already connected or
  already pending.
- **Publishing & feed** — publish a note to all friends at once with a pre-publish confirmation
  dialog listing recipients (PR #37), a combined feed showing both your own and friends' published
  notes with "You" labeling for your own, an unseen-post count badge on the Feed nav destination
  (PR #39).
- **Engagement** — likes and comments on published/shared notes, shown on a dedicated post-detail
  page (not a modal sheet, PR #35); a **"liked by" panel** (PR #57) listing everyone who liked a
  post — you first if you liked it too, then friends, then everyone else with a mutual-friend count
  and a one-tap "Add Friend."
- **Navigation & shell** — persistent bottom nav (Notes/Feed/Friends), persistent Profile icon,
  per-tab state preservation via `IndexedStack`, a frosted/translucent nav bar with the tab
  content's background gradient showing through (PR #51).
- **Visual/motion design system** — a full dark "playful & rounded" theme applied to *every* Notes
  screen (not just the list, superseding earlier partial-rollout status), a custom app icon and
  matching dark native splash screens on every platform (PR #49/#53), the app renamed from the
  Flutter-template default to **Mini Projects** everywhere it's user-visible (PR #53/#54), skeleton
  loading states on every data-driven screen, and a consistent crossfade/bounce/stagger motion
  language covering every conditionally-appearing element in the feature (PRs #47–#56).
- **Testing infrastructure** — the `NotesDataSource` pattern (Notes → Profiles → Friends → Feed →
  Auth) is complete across all five logic domains, 300+ unit tests total using fakes.

### 7.2 In scope, not yet started / known gaps

- **View another user's profile** — tapping a friend's avatar (or a liker's row in the "liked by"
  list) currently does nothing beyond the friend-status button. Identified as the next social
  feature to build since a feature audit before PR #9, still not started as of PR #57.
- **Edit/delete your own posted comments** — no path exists today, at either the UI or the RLS
  layer beyond a raw delete policy (`shared_note_comments_delete_self` exists at the DB level, but
  no UI calls it).
- **Feed pagination** — the feed is hard-capped at the 100 most recent items with no "load more" —
  flagged repeatedly in past audits, never picked up, low urgency at current usage scale.
- **Self-service account deletion.**
- **Notifications for new likes/comments** on your own published notes (only the friend-request
  badge and unseen-feed-post badge exist — nothing surfaces "someone liked/commented on your post"
  outside of opening that post's "liked by" list or comments yourself).
- **Choosing which friends to publish to** — currently all-or-nothing.
- **Batched/optimized mutual-friend-count fetching** — currently one RPC call per non-friend row in
  the "liked by" list; fine at this app's real scale (a handful of likers), would need revisiting
  if like counts ever grew into the hundreds.
- **Verify PR #15's Android deep-link fix, and PR #49's Android/iOS native splash/icon, on a real
  device/emulator** — all implemented but never actually tested on real Android/iOS hardware; no
  SDK/emulator or Mac available in this dev environment.
- **`updateUsername`/`uploadProfileAvatar` full-path unit test coverage** — only their signed-out/
  invalid-input guard clauses are unit-tested today; the real Supabase-touching paths are
  integration-tested only (a deliberate, accepted gap, not an oversight).

### 7.3 Explicitly out of scope

See Non-goals (§5). Additionally not planned: rich content, real-time sync, a public/global feed,
comment moderation, a desktop-optimized layout, or a light theme.

## 8. Feature breakdown

| Area | Capability | Status |
|---|---|---|
| Auth | Signup / login / email confirmation | ✅ Shipped |
| Auth | Forgot/reset password (web) | ✅ Shipped |
| Auth | Forgot/reset password (Android deep link) | ⚠️ Implemented, unverified on real hardware |
| Auth | Password visibility toggle (all fields) | ✅ Shipped |
| Profile | Avatar (crossfades on change), username, password | ✅ Shipped |
| Profile | View another user's profile | ⬜ Not started |
| Notes | CRUD, pin, favorite | ✅ Shipped |
| Notes | Search by title or content | ✅ Shipped |
| Notes | Delete via swipe-undo *and* overflow menu | ✅ Shipped |
| Notes | Autosave + live word/character count | ✅ Shipped |
| Friends | Search / send / accept / decline / cancel / unfriend | ✅ Shipped |
| Friends | Friend-status button (Friends/Requested/Add) everywhere a person row appears | ✅ Shipped |
| Feed | Combined own + friends' published notes | ✅ Shipped |
| Feed | Unseen-post count badge | ✅ Shipped |
| Feed | Pagination beyond 100 items | ⬜ Not started |
| Engagement | Likes, comments (dedicated detail page) | ✅ Shipped |
| Engagement | "Liked by" list | ✅ Shipped |
| Engagement | Mutual-friend discovery from likers | ✅ Shipped |
| Engagement | Comment edit/delete | ⬜ Not started |
| Feed | Selective (not all-friends) publish | ⬜ Not started |
| Growth | Push notifications (likes/comments) | ⬜ Not planned yet |
| Growth | Account deletion | ⬜ Not planned yet |
| UI/Motion | Dark theme, full rollout across every screen | ✅ Shipped |
| UI/Motion | Skeleton loading, crossfades, bounces, staggered lists | ✅ Shipped |
| UI/Motion | Frosted/translucent bottom nav | ✅ Shipped |
| Branding | Custom app icon + name ("Mini Projects") + dark splash | ✅ Shipped |
| UI/Motion | Desktop/wide-viewport layout | ⬜ Deferred, not planned |

## 9. Key decisions already made (and why)

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
  message substrings; message text isn't a stable contract, error codes are.
- **Global dark theme applied at the MaterialApp root**, not scoped to Notes' navigator subtree —
  because `ResetPasswordPage` is pushed directly onto the root navigator for the password-recovery
  deep link, bypassing Notes' own navigation stack; a scoped theme override would've left that
  screen unthemed.
- **`SECURITY DEFINER` helper functions for RLS that needs to bypass its own table's policy** —
  `is_shared_note_author()` avoids a circular RLS reference; the same idiom was reused for
  `mutual_friend_count()` (§13.6), which must read another user's `friendships` rows (RLS otherwise
  restricts every user to seeing only their own).
- **Mutual-friend counting is a scalar RPC, called once per row, not batched** — validated via a
  dedicated Plan-agent review before implementation (PR #57); at this app's real scale a "liked by"
  list has a handful of rows, so simplicity/reviewability of the SQL won out over the added
  complexity of an array+`unnest` batched version.
- **Motion/animation conventions are shared widgets, not one-off code per screen** — `PopOnChange`
  (spring-pop on becoming active), `StaggeredListItem` (fade+slide entrance keyed by item id, not
  index, so reordering doesn't replay/skip the wrong item's animation), and a repeated
  `AnimatedSize`/`AnimatedSwitcher` idiom for conditionally-appearing content — chosen specifically
  so new screens reuse the same few primitives instead of inventing new animation code each time.
- **Publishing always targets the entire friends list**, not a chosen subset — simpler model,
  accepted as a real limitation (see backlog).
- **Password-reset error messages are deliberately non-revealing** — `sendPasswordResetEmail`
  always appears to succeed, regardless of whether the email is registered, to avoid leaking
  account existence.
- **App renamed and re-iconed at the display layer only** — `pubspec.yaml`'s `name: new_project`
  (the Dart package identifier used in every `import 'package:new_project/...'`) was deliberately
  left untouched when the app was renamed to "Mini Projects" (PR #53); renaming the package
  identifier would touch every import statement in the codebase for a purely cosmetic, user-facing
  change, which wasn't worth the blast radius.

## 10. Risks & open questions

| Risk / question | Notes |
|---|---|
| Android/iOS native polish unverified | Deep links (PR #15), native splash screens, and the app icon (PR #49/#53) are all implemented but never tested on real Android/iOS hardware — no SDK/emulator or Mac available in this dev environment. |
| RLS bugs aren't caught by unit tests | Already happened once (PR #13's author-can't-see-own-shared-recipient-row bug) — only live testing surfaced it. Any new INSERT/UPDATE policy, or new RPC like `mutual_friend_count`, should be sanity-checked live, not just reviewed. |
| No feed pagination | Users with very active friend graphs only ever see the 100 most recent posts, with no signal that older ones exist or a way to reach them. Not urgent at current usage scale. |
| No content-search relevance ranking | Search matches title or content, but has no ranking/highlighting — a very long note matching once may not surface as prominently as a short one matching in the title. Not a known complaint yet, just an unexamined assumption. |
| Recipient insert has no DB-level friend check | `shared_note_recipients_insert_author` only verifies the inserter authored the shared note — it does *not* re-verify recipients are actually friends at the DB layer (an earlier check was removed while debugging the PR #13 RLS recursion issue). The only gate on "who can be a recipient" today is the app's own `fetchFriends()`-driven UI. Not currently exploitable through the app's own UI, but worth knowing if a new write path to `shared_note_recipients` is ever added. |
| Mutual-friend RPC is per-row, not batched | A "liked by" list with many non-friend likers makes that many sequential round-trips. Accepted at current scale (see §9); would need a batched `unnest`-based version if like counts ever grew large. |
| No automated visual/animation regression testing | The entire PR #47–#56 motion-language rollout was verified by hand in a browser preview each time (the Browser pane's screenshot tool has a known, unresolved intermittent "pane not displayed" compositing failure in this dev environment) — there's no automated way to catch a future regression in, say, a crossfade duration or a skeleton shape drifting from its real content's layout. |

## 11. Suggested roadmap (next steps, unsequenced)

The user sequences PRs one at a time rather than committing to a fixed order; known candidates,
not a committed sequence:

1. View another user's (friend's, or a "liked by" list liker's) profile — the longest-standing
   item from repeated feature audits, now doubly relevant given PR #57's discovery surface.
2. Comment edit/delete.
3. Verify the Android/iOS deep-link, splash, and icon work on real hardware once available.
4. Feed pagination, content-search relevance, notifications, selective-friend publishing, batched
   mutual-friend-count fetching, or self-service account deletion, if priorities shift that way.

---

# PART II — DETAILED SPECIFICATION

*Everything below documents the app exactly as it behaves today (current source), not aspiration.
Field names, button labels, and error strings are copied verbatim from the code so this section
can serve as a functional spec in its own right.*

## 12. App shell & entry point

- `main.dart` initializes Supabase, then runs `LearningFlutterApp` (the Dart class name is
  unchanged — only the user-visible display name changed, see below), whose `home` is
  `ProjectsHomePage` (the app's overall dashboard of mini-projects, itself titled "Mini Projects" —
  Notes is one entry among several, reached by tapping into it from there, not the app's direct
  home route).
- **App identity (PR #53/#54):** the app's user-visible name is **Mini Projects** everywhere it
  surfaces — the Android launcher label, the browser tab title (`MaterialApp.title`, which Flutter's
  web engine uses to overwrite `index.html`'s own `<title>` at runtime — a real bug fixed in PR #54
  after the title was going blank post-boot), the iOS bundle display name, and Windows/Linux window
  titles. A custom icon (a blurple `#5865F2` rounded-square badge with a white 2×2 apps-grid glyph)
  replaces Flutter's stock default on every platform. The Dart package identifier
  (`pubspec.yaml`'s `name: new_project`) was deliberately left unchanged (§9).
- **Dark-only, everywhere, from first paint.** `AppTheme.dark`/`ThemeMode.dark` covers the whole
  in-app UI; additionally, the *native* launch/splash screens (Android `launch_background.xml`,
  iOS `LaunchScreen.storyboard`, and the web page's own background before Flutter/CanvasKit paints)
  all match the same dark surface color (`#1E2128`), so there's no white flash on cold launch on any
  platform (PR #49) — this was a real, visible gap for a "dark-theme-only" app before being fixed.
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

## 13. Data model (Supabase / Postgres)

All tables live in the `public` schema; `auth.users` is Supabase's built-in user table. Every
table has Row-Level Security (RLS) enabled — a row is only visible/writable to a given user if a
matching policy allows it, enforced by Postgres itself, independent of app code.

### 13.1 `public.notes` — a user's private notes

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

### 13.2 `public.profiles` — one row per user, public identity

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

### 13.3 `public.friend_requests` — the friend-request lifecycle

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `sender_id` | uuid | Who sent the request. |
| `receiver_id` | uuid | Who it was sent to. Table-level check: cannot equal `sender_id`. |
| `status` | text | One of `'pending'`, `'accepted'`, `'declined'`, `'cancelled'`. Default `'pending'`. |
| `created_at` / `updated_at` | timestamptz | Standard. |

A partial unique index prevents two *simultaneous pending* requests in the exact same direction
(same sender → same receiver) — the app's own logic separately checks both directions before
allowing a new request (see §14.4).

**RLS:** a user can see a request only if they're the sender or receiver. Only the sender can
create a request (and not to themselves). Either sender or receiver can update a request's status
(covers accept, decline, and cancel — all are just status changes performed by whichever side is
allowed to make that particular transition, enforced in application logic, not by separate RLS
rules per transition).

### 13.4 `public.friendships` — confirmed friendships

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `user_low_id` | uuid | The lexicographically smaller of the two friend ids. |
| `user_high_id` | uuid | The lexicographically larger. |
| `created_at` | timestamptz | When the friendship was formed. |

Friendships are stored in **canonical order** (`user_low_id < user_high_id`, enforced by a table
check and used consistently by the app when reading/writing) so each friendship exists as exactly
one row regardless of who's "looking it up," with a uniqueness constraint on the pair.

**RLS:** a user can see a friendship row only if they're one of the two parties — critically, this
means **a client can never fetch another arbitrary user's friend list**, which is exactly why
mutual-friend counting (§13.6) has to happen through a `SECURITY DEFINER` RPC rather than a plain
query. Either party can insert (used when a request is accepted) or delete (unfriend) the row.

### 13.5 Sharing/feed tables

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
a no-op/toggle-off, handled in app logic as delete-if-exists-else-insert). This table backs both
the aggregate like count shown on every card **and** the full liker list in the "liked by" panel
(§13.6, §21) — the panel's query (`selectLikesForSharedNote`) is a per-note variant of the same
table, mirroring the existing per-note comments query exactly.

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

### 13.6 `public.mutual_friend_count` — RPC, not a table (PR #57)

```sql
mutual_friend_count(p_other_user_id uuid) returns integer
```

A `SECURITY DEFINER` SQL function (not a table) that returns how many friends the calling user has
in common with `p_other_user_id`, without ever exposing either party's actual friend-list rows to
the caller — only a count. Exists because `friendships`' RLS (§13.4) only ever lets a user see
their own friendship rows; a client-side "fetch their friends and intersect" is architecturally
impossible. Granted to `authenticated` only (explicitly not `anon` — a logged-out caller has no
business computing mutual-friend counts about anyone). Called once per non-friend row in the
"liked by" list, not batched (§9, §10).

### 13.7 Schema history note

An earlier version of the sharing tables (migration `002`) modeled `shared_notes` with **one row
per (note, author, recipient) triple** — i.e., publishing to 5 friends created 5 separate rows for
the same note. This caused a real bug: the author of a note could never see likes/comments on
their *own* post, because every query filtered by `recipient_id = you`, and a naive fix would have
shown 5 duplicate, fragmented feed cards instead of one. Migration `004` destructively redesigned
this into the current one-row-per-note-plus-join-table shape described in §13.5. This history
matters context-wise (it's why §9's "why" mentions it) but the *old* shape no longer exists in the
live schema.

### 13.8 Storage

**Bucket `profile-pictures`** — public bucket, 5 MB file-size limit, accepts only
`image/jpeg`/`image/png`/`image/webp`. Anyone can read any file in it (avatars are public by
design). A user may only upload/update/delete files whose path starts with their own user id as
the first folder segment (the app's convention is `<user_id>/avatar.<ext>`) — enforced by RLS on
`storage.objects`, not just app convention.

## 14. Business rules by domain

*(`NotesLogic` is the single class the UI calls into; it delegates persistence to swappable
data-source classes, each with a real-Supabase implementation and a fake used only in tests.)*

### 14.1 Email & username validity (used everywhere)

- **Valid email**: must match `^[^\s@]+@[^\s@]+\.[^\s@]+$` (something@something.something, no
  spaces).
- **Valid username**: trimmed and lowercased, then must match `^[a-zA-Z0-9_.-]{3,30}$` — 3 to 30
  characters, letters/digits/underscore/dot/hyphen only.

### 14.2 Registration (`signUpWithUsername`)

1. Username must be valid, else: *"Use 3-30 chars: letters, numbers, _, -, ."*
2. Email must be valid, else: *"Enter a valid email address."*
3. Calls Supabase sign-up, tagging the account's metadata with `app: 'notes'` (so the shared
   `auth.users` pool can tell Notes and SmartAcademy accounts apart later) and a redirect URL for
   the confirmation email.
4. Interprets the response:
   - If Supabase reports the email is **already a registered, confirmed account** (detected via
     an empty `identities` list on the returned user): *"That email is already registered. Try
     logging in, or use \"Forgot password\" if you don't remember your password."*
   - If the new account still needs email confirmation: any session Supabase handed back is
     immediately signed out again (so an unconfirmed user is never left half-logged-in), and the
     UI shows a "check your email" message and offers to resend the confirmation email.
   - If the account is fully confirmed and active immediately (rare — only if email confirmation
     is disabled project-wide): a profile row is ensured to exist, and the UI proceeds as if login
     succeeded.

### 14.3 Login (`signInWithEmail`)

1. Email must be valid, else *"Enter a valid email address."*
2. Calls Supabase sign-in with password.
3. If the resulting account's email isn't confirmed, the user is immediately signed back out and
   shown: *"Please confirm your email to activate your account."*
4. Any other Supabase auth error is translated via the shared error-humanizer (§14.9) — e.g. wrong
   password/email shows *"Incorrect email or password. Please try again."*, not a raw Supabase
   error string.

### 14.4 Friend requests (`sendFriendRequestByUsername` and related)

Sending a request, in order, fails fast at the first violated rule:

1. Must be signed in, else *"You are not logged in."*
2. Username must be valid, else *"Enter a valid username."*
3. A profile with that username must exist, else *"No user found with that username."*
4. Can't be yourself, else *"You cannot send a friend request to yourself."*
5. Can't already be friends, else *"You are already friends."*
6. Can't already have a pending request between the two of you (checked in **either** direction),
   else *"A pending friend request already exists."*
7. Otherwise, inserts a new pending request.

**Every place a person row can be sent a request from** (Friends-tab search results, and the
"liked by" panel) resolves and displays this status *before* the user ever taps anything, via the
shared `FriendStatusButton` widget: `friend` (already friends), `pending` (a request already sent),
or `none` (safe to send). This makes rules 5 and 6 above effectively unreachable through the UI in
practice — they remain as a defense-in-depth guarantee at the logic layer.

**Responding to a request** (accept/decline): only the *receiver* of a still-*pending* request may
respond; any other case (already responded to, wrong user, request no longer exists) shows the
same message: *"This request can no longer be updated."* Accepting also creates the corresponding
`friendships` row (in canonical low/high order) in the same operation.

**Cancelling a sent request**: only the *sender* of a still-pending request may cancel; otherwise
*"This request can no longer be cancelled."* Cancelling sets status to `'cancelled'` rather than
deleting the row (a status the schema already allowed for).

**Removing a friend**: deletes the friendship row outright; either party may do this (enforced by
RLS, not re-checked separately in app logic).

### 14.5 Publishing notes to friends (`publishNoteToFriends` / `unpublishNoteFromFriends`)

- **You cannot publish a note if you have zero friends** — attempting to shows *"Add at least one
  friend before publishing notes."*
- Before actually publishing, a confirmation dialog lists exactly who it'll reach (capped at 8
  usernames + a "and N more" count for larger lists) — the user must explicitly confirm; cancelling
  leaves the note unpublished and its editor-inline toggle correctly un-flipped.
- Publishing copies the note's *current* title/content into `shared_notes` and adds every one of
  your current friends as a recipient. There's no way to publish to a subset — it's always
  "everyone who is currently my friend."
- Republishing an already-published note updates the existing shared copy's title/content/
  timestamp in place, rather than creating a duplicate; it also (re-)adds any friends gained since
  the last publish, but never removes a recipient who's since been unfriended.
- Unpublishing deletes the `shared_notes` row entirely, which cascades to delete its recipients,
  likes, and comments too (nothing is "soft-deleted"). Unpublishing does **not** show a
  confirmation dialog (only publishing does).

### 14.6 The feed (`fetchFriendsFeed`)

- Shows: every post you authored, plus every post where you're a listed recipient, merged into one
  list (deduplicated by post id, sorted newest-first, capped at the 100 most recent).
- Each item is tagged `isOwnPost` so the UI can show "You" instead of a username for your own
  posts.
- Each item carries a like count, comment count, and whether *you* currently like it.

### 14.7 Comments (`addFeedComment`)

- Must be signed in, else *"You are not logged in."*
- Cannot be blank (after trimming), else *"Comment cannot be empty."*
- Cannot exceed 500 characters, else *"Comment is too long (max 500 characters)."* — this mirrors
  a hard database constraint, so it can never be bypassed even if a client skipped this check.

### 14.8 Likers & mutual friends (`fetchFeedLikers` / `fetchMutualFriendCount`, PR #57)

- `fetchFeedLikers(sharedNoteId)` returns every liker (id, username, avatar, liked-at timestamp),
  oldest-liked-first, resolved through the same profile-batch-hydration helper every other
  people-list in the app uses.
- The current user, if they're among the likers, is **kept in the list** (not filtered out) and
  sorted to the very top, rendered as "You" with no friend-status button — an earlier version
  excluded the current user entirely, which produced a misleading "No likes yet" when the viewer
  was the *only* liker (fixed the same PR, after live testing surfaced it).
- After the current user, friends are sorted next, then everyone else — each group preserves its
  original like-order (oldest-liked-first) internally.
- For each non-friend, non-self row, `fetchMutualFriendCount` is called once (see §13.6) and its
  result is displayed as "N mutual friends" once it resolves (a progressive-enhancement fetch —
  the row renders immediately with just a friend-status button, then the mutual count fades in a
  moment later once that row's RPC call completes).
- Tapping "Add Friend" from this list calls the same `sendFriendRequestByUsername` as everywhere
  else in the app, and optimistically flips that row to the `pending` status without reloading the
  whole list.

### 14.9 The shared error-humanizer (`userMessageForError`)

Every low-level error (from Supabase Auth, Postgrest/database, or Storage) is translated through
one central function before ever reaching the user, so raw technical errors are never shown
directly. Rules, checked in order:

- A password-change rejected specifically because it matches your *current* password →
  *"Your new password must be different from your current password."* (matched on Supabase's
  stable `same_password` error **code**, not message text.)
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

---

# PART III — PAGE INVENTORY

Every page/surface in the Notes feature, documented as a product artifact: what it's *for*, what's
*on it*, what the user can *do*, and the concrete criteria that make it acceptable to ship or
regress-check against. This part supersedes the older flat "screen-by-screen walkthrough" format —
the same information is here, organized so each page is a self-contained unit.

## 15. Notes list (`NotesPage`, Notes tab)

**Purpose:** the default landing surface once logged in — browse, organize, and jump into your own
private notes.

**Content:**
- App bar titled "Notes" (crossfades when switching tabs), with a Profile icon (shows your avatar,
  or a small spinner while it's loading) and a Sign-out icon.
- A search box (*"Search by title or content"*) and three filter chips — **All**, **Pinned**,
  **Favorites**.
- A **New** button opening a small dialog (*"New Note"*, one **Title** field) — leaving the title
  blank silently cancels creation; success jumps straight into the editor for the new note.
- One row per note (pinned notes sort first, then most-recently-updated), each showing: title, a
  two-line content preview (or *"No additional text"*), last-updated time, favorite/pin icon
  toggles, and a 3-dot overflow menu with **Publish to friends**/**Unpublish from friends** and
  **Delete** (red, with a divider separating it from Publish).
- A **"Shared with friends"** pill appears under a published note's preview, animating in/out as
  publish state changes.
- Loading: a shimmering skeleton shaped like the real list. Empty (no notes, or none match the
  current search/filter): **"No notes yet — Create your first note to get started."** Error: a
  themed error banner.

**User actions:**
- Search/filter the list.
- Create a note (opens the editor immediately).
- Tap a row to open it in the editor.
- Toggle favorite/pin inline (haptic + spring-pop on becoming active).
- Publish/unpublish from the overflow menu (publish shows a recipient-confirmation dialog first).
- Delete from the overflow menu, or swipe the row left — both go through the same delete-then-
  undo-snackbar flow (a few seconds to tap **Undo** before the delete is final).
- Open Profile or sign out from the app bar.

**Acceptance criteria:**
- A note created, edited, pinned, favorited, published, or deleted here is reflected correctly and
  immediately (optimistically) without a full-list flash, and survives a real reload from the
  server.
- Search matches both title and note content, case-insensitively.
- Deleting via either path (menu or swipe) is undoable within the snackbar's visible duration, and
  irreversible only after it's dismissed/expires.
- Publishing with zero friends is blocked with a clear, specific message, not a generic failure.
- The loading skeleton's shape matches the real list's layout closely enough that the transition
  doesn't visibly jump.

## 16. Note editor (`NoteEditorPage`)

**Purpose:** read and edit one note's full content.

**Content:**
- A borderless, document-like layout: large title field, a divider, then a full-height content
  field (placeholder *"Start writing..."*).
- App bar with a **Delete** icon (trash) and last-edited time.
- Inline favorite/pin/publish-status toggles in the header (same icons/behavior as the list row).
- A live word/character count and a **"Unsaved changes"**/**"Saved"** status pill, both at the
  bottom of the content area, crossfading between states.

**User actions:**
- Edit title/content — autosaves 1.5s after the last keystroke (only while dirty and the title is
  non-empty; a blank title mid-edit silently skips scheduling rather than erroring in the
  background).
- Toggle favorite/pin/publish inline without leaving the editor.
- Manually navigate back — always attempts a save first if dirty.
- Delete — opens a confirm dialog (*"Delete Note"* / *"Are you sure you want to delete this
  note?"*), unlike the list's undo-snackbar pattern, because this flow pops immediately after
  deleting and an undo window doesn't fit as naturally as it does in a persistent list.

**Acceptance criteria:**
- Saving with a blank title is blocked with a visible snackbar (*"Title cannot be empty."*) and
  never silently discards content.
- The dirty/saved pill accurately reflects real unsaved state at all times, including immediately
  after a save and immediately after a fresh edit following one — no stuck-"Saved" or stuck-
  "Unsaved" states.
- Autosave never fires a redundant duplicate save if a manual save/navigation-away already just
  happened.
- Publish toggled from here correctly shows the same recipient-confirmation dialog as the list, and
  correctly declines to flip local state if that dialog is cancelled.

## 17. Feed (`FeedPage`, Feed tab)

**Purpose:** a combined, chronological view of your own and your friends' published notes.

**Content:**
- One card per published note: author (**"You"** for your own posts, otherwise **@username**),
  publish time, title, content, a like button + tappable, bold, primary-colored count, a comment
  icon + count, and a **"Read-only"** badge (signaling this is a shared copy, not the live
  original).
- Cards fade+slide into place in a staggered sequence on first load.
- Loading: skeleton shaped like the card list. Empty: **"No shared notes yet — When your friends
  publish notes, they will appear here."**

**User actions:**
- Pull to refresh.
- Like/unlike a card directly from the feed (optimistic, with a haptic and an icon spring-pop).
- Tap the like count to open the "liked by" panel (§21).
- Tap a card or its comment icon to open the post-detail page (§18).

**Acceptance criteria:**
- The feed never shows a friend's post to someone who isn't currently a listed recipient, and
  always shows the viewer's own posts regardless of recipient status.
- Liking/unliking updates the count and icon immediately, and reconciles with the server silently
  on success or reverts (with an error snackbar) on failure.
- The unseen-post nav badge (§19) accurately reflects posts published since the user's last feed
  visit, and never counts the viewer's own posts as unseen.

## 18. Post detail (`FeedPostDetailPage`)

**Purpose:** full view of one published note plus its comments, reached from the feed.

**Content:**
- Author, publish time, full title/content (expandable if long, via `ExpandableText`'s smooth
  height animation), a like row (icon + tappable count), then a "Comments (N)" section listing every
  comment inline (author, text, date) with a text box at the bottom to add a new one.
- Loading: a skeleton for the comments section specifically (the header content above it isn't
  re-fetched, so it renders immediately).

**User actions:**
- Like/unlike.
- Tap the like count to open the "liked by" panel (§21).
- Read/expand the full note content.
- Post a new comment (blocked client-side if empty; 500-char cap enforced by both the logic layer
  and, ultimately, the database).

**Acceptance criteria:**
- The 500-character comment cap is enforced identically whether or not the client-side check is
  somehow bypassed (the database CHECK constraint is the real guarantee).
- Posting a comment updates the visible comment count and list immediately without requiring the
  user to leave and re-enter the page.

## 19. Friends & Feed navigation shell

**Purpose:** the persistent app frame hosting Notes/Feed/Friends as sibling tabs plus a global
Profile entry point.

**Content:**
- A frosted/translucent bottom `NavigationBar` (blurred content visible through it) with three
  destinations — Notes, Feed (badge = unseen post count), Friends (badge = pending incoming request
  count) — each badge bouncing in with a spring-pop the moment its count goes from zero to
  non-zero.
- A persistent Profile icon in the app bar, present on all three tabs.
- A soft background gradient behind the tab content, consistent across all three tabs.

**User actions:**
- Switch tabs (each tab's scroll/search/loaded-data state is preserved across switches via
  `IndexedStack`, not reset).
- Open Profile from any tab.

**Acceptance criteria:**
- Switching tabs never resets a tab's search box, scroll position, or already-loaded data.
- Badge counts are accurate at all times and animate in exactly once per zero-to-nonzero
  transition, never replaying on every rebuild.

## 20. Friends (`FriendsTab`, Friends tab)

**Purpose:** manage the friend graph — find and add people, respond to requests, review current
friends.

**Content:** four sections, each its own bounded card:
- **Search** — a username search box + **Search** button; results show avatar/username and a
  `FriendStatusButton` (Friends tick / Requested / Add Friend) reflecting real status, not a blind
  "Add." No matches: **"No users found. Make sure the username is correct."**
- **Incoming requests** (count badge, spring-pop on a new arrival) — each row: avatar/username +
  **Accept**/**Decline**. Empty: **"No pending incoming requests."**
- **Sent requests** — removable chips (one per pending outgoing request); tapping a chip's delete
  icon cancels that request. Empty: **"No pending outgoing requests."**
- **Friends** (count in the heading) — avatar/username + how long you've been friends + a
  remove-friend icon (confirmation dialog: *"Remove Friend"* / *"Remove @username from your
  friends? You'll need to send a new friend request to reconnect."*). Empty: **"No friends yet."**

All four sections' content smoothly resizes (`AnimatedSize`) as their state changes, rather than
snapping.

**User actions:**
- Search for a username and see their real connection status before deciding to add them.
- Send/accept/decline/cancel a request; unfriend an existing friend.

**Acceptance criteria:**
- A search result for someone already a friend or already pending never shows an actionable "Add"
  control that would just produce a rejection error if tapped.
- Accepting a request correctly creates exactly one `friendships` row (canonical low/high order),
  never a duplicate.
- Every section's empty/populated transition animates smoothly, with no instant layout jump.

## 21. "Liked by" panel (`liked_by_sheet.dart`, PR #57)

**Purpose:** show who liked a specific post, and help the viewer discover/add people they share
mutual friends with.

**Content:** a floating, centered, rounded panel (not a full page, not an edge-to-edge bottom
sheet) with the rest of the screen visibly blurred behind it. Header: "Liked by" + a close icon.
Body: one row per liker — **you first** if you liked it too (labeled "You", no status button), then
friends (Friends tick), then everyone else (a mutual-friend-count subtitle once it resolves, and an
Add Friend button). Loading: a centered spinner. Empty (nobody has liked it, and the viewer hasn't
either): **"No likes yet."**

**User actions:**
- Tap outside the panel (on the blurred backdrop) or the close icon to dismiss.
- Tap "Add Friend" on a non-friend row — sends a request and optimistically flips that row to
  "Requested" without reloading the list.

**Acceptance criteria:**
- If the viewer is the only liker, the panel shows them as "You" at the top — never a misleading
  "No likes yet" (a real bug found and fixed live during this PR).
- Mutual-friend counts never expose the other person's actual friend list, only a number.
- The panel never shows an actionable Add-Friend control for someone already a friend, already
  pending, or the viewer themselves.

## 22. Profile (`NotesProfilePage`)

**Purpose:** manage your own identity — avatar, username, password.

**Content:** three sectioned cards:
- **Avatar** — current picture (crossfades on change) + **"Change profile picture"** (opens the
  device photo gallery; images are resized/compressed before upload). Success: **"Profile picture
  updated."**
- **Username** — one field, **"Save username"**. Success: **"Username updated."**
- **Password** — new/confirm fields (with visibility toggles), **"Update password"**. Success:
  **"Password updated."**, clears both fields.

Loading: a skeleton shaped like all three sections.

**User actions:** upload a new avatar; change username; change password.

**Acceptance criteria:**
- Every field validates client-side using the same rules as §14.1 before ever hitting the network.
- An unsupported avatar file type/size shows the specific, correct message (§14.9), not a generic
  failure.
- A successful password change clears both password fields (never leaves a stale value visible).

## 23. Auth: Login / Register (`NotesAuthPage`)

**Purpose:** the entry point for signed-out users.

**Content:** a single card headed **"Welcome to Notes"**, with a circular icon badge, a Login/
Register segmented toggle, Email + Password (Register adds Username above, Confirm password
below, both with visibility toggles), and a **"Forgot password?"** link (Login mode only).

**User actions:** register; log in; request a password reset; resend a confirmation email (once
shown, post-registration).

**Acceptance criteria:**
- Client-side validation (§14.1) catches invalid email/username/password shape before any network
  call.
- The forgot-password flow's response is identical regardless of whether the email is actually
  registered (no account-existence leak).
- Every distinct auth failure shows its own specific, correct message (§14.9), never a raw
  Supabase error string.

## 24. "Confirm your email" gate (`NotesActivationRequiredPage`)

**Purpose:** block access to the app until the account's email is confirmed.

**Content:** a single card: **"Please confirm your email to activate your account."** + **"Back to
login"** (signs out).

**User actions:** sign out and return to login.

**Acceptance criteria:** an unconfirmed account can never reach any authenticated screen, even
though Supabase itself did issue a session for it.

## 25. Set a new password (`ResetPasswordPage`)

**Purpose:** complete a password-reset flow, reached only via an emailed reset link.

**Content:** New password + Confirm new password (both with visibility toggles, 6-char minimum,
must match).

**User actions:** set a new password.

**Acceptance criteria:** on success, pops back to wherever the app was and shows **"Password
updated. You can now log in with it."**; the flow is reachable from any screen the user happened
to be on when the link opened the app (global-navigator push, §12).

---

# PART IV — ACCEPTANCE CRITERIA

Part III already states page-level acceptance criteria. This part states what "done" means one
level up (a whole functional module) and one level up from that (the project as a whole).

## 26. Module-level acceptance criteria

**Auth & Account** — accepted when: every distinct failure mode (bad password, unconfirmed email,
duplicate email/username, same-password rejection, rate-limiting) shows its own correct,
non-generic message; a user can complete signup → confirm → login → forgot/reset password → change
username/avatar/password without ever hitting a dead end or an unhandled raw error.

**Notes CRUD** — accepted when: create/edit/delete/pin/favorite/search all work with no data loss
under normal use (including autosave and app backgrounding mid-edit); delete is always recoverable
for a few seconds via undo, from both entry points (menu and swipe); search matches title and
content correctly and case-insensitively.

**Friends & Social Graph** — accepted when: the full request lifecycle (send/accept/decline/
cancel/unfriend) is provably free of duplicate-friendship or duplicate-pending-request states; every
person row anywhere in the app (search results, liked-by list) shows accurate real-time connection
status via the shared `FriendStatusButton`, never a stale or misleading control.

**Publishing & Feed** — accepted when: publishing always reaches exactly the friend set confirmed
in the pre-publish dialog; the feed never leaks a post to a non-recipient at the RLS layer
regardless of what the UI shows; unpublishing fully removes a post and its engagement data with no
orphaned rows.

**Engagement (Likes/Comments/Liked-by/Mutuals)** — accepted when: like/comment counts are always
consistent between the feed card, the detail page, and the liked-by panel; the liked-by panel never
misrepresents "nobody liked this" when the viewer themselves did; mutual-friend counts are correct
and never leak the other party's actual friend list.

**Profile** — accepted when: avatar/username/password changes all succeed or fail with a specific,
correct message, and a successful change is reflected everywhere that data appears (list, feed,
comments, liked-by) without requiring an app restart.

**Visual/Motion Design System** — accepted when: every screen in the feature uses the shared dark
theme and shared animation primitives (no one-off colors, no un-animated conditionally-appearing
content); the app's identity (name, icon, splash) is consistent across every platform surface that
displays one.

**Testing Infrastructure** — accepted when: every `*Logic` method with non-trivial branching logic
has unit test coverage via its data source's fake, with the explicitly-accepted exception of a few
real-Supabase-only paths (`updateUsername`'s `auth.updateUser` call, `uploadProfileAvatar`'s storage
write, real RLS enforcement) that are integration-tested only, not silently untested.

## 27. Whole-project acceptance criteria

Since this is a learning project with no external users, "finished" is defined qualitatively, not
by a launch date or user-adoption metric:

- A user can manage notes and their entire social graph (friends, publishing, engagement,
  discovery) with no dead ends, silent failures, or misleading states.
- Every account/auth edge case shows an accurate, specific message — never a generic or misleading
  one.
- The UI is visually and behaviorally consistent across every screen in the feature — one design
  system, one motion language, applied everywhere, not just the first screen built.
- Each shipped increment stays small, is unit-tested where the logic is pure, and is live-verified
  (not just reviewed) before merge — the collaboration pattern established for this repo from PR #1
  onward and never abandoned as the project grew.
- Changes to shared infrastructure (the `auth.users` trigger, the root deep-link listener, shared
  widgets like `FriendStatusButton`/`PopOnChange`/`NotesErrorBanner`) are explicitly regression-
  checked against every consumer, not just the one that motivated the change.
- New backend-touching changes (new tables, RLS policies, or RPC functions) get a dedicated
  design/validation pass before implementation — either a live Plan-agent review or equivalent
  scrutiny — given this project's own history of RLS bugs that only live testing ever caught.
- The product's actual differentiator (a closed, mutual friend-graph with lightweight publishing
  and engagement — §4) stays legible in the UI rather than getting lost under generic notes-app or
  generic social-app conventions borrowed without a reason tied back to that differentiator.

---

# PART V — END-TO-END USER FLOWS

**A. New user signs up, writes a note, and shares it:**
1. Opens Notes → sees `NotesAuthPage` (not logged in).
2. Switches to Register, enters username/email/password/confirm, submits.
3. Gets *"Account created. Check your email to confirm it..."*, follows the email link (which
   also confirms the account), returns and logs in.
4. Lands on the empty notes list (skeleton, then the real empty state), taps **New**, types a
   title, is dropped into the editor, writes content (autosaves), backs out.
5. Adds a friend first (Friends tab → search username → sees "Add Friend" since not yet connected
   → sends → friend accepts), since publishing with zero friends is blocked.
6. Back on the notes list, opens the note's overflow menu, taps **Publish to friends**, confirms
   the recipient list in the dialog. The note now shows the **"Shared with friends"** pill.
7. Their friend opens their own Feed tab (staggered card entrance), sees the new post, can like/
   comment on it, and tap the like count to see who else liked it.

**B. Forgotten password (web):**
1. On `NotesAuthPage`, taps **"Forgot password?"**, enters email, gets the neutral
   "if an account exists..." message regardless of outcome.
2. Follows the emailed link → app opens, the root auth listener detects the recovery event, reads
   the `app` metadata tag (`'notes'`), and pushes `ResetPasswordPage` directly, bypassing whatever
   screen was open.
3. Sets a new password, confirmation snackbar shown, returns to the app and logs in normally with
   the new password.

**C. Friend-request lifecycle:**
1. A sends B a request → B sees it under "Incoming requests" with a badge (spring-pop on arrival);
   A sees it under "Sent requests" as a chip.
2. B declines → request status becomes `declined`; it disappears from both lists (only *pending*
   requests are shown), each section's card smoothly resizing rather than snapping.
3. A can send a new request to B any time after that (no cooldown), repeating step 1.
4. Alternatively, A could have cancelled the request themselves before B responded, which also
   just changes the status (to `cancelled`) rather than deleting the row.

**D. Discovering a mutual connection through engagement (PR #57):**
1. A publishes a note; both B (a friend of A) and C (a stranger to A's viewer, D) like it.
2. D — a friend of B, but not yet connected to C — opens the post and taps the like count.
3. The "liked by" panel shows B at the top (Friends tick, since D and B are already connected),
   then C below with a mutual-friend count (D and C share at least one mutual friend, likely B) and
   an **Add Friend** button.
4. D taps **Add Friend** on C's row — it flips to "Requested" immediately; C later sees the
   request appear under their own "Incoming requests" and can accept it, completing the
   discovery-to-connection loop the feature was built for.

---

## Glossary

- **Shared note**: the *published copy* of a note visible in the feed — distinct from the private
  original in `notes`; editing the original after publishing does not update the shared copy
  unless you republish.
- **Recipient**: a friend who can see a specific published note; recipients are only ever added
  during publish, never removed automatically (e.g. unfriending someone doesn't retroactively hide
  old shared posts from them).
- **Own post**: a feed item where you are the author, shown labeled "You" rather than a username.
- **Liker**: anyone who has liked a specific published note; shown in that note's "liked by" panel.
- **Mutual friends**: friends the current user and another person both have in common — computed
  server-side via a privacy-preserving RPC (§13.6) that never exposes either party's actual friend
  list, only a count.
- **Friend status**: one of three states (`friend`, `pending`, `none`) shown via the shared
  `FriendStatusButton` on any person row anywhere in the app, so the same person never shows
  inconsistent or misleadingly-actionable controls in different places.
- **Activation** / **confirmed email**: Supabase's built-in email-confirmation state; the app
  treats an unconfirmed account as functionally logged-out (auto-signs-out and shows the
  activation gate) even though Supabase itself did issue a session.
