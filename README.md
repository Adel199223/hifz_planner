# hifz_planner

A new Flutter project.

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
