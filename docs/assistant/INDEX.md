# Assistant Docs Index

One-page navigation guide for agent-facing documentation.

## How To Use This Index

1. Open the row matching your task.
2. Read that document first.
3. Run the listed validator/smoke command before handoff.

## Agent Doc Map

| Document | Use when... | Do not use for... | Time to value |
|---|---|---|---|
| `AGENTS.md` | Your tool auto-opens `AGENTS.md` and needs immediate routing. | Deep architecture details. | 1 min |
| `agent.md` | You need the operational runbook and quick task routing matrix. | Full DB schema details. | 2 min |
| `APP_KNOWLEDGE.md` | You need canonical app architecture, feature status, and subsystem map. | Fine-grained per-workflow checklists. | 3 min |
| `docs/assistant/APP_KNOWLEDGE.md` | Your workflow expects assistant-path docs and needs canonical pointer/bootstrapping. | Canonical truth when conflicts exist. | 1 min |
| `docs/assistant/manifest.json` | You are an automated agent selecting docs/tests programmatically. | Human narrative context. | <1 min |
| `docs/assistant/DB_DRIFT_KNOWLEDGE.md` | You are changing schema/migrations/repos/planner persistence. | Reader-only UI behavior changes. | 3 min |
| `docs/assistant/workflows/READER_WORKFLOW.md` | Task targets Verse by Verse / Reading UI and interactions. | Planner internals or DB migrations. | 2 min |
| `docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md` | Task targets Quran.com fetch/cache/dedupe/fonts/translations. | Navigation shell changes. | 2 min |
| `docs/assistant/workflows/PLANNER_WORKFLOW.md` | Task targets onboarding/plan/today/scheduler/calibration. | Quran.com rendering fidelity tasks. | 2 min |
| `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md` | Task changes docs structure/contracts/links. | Runtime feature implementation. | 2 min |

## Validator Command

Run after docs changes:

```powershell
dart run tooling/validate_agent_docs.dart
```

Recommended docs smoke test:

```powershell
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```
