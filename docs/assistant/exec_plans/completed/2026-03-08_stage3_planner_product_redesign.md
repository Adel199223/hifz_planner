# ExecPlan: Stage 3 Planner Product Redesign

## Purpose
- Redefine the planner as a learner-facing coaching system rather than a raw settings/control surface.
- Produce an implementation-ready product spec that can guide later UX and algorithm work.

## Scope
- In scope:
  - planner product goals and tradeoff rules
  - plain-language learner behavior model
  - preset strategy and recovery modes
  - feature additions, removals, and hiding decisions
  - implementation-ready acceptance criteria
- Out of scope:
  - scheduler algorithm pseudocode
  - runtime UI implementation
  - DB/schema changes
  - teacher/classroom workflows

## Assumptions
- Stage 1 and Stage 2 conclusions are accepted inputs.
- `Today` is the primary execution surface and `My Plan` becomes a guided setup/adjustment surface.
- The first planner redesign should stay interpretable and beginner-friendly.

## Milestones
1. Reconfirm current planner promises and current exposed controls.
2. Define the new planner product model in plain language.
3. Produce the implementation-ready Stage 3 planner spec and validate docs.

## Detailed Steps
1. Review:
   - `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`
   - `docs/assistant/research/STAGE2_NON_CODER_UX_AND_JOURNEY_REDESIGN.md`
   - `docs/assistant/features/PLANNER_USER_GUIDE.md`
   - `docs/assistant/workflows/PLANNER_WORKFLOW.md`
   - `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`
2. Reconfirm current planner concepts in:
   - `lib/screens/plan_screen.dart`
   - `lib/screens/today_screen.dart`
   - `lib/data/services/daily_planner.dart`
   - `lib/data/services/scheduling/planning_projection_engine.dart`
3. Write Stage 3 deliverable:
   - `docs/assistant/research/STAGE3_PLANNER_PRODUCT_REDESIGN.md`
4. Validate with:
   - `dart tooling/validate_agent_docs.dart`

## Decision Log
- 2026-03-08: Kept Stage 3 as a spec-only step so the product behavior is locked before algorithm redesign begins.
- 2026-03-08: Separated this planner product redesign from the existing hidden-recall Stage 3 research docs because they cover different concerns.

## Validation
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Reconfirm current planner promises and exposed controls
- [x] Define the new planner product model in plain language
- [x] Write Stage 3 planner spec
- [x] Validate docs

## Surprises and Adjustments
- Current planner already contains many concepts that should survive in the engine, but most of them should no longer be first-run user decisions.
- The strongest redesign opportunity is not additional complexity; it is converting existing planner power into safer defaults and clearer recovery behavior.

## Handoff
- Stage 3 should end with a full planner product spec, plain-language user behavior model, feature additions/removals/hiding decisions, and acceptance criteria.
- Stop after Stage 3 and ask whether to proceed to Stage 4 scheduler and algorithm V2 spec.
