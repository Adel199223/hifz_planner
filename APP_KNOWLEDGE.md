# APP_KNOWLEDGE — Hifz Planner (Windows-first Flutter app)

## 0. How to use this knowledge pack (for the Codex/AI agent)

**Read order (keep token usage low):**
1) `agent.md` (Codex entrypoint / operating rules)
2) `docs/assistant/APP_KNOWLEDGE.md` (this file: repo map + commands + pointers)
3) Only open other docs when relevant (testing, DB, assets, UI)

**Rules:**
- Prefer file-path-grounded answers. When unsure, label `Uncertain` and give a command to verify.
- If asked “where does X live?”, consult **Section J** first, then verify with:
  - `rg -n "symbol_or_keyword" lib test tooling`
- Keep diffs small and localized; avoid repo-wide rewrites unless explicitly asked.
- For widget tests: avoid unbounded `pumpAndSettle()` when animations/timers/dialogs exist → use `pumpUntilFound`.

## 0b. How we work / Workflow (token-efficient, Windows-friendly)

**Safe change flow:**
1) Snapshot:
   - `git status --short`
   - `git diff --name-only`
   - `flutter --version`
2) Verify (default):
   - `dart format .`
   - `flutter analyze`
   - `flutter test -j 1 -r expanded`
3) Make a focused change.
4) Re-run the smallest relevant test target(s), then the full suite if practical.
5) Commit with a descriptive message and push.

**Windows notes that prevent common failures:**
- `flutter format` is not a command → use `dart format .`
- Prefer `flutter test -j 1` on Windows to avoid occasional build/test cache collisions.
- If `flutter` isn’t recognized in the current shell, use absolute path:
  - `& "C:\dev\tools\flutter\bin\flutter.bat" <command>`

---

## A. What the app does (user workflows)

Hifz Planner is a Windows-first Flutter app to help users memorize the Qur’an using an evidence-inspired spaced repetition approach, with a focus on **Madina Mushaf page mode**:

Primary user workflows:
- Read in **Surah mode** or **Page mode** (Madina pages) and interact per-ayah:
  - tap/hover highlight, bookmark, add note, copy text.
- Import Qur’an text (Tanzil Uthmani lines) into local Drift DB.
- Import page metadata CSV to populate `ayah.page_madina` (enables Page Mode).
- View bookmarks and notes and “Go to verse / Go to page” (preferring page mode when metadata exists).
- (Planned / Prompt 8+): Generate daily plan (new memorization + reviews), store progress cursor, schedule revisions.

Assistant routing hint:
- If asked “what can a user do?”, inspect screens under `lib/screens/` first.

---

## B. How to run it (dev / test / build) — exact commands + entrypoints

