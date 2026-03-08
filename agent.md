# AGENT RUNBOOK - Hifz Planner

Operational entrypoint for humans and AI agents working in this repo.

## What This Is For

Use this runbook to quickly route a task to the right files, commands, and tests.

## Canonical Docs Stack

1. `APP_KNOWLEDGE.md` (canonical app status and architecture)
2. `docs/assistant/manifest.json` (machine-readable routing map)
3. `docs/assistant/INDEX.md` (human doc index)
4. `docs/assistant/ISSUE_MEMORY.md` (repeatable issue registry)
5. `docs/assistant/GOLDEN_PRINCIPLES.md` (mechanical style/invariant rules)
6. `docs/assistant/exec_plans/PLANS.md` (major-work execution plans)
7. `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (DB and Drift deep reference)
8. `docs/assistant/LOCAL_ENV_PROFILE.example.md` (WSL-vs-Windows routing format)
9. `docs/assistant/LOCAL_CAPABILITIES.md` (discovered local tool inventory)
10. `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md` (launch/build identity)
11. `docs/assistant/workflows/CI_REPO_WORKFLOW.md` (CI and branch/repo operations)
12. `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` (commit/publish branch hygiene)

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
| Build identity, launch/open app, parallel worktrees | `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md` | `dart tooling/print_build_identity.dart` |
| User support / non-technical app explanation | `docs/assistant/features/APP_USER_GUIDE.md` (or `docs/assistant/features/PLANNER_USER_GUIDE.md` for planner questions); respond in plain language first and define unavoidable jargon once | `dart run tooling/validate_agent_docs.dart` when docs were edited |
| Agent docs/structure | `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md` | `dart run tooling/validate_agent_docs.dart` |
| CI workflow / branch merge hygiene | `docs/assistant/workflows/CI_REPO_WORKFLOW.md` | `flutter analyze --no-fatal-infos --no-fatal-warnings` |
| Commit, stage, ignore, push, remote cleanup | `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` | `git status --short --branch` |

## Shorthand Defaults

- Bare `commit` means full pending-tree triage, logical grouped commits, and immediate push suggestion unless the user narrows scope.
- Bare `push` means Push+PR+Merge+Cleanup unless the user narrows scope explicitly.

## Non-Coder Communication Mode

For user support or explanation tasks:
1. Start with `docs/assistant/features/APP_USER_GUIDE.md` (or `docs/assistant/features/PLANNER_USER_GUIDE.md` for planner topics).
2. Answer in plain language first, then give numbered steps with exact UI labels.
3. If you must use a technical term, define it in one short line.
4. Verify technical claims with `APP_KNOWLEDGE.md` before asserting them.
5. Mention uncertainty explicitly when behavior may still be evolving.

## 5-Minute Bootstrap

1. Check local state:
   - `git status --short`
   - if environment/tooling is unclear, open `docs/assistant/LOCAL_CAPABILITIES.md`
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
17. For support/non-technical replies, do a canonical cross-check with `APP_KNOWLEDGE.md` before making technical behavior claims.
18. Consult `docs/assistant/ISSUE_MEMORY.md` before widening touched-scope docs for a repeated workflow or tooling failure.
19. When launch/build identity matters, route through `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md` and use `dart tooling/print_build_identity.dart`.

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
dart tooling/print_build_identity.dart
```

## Done Checklist

- files changed are intentional
- targeted tests passed for the touched area
- `dart run tooling/validate_agent_docs.dart` passed for doc changes
- `dart run tooling/validate_workspace_hygiene.dart` passed for performance/workspace changes
- after significant changes, Assistant Docs Sync prompt was asked and outcome recorded
- no stale or broken doc paths remain

## Roadmap Return Protocol

Use this whenever work belongs to the staged product-redesign roadmap.

1. After every substantial closeout, explicitly report:
   - current roadmap status
   - exact next step by wave or stage name
2. When Stage 1-5 research is already complete, say exactly:
   - `All research stages are complete; implementation continues by wave.`
3. After any detour for bugfixes, tooling, docs, or environment:
   - update the active wave ExecPlan first
   - update `docs/assistant/exec_plans/active/2026-03-08_product_redesign_execution.md` second
   - resume from the tracker unless it records a sequence change
4. Every roadmap closeout message must end with:
   - `Next step: Wave X - <name>`
5. If the next action is a closeout step instead of a new wave, end with:
   - `Next step: close Wave X with <closeout action>`
