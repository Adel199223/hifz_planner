# Project Harness Sync Workflow

## What This Workflow Is For

Use this workflow when the repo's vendored bootstrap templates should be applied to the local harness without replacing the repo-specific canon.

## Expected Outputs

- Bootstrap profile/state files stay valid.
- Local harness docs reflect the vendored bootstrap contracts where applicable.
- Repo-specific canon remains primary and is not replaced by generic bootstrap outputs.

## When To Use

Use when the user says one of these:
- `implement the template files`
- `sync project harness`
- `audit project harness`
- `check project harness`

## What Not To Do

- Do not edit `docs/assistant/templates/*` during normal local harness apply.
- Do not replace `APP_KNOWLEDGE.md`, `agent.md`, `docs/assistant/manifest.json`, or `docs/assistant/ROADMAP_ANCHOR.md` with generic bootstrap copies.
- Do not treat bootstrap adoption as runtime feature work.
- Do not auto-commit or auto-push as part of harness apply.
- Do not confuse local harness apply with global bootstrap maintenance.

## Primary Files

- `docs/assistant/HARNESS_PROFILE.json`
- `docs/assistant/HARNESS_OUTPUT_MAP.json`
- `docs/assistant/runtime/BOOTSTRAP_STATE.json`
- `docs/assistant/manifest.json`
- `AGENTS.md`
- `agent.md`
- `docs/assistant/INDEX.md`
- `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`
- `docs/assistant/templates/BOOTSTRAP_TEMPLATE_MAP.json`
- `docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md`
- `tooling/check_harness_profile.py`
- `tooling/preview_harness_sync.py`
- `tooling/validate_agent_docs.dart`

## Minimal Commands

```powershell
git status --short --branch
py -3.11 tooling/check_harness_profile.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json
py -3.11 tooling/preview_harness_sync.py --profile docs/assistant/HARNESS_PROFILE.json --registry docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json --output-map docs/assistant/HARNESS_OUTPUT_MAP.json --write-state docs/assistant/runtime/BOOTSTRAP_STATE.json
dart run tooling/validate_agent_docs.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: profile validation fails.
   - Re-check `docs/assistant/HARNESS_PROFILE.json` against `docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json`.
2. Symptoms: preview resolves outputs that should map to stronger existing repo docs.
   - Update `docs/assistant/HARNESS_OUTPUT_MAP.json` before changing canon.
3. Symptoms: bootstrap guidance conflicts with existing repo rules.
   - Keep the stronger local repo rule and encode the preservation in local docs and mappings.
4. Symptoms: templates begin to drive normal feature work directly.
   - Restore read-on-demand routing and keep bootstrap tasks explicit.
5. Symptoms: someone wants to edit `docs/assistant/templates/*`.
   - Treat that as bootstrap maintenance, not normal local harness apply.

## Handoff Checklist

- `HARNESS_PROFILE.json` reflects the chosen archetype, mode, and module overrides
- `HARNESS_OUTPUT_MAP.json` preserves stronger repo-local equivalents
- preview writes a current `docs/assistant/runtime/BOOTSTRAP_STATE.json`
- `APP_KNOWLEDGE.md`, `agent.md`, `docs/assistant/manifest.json`, and `docs/assistant/ROADMAP_ANCHOR.md` remain primary
- validator and targeted test pass

