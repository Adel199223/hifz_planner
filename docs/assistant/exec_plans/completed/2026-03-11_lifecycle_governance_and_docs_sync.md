# ExecPlan: Lifecycle Governance and Targeted Assistant Docs Sync

## Purpose
- Extend lifecycle handling beyond first promotion so scheduled reviews can maintain or lower lifecycle tiers deterministically.
- Sync assistant-facing docs and user guides to the implemented Stage-5 maintenance behavior.

## Scope
- In scope:
- extend `ReviewCompletionService` result contract and tier transitions
- add lifecycle-aware Today review rows and ordering
- update targeted canonical/workflow/user-guide docs and routing metadata
- add tests and validators for code + docs sync
- Out of scope:
- new routes or launch modes
- schema changes or Drift codegen
- automatic Stage-4 reopen or new strengthening queues
- broader product-surface completion

## Assumptions
- `stable + q>=3 -> maintained`
- `maintained + q>=4 -> maintained`
- `maintained + q=3 -> stable`
- `stable|maintained + q<3 -> ready`
- `ready` never auto-promotes from scheduled review
- Today/planner reaction remains light-touch: badges and ordering only

## Milestones
1. Extend lifecycle review completion contract and planner review row model.
2. Wire Today and Companion UI to the richer lifecycle result.
3. Apply targeted Assistant Docs Sync and validate docs/tests.

## Detailed Steps
1. Extend `ReviewCompletionService` with lifecycle before/after fields and full demotion rules.
2. Replace `TodayPlan.plannedReviews` row type with a lifecycle-aware wrapper and adjust Today ordering/badge rendering.
3. Update Companion summary messaging to reflect maintain/demotion outcomes without re-querying.
4. Update `APP_KNOWLEDGE.md`, `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`, `docs/assistant/DB_DRIFT_KNOWLEDGE.md`, `docs/assistant/features/APP_USER_GUIDE.md`, `docs/assistant/features/PLANNER_USER_GUIDE.md`, `docs/assistant/manifest.json`, and `docs/assistant/LOCALIZATION_GLOSSARY.md`.
5. Run targeted tests plus docs validation.

## Decision Log
- 2026-03-11: Lifecycle governance is demotion-only in this phase; no Stage-4 reopen.
- 2026-03-11: `maintained` is stricter than ordinary pass quality; `q=3` demotes to `stable`.
- 2026-03-11: Docs Sync is targeted to touched companion/planner assistant docs only.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/review_completion_service_test.dart`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `dart run tooling/validate_localization.dart`
- `dart run tooling/validate_agent_docs.dart`
- `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three

## Surprises and Adjustments
- `DailyPlanner` already had a partial `PlannedReviewRow` refactor in place, but the collection and empty-state types still used `DueUnitRow`; the lifecycle-aware wrapper had to be completed before UI work.
- The localization glossary still described the old three-tier Stage-4 snapshot; it needed a targeted refresh so docs and strings agreed on `maintained`.

## Handoff
- `ReviewCompletionService` now owns scheduled-review lifecycle transitions for both Today and Companion review saves.
- Today review rows now carry lifecycle tier metadata for badge rendering and overdue tie-breaking.
- Assistant docs and user guides now describe Stage-5 as an implemented maintenance overlay on scheduled reviews, including demotion-only governance and no Stage-4 reopen.
