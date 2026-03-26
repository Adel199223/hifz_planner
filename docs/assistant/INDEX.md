# Assistant Docs Index

One-page navigation guide for agent-facing documentation.

## How To Use This Index

1. Open the row matching your task.
2. Read that document first.
3. Run the listed validator/smoke command before handoff.

For roadmap continuation or "continue where we left off" requests, open `docs/assistant/ROADMAP_ANCHOR.md` after `APP_KNOWLEDGE.md`.
For active product-direction work, also open `docs/strategy/adaptive-hifz-path-solo-master-plan.md` and `docs/roadmap/adaptive-hifz-path-solo-roadmap.md`.
For explicit HTML explainer requests, open `docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md`; that workflow will decide whether any on-demand template is needed.
For explicit bootstrap harness apply/audit requests, open `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md`; that workflow will decide when vendored bootstrap templates are in scope.

## Beginner Quick Path

1. Start with `docs/assistant/features/APP_USER_GUIDE.md`.
2. For planning or daily-assignment questions, open `docs/assistant/features/PLANNER_USER_GUIDE.md`.
3. Open `APP_KNOWLEDGE.md` only if you need technical/canonical detail.

## Agent Doc Map

| Document | Use when... | Do not use for... | Time to value |
|---|---|---|---|
| `AGENTS.md` | Your tool auto-opens `AGENTS.md` and needs immediate routing. | Deep architecture details. | 1 min |
| `agent.md` | You need the operational runbook and quick task routing matrix. | Full DB schema details. | 2 min |
| `APP_KNOWLEDGE.md` | You need canonical app architecture, feature status, and subsystem map. | Fine-grained per-workflow checklists. | 3 min |
| `docs/assistant/ROADMAP_ANCHOR.md` | You need the current Adaptive Hifz Path roadmap state, the active next milestone, or a new-chat continuation point. | Canonical app architecture or detailed per-workflow checklists. | 2 min |
| `docs/WEB_VERSION_ROADMAP.md` | You need the current web-platform rollout shape, browser-first scope, and honest Web V1 degradations. | Canonical app architecture or general mobile/desktop planning by itself. | 2 min |
| `docs/strategy/adaptive-hifz-path-solo-master-plan.md` + `docs/roadmap/adaptive-hifz-path-solo-roadmap.md` | You need the active product reset, solo-learner-first direction, and Wave 0/Wave 1 roadmap framing. | Current shipped UI details or DB internals by themselves. | 3 min |
| `docs/assistant/GOLDEN_PRINCIPLES.md` | You need enforceable style/invariant rules before implementation. | Feature-specific workflow steps. | 1 min |
| `docs/assistant/exec_plans/PLANS.md` | Work is major/multi-file and needs a self-contained execution plan format. | Small isolated fixes. | 2 min |
| `docs/assistant/APP_KNOWLEDGE.md` | Your workflow expects assistant-path docs and needs canonical pointer/bootstrapping. | Canonical truth when conflicts exist. | 1 min |
| `docs/assistant/manifest.json` | You are an automated agent selecting docs/tests programmatically. | Human narrative context. | <1 min |
| `docs/assistant/features/PLANNER_USER_GUIDE.md` | You need a thorough, non-coder explanation of planning/scheduling behavior and user decisions. | Canonical architecture, DB internals, or implementation-level scheduler logic. | 3 min |
| `docs/assistant/features/APP_USER_GUIDE.md` | You need a non-technical whole-app explainer for user guidance and support conversations. | Canonical architecture truth, schema/migration details, or implementation/runbook constraints. | 2 min |
| `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` | Task changes labels/locales/RTL/translation-resource mapping. | DB schema or non-localization feature logic. | 2 min |
| `docs/assistant/LOCALIZATION_GLOSSARY.md` | You need canonical terms across languages without duplication. | Runtime data/cache logic decisions. | 1 min |
| `docs/assistant/workflows/PERFORMANCE_WORKFLOW.md` | Task targets VS Code lag, file watchers, indexing pressure, or workspace artifact placement. | Feature/domain logic implementation details. | 2 min |
| `docs/assistant/PERFORMANCE_BASELINES.md` | You need canonical watcher/search excludes and environment placement defaults. | CI release logic or runtime architecture decisions. | 1 min |
| `docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md` | Task requires parity/inspiration from named apps/sites and external reference selection. | Direct implementation details without external-source analysis. | 2 min |
| `docs/assistant/DB_DRIFT_KNOWLEDGE.md` | You are changing schema/migrations/repos/planner persistence. | Reader-only UI behavior changes. | 3 min |
| `docs/assistant/workflows/READER_WORKFLOW.md` | Task targets Verse by Verse / Reading UI, shared Quran word rendering, and interaction parity. | Planner internals or DB migrations. | 2 min |
| `docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md` | Task targets Quran.com fetch/cache/dedupe/fonts/translations. | Navigation shell changes. | 2 min |
| `docs/assistant/workflows/PLANNER_WORKFLOW.md` | Task targets onboarding/plan/today/scheduler/calibration. | Quran.com rendering fidelity tasks. | 2 min |
| `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md` | Task targets automatic scheduling, weekly calendar generation, advanced availability, or companion staged/recitation/word-hover behavior. | Reader-only rendering or Quran.com data ingestion tasks. | 2 min |
| `docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md` | The user explicitly asks for a local HTML explainer or study guide that stays outside the shipped app. | Normal support replies, runtime feature work, or product-scope documentation. | 2 min |
| `docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md` | The user explicitly wants to apply, audit, or validate the vendored bootstrap harness in this repo. | Normal feature work, product behavior docs, or global bootstrap-template maintenance. | 2 min |
| `docs/assistant/workflows/CI_REPO_WORKFLOW.md` | Task targets CI workflow edits, branch sync/merge hygiene, and release gating commands. | Feature implementation details inside reader/planner logic. | 2 min |
| `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md` | Task starts with "commit": stage triage, ignore checks, commit message, push, and branch cleanup operations. | Feature implementation logic or schema design work. | 2 min |
| `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md` | Task changes docs structure/contracts/links. | Runtime feature implementation. | 2 min |

## Validator Command

Run after docs changes:

```powershell
dart run tooling/validate_agent_docs.dart
```

Recommended docs smoke test:

```powershell
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```
