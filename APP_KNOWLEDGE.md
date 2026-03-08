# APP_KNOWLEDGE - Hifz Planner

This document is the single-source project briefing for outsiders (new engineers, reviewers, and AI agents).
It explains what the app is, what is already implemented, where key logic lives, and how to work safely.

## If You Are Not a Developer (Read This First)

- This file is technical and canonical.
- If you want a beginner-friendly explanation, start with:
  - `docs/assistant/features/APP_USER_GUIDE.md`
  - `docs/assistant/features/PLANNER_USER_GUIDE.md` (for planning-specific questions)
- If those guides and this file disagree, this file and source code are the final truth.

## 0) Agent Docs Map

Documentation contract for contributors and AI agents:
- Canonical app brief: `APP_KNOWLEDGE.md` (this file)
- Compatibility entrypoint: `AGENTS.md`
- Agent runbook entrypoint: `agent.md`
- Assistant bridge path: `docs/assistant/APP_KNOWLEDGE.md`
- DB/Drift deep reference: `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- Assistant doc index: `docs/assistant/INDEX.md`
- Machine manifest: `docs/assistant/manifest.json`
- Issue memory registry: `docs/assistant/ISSUE_MEMORY.md` and `docs/assistant/ISSUE_MEMORY.json`
- Mechanical rules: `docs/assistant/GOLDEN_PRINCIPLES.md`
- ExecPlan playbook: `docs/assistant/exec_plans/PLANS.md`
- Local environment overlay format: `docs/assistant/LOCAL_ENV_PROFILE.example.md`
- Discovered capability inventory: `docs/assistant/LOCAL_CAPABILITIES.md`

User-perspective guides:
- Planner deep guide (non-coder): `docs/assistant/features/PLANNER_USER_GUIDE.md`
- Whole-app guide (non-coder): `docs/assistant/features/APP_USER_GUIDE.md`

If documentation conflicts:
- this file (`APP_KNOWLEDGE.md`) is canonical for overall app behavior and structure
- source code remains the final truth

Workflow runbooks:
- Reader/UI: `docs/assistant/workflows/READER_WORKFLOW.md`
- Localization/i18n: `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- Quran.com data/cache/fonts: `docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md`
- Planner/scheduler: `docs/assistant/workflows/PLANNER_WORKFLOW.md`
- Scheduling + companion engine: `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`
- Workspace performance: `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- Reference discovery: `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`
- Worktree/build identity: `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md`
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
- consult issue memory first when deciding whether the docs sync should widen beyond directly touched files.

Why two `APP_KNOWLEDGE.md` files:
- Root `APP_KNOWLEDGE.md` is canonical and complete.
- `docs/assistant/APP_KNOWLEDGE.md` is intentionally shorter as a bridge/bootstrap doc.

Why both `AGENTS.md` and `agent.md` exist:
- `AGENTS.md` is a short compatibility shim for auto-discovery tools.
- `agent.md` is the operational runbook for humans and AI agents.

## 0.1) Bootstrap Module Status

Active modules:
- Core contract and routing:
  - canonical docs, bridge docs, manifest routing, validators, and targeted workflows are active
- Issue memory system:
  - `docs/assistant/ISSUE_MEMORY.md`
  - `docs/assistant/ISSUE_MEMORY.json`
- Local environment overlay:
  - tracked format: `docs/assistant/LOCAL_ENV_PROFILE.example.md`
  - machine-local overlay: keep a same-directory local profile on the machine that actually runs the repo
- Capability discovery:
  - `docs/assistant/LOCAL_CAPABILITIES.md`
- Worktree/build identity:
  - `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md`
  - `tooling/print_build_identity.dart`
  - canonical runnable build: `/home/fa507/dev/hifz_planner` via `/home/fa507/dev/hifz_planner-only.code-workspace`

Intentionally inactive modules:
- Host integration preflight:
  - keep inactive until a feature depends on local auth, desktop automation, browser state, or same-host CLI integration
- Bootstrap update policy as a project workflow:
  - template maintenance remains separate from normal project work even though this repo carries local template files

## 1) App Purpose

Hifz Planner is a Flutter app focused on Quran reading and memorization workflow.

Current product direction:
- Quran.com-style reading experience (both Mushaf reading and Verse-by-Verse views).
- Practical hifz planning workflow (onboarding settings, daily plan, review grading, calibration, forecast).
- Local-first data with robust fallback behavior.

Primary target right now is desktop (Windows-first), while keeping architecture reusable for Android/iOS later.

## 2) Current User-Facing Surface

### Navigation
- Left `NavigationRail` now carries the core daily path:
  - Today, Read, My Plan, Library
- `Library` is a hub for:
  - Bookmarks
  - Notes
- A top-right `More` drawer holds secondary tools and destinations:
  - Settings, About, Reciters
  - `Explore` section: Learn, My Quran, Quran Radio
- `Learn` now includes:
  - a simple `Practice from Memory` hub
  - the existing `Hifz Plan` card

### Routes
Defined in `lib/app/router.dart`:
- `/reader`
- `/bookmarks`
- `/library`
- `/notes`
- `/plan`
- `/learn`
- `/my-quran`
- `/quran-radio`
- `/reciters`
- `/today`
- `/companion/chain`
- `/settings`
- `/about`

`/reader` also supports query params:
- `mode`, `page`
- `targetSurah`, `targetAyah`
- `highlightStartSurah`, `highlightStartAyah`
- `highlightEndSurah`, `highlightEndAyah`

`/companion/chain` query params:
- `unitId` (required)
- `mode` (`new` or `review`, defaults to review if omitted)

### Global Preferences (persisted)
- Language options (fully wired for app UI strings):
  - English, Français, العربية, Português
- Theme options:
  - Sepia, Dark
- Companion options:
  - `Autoplay next ayah` toggle for Companion recitation (default off)
- Stored via SharedPreferences and restored on startup.
- SharedPreferences fallback remains no-crash:
  - if local persistence is unavailable, the app still loads defaults
  - unexpected load/save failures are now logged as non-fatal diagnostics instead of being silently swallowed

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
- Verse-by-Verse suppresses Quran.com end-marker circle tokens (`char_type_name=end`) at display time.
- No "whole-row tap opens old sheet" behavior.
- Bookmark/note/copy are wired to existing logic.
- Copy feedback is truthful:
  - success appears only after the clipboard write completes
  - clipboard failures show a failure snackbar instead of a false success message
- Play/share/extra actions are scaffold-safe where backend is not ready.

Chapter header behavior:
- Quran.com-style external chapter header on surah-start context.
- Uses SurahNames font glyph + `assets/quran/bismillah.svg` when applicable.
- Header title format follows Quran.com ordering:
  - non-Arabic: `<chapter>. <name>` (example: `1. Al-Fatihah`)
  - Arabic locale: Arabic name + chapter number.
- Header subtitle uses chapter translated meaning (for example `The Opener`) when available.
- Header bidi is explicit per locale to avoid punctuation inversion in mixed-script titles.

Top controls and tajweed legend:
- Listen and Translation remain primary top actions.
- Top actions are responsive:
  - the main action strip stays horizontally scrollable
  - the settings button sits on its own aligned row
  - opening reader settings still hides the global menu button
- `Tajweed colors` is rendered in a dedicated legend section.
- Tajweed legend (colored dots + labels) appears only when Tajweed mode is active.

Directionality and alignment:
- Arabic ayah lines are rendered RTL and right-anchored.
- Translation lines are forced LTR in all app locales (including Arabic UI) to avoid punctuation-order artifacts.
- Arabic sidebar uses localized search placeholder and Arabic surah names.

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
- Audio stack uses `just_audio` with `just_audio_media_kit` backend (`media_kit_libs_windows_audio` on Windows).
- `just_audio_windows` is intentionally not used due Windows thread-channel instability observed during reciter switching.
- After changing audio plugin dependencies, run a full restart/rebuild (not only hot reload) so plugin registration is reloaded.

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

### 4.2 Quran.com chapters service

File: `lib/data/services/qurancom_chapters_service.dart`

Responsibilities:
- Fetch chapter labels and translated names from Quran.com:
  - `https://api.quran.com/api/v4/chapters?language={code}`