### Run (Windows desktop dev)
```powershell
flutter pub get
flutter run -d windows

Run (PATH-safe / PowerShell-safe)
Use this when flutter isn’t recognized in the current terminal/session:
& "C:\dev\tools\flutter\bin\flutter.bat" pub get
& "C:\dev\tools\flutter\bin\flutter.bat" run -d windows

Verify (default, Windows-safe)
dart format .
flutter analyze
flutter test -j 1 -r expanded

Targeted tests (run the smallest thing that proves the change)
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/screens/notes_screen_test.dart
flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart
flutter test -j 1 -r expanded test/screens/settings_screen_test.dart
flutter test -j 1 -r expanded test/widget_test.dart

If a test hangs
Use a timeout + chain stacks to reveal what is stuck:
flutter test -j 1 -r expanded --timeout 30s --chain-stack-traces test/screens/reader_screen_test.dart

Widget test stability rule (important)
Avoid unbounded pumpAndSettle() when dialogs/animations/timers exist.
Prefer bounded waits:
test/helpers/pump_until_found.dart → pumpUntilFound(...)

Assets policy (Tanzil)
Repo may contain only assets/quran/.gitkeep during development.
If assets/quran/tanzil_uthmani.txt is not present locally, integrity tests may skip (expected).
If you later decide to bundle the Tanzil text, place it at:
assets/quran/tanzil_uthmani.txt

## C. Architecture map (module tree + responsibilities) — Flutter/Drift

App shell/navigation:
- `lib/main.dart`: app bootstrap
- `lib/app/router.dart`: routing (Reader/Bookmarks/Notes/Settings/Today/Plan)
- `lib/app/navigation_shell.dart`: NavigationRail shell layout
- `lib/app/nav_destination.dart`: destinations config
- `lib/app/navigation_providers.dart`: navigation-related providers

Database + providers (Drift):
- `lib/data/database/app_database.dart`: Drift schema, db class, migrations/version
- `lib/data/database/app_database.g.dart`: generated Drift code (do not hand-edit)
- `lib/data/providers/database_providers.dart`: DB provider wiring (Riverpod/Provider)

Repositories:
- `lib/data/repositories/quran_repo.dart`: ayah queries (by surah/page), search, page list
- `lib/data/repositories/note_repo.dart`: notes CRUD + watch streams
- (bookmark repo file name may vary; search `BookmarkRepo` in `lib/data/repositories/`)

Import services:
- `lib/data/services/quran_text_importer_service.dart`: parse Tanzil lines → insert into `ayah`
- `lib/data/services/page_metadata_importer_service.dart`: parse CSV → update `ayah.page_madina`
- `test/data/services/tanzil_text_integrity_guard_test.dart`: integrity checks (skips if asset missing)

UI screens:
- `lib/screens/reader_screen.dart`: Surah mode + Page mode reader, per-ayah actions
- `lib/screens/bookmarks_screen.dart`: bookmark list + go-to routing
- `lib/screens/notes_screen.dart`: notes list + editor dialog + go-to routing
- `lib/screens/settings_screen.dart`: import controls + status/progress UI
- `lib/screens/today_screen.dart`: Today/home (currently basic; later daily plan)
- `lib/screens/plan_screen.dart`: plan screen (user plan settings; later linked to memorization engine)
- `lib/screens/about_screen.dart`: about/help

Test helpers:
- `test/helpers/pump_until_found.dart`: bounded wait helper to avoid test hangs

---

## D. Data pipelines (imports + indexing)

### 1) Qur’an text import (Tanzil Uthmani)
Owner: `lib/data/services/quran_text_importer_service.dart`

- Reads Tanzil line format and inserts into `ayah` table.
- Must preserve text verbatim.
- Import should be idempotent:
  - If ayah table has data and `force=false`, should skip.
  - If `force=true`, should proceed but ignore duplicates (insert-or-ignore).
- DB must enforce uniqueness on `(surah, ayah)`.

Related tests:
- `test/data/services/quran_text_importer_service_test.dart`
- `test/data/database/app_database_test.dart` (unique constraint)

### 2) Page metadata import (Madina page mapping)
Owner: `lib/data/services/page_metadata_importer_service.dart`

- Imports CSV mapping to set `ayah.page_madina`.
- Must be idempotent; repeated import shouldn’t produce inconsistent state.
- Handles header rows, blank lines, duplicate keys (last row wins).

Related tests:
- `test/data/services/page_metadata_importer_service_test.dart`

### 3) Search / LIKE
Owner: `lib/data/repositories/quran_repo.dart`

- When using LIKE patterns, Drift uses `escapeChar` (not `escape`).
- Keep search behavior stable; add tests for empty query returning empty.

Related tests:
- `test/data/repositories/quran_repo_test.dart`

---

## E. Memorization engine (spaced repetition) — status + planned integration

**Status:**
- As of now, the repo includes reader + imports + notes/bookmarks + settings/testing stability.
- The memorization/scheduling engine is intended to be added in Prompt 8+ (tables: mem_unit, schedule_state, review_log, app_settings, mem_progress).

**Design invariants for planned engine:**
- Units are **page-based segments** (show the full page, highlight only the segment).
- Scheduling uses an integer `due_day` (local day index).
- User controls time availability and difficulty profile.
- Avoid unbounded daily load: planning must cap reviews and optionally go “revision only” if overloaded.

When implementing Prompt 8+, document tables and cursor in `docs/assistant/DB_DRIFT_KNOWLEDGE.md` and link back here.

---

## F. Settings & persistence

Current persistence:
- Local Drift database (tables for ayah/notes/bookmarks + metadata).
- UI settings currently live either in DB or local state (exact location: see `settings_screen.dart` and providers).

Planned:
- `app_settings` single-row table for user plan settings (profile, minutes, caps, averages).
- `mem_progress` cursor (next surah/ayah).

No secret keys are required at present (reciters/audio licensing handled later).

---

## G. Diagnostics & troubleshooting (Windows-focused)

Common issues + fixes:

### Flutter not recognized in terminal
Use absolute path:
```powershell
& "C:\dev\tools\flutter\bin\flutter.bat" doctor -v

### Windows test cache collision (file exists / errno 183)

Symptom:
- Errors like `PathExistsException ... (OS Error: Cannot create a file when that file already exists, errno = 183)`
- Usually occurs after an interrupted/hung test run or overlapping test processes on Windows.

