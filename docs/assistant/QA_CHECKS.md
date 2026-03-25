# QA Checks

This file lists the smallest useful validation commands for each major docs/workflow surface.

## Bootstrap Harness

```powershell
py -3.11 tooling/check_harness_profile.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json
py -3.11 tooling/preview_harness_sync.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json --output-map docs/assistant/HARNESS_OUTPUT_MAP.json --write-state docs/assistant/runtime/BOOTSTRAP_STATE.json
```

## Assistant Docs Contracts

```powershell
dart run tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Reader

```powershell
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
```

## Planner

```powershell
flutter test -j 1 -r expanded test/screens/plan_screen_test.dart
flutter test -j 1 -r expanded test/screens/today_screen_test.dart
```

## Companion

```powershell
flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart
flutter test -j 1 -r expanded test/data/services/companion/verse_evaluator_test.dart
```