- Parse chapter presentation fields used by Reader header/sidebar:
  - `name_simple`, `name_arabic`, `translated_name`.
- Cache per-language chapter payloads in app support directory.
- Fallback to cache if network fails; fallback again to bundled/local metadata in Reader if cache is missing.

### 4.3 QCF font manager

File: `lib/ui/qcf/qcf_font_manager.dart`

Responsibilities:
- Download/cache per-page QCF fonts.
- Load fonts dynamically into Flutter runtime.
- Handle v4 tajweed fallback to v2.

Note:
- Uses `dart:io` and local filesystem; this is a known constraint for web parity later.

## 5) Local Data Model (Drift)

Database file: `lib/data/database/app_database.dart`
Schema version: `7`

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
- `companion_chain_session`
- `companion_verse_attempt`
- `companion_unit_state`
- `companion_stage_event`
- `companion_step_proficiency`

Key points:
- `ayah` unique key: `(surah, ayah)`
- `app_settings` now persists scheduling contracts:
  - `scheduling_prefs_json`
  - `scheduling_overrides_json`
- companion persistence now includes:
  - per-attempt `stage_code` (`guided_visible`, `cued_recall`, `hidden_reveal`)
  - Stage-1 telemetry columns on `companion_verse_attempt`:
    - `attempt_type` (`encode_echo`, `probe`, `spaced_reprobe`, `checkpoint`)
    - `assisted_flag`
    - `auto_check_type`
    - `auto_check_result`
    - `time_on_verse_ms`
    - `time_on_chunk_ms`
    - `telemetry_json`
  - per-unit staged unlock state (`companion_unit_state`)
  - stage transition/skip/resume telemetry (`companion_stage_event`)
