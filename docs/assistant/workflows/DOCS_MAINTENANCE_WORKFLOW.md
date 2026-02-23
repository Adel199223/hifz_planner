# Docs Maintenance Workflow

## What This Workflow Is For

Use this workflow for maintaining agent-facing docs structure, routing clarity, and long-term consistency.

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

- Do not let bridge docs become alternate canon.
- Do not add stale paths or commands that fail in this repo.
- Do not skip docs validation after changing documentation structure.
- Do not route private template assets as default execution docs.
- Do not duplicate localization term tables across docs; keep terms canonical in `docs/assistant/LOCALIZATION_GLOSSARY.md`.
- Do not duplicate performance exclusion tables across docs; keep workspace defaults canonical in `docs/assistant/PERFORMANCE_BASELINES.md`.
- Do not run full assistant-doc rewrites after feature work unless explicitly approved; use targeted docs sync by touched scope.

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

## Significant-Change Docs Sync Policy

Significant change definition:
- behavior/UI/data-flow changes in `lib/` or `tooling/`
- multi-file feature passes
- CI/contract/workflow changes affecting developer process

Mandatory end-of-implementation prompt:
- "Would you like me to run Assistant Docs Sync for this change now?"

Relevance matrix:
- Reader/UI change -> reader workflow + canonical app sections + relevant test/docs links
- Data pipeline change -> data workflow + cache/API contract docs only
- Localization change -> localization workflow/glossary only (+ routing references if needed)
- CI/repo ops change -> CI workflow + manifest/validator only
- Template-only change -> template only unless user requests broader propagation

## Sync Order

1. Update canonical:
   - `APP_KNOWLEDGE.md`
2. Update bridge:
   - `docs/assistant/APP_KNOWLEDGE.md`
3. Update routing docs:
   - `docs/assistant/INDEX.md`
   - `docs/assistant/manifest.json`
4. Update validator and tests:
   - `tooling/validate_agent_docs.dart`
   - `tooling/validate_localization.dart`
   - `tooling/validate_workspace_hygiene.dart`
   - `test/tooling/validate_agent_docs_test.dart`
   - `test/tooling/validate_localization_test.dart`
   - `test/tooling/validate_workspace_hygiene_test.dart`
5. Update private templates only when requested:
   - `docs/assistant/templates/*`
6. For significant implementation work, ask docs-sync prompt and update only relevant files when approved.

## Handoff Checklist

- canonical-vs-bridge policy remains explicit
- validator passes with zero errors
- workflow docs keep required section template
- README onboarding links are in sync with assistant docs
- CI command examples in docs match `.github/workflows/dart.yml`
- localization terms and workspace performance defaults are maintained in their canonical docs only
- significant-change docs-sync prompt was asked and response handled
