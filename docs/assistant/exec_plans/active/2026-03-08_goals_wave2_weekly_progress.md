# ExecPlan: Goals Wave 2 - Weekly Progress and Trust Layer

## Purpose
- Add a simple recent-progress snapshot that helps the learner trust what the app is saying about consistency and retention.
- Reuse existing local planner, review, and practice data instead of creating a new progress system.
- Keep the experience calm, supportive, and count-based rather than time-based or gamified.

## Scope
- In scope:
  - one shared progress snapshot service extension for recent 7-day counts
  - integrated recent-progress cards in `Today` and `My Plan`
  - a simple recent-quality band derived from review grades
  - focused tests and tracker updates
- Out of scope:
  - goal-coaching recommendations
  - schema or route changes
  - badges, streaks, trophies, or reward mechanics
  - duration-based progress metrics

## Assumptions
- Existing persisted sources are enough for a first trust layer:
  - planner posture
  - review logs
  - current practice completion signals
  - delayed-check/review/new-work records already stored locally
- Count-based recent progress is more honest than duration because session minutes are not consistently recorded.
- The same shared snapshot should feed both `Today` and `My Plan`.

## Milestones
1. Extend the shared progress snapshot layer with recent 7-day metrics.
2. Add a short weekly consistency summary to `Today`.
3. Add a fuller last-7-day summary to `My Plan`.
4. Add focused service and widget tests for no-history, steady, retention-heavy, and overloaded learners.

## Detailed Steps
1. Extend `goal_progress_snapshot_service.dart` to compute:
   - completed practice days in the last 7 days
   - completed delayed checks in the last 7 days
   - completed reviews in the last 7 days
   - completed new-practice completions in the last 7 days
   - a simple recent-quality band derived from review grades
2. Reuse existing repositories/providers instead of introducing schema changes.
3. Add a lightweight weekly consistency card to `Today`.
4. Add a fuller last-7-day progress card to `My Plan`.
5. Keep language calm and literal:
   - no streak-loss framing
   - no vanity totals
   - no duration-minute claims if the data is not reliable
6. Validate with focused service tests and widget tests.

## Decision Log
- 2026-03-08: Keep Wave 2 count-based first; drop any metric that would require unreliable duration data.
- 2026-03-08: Use the existing goal snapshot layer from Wave 1 instead of creating a parallel progress model.
- 2026-03-08: Keep this wave supportive and trust-building, not motivational-gamification driven.

## Validation
- `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Start Wave 2 ExecPlan and tracker update
- [x] Extend shared progress snapshot with recent 7-day metrics
- [x] Integrate Today weekly consistency summary
- [x] Integrate My Plan recent-progress summary
- [x] Run focused validation

## Surprises and Adjustments
- 2026-03-08: Existing persisted data does not separate new-vs-review non-stage4 practice sessions, so the shared snapshot uses a best-effort non-stage4 practice completion count instead of inventing a schema change mid-roadmap.
- 2026-03-08: Sequential Flutter test runs remained the reliable validation path in this worktree; dependency resolution ran automatically on the first test invocation, then the full Wave 2 validation set passed cleanly.
- 2026-03-08: Repeatable local validation issues from this wave were promoted into `docs/assistant/ISSUE_MEMORY.md` and `docs/assistant/ISSUE_MEMORY.json` so future restarts keep the sequential Flutter-test rule and the incidental lockfile-churn cleanup rule.

## Handoff
- Wave 2 should end with:
  - one shared recent-progress snapshot feeding both `Today` and `My Plan`
  - calm weekly consistency messaging
  - simple recent-quality guidance derived from existing review data
  - no schema changes and no new top-level navigation
- Current state:
  - implemented locally on `feat/goals-wave2-weekly-progress`
  - validations passed:
    - `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
    - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
    - `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
    - `flutter analyze --no-fatal-infos --no-fatal-warnings`
    - `dart tooling/validate_localization.dart`
    - `dart tooling/validate_agent_docs.dart`
    - `dart tooling/validate_workspace_hygiene.dart`
- Follow-up risk:
  - if one of the intended recent-progress metrics cannot be derived honestly from existing local data, it should be removed instead of forcing a migration.
  - next closeout step is commit, PR, and merge.
