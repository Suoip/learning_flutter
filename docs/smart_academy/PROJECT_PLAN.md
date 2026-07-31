# SmartAcademy — Project Plan

**Status:** Retroactive pre-project plan, written after initial development (PR #17–#28) to
formalize direction for everything ahead. Where this doc describes something already shipped,
that's noted explicitly — treat those sections as "confirm this is still true" rather than
"design from scratch."

---

## 1. Vision

SmartAcademy is a coding-education hub inside the `learning_flutter` app, modeled loosely on
YouTube/Twitch/Kick: a curated, public discovery surface (the **hub**) where anyone can browse
video lessons and forum-style posts, plus individual **educator** accounts that own and publish
that content from their own dashboard and public channel page.

It is a sibling feature to the app's original Notes project, not a variant of it — different
users (educators, not Notes' personal-notes users), different content model, and a deliberately
separate account system, though both live in the same Flutter app and the same Supabase project.

## 2. Problem / motivation

This is a learning repo — the underlying motivation is to practice building a second,
structurally different full-stack feature (multi-author public content + engagement, vs. Notes'
private-content-shared-with-friends model) inside an existing codebase without disturbing what
already works. There is no external user base or business pressure; scope and sequencing are
driven by what's most useful to build and learn next, decided collaboratively PR by PR.

## 3. Goals

- Let an **educator** register, build a profile, and publish video lessons and forum posts.
- Let **anyone** (including signed-out visitors) discover that content on a public hub: browse,
  search, filter by content type, and read/watch.
- Let signed-in visitors (educator or Notes account) engage with content — like and comment.
- Give each educator a public channel page other people can find and browse.
- Keep the feature additive: it must never change behavior for existing Notes users or data.

### Non-goals (for now)

- Payments, subscriptions, or any monetization.
- Live streaming or real-time video.
- Moderation tooling, reporting, or admin roles.
- Notifications (new likes/comments/followers).
- A unified single account system spanning Notes and SmartAcademy.

## 4. Target users

| Persona | Description | Needs |
|---|---|---|
| **Educator** | Registers specifically to teach/publish. | Simple auth, a dashboard to manage their own videos and posts, a public presence (channel page), basic profile customization (avatar, username). |
| **Visitor (signed out)** | Anyone landing on the hub. | Browse and search all content, watch/read it, find an educator's channel — with zero friction, no forced signup. |
| **Signed-in participant** | Either a Notes user or an educator, browsing SmartAcademy. | Everything a visitor can do, plus liking and commenting. |

Note the deliberate asymmetry: an *educator* account is required to **publish**, but not to
**consume or engage** — engagement is open to any authenticated identity in the shared Supabase
project, Notes users included. This was a conscious tradeoff (see §8) rather than an oversight.

## 5. Scope

### 5.1 In scope, already shipped

- **Educator accounts** — register/login/forgot-password, separate from Notes, sharing the
  underlying Supabase `auth.users` pool via a metadata tag (`app = 'smart_academy'`).
- **Educator profile** — username, avatar upload, password change.
- **Content authoring (educator-only, own content)** — create/edit video entries (metadata only:
  title, description, duration label — no file upload) and forum posts.
- **Public hub** — a Videos section and a separate Forum section, both populated from all
  educators' real content, newest-first.
- **Search & filter** on the hub — by title or author name, and by content type (All/Video/Forum).
- **Detail pages** — YouTube-watch-page style: full content, expandable description, likes, and
  an inline (not modal) comment list, for both videos and forum posts.
- **Engagement** — like/unlike and comment, open to any signed-in account (educator or Notes).
- **Public educator channel pages** — reachable via hub username search or a link from an
  educator's own dashboard; shows their profile plus their videos/forum posts.
- **Non-educator gating** — a session that isn't a real educator (e.g. a Notes account that hit
  the shared-email collision path) is blocked from the dashboard with a clear message rather than
  silently erroring on save.

### 5.2 In scope, not yet started

- **Real video file upload and playback.** Currently videos are metadata-only (title,
  description, a free-text duration label) — there's no actual video asset, storage, or player.
  This is the single largest known gap and the next big scoped decision (storage strategy,
  transcoding/format constraints, playback widget, upload UX, file size limits).

### 5.3 Explicitly out of scope

See Non-goals (§3). Additionally not planned: comment editing/deletion, notifications, a
follow/subscribe mechanic, view counts, or discovery beyond search+filter (no recommendation
system).

## 6. Feature breakdown

| Area | Capability | Status |
|---|---|---|
| Auth | Register / login / forgot-password (educator) | ✅ Shipped |
| Auth | Non-educator detection & gating | ✅ Shipped |
| Profile | Avatar, username, password | ✅ Shipped |
| Content | Video CRUD (metadata only) | ✅ Shipped |
| Content | Forum post CRUD | ✅ Shipped |
| Content | **Real video upload/playback** | ⬜ Not started |
| Discovery | Public hub (Videos + Forum sections) | ✅ Shipped |
| Discovery | Search / filter | ✅ Shipped |
| Discovery | Public educator channel page | ✅ Shipped |
| Engagement | Likes (video + forum) | ✅ Shipped |
| Engagement | Comments, inline display (video + forum) | ✅ Shipped |
| Engagement | Comment edit/delete | ⬜ Not planned |
| Growth | Notifications | ⬜ Not planned |
| Growth | Follow/subscribe | ⬜ Not planned |

## 7. Technical approach

- **Client:** Flutter, following the same layered pattern as Notes — a `*Logic` class
  (`EducatorLogic`) orchestrating pure business rules, delegating persistence to small
  `*DataSource` interfaces with a real Supabase implementation and a fake for unit tests.
- **Backend:** Supabase (Postgres + Row-Level Security + Storage), one shared project with Notes.
  Schema lives in `backend/sql/`, applied as sequential numbered migrations
  (`005_educators.sql` → `011_educator_video_engagement.sql` so far).
- **Data model (current):** `public.educators` (own row per educator, FK'd to `auth.users`),
  `public.educator_videos` and `public.educator_forum_posts` (each FK'd to `educators`, not
  `auth.users`, for a real ownership guarantee at the database level), plus like/comment tables
  per content type. All content tables are public-readable; writes are owner-scoped via RLS.
  Avatars live in a dedicated `educator-avatars` Storage bucket.
- **Account separation:** one Supabase project, two logical account types, disambiguated via
  `auth.users.raw_user_meta_data.app`. A single `handle_new_auth_user()` trigger branches on that
  tag to create either a Notes `profiles` row or an `educators` row.
- **Testing:** unit tests over `EducatorLogic`'s pure/testable-with-fakes surface
  (`test/educator_logic_*.dart`), mirroring Notes' existing test suite structure.

## 8. Key decisions already made (and why)

- **One shared Supabase project, not two** — avoids duplicating Supabase project config,
  accepted the tradeoff that a Notes-registered email can't also register as an educator (project-
  wide `auth.users` email uniqueness); that collision path is handled explicitly (falls through to
  sign-in, then gets gated out of the dashboard) rather than left as a bug.
- **Engagement open to any signed-in identity, not educator-only** — chosen deliberately so
  Notes users can participate in SmartAcademy discussions without needing a second account. Known
  accepted tradeoff: a fully signed-out viewer can't always resolve a Notes-user commenter's
  identity (Notes' own profile-read privacy boundary), and there's no single "sign in" entry point
  spanning both account types — the like/comment UI simply goes inert with an explanation when
  signed out.
- **Videos/Forum stay visually separate**, never merged into one feed — on both the hub and the
  dashboard, each with independent loading/error/empty state, so one section failing doesn't
  block the other.
- **Metadata-only videos as a deliberate phase boundary** — file upload was scoped out
  repeatedly so the account/content/engagement model could be validated end-to-end first.
- **SmartAcademy duplicates rather than shares UI code with Notes**, even for near-identical
  widgets (e.g. avatar circle), matching this repo's existing convention — accepted extra
  duplication in exchange for zero coupling between the two features.

## 9. Risks & open questions

| Risk / question | Notes |
|---|---|
| Video upload strategy undecided | Needs a decision on storage (Supabase Storage vs. external), max file size/duration, allowed formats, and whether transcoding is needed before this can be scoped as a PR. |
| No moderation | Public write access (likes/comments) with no reporting/removal path beyond the content owner deleting their own post. Acceptable for a learning project's current scale; revisit if that changes. |
| Discovery scales linearly | Hub queries are capped at 50 most-recent items with no pagination; fine at current content volume, will need pagination once that's no longer true. |
| Cross-account UX gap | No single sign-in surface spanning Notes + SmartAcademy; a visitor with only a Notes account must understand two separate login flows to engage. Accepted for now (§8), worth revisiting if it causes real confusion. |

## 10. Suggested roadmap (next steps, unsequenced)

The user sequences PRs one at a time rather than committing to a fixed roadmap order up front;
the items below are the known candidates, not a committed order:

1. **Real video upload/playback** — the largest remaining gap (see §5.2, §9).
2. Pagination for the hub once content volume warrants it.
3. SmartAcademy already inherits the same base dark theme colors/typography as Notes (the theme is
   applied globally at the `MaterialApp` root, not per-feature), but has none of the loading-
   skeleton/crossfade/spring-pop motion language Notes built up across its own UI-polish initiative,
   now fully shipped (see [../notes/PROJECT_PLAN.md](../notes/PROJECT_PLAN.md)). Bringing that same
   motion language to SmartAcademy is a candidate worth considering on its own merits, not blocked
   on anything in Notes being incomplete anymore.
4. Any of the "not planned" items in §6 (comment editing, notifications, follow/subscribe) if
   priorities change.

## 11. Success criteria

Since this is a learning project with no external users, "success" is defined qualitatively:

- An educator can go from zero to a published, discoverable piece of content with no dead ends.
- A signed-out visitor can discover and consume all public content without hitting a login wall.
- The feature has not introduced any regression in Notes (verified live after each PR that
  touches shared infrastructure, e.g. the `auth.users` trigger).
- Each shipped increment is small, reviewed, tested, and live-verified before merge — consistent
  with the collaboration pattern already established for this repo.
