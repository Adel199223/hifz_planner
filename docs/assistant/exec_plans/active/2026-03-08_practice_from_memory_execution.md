# ExecPlan: Practice From Memory Execution Tracker

## Purpose
- Keep the new Practice from Memory roadmap durable inside the repo.
- Track the live execution order for the four practice-focused waves.
- Provide one file to return to after interruptions, bugfix detours, or publish steps.

## Scope
- In scope:
  - Wave 1 through Wave 4 status tracking
  - Branch and worktree mapping
  - Current blockers
  - Detours and plan updates
  - Next recommended action
  - Links to the existing supporting research/spec docs
- Out of scope:
  - Detailed implementation steps for each wave
  - Replacing wave-specific ExecPlans

## Assumptions
- The previous Wave 1-7 product redesign roadmap is complete and remains historical context only.
- This is a new roadmap focused on easier daily memorization practice for solo learners.
- Internal route and launch-mode compatibility must remain stable:
  - `/companion/chain`
  - `mode=new|review|stage4`
- Persistence and schema stay unchanged unless a later wave proves that unavoidable.

## Milestones
1. Start and complete Wave 1 entry and naming simplification.
2. Start and complete Wave 2 core practice screen simplification.
3. Start and complete Wave 3 hidden recall runtime completion.
4. Start and complete Wave 4 daily practice modes and integration.
5. Close the roadmap and define the next backlog.

## Detailed Steps
1. Start Wave 1 on an isolated worktree and add a wave-specific ExecPlan.
2. Reframe learner-facing entry language from `Companion` toward `Practice from Memory` without changing the internal route contract.
3. Update `Today`, `Learn`, and the visible launch points to expose clear actions for:
   - new practice
   - review practice
   - delayed check
4. Keep Wave 2 focused on task-first practice screen wording and reduced visible jargon.
5. Use `docs/assistant/research/STAGE3_HIDDEN_RECALL_DESIGN_SPEC.md` as the Wave 3 contract.
6. Finish Wave 4 by making the daily practice modes feel clear from `Today` and `Learn`, then close the roadmap.

## Decision Log
- 2026-03-08: Start a new roadmap instead of extending the completed Wave 1-7 planner roadmap.
- 2026-03-08: Keep the practice roadmap manual and deterministic; do not add microphone, voice-aware checking, or AI recitation analysis.
- 2026-03-08: Keep schema and route compatibility stable so the new practice roadmap can ship incrementally without data migration risk.

## Validation
- For each active wave, run the focused screen/service tests listed in that wave's ExecPlan.
- Run `dart tooling/validate_agent_docs.dart` after tracker or ExecPlan updates.
- Run `dart tooling/validate_localization.dart` when Wave 1 or Wave 2 changes user-facing wording.

## Progress
- [x] Start Wave 1
- [x] Merge Wave 1
- [x] Start Wave 2
- [x] Merge Wave 2
- [x] Start Wave 3
- [x] Merge Wave 3
- [x] Start Wave 4
- [ ] Merge Wave 4
- [ ] Close the roadmap

## Surprises and Adjustments
- Use this section for new sequence changes, blockers, or scope corrections discovered during implementation.

## Roadmap Return Protocol

- After every substantial closeout, explicitly report:
  - current roadmap status
  - exact next step by wave or stage name
- When research stages are already complete, say exactly:
  - `All research stages are complete; implementation continues by wave.`
- After any detour for bugfixes, tooling, docs, or environment:
  1. update the active wave ExecPlan first
  2. update this tracker second
  3. resume from this tracker unless it records a new sequence
- Every roadmap closeout message must end with:
  - `Next step: Wave X - <name>`
- If the next action is closeout instead of a new wave, end with:
  - `Next step: close Wave X with <closeout action>`

## Handoff
- Roadmap order and supporting references:
  - Wave 1: Practice Entry and Naming Simplification
  - Wave 2: Core Practice Screen Simplification
  - Wave 3: Hidden Recall Runtime Completion
    - Spec: `docs/assistant/research/STAGE3_HIDDEN_RECALL_DESIGN_SPEC.md`
  - Wave 4: Daily Practice Modes and Integration
- Related context:
  - `APP_KNOWLEDGE.md`
  - `docs/assistant/features/APP_USER_GUIDE.md`
  - `docs/assistant/features/PLANNER_USER_GUIDE.md`
  - `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`
- Wave status:

| Stream | Status | Branch | Worktree | Notes |
|---|---|---|---|---|
| Previous planner roadmap | merged | historical | removed | Wave 1-7 completed before this roadmap started |
| Practice Wave 1 | merged | `feat/practice-wave1-entry-language` | removed | Merged to `main` as PR #18; plan archived by PR #19 |
| Practice Wave 2 | merged | `feat/practice-wave2-screen-simplification` | removed | Merged to `main` as PR #20; plan archived in `docs/assistant/exec_plans/completed/` |
| Practice Wave 3 | merged | `feat/practice-wave3-hidden-recall-runtime` | removed | Merged to `main` as PR #22 after verification-only closeout; plan archived in `docs/assistant/exec_plans/completed/` |
| Practice Wave 4 | active | `feat/practice-wave4-daily-modes` | `/home/fa507/dev/hifz_planner_practice_wave4` | Implemented, validated, and docs-synced locally; ready for publish closeout |

- Current blockers:
  - No blocker is recorded at roadmap start.
- Detours and plan updates:
  - 2026-03-08: New roadmap opened after the planner/product redesign roadmap completed.
  - 2026-03-08: Wave 1 is implemented and validated locally in `/home/fa507/dev/hifz_planner_practice_wave1`; `Today` now launches new work into practice-first flow, `Learn` exposes a practice hub, and the practice screen title no longer leads with `Progressive Reveal Chain`.
  - 2026-03-08: Wave 1 received a narrow Assistant Docs Sync limited to the canonical app brief, assistant bridge, app user guide, and one planner guide reference.
  - 2026-03-08: PR #18 merged Wave 1 to `main`; the next roadmap action returns to Wave 2 after the Wave 1 plan is archived.
  - 2026-03-08: PR #19 archived the completed Wave 1 plan and reset the tracker on `main`, so Wave 2 can now start from a clean baseline.
  - 2026-03-08: Wave 2 is implemented and validated locally in `/home/fa507/dev/hifz_planner_practice_wave2`; the practice screen now uses task-first learner wording while keeping the deterministic engine, keys, and route contract unchanged.
  - 2026-03-08: PR #20 merged Wave 2 to `main`; the next roadmap action returns to Wave 3 after the Wave 2 plan is archived and cleanup completes.
  - 2026-03-08: PR #21 archived the completed Wave 2 plan and reset the tracker on `main`, so Wave 3 can now start from a clean baseline.
  - 2026-03-08: Wave 3 validation confirmed that the current hidden-recall runtime already matches `STAGE3_HIDDEN_RECALL_DESIGN_SPEC.md`; this wave needs closeout only, not a new engine patch.
  - 2026-03-08: PR #22 archived the completed Wave 3 plan and confirmed that the next roadmap action is Wave 4 from a clean baseline.
  - 2026-03-08: Wave 4 is implemented and validated locally in `/home/fa507/dev/hifz_planner_practice_wave4`; `Learn` now teaches the best daily order and readiness state for each practice path, while `Today` now exposes secondary practice-mode shortcuts when multiple valid modes remain.
  - 2026-03-08: Wave 4 received a narrow Assistant Docs Sync limited to the canonical app brief, assistant bridge, app user guide, and planner guide.
- Next recommended action:
  - Close Practice Wave 4 with commit, PR, merge, cleanup, and roadmap closeout.
