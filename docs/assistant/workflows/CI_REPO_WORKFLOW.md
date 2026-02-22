# CI and Repo Workflow

## What This Workflow Is For

Use this workflow for CI command parity, branch/merge hygiene, and release-safe repository operations.
For explicit commit/stage/push triage protocol, use `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`.

## When To Use

Use when changes touch:
- `.github/workflows/dart.yml`
- branch sync/merge/reset strategy
- docs and scripts that define CI/validation commands
- release gating checks before pushing to `main`

## What Not To Do

- Do not bypass fast-forward-only merge policy when it is required.
- Do not change CI commands in docs without syncing to the workflow file.
- Do not push branch cleanup/deletions before confirming critical tests pass.

## Primary Files

- `.github/workflows/dart.yml`
- `agent.md`
- `docs/assistant/manifest.json`
- `docs/assistant/INDEX.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`
- `tooling/validate_agent_docs.dart`

## Minimal Commands

```powershell
git fetch --prune origin
git status --short --branch
git branch -vv
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: push to `main` rejected due protections.
   - Push feature branch and open a PR instead of force-pushing.
2. Symptoms: `--ff-only` merge fails.
   - Re-fetch, inspect divergence, and resolve with explicit branch reconciliation.
3. Symptoms: docs commands differ from CI workflow.
   - Update docs and `manifest.json` to match `.github/workflows/dart.yml`.
4. Symptoms: cleanup script attempts to delete required branches.
   - Rebuild keep-list and rerun branch pruning with explicit allowlist.

## Handoff Checklist

- `.github/workflows/dart.yml` and docs commands are in sync
- `docs/assistant/manifest.json` includes `ci_repo_ops`
- `dart run tooling/validate_agent_docs.dart` passes
- targeted CI-facing tests pass
- branch state and upstream tracking are clean before handoff
