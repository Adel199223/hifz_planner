# CODEX Project Bootstrap Prompt (Reusable Template)

## Purpose

This is a reusable, app-agnostic prompt template for bootstrapping an AI-first documentation stack in a new repository.

Use this prompt in other Codex chats/projects to generate equivalent docs and workflow contracts.

## Usage

1. Copy the prompt block below into the new Codex chat.
2. Replace project-specific placeholders only if needed.
3. Keep the workflow/validator requirements intact unless your repo has a clear reason to differ.

Read policy:
- This file is a private template asset.
- `docs/assistant/templates/*` is read-on-demand only and should not be opened unless explicitly requested by the user.

## Master Prompt (Copy/Paste)

```md
# Cross-Project Codex Prompt (Agent Docs + Workflows Bootstrap)

You are working in a new app repository. Build an AI-first documentation system that makes third-party agents fast, accurate, and safe.

## Objectives
1. Create a canonical+bridge docs model so one source of truth exists.
2. Add machine-readable routing so automated agents can choose the right workflow quickly.
3. Add workflow runbooks for feature work, data work, CI/repo operations, docs maintenance, and commit/publish hygiene.
4. Add validator tooling and tests that catch docs drift and policy violations.
5. Keep all commands PowerShell-compatible and avoid bash-only syntax.
6. Ensure commit requests are never handled blindly.

## Required Documentation Architecture
Create or update these files (adapt names to repo domain where needed):

### Root level
- `AGENTS.md` (compatibility shim; short)
- `agent.md` (operational runbook)
- `APP_KNOWLEDGE.md` (canonical architecture/status brief)
- `README.md` (short onboarding links to agent docs stack)

### Assistant docs namespace
- `docs/assistant/APP_KNOWLEDGE.md` (bridge, intentionally shorter than canonical)
- `docs/assistant/INDEX.md` (human index with “Use when…”)
- `docs/assistant/manifest.json` (machine routing map)
- `docs/assistant/DB_DRIFT_KNOWLEDGE.md` (if DB-backed app; otherwise equivalent persistence deep doc)

### Workflow docs
- `docs/assistant/workflows/FEATURE_WORKFLOW.md` (core product workflow; rename to domain)
- `docs/assistant/workflows/DATA_WORKFLOW.md` (data/API/cache/schema workflow; rename to domain)
- `docs/assistant/workflows/CI_REPO_WORKFLOW.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`

### Tooling
- `tooling/validate_agent_docs.dart`
- `test/tooling/validate_agent_docs_test.dart`

## Canonical Rules
1. `APP_KNOWLEDGE.md` is canonical for app-level architecture/status.
2. Bridge doc is intentionally non-identical and must defer to canonical.
3. Source code is final truth when docs conflict.
4. `AGENTS.md` is shim; `agent.md` is runbook.
5. If user says “commit”, follow commit workflow protocol before any commit.
6. Keep `main` stable: major changes must start on a new `feat/*` branch.
7. Merge to `main` via PR flow and required checks; avoid direct push to `main` for major work.

## Commit/Publish Workflow Requirements
In `COMMIT_PUBLISH_WORKFLOW.md`, define a strict sequence:
1. Branch safety gate (before staging):
   - if change is major and branch is `main`, create/switch to `feat/<scope-name>`
   - keep `main` as stable integration branch
2. Fetch/prune and inspect state:
   - `git fetch --prune origin`
   - `git status --short --branch`
   - `git diff --name-only`
   - `git diff --cached --name-only`
   - `git ls-files --others --exclude-standard`
3. Triage:
   - what to stage
   - what to ignore
   - what to split into separate commits
4. Validate:
   - targeted tests for touched area
   - docs validator when docs changed
5. Commit:
   - scoped staging (`git add <path>`)
   - remove accidental staged files (`git restore --staged <path>`)
   - meaningful commit message
6. Push:
   - push correct branch only
   - never force-push `main`
7. Repo cleanup:
   - ff-only merge to `main`
   - delete stale branches with explicit keep-list
   - prune refs and verify final clean state

## Manifest Requirements (`docs/assistant/manifest.json`)
Include:
- `version`
- `canonical`
- `bridges`
- `workflows[]` with:
  - `id`, `doc`, `scope`, `primary_files`, `targeted_tests`, `validation_commands`
- `global_commands`
- `contracts`
- `last_updated` (YYYY-MM-DD)

Add workflow IDs for:
- feature workflow
- data workflow
- `ci_repo_ops`
- `commit_publish_ops`
- docs maintenance workflow

## Workflow Doc Template (required in each workflow)
- What This Workflow Is For
- When To Use
- What Not To Do
- Primary Files
- Minimal Commands
- Targeted Tests
- Failure Modes and Fallback Steps
- Handoff Checklist

## Validator Requirements
Validator must fail if:
1. Required docs/workflow/tooling files are missing.
2. Manifest schema keys are missing/invalid.
3. Manifest paths do not exist.
4. Required workflow IDs are missing (including `ci_repo_ops`, `commit_publish_ops`).
5. Required section headings are missing in any workflow doc.
6. Canonical/bridge contract phrases are missing.
7. Command snippets in manifest are bash-only or non-PowerShell-safe.
8. Commit workflow doc is missing.
9. Bridge/canonical policy conflicts are detected.

## Tests
1. Validator passes in current repo.
2. Fails when required workflow file missing.
3. Fails when required workflow ID missing in manifest.
4. Fails when canonical/bridge policy phrases are removed.
5. Fails when manifest paths are broken.

Use temporary fixture directories for failure-mode tests; do not mutate real docs during tests.

## Acceptance Criteria
1. Agent docs are discoverable and role-separated.
2. Manifest routes tasks without guessing.
3. Commit requests follow strict triage/validation/push protocol.
4. Validator catches docs drift automatically.
5. Docs are concise, non-duplicative, and Windows command compatible.
6. No runtime behavior changes unless explicitly requested.

## Output
Return:
1. Changed/added files list
2. Contract summary
3. Validation commands run + results
4. Any assumptions made
```

## Customization Checklist

- Replace workflow names (`FEATURE_WORKFLOW`, `DATA_WORKFLOW`) with domain-specific names if needed.
- Confirm canonical file name if the project uses a different standard than `APP_KNOWLEDGE.md`.
- Align targeted tests to the new repo's test layout.
- Keep PowerShell command style if you are targeting Windows-first workflows.

## Update Cadence

Review/update this template when:
- your agent docs architecture changes materially
- validator contracts gain new rules
- commit/CI governance changes
