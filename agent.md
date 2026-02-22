# AGENT RUNBOOK - Hifz Planner

This file is the operational entrypoint for AI agents and new engineers.
Use it to choose the right files, commands, and tests quickly.

## What This Is For

Use this runbook when you need to:
- implement or debug reader behavior
- update Quran.com cache/font/data paths
- change hifz planner/scheduler workflows
- run safe verification and tests
- onboard to this repo quickly

## When To Use vs Not Use

Use this file:
- before touching code
- when you need a fast map of "where logic lives"
- when deciding which tests to run for a scoped change

Do not rely on this file alone when:
- changing schema or complex business logic without reading source files
- assumptions conflict with current code (source code wins)
- there is ambiguity not covered here (use repo search and targeted inspection)

## Read Order

1. `agent.md` (this runbook)
2. `APP_KNOWLEDGE.md` (canonical app brief)
3. Targeted deep docs:
   - `docs/assistant/DB_DRIFT_KNOWLEDGE.md` for schema/migrations
4. Source files in the area you are changing

## 5-Minute Bootstrap Checklist

1. Check repo state:
   - `git status --short`
2. Open core shell and routing:
   - `lib/main.dart`
   - `lib/app/router.dart`
   - `lib/app/navigation_shell.dart`
3. Open reader core if work touches Quran UX:
   - `lib/screens/reader_screen.dart`
4. Open data services if work touches Quran.com pipeline:
   - `lib/data/services/qurancom_api.dart`
   - `lib/ui/qcf/qcf_font_manager.dart`
5. Pick smallest relevant tests:
   - `test/screens/reader_screen_test.dart`
   - `test/data/services/qurancom_api_test.dart`

## Fast Repo Map

### App Shell
- `lib/main.dart`: app bootstrap, theme application
- `lib/app/router.dart`: route graph and `/reader` query parsing
- `lib/app/navigation_shell.dart`: left rail + global right menu drawer

### Reader and Quran UX
- `lib/screens/reader_screen.dart`: Verse by Verse + Reading (Mushaf) unified shell
- `lib/ui/tajweed/*`: tajweed color rendering helpers
- `lib/ui/qcf/qcf_font_manager.dart`: dynamic QCF font loading

### Data Layer
- `lib/data/database/app_database.dart`: Drift schema and migrations
- `lib/data/repositories/*`: DB query ownership
- `lib/data/services/*`: planner, importers, Quran.com API, scheduler
- `lib/data/providers/database_providers.dart`: provider wiring

### Test Surface
- `test/screens/*`: widget-level behaviors
- `test/data/services/*`: services and pipelines
- `test/data/repositories/*`: repository correctness
- `test/app/*`: shell/menu/preferences behavior

### Assets/Tooling
- `assets/quran/*`: Quran text/meta/static assets
- `assets/fonts/*`: Uthmani/SurahNames fonts
- `tooling/*`: generation and checksum scripts

## Task Playbooks

### A) Reader/UI parity tasks

Goal:
- change visuals/interactions in Verse by Verse or Reading mode

Open first:
- `lib/screens/reader_screen.dart`
- `test/screens/reader_screen_test.dart`

Run:
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`

Then:
- `flutter analyze`

### B) Quran.com data/cache/font tasks

Goal:
- adjust by-page fetch, cache shape, dedupe, translations, or QCF fonts

Open first:
- `lib/data/services/qurancom_api.dart`
- `lib/ui/qcf/qcf_font_manager.dart`
- `test/data/services/qurancom_api_test.dart`

Run:
- `flutter test -j 1 -r expanded test/data/services/qurancom_api_test.dart`
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`

### C) Hifz planner/scheduler tasks

Goal:
- change onboarding, plan generation, review grading, calibration, forecast

Open first:
- `lib/screens/plan_screen.dart`
- `lib/screens/today_screen.dart`
- `lib/data/services/daily_planner.dart`
- `lib/data/services/spaced_repetition_scheduler.dart`
- `lib/data/database/app_database.dart`

Run:
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `flutter test -j 1 -r expanded test/data/services/spaced_repetition_scheduler_test.dart`

### D) Docs-only tasks

Goal:
- update project guidance and onboarding docs

Run:
- verify links/paths exist
- `flutter analyze` only if touching examples that might reference code symbols

## Safe Working Rules

1. Do not revert unrelated local changes in a dirty worktree.
2. Keep diffs focused to the files relevant to the request.
3. Prefer targeted tests first; expand scope only as needed.
4. Use Windows-stable test execution:
   - `flutter test -j 1 -r expanded`
5. Do not manually edit generated Drift file:
   - `lib/data/database/app_database.g.dart`
6. Preserve fallback behavior in reader/data pipelines (no hard crashes on partial failures).

## Verification Matrix

### Reader-only change
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter analyze`

### Quran.com API or cache change
- `flutter test -j 1 -r expanded test/data/services/qurancom_api_test.dart`
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter analyze`

### DB/repository/scheduler change
- `flutter test -j 1 -r expanded test/data/database/app_database_test.dart`
- `flutter test -j 1 -r expanded test/data/repositories`
- `flutter test -j 1 -r expanded test/data/services`
- `flutter analyze`

### Navigation/menu/preferences change
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
- `flutter analyze`

## When Unsure

Use these commands:

```powershell
rg -n "keyword_or_symbol" lib test tooling
rg --files lib/screens
rg --files lib/data/services
git status --short
```

Fallback strategy:
1. Find source-of-truth file with `rg`.
2. Confirm behavior in tests.
3. Make smallest valid change.
4. Re-run only impacted tests, then broader checks.

## Done Checklist

Before finishing:
- changed files are intentional
- no stale paths in docs/comments
- targeted tests pass
- no generated files edited manually unless intentionally regenerated