- `companion_unit_state` creation now uses conflict-safe insertion so parallel readers do not hide unexpected storage issues behind a broad catch.
- companion attempt/proficiency tables are indexed for session/verse/unit lookup.
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
  - `companion_repo.dart`
- Services:
  - `quran_text_importer_service.dart`
  - `page_metadata_importer_service.dart`
  - `daily_planner.dart`
  - `spaced_repetition_scheduler.dart`
  - `calibration_service.dart`
  - `forecast_simulation_service.dart`
  - `new_unit_generator.dart`
  - `scheduling/planning_projection_engine.dart`
  - `scheduling/availability_interpreter.dart`
  - `scheduling/weekly_plan_generator.dart`
  - `scheduling/daily_content_allocator.dart`
  - `scheduling/scheduling_preferences_codec.dart`
  - `companion/progressive_reveal_chain_engine.dart`
  - `companion/verse_evaluator.dart`
  - `companion/companion_calibration_bridge.dart`
  - `tajweed_tags_service.dart`
  - `surah_metadata_service.dart`
  - `qurancom_api.dart`

## 7) Hifz Planning Flow (Implemented)

### Plan screen
File: `lib/screens/plan_screen.dart`

User-facing explainer:
- `docs/assistant/features/PLANNER_USER_GUIDE.md` (plain-language walkthrough of every planner option and expected outcomes)

Current capabilities:
- Preset-first setup flow:
  - `Easy`, `Normal`, `Intensive`
  - realistic time question
  - fluency question
  - plain-language plan summary before activation
- Activate/update settings (`profile`, minutes, caps, etc.) without opening advanced controls
- Guided setup now syncs visible time inputs into scheduling preferences, so the weekly planner preview follows the same time values the user entered
- Plan health card now surfaces the current posture in plain language:
  - `On track`
  - `Tight`
  - `Overloaded`
