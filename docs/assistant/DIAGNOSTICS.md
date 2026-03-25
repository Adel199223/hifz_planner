# Diagnostics

Use this file when something seems wrong but you do not yet know whether the problem is docs, local setup, or app logic.

## First Packet To Collect

- branch and worktree:
  - `git status --short --branch`
  - `git worktree list`
- the exact command that failed
- the exact error text
- whether the failure is local-only or reproducible in a clean worktree

## Failure Labels

- `unavailable`
  - a tool, install, auth state, browser session, or local dependency is missing
- `failed`
  - the command ran, but the logic or assertion was wrong

## Fast Triage Order

1. Check repo state and worktree.
2. Check whether the workflow you are following is the right one.
3. Run the smallest validator or targeted test for that area.
4. Only then widen to broader checks.

## Bootstrap Harness Checks

```powershell
py -3.11 tooling/check_harness_profile.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json
py -3.11 tooling/preview_harness_sync.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json --output-map docs/assistant/HARNESS_OUTPUT_MAP.json --write-state docs/assistant/runtime/BOOTSTRAP_STATE.json
```

## Docs Contract Checks

```powershell
dart run tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Flutter Checks

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
```
