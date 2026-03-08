# ExecPlan: Wave 5 Scheduler and Daily Allocation V2

## Purpose
- Replace the current allocation behavior with the Stage 4 deterministic scheduler policy.
- Make `Today` and Forecast depend on the same explainable allocation rules instead of separate behavior paths.

## Scope
- In scope:
  - deterministic stress computation
  - learner-mode-aware daily allocation
  - shared policy path for Today and Forecast
  - explicit new-work gating and fallback-plan outputs
  - scenario-driven regression coverage for missed sessions, heavy review, and Stage-4 pressure
- Out of scope:
  - adaptive scheduling
  - schema or persistence-contract changes unless a smaller compatibility bridge is unavoidable
  - calibration redesign
  - forecast UX redesign beyond what the scheduler contract forces

## Assumptions
- All research stages are complete; implementation continues by wave.
- Wave 4 is merged, so the learner-facing contract for health, recovery, minimum-day guidance, and explanation text is already live.
- Wave 5 must satisfy the Stage 4 scheduler spec first, not invent a new planner contract.
- The safest path is to reuse the current planning data model and only replace allocation logic where needed.

## Milestones
1. Map the current planner pipeline to the Stage 4 deterministic policy.
2. Implement shared stress and daily-allocation logic with minimal contract churn.
3. Update Today/Forecast integration and add deterministic scenario tests.

## Detailed Steps
1. Audit the current planning pipeline:
   - `lib/data/services/daily_planner.dart`
   - `lib/data/services/spaced_repetition_scheduler.dart`
   - `lib/data/services/forecast_simulation_service.dart`
   - `lib/data/services/scheduling/daily_content_allocator.dart`
   - `lib/data/services/scheduling/weekly_plan_generator.dart`
2. Identify which existing services can host:
   - weighted stress computation
   - learner mode resolution
   - daily allocation passes
   - minimum viable new-work threshold
   - shared explanation outputs
3. Implement the deterministic Wave 5 allocation path so it follows the Stage 4 priority order:
   - mandatory Stage-4 due first
   - critical review second
   - sustainable new memorization last
4. Ensure Today and Forecast read from the same policy decisions wherever the current data model allows.
5. Add scenario-driven tests for:
   - one missed session
   - several missed days
   - Stage-4 pressure blocking new work
   - high review pressure reducing new work
   - low-pressure days preserving sustainable new work
6. If the implementation reveals a better sequence or a required compatibility bridge:
   - update this ExecPlan first
   - update `docs/assistant/exec_plans/active/2026-03-08_product_redesign_execution.md` second
   - then continue

## Decision Log
- 2026-03-08: Wave 5 starts only after Wave 4 so the algorithm can target a fixed user-facing contract.
- 2026-03-08: Prefer deterministic shared policy outputs over deeper architecture reshaping in the first pass.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `flutter test -j 1 -r expanded test/data/services/spaced_repetition_scheduler_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Create the Wave 5 branch/worktree and mark it active in the master tracker
- [x] Create this Wave 5 ExecPlan
- [ ] Audit the current scheduler/allocation pipeline against the Stage 4 spec
- [ ] Implement the deterministic allocation replacement
- [ ] Validate the branch and prepare the publish path

## Surprises and Adjustments
- Use this section for any mismatch between the current data model and the Stage 4 scheduler contract.

## Handoff
- Wave 5 is active on `feat/planner-wave5-scheduler-v2` in `/home/fa507/dev/hifz_planner_wave5`.
- No runtime implementation has landed yet on this branch; this startup commit exists to preserve the exact next stream and validation targets.
- All research stages are complete; implementation continues by wave.
- Next step: Wave 5 - Scheduler and Daily Allocation V2