Fix (PowerShell, run from repo root):
```powershell
# Stop any stuck flutter/dart processes
Get-Process | Where-Object { $_.ProcessName -match 'flutter|dart' } |
  ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }

# Remove test cache/build artifacts (safe; they regenerate)
Remove-Item -Recurse -Force ".\build\test_cache" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:TEMP\flutter_tools.*" -ErrorAction SilentlyContinue

# Clean + re-fetch deps
flutter clean
flutter pub get

# Re-run tests single-threaded (recommended on Windows)
flutter test -j 1 -r expanded

Notes:
- Prefer `flutter test -j 1` on Windows to reduce cache collisions.
- If you still see collisions, close VS Code and all terminals, then retry.

---

### Widget test hangs (no output for minutes)

Symptom:
- A test appears to run forever (often stuck after printing the test name).

Root causes:
- Unbounded `pumpAndSettle()` while there is an animation/timer/caret blink/stream that never settles.
- Awaiting a Future/stream that never completes.

Fix strategy:
1) Re-run the single test with a timeout to force a stack trace:
```powershell
flutter test -j 1 -r expanded --timeout 30s --chain-stack-traces test/screens/reader_screen_test.dart --plain-name "TEST NAME HERE"

Notes:
- Prefer `flutter test -j 1` on Windows to reduce cache collisions.
- If you still see collisions, close VS Code and all terminals, then retry.

---

### Widget test hangs (no output for minutes)

Symptom:
- A test appears to run forever (often stuck after printing the test name).

Root causes:
- Unbounded `pumpAndSettle()` while there is an animation/timer/caret blink/stream that never settles.
- Awaiting a Future/stream that never completes.

Fix strategy:
1) Re-run the single test with a timeout to force a stack trace:
```powershell
flutter test -j 1 -r expanded --timeout 30s --chain-stack-traces test/screens/reader_screen_test.dart --plain-name "TEST NAME HERE"
````

2. Replace unbounded waits with bounded waits:

* Avoid `await tester.pumpAndSettle();` in dialog/navigation/snackbar flows.
* Use `pumpUntilFound(...)` from:

  * `test/helpers/pump_until_found.dart`

Example pattern:

```dart
await tester.tap(find.byKey(const Key('copy_button')));
await tester.pump(); // start UI update
await pumpUntilFound(tester, find.byType(SnackBar), timeout: const Duration(seconds: 3));
```

---

## H. Packaging / distribution

Windows desktop build:

```powershell
flutter build windows
```

Web build (later):

```powershell
flutter build web
```

Android build (once needed):

```powershell
flutter build apk
```

Note:

* Android toolchain readiness is validated by `flutter doctor -v` (should show no issues).

---

## I. Testing & verification

Primary verification (default, Windows-safe):

```powershell
dart format .
flutter analyze
flutter test -j 1 -r expanded
```

Targeted suites (run the smallest thing that proves the change):

```powershell
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/screens/notes_screen_test.dart
flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart
flutter test -j 1 -r expanded test/screens/settings_screen_test.dart
flutter test -j 1 -r expanded test/widget_test.dart
```

Test stability rules:

* Prefer Keys in UI for tests rather than brittle text matching.
* Prefer `pumpUntilFound` over `pumpAndSettle` in dialog/navigation/snackbar flows.
* Keep widget tests deterministic (override DB providers with in-memory DB when needed).

---

## J. Where is X? index (common tasks mapped to exact files)

Navigation / routes:

* Router setup: `lib/app/router.dart`
* Navigation shell: `lib/app/navigation_shell.dart`

Reader / Page Mode:

* Reader UI: `lib/screens/reader_screen.dart`
* Page-mode data queries: `lib/data/repositories/quran_repo.dart` (`getPagesAvailable`, `getAyahsByPage`)
* Ayah row keys/highlight logic: `lib/screens/reader_screen.dart` (search for `Key(` and `ayah_row_`)

Bookmarks:

* Bookmarks UI: `lib/screens/bookmarks_screen.dart`
* Bookmark queries: search `BookmarkRepo` in `lib/data/repositories/`

Notes:

* Notes UI: `lib/screens/notes_screen.dart`
* Notes repo: `lib/data/repositories/note_repo.dart`
* Notes editor dialog keys used in tests: search in `notes_screen.dart` for:

  * `notes_editor_title_field`
  * `notes_editor_body_field`
  * `notes_editor_save_button`
  * `notes_editor_go_button`
  * `notes_editor_go_page_button`

Import controls:

* Settings UI: `lib/screens/settings_screen.dart`
* Text import: `lib/data/services/quran_text_importer_service.dart`
* Page metadata import: `lib/data/services/page_metadata_importer_service.dart`

DB schema:

* `lib/data/database/app_database.dart` (schema + constraints)
* Generated file: `lib/data/database/app_database.g.dart` (do not edit by hand)

Test helper (bounded waits):

* `test/helpers/pump_until_found.dart`

Integrity guard tests:

* `test/data/services/tanzil_text_integrity_guard_test.dart`

If unsure, run:

```powershell
rg -n "keyword" lib test
```

```
::contentReference[oaicite:0]{index=0}
```