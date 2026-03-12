# Docs Maintenance Workflow

## What This Workflow Is For

Use this workflow for maintaining agent-facing docs structure, routing clarity, and long-term consistency.

## Expected Outputs

- Canonical/bridge/routing docs remain coherent and validated.
- Docs contracts and validators stay aligned.
- No stale paths or routing regressions remain.

## When To Use

Use when changes touch:
- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/*`
- `.github/workflows/dart.yml`
- docs references in `README.md`
- docs validator script

## What Not To Do

- Don't use this workflow when the task is runtime feature implementation edits. Instead use the relevant feature/data workflow.
- Don't use this workflow for commit-stage/publish requests. Instead use `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`.
- Don't use this workflow to bypass targeted docs sync scope after feature work. Instead apply only touched-scope updates.
- Do not rewrite entire user guides when only one user journey changed; update touched sections only.
- Do not replace plain-language user-guide support guidance with implementation jargon; preserve exact support scope boundaries.
- Do not remove beginner-focused sections (`Quick Start`, `Terms in Plain English`) when updating support-facing guides.
- Do not mix runtime implementation files into the docs-only sync commit for a major stage.
- Do not let bridge docs become alternate canon.
- Do not add stale paths or commands that fail in this repo.
- Do not skip docs validation after changing documentation structure.
- Do not route private template assets as default execution docs.
- Do not duplicate localization term tables across docs; keep terms canonical in `docs/assistant/LOCALIZATION_GLOSSARY.md`.
- Do not duplicate performance exclusion tables across docs; keep workspace defaults canonical in `docs/assistant/PERFORMANCE_BASELINES.md`.
- Do not run full assistant-doc rewrites after feature work unless explicitly approved; use targeted docs sync by touched scope.
- Do not auto-push as part of the default docs-sync closeout sequence.

## Primary Files

- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `README.md`
- `.github/workflows/dart.yml`
- `docs/assistant/APP_KNOWLEDGE.md`
- `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/manifest.json`
- `docs/assistant/LOCALIZATION_GLOSSARY.md`
- `docs/assistant/PERFORMANCE_BASELINES.md`
- `docs/assistant/workflows/CI_REPO_WORKFLOW.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md`
- `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`
- `tooling/validate_agent_docs.dart`
- `tooling/validate_localization.dart`
- `tooling/validate_workspace_hygiene.dart`
- `test/tooling/validate_agent_docs_test.dart`
- `test/tooling/validate_localization_test.dart`
- `test/tooling/validate_workspace_hygiene_test.dart`

## Minimal Commands

```powershell
git worktree list
git status --short
rg -n "Canonical|Doc Sync Rule|workflow|manifest|validator" AGENTS.md agent.md APP_KNOWLEDGE.md docs/assistant README.md
dart run tooling/validate_agent_docs.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: agents read conflicting instructions.
   - Ensure root `APP_KNOWLEDGE.md` states canonical contract explicitly.
2. Symptoms: automation cannot route tasks.
   - Verify `docs/assistant/manifest.json` keys and file paths.
3. Symptoms: docs contain broken links/paths.
   - Run validator and fix failing references.
4. Symptoms: docs drift after feature changes.
   - Update canonical file first, then bridge/index/manifest/workflows.
5. Symptoms: no docs updates were requested after significant change.
   - Ask: "Would you like me to run Assistant Docs Sync for this change now?"
   - If declined, record brief drift warning.
6. Symptoms: parallel doc refactors conflict repeatedly.
   - perform each stream in isolated `git worktree` to reduce merge contention.
7. Symptoms: support docs become too technical for non-coders.
   - restore plain-language wording and keep canonical-deference boundaries explicit.
8. Symptoms: user guides use unexplained technical terms.
   - add or refresh `Terms in Plain English` and keep definitions short.

## Significant-Change Docs Sync Policy

Significant change definition:
- behavior/UI/data-flow changes in `lib/` or `tooling/`
- multi-file feature passes
- CI/contract/workflow changes affecting developer process

Mandatory end-of-implementation prompt:
- "Would you like me to run Assistant Docs Sync for this change now?"

Default major-stage closeout order:
1. Finish implementation and targeted validation.
2. Commit implementation files first.
3. Ask the exact Assistant Docs Sync prompt.
4. If approved, update only relevant assistant docs for touched scope.
5. Commit docs changes separately as a docs-only commit.
6. End with a clean local worktree.
7. Push remains explicit.

Relevance matrix:
- Reader/UI change -> reader workflow + canonical app sections + relevant test/docs links
- Data pipeline change -> data workflow + cache/API contract docs only
- Localization change -> localization workflow/glossary only (+ routing references if needed)
- CI/repo ops change -> CI workflow + manifest/validator only
- Template-only change -> template only unless user requests broader propagation
- User-facing behavior copy/flow change -> update affected sections in `docs/assistant/features/APP_USER_GUIDE.md` and/or `docs/assistant/features/PLANNER_USER_GUIDE.md`

## Sync Order

1. For post-implementation stage closeout, ensure the implementation commit already exists and Assistant Docs Sync is approved before editing docs.
2. Update canonical:
   - `APP_KNOWLEDGE.md`
3. Update bridge:
   - `docs/assistant/APP_KNOWLEDGE.md`
4. Update routing docs:
   - `docs/assistant/INDEX.md`
   - `docs/assistant/manifest.json`
5. Update validator and tests:
   - `tooling/validate_agent_docs.dart`
   - `tooling/validate_localization.dart`
   - `tooling/validate_workspace_hygiene.dart`
   - `test/tooling/validate_agent_docs_test.dart`
   - `test/tooling/validate_localization_test.dart`
   - `test/tooling/validate_workspace_hygiene_test.dart`
6. Update private templates only when requested:
   - `docs/assistant/templates/*`
7. Keep docs-sync changes in their own docs-only commit and leave push as a separate explicit action.

## Handoff Checklist

- canonical-vs-bridge policy remains explicit
- validator passes with zero errors
- workflow docs keep required section template
- README onboarding links are in sync with assistant docs
- CI command examples in docs match `.github/workflows/dart.yml`
- localization terms and workspace performance defaults are maintained in their canonical docs only
- significant-change docs-sync prompt was asked and response handled
- major-stage closeout kept implementation and docs sync in separate commits when docs sync ran
- worktree isolation was used when multiple doc streams ran in parallel
- relevant user-guide sections were updated or explicitly deemed unchanged
- touched user-guide sections remain understandable to non-technical readers and still defer to canonical docs
- beginner-focused sections (`Quick Start`, `Terms in Plain English`) were updated or explicitly confirmed unchanged
