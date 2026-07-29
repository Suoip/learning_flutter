# Notes App — UI Improvement Plan

**Goal:** make Notes more user-friendly, easier to navigate, and better-looking, without changing
what it *does* (this is a UI/UX pass, not a feature-scope change — see
[PROJECT_PLAN.md](PROJECT_PLAN.md) for functional scope).

This plan is organized as: (1) an audit of the current state and why it's friction-y, (2) the
proposed direction, (3) a screen-by-screen change list, (4) phasing, (5) explicit non-goals and
open decisions for you to weigh in on.

---

## 1. Current-state audit

### 1.1 Navigation structure — the biggest friction point

Today, Notes has **no persistent navigation** at all. It's a single home screen (`NotesPage`)
with everything else reached by drilling into a full-screen page and back:

```
NotesPage (notes list)
 ├─ AppBar icon → NotesSocialPage (Friends & Feed, its own 2-tab bar) → back
 ├─ AppBar icon → NotesProfilePage → back
 └─ tap a note  → NoteEditorPage → back
```

Problems this causes:
- **The Feed (a "check what's new" surface) is buried two taps deep** behind an icon most users
  won't associate with "feed" (a groups/people icon, not a feed/home icon), and behind a second
  tab once there.
- **No way to tell "there's new activity" at a glance** beyond the friend-request count badge —
  nothing surfaces "a friend published something new" or "someone liked/commented on your post"
  anywhere in the shell.
- **Every trip to Friends or Profile is a full navigation stack push** — there's no quick way to
  glance at your friend list without losing your place in the notes list (scroll position,
  search/filter state are preserved by Flutter's navigation stack today, so this is a minor point,
  but it still *feels* heavier than it needs to be for something used often).
- Mental model mismatch: on the two-tab `NotesSocialPage`, "Friends" (a management screen) and
  "Feed" (a content-consumption screen) are functionally very different but presented as equally-
  weighted siblings.

### 1.2 Visual consistency

The good news: the dark theme (`AppTheme.dark`) is applied globally, and a scan of every Notes
screen file found **zero hardcoded colors** outside `home_navigation_page.dart` (the cross-project
dashboard, where per-project color-coding is intentional). So screens *do* inherit the theme's
colors, typography, card/button/input styling automatically — the "only the list screen is
themed" characterization from earlier PRs undersold this; what's actually missing is **layout and
polish work**, not raw re-theming:

