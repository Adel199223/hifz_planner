# ExecPlan: Goals Wave 3 - Goal Coaching and Adjustment Guidance

## Purpose
- Add a gentle recommendation layer on top of the existing goal/progress snapshot so the learner knows what to do next without reading planner jargon.
- Keep the guidance advice-only: no silent plan mutation, no punitive language, and no new settings flow.
- Reuse the current planner posture and recent-progress snapshot instead of introducing new schema or route contracts.

## Scope
- In scope:
  - one shared coaching recommendation model derived from existing planner feedback and goal/progress snapshot data
  - integrated advice in `Today`
  - integrated advice in `My Plan`
  - focused tests for the new recommendation logic and the two affected screens
- Out of scope:
  - automatic settings changes
  - route or schema changes
  - gamified goal systems
  - Wave 4 wording alignment and broader empty/completion state cleanup

## Assumptions
- The existing `GoalProgressSnapshotService` already has enough honest signal to support a first coaching layer.
- Recent progress should be interpreted calmly: sparse progress means simplify, not push harder.
- `Today` and `My Plan` should use the same recommendation logic so the learner does not get mixed messages.
- If the current persisted data is too weak to support a more precise recommendation, the guidance should stay broad and safe.

## Milestones
1. Add the shared recommendation model and derivation logic.
2. Integrate the recommendation into `Today`.
3. Integrate the recommendation into `My Plan`.
4. Validate the new guidance with focused service and widget tests.

## Detailed Steps
1. Extend `lib/data/services/goal_progress_snapshot_service.dart` with:
   - a coaching recommendation enum
   - a small shared advice model
   - derivation helpers for `TodayPlan` and `WeeklyPlan`
2. Update `lib/screens/today_screen.dart` to show one advice block that:
   - recommends the next safe posture
   - explains what counts as progress
   - stays advice-only
3. Update `lib/screens/plan_screen.dart` to show the same recommendation logic in `My Plan`.
4. Add learner-facing copy in `lib/l10n/app_strings.dart`.
5. Add focused tests in:
   - `test/data/services/goal_progress_snapshot_service_test.dart`
   - `test/screens/today_screen_test.dart`
   - `test/screens/plan_screen_test.dart`

## Decision Log
- 2026-03-08: Keep Wave 3 recommendation logic inside the shared goal/progress service so `Today` and `My Plan` stay aligned.
- 2026-03-08: Treat the guidance as advice only; Wave 3 should not mutate planner settings or scheduling state automatically.

## Validation
- `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Start Wave 3 ExecPlan and tracker update
- [x] Add shared coaching recommendation model
- [x] Integrate Today coaching guidance
- [x] Integrate My Plan coaching guidance
- [x] Run focused validation

## Surprises and Adjustments
- 2026-03-08: The first fresh-worktree Flutter test invocation touched dependency resolution state, but `pubspec.lock` churn remained incidental and was reverted after validation.
- 2026-03-08: The weekly plan widget path can legitimately surface a safer recommendation than the raw last-7-days summary alone suggests, because the recommendation also uses the live planner posture from the generated weekly plan.
- 2026-03-08: Assistant Docs Sync for Wave 3 stayed narrow to the canonical app brief, assistant bridge, user guides, and the repeated issue-memory entry for fresh-worktree lockfile churn.

## Handoff
- Wave 3 should end with:
  - one shared, advice-only recommendation layer
  - the same coaching message shape in `Today` and `My Plan`
  - explicit wording that real completed practice/review/delayed-check work counts, while merely opening a screen does not
  - no schema or route changes
- Current state:
  - merged to `main` via PR #29 after narrow docs sync and issue-memory refresh
  - validations passed before publish:
    - `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
    - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
    - `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
    - `flutter analyze --no-fatal-infos --no-fatal-warnings`
    - `dart tooling/validate_localization.dart`
    - `dart tooling/validate_agent_docs.dart`
    - `dart tooling/validate_workspace_hygiene.dart`
- Follow-up risk:
  - if the progress signal cannot honestly distinguish a coaching branch, the recommendation should fall back to a safer broader option rather than inventing precision.
  - Wave 4 should keep the same honesty rule while aligning the goal/progress language across surfaces.
