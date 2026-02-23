# APP_KNOWLEDGE - Hifz Planner

This document is the single-source project briefing for outsiders (new engineers, reviewers, and AI agents).
It explains what the app is, what is already implemented, where key logic lives, and how to work safely.

## 0) Agent Docs Map

Documentation contract for contributors and AI agents:
- Canonical app brief: `APP_KNOWLEDGE.md` (this file)
- Compatibility entrypoint: `AGENTS.md`
- Agent runbook entrypoint: `agent.md`
- Assistant bridge path: `docs/assistant/APP_KNOWLEDGE.md`
- DB/Drift deep reference: `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- Assistant doc index: `docs/assistant/INDEX.md`
- Machine manifest: `docs/assistant/manifest.json`

If documentation conflicts:
- this file (`APP_KNOWLEDGE.md`) is canonical for overall app behavior and structure
- source code remains the final truth

Workflow runbooks:
- Reader/UI: `docs/assistant/workflows/READER_WORKFLOW.md`
- Localization/i18n: `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- Quran.com data/cache/fonts: `docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md`
- Planner/scheduler: `docs/assistant/workflows/PLANNER_WORKFLOW.md`
- Workspace performance: `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- Reference discovery: `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`
- Docs maintenance: `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`
- CI and repo operations: `docs/assistant/workflows/CI_REPO_WORKFLOW.md`
- Commit/publish hygiene: `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`

Localization glossary:
- `docs/assistant/LOCALIZATION_GLOSSARY.md` (canonical term source)

Workspace performance baseline:
- `docs/assistant/PERFORMANCE_BASELINES.md` (canonical VS Code/workspace performance defaults)

Significant-change docs sync policy:
- after significant implementation changes, ask:
  - "Would you like me to run Assistant Docs Sync for this change now?"
- if approved, update only relevant assistant docs by touched scope.

Why two `APP_KNOWLEDGE.md` files:
- Root `APP_KNOWLEDGE.md` is canonical and complete.
- `docs/assistant/APP_KNOWLEDGE.md` is intentionally shorter as a bridge/bootstrap doc.

Why both `AGENTS.md` and `agent.md` exist:
- `AGENTS.md` is a short compatibility shim for auto-discovery tools.
- `agent.md` is the operational runbook for humans and AI agents.

## 1) App Purpose

Hifz Planner is a Flutter app focused on Quran reading and memorization workflow.

Current product direction:
- Quran.com-style reading experience (both Mushaf reading and Verse-by-Verse views).
- Practical hifz planning workflow (onboarding settings, daily plan, review grading, calibration, forecast).
- Local-first data with robust fallback behavior.

Primary target right now is desktop (Windows-first), while keeping architecture reusable for Android/iOS later.

## 2) Current User-Facing Surface

### Navigation
- Left `NavigationRail` remains active for core app areas:
  - Reader, Bookmarks, Notes, Plan, Today, Settings, About
- A top-right global menu drawer (Quran.com-style direction) adds:
  - Read, Learn, My Quran, Quran Radio, Reciters

### Routes
Defined in `lib/app/router.dart`:
- `/reader`
- `/bookmarks`
- `/notes`
- `/plan`
- `/learn`
- `/my-quran`
- `/quran-radio`
- `/reciters`
- `/today`
- `/settings`
- `/about`

`/reader` also supports query params:
- `mode`, `page`
- `targetSurah`, `targetAyah`
- `highlightStartSurah`, `highlightStartAyah`
- `highlightEndSurah`, `highlightEndAyah`

### Global Preferences (persisted)
- Language options (fully wired for app UI strings):
  - English, Français, العربية, Português
- Theme options:
  - Sepia, Dark
- Stored via SharedPreferences and restored on startup.

Files:
- `lib/app/app_preferences.dart`
- `lib/app/app_preferences_store.dart`
- `lib/l10n/app_language.dart`
- `lib/l10n/app_strings.dart`
- `lib/theme/quran_themes.dart`

Localization governance:
- Use `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` for process.
- Use `docs/assistant/LOCALIZATION_GLOSSARY.md` as the term source of truth.
- Avoid duplicating term tables across other docs.

Workspace performance governance:
- Use `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` for lag/indexing/file-watcher issues.
- Use `docs/assistant/PERFORMANCE_BASELINES.md` as canonical exclusion and environment placement policy.
- Avoid repeating exclusion tables in other docs.

Inspiration/parity governance:
- Use `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` when user names external apps/sites to emulate.
- Prefer official sources first, then high-quality community repos; use Hugging Face only when model/data/inference scope is relevant.

## 3) Reader System (Most Important Area)

Main file: `lib/screens/reader_screen.dart`

The reader has two views (internal enum names kept for backward compatibility):
- UI label: `Verse by Verse` (internal: `_ReaderViewMode.simple`)
- UI label: `Reading` (internal: `_ReaderViewMode.mushaf`)

Both views use one unified shell:
- Left pane: Surah / Verse / Juz / Page navigation tabs
- Center pane: context + top actions + content
- Right pane: settings drawer (`Arabic`, `Translation`, `Word By Word`)

### 3.1 Verse by Verse view

Intent:
- Replace old "Simple" style with Quran.com-like verse cells.

Per-verse cell includes:
- Top action row (`surah:ayah` + action icons)
- Arabic row (Quran.com words/QCF pipeline when available)
- Translation line
- Bottom action row (`Tafsirs`, `Lessons`, `Reflections` scaffold actions)
- Divider

Behavior:
- Visible source is Quran.com pipeline.
- Hidden per-verse fallback to local rendering if Quran.com data/font fails.
- No "whole-row tap opens old sheet" behavior.
- Bookmark/note/copy are wired to existing logic.
- Play/share/extra actions are scaffold-safe where backend is not ready.

Chapter header behavior:
- Quran.com-style external chapter header on surah-start context.
- Uses SurahNames font glyph + `assets/quran/bismillah.svg` when applicable.

Translation behavior:
- One default translation resource selected by app language:
  - English -> resource `85` (M.A.S. Abdel Haleem)
  - French -> resource `31` (Muhammad Hamidullah)
  - Portuguese -> resource `43` (Samir El-Hayek)
  - Arabic app language -> currently falls back to English resource `85`
- Fallback text: `Translation unavailable`

### 3.2 Reader recitation playback (streaming)

Status:
- Implemented in Reader (Verse by Verse + Reading top Listen controls).
- Uses AlQuran Cloud CDN streaming (no OAuth, no server, no DB changes).
- `Reciters` route is implemented as a functional searchable reciter selector.

Playback capabilities:
- Per-ayah play from verse action row.
- Play from here (queue to end of current surah).
- Pause/resume.
- Next/previous (distinct ayah navigation).
- Speed control: `0.75x`, `1.0x`, `1.25x`, `1.5x`.
- Repeat current ayah count: `Off`, `1x`, `2x`, `3x`.
- Mini-player appears in Reader when an ayah is active.
- Mini-player includes elapsed/total time and seek slider.
- Audio options menu includes:
  - `Download` (placeholder)
  - `Manage repeat settings` (functional)
  - `Experience` (placeholder)
  - `Speed` (functional)
  - `Reciter` (functional)
- Playback stays active while navigating inside `/reader` and stops when leaving `/reader` (provider disposal).
- Selected reciter/speed/repeat are persisted locally via SharedPreferences.

Implementation files:
- `lib/data/services/ayah_audio_source.dart`
- `lib/data/services/ayah_audio_service.dart`
- `lib/data/services/ayah_audio_preferences.dart`
- `lib/data/services/ayah_reciter_catalog_service.dart`
- `lib/data/providers/audio_providers.dart`
- `lib/ui/audio/reciter_selection_list.dart`
- `lib/screens/reader_screen.dart`
- `lib/screens/reciters_screen.dart`

Windows plugin note:
- Audio stack uses `just_audio` with `just_audio_windows`.
- After changing audio plugin dependencies, run a full restart (not only hot reload) so Windows plugin registration is reloaded.

### 3.3 Reading (Mushaf) view

Intent:
- Quran.com-style page reading with QCF glyph fidelity and word-level interaction.

Core behavior:
- Loads by page using Quran.com API and per-page QCF fonts.
- Plain mode -> mushaf id `1`, QCF v2.
- Tajweed mode -> mushaf id `19`, QCF v4tajweed (with fallback to v2 if v4 fails).
- Content scrolls vertically when needed (no fit-to-height compression).

Interaction model:
- Words rendered as independent widgets in line rows.
- Hover highlights word/verse context.
- End-marker click opens verse actions.
- Non-marker click opens word popover.
- Tooltip uses word translation when available; fallback `Translation unavailable`.

Header/spacing model:
- External chapter header for surah starts.
- Basmala rendered via SVG asset, not plain text.
- Centering rules include page-specific static centered lines map.

## 4) Quran.com Data + Font Pipeline

### 4.1 Quran.com API service

File: `lib/data/services/qurancom_api.dart`

Key responsibilities:
- Fetch by-page Quran.com payloads.
- Parse words + verse grouping + page meta + verse translations.
- Cache JSON to app support directory.
- In-memory dedupe for concurrent loads.
- Graceful refresh logic when older cache shape lacks required fields.

Important models:
- `MushafWord`
- `MushafVerseData`
- `MushafVerseTranslation`
- `MushafPageMeta`
- `MushafPageData`
- `MushafJuzNavEntry`

Important methods:
- `getPage(...)`
- `getPageWithVerses(...)`
- `getVerseDataByPage(...)`
- `getVerseWordsByPage(...)`
- `getJuzIndex(...)`

Cache naming:
- No translation: `page_{page}_m{mushafId}.json`
- Translation-aware: `page_{page}_m{mushafId}_t{translationId}.json`
- Juz index: `juz_index_m{mushafId}.json`

### 4.2 QCF font manager

File: `lib/ui/qcf/qcf_font_manager.dart`

Responsibilities:
- Download/cache per-page QCF fonts.
- Load fonts dynamically into Flutter runtime.
- Handle v4 tajweed fallback to v2.

Note:
- Uses `dart:io` and local filesystem; this is a known constraint for web parity later.

## 5) Local Data Model (Drift)

Database file: `lib/data/database/app_database.dart`
Schema version: `3`

Tables:
- `ayah` (Quran text + optional `page_madina`)
- `bookmark`
- `note`
- `mem_unit`
- `schedule_state`
- `review_log`
- `app_settings` (singleton row id=1)
- `mem_progress` (singleton row id=1)
- `calibration_sample`
- `pending_calibration_update`

Key points:
- `ayah` unique key: `(surah, ayah)`
- schedule/review/calibration indexes are created in migration helpers
- singleton rows are enforced via `ensureSingletonRows()`

Generated file:
- `lib/data/database/app_database.g.dart` (do not hand-edit)

## 6) Repositories and Services

Provider wiring:
- `lib/data/providers/database_providers.dart`

Important repos/services:
- Repositories:
  - `quran_repo.dart`
  - `bookmark_repo.dart`
  - `note_repo.dart`
  - `mem_unit_repo.dart`
  - `schedule_repo.dart`
  - `review_log_repo.dart`
  - `settings_repo.dart`
  - `progress_repo.dart`
  - `calibration_repo.dart`
- Services:
  - `quran_text_importer_service.dart`
  - `page_metadata_importer_service.dart`
  - `daily_planner.dart`
  - `spaced_repetition_scheduler.dart`
  - `calibration_service.dart`
  - `forecast_simulation_service.dart`
  - `new_unit_generator.dart`
  - `tajweed_tags_service.dart`
  - `surah_metadata_service.dart`
  - `qurancom_api.dart`

## 7) Hifz Planning Flow (Implemented)

### Plan screen
File: `lib/screens/plan_screen.dart`

Current capabilities:
- Onboarding-like questionnaire inputs
- Activate/update settings (`profile`, minutes, caps, etc.)
- Calibration sample logging and apply timing
- Forecast simulation display

### Today screen
File: `lib/screens/today_screen.dart`

Current capabilities:
- Build today plan from scheduler/planner
- Render planned reviews and planned new memorization
- Save grades (`q=5/4/3/2/0`)
- "Open in Reader" deep-link with page mode + verse range highlight params

## 8) Other Screens

- `lib/screens/learn_screen.dart`
  - Learn container page; includes Hifz Plan entry card linking to `/plan`
- `lib/screens/my_quran_screen.dart`
  - placeholder scaffold (`coming soon`)
- `lib/screens/quran_radio_screen.dart`
  - placeholder scaffold (`coming soon`)
- `lib/screens/reciters_screen.dart`
  - placeholder scaffold (`coming soon`)
- `lib/screens/settings_screen.dart`
  - import Quran text + import page metadata + progress status
- `lib/screens/bookmarks_screen.dart`
  - list bookmarks with go-to verse/page actions
- `lib/screens/notes_screen.dart`
  - list notes + edit dialog + go-to verse/page actions
- `lib/screens/about_screen.dart`
  - placeholder

## 9) Assets and Tooling

### Key assets
- `assets/quran/tanzil_uthmani.txt` (optional at runtime in some environments)
- `assets/quran/tajweed_uthmani_tags.json` (generated optional tajweed overlay data)
- `assets/quran/bismillah.svg`
- `assets/fonts/UthmanicHafs1Ver18.ttf`
- `assets/fonts/sura_names.ttf`

### Tooling scripts
- `tooling/generate_page_index_madani_hafs.dart`
- `tooling/generate_tajweed_uthmani_tags.dart`
- `tooling/generate_tajweed_uthmani_tags_alquran_cloud.dart`
- `tooling/print_tanzil_checksum.dart`

## 10) Build, Run, Test

From repo root (`c:\dev\hifz_planner`):

```powershell
flutter pub get
flutter run -d windows
```

Quality checks:

```powershell
dart format .
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test -j 1 -r expanded
```

Common focused suite:

```powershell
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
```

Why `-j 1`:
- Windows is more stable with single-threaded Flutter test runs in this project.

### CI Quality Gate

CI source of truth:
- `.github/workflows/dart.yml`

Current CI checks:
- `flutter pub get`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart run tooling/validate_agent_docs.dart`
- `dart run tooling/validate_localization.dart`
- `flutter test -j 1 -r expanded test/l10n/app_strings_test.dart`
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`

## 11) Testing Coverage Snapshot

There is broad automated coverage in:
- `test/screens/` (reader, plan, today, bookmarks, notes, settings)
- `test/data/services/` (importers, Quran.com API, planner, scheduler, calibration)
- `test/data/repositories/`
- `test/app/` (menu and preferences)
- `test/ui/` and `test/helpers/`

Representative files:
- `test/screens/reader_screen_test.dart`
- `test/data/services/qurancom_api_test.dart`
- `test/app/navigation_shell_menu_test.dart`
- `test/app/app_preferences_test.dart`

## 12) Known Constraints / Incomplete Areas

- Full UI localization infrastructure is implemented for English/French/Portuguese/Arabic; new terms should follow the localization workflow and glossary contracts.
- `Translation` and `Word By Word` settings tabs are scaffolded but not fully implemented.
- My Quran / Quran Radio / Reciters screens are placeholders.
- Web parity will require abstraction of `dart:io` usage in Quran.com cache/font services.
- Quran.com parity work is active; visuals and interactions are close in many areas but still evolving.
- No Python CI/tooling is configured because this repository currently has no Python code path; add Python configuration only when Python tooling is introduced.

## 13) Where to Edit What

- Router and route behavior:
  - `lib/app/router.dart`
- Global shell (rail + global drawer):
  - `lib/app/navigation_shell.dart`
- Language/theme preference logic:
  - `lib/app/app_preferences.dart`
  - `lib/app/app_preferences_store.dart`
  - `lib/l10n/app_language.dart`
  - `lib/l10n/app_strings.dart`
  - `lib/theme/quran_themes.dart`
  - `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
  - `docs/assistant/LOCALIZATION_GLOSSARY.md`
- Workspace performance and hygiene:
  - `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
  - `docs/assistant/PERFORMANCE_BASELINES.md`
  - `tooling/validate_workspace_hygiene.dart`
  - `.vscode/settings.json`
  - `.gitignore`
- Reader UI and behavior:
  - `lib/screens/reader_screen.dart`
- Quran.com fetch/cache/parsing:
  - `lib/data/services/qurancom_api.dart`
- QCF fonts:
  - `lib/ui/qcf/qcf_font_manager.dart`
- Planning:
  - `lib/screens/plan_screen.dart`
  - `lib/screens/today_screen.dart`
  - `lib/data/services/daily_planner.dart`
  - `lib/data/services/spaced_repetition_scheduler.dart`
- DB schema:
  - `lib/data/database/app_database.dart`

## 14) Contributor Rules of Thumb

- Keep changes scoped and verify with targeted tests first, then broader suite.
- Preserve graceful fallback behavior in reader/data pipelines.
- Avoid touching generated Drift code by hand.
- When adding UI behavior, prefer stable `ValueKey`s for testability.
- Keep Quran.com parity work grounded in source behavior, but avoid breaking existing planner and data workflows.

Current branch model:
- `main` is the stable default branch.
- active implementation branches follow `feat/*`.
