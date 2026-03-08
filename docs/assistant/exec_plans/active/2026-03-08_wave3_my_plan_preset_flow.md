# ExecPlan: Wave 3 My Plan Preset-First Flow

## Purpose
- Turn `My Plan` into a guided setup flow that a solo learner can finish without opening advanced controls.
- Keep the existing planner engine stable while making the setup experience simpler and more trustworthy.

## Scope
- In scope:
  - Easy / Normal / Intensive preset-first setup
  - realistic time question
  - fluency question
  - simple confirmation summary
  - advanced settings gate
  - recovery and revision-only framing in plain language
  - syncing basic time inputs into scheduling preferences so preview/engine behavior matches the guided setup
  - targeted planner screen and onboarding-default tests
- Out of scope:
  - scheduler V2 replacement
  - planner health or recovery workflow UI
  - forecast or calibration redesign beyond hiding them behind `Advanced`
  - data-model or schema changes

## Assumptions
- Wave 1, post-Wave1 critical fixes, and Wave 2 are already merged to `main`.
- The existing settings fields and planning engine remain the persistence contract for this wave.
- `My Plan` should still expose power-user controls, but only after the learner opens `Advanced`.

## Milestones
1. Establish the Wave 3 tracker state and preset model.
2. Rebuild `My Plan` around guided setup and summary-first flow.
3. Rework tests so the new default path and advanced gate are both covered.
4. Validate the branch and prepare for narrow docs sync.

## Detailed Steps
1. Update `docs/assistant/exec_plans/active/2026-03-08_product_redesign_execution.md` so Wave 3 is marked active with the live branch/worktree mapping.
2. Add preset helpers in `lib/data/services/onboarding_defaults.dart` and cover them in `test/data/services/onboarding_defaults_test.dart`.
3. Refactor `lib/screens/plan_screen.dart` to:
   - load persisted plan inputs into the screen state
   - present preset, time, and fluency as the default flow
   - move profile/caps/scheduling/forecast/calibration behind an advanced gate
   - sync guided time inputs into scheduling preferences before preview and activation
4. Update `test/screens/plan_screen_test.dart` for the new guided flow, advanced expansion, and activation behavior.
5. Update `lib/l10n/app_strings.dart` for the new planner copy and run localization validation.

## Decision Log
- 2026-03-08: Wave 3 should fix the basic-input/scheduling-preferences mismatch because a preset-first flow is not trustworthy if the weekly planner still follows stale advanced defaults.
- 2026-03-08: Presets remain heuristic wrappers over the current engine rather than a new scheduling model.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter test -j 1 -r expanded test/data/services/onboarding_defaults_test.dart`
- `flutter test -j 1 -r expanded test/l10n/app_strings_test.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Mark Wave 3 active in the execution tracker
- [x] Implement preset helpers and planner UI changes
- [x] Update tests and validate branch
- [x] Run narrow Assistant Docs Sync for changed `My Plan` behavior

## Surprises and Adjustments
- The pre-Wave3 planner stored legacy time inputs separately from `schedulingPrefsJson`, which could make the weekly plan preview ignore the visible setup values.
- A transient Flutter shader write crash appeared only when two Flutter commands ran in parallel in the same worktree; sequential validation was stable.
- The narrow docs sync stayed limited to planner-facing and support-facing docs; no workflow or manifest routing changes were needed beyond the roadmap-return rule already being added in this branch.
- GitHub CI exposed one stale navigation-shell assertion that still expected the old Learn -> My Plan landing text; the fix was to assert the new guided-setup card and summary card instead.

## Handoff
- Wave 3 leaves `My Plan` usable without expert knowledge while preserving the existing advanced tools for later waves.
- Branch is ready for commit, PR, and merge after the validation gate stays green.
