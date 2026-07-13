# Copilot Instructions for `learning_flutter`

## Build, test, and lint commands

Run from repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter test <path-to-test-file> --plain-name "<test name pattern>"
flutter run
flutter build apk
```

Examples for single-test execution:

```bash
flutter test test/widget_test.dart
flutter test test/widget_test.dart --plain-name "counter increments"
```

Backend note: `backend/package.json` exists, but it currently has only a placeholder `npm test` script and no implemented backend entrypoint.

## High-level architecture

- This repository is a Flutter “mini-projects” app (per `README.md`) with one launcher screen (`ProjectsHomePage`) that routes to independent feature pages: CV, Calculator, World Clock, Stopwatch, and Notes.
- App startup in `lib/main.dart` is async and requires `AppSupabase.initialize()` before `runApp`, so Supabase and `.env` loading are part of the boot path even if only Notes uses database/auth features.
- Code is split into:
  - `lib/pages/`: UI screens and navigation
  - `lib/resources_and_services/`: non-UI logic/services (calculator logic, notes data/auth logic, world-time API, Supabase bootstrap)
- World Clock + Stopwatch are coupled through shared route arguments (`Map<String, dynamic>`) passed back/forth via named routes (`/home`, `/location`, `/loading`, `/stopwatch`).
- Notes is a full flow in-app: auth screen, notes list, note editor, all backed by Supabase (`notes_logic.dart`) and surfaced in `notes_page.dart`.

## Key conventions in this codebase

- **Service-first logic split:** business logic lives under `resources_and_services` and widgets delegate to it (notably `CalculatorLogic`, `NotesLogic`, `WorldTime`, `AppSupabase`).
- **Supabase auth model for Notes:** usernames are converted to synthetic emails (`<username>@notesapp.dev`) before auth calls; login/register behavior depends on this mapping.
- **Notes ordering/filter rules:** pinned notes always sort before unpinned; within each group, newest `updated_at` first.
- **Expected Notes table fields:** UI/logic assumes `notes` rows include `id`, `user_id`, `title`, `content`, `created_at`, `updated_at`, `is_pinned`, `is_favorite`.
- **Async UI safety pattern:** after awaited calls, widgets commonly guard with `if (!mounted) return;` before `setState`/navigation.
- **Environment contract:** `.env` must define `SUPABASE_URL` and `SUPABASE_ANON_KEY`; `.env.example` is the template and both are declared as Flutter assets.
- **Page naming/import style:** many feature pages expose a `Home` widget and are imported with aliases in `main.dart`/navigation code to avoid symbol collisions.
- **World time route-argument contract:** clock/stopwatch navigation expects map keys `location`, `flag`, `time`, and `isDaytime`; preserve these keys when changing either page.
