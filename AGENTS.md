# AGENTS Compatibility Entry

This file exists for tooling that auto-discovers `AGENTS.md`.

Why both files exist:
- `AGENTS.md` is a compatibility shim for auto-discovery.
- `agent.md` is the full operational runbook.

## Use These Docs In Order

1. `agent.md` (primary runbook)
2. `APP_KNOWLEDGE.md` (canonical app knowledge)
3. `docs/assistant/manifest.json` (machine-readable task routing)
4. `docs/assistant/INDEX.md` (human doc index)
5. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB/Drift deep reference)
6. `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` (language/RTL/terminology workflow)
7. `docs/assistant/LOCALIZATION_GLOSSARY.md` (single source of localized terms)
8. `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` (workspace performance workflow)
9. `docs/assistant/PERFORMANCE_BASELINES.md` (canonical editor/perf defaults)
10. `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` (inspiration/parity reference policy)
11. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/push/cleanup protocol)

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
