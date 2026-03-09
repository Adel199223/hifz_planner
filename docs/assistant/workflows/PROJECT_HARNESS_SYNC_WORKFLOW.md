# Project Harness Sync Workflow

## What This Workflow Is For

Use this workflow when a repo already carries vendored `docs/assistant/templates/*` files and the task is to apply those templates to the repo's own assistant harness.

## Expected Outputs

- The repo's local harness matches the vendored template contracts.
- Vendored template files stay committed and protected.
- Routing docs, workflows, manifest contracts, and validators stay aligned.

## When To Use

Use when requests include:
- `implement the template files`
- `sync project harness`
- `audit project harness`
- `check project harness`
- local harness alignment after copied template files changed

## What Not To Do

- Don't use this workflow when the task is global bootstrap-template maintenance. Instead use the canonical bootstrap-maintenance triggers from `docs/assistant/templates/BOOTSTRAP_UPDATE_POLICY.md`.
- Don't edit `docs/assistant/templates/*` during local harness application unless the user explicitly asks to update the template folder itself.
- Don't treat vendored template files as cleanup candidates or ignore targets by default.
- Don't rewrite unrelated product docs or runtime files just because a template exists.

## Primary Files

- `AGENTS.md`
- `agent.md`
- `README.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/manifest.json`
- `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md`
- `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `docs/assistant/workflows/ROADMAP_WORKFLOW.md`
- `docs/assistant/exec_plans/PLANS.md`
- `tooling/validate_agent_docs.dart`
- `test/tooling/validate_agent_docs_test.dart`

## Minimal Commands

```powershell
git status --short --branch
rg -n "implement the template files|sync project harness|SESSION_RESUME|templates" AGENTS.md agent.md README.md docs/assistant tooling test
dart run tooling/validate_agent_docs.dart
```

## Targeted Tests

```powershell
flutter test --no-pub -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: `implement the template files` starts editing vendored template files.
   - Stop and keep `docs/assistant/templates/*` unchanged unless the user explicitly requested template-folder maintenance.
2. Symptoms: copied template files appear untracked during later commit triage.
   - Treat them as intentional vendored template scope, not as cleanup clutter.
3. Symptoms: local harness drift exists but the template folder is incomplete.
   - Repair the vendored template inventory first, then re-run local harness sync.
4. Symptoms: request says `update bootstrap`.
   - Clarify whether the target is global bootstrap maintenance or local harness application.
5. Symptoms: roadmap/resume docs drift after local harness apply.
   - Update `ROADMAP_WORKFLOW.md`, `PLANS.md`, and `SESSION_RESUME.md` only if the changed contracts affect resume/governance behavior.
6. Symptoms: `flutter test --no-pub` fails in a fresh worktree before dependencies are bootstrapped.
   - Allow one `flutter test` run to resolve dependencies, then revert incidental `pubspec.lock` churn before closeout if that file changed outside intended scope.

## Handoff Checklist

- `implement the template files` routing exists in agent-facing docs
- vendored template files stayed committed and unchanged unless explicitly requested
- local harness contracts were updated in `agent.md` and `docs/assistant/manifest.json`
- commit/publish policy no longer treats vendored templates as remove/ignore candidates
- roadmap anchor-file wording remains aligned
- validator passed
