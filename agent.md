# AGENT RUNBOOK - Hifz Planner

Operational entrypoint for humans and AI agents working in this repo.

## What This Is For

Use this runbook to quickly route a task to the right files, commands, and tests.

## Canonical Docs Stack

1. `APP_KNOWLEDGE.md` (canonical app status and architecture)
2. `docs/assistant/manifest.json` (machine-readable routing map)
3. `docs/assistant/INDEX.md` (human doc index)
4. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB and Drift deep reference)
5. `docs/assistant/workflows/CI_REPO_WORKFLOW.md` (CI and branch/repo operations)
6. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/publish branch hygiene)

Compatibility:
- `AGENTS.md` is a short shim for tools that auto-open that filename.
- `agent.md` is the detailed runbook humans and AI agents should execute.

## Quick Routing Matrix

| If task is about... | Open first | Run first |
|---|---|---|
| Reader UI or Quran parity | `docs/assistant/workflows/READER_WORKFLOW.md` | `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart` |
| Quran.com API/cache/fonts | `docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md` | `flutter test -j 1 -r expanded test/data/services/qurancom_api_test.dart` |
| Planning/scheduling/calibration | `docs/assistant/workflows/PLANNER_WORKFLOW.md` | `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart` |
| Agent docs/structure | `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md` | `dart run tooling/validate_agent_docs.dart` |
| CI workflow / branch merge hygiene | `docs/assistant/workflows/CI_REPO_WORKFLOW.md` | `flutter analyze --no-fatal-infos --no-fatal-warnings` |
| Commit, stage, ignore, push, remote cleanup | `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` | `git status --short --branch` |

## 5-Minute Bootstrap

1. Check local state:
   - `git status --short`
2. Confirm routing and shell:
   - `lib/app/router.dart`
   - `lib/app/navigation_shell.dart`
3. Confirm reader core:
   - `lib/screens/reader_screen.dart`
4. Confirm data pipeline:
   - `lib/data/services/qurancom_api.dart`
   - `lib/ui/qcf/qcf_font_manager.dart`
5. Run docs validator:
   - `dart run tooling/validate_agent_docs.dart`

## Safe Working Rules

1. Source code wins over docs if there is conflict.
2. Keep diffs focused; do not revert unrelated local changes.
3. Do not manually edit generated Drift output:
   - `lib/data/database/app_database.g.dart`
4. Preserve fallback/no-crash behavior in reader and data flows.
5. On Windows prefer:
   - `flutter test -j 1 -r expanded`
6. If user says `commit`, follow `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` before creating commits.
7. `docs/assistant/templates/*` is read-on-demand only.
8. Only open or update template files when the user explicitly requests template/prompt work.
9. Exception: if user says to create/update the reusable prompt/template, `docs/assistant/templates/*` becomes in-scope for that task only.

## Core Commands

```powershell
git status --short
rg -n "keyword_or_symbol" lib test tooling
flutter analyze
flutter test -j 1 -r expanded
```

## Done Checklist

- files changed are intentional
- targeted tests passed for the touched area
- `dart run tooling/validate_agent_docs.dart` passed for doc changes
- no stale or broken doc paths remain