- Plan health copy can now explain:
  - when backlog burn-down is recommended
  - when a minimum viable day is safer than pushing full load
  - when repeated missed work should trigger recovery guidance
- Weekly planner status now follows the same deterministic stress policy used by `Today`:
  - tighter days can surface `due soon`
  - overloaded days can flip session focus to review-only
- `Advanced` gate for expert controls instead of exposing the full simulator-style surface on first load
- Advanced planning tools remain available behind `Advanced`:
  - profile, review-protection, caps, and pace assumptions
  - scheduling preferences:
    - default `2 sessions/day`
    - optional fixed times
    - enabled study days + revision-only days
    - availability models: minutes/day, minutes/week, specific windows
  - weekly calendar (rolling next 7 days) with session focus/minutes/status
  - per-day override shell (skip/holiday + per-session time override)
  - calibration sample logging, guidance, and apply timing
  - forecast summary, confidence, and detailed curves
- Forecast and weekly planning now use the same shared allocation policy as `Today`, so planner pressure is more consistent across surfaces
- Forecast now starts with:
  - a plain-language summary
  - a simple confidence label
  - a short explanation of why that confidence is high, medium, or low
- Forecast can now also surface a plain-language pace-trend note when recent calibration shows the learner is moving materially slower or faster than the active plan
- Calibration now behaves more like `teach the planner your pace` than a raw tuning panel:
  - it encourages a few real samples first
  - it can apply now or starting tomorrow
  - its sample data and grade distribution now slightly influence how cautiously the shared planner treats review pressure and new-work budget
  - recent calibration pace now also adds one bounded adaptive nudge to the shared planner, so `Today`, weekly planning, and Forecast can all become slightly more cautious or slightly more permissive without diverging into separate rule systems

### Today screen
File: `lib/screens/today_screen.dart`

User-facing explainer:
- `docs/assistant/features/PLANNER_USER_GUIDE.md` (execution flow, Stage-4 due handling, grading, and override guidance)

Current capabilities:
- Build today plan from a shared deterministic scheduler path that is also used by Forecast and weekly planning
- Render a top coaching card that:
  - chooses one next action in plain language
  - explains why that action matters today
  - gives a short-day fallback
  - exposes a recovery entry point back to `My Plan`
  - can show secondary practice-mode shortcuts when other valid modes still remain after the main priority item
- Render a health badge and explanation packet so the learner can see whether the day is:
  - `On track`
  - `Tight`
  - `Overloaded`
- Today explanation packet can now explain:
  - when new work is paused
  - when new work is reduced
  - when backlog burn-down is the safer posture
- Show a `Do the minimum day` action when current pressure suggests a shorter safe day
- Show a Recovery assistant entry when the current day looks overloaded or repeated pressure is building
- Recovery assistant remains advice-first:
  - it does not silently change planner settings
  - it recommends the next safest move based on a simple scenario choice
  - it can route the learner to the minimum day flow or back to `My Plan`
- Render planned reviews and planned new memorization
- Render dedicated Stage-4 delayed-consolidation due items with urgency metadata
- Mandatory Stage-4 due now reserves planner minutes before new memorization is assigned, even when the learner explicitly overrides the default block
- Render completion and empty-state cards when there is no remaining actionable work
- Render sessionized day blocks (timed or untimed) with recovery signal
- Save grades (`q=5/4/3/2/0`)
- "Open in Reader" deep-link with page mode + verse range highlight params
- Practice-first launch actions for daily work:
  - review rows use `Continue review practice`
  - new rows use `Start new practice`
  - delayed checks use `Do delayed check`
- Soft-block NEW launch when mandatory Stage-4 due exists (explicit override allowed and logged)
- New work now uses a minimum viable threshold:
  - if only a tiny unsafe remainder is left after retention work, new memorization is paused instead of creating token assignments
- Stage-4 section now includes a plain-language explanation for why delayed checks are prioritized ahead of new work
- Companion route launch:
  - review: `/companion/chain?unitId=...&mode=review`
  - new practice: `/companion/chain?unitId=...&mode=new`
  - delayed check: `/companion/chain?unitId=...&mode=stage4`
