# Session Resume

## Fresh Session Rule

If a brand-new Codex chat in VS Code needs to continue roadmap work, start here before opening any roadmap tracker or wave plan.

This file is the roadmap anchor file and stable resume anchor for:
- `resume master plan`
- `where did we leave off`
- `what is the next roadmap step`

## Resume Trigger

Primary explicit trigger:
- `resume master plan`

Equivalent resume intents:
- `where did we leave off`
- `what is the next roadmap step`

For any of those, open these docs in order:
1. `docs/assistant/SESSION_RESUME.md`
2. `docs/assistant/exec_plans/completed/2026-03-09_my_quran_execution.md`
3. `docs/assistant/exec_plans/completed/2026-03-09_recent_change_integration_sweep.md`

## Current Roadmap

- `No active roadmap (latest completed: My Quran Personal Hub)`

## Current Wave

- `No active wave`

## Current Status

- Wave 4 is merged to `main`.
- The Wave 4 active plan is archived.
- The My Quran Personal Hub roadmap tracker is archived to `docs/assistant/exec_plans/completed/`.
- The Recent Change Integration Sweep is the latest completed closeout plan and is archived to `docs/assistant/exec_plans/completed/`.
- No roadmap is currently active on stable `main`.
- The project harness now inherits the reusable UCBS roadmap-governance module from `main`, including the template-layer upgrade and active-worktree authority rules.

## Exact Next Step

- `define the next backlog or a new roadmap`

## Active Worktree And Branch

- Worktree: `/home/fa507/dev/hifz_planner`
- Branch: `main`

## Read These Next

1. `docs/assistant/exec_plans/completed/2026-03-09_my_quran_execution.md`
2. `docs/assistant/exec_plans/completed/2026-03-09_recent_change_integration_sweep.md`
3. `docs/assistant/ISSUE_MEMORY.md`

## Completed Roadmaps

- Planner redesign roadmap: completed
- Practice from Memory roadmap: completed
- Goals + Progress roadmap: completed
- Reader Understanding roadmap: completed
- My Quran Personal Hub roadmap: completed

## Detours And Open Notes

- A docs-governance detour added `docs/assistant/features/START_HERE_USER_GUIDE.md` and the related docs-routing/validator support before Wave 2 publish.
- Fresh-session resume routing is now in place so future chats do not need to reconstruct roadmap state from scattered trackers.
- `docs/assistant/SESSION_RESUME.md` remains summary-level only as the roadmap anchor file; when no roadmap is active it should point to the latest completed roadmap tracker and relevant completed closeout plan.
- Roadmap governance is now explicit in `docs/assistant/workflows/ROADMAP_WORKFLOW.md`, including adaptive trigger thresholds and the rule that the active worktree is authoritative during in-flight wave work.
- The reusable UCBS roadmap-governance template module is now merged to `main`, and this active worktree has been rebased onto that baseline so the live project harness matches the reusable template contracts.
- The repeated fresh-worktree Flutter lockfile-churn issue also surfaced during the final Wave 4 closeout validation; the incidental change was reverted and issue memory now points at the archived plan.
- Keep this file summary-level only. The active roadmap tracker and active wave plan remain the deeper execution sources while a roadmap is live; completed roadmap history belongs under `docs/assistant/exec_plans/completed/`.
