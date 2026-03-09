# ExecPlan: Post-Wave1 Critical Fixes

## Purpose
- Land the approved high-severity runtime and test fixes after Wave 1 without dragging the dirty audit branch into `main`.

## Scope
- In scope:
  - truthful Reader clipboard feedback
  - non-silent SharedPreferences diagnostics
  - conflict-safe companion unit-state creation
  - targeted regression tests for those fixes
  - narrow tracker updates for this branch
- Out of scope:
  - template/bootstrap maintenance
  - local env capability churn
  - unrelated docs cleanup

## Assumptions
- Wave 1 is already merged to `main`.
- The dirty `feat/audit-critical-fixes` branch is a reference source only.
- No DB schema changes are required for this port.

## Milestones
1. Port runtime fixes from the audit branch.
2. Add and run targeted tests.
3. Publish the clean post-Wave1 stability branch.

## Detailed Steps
1. Update the preferences stores to report persistence failures without breaking fallback behavior.
2. Update Reader copy behavior so success appears only after a real clipboard write.
3. Replace the broad catch in companion unit-state creation with conflict-aware insertion.
4. Add the targeted regression tests for preferences, Reader copy failure, and concurrent companion state creation.
5. Update the shared execution tracker for branch start and next-step routing.

## Decision Log
- 2026-03-08: Port only the approved runtime/test fixes instead of merging the dirty audit branch.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter test -j 1 -r expanded test/data/repositories/companion_repo_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
- `flutter test -j 1 -r expanded test/data/services/ayah_audio_preferences_test.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Port runtime fixes
- [x] Add targeted regression tests
- [x] Validate and publish branch

## Surprises and Adjustments
- Record any extra Wave 1 overlap found during the port.
- `flutter analyze` refreshed `pubspec.lock` even without dependency changes; the incidental lock churn was reverted before commit.

## Handoff
- This fix set shipped on `main` in commit `40d8c28` before Wave 2 started.
