# ExecPlan: Stage 5 Implementation Roadmap and Validation System

## Purpose
- Convert the approved Stage 1-4 research/spec outputs into a sequenced delivery roadmap and a concrete validation system.
- Make the next implementation phase low-risk, testable, and easy to split across branches.

## Scope
- In scope:
  - implementation waves
  - branch/worktree strategy
  - validation layers and test categories
  - dependency policy
  - acceptance gates between waves
- Out of scope:
  - runtime implementation
  - schema changes
  - PR/merge execution
  - release planning

## Assumptions
- Stage 1 through Stage 4 outputs are accepted inputs.
- The next implementation phase should preserve current app behavior wherever possible until each targeted wave is ready.
- The WSL Flutter environment may still block full local Flutter test execution and should be treated as an environment constraint, not as product truth.

## Milestones
1. Consolidate the approved outputs into implementation waves.
2. Define the validation system and wave gates.
3. Produce the Stage 5 roadmap artifact and validate docs.

## Detailed Steps
1. Review:
   - `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`
   - `docs/assistant/research/STAGE2_NON_CODER_UX_AND_JOURNEY_REDESIGN.md`
   - `docs/assistant/research/STAGE3_PLANNER_PRODUCT_REDESIGN.md`
   - `docs/assistant/research/STAGE4_SCHEDULER_AND_ALGORITHM_V2_SPEC.md`
2. Define implementation waves in value/risk order.
3. Define validation layers:
   - product scenarios
   - targeted tests
   - algorithm simulation/regression
   - usability walkthroughs
   - mobile suitability review
4. Write Stage 5 deliverable:
   - `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md`
5. Validate with:
   - `dart tooling/validate_agent_docs.dart`

## Decision Log
- 2026-03-08: Kept the roadmap wave-based instead of milestone-by-screen so work can land incrementally without forcing a giant UI + algorithm rewrite.
- 2026-03-08: Deferred optional adaptive scheduling to a final follow-up wave because deterministic behavior must be validated first.

## Validation
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Consolidate approved outputs into implementation waves
- [x] Define validation system and wave gates
- [x] Write Stage 5 roadmap artifact
- [x] Validate docs

## Surprises and Adjustments
- The best delivery order is not “Planner first.” The safer order is copy/IA, then Today coaching, then preset-first planning, then algorithm replacement.
- The current repo already has enough targeted test coverage to support wave-by-wave validation once the local Flutter toolchain is repaired or CI is used consistently.

## Handoff
- Stage 5 should end with a sequenced implementation roadmap and validation suite definition.
- This completes the staged research/spec program and should be followed by a new implementation branch strategy, not by mixing implementation into this research worktree.
