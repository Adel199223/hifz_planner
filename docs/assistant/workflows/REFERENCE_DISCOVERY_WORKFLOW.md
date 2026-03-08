# Reference Discovery Workflow

## What This Workflow Is For

Use this workflow when a feature should be inspired by or aligned with an existing app/product/site and the team needs reliable external references before implementation.

## Expected Outputs

- External references are cited with links and rationale.
- Chosen patterns are separated from local adaptations.
- Licensing/maintenance risks are documented when relevant.

## When To Use

Use when requests include:
- "like X"
- "same as X"
- "closest to X"
- parity or inspiration from a named app/service/site

Use when architecture, UX patterns, data behavior, or terminology should be grounded in real implementations.

## What Not To Do

- Don't use this workflow when the user did not request or imply external parity/inspiration. Instead use the domain workflow directly.
- Don't use this workflow as a replacement for implementation/testing workflow steps. Instead use the corresponding feature/data workflow after discovery.
- Don't use this workflow to copy code wholesale from external projects. Instead adopt pattern-level behavior with local implementation.
- Do not copy code blindly from external repositories.
- Do not rely on outdated or inactive reference projects without noting risk.
- Do not use UI-only references when backend/data behavior is in scope.
- Do not skip license compatibility checks for reused patterns/assets/code.
- Do not claim parity decisions without listing source links.

## Primary Files

- `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md`
- `docs/assistant/manifest.json`
- `AGENTS.md`
- `agent.md`
- `APP_KNOWLEDGE.md`

## Source Priority

1. Official repository/docs of the target product.
2. High-quality community repositories with active maintenance.
3. Hugging Face references only when model/data/inference behavior is relevant (or explicitly requested).

## Quality Filters

- maintenance recency
- license compatibility
- stack fit with current project
- architecture relevance to requested scope

## Minimal Commands

```powershell
git status --short
```

When external discovery is required, use web search with explicit source links in output.

## Targeted Tests

```powershell
dart run tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: no adequate reference found.
   - Report search scope and why sources were insufficient.
   - Propose conservative local implementation fallback.
2. Symptoms: candidate references conflict.
   - Rank by source priority and quality filters.
   - State chosen source and rationale explicitly.
3. Symptoms: licensing ambiguity.
   - Avoid direct reuse and stick to pattern-level adaptation.
   - Flag license uncertainty in handoff notes.

## Handoff Checklist

- source links are listed
- chosen references and rationale are stated
- adopted patterns are separated from local adaptations
- license and maintenance risks are noted when relevant
