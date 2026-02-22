# Docs Maintenance Workflow

## What This Workflow Is For

Use this workflow for maintaining agent-facing docs structure, routing clarity, and long-term consistency.

## When To Use

Use when changes touch:
- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/*`
- docs references in `README.md`
- docs validator script

## What Not To Do

- Do not let bridge docs become alternate canon.
- Do not add stale paths or commands that fail in this repo.
- Do not skip docs validation after changing documentation structure.

## Primary Files

- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `README.md`
- `docs/assistant/APP_KNOWLEDGE.md`
- `docs/assistant/DB_DRIFT_KNOWLEDGE.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/manifest.json`
- `tooling/validate_agent_docs.dart`
- `test/tooling/validate_agent_docs_test.dart`

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

## Handoff Checklist

- canonical-vs-bridge policy remains explicit
- validator passes with zero errors
- workflow docs keep required section template
- README onboarding links are in sync with assistant docs
