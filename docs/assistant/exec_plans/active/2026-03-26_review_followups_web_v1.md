# ExecPlan: Review Follow-ups for Web V1

## Purpose
- Harden the Web V1 follow-up patch by fixing three review findings before the broader web work is considered ready.
- Ensure the browser database worker asset resolves correctly, the first-run starter CTA uses production planner logic, and narrow-shell titles reflect the active route.

## Scope
- In scope:
- Fix the Drift web worker URI and commit the compiled worker asset.
- Add first-unit-only starter generation APIs in the planner/generator stack.
- Rewire the release-visible starter CTA to production logic while keeping the debug helper debug-only.
- Resolve narrow app-bar titles for menu-only routes.
- Update targeted unit/widget tests and run focused validation.
- Out of scope:
- DB schema changes or new migrations.
- Route contract changes.
- Persisted preference contract changes.
- New build automation for the web worker.

## Assumptions
- The starter CTA is intentionally stricter than normal daily planning and should only appear before any memorization unit exists.
- `web/drift_worker.dart` remains the source file, and the generated `web/drift_worker.js` is committed directly in this pass.
- Existing uncommitted workspace changes outside this scope belong to the user and must be preserved.

## Milestones
1. Land production fixes for the worker asset and starter-unit generation path.
2. Land the narrow-title fix and targeted regression coverage.
3. Validate the touched scope with analyze, tests, and a web build.

## Detailed Steps
1. Create this ExecPlan and keep the assumptions, decisions, and validation commands current while implementing.
2. Update `lib/data/database/app_database_connection_factory.dart` to point web Drift at `drift_worker.js`, then compile `web/drift_worker.dart` to `web/drift_worker.js`.
3. Extend `lib/data/repositories/mem_unit_repo.dart`, `lib/data/services/new_unit_generator.dart`, and `lib/data/services/daily_planner.dart` with first-unit-safe production APIs.
4. Update `lib/data/providers/database_providers.dart` and `lib/screens/today_screen.dart` so the release starter CTA uses the new planner API, updates local state without reloading the plan, and keeps the debug helper debug-only.
5. Update `lib/app/navigation_shell.dart` to resolve narrow app-bar titles from the active route path.
6. Extend `test/data/services/new_unit_generator_test.dart`, `test/data/services/daily_planner_test.dart`, `test/screens/today_screen_test.dart`, and `test/app/navigation_shell_menu_test.dart`.
7. Run targeted validation:
   - `dart analyze lib/app/navigation_shell.dart lib/data/database/app_database_connection_factory.dart lib/data/services/daily_planner.dart lib/data/services/new_unit_generator.dart lib/screens/today_screen.dart`
   - `flutter test -j 1 -r expanded test/data/services/new_unit_generator_test.dart test/data/services/daily_planner_test.dart test/screens/today_screen_test.dart test/app/navigation_shell_menu_test.dart`
   - `flutter build web`
   - Serve `build/web` and run the Playwright smoke suite if the existing local harness is available.

## Decision Log
- 2026-03-26: Keep the worker fix simple by committing a compiled `web/drift_worker.js` asset instead of introducing new build automation in this pass.
- 2026-03-26: Reuse the production new-unit generator/planner path for the starter CTA instead of extending the debug seeding helper into release logic.
- 2026-03-26: Keep the narrow-shell patch limited to title resolution; do not change bottom-navigation selection fallback in this pass.

## Validation
- `dart analyze lib/app/navigation_shell.dart lib/data/database/app_database_connection_factory.dart lib/data/repositories/mem_unit_repo.dart lib/data/services/daily_planner.dart lib/data/services/new_unit_generator.dart lib/screens/today_screen.dart test/data/services/new_unit_generator_test.dart test/data/services/daily_planner_test.dart test/screens/today_screen_test.dart test/app/navigation_shell_menu_test.dart`
  - Passed.
- `flutter test -j 1 -r expanded test/data/services/new_unit_generator_test.dart test/data/services/daily_planner_test.dart test/screens/today_screen_test.dart test/app/navigation_shell_menu_test.dart`
  - Blocked locally by Flutter toolchain failure: `frontend_server_aot.dart.snapshot is not an AOT snapshot, it cannot be run with 'dartaotruntime'`.
- `flutter build web`
  - Passed. `build/web` was produced successfully.
- `npm run smoke` from `tooling/playwright`
  - `narrow shell stays usable` passed.
  - `plan activation persists after refresh` failed because the weekly-minutes field reset after reload.
  - `core web learner journey` failed because Today still reported `Import page metadata first`, so no `Open Companion Chain` button became available.

## Progress
- [x] Create ExecPlan and capture assumptions.
- [x] Fix worker asset wiring and compile the browser worker JS.
- [x] Add production starter-unit APIs and wire Today screen state updates.
- [x] Fix narrow-shell menu-route titles.
- [x] Update targeted tests.
- [x] Run focused validation.

## Surprises and Adjustments
- `flutter test` is not trustworthy in the current local Flutter install because the frontend compiler snapshot/runtime pairing is broken.
- The browser build succeeded, but the existing Playwright smoke suite still surfaced broader web persistence/setup issues outside the three review-follow-up fixes.

## Handoff
- Implemented the worker-path fix, starter-unit production flow, narrow-title fix, and targeted regression tests.
- `web/drift_worker.js` was generated and is ready to commit alongside the existing `web/drift_worker.dart` source.
- Follow-up is still needed on the broader web validation failures if this branch must fully satisfy the existing Playwright smoke expectations.
