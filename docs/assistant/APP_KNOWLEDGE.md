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
- `docs/assistant/ROADMAP_ANCHOR.md` (active Adaptive Hifz Path continuity and next-milestone handoff)
- `docs/assistant/exec_plans/active/2026-03-25_wave1_guided_daily_hifz_path.md` (active Wave 1 Today-path implementation handoff)
- `docs/strategy/adaptive-hifz-path-solo-master-plan.md` (active product direction)
- `docs/roadmap/adaptive-hifz-path-solo-roadmap.md` (active roadmap)
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

Roadmap continuity note:
- this repo does not use `SESSION_RESUME.md`
- `docs/assistant/ROADMAP_ANCHOR.md` is the canonical continuity file

## Quick Start Links (High Impact)

### Core entry docs
- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/ROADMAP_ANCHOR.md`
- `docs/strategy/adaptive-hifz-path-solo-master-plan.md`
- `docs/roadmap/adaptive-hifz-path-solo-roadmap.md`
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
- `lib/screens/today_path.dart`
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
   - `docs/strategy/adaptive-hifz-path-solo-master-plan.md` when the task is about product direction
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

## Web bridge update (2026-03-26)

Current web continuity links:
- `docs/WEB_VERSION_ROADMAP.md`
- `docs/assistant/exec_plans/active/2026-03-26_web_adaptive_hifz_v1.md`
- `tooling/playwright/`

Web-specific high-impact files:
- `web/index.html`
- `web/drift_worker.js`
- `web/sqlite3.wasm`
- `lib/app/navigation_shell.dart`
- `lib/data/database/app_database_connection_factory.dart`
- `lib/data/database/database_storage_status.dart`
- `lib/data/services/daily_planner.dart`
- `lib/data/services/new_unit_generator.dart`
- `lib/data/services/quran_data_readiness.dart`
- `lib/data/services/solo_setup_flow.dart`
- `lib/screens/today_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/data/services/qurancom_api.dart`
- `lib/data/services/qurancom_chapters_service.dart`
- `lib/ui/qcf/qcf_font_manager.dart`
- `lib/data/services/ayah_audio_download_service.dart`
- `lib/data/services/ayah_audio_playback_resolver.dart`

Current browser-first truth to preserve:
- Today and Settings now share one guided setup flow for first-run browser use
- for zero-unit learners, that guided setup is the sole release-visible first-run path before the normal Today queue appears
- Today uses a non-materializing planner preview in that zero-unit state so loading the page does not silently create the first unit or advance the cursor
- the guided setup imports Qur'an text first, backfills page metadata only if it is still missing, saves a calm starter plan, and prepares the first memorization unit
- starter-plan readiness on Today and Settings now means a healthy starter plan, not just non-empty structured scheduling prefs; existing learners with the legacy revision-only trap still surface guided setup repair
- structured scheduling now carries an explicit starter-plan source marker so intentional user-saved revision-only plans are not mistaken for legacy starter traps
- Today only shows a browser-storage warning when persistence is degraded or transient
- Plan beginner setup now writes legacy minute fields and structured scheduler prefs from one coherent source of truth
- Plan no longer defaults fresh or repair-needed learners into revision-only in the UI; it only coerces revision-only off for the true legacy default trap, while intentional user-owned or structurally custom legacy revision-only plans stay intact

Current local validation caveats:
- local `flutter test` execution is still blocked by the native-assets `objective_c` `hook.dill` failure in this environment
- `flutter build web` still succeeds with non-fatal warnings about the missing `CupertinoIcons` font asset and the Drift wasm dry run (`Bad state: No definition of type Stream`)
