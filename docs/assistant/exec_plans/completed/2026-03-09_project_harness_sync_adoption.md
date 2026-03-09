# ExecPlan: Adopt the New Vendored Bootstrap System

## Purpose
- Align this repo with the newer vendored bootstrap model so copied `docs/assistant/templates/*` files can be applied locally through `implement the template files`.

## Scope
- In scope:
- Port the newer vendored template inventory and local harness routing into this repo.
- Add the project-local harness apply workflow, manifest contracts, and roadmap anchor-file wording.
- Port validator and test coverage for vendored template integrity and anchor-first roadmap routing.
- Out of scope:
- Product/runtime behavior changes outside assistant/bootstrap infrastructure.
- Global bootstrap redesign beyond the already-vetted reference worktree.

## Assumptions
- `/home/fa507/dev/hifz_planner_vendored_bootstrap_apply` is the reference source for the desired assistant/bootstrap state.
- This remains a single-merge ExecPlan, not a roadmap.
- Vendored template files should remain committed project assets in this repo.

## Milestones
1. Sync vendored template and harness docs into the feature worktree.
2. Port validator/test coverage and run the bootstrap validation set.
3. Record final state and handoff in this ExecPlan.

## Detailed Steps
1. Create an isolated `feat/*` worktree from `main` and record the active ExecPlan.
2. Copy the vetted assistant/bootstrap files from `/home/fa507/dev/hifz_planner_vendored_bootstrap_apply` into this worktree while keeping scope limited to harness/templates/workflows/validator files.
3. Run `dart run tooling/validate_agent_docs.dart`, `dart run tooling/validate_workspace_hygiene.dart`, and `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`.
4. Update this ExecPlan with progress, surprises, and validation results.

## Decision Log
- 2026-03-09: Use the existing vendored-bootstrap draft worktree as the port source instead of re-deriving the changes on `main`; this reduces drift and preserves the already-vetted contract set.
- 2026-03-09: Copy the vetted file set in bulk from the reference worktree and then validate locally, rather than reapplying each bootstrap edit by hand; the source/destination repos are the same project and the reference worktree already encoded the intended contract set.

## Validation
- `dart run tooling/validate_agent_docs.dart`
- `dart run tooling/validate_workspace_hygiene.dart`
- `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three

## Surprises and Adjustments
- An initial absolute-path `rsync` created an accidental nested `home/` tree inside the feature worktree; that stray directory was removed immediately and the sync was rerun with relative paths.
- `flutter test --no-pub` was not viable in this fresh worktree because the test package setup had not been resolved yet, so validation used `flutter test` once to resolve dependencies. The incidental `pubspec.lock` churn was reverted afterward.

## Handoff
- Active worktree: `/home/fa507/dev/hifz_planner_project_harness_sync`
- Branch: `feat/project-harness-sync-adoption`
- Result: this worktree now carries the newer vendored-template inventory, the `PROJECT_HARNESS_SYNC_WORKFLOW.md` local apply flow, manifest version `14`, explicit `SESSION_RESUME.md` roadmap-anchor wording, vendored-template commit/ignore policy, and the matching validator/test coverage.
- Assistant Docs Sync: completed for the assistant/bootstrap scope, including a fresh-worktree fallback note in `PROJECT_HARNESS_SYNC_WORKFLOW.md` for dependency bootstrap before `--no-pub` test runs.
- Validation passed for `dart run tooling/validate_agent_docs.dart`, `dart run tooling/validate_workspace_hygiene.dart`, and `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`.
- `pubspec.lock` was restored after dependency bootstrap; no runtime/product files were intentionally changed.
