# ExecPlan: Goals Wave 4 - Cross-Surface Consistency and Roadmap Closeout

## Purpose
- Align the learner-facing goal and progress wording across `Today`, `My Plan`, and calm no-history/completion states.
- Finish the Goals + Progress roadmap without changing planner logic, routes, or schema.

## Scope
- In scope:
  - Shared derived progress-state helpers on top of the existing snapshot layer
  - `Today` wording alignment for weekly progress, empty states, and completion states
  - `My Plan` wording alignment for weekly progress and goal summary hints
  - Focused screen/service tests for no-history, sparse-history, and recovery-safe states
- Out of scope:
  - Schema changes
  - New navigation destinations
  - Gamification, streaks, badges, or trophies
  - Docs sync and publish closeout

## Assumptions
- The current snapshot layer already has enough persisted data for count-based progress framing.
- If a metric cannot be derived honestly from current data, the UI should stay generic rather than pretend to be more precise.
- Wave 4 should close the roadmap by aligning wording and calm state handling, not by widening scope into a new progress product.

## Milestones
1. Start Wave 4 on an isolated worktree and mark it active in the roadmap tracker.
2. Add shared progress-state helpers for no-history, sparse-history, recovery-safe, and steady/protect states.
3. Align `Today` and `My Plan` to the same progress/trust wording and state handling.
4. Add or update focused service and screen tests.
5. Validate Wave 4 locally and prepare it for narrow Assistant Docs Sync.

## Detailed Steps
1. Update `lib/data/services/goal_progress_snapshot_service.dart` with shared derived state helpers that both surfaces can use.
2. Update `lib/screens/today_screen.dart` to align weekly progress messaging and add calm empty/completion-state variants.
3. Update `lib/screens/plan_screen.dart` to align weekly progress wording and plan-summary hints to the same shared state.
4. Update `lib/l10n/app_strings.dart` only for the new learner-facing strings required by the aligned states.
5. Update focused tests:
   - `test/data/services/goal_progress_snapshot_service_test.dart`
   - `test/screens/today_screen_test.dart`
   - `test/screens/plan_screen_test.dart`
6. Run the focused Flutter tests, analyze, and the relevant Dart validators.

## Decision Log
- 2026-03-08: Wave 4 closes the roadmap by improving consistency and calm state handling instead of adding a new progress surface.
- 2026-03-08: Shared derived state belongs in the snapshot service so `Today` and `My Plan` do not drift again.

## Validation
- `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Create Wave 4 branch/worktree
- [x] Create this Wave 4 ExecPlan
- [x] Add shared progress-state helpers
- [x] Align `Today` and `My Plan`
- [x] Update focused tests
- [x] Validate locally

## Surprises and Adjustments
- Use this section for Wave 4 detours, especially if an apparently empty state is actually caused by a recovery-safe planner posture rather than missing activity.
- 2026-03-08: `My Plan` widget tests were more reliable when they asserted the aligned card structure, counts, and hints rather than one exact weekly-plan headline. The service-level state derivation is covered directly in `goal_progress_snapshot_service_test.dart`.
- 2026-03-08: Fresh-worktree Flutter validation touched `pubspec.lock` again even though this wave did not change dependencies. The lockfile was reverted before closeout.
- 2026-03-08: Narrow Assistant Docs Sync was completed for the canonical app brief, assistant bridge, app user guide, and planner user guide so the new progress-state wording is durable for future restarts.

## Handoff
- Wave 4 is active on `feat/goals-wave4-cross-surface-consistency` in `/home/fa507/dev/hifz_planner_goals_wave4`.
- Wave 4 is now implemented and validated locally:
  - `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
  - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
  - `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
  - `dart tooling/validate_workspace_hygiene.dart`
- The next branch step is narrow Assistant Docs Sync, then commit/PR closeout.
- The next branch step is feature commit/PR closeout.
- Next step: close Wave 4 with commit, PR, and merge
