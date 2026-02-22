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
6. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/push/cleanup protocol)

## Non-Negotiables

- Source code wins over docs on any conflict.
- Do not manually edit generated Drift file: `lib/data/database/app_database.g.dart`.
- Run targeted tests before broad suites.
- `docs/assistant/templates/*` is read-on-demand only.
- Only open or update `docs/assistant/templates/*` when the user explicitly asks for template/prompt creation or updates.
