# Assistant Bridge: APP_KNOWLEDGE

## Canonical Source

The canonical app brief is:
- `APP_KNOWLEDGE.md` (repo root)

This file is a bridge for tools/agents expecting the old assistant-doc path.
It is intentionally shorter than the canonical root document.

Why two `APP_KNOWLEDGE.md` files:
- Root file is canonical architecture/status truth.
- This file is a bootstrap bridge for path compatibility and quick routing.

Recommended starting points:
- `AGENTS.md` (compatibility shim)
- `agent.md` (primary runbook)
- `docs/assistant/INDEX.md` (human index)
- `docs/assistant/manifest.json` (machine routing map)
- `docs/assistant/ISSUE_MEMORY.md` (repeatable issue registry)
- `docs/assistant/LOCAL_ENV_PROFILE.example.md` (WSL-vs-Windows routing format)
- `docs/assistant/LOCAL_CAPABILITIES.md` (discovered local tool inventory)
- `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md` (launch/build identity)

## What This File Is For

Use this file to:
- discover where canonical knowledge lives
- bootstrap quickly to high-impact files
- follow a fixed onboarding checklist in the first 15 minutes

## When To Use

Use this file:
- if an agent is configured to open `docs/assistant/APP_KNOWLEDGE.md`
- when you need a quick index before reading full canonical docs

Do not use this file as primary truth when there is a conflict.

## Doc Sync Rule

1. Root canonical wins:
   - if this file conflicts with `APP_KNOWLEDGE.md`, trust `APP_KNOWLEDGE.md`
2. Keep this bridge updated whenever canonical structure changes
3. Do not duplicate long canonical content here unless necessary

## Quick Start Links (High Impact)

### Core entry docs
- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/manifest.json`
- `docs/assistant/ISSUE_MEMORY.md`
- `docs/assistant/LOCAL_ENV_PROFILE.example.md`
- `docs/assistant/LOCAL_CAPABILITIES.md`
- `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PLANNER_USER_GUIDE.md`

### App shell
- `lib/main.dart`
- `lib/app/router.dart`
- `lib/app/navigation_shell.dart`

## Current App Shell

- Primary rail: `Today`, `Read`, `My Plan`, `Library`
- `Library` routes users to `Bookmarks` and `Notes`
- Top-right drawer is the `More` surface for `Settings`, `About`, `Reciters`, and the demoted Explore entries
- Reader top actions are now responsive, with the settings button on its own row to avoid narrow-layout collisions

## Current Stability Notes

- Reader copy success now appears only after a real clipboard write; clipboard failure shows explicit failure feedback
- SharedPreferences-backed app and audio preferences still fall back safely, but unexpected persistence failures now log non-fatal diagnostics
- Companion unit-state creation is conflict-safe for parallel reads/writes and has a dedicated concurrency regression test

## Current Today Home Notes

- `Today` now opens with a coaching card instead of raw planner metrics
- The coaching card chooses one next action, explains why it matters, and gives a short-day fallback
- `Today` now has a visible recovery entry back to `My Plan`
- Empty and completion states are called out explicitly instead of only leaving section-level empty text
- `Today` now also shows a simple health state (`On track`, `Tight`, `Overloaded`) plus a plain-language explanation packet
- When pressure is high, `Today` can expose `Do the minimum day` and the `Recovery assistant`
- `Today` now uses the same deterministic allocation policy as Forecast and weekly planning
- Mandatory Stage-4 due now reserves planner minutes before new work is allowed, even when the default block is overridden

## Current My Plan Notes

- `My Plan` now opens with a guided setup flow instead of a full control panel
- The default path is `Easy`, `Normal`, `Intensive` plus realistic time, fluency, and a plain-language summary
- Scheduling, forecast, calibration, and other expert controls are still present, but now live behind `Advanced`
- The weekly planner preview now follows the guided time inputs rather than stale advanced defaults
- `My Plan` now also shows a plain-language `Plan health` card with backlog burn-down, minimum-day, and recovery hints when needed
- The weekly planner preview and Forecast now follow the same stress/new-work rules as `Today`
- Forecast now opens with a plain-language summary and a simple confidence label before the detailed curves
- Calibration is now framed as teaching the planner your real pace, with guidance about when enough samples exist to trust the update
- Recent calibration and grade-distribution data now slightly influence how cautious the shared planner is about review pressure and new work
- Recent calibration pace can now also add one bounded pace-trend nudge to the shared planner, and Forecast exposes that in plain language instead of hiding it

### Reader and Quran pipeline
- `lib/screens/reader_screen.dart`
- `lib/data/services/qurancom_api.dart`
- `lib/data/services/qurancom_chapters_service.dart`
- `lib/data/services/ayah_audio_source.dart`
- `lib/data/services/ayah_audio_service.dart`
- `lib/ui/qcf/qcf_font_manager.dart`

### Localization
- `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- `docs/assistant/LOCALIZATION_GLOSSARY.md`
- `lib/l10n/app_language.dart`
- `lib/l10n/app_strings.dart`
- `test/l10n/app_strings_test.dart`

### Workspace performance
- `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- `docs/assistant/PERFORMANCE_BASELINES.md`
- `tooling/validate_workspace_hygiene.dart`
- `test/tooling/validate_workspace_hygiene_test.dart`

### Local environment and launch identity
- `docs/assistant/LOCAL_ENV_PROFILE.example.md`
- `docs/assistant/LOCAL_CAPABILITIES.md`
- `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md`
- `tooling/print_build_identity.dart`

### Inspiration/parity reference discovery
- `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`

### Planning
- `lib/screens/plan_screen.dart`
- `lib/screens/today_screen.dart`
- `lib/data/services/daily_planner.dart`
- `lib/data/services/spaced_repetition_scheduler.dart`
- `docs/assistant/features/PLANNER_USER_GUIDE.md`
- `docs/assistant/features/APP_USER_GUIDE.md`

### DB schema
- `lib/data/database/app_database.dart`

### Key tests
- `test/screens/reader_screen_test.dart`
- `test/data/services/qurancom_api_test.dart`
- `test/app/navigation_shell_menu_test.dart`
- `test/app/app_preferences_test.dart`

## Outsider Bootstrap Checklist (First 15 Minutes)

1. Run:
   - `git status --short`
2. Read:
   - `agent.md`
   - `APP_KNOWLEDGE.md`
3. Confirm current routes:
   - open `lib/app/router.dart`
4. Confirm current reader modes:
   - search `_ReaderViewMode` in `lib/screens/reader_screen.dart`
5. Confirm DB schema version:
   - open `lib/data/database/app_database.dart`
6. Pick relevant smoke tests for your area before edits
7. If local tooling or host routing is unclear:
   - open `docs/assistant/LOCAL_CAPABILITIES.md`
   - open `docs/assistant/LOCAL_ENV_PROFILE.example.md`
8. If launch/build identity matters:
   - run `dart tooling/print_build_identity.dart`

## Windows Command Baseline

```powershell
flutter pub get
flutter analyze
flutter test -j 1 -r expanded
```

## What Not To Do

- Do not treat this bridge file as canonical.
- Do not assume stale paths from historical docs are valid.
- Do not skip targeted tests for the area you changed.
