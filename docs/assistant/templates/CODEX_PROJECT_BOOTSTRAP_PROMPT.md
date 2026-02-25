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

Dual-audience design note:
- Agent docs answer implementation/routing contracts.
- User guides answer how to use the app effectively in plain language.

Drift prevention note:
- Major feature changes should update only relevant user-guide sections plus relevant technical docs.

Support/explanation use case note:
- Generated user guides should help agents explain app behavior simply during user support.

## Master Prompt (Copy/Paste)

```md
# Cross-Project Codex Prompt (Agent Docs + Workflows Bootstrap)

You are working in a new app repository. Build an AI-first documentation system that makes third-party agents fast, accurate, and safe.

## Objectives
1. Create a canonical+bridge docs model so one source of truth exists.
2. Add machine-readable routing so automated agents can choose the right workflow quickly.
3. Add workflow runbooks for feature work, data work, CI/repo operations, docs maintenance, commit/publish hygiene, and inspiration/parity reference discovery.
4. Add validator tooling and tests that catch docs drift and policy violations.
5. Keep all commands PowerShell-compatible and avoid bash-only syntax.
6. Ensure commit requests are never handled blindly.
7. Add one canonical localization workflow and glossary so language work is consistent and non-duplicative.
8. Add one canonical workspace performance workflow and baseline doc so IDE/file-watcher performance is consistently managed.
9. Require a mandatory post-significant-change docs-sync prompt policy so assistant docs stay fresh without broad rewrites.
10. Require explicit external reference discovery policy when users request parity/inspiration from named apps/sites/products.
11. Create a user-perspective documentation track so agents can explain the app to non-coders clearly.
12. Add enforceable approval gates and worktree isolation guidance for safer execution.
13. Add Golden Principles and ExecPlans so major work stays deterministic and self-contained.

## Required Documentation Architecture
Create or update these files (adapt names to repo domain where needed):
If equivalent docs/files already exist in the repo (same or similar purpose), update/restructure/replace those existing artifacts as needed instead of duplicating them.

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
- `docs/assistant/GOLDEN_PRINCIPLES.md` (single source for enforceable mechanical rules)
- `docs/assistant/exec_plans/PLANS.md` (ExecPlan template + lifecycle rules)
- `docs/assistant/exec_plans/active/.gitkeep` (active major-work plans)
- `docs/assistant/exec_plans/completed/.gitkeep` (completed major-work plans)
- `docs/assistant/LOCALIZATION_GLOSSARY.md` (single source for localized terminology)
- `docs/assistant/PERFORMANCE_BASELINES.md` (single source for workspace performance defaults)

### User guide namespace
- `docs/assistant/features/APP_USER_GUIDE.md` (whole-app, non-coder perspective)
- `docs/assistant/features/PRIMARY_FEATURE_USER_GUIDE.md` (domain-deep non-coder guide for the app’s most critical workflow)
- These guides are explanatory/support docs, not canonical architecture truth.

### Workflow docs
- `docs/assistant/workflows/FEATURE_WORKFLOW.md` (core product workflow; rename to domain)
- `docs/assistant/workflows/DATA_WORKFLOW.md` (data/API/cache/schema workflow; rename to domain)
- `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`
- `docs/assistant/workflows/CI_REPO_WORKFLOW.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`

### Tooling
- `tooling/validate_agent_docs.dart`
- `test/tooling/validate_agent_docs_test.dart`
- `tooling/validate_workspace_hygiene.dart`
- `test/tooling/validate_workspace_hygiene_test.dart`

## Canonical Rules
1. `APP_KNOWLEDGE.md` is canonical for app-level architecture/status.
2. Bridge doc is intentionally non-identical and must defer to canonical.
3. Source code is final truth when docs conflict.
4. `AGENTS.md` is shim; `agent.md` is runbook.
5. If user says “commit”, follow commit workflow protocol before any commit.
6. Keep `main` stable: major changes must start on a new `feat/*` branch.
7. Merge to `main` via PR flow and required checks; avoid direct push to `main` for major work.
8. Keep localization terms centralized in `docs/assistant/LOCALIZATION_GLOSSARY.md`; other docs should reference it.
9. Keep workspace performance defaults centralized in `docs/assistant/PERFORMANCE_BASELINES.md`; other docs should reference it.
10. By default keep heavyweight environments/artifacts outside workspace root when feasible.
11. After significant implementation changes, always ask exactly: "Would you like me to run Assistant Docs Sync for this change now?"
12. If docs sync is approved, update only relevant assistant docs for touched scope (do not do blanket doc rewrites).
13. If user names a product/site/app for parity or inspiration, run `REFERENCE_DISCOVERY_WORKFLOW.md` before implementation decisions.
14. Technical canonical docs remain source-of-truth; user guides must defer to them when conflicts appear.
15. `AGENTS.md` and `agent.md` must include `Approval Gates`, `ExecPlans`, and `Worktree Isolation` sections.
16. ExecPlans are mandatory for major/multi-file work and optional for small isolated changes.

## Commit/Publish Workflow Requirements
In `COMMIT_PUBLISH_WORKFLOW.md`, define a strict sequence:
1. Branch safety gate (before staging):
   - for parallel threads, use `git worktree` isolation first
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

## Approval Gates Requirements
In `AGENTS.md` and `agent.md`, require `## Approval Gates` with explicit ask-before-execute triggers for:
1. destructive operations
2. risky DB/schema operations
3. force-push/history rewrite
4. publish/release/deploy
5. non-essential external network actions

## ExecPlans and Worktree Requirements
1. Require `## ExecPlans` section in `AGENTS.md` and `agent.md`.
2. Require major/multi-file work to create plan files under `docs/assistant/exec_plans/active/`.
3. Require `docs/assistant/exec_plans/PLANS.md` to define format and lifecycle.
4. Require `## Worktree Isolation` section in `AGENTS.md` and `agent.md`.
5. Require worktree guidance in CI/commit/docs-maintenance workflows.

## Manifest Requirements (`docs/assistant/manifest.json`)
Include:
- `version`
- `canonical`
- `bridges`
- `user_guides`
- `workflows[]` with:
  - `id`, `doc`, `scope`, `primary_files`, `targeted_tests`, `validation_commands`
- `global_commands`
- `contracts`
- `last_updated` (YYYY-MM-DD)

For `user_guides`, require:
- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PRIMARY_FEATURE_USER_GUIDE.md`

Add workflow IDs for:
- feature workflow
- data workflow
- localization workflow
- workspace performance workflow
- `reference_discovery`
- `ci_repo_ops`
- `commit_publish_ops`
- docs maintenance workflow

Add contract keys for:
- template read policy
- localization glossary source of truth
- workspace performance source of truth
- environment-outside-workspace default policy
- `post_change_docs_sync_prompt_policy`
- `inspiration_reference_discovery_policy`
- `golden_principles_source_of_truth`
- `execplan_policy`
- `approval_gates_policy`
- `worktree_isolation_policy`
- `doc_gardening_policy`

## Inspiration Reference Discovery Requirements
Create one dedicated workflow:
- `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`

In that workflow, require:
1. Trigger phrases include: "like X", "same as X", "closest to X", and parity requests against named products/sites/apps.
2. Source priority:
   - official product repo/docs first
   - then high-quality, actively maintained GitHub repos
   - Hugging Face only when model/data/inference scope is relevant (or user explicitly asks)
3. Output contract:
   - list selected references with links
   - explain why each was chosen
   - clearly separate adopted pattern vs local adaptation
4. Safety:
   - no blind code copying
   - license/attribution checks
   - report insufficiency and fallback strategy when references are weak

## Workspace Performance Requirements
Create one dedicated workflow and one baseline doc:
- `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- `docs/assistant/PERFORMANCE_BASELINES.md`

In that workflow, require:
1. Diagnosis first (`code --status` when available).
2. Safe watcher/search excludes in `.vscode/settings.json`.
   - apply defaults conditionally and idempotently (only when missing or conflicting).
3. Stack-conditional rules:
   - Flutter: `.dart_tool`, `build`
   - Python: `.venv`, `__pycache__`, `.pytest_cache`, `.mypy_cache`
   - Node: `node_modules`
   - add other stack outputs as needed
4. OS-conditional guidance:
   - Windows Defender exclusions for heavy generated/toolchain folders
   - macOS/Linux indexing alternatives where relevant
5. Safety migration rule:
   - never delete old environment before replacement is verified.
6. Anti-duplication:
   - exclusion/policy tables live only in `PERFORMANCE_BASELINES.md`.
7. Tooling scope rule:
   - do not add language-specific CI/tooling configuration (for example Python) unless that language is actually present in the repository build/test path.

## Workflow Doc Template (required in each workflow)
- What This Workflow Is For
- Expected Outputs
- When To Use
- What Not To Do
- Include explicit negative routing language:
  - "Don't use this workflow when..."
  - "Instead use ..."
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
4. Required workflow IDs are missing (including `ci_repo_ops`, `commit_publish_ops`, and localization workflow id).
5. Required section headings are missing in any workflow doc.
6. Any workflow doc misses `Expected Outputs`.
7. Any workflow doc misses explicit negative-routing + alternative language.
8. Canonical/bridge contract phrases are missing.
9. Command snippets in manifest are bash-only or non-PowerShell-safe.
10. Commit workflow doc is missing.
11. Bridge/canonical policy conflicts are detected.
12. Localization glossary/workflow routing contracts are missing.
13. Workspace performance workflow/baseline or routing contracts are missing.
14. Workspace hygiene validator/tooling files are missing.
15. `REFERENCE_DISCOVERY_WORKFLOW.md` is missing.
16. `reference_discovery` workflow id is missing from manifest.
17. `post_change_docs_sync_prompt_policy` or `inspiration_reference_discovery_policy` contracts are missing from manifest.
18. New contracts are missing from manifest:
   - `golden_principles_source_of_truth`
   - `execplan_policy`
   - `approval_gates_policy`
   - `worktree_isolation_policy`
   - `doc_gardening_policy`
19. `GOLDEN_PRINCIPLES.md` or `exec_plans/PLANS.md` scaffolding is missing.
20. `AGENTS.md`/`agent.md` do not enforce:
   - post-significant-change docs-sync prompt policy
   - inspiration/parity routing to `REFERENCE_DISCOVERY_WORKFLOW.md`
   - Approval Gates
   - ExecPlans
   - Worktree Isolation
21. `user_guides` key is missing from manifest.
22. Any `user_guides` path in manifest does not exist.
23. User guides are not discoverable from the docs index/routing docs.
24. Template-path routing regression protections are missing.

## Tests
1. Validator passes in current repo.
2. Fails when required workflow file missing.
3. Fails when required workflow ID missing in manifest.
4. Fails when canonical/bridge policy phrases are removed.
5. Fails when manifest paths are broken.
6. Fails when localization workflow ID or glossary contract key is missing.
7. Fails when workspace performance workflow ID or performance contract keys are missing.
8. Fails when workspace hygiene validator files are missing.
9. Fails when `reference_discovery` workflow id or discovery/docs-sync contracts are missing.
10. Fails when AGENTS/runbook policy routing phrases are removed.
11. Fails when `docs/assistant/GOLDEN_PRINCIPLES.md` is missing.
12. Fails when `docs/assistant/exec_plans/PLANS.md` is missing.
13. Fails when `Approval Gates` section is missing from AGENTS/runbook.
14. Fails when worktree isolation guidance is missing from required docs/workflows.
15. Fails when a workflow misses `Expected Outputs`.
16. Fails when a workflow misses explicit negative-routing + alternative text.
17. Fails when any required new manifest contracts are missing:
    - `golden_principles_source_of_truth`
    - `execplan_policy`
    - `approval_gates_policy`
    - `worktree_isolation_policy`
    - `doc_gardening_policy`

## CI Guidance
Ensure CI includes:
1. docs validator
2. localization validator
3. localization tests
4. workspace hygiene validator
5. workspace hygiene tests
6. targeted core regression tests

## External Source Conditional Matrix
1. If task involves model/data/inference behavior:
   - include Hugging Face discovery in reference search.
2. If task is product/UI/UX/data-flow parity without model scope:
   - prioritize official product docs/repo and GitHub references; do not require Hugging Face.
3. If no high-quality references are found:
   - report insufficiency explicitly and propose conservative local fallback.

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
5. User-guide coverage summary (what user journeys are documented)
```

## Customization Checklist

- Replace workflow names (`FEATURE_WORKFLOW`, `DATA_WORKFLOW`) with domain-specific names if needed.
- Confirm canonical file name if the project uses a different standard than `APP_KNOWLEDGE.md`.
- Align targeted tests to the new repo's test layout.
- Keep PowerShell command style if you are targeting Windows-first workflows.
- If the app is not planning-centric, rename `PRIMARY_FEATURE_USER_GUIDE.md` to the app’s most critical user workflow guide.

## Update Cadence

Review/update this template when:
- your agent docs architecture changes materially
- validator contracts gain new rules
- commit/CI governance changes
