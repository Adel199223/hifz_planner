# ExecPlan: Product Redesign Execution Tracker

## Purpose
- Keep the Stage 1-5 research roadmap durable inside the repo.
- Track the live execution order for implementation waves and detours.
- Provide one file to return to after interruptions or side-task branches.

## Scope
- In scope:
  - Wave 1 through Wave 7 status tracking
  - Branch and worktree mapping
  - Current blockers
  - Detours and plan updates
  - Next recommended action
  - Links to the Stage 1-5 research specs
- Out of scope:
  - Detailed feature implementation steps for each wave
  - Replacing wave-specific ExecPlans

## Assumptions
- Stage 1-5 research docs are the locked strategic input unless this tracker records a newer decision.
- Wave 1 should merge before the critical-fix port because both touch Reader and app docs.
- The existing `feat/audit-critical-fixes` branch is a reference source, not the branch that should be merged.
- Each major wave or port stream gets its own isolated branch and worktree.

## Milestones
1. Publish the Stage 1-5 roadmap docs.
2. Merge Wave 1.
3. Port and merge post-Wave1 critical fixes.
4. Start and complete Wave 2.
5. Resume the roadmap from Wave 3.

## Detailed Steps
1. Publish the research docs from `feat/stage1-product-audit`.
2. Sync this tracker into the active Wave 1 branch and update its status before PR.
3. Merge Wave 1 to `main`, then update this tracker on `main`.
4. Create a fresh `feat/stability-post-wave1-critical-fixes` branch from updated `main`.
5. Port only the approved runtime/test fixes from `feat/audit-critical-fixes`.
6. Merge the post-Wave1 stability branch, then archive or delete the stale dirty audit branch.
7. Create `feat/ux-wave2-today-coaching` from updated `main`.
8. Keep Wave 2 limited to Today-as-coach UX work, then update this tracker when scope or sequence changes.

## Decision Log
- 2026-03-08: Preserve the Stage 1-5 roadmap in-repo before more feature merges so implementation can restart from repo state alone.
- 2026-03-08: Use this file as the long-lived tracker for detours, blockers, and resumed roadmap order.
- 2026-03-08: Merge Wave 1 before the critical-fix port to avoid carrying overlapping dirty branch state into the new app-shell baseline.
- 2026-03-08: Port only the real runtime/test fixes from `feat/audit-critical-fixes`; do not merge its unrelated template/local-env churn.

## Validation
- `dart tooling/validate_agent_docs.dart`
- For each active branch, run the wave-specific tests listed in its ExecPlan before PR.

## Progress
- [x] Publish Stage 1-5 roadmap docs
- [x] Merge Wave 1
- [ ] Merge post-Wave1 critical fixes
- [ ] Start Wave 2
- [ ] Merge Wave 2
- [ ] Resume roadmap from Wave 3

## Surprises and Adjustments
- Use this section for new sequence changes, blockers, or scope corrections discovered during implementation.

## Handoff
- Current roadmap order and links:
  - Wave 1: Navigation and Copy Simplification
    - Spec: `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md#wave-1-navigation-and-copy-simplification`
  - Wave 2: Today as Coaching Home
    - Spec: `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md#wave-2-today-as-coaching-home`
  - Wave 3: My Plan Preset-First Flow
    - Spec: `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md#wave-3-my-plan-preset-first-flow`
  - Wave 4: Plan Health, Recovery, and Explanation Layer
    - Spec: `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md#wave-4-plan-health-recovery-and-explanation-layer`
  - Wave 5: Scheduler and Daily Allocation V2
    - Spec: `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md#wave-5-scheduler-and-daily-allocation-v2`
  - Wave 6: Forecast and Calibration Refinement
    - Spec: `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md#wave-6-forecast-and-calibration-refinement`
  - Wave 7: Optional Adaptive Follow-Up
    - Spec: `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md#wave-7-optional-adaptive-follow-up`
- Research doc set:
  - `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`
  - `docs/assistant/research/STAGE2_NON_CODER_UX_AND_JOURNEY_REDESIGN.md`
  - `docs/assistant/research/STAGE3_PLANNER_PRODUCT_REDESIGN.md`
  - `docs/assistant/research/STAGE4_SCHEDULER_AND_ALGORITHM_V2_SPEC.md`
  - `docs/assistant/research/STAGE5_IMPLEMENTATION_ROADMAP_AND_VALIDATION_SYSTEM.md`
- Wave status:

| Stream | Status | Branch | Worktree | Notes |
|---|---|---|---|---|
| Stage 1-5 roadmap publication | merged | `feat/stage1-product-audit` | `/home/fa507/dev/hifz_planner_stage1` | Merged to `main` as PR #3 |
| Wave 1 | merged | `feat/ux-wave1-navigation-copy` | `/home/fa507/dev/hifz_planner_wave1` | Merged to `main` as PR #4 |
| Post-Wave1 critical fixes | active | `feat/stability-post-wave1-critical-fixes` | `/home/fa507/dev/hifz_planner_stability` | Porting only approved runtime/test fixes from the dirty audit branch |
| Wave 2 | planned | `feat/ux-wave2-today-coaching` | not created yet | Starts after Wave 1 and stability port merge |
| Wave 3 | planned | `feat/ux-wave3-my-plan-preset-flow` | not created yet | Resume after Wave 2 |
| Wave 4 | planned | `feat/planner-wave4-health-explanations` | not created yet | Depends on Wave 3 contract |
| Wave 5 | planned | `feat/planner-wave5-scheduler-v2` | not created yet | Deterministic allocation replacement |
| Wave 6 | planned | `feat/planner-wave6-forecast-calibration-refine` | not created yet | Post-scheduler refinement |
| Wave 7 | planned | `feat/planner-wave7-optional-adaptive-followup` | not created yet | Optional only |

- Current blockers:
  - Wave 1 and the dirty audit branch overlap in Reader and docs files; they must not be merged together.
  - The critical fixes need a clean post-Wave1 branch so only the approved runtime/test changes move forward.
- Detours and plan updates:
  - 2026-03-08: Research/spec work completed before broader implementation. Preserve it before merging app code branches.
  - 2026-03-08: Roadmap publication finished first so the execution tracker exists on `main` before Wave 1 closes.
  - 2026-03-08: Wave 1 merged cleanly after syncing the tracker/research docs from `main`.
- Next recommended action:
  - Finish the clean post-Wave1 critical-fix port, then branch from updated `main` for Wave 2.