- When new work is the top coaching action, `Today` now routes directly into the practice flow instead of sending the learner to Reader first

## 8) Other Screens

- `lib/screens/learn_screen.dart`
  - Learn container page
  - includes a `Practice from Memory` card with direct launch buttons for:
    - `Start new practice`
    - `Continue review practice`
    - `Do delayed check`
  - teaches a simple best-order rule:
    - delayed check first
    - review next
    - new practice after retention work feels stable
  - uses already-existing direct targets when possible
  - each practice entry now shows whether it is:
    - `Ready now`
    - or `Opens Today for guidance`
  - falls back to `/today` when no direct practice target is ready yet
  - includes the Hifz Plan entry card linking to `/plan`
- `lib/screens/my_quran_screen.dart`
  - placeholder scaffold (`coming soon`)
- `lib/screens/quran_radio_screen.dart`
  - placeholder scaffold (`coming soon`)
- `lib/screens/reciters_screen.dart`
  - functional searchable reciter selector with persisted selection
- `lib/screens/settings_screen.dart`
  - import Quran text + import page metadata + progress status
- `lib/screens/bookmarks_screen.dart`
  - list bookmarks with go-to verse/page actions
- `lib/screens/notes_screen.dart`
  - list notes + edit dialog + go-to verse/page actions
- `lib/screens/companion_chain_screen.dart`
  - learner-facing screen title now says `Practice from Memory`
  - learner-facing runtime is now task-first instead of stage-first:
    - top status uses plain labels like `Listen and follow`, `Recite with a cue`, `Recite from memory`, `Review from memory`, and `Delayed check`
    - the main action card now leads with `What to do now`
    - correction states tell the learner to listen to the correction before retrying
    - stage progress is shown as `Practice step X/Y`
  - human-readable session details now include:
    - `Verse X of Y`
    - delayed-check due text mapped into plain labels instead of raw due codes
    - summary text like `Practice complete`, `Completed verses`, `Average help used`, and `Average memory strength`
  - internal deterministic stage/runtime model remains unchanged under the hood:
  - staged companion flow for new units:
    - Stage 1 `guided_visible` uses internal deterministic sub-modes:
      - `Model+Echo` (talqin exposure, capped loops)
      - mandatory H0 hidden cold probes with required micro-check by default
      - correction gate after failed cold attempts
      - per-verse time-based spaced confirmation
      - chunk checkpoint + targeted remediation + short cumulative hidden check
      - budget fallback marks weak verses and advances to Stage 2
    - Stage 2 `cued_recall` (deterministic minimal-cue bridge):
      - adaptive cue baseline (`H2` weak / `H1` non-weak) with cue fading toward `H0`
      - telemetry-triggered discrimination checks + required linking pass (`k-1 -> k`)
      - correction gate after failures, checkpoint threshold (`0.75`), and failed-only remediation
      - budget fallback carries unresolved weak verses into guarded Stage-3 prelude
    - Stage 3 `hidden_reveal` (NEW mode runtime):
      - deterministic Stage-3 runtime is active only for NEW runs (`state.stage3 != null`); review keeps the legacy hidden path unchanged
      - guarded weak-prelude is mandatory when `stage3WeakPreludeTargets` is non-empty:
        - prelude targets are consumed first in deterministic order
        - hint cap remains `H1` until prelude targets clear
      - Stage-3 modes are runtime-driven (`weak_prelude`, `hidden_recall`, `linking`, `discrimination`, `correction`, `checkpoint`, `remediation`)
      - failure in any retrieval mode enforces correction exposure before next cold attempt
      - counted-pass/readiness path remains strict (unassisted, hint-threshold limited, auto-check required by default)
      - budget overflow is explicit (`budgetFallback` phase, non-terminal), preserving unresolved weak requirements for follow-up
    - Stage 4 delayed consolidation (`mode=stage4`, lifecycle runtime):
      - activation uses `hidden_reveal` stage code with dedicated runtime (`state.stage4 != null`) and lifecycle telemetry tags
      - deterministic verification order prioritizes correction-required and weak/risk targets, then random-start and linking obligations
      - run structure is retrieval-first and short: cold-start, random-start probes, linking checks, targeted discrimination, failed-only remediation
      - failures in all Stage-4 retrieval modes require correction exposure before retry
      - outcomes are explicit and persisted:
        - `pass` => lifecycle tier `stable`, Stage-5 candidate hook
        - `partial` => unresolved targets carried forward for retry
        - `fail` => strengthening route (`targeted_stage3`/`broad_stage3`) plus retry scheduling
      - mandatory next-day delayed check is prioritized in Today and can soft-block NEW generation
  - review runs stay hidden-first (`mode=review`)
  - stage skip with confirmation logs telemetry and persists unlock stage
  - recitation controls:
    - `Play current ayah` button
    - persisted `Autoplay next ayah` toggle (SharedPreferences)
  - shared word-hover parity with Reader Verse-by-Verse:
    - per-word hover highlight
    - per-word translation tooltip
    - end-marker suppression (`char_type_name=end`) in Companion + Reader Verse-by-Verse scope
  - hidden verses render without dot placeholders
  - Arabic rendering parity with tajweed colors by default (no reader action-chip parity)
