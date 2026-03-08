# CI and Repo Workflow

## What This Workflow Is For

Use this workflow for CI command parity, branch/merge hygiene, and release-safe repository operations.
For explicit commit/stage/push triage protocol, use `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`.

## Expected Outputs

- CI docs/commands stay aligned with `.github/workflows/dart.yml`.
- Branch safety and required checks remain explicit and enforceable.
- CI-facing validators/tests pass for touched scope.

## When To Use

Use when changes touch:
- `.github/workflows/dart.yml`
- branch sync/merge/reset strategy
- branch model enforcement (`main` stable, `feat/*` for major changes)
- docs and scripts that define CI/validation commands
- release gating checks before pushing to `main`

## What Not To Do

- Don't use this workflow when the request is specific staging/commit composition. Instead use `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`.
- Don't use this workflow when implementing runtime feature logic. Instead use the relevant feature/data workflow first.
- Don't use this workflow for broad doc rewrites outside CI/repo scope. Instead use `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`.
- Do not bypass fast-forward-only merge policy when it is required.
- Do not change CI commands in docs without syncing to the workflow file.
- Do not push branch cleanup/deletions before confirming critical tests pass.
- Do not implement major changes directly on `main`; create/use a `feat/*` branch first.
- Do not merge major work to `main` without PR flow and required checks.

## Primary Files

- `.github/workflows/dart.yml`
- `agent.md`
- `docs/assistant/manifest.json`
- `docs/assistant/INDEX.md`
- `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- `docs/assistant/PERFORMANCE_BASELINES.md`
- `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md`
- `tooling/validate_localization.dart`
- `tooling/validate_workspace_hygiene.dart`
- `tooling/print_build_identity.dart`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`
- `tooling/validate_agent_docs.dart`

## Minimal Commands

```powershell
git worktree list
git fetch --prune origin
git status --short --branch
git branch -vv
dart tooling/print_build_identity.dart
flutter analyze --no-fatal-infos --no-fatal-warnings
dart run tooling/validate_localization.dart
dart run tooling/validate_workspace_hygiene.dart
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart
flutter test -j 1 -r expanded test/l10n/app_strings_test.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
flutter test -j 1 -r expanded test/tooling/validate_workspace_hygiene_test.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
flutter test -j 1 -r expanded test/tooling/validate_workspace_hygiene_test.dart
flutter test -j 1 -r expanded test/l10n/app_strings_test.dart
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
5. Symptoms: parallel agent runs contaminate one branch state.
   - Move one stream to a dedicated `git worktree` and keep branch scopes isolated.
6. Symptoms: the wrong runnable build is being tested.
   - Run `dart tooling/print_build_identity.dart` and confirm the branch, SHA, worktree path, and launch command before proceeding.

## Handoff Checklist

- `.github/workflows/dart.yml` and docs commands are in sync
- `docs/assistant/manifest.json` includes `ci_repo_ops`
- major changes were developed on `feat/*` branch, not directly on `main`
- `main` updates for major work followed PR flow and required checks
- `dart run tooling/validate_agent_docs.dart` passes
- targeted CI-facing tests pass
- branch state and upstream tracking are clean before handoff
- parallel streams used isolated worktrees where applicable
