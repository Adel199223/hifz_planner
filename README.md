# hifz_planner

A new Flutter project.

## Agent onboarding docs

- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/manifest.json`
- `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- `docs/assistant/LOCALIZATION_GLOSSARY.md`
- `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- `docs/assistant/PERFORMANCE_BASELINES.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`

Canonical source:
- `APP_KNOWLEDGE.md` is the canonical app-level architecture/status brief.

CI quality gates:
- `.github/workflows/dart.yml`

## Reader audio streaming

- Verse-by-verse recitation streams from AlQuran Cloud CDN.
- Default source: edition `ar.alafasy`, bitrate `128`.
- Playback is streaming-first; offline download can be added later.

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
