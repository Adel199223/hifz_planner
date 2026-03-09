# ExecPlan: Wave 1 Navigation and Copy Simplification

## Purpose
- Implement the first low-risk UX wave from the staged redesign program.
- Reduce first-run cognitive load without changing planner or scheduler behavior.

## Scope
- In scope:
  - simplify primary navigation labels and grouping
  - create a `Library` hub for bookmarks and notes
  - use the existing drawer as the `More` surface
  - demote secondary destinations from the main daily path
  - hide obvious unfinished Reader actions from the default surface
  - update targeted tests for the new navigation shape
- Out of scope:
  - planner algorithm changes
  - recovery logic changes
  - forecast/calibration behavior changes
  - schema changes

## Assumptions
- This wave should be source-compatible with the current routes wherever practical.
- Bookmarks and Notes remain functional standalone routes even if they are no longer top-level rail destinations.
- Secondary surfaces like Learn, My Quran, and Quran Radio remain accessible, but should be visually demoted.

## Milestones
1. Rework navigation structure and add the Library hub.
2. Simplify More drawer grouping and labels.
3. Hide unfinished Reader actions and update targeted tests.

## Detailed Steps
1. Update navigation models and shell:
   - `lib/app/nav_destination.dart`
   - `lib/app/navigation_providers.dart`
   - `lib/app/navigation_shell.dart`
   - `lib/app/router.dart`
2. Add Library hub screen:
   - `lib/screens/library_screen.dart`
3. Update strings:
   - `lib/l10n/app_strings.dart`
4. Hide unfinished Reader actions:
   - `lib/screens/reader_screen.dart`
5. Update targeted tests:
   - `test/app/navigation_shell_menu_test.dart`
   - add a focused library screen test if needed
   - update reader tests only if impacted by visible-action changes
6. Validate with targeted tests and docs/workspace validators.

## Decision Log
- 2026-03-08: Chose to keep the drawer and reinterpret it as `More` instead of inventing a second navigation surface.
- 2026-03-08: Chose a Library hub over immediately merging bookmarks and notes into a single data screen to keep risk low.

## Validation
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`

## Progress
- [x] Rework navigation structure and add Library hub
- [x] Simplify More drawer grouping and labels
- [x] Hide unfinished Reader actions
- [x] Update targeted tests
- [x] Run validators and targeted tests

## Surprises and Adjustments
- `flutter test` could not start because the local WSL Flutter toolchain still points to a missing SDK binary at `/mnt/c/dev/tools/flutter/bin/cache/dart-sdk/bin/dart`.
- Used the existing drawer as the `More` surface instead of adding a second secondary-navigation route because it is lower risk and already fits the Stage 2 target.

## Handoff
- End state should be a clearer Wave 1 navigation model with no planner-behavior changes.
