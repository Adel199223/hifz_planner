# ExecPlan: Goals Wave 1 - Goal Framing and Daily Wins

## Purpose
- Add calm, supportive goal framing to `Today` and `My Plan` without adding a new settings flow.
- Help the learner understand what a good day looks like right now.
- Introduce a shared read-only goal snapshot layer that later waves can extend with recent progress data.

## Scope
- In scope:
  - a shared `goal focus` model with exactly three learner-facing states
  - one internal read-only snapshot service reused by `Today` and `My Plan`
  - a small daily-win block in `Today`
  - a lightweight weekly goal summary in `My Plan`
  - focused tests and roadmap tracker updates
- Out of scope:
  - weekly recent-progress counts
  - coaching recommendations that tell the learner to change the plan
  - schema or route changes
  - new top-level navigation

## Assumptions
- Current planner feedback already provides enough signal to derive a first-wave goal focus.
- `Today` should tell the learner what counts as a good day right now.
- `My Plan` should summarize weekly posture without adding new configuration steps.
- Recent-history counts will arrive in Wave 2 on top of the same shared snapshot layer.

## Milestones
1. Add the new Goals + Progress roadmap tracker and start Wave 1 on an isolated branch.
2. Add the shared goal snapshot service and provider.
3. Integrate a small daily-win goal block into `Today`.
4. Integrate a weekly goal summary card into `My Plan`.
5. Validate the new goal framing with focused service and widget tests.

## Detailed Steps
1. Add the roadmap tracker at `docs/assistant/exec_plans/active/2026-03-08_goals_progress_execution.md`.
2. Add `lib/data/services/goal_progress_snapshot_service.dart` with:
   - `GoalFocus`
   - `GoalProgressSnapshot`
   - `GoalProgressSnapshotService`
3. Add a provider for the new service in `lib/data/providers/database_providers.dart`.
4. Update `lib/screens/today_screen.dart` to show a progress block that explains:
   - this week's goal
   - what counts as a good day today
   - how today's main task supports that goal
   - what still counts on a short day
5. Update `lib/screens/plan_screen.dart` to show a lightweight weekly goal summary tied to current plan posture.
6. Add learner-facing strings in `lib/l10n/app_strings.dart`.
7. Add focused tests in:
   - `test/data/services/goal_progress_snapshot_service_test.dart`
   - `test/screens/today_screen_test.dart`
   - `test/screens/plan_screen_test.dart`

## Decision Log
- 2026-03-08: Use planner posture first for Wave 1 instead of waiting for richer recent-progress history.
- 2026-03-08: Keep the first snapshot model read-only and extensible so Wave 2 can add recent 7-day counts without redesigning the interface.
- 2026-03-08: Prefer reassuring language like `done enough` and `good day` over performance framing.

## Validation
- `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Add roadmap tracker and Wave 1 ExecPlan
- [x] Add shared goal snapshot service/provider
- [x] Integrate Today daily-win block
- [x] Integrate My Plan weekly goal summary
- [x] Run focused validation

## Surprises and Adjustments
- Running multiple `flutter test` commands in parallel in the same worktree triggered a Flutter plugin-symlink crash in `windows/flutter/ephemeral/.plugin_symlinks/`.
- The implementation itself was not blocked; rerunning the Wave 1 checks sequentially avoided the tool crash and produced a clean validation result.

## Handoff
- Wave 1 should end with:
  - one shared goal-focus layer reused by `Today` and `My Plan`
  - a calm daily-win explanation in `Today`
  - a lightweight weekly goal summary in `My Plan`
  - no new route, schema, or top-level navigation changes
- Current state:
  - implemented, docs-synced, and validated locally on `feat/goals-wave1-daily-wins`
- Validation run:
  - `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
  - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
  - `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
  - `dart tooling/validate_workspace_hygiene.dart`
- Follow-up risk:
  - recent-history counts are still missing until Wave 2, so Wave 1 should avoid pretending it has a full consistency view.
