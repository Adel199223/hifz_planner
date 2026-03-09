# AGENTS Compatibility Entry

This file exists for tooling that auto-discovers `AGENTS.md`.

Why both files exist:
- `AGENTS.md` is a compatibility shim for auto-discovery.
- `agent.md` is the full operational runbook.

## Use These Docs In Order

1. `docs/assistant/SESSION_RESUME.md` (fresh-session roadmap resume entrypoint)
2. `agent.md` (primary runbook)
3. `APP_KNOWLEDGE.md` (canonical app knowledge)
4. `docs/assistant/manifest.json` (machine-readable routing)
5. `docs/assistant/INDEX.md` (human doc index)
6. `docs/assistant/ISSUE_MEMORY.md` (repeatable issue registry)
7. `docs/assistant/GOLDEN_PRINCIPLES.md` (mechanical invariants)
8. `docs/assistant/exec_plans/PLANS.md` (major-work planning contract)
9. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB/Drift deep reference)
10. `docs/assistant/LOCAL_ENV_PROFILE.example.md` (WSL-vs-Windows routing format)
11. `docs/assistant/LOCAL_CAPABILITIES.md` (discovered local tool inventory)
12. `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md` (launch/build identity)
13. `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` (language/RTL/terminology)
14. `docs/assistant/LOCALIZATION_GLOSSARY.md` (localized term source)
15. `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` (workspace performance)
16. `docs/assistant/PERFORMANCE_BASELINES.md` (editor/perf defaults)
17. `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` (parity reference policy)
18. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/push/cleanup protocol)

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
- Route launch/open-app/parallel-worktree tasks to:
  - `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md`
  - `tooling/print_build_identity.dart`
- Use `docs/assistant/ISSUE_MEMORY.md` and `docs/assistant/ISSUE_MEMORY.json` for repeatable workflow issues; do not seed fake incidents.
- Use `docs/assistant/LOCAL_CAPABILITIES.md` and `docs/assistant/LOCAL_ENV_PROFILE.example.md` when tool availability or WSL-vs-Windows routing is unclear.
- For user support/non-technical explanation tasks:
  - start with `docs/assistant/features/START_HERE_USER_GUIDE.md`
  - then use `docs/assistant/features/APP_USER_GUIDE.md` for broader support
  - for planner behavior/support use `docs/assistant/features/PLANNER_USER_GUIDE.md`
  - respond in plain language first; avoid jargon unless you define it in one short sentence
  - run a canonical cross-check with `APP_KNOWLEDGE.md` before making technical behavior claims
- After significant implementation changes, always ask:
  - "Would you like me to run Assistant Docs Sync for this change now?"
  - If user agrees, update only relevant assistant docs for changed scope.
- `docs/assistant/templates/*` is read-on-demand only.
- Only open or update `docs/assistant/templates/*` when the user explicitly asks for template/prompt creation or updates.

## Non-Coder Communication Mode

For user support or explanation tasks:
- start with `docs/assistant/features/START_HERE_USER_GUIDE.md`
- then use `docs/assistant/features/APP_USER_GUIDE.md` (and use `docs/assistant/features/PLANNER_USER_GUIDE.md` for planner-specific questions)
- answer in plain language first
- avoid jargon unless you define it in one short line
- verify technical claims using `APP_KNOWLEDGE.md` before asserting them

## Approval Gates

Pause and ask for explicit user confirmation before commands that:
- delete data or files outside normal scoped edits
- change DB schema/migrations in risky contexts
- use force-push or protected-branch rewrite operations
- publish/release/deploy artifacts
- call non-essential external network endpoints for implementation tasks

## Shorthand Defaults

- Bare `commit` means full pending-tree triage, logical grouped commits, and immediate push suggestion unless the user narrows scope.
- Bare `push` means Push+PR+Merge+Cleanup unless the user narrows scope explicitly.

## ExecPlans

- Use ExecPlans for major or multi-file work.
- Major/multi-file work must start with an ExecPlan in `docs/assistant/exec_plans/active/`.
- Follow structure in `docs/assistant/exec_plans/PLANS.md`.
- Minor isolated edits may skip ExecPlan.

## Worktree Isolation

- For parallel feature or automation threads, prefer `git worktree` isolation.
- Do not mix unrelated implementation streams in the same working tree.
- For runnable-build handoff, include worktree path, branch, HEAD SHA, workspace file, and launch command.

## Fresh Session Resume Protocol

- For a new chat that asks to continue, resume, or asks what the next roadmap step is, open `docs/assistant/SESSION_RESUME.md` first.
- Treat `resume master plan` as the explicit trigger phrase.
- Also treat these as equivalent resume intents:
  - `where did we leave off`
  - `what is the next roadmap step`
- After `docs/assistant/SESSION_RESUME.md`, open:
  1. the linked active roadmap tracker
  2. the linked active wave ExecPlan
- Answer with:
  - current roadmap status
  - exact next step

## Roadmap Return Protocol

- After every substantial closeout, always tell the user:
  - current roadmap status
  - exact next step by wave or stage name
- When the research stages are already complete, say exactly:
  - `All research stages are complete; implementation continues by wave.`
- After any detour for bugfix, tooling, docs, or environment work:
  1. update the active wave ExecPlan first
  2. update the active roadmap tracker second
  3. update `docs/assistant/SESSION_RESUME.md` third
  4. resume from `docs/assistant/SESSION_RESUME.md` unless the active roadmap tracker records a new sequence
- Every roadmap closeout message must end with one explicit line in this shape:
  - `Next step: Wave X - <name>`
- If the next action is closeout rather than a new wave, end with:
  - `Next step: close Wave X with <closeout action>`
