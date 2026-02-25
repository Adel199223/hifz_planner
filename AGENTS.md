# AGENTS Compatibility Entry

This file exists for tooling that auto-discovers `AGENTS.md`.

Why both files exist:
- `AGENTS.md` is a compatibility shim for auto-discovery.
- `agent.md` is the full operational runbook.

## Use These Docs In Order

1. `agent.md` (primary runbook)
2. `APP_KNOWLEDGE.md` (canonical app knowledge)
3. `docs/assistant/manifest.json` (machine-readable routing)
4. `docs/assistant/INDEX.md` (human doc index)
5. `docs/assistant/GOLDEN_PRINCIPLES.md` (mechanical invariants)
6. `docs/assistant/exec_plans/PLANS.md` (major-work planning contract)
7. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB/Drift deep reference)
8. `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` (language/RTL/terminology)
9. `docs/assistant/LOCALIZATION_GLOSSARY.md` (localized term source)
10. `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` (workspace performance)
11. `docs/assistant/PERFORMANCE_BASELINES.md` (editor/perf defaults)
12. `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` (parity reference policy)
13. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/push/cleanup protocol)

## Non-Negotiables

- Source code wins over docs on any conflict.
- Do not manually edit generated Drift file: `lib/data/database/app_database.g.dart`.
- Run targeted tests before broad suites.
- Major changes must start on a new `feat/*` branch, not on `main`.
- Keep `main` stable; merge major work through PR flow with required checks.
- Route localization tasks to:
  - `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
  - `docs/assistant/LOCALIZATION_GLOSSARY.md`
- Route workspace performance/lag tasks to:
  - `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
  - `docs/assistant/PERFORMANCE_BASELINES.md`
- Route inspiration/parity tasks to:
  - `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`
- After significant implementation changes, always ask:
  - "Would you like me to run Assistant Docs Sync for this change now?"
  - If user agrees, update only relevant assistant docs for changed scope.
- `docs/assistant/templates/*` is read-on-demand only.
- Only open or update `docs/assistant/templates/*` when the user explicitly asks for template/prompt creation or updates.

## Approval Gates

Pause and ask for explicit user confirmation before commands that:
- delete data or files outside normal scoped edits
- change DB schema/migrations in risky contexts
- use force-push or protected-branch rewrite operations
- publish/release/deploy artifacts
- call non-essential external network endpoints for implementation tasks

## ExecPlans

- Use ExecPlans for major or multi-file work.
- Major/multi-file work must start with an ExecPlan in `docs/assistant/exec_plans/active/`.
- Follow structure in `docs/assistant/exec_plans/PLANS.md`.
- Minor isolated edits may skip ExecPlan.

## Worktree Isolation

- For parallel feature or automation threads, prefer `git worktree` isolation.
- Do not mix unrelated implementation streams in the same working tree.
