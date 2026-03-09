# ExecPlan: Recent Change Integration Sweep

## Purpose
- Bring `main` up to the true recent state by landing the drafted placeholder cleanup, closing roadmap/archive drift, and hardening worktree build identity for future use.

## Scope
- In scope:
- remove the visible `Quran Radio` placeholder surface and stale `My Quran` menu subtitle
- clean current-surface docs/localization to match that runtime cleanup
- adopt the archive-first resting model for completed roadmaps and close stale `active/` plan drift
- fix `tooling/print_build_identity.dart` for real worktree ref resolution
- add validator/test coverage and issue-memory entries for the new governance and tooling rules
- Out of scope:
- reviving old draft branches directly
- changing historical research docs beyond current routing needs
- starting a new roadmap

## Assumptions
- `/home/fa507/dev/hifz_planner_placeholder_cleanup` is the reference source for the product placeholder cleanup only.
- `/home/fa507/dev/hifz_planner_vendored_bootstrap_apply` is superseded by merged `main` and should not be used as an implementation base.
- This remains one ExecPlan-only merge.

## Milestones
1. Port the placeholder cleanup and current-surface doc/localization updates.
2. Archive closed plans and align roadmap/bootstrap docs to the no-active-roadmap resting state.
3. Fix build-identity worktree ref resolution, add tests/validators/issue memory, and run validation.

## Detailed Steps
1. Create this isolated `feat/*` worktree and record the active ExecPlan.
2. Port the placeholder cleanup from the draft worktree onto current `main`, keeping scope limited to runtime/current-surface docs/localization/tests.
3. Move completed trackers/plans out of `docs/assistant/exec_plans/active/`, then update `SESSION_RESUME.md`, roadmap docs, and vendored bootstrap docs so the completed-roadmap resting model is explicit.
4. Fix `tooling/print_build_identity.dart` to resolve refs through worktree `commondir` fallback, add targeted tests, and record repeatable issue-memory entries.
5. Run the planned product, governance, and tooling validation set and update this ExecPlan with results.

## Decision Log
- 2026-03-09: Implement this sweep from a fresh branch off current `main` instead of reviving the old placeholder or bootstrap draft branches directly.

## Validation
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `dart run tooling/validate_localization.dart`
- `flutter test -j 1 -r expanded test/tooling/validate_localization_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart run tooling/validate_agent_docs.dart`
- `flutter test --no-pub -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`
- `flutter test -j 1 -r expanded test/tooling/print_build_identity_test.dart`

## Progress
- [x] Create isolated feature worktree and ExecPlan
- [x] Port product placeholder cleanup
- [x] Archive closed plans and align roadmap governance
- [x] Fix build identity and add validator/test coverage
- [x] Run full validation

## Surprises and Adjustments
- `lib/app/navigation_shell.dart` still carried a dead optional subtitle field after the placeholder copy removal; removing that unused field was required to get `flutter analyze` back to clean.
- Fresh-worktree dependency resolution touched `pubspec.lock`; the incidental lockfile churn was reverted after validation.
- The two older local draft worktrees were reviewed and found to contain only stale local drafts or already-ported changes, but deletion is deferred until the user explicitly approves removing those directories.

## Handoff
- `Quran Radio` is removed from runtime navigation, routing, placeholder UI, localization inventory, and current-surface docs; `My Quran` remains in the More menu without the stale `Coming soon` subtitle.
- `docs/assistant/exec_plans/active/` now contains only genuinely live plans during execution, and the no-active-roadmap resting model now points `docs/assistant/SESSION_RESUME.md` to completed roadmap history instead of archived trackers lingering under `active/`.
- `tooling/print_build_identity.dart` now resolves branch refs from normal repos and worktree gitdirs via `commondir` fallback, with targeted regression coverage in `test/tooling/print_build_identity_test.dart`.
- Validation passed:
  - `flutter test --no-pub -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
  - `dart run tooling/validate_localization.dart`
  - `flutter test --no-pub -j 1 -r expanded test/tooling/validate_localization_test.dart`
  - `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings`
  - `dart run tooling/validate_agent_docs.dart`
  - `dart run tooling/validate_workspace_hygiene.dart`
  - `flutter test --no-pub -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`
  - `flutter test --no-pub -j 1 -r expanded test/tooling/print_build_identity_test.dart`
