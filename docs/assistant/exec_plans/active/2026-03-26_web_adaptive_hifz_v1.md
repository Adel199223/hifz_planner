# ExecPlan: Web Adaptive Hifz V1

Date: 2026-03-26
Status: active
Owner: Codex

## Goal

Land a serious Flutter web target for the existing Adaptive Hifz app without rewriting the product or breaking native behavior.

## Scope

- Add and stabilize the `web/` target.
- Keep Today, Companion, Reader, Plan, My Quran, and Settings in one coherent browser-first shell.
- Move database opening behind a platform-aware connection factory.
- Surface browser storage health and first-run Quran data readiness.
- Replace native-only filesystem assumptions with web-safe fallbacks for Quran.com cache, QCF fonts, and audio resolution.
- Preserve streaming audio on web and hide offline-download-only paths.
- Add a small Playwright + Chromium smoke harness.
- Update repo docs and assistant continuity docs.

## Workstreams

1. Bootstrap and startup
- add standard Flutter web assets
- gate desktop-only audio bootstrap
- enable semantics on web startup for accessibility and browser automation

2. Persistence and readiness
- add `AppDatabaseConnectionFactory`
- add `DatabaseStorageStatus`
- add `QuranDataReadiness`
- show setup/import CTA instead of assuming bundled data has already been imported

3. Native/web service seams
- conditional-export native and web variants for Quran.com services, QCF font manager, and audio services
- keep native filesystem behavior
- use memory/network-first fallbacks on web

4. Product polish for browser use
- responsive shell for narrow/medium/wide widths
- Today keeps one obvious next action
- expose one guided setup path that prepares the first unit when Quran data exists but the learner has no units yet
- add route-level semantics and keyboard affordances where safe

5. Browser automation
- add `tooling/playwright/`
- serve built web output in Chromium
- cover launch, setup/import, Today, starter-unit flow, Companion launch, Reader deep links, and responsive shell smoke

## Validation plan

- `flutter pub get`
- `dart run tooling/validate_localization.dart`
- `dart run tooling/validate_agent_docs.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- targeted Flutter tests for navigation, today, reader, settings, planner, and web seams
- `flutter run -d chrome`
- `flutter build web`
- Playwright smoke tests against the served web app

## Notes

- Web V1 degrades offline audio downloads, disk-backed Quran.com cache, and persistent QCF disk cache.
- Browser storage health is visible in Settings and Today.
- Plan screen now writes legacy minute fields and structured scheduling prefs from one coherent source of truth.
- Today and Settings now share one guided setup flow that imports Quran text first, backfills page metadata only if it is still missing, saves a calm starter plan, and prepares the first memorization unit.
- TodayPath now follows typed planner availability/notice state instead of fragile string checks.
