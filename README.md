# hifz_planner

A new Flutter project.

## Local developer start

If you are working in this repo locally, start with `README_START_HERE.md`.

Recommended workspace:

```bash
code /home/fa507/dev/hifz_planner-only.code-workspace
```

If local tools or WSL routing are unclear:
- `docs/assistant/LOCAL_CAPABILITIES.md`
- `docs/assistant/LOCAL_ENV_PROFILE.example.md`

## Agent onboarding docs

- `docs/assistant/SESSION_RESUME.md`
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

Canonical source:
- `APP_KNOWLEDGE.md` is the canonical app-level architecture/status brief.

## Fresh Session Resume

If a new Codex chat should continue the roadmap, start with `docs/assistant/SESSION_RESUME.md`.

Explicit trigger phrase:
- `resume master plan`

Equivalent resume intents:
- `where did we leave off`
- `what is the next roadmap step`

## User-facing guidance docs

- `docs/assistant/features/START_HERE_USER_GUIDE.md`
- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PLANNER_USER_GUIDE.md`

## If You Are Not a Developer, Start Here

1. Start with `docs/assistant/features/START_HERE_USER_GUIDE.md` for the shortest first-time path.
2. Then use `docs/assistant/features/APP_USER_GUIDE.md` for the broader whole-app walkthrough.
3. If your question is about planning or daily assignments, open `docs/assistant/features/PLANNER_USER_GUIDE.md`.
4. If you are still unsure where to look, open `docs/assistant/INDEX.md`.
5. Use `APP_KNOWLEDGE.md` only when you need technical or canonical detail.

CI quality gates:
- `.github/workflows/dart.yml`

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

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
