# hifz_planner

Hifz Planner is being re-centered around an **Adaptive Hifz Path**:
a solo-first Quran memorization companion that combines a strong reader, audio support, and local-first study tools with a guided daily memorization path.

Current product reset priorities:
- solo learner first
- Today's Hifz Path as the product center
- adaptive review and recovery instead of manual daily assembly
- weak-spot and similar-verse support over feature sprawl
- ADHD/dyslexia-friendly defaults that reduce overwhelm

Reader and audio remain major strengths and are being preserved as core support systems rather than replaced.

## Product Direction Docs

Start here for the active product reset:
- `docs/strategy/adaptive-hifz-path-solo-master-plan.md`
- `docs/roadmap/adaptive-hifz-path-solo-roadmap.md`
- `docs/algorithms/adaptive-hifz-scheduler-v1.md`
- `docs/ux/solo-learner-daily-flow.md`
- `docs/backlog/wave-1-implementation-backlog.md`

Continuity for future chats and contributors:
- `docs/assistant/ROADMAP_ANCHOR.md`

## Agent onboarding docs

- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/manifest.json`
- `docs/assistant/GOLDEN_PRINCIPLES.md`
- `docs/assistant/exec_plans/PLANS.md`
- `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- `docs/assistant/LOCALIZATION_GLOSSARY.md`
- `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- `docs/assistant/PERFORMANCE_BASELINES.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md`
- `docs/assistant/HARNESS_PROFILE.json`
- `docs/assistant/HARNESS_OUTPUT_MAP.json`

Canonical source:
- `APP_KNOWLEDGE.md` is the canonical app-level architecture/status brief.

Current roadmap default:
- `roadmap`, `master plan`, and `next milestone` now mean the Adaptive Hifz Path track unless explicitly redirected.

## User-facing guidance docs

- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PLANNER_USER_GUIDE.md`

## If You Are Not a Developer, Start Here

1. Start with `docs/assistant/features/APP_USER_GUIDE.md` for a plain-language app walkthrough.
2. If your question is about planning or daily assignments, open `docs/assistant/features/PLANNER_USER_GUIDE.md`.
3. If you are still unsure where to look, open `docs/assistant/INDEX.md`.
4. Use `APP_KNOWLEDGE.md` only when you need technical or canonical detail.

CI quality gates:
- `.github/workflows/dart.yml`

## Bootstrap Harness Maintenance

- Use `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md` for:
  - `implement the template files`
  - `sync project harness`
  - `audit project harness`
  - `check project harness`
- `docs/assistant/HARNESS_PROFILE.json` is the local bootstrap source of truth.
- `docs/assistant/HARNESS_OUTPUT_MAP.json` preserves stronger repo-local equivalents when generic bootstrap outputs would overlap.

## Reader audio streaming

- Verse-by-verse recitation streams from AlQuran Cloud CDN.
- Default source: edition `ar.alafasy`, bitrate `128`.
- Reader includes Quran.com-style playback options menu with:
  - `Download` (placeholder)
  - `Manage repeat settings` (functional)
  - `Experience` (placeholder)
  - `Speed` (functional)
  - `Reciter` (functional)
- Reciter/speed/repeat preferences persist across launches.
- `Reciters` route is a functional searchable selector backed by AlQuran Cloud editions API with bundled fallback list.
- Playback is streaming-first; offline download can be added later.
- Windows backend uses `just_audio_media_kit` (`media_kit_libs_windows_audio`).
- If audio plugin wiring looks stale on Windows, run a full rebuild/restart (`flutter clean`, `flutter pub get`, then `flutter run -d windows`).

## Flutter Development Baseline

This repo is built with Flutter.

Useful Flutter resources if you need framework help:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to generate tajweed tags JSON

Tajweed color rendering uses a generated asset at
`assets/quran/tajweed_uthmani_tags.json`.

```powershell
set QF_CLIENT_ID=...
set QF_CLIENT_SECRET=...
set QF_ENV=prelive
dart run tooling/generate_tajweed_uthmani_tags.dart
```

If the file is not generated yet, the app still works and Plain mode is used.
Generate this file to see Tajweed colors in Reader.

## Web target (Serious V1)

The repo now includes a real Flutter web target in the same codebase.

What web currently supports best:
- `/today`
- `/companion/chain`
- `/reader`
- `/plan`
- `/my-quran`
- `/settings`

Web behavior notes:
- browser storage is opened through a platform-aware Drift connection factory
- Settings and Today surface browser storage health and first-run Quran data readiness
- audio is streaming-first on web
- offline audio downloads are intentionally disabled on web for now
- Quran.com cache and QCF font persistence use lighter browser-safe fallbacks instead of native filesystem paths

Useful commands:

```powershell
flutter run -d chrome
flutter build web
cd tooling/playwright
npm install
npm run smoke
```

See also:
- `docs/WEB_VERSION_ROADMAP.md`
- `docs/assistant/exec_plans/active/2026-03-26_web_adaptive_hifz_v1.md`
