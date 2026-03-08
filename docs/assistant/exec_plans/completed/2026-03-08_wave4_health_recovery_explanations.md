# ExecPlan: Wave 4 Plan Health, Recovery, and Explanation Layer

## Purpose
- Turn the current planner outputs into a clearer learner-facing contract before Wave 5 changes the scheduler itself.
- Help a solo learner understand whether the plan is healthy, what to do after missed sessions, and what the safest minimum day looks like.

## Scope
- In scope:
  - plan health states: `on_track`, `tight`, `overloaded`
  - recovery recommendations tied to current planner outputs
  - missed-session recovery wizard
  - minimum viable day mode in UI copy and flow
  - daily explanation packet surfaced in the UI
  - backlog burn-down framing in user-facing language
- Out of scope:
  - scheduler V2 replacement
  - forecast rewrite
  - calibration redesign
  - schema or persistence-contract changes
  - adaptive behavior

## Assumptions
- All research stages are complete; implementation continues by wave.
- Wave 3 is merged and its preset-first `My Plan` contract is now the baseline.
- Wave 4 must stay on the current planner outputs and data model so Wave 5 can later replace allocation logic without losing the user-facing contract.
- `Today` and `My Plan` are the primary surfaces for Wave 4 user-facing changes.

## Milestones
1. Define the Wave 4 user-facing contract on top of current planner outputs.
2. Implement plan health, recovery entry points, minimum-day framing, and explanation UI.
3. Add focused tests, sync any stale docs, and prepare the branch for publish.

## Detailed Steps
1. Review current `Today` and `My Plan` code paths to identify the best integration points for:
   - health-state calculation/presentation
   - recovery recommendations
   - minimum-day guidance
   - explanation packets
2. Add lightweight planner-facing helpers or view models that derive:
   - plan health
   - recovery posture
   - backlog burn-down framing
   from the current planner state without altering scheduler persistence or schema.
3. Update `lib/screens/today_screen.dart` so learners can:
   - see current plan health
   - understand why the day is shaped the way it is
   - open a recovery path when they miss work
   - choose a minimum viable day path when time is short
4. Update `lib/screens/plan_screen.dart` so `My Plan` can:
   - explain recovery posture clearly
   - frame overload and burn-down behavior in plain language
   - stay consistent with Wave 3 preset-first flow
5. Add or update targeted tests for:
   - health classification visibility
   - recovery entry points
   - minimum-day UI
   - explanation text presence and fallback behavior
6. If behavior docs become stale, run a narrow Assistant Docs Sync limited to touched planner/today support docs.

## Decision Log
- 2026-03-08: Wave 4 should establish the learner-facing contract before Wave 5 changes the scheduler internals.
- 2026-03-08: Health, recovery, and explanation work must reuse the current data model first so the wave stays low risk.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/planner_feedback_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter test -j 1 -r expanded test/l10n/app_strings_test.dart`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Create the Wave 4 branch/worktree and mark it active in the master tracker
- [x] Create this Wave 4 ExecPlan
- [x] Implement Wave 4 user-facing health/recovery/explanation changes
- [x] Validate the branch and prepare the publish path

## Surprises and Adjustments
- Use this section for Wave 4 detours, especially if the current planner outputs are insufficient and a smaller bridge helper is needed before Wave 5.
- A small pure helper (`planner_feedback.dart`) was enough to classify health/recovery state without touching persistence or scheduler internals.
- The recovery wizard stayed UI-only and routes learners toward minimum-day execution or `My Plan` adjustments instead of mutating planner settings automatically.
- Flutter validation should keep running sequentially in this worktree because parallel Flutter commands previously caused false failures in the same build directory.

## Handoff
- Wave 4 is active on `feat/planner-wave4-health-explanations` in `/home/fa507/dev/hifz_planner_wave4`.
- Wave 4 user-facing health, recovery, minimum-day, and explanation changes are implemented locally, validated, and docs-synced.
- The next branch step is commit/PR closeout for Wave 4.
- All research stages are complete; implementation continues by wave.
- Next step: close Wave 4 with commit, PR, and merge
