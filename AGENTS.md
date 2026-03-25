# AGENTS Compatibility Entry

This file exists for tooling that auto-discovers `AGENTS.md`.

Why both files exist:
- `AGENTS.md` is a compatibility shim for auto-discovery.
- `agent.md` is the full operational runbook.

## Use These Docs In Order

1. `agent.md` (primary runbook)
2. `APP_KNOWLEDGE.md` (canonical app knowledge)
3. `docs/assistant/ROADMAP_ANCHOR.md` (current roadmap continuity and next-milestone handoff)
4. `docs/assistant/manifest.json` (machine-readable routing)
5. `docs/assistant/INDEX.md` (human doc index)
6. `docs/assistant/GOLDEN_PRINCIPLES.md` (mechanical invariants)
7. `docs/assistant/exec_plans/PLANS.md` (major-work planning contract)
8. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB/Drift deep reference)
9. `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` (language/RTL/terminology)
10. `docs/assistant/LOCALIZATION_GLOSSARY.md` (localized term source)
11. `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` (workspace performance)
12. `docs/assistant/PERFORMANCE_BASELINES.md` (editor/perf defaults)
13. `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` (parity reference policy)
14. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/push/cleanup protocol)
15. `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md` (local bootstrap harness apply/audit)

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
- Route local bootstrap harness apply/audit tasks to:
  - `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md`
- Route explicit HTML explainer requests to:
  - `docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md`
- For user support/non-technical explanation tasks:
  - start with `docs/assistant/features/APP_USER_GUIDE.md`
  - for planner behavior/support use `docs/assistant/features/PLANNER_USER_GUIDE.md`
  - respond in plain language first; avoid jargon unless you define it in one short sentence
  - run a canonical cross-check with `APP_KNOWLEDGE.md` before making technical behavior claims
- After significant implementation changes, always ask:
  - "Would you like me to run Assistant Docs Sync for this change now?"
  - If user agrees, update only relevant assistant docs for changed scope.
- In user conversations, `roadmap`, `master plan`, and `next milestone` default to the Companion/Planner track unless the user explicitly redirects.
- For roadmap continuation or "continue where we left off" requests, open `docs/assistant/ROADMAP_ANCHOR.md` early.
- Default closeout for major implementation stages:
  - run targeted validation for the touched scope
  - commit implementation files first
  - keep the exact Assistant Docs Sync prompt unchanged
  - if approved, run targeted docs sync for the touched scope
  - commit docs changes separately
  - end with a clean local worktree
  - keep push explicit
- `docs/assistant/templates/*` is read-on-demand only.
- Only open or update `docs/assistant/templates/*` when the user explicitly asks for template/prompt creation or updates.
- Exception: explicit HTML explainer requests may use `docs/assistant/templates/EXPLAINER_HTML_PROMPT.md`.
- Exception: explicit bootstrap harness tasks such as `implement the template files`, `sync project harness`, `audit project harness`, or `check project harness` may read vendored bootstrap templates through `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md`.

## Non-Coder Communication Mode

For user support or explanation tasks:
- start with `docs/assistant/features/APP_USER_GUIDE.md` (and use `docs/assistant/features/PLANNER_USER_GUIDE.md` for planner-specific questions)
- answer in plain language first
- avoid jargon unless you define it in one short line
- verify technical claims using `APP_KNOWLEDGE.md` before asserting them
- if the user explicitly asks for an HTML explainer, route to `docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md`

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
