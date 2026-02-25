# AGENT RUNBOOK - Hifz Planner

Operational entrypoint for humans and AI agents working in this repo.

## What This Is For

Use this runbook to quickly route a task to the right files, commands, and tests.

## Canonical Docs Stack

1. `APP_KNOWLEDGE.md` (canonical app status and architecture)
2. `docs/assistant/manifest.json` (machine-readable routing map)
3. `docs/assistant/INDEX.md` (human doc index)
4. `docs/assistant/GOLDEN_PRINCIPLES.md` (mechanical style/invariant rules)
5. `docs/assistant/exec_plans/PLANS.md` (major-work execution plans)
6. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB and Drift deep reference)
7. `docs/assistant/workflows/CI_REPO_WORKFLOW.md` (CI and branch/repo operations)
8. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/publish branch hygiene)

Compatibility:
- `AGENTS.md` is a short shim for tools that auto-open that filename.
- `agent.md` is the detailed runbook humans and AI agents should execute.

## Approval Gates

Ask for explicit approval before commands that:
- delete data/files outside scoped implementation
- apply destructive DB/schema actions in risky contexts
- force-push or rewrite protected branch history
- publish/release/deploy artifacts
- run non-essential external network calls for implementation

## Quick Routing Matrix

| If task is about... | Open first | Run first |
|---|---|---|
| VS Code lag, file watchers, indexing pressure, workspace hygiene | `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` | `dart run tooling/validate_workspace_hygiene.dart` |
| Localization, new language rollout, terminology consistency, RTL | `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` | `dart run tooling/validate_localization.dart` |
| Reader UI or Quran parity | `docs/assistant/workflows/READER_WORKFLOW.md` | `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart` |
| Quran.com API/cache/fonts | `docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md` | `flutter test -j 1 -r expanded test/data/services/qurancom_api_test.dart` |
| Planning/scheduling/calibration | `docs/assistant/workflows/PLANNER_WORKFLOW.md` | `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart` |
| "Like X"/"same as X"/parity inspired by named app/site | `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` | `dart run tooling/validate_agent_docs.dart` |
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
   - `lib/data/services/ayah_audio_service.dart`
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
10. Major changes must start on a new `feat/*` branch, not on `main`.
11. Keep `main` stable; merge major work through PR flow with required checks.
12. For localization tasks, open `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` and use `docs/assistant/LOCALIZATION_GLOSSARY.md` as the term source of truth.
13. For workspace performance tasks, open `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` and treat `docs/assistant/PERFORMANCE_BASELINES.md` as the source of truth.
14. For inspiration/parity requests against named apps/sites, open `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` and base implementation decisions on cited references.
15. After significant implementation changes, ask exactly: "Would you like me to run Assistant Docs Sync for this change now?"
16. If docs sync is approved, update only relevant assistant docs for touched scope (no blanket doc rewrites).

## ExecPlans

For major or multi-file work:
1. Create an ExecPlan under `docs/assistant/exec_plans/active/`.
2. Follow required structure from `docs/assistant/exec_plans/PLANS.md`.
3. Keep the plan self-contained and update decisions/progress during implementation.
4. Move finished plans to `docs/assistant/exec_plans/completed/`.

ExecPlans are optional for minor isolated edits.

## Worktree Isolation

- For parallel implementation streams, prefer isolated `git worktree` workspaces.
- Keep each major thread scoped to one worktree/branch pair.
- Avoid mixing unrelated feature work in the same worktree.

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
- `dart run tooling/validate_workspace_hygiene.dart` passed for performance/workspace changes
- after significant changes, Assistant Docs Sync prompt was asked and outcome recorded
- no stale or broken doc paths remain