- `lib/screens/about_screen.dart`
  - placeholder

## 9) Assets and Tooling

### Key assets
- `assets/quran/tanzil_uthmani.txt` (optional at runtime in some environments)
- `assets/quran/tajweed_uthmani_tags.json` (bundled generated tajweed overlay data for offline-by-default coloring)
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

Scheduling + companion focused validation:

```powershell
flutter test -j 1 -r expanded test/app/app_preferences_test.dart
flutter test -j 1 -r expanded test/screens/plan_screen_test.dart
flutter test -j 1 -r expanded test/screens/today_screen_test.dart
flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/ui/quran/quran_word_wrap_test.dart
flutter test -j 1 -r expanded test/data/services/tajweed_tags_service_test.dart
flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart
flutter test -j 1 -r expanded test/data/services/spaced_repetition_scheduler_test.dart
flutter test -j 1 -r expanded test/data/database/app_database_test.dart
flutter test -j 1 -r expanded test/data/repositories/companion_repo_test.dart
flutter test -j 1 -r expanded test/data/services/scheduling
flutter test -j 1 -r expanded test/data/services/companion
dart run tooling/validate_localization.dart
dart run tooling/validate_agent_docs.dart
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
- My Quran and Quran Radio screens are placeholders.
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
  - `lib/ui/quran/quran_word_wrap.dart`
  - `lib/data/services/quran_wording.dart`
- Quran.com fetch/cache/parsing:
  - `lib/data/services/qurancom_api.dart`
- QCF fonts:
  - `lib/ui/qcf/qcf_font_manager.dart`
- Planning:
  - `lib/screens/plan_screen.dart`
  - `lib/screens/today_screen.dart`
  - `lib/screens/companion_chain_screen.dart`
  - `lib/ui/quran/quran_word_wrap.dart`
  - `lib/data/services/daily_planner.dart`
  - `lib/data/services/forecast_simulation_service.dart`
  - `lib/data/services/spaced_repetition_scheduler.dart`
  - `lib/data/services/scheduling/planning_projection_engine.dart`
  - `lib/data/services/scheduling/availability_interpreter.dart`
  - `lib/data/services/scheduling/weekly_plan_generator.dart`
  - `lib/data/services/scheduling/daily_content_allocator.dart`
  - `lib/data/services/scheduling/scheduling_preferences_codec.dart`
  - `lib/data/services/companion/progressive_reveal_chain_engine.dart`
  - `lib/data/services/companion/verse_evaluator.dart`
  - `lib/data/services/companion/companion_calibration_bridge.dart`
  - `lib/data/repositories/companion_repo.dart`
  - `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`
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