- `NoteEditorPage` is a bare title field + divider + content field — functional, but has no visual
  distinction from a plain text editor; no sense of "this is a note," no metadata (last-edited
  time isn't shown while editing, only in the list).
- `NotesAuthPage`'s login/register form is a single long vertical `Card` — standard, but doesn't
  establish any brand personality (no illustration/icon treatment beyond one small icon, per the
  existing spec).
- Friends tab (§14.6 of the functional spec) stacks four independent sections (search, incoming,
  sent, friends list) vertically with heading text only to separate them — no visual grouping
  (e.g., card boundaries) between very different concerns, so it can read as a wall of similar-
  looking rows.
- The Feed's comments are a **modal bottom sheet** (`FeedCommentsSheet`), while SmartAcademy
  (built later, reusing Notes' patterns) deliberately moved *away* from a modal sheet to inline
  comments on its detail page, explicitly because the sheet felt like an extra hop. Notes never
  got that same follow-up.
- Empty/loading/error states exist on every screen but are styled minimally (icon + two lines of
  text) — consistent, but generic; no differentiation in tone between e.g. "no notes yet" (a new
  user) vs. "no friends yet" (a specific, actionable gap).

### 1.3 Interaction friction (smaller, but real)

- Publishing is all-or-nothing to every current friend, with no confirmation of *who* it went to
  — a user has to trust it worked rather than see it.
- Deleting a note requires: swipe → confirm dialog. Two motions for a common, low-risk-to-undo
  action (there's no undo/snackbar-recovery either — deletion is immediate and final once
  confirmed).
- Note list rows pack three icon toggles (favorite/pin/publish) plus a title into one line, which
  is a lot of tappable targets close together, especially on a phone-width screen.
- Search only matches titles (a functional gap, not visual, but it undermines trust in the search
  box if a user expects it to find notes by content and gets no results).

---

## 2. Proposed direction

### 2.1 Add persistent bottom navigation (the headline change)

Replace the "drill into a full page" model with a **bottom navigation bar** with three
destinations:

| Tab | Replaces | Icon idea |
|---|---|---|
| **Notes** | `NotesPage` (unchanged content) | note/list icon |
| **Feed** | the Feed half of `NotesSocialPage` | home/feed icon, badge for unseen items* |
| **Friends** | the Friends half of `NotesSocialPage` | people icon, existing request-count badge |

Profile moves to a persistent icon in the top app bar (present on all three tabs, not just Notes),
rather than being buried inside any one tab — it's an identity/settings surface, not a content
tab.

This directly fixes §1.1: Feed becomes a first-class, one-tap destination instead of two taps deep
behind a Friends-shaped icon; Friends and Feed stop being artificially merged into one screen with
a sub-tab-bar of their own (removing a layer of navigation, not adding one — net UI is simpler).

*"Unseen items" badge on Feed is a stretch goal — see §4 Phase 3; the request-count badge on
Friends already exists today and just moves location.

### 2.2 Visual polish pass per screen (not a re-theme — a layout/hierarchy pass)

Since the color/type system is already sound and consistently applied, this is about **improving
layout, spacing, and information hierarchy** within the existing design language, not introducing
new colors or a new typeface. Concretely: giving the editor a header treatment, grouping the
Friends tab into distinct visual sections, moving Feed comments inline (matching SmartAcademy's
now-established, deliberately-chosen pattern), and reducing icon-crowding on note rows.

### 2.3 A few targeted interaction fixes

Small, low-risk changes that meaningfully reduce friction: an undo affordance on delete, a "who
did this go to" confirmation on publish, and title+content search.

---

## 3. Screen-by-screen change list

### 3.1 App shell (new)

- Add a `Scaffold` with `bottomNavigationBar: NavigationBar` (Material 3 component — already
  compatible with the existing theme's surface/color tokens without new styling work) hosting
  Notes / Feed / Friends.
- Add a persistent Profile icon button to a shared app bar across all three tabs (currently only
  exists on `NotesPage`'s app bar).
- Preserve each tab's scroll/search state when switching tabs (`IndexedStack` or equivalent, not
  a plain route swap, so switching tabs doesn't reset the notes search box or feed scroll
  position).

### 3.2 Notes list (`NotesPage`)

- No structural change — it's already the best-polished screen. Consider: separating the three
  icon toggles on each row with slightly more spacing, or moving less-frequently-used actions
  (e.g. publish/unpublish) behind a per-row overflow menu (`⋮`) instead of a permanent icon, to
  reduce row density. **Decision point:** this is a density-vs-discoverability tradeoff — worth
  a quick look at the live screen together before committing either way.

### 3.3 Note editor (`NoteEditorPage`)

- Add a lightweight header above the title field showing last-edited time (currently only visible
  from the list, not while editing) and the pin/favorite/publish toggles here too, so publishing
  doesn't require backing out to the list first.
- Add an undo affordance: instead of a confirm dialog before delete, delete immediately and show
  a snackbar with an **Undo** action for a few seconds (standard, lower-friction pattern than a
  blocking dialog for a reversible-for-a-few-seconds action). **Decision point:** whether to keep
  the confirm dialog for extra safety instead — reasonable to prefer either.

### 3.4 Feed (new standalone tab, was half of `NotesSocialPage`)

- Move comments from a modal `FeedCommentsSheet` to an inline expandable section on each card (or
  a dedicated post-detail screen, mirroring SmartAcademy's `SmartAcademyDetailPage` pattern) —
  this also opens the door to eventually showing the full note content without truncation, similar
  to how SmartAcademy's `ExpandableText` works.
- Add a pull-to-refresh-triggered "you're all caught up" affirmation at the top when there's
  nothing new, to reinforce that an empty/short feed isn't a loading failure.

### 3.5 Friends (new standalone tab, was half of `NotesSocialPage`)

- Group into visually distinct `Card` sections (Search / Incoming / Sent / Friends) instead of
  plain heading-separated blocks, so the very different concerns (searching vs. managing existing
  relationships) read as distinct at a glance.
- Consider collapsing "Sent requests" into a smaller, less prominent element (e.g. inside an
  expandable section) when empty or small, since it's the least frequently useful of the four
  sections once a user's graph is established.

### 3.6 Auth (`NotesAuthPage`)

- Add a small amount of visual identity (an app icon/wordmark treatment) above the segmented
  Login/Register toggle — currently just one small icon per the existing spec; low-effort, meaningfully
  improves first impression since it's the very first screen many users see.
- No functional change to the form itself (validation/error messaging already solid per the
  functional spec).

### 3.7 Profile (`NotesProfilePage`)

- No major layout change needed — already sectioned (Avatar / Username / Password). Main change
  is relocating *entry* to it (persistent icon across tabs, §3.1), not its own internal layout.

---

## 4. Phasing

**Phase 1 — Navigation restructure** ✅ **Shipped** (PR #30): bottom nav bar (Notes / Feed /
Friends), persistent Profile icon, state preservation across tabs via `IndexedStack`.

**Phase 2 — Per-screen polish** ✅ **Shipped** (PRs #31–#35), once the shell was stable:
- Notes list: publish toggle moved behind a per-row overflow menu, favorite/pin stay inline (PR #31).
- Friends tab: Search/Incoming/Sent/Friends each grouped into a bounded `Card` (PR #32).
- Auth screen: header icon wrapped in a `primaryContainer` circular badge (PR #33).
- Note editor: last-edited header + inline favorite/pin/publish toggles; also fixed a real latent
  bug where the `PopScope` autosave-on-back handler never actually fired (PR #34).
- Feed: comments moved from a modal sheet to a dedicated `FeedPostDetailPage` (mirroring
  SmartAcademy's `SmartAcademyDetailPage` pattern, including a duplicated `ExpandableText`),
  reached by tapping a card or its comment icon (PR #35).

**Phase 3 — Interaction refinements** ✅ **Shipped** (PRs #36–#38):
- Search matches note content in addition to title (PR #36).
- Publishing (not unpublishing) shows a confirmation dialog listing the friends it'll go to,
  capped at 8 usernames + a count for larger lists (PR #37). `_togglePublish` now reports back
  whether the toggle actually happened, so the editor's inline toggle (Phase 2) correctly declines
  to flip its local state when the dialog is cancelled.
- Swipe-to-delete replaced with delete-then-undo-snackbar, no confirm dialog (PR #38) — the
  editor's own delete button deliberately keeps its confirm dialog, since it pops immediately
  after deleting and an undo window doesn't fit that flow as naturally as a persistent list.

**Phase 4 — Unseen feed badge** ✅ **Shipped** (PR #39): new server-synced `public.feed_read_state`
table (one row per user, `last_seen_at`) backs a live count badge on the Feed bottom-nav
destination for friends' posts published since the user's last visit. Deliberately scoped to new
posts only, not engagement (likes/comments) on your own posts — see §6 below.

All four phases of this UI improvement plan are now shipped (PRs #30–#39).

Each phase should still ship as multiple small, sequential PRs per this repo's established
convention (see [PROJECT_PLAN.md §"Key decisions"](PROJECT_PLAN.md)), verified live before merge —
this plan describes *what*, sequencing into individual PRs is a follow-up planning step per PR as
usual.

---

## 5. Non-goals for this pass

- No new color palette, typeface, or design-system rework — `AppTheme`/`AppColors` are treated as
  settled; this plan works within them.
- No change to underlying data/business logic (publish-to-all-friends, 500-char comment cap, etc.)
  — purely presentation and navigation, except where phase 3 explicitly touches a small
  interaction (e.g. undo requires a soft-delete or optimistic-UI approach in the data layer, which
  is a small logic touch, called out there specifically).
- No redesign of SmartAcademy — out of scope for this doc entirely.

## 6. Decisions

1. ~~Bottom nav bar vs. keeping the current drill-down model~~ — **Resolved: bottom nav**, shipped
   in Phase 1.
2. ~~Delete: undo-snackbar vs. keep the confirm dialog~~ — **Resolved: undo-snackbar** for the
   notes list (the editor's own delete button keeps its confirm dialog), shipped in Phase 3
   (PR #38).
3. ~~Row density on the notes list~~ — **Resolved: publish moved behind an overflow menu**,
   favorite/pin stay inline, shipped in Phase 2 (PR #31).
4. ~~Feed comments: inline-on-card vs. dedicated detail screen~~ — **Resolved: dedicated detail
   screen**, matching SmartAcademy's pattern, shipped in Phase 2 (PR #35).

---

## 7. Round 2 audit (post Phase 1–4)

A fresh pass over every Notes screen now that Phases 1–4 are shipped, looking for what's still
rough. Five candidates, roughly in order of impact:

### 7.1 No desktop/wide-viewport adaptation

The whole feature — bottom `NavigationBar`, single-column `ListView`s everywhere (Notes, Feed,
Friends) — is a fixed phone-style layout regardless of window size (confirmed: zero use of
`MediaQuery`/`LayoutBuilder`/`NavigationRail`/breakpoints anywhere in `lib/pages/notes/`). This
runs on Flutter web and is likely often viewed at desktop widths, where a full-width bottom bar
and a single narrow column of notes is a poor use of space. Candidate: swap to a `NavigationRail`
(or keep the bottom bar but add a rail) above some width threshold, and let the notes/feed lists
reflow into a responsive grid at wide widths — mirroring the breakpoint ladder SmartAcademy's hub
already uses (`smart_academy_page.dart`, 1→2→3→4→5 columns at 480/840/1200/1600px).

### 7.2 Three divergent empty-state treatments, two divergent error-banner conventions ✅ Shipped

Notes' empty state (solid-fill card, `cs.primary`-colored icon, themed text) and Feed's empty state
(outlined card, default-colored icon, hardcoded `TextStyle`) were two different visual answers to
the same "whole tab is empty" concept — unified into one shared `NotesEmptyState` widget
(`lib/pages/notes/notes_empty_state.dart`), standardized on the outlined-card look (the more common
convention elsewhere in the app) with a `cs.primary`-tinted icon and theme-driven text styles.
Friends' inline "No pending requests."/"No friends yet." texts were deliberately **left as plain
text, not unified** — they're a lighter-weight sub-state inside an already-bounded section card
(Phase 2), and forcing the same heavy icon+card treatment in there would look nested/bloated.

Error banners were unified everywhere via a new shared `NotesErrorBanner`
(`lib/pages/notes/notes_error_banner.dart`), matching Notes/Feed's already-correct theme-aware
`cs.errorContainer`/`cs.onErrorContainer` style — Profile and Friends moved off their hardcoded
`Colors.red.shade50`/`Colors.red.shade700`.

### 7.3 Zero animation/transition anywhere

Confirmed via grep: no `AnimatedList`, `AnimatedSwitcher`, `AnimatedContainer`, or any implicit
animation anywhere in the feature. Concretely: deleting a note (post-undo-window) removes it from
a plain `ListView` via instant rebuild, not an animated collapse; switching bottom-nav tabs is an
instant `IndexedStack` swap; liking a post or toggling favorite/pin triggers a **full list
refetch** (`_loadFeed()`/`_loadNotes()`) rather than a local optimistic icon flip, so every one of
those actions has a visible full-list "flash" while it reloads instead of feeling instant.
Candidate: `AnimatedList` (or a simpler `AnimatedSize`/fade) for note removal, optimistic local
toggles for favorite/pin/like (update local state immediately, reconcile with the server response
in the background, roll back only on error) instead of reload-the-world.

### 7.4 Note editor rough edges

- ✅ **Shipped**: the "Saved" pill was misleading — `_hasSavedOnce` was set on first successful
  save and never reset, so it read "Saved" even mid-typing with real unsaved edits. Fixed by
  tracking the last-saved title/content snapshot and deriving a real `_isDirty` getter (compared
  against the raw, untrimmed field text — not the trimmed value sent to the backend, otherwise
  trailing whitespace alone would leave the pill stuck on "Unsaved changes" forever). The pill now
  shows "Unsaved changes" (`primaryContainer`) while dirty, "Saved" (`secondaryContainer`,
  unchanged color) once clean and saved at least once, or nothing on a freshly-opened, untouched
  note.
- No autosave while typing (only on explicit Save or on navigating back) — a crash or browser
  refresh between saves loses unsaved edits. **Not bundled with the pill fix** (see §8.3) — left
  open.
- No word/character count, no keyboard shortcuts (confirmed: no `Shortcuts`/`CallbackShortcuts`
  anywhere in the feature — no Ctrl+S, no Escape-to-go-back). Still open.

### 7.5 Two small, concrete fixes ✅ Shipped

- `notes_profile_page.dart`'s AppBar back button was the one icon-only button in the whole feature
  missing a `tooltip:` — added (`'Back'`).
- `note_list_tile.dart`'s overflow `PopupMenuButton` (·) had no tooltip override, falling back to
  Flutter's generic default ("Show menu") — added `tooltip: 'More options'`.

### Non-goals carried forward

Same as §5 — no color/typeface rework, no SmartAcademy changes. Additionally: no rich-text/
markdown editor (7.4's word-count/shortcuts are small affordances, not an editor rewrite), no
light theme (7.2's error-banner fix is about using existing theme tokens correctly, not adding a
new theme).

## 8. Round 2 decisions

1. ~~Desktop layout (§7.1)~~ — **Deferred, not planned.** The app's main purpose is mobile; web is
   only used for faster local testing/iteration. A responsive desktop pass isn't worth the scope
   against that reality — revisit only if the project's primary usage target changes.
2. **Order for the rest**: (a) the two tooltip fixes (§7.5) + the editor "Saved" pill bug (§7.4)
   first — small, unambiguous fixes; (b) empty-state/error-banner unification (§7.2) next — same
   shape as Phase 2's polish work; (c) animations (§7.3) last, scope (just the instant-snap fixes,
   or also tab-switch transitions) to be decided when we get there.
3. Autosave-while-typing (part of §7.4) is **not** bundled with the "Saved" pill fix — a bigger
   behavioral change, left for a separate explicit decision later if wanted.
