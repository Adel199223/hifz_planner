# ExecPlan: Wave 7 Optional Adaptive Follow-Up

## Purpose
- Explore whether the deterministic planner can gain small adaptive improvements without weakening explainability.
- Keep Wave 7 explicitly optional and evidence-driven instead of turning the planner into an opaque system.

## Scope
- In scope:
  - audit the current deterministic planner outputs and calibration data for safe adaptive hooks
  - identify low-risk adaptive ideas such as pace nudging, uncertainty handling, or richer stability estimation
  - prototype only the smallest adaptive refinement that remains explainable and testable
  - add regression coverage for any adaptive behavior that is accepted
- Out of scope:
  - opaque models or black-box ranking
  - schema changes unless a tiny compatibility bridge is unavoidable
  - replacing the deterministic Wave 5/6 planner contract
  - broad UX redesign outside what an accepted adaptive refinement requires

## Assumptions
- All research stages are complete; implementation continues by wave.
- Wave 6 is merged, so forecast, calibration, and deterministic planning are already aligned on one shared rule system.
- Adaptive behavior is only acceptable if it remains auditable, reversible, and easy to explain in plain language.
- The safest first step is to audit and prove value before changing live planner behavior.

## Milestones
1. Audit current planner/calibration signals for adaptive opportunities that do not weaken explainability.
2. Choose one narrow adaptive refinement or decide that no adaptive refinement is justified yet.
3. Implement and validate only if the chosen refinement stays deterministic enough to explain and test clearly.

## Detailed Steps
1. Audit the current Wave 7 surface:
   - `lib/data/services/daily_planner.dart`
   - `lib/data/services/forecast_simulation_service.dart`
   - `lib/data/services/calibration_service.dart`
   - `lib/data/services/scheduling/daily_content_allocator.dart`
   - `lib/data/services/scheduling/planner_quality_signal.dart`
2. Identify candidate adaptive inputs that are already available without schema changes:
   - calibration samples
   - grade-distribution trends
   - forecast confidence state
   - repeated overload or review-pressure signals
3. Reject any candidate that:
   - creates an opaque score the learner cannot understand
   - makes forecast and Today diverge
   - needs large persistence changes
4. If a safe candidate survives, prototype the narrowest version first and add targeted tests for:
   - determinism
   - explainability
   - no regression of Wave 5/6 planner behavior under neutral conditions
5. If the best outcome is `do not adapt yet`, record that explicitly in this ExecPlan and the tracker instead of forcing a change.
6. If implementation reveals a better sequence or a blocker:
   - update this ExecPlan first
   - update `docs/assistant/exec_plans/active/2026-03-08_product_redesign_execution.md` second
   - then continue

## Decision Log
- 2026-03-08: Wave 7 starts only after Wave 6 so adaptive follow-up is evaluated against a stable deterministic planner.
- 2026-03-08: The default stance is skepticism: adaptive behavior must earn its place by staying explainable and low-risk.
- 2026-03-08: Wave 7 may legitimately conclude that the best result is to keep the deterministic planner unchanged for now.
- 2026-03-08: The accepted Wave 7 refinement is a bounded pace-trend signal from recent calibration samples, merged into the existing deterministic planner instead of creating a separate adaptive rule path.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `flutter test -j 1 -r expanded test/data/services/forecast_simulation_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Create the Wave 7 branch/worktree and mark it active in the master tracker
- [x] Create this Wave 7 ExecPlan
- [x] Audit the current planner/calibration path for safe adaptive opportunities
- [x] Decide whether a Wave 7 adaptive refinement is justified
- [x] Implement and validate only the accepted adaptive refinement, if any

## Surprises and Adjustments
- Use this section for any evidence that Wave 7 should stay exploratory or stop without shipping adaptive behavior.
- `flutter test` refreshed `pubspec.lock` during the first validation pass; that incidental lockfile churn was restored before keeping the branch active.

## Handoff
- Wave 7 shipped on `feat/planner-wave7-optional-adaptive-followup` and merged to `main` as PR #16.
- The delivered refinement is intentionally narrow: recent calibration pace can nudge the shared planner slightly slower or faster, and the forecast UI explains that pace trend in plain language.
- All research stages are complete; implementation continues by wave.
- Next step: define the next backlog or roadmap after the completed Wave 1-7 program
