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
- `docs/assistant/ROADMAP_ANCHOR.md` (current roadmap continuity and next-milestone handoff)
- `docs/assistant/HARNESS_PROFILE.json` (bootstrap profile source of truth when bootstrap harness work is in scope)
- `docs/assistant/HARNESS_OUTPUT_MAP.json` (repo-local mapping overlay for bootstrap outputs)
- `docs/assistant/INDEX.md` (human index)
- `docs/assistant/manifest.json` (machine routing map)

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
- `docs/assistant/ROADMAP_ANCHOR.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/manifest.json`
- `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PLANNER_USER_GUIDE.md`
- `docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md` for explicit HTML explainer requests
- `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md` for local bootstrap harness apply/audit

### App shell
- `lib/main.dart`
- `lib/app/router.dart`
- `lib/app/navigation_shell.dart`

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
   - `docs/assistant/ROADMAP_ANCHOR.md` when resuming roadmap work
3. Confirm current routes:
   - open `lib/app/router.dart`
4. Confirm current reader modes:
   - search `_ReaderViewMode` in `lib/screens/reader_screen.dart`
5. Confirm DB schema version:
   - open `lib/data/database/app_database.dart`
6. Pick relevant smoke tests for your area before edits

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
