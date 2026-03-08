# ExecPlan: Stage 4 Scheduler and Algorithm V2 Spec

## Purpose
- Define an interpretable, deterministic planner/scheduler V2 that matches the Stage 3 planner product redesign.
- Produce a spec that can guide later implementation and validation without changing runtime code yet.

## Scope
- In scope:
  - objective priorities
  - capacity model
  - daily allocation policy
  - missed-session recovery policy
  - calibration and forecast contracts
  - explainability requirements
  - pseudocode, scenario table, data contracts, migration notes
- Out of scope:
  - runtime implementation
  - schema migration execution
  - UI implementation
  - adaptive/ML-based scheduling

## Assumptions
- Stage 1, Stage 2, and Stage 3 outputs are accepted inputs.
- The first algorithm version should reuse as much of the current data model as possible.
- Deterministic and auditable behavior is more important than theoretical optimality in this phase.

## Milestones
1. Reconfirm current scheduling data and allocation logic.
2. Define the V2 deterministic policy and explainability contract.
3. Produce the implementation-ready Stage 4 algorithm spec and validate docs.

## Detailed Steps
1. Review:
   - `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`
   - `docs/assistant/research/STAGE2_NON_CODER_UX_AND_JOURNEY_REDESIGN.md`
   - `docs/assistant/research/STAGE3_PLANNER_PRODUCT_REDESIGN.md`
   - `docs/assistant/features/PLANNER_USER_GUIDE.md`
2. Reconfirm current algorithm/data files:
   - `lib/data/services/daily_planner.dart`
   - `lib/data/services/spaced_repetition_scheduler.dart`
   - `lib/data/services/forecast_simulation_service.dart`
   - `lib/data/services/calibration_service.dart`
   - `lib/data/services/scheduling/planning_projection_engine.dart`
   - `lib/data/services/scheduling/daily_content_allocator.dart`
   - `lib/data/services/scheduling/weekly_plan_generator.dart`
   - `lib/data/services/scheduling/scheduling_preferences_codec.dart`
   - `lib/data/repositories/schedule_repo.dart`
   - `lib/data/database/app_database.dart`
3. Reconfirm external evidence from:
   - Anki docs / FSRS workload-retention framing
   - SuperMemo algorithm reference
   - learning-science research on retrieval practice, spacing, and successive relearning
4. Write Stage 4 deliverable:
   - `docs/assistant/research/STAGE4_SCHEDULER_AND_ALGORITHM_V2_SPEC.md`
5. Validate with:
   - `dart tooling/validate_agent_docs.dart`

## Decision Log
- 2026-03-08: Chose a heuristic-first deterministic scheduler rather than jumping to adaptive or ML-driven scheduling.
- 2026-03-08: Constrained the V2 design to current repo data where possible so implementation can be phased without immediate schema churn.

## Validation
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Reconfirm current scheduling data and allocation logic
- [x] Define the V2 deterministic policy and explainability contract
- [x] Write Stage 4 algorithm spec
- [x] Validate docs

## Surprises and Adjustments
- The current repo already has enough scheduling primitives to support a significantly better planner product without inventing a new data layer first.
- The biggest hard limit is not scheduling math; it is the lack of explicit persisted session-adherence data for automatic missed-session inference.

## Handoff
- Stage 4 should end with an algorithm spec, scenario table, pseudocode, required data contracts, and migration/risk notes.
- Stop after Stage 4 and ask whether to proceed to Stage 5 implementation roadmap and validation system.
