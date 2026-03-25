# Safe Commands

Use these commands when you want low-risk checks that do not change app logic.

## Repo State

```powershell
git status --short --branch
git worktree list
```

## Harness And Docs

```powershell
py -3.11 tooling/check_harness_profile.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json
py -3.11 tooling/preview_harness_sync.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json --output-map docs/assistant/HARNESS_OUTPUT_MAP.json --write-state docs/assistant/runtime/BOOTSTRAP_STATE.json
dart run tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Flutter Health

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/screens/plan_screen_test.dart
flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart
```

## When To Stop And Ask

- If a command wants to delete files you did not mean to touch.
- If a DB/schema or migration change is about to happen.
- If a command needs a force-push, publish, or deploy step.
- If a command depends on auth, browser state, or another local app and you are not sure the same host is ready.
