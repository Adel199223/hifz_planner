# AGENTS Compatibility Entry

This file exists for tooling that auto-discovers `AGENTS.md`.

## Use These Docs In Order

1. `agent.md` (primary runbook)
2. `APP_KNOWLEDGE.md` (canonical app knowledge)
3. `docs/assistant/manifest.json` (machine-readable task routing)
4. `docs/assistant/INDEX.md` (human doc index)
5. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB/Drift deep reference)

## Non-Negotiables

- Source code wins over docs on any conflict.
- Do not manually edit generated Drift file: `lib/data/database/app_database.g.dart`.
- Run targeted tests before broad suites.
