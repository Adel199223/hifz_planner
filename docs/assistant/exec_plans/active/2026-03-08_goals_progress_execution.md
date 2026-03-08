# ExecPlan: Goals + Progress Execution Tracker

## Purpose
- Keep the Goals + Progress roadmap durable inside the repo.
- Track the live execution order for the four progress-focused waves.
- Provide one file to return to after interruptions, bugfix detours, or publish steps.

## Scope
- In scope:
  - Wave 1 through Wave 4 status tracking
  - Branch and worktree mapping
  - Current blockers
  - Detours and plan updates
  - Next recommended action
  - Links to the supporting roadmap definition
- Out of scope:
  - Replacing wave-specific ExecPlans
  - Detailed implementation steps for each wave

## Assumptions
- The earlier planner roadmap and the Practice from Memory roadmap are complete and now serve as historical context.
- This is a new roadmap focused on supportive, integrated goals and progress for solo learners.
- Progress remains integrated into `Today` and `My Plan`; this roadmap does not add a new top-level destination.
- Schema and route stability are preferred; if a metric cannot be derived from existing persisted data, it should be dropped instead of forcing a migration.

## Milestones
1. Start and complete Wave 1 goal framing and daily wins.
2. Start and complete Wave 2 weekly progress and trust layer.
3. Start and complete Wave 3 goal coaching and adjustment guidance.
4. Start and complete Wave 4 cross-surface consistency and roadmap closeout.
5. Close the roadmap and define the next backlog.

## Detailed Steps
1. Start Wave 1 on an isolated worktree and add a wave-specific ExecPlan.
2. Add one shared internal read-only progress snapshot layer used by both `Today` and `My Plan`.
3. Keep Wave 1 focused on goal framing and daily wins derived from current planner posture.
4. Add Wave 2 only after Wave 1 closes, using count-based recent progress metrics from existing logs.
5. Keep Wave 3 advice-only; do not silently mutate the learner's plan.
6. Finish Wave 4 by aligning the goal/progress language across `Today`, `My Plan`, completion states, and support docs.

## Decision Log
- 2026-03-08: Start a new roadmap instead of extending the completed Practice from Memory roadmap.
- 2026-03-08: Keep progress supportive and integrated, not gamified.
- 2026-03-08: Derive goals from planner posture and recent behavior rather than adding a separate goal-setup flow.
- 2026-03-08: Prefer count-based recent progress first; do not depend on duration minutes because current logs do not reliably populate them.

## Validation
- For each active wave, run the focused screen and service tests listed in that wave's ExecPlan.
- Run `dart tooling/validate_agent_docs.dart` after tracker or ExecPlan updates.
- Run `dart tooling/validate_localization.dart` when wave work changes learner-facing wording.

## Progress
- [x] Start Wave 1
- [x] Merge Wave 1
- [x] Start Wave 2
- [x] Merge Wave 2
- [ ] Start Wave 3
- [ ] Merge Wave 3
- [ ] Start Wave 4
- [ ] Merge Wave 4
- [ ] Close the roadmap

## Surprises and Adjustments
- Use this section for sequence changes, blockers, or scope corrections discovered during implementation.

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
- Roadmap order:
  - Wave 1: Goal Framing and Daily Wins
  - Wave 2: Weekly Progress and Trust Layer
  - Wave 3: Goal Coaching and Adjustment Guidance
  - Wave 4: Cross-Surface Consistency and Roadmap Closeout
- Related context:
  - `APP_KNOWLEDGE.md`
  - `docs/assistant/features/APP_USER_GUIDE.md`
  - `docs/assistant/features/PLANNER_USER_GUIDE.md`
- Wave status:

| Stream | Status | Branch | Worktree | Notes |
|---|---|---|---|---|
| Previous planner roadmap | merged | historical | removed | Wave 1-7 completed before this roadmap started |
| Practice from Memory roadmap | merged | historical | removed | Focused 4-wave practice roadmap completed before this roadmap started |
| Goals Wave 1 | merged | `feat/goals-wave1-daily-wins` | removed after merge | Merged to `main` as PR #25; plan archived in `docs/assistant/exec_plans/completed/` |
| Goals Wave 2 | merged | `feat/goals-wave2-weekly-progress` | removed after merge | Weekly recent-progress snapshot and trust layer merged to `main` as PR #27; plan archived in `docs/assistant/exec_plans/completed/` |
| Goals Wave 3 | planned | not created | not created | Advice-only goal coaching and adjustment guidance |
| Goals Wave 4 | planned | not created | not created | Cross-surface wording alignment and roadmap closeout |

- Current blockers:
  - No blocker is recorded at roadmap start.
- Detours and plan updates:
  - 2026-03-08: New roadmap opened after the planner and practice roadmaps completed.
  - 2026-03-08: Wave 1 started in isolated worktree `/home/fa507/dev/hifz_planner_goals_wave1` on branch `feat/goals-wave1-daily-wins`.
  - 2026-03-08: Wave 1 added a shared `GoalProgressSnapshotService`, a new roadmap tracker, a Wave 1 ExecPlan, a `Today` daily-win block, and a `My Plan` weekly goal summary tied to existing planner posture.
  - 2026-03-08: Wave 1 validation is green after rerunning Flutter tests sequentially; parallel `flutter test` launches in the same worktree triggered a Flutter plugin-symlink crash, so the clean validation record for this wave is the sequential run.
  - 2026-03-08: Wave 1 received a narrow Assistant Docs Sync limited to the canonical app brief, assistant bridge, app user guide, and planner user guide.
  - 2026-03-08: PR #25 merged Goals Wave 1 to `main`; the next roadmap action returns to Wave 2 after this archive/update lands.
- 2026-03-08: PR #26 archived the completed Wave 1 plan and reset the tracker on `main`, so Wave 2 can now start from a clean baseline.
- 2026-03-08: Wave 2 started in isolated worktree `/home/fa507/dev/hifz_planner_goals_wave2` on branch `feat/goals-wave2-weekly-progress`.
- 2026-03-08: Wave 2 now has a shared recent-progress snapshot feeding both `Today` and `My Plan`, including active-day counts, delayed-check counts, review counts, a best-effort practice completion count, and a simple recent-quality band from review grades.
- 2026-03-08: Wave 2 validation is green in the isolated worktree after sequential Flutter runs:
  - `flutter test -j 1 -r expanded test/data/services/goal_progress_snapshot_service_test.dart`
  - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
  - `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
  - `dart tooling/validate_workspace_hygiene.dart`
- 2026-03-08: Wave 2 pre-closeout docs sync also refreshed issue memory with the repeatable local validation issues from this stream:
  - parallel Flutter test plugin-symlink races inside one worktree
  - incidental `pubspec.lock` churn on first Flutter validation in a fresh worktree
- 2026-03-08: PR #27 merged Goals Wave 2 to `main`; the closeout step is now archive/tracker bookkeeping only, and the roadmap resumes at Wave 3 after cleanup.
- Next recommended action:
  - Wave 3 - Goal Coaching and Adjustment Guidance
