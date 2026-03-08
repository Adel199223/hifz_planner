# ExecPlan: Wave 2 Today Coaching

## Purpose
- Turn `Today` into a guided daily coaching surface without changing planner or scheduler contracts.

## Scope
- In scope:
  - top coaching card
  - `Do this next`
  - `Why it matters today`
  - short-day / minimum-day guidance
  - clearer delayed-check explanation
  - empty state and completion state
  - visible recovery entry point from `Today`
  - targeted Today screen tests
- Out of scope:
  - scheduler replacement
  - preset-first `My Plan` redesign
  - planner data-model changes
  - forecast or calibration redesign

## Assumptions
- Wave 1 and the post-Wave1 critical fixes are already merged to `main`.
- Wave 2 should use existing planner outputs and routing instead of inventing new planner state.
- New user-facing copy can be added through `AppStrings` without changing current route contracts.

## Milestones
1. Add the coaching layer to `Today`.
2. Add the new Today states and recovery entry point.
3. Update docs and tests for the new Today behavior.

## Detailed Steps
1. Replace the raw metric-heavy Today header with a coaching card driven by stage-4, review, new-work, and no-work priorities.
2. Add a short-day hint and a recovery entry path that routes to `My Plan`.
3. Add clearer delayed-check explanation text to the Stage 4 section.
4. Add empty and completion cards based on current Today data.
5. Extend `today_screen_test.dart` with action-priority and state-transition coverage.
6. Narrow-sync the app behavior docs for the new Today home experience.

## Decision Log
- 2026-03-08: Keep Wave 2 UI-only and reuse existing Today planner outputs rather than mixing in Wave 3 planner redesign work.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/l10n/app_strings_test.dart`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Add Today coaching card and state-specific guidance
- [x] Add/refresh targeted Today tests
- [ ] Validate and publish branch

## Surprises and Adjustments
- Record any missing Today planner inputs that would force Wave 3 or Wave 4 logic to move earlier.

## Handoff
- Wave 2 should merge before starting the preset-first `My Plan` redesign in Wave 3.
