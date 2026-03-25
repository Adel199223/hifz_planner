# ExecPlan: Wave 1 Guided Daily Hifz Path

## Purpose
- Turn Today into a clearer guided daily Hifz Path for solo learners without rebuilding the scheduler, reader, or companion flow.

## Scope
- In scope:
- Add a pure TodayPath adapter over current planner outputs.
- Reorder Today around one obvious next action, path mode, guided queue sections, and a calmer summary.
- Rewrite visible self-grading labels in plain solo-learner language.
- Add targeted tests for the adapter and Today screen.
- Out of scope:
- DB migrations or new schema.
- Scheduler rewrite.
- Reader or companion-chain rebuild.
- Large accessibility/settings refactors.

## Assumptions
- `TodayPlan` stays the source of truth for review pressure, recovery mode, Stage-4 blocking, and planned work.
- `/my-quran` is the safest fallback resume surface already present in the repo.
- Keeping five visible grade buttons is lower risk than changing scheduler-facing q-values.

## Milestones
1. Add the TodayPath adapter and queue derivation.
2. Rework Today into the guided path layout.
3. Update localization and targeted tests.

## Detailed Steps
1. Create a pure adapter next to Today that derives mode, new-state, queue slices, and next-step priority from `TodayPlan` plus the current remaining lists.
2. Rebuild Today around the adapter while preserving existing row widgets, reader routes, companion routes, and Stage-4 behavior.
3. Update localization strings for guided-path copy and plain-language grading labels.
4. Add a focused adapter test file and extend Today screen tests for next-step, locked-state, and guided ordering behavior.
5. Run only the targeted Flutter and localization validation commands for the touched area.

## Decision Log
- 2026-03-25: Keep the current 5-button grading shape and only rewrite labels to avoid destabilizing scheduler compatibility.
- 2026-03-25: Keep Stage-4 in its existing dedicated section and derive the guided queue from remaining review/new items instead of changing planner data shape.
- 2026-03-25: Use `/my-quran` as the fallback resume path because the repo already exposes a stable resume card there.

## Validation
- `flutter test -j 1 -r expanded test/screens/today_path_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `dart run tooling/validate_localization.dart`
- `flutter analyze lib/screens/today_screen.dart lib/screens/today_path.dart lib/l10n/app_strings.dart test/screens/today_path_test.dart test/screens/today_screen_test.dart`

## Progress
- [x] Add TodayPath adapter
- [x] Rework Today layout
- [x] Update localization strings
- [x] Update targeted tests
- [x] Run targeted validation

## Surprises and Adjustments
- `dart run tooling/validate_localization.dart` passed.
- `flutter analyze ...` passed on the touched files.
- The targeted `flutter test` attempts hit machine-level Flutter toolchain problems rather than code failures:
- one run failed while trying to download Flutter engine metadata (`engine_stamp.json`, 404)
- one run timed out without returning test results
- one run failed while updating the cached Flutter engine stamp in PowerShell

## Handoff
- Expected result: Today becomes a guided daily memorization entry while keeping the current planner and companion engine intact.
- The new adapter lives in `lib/screens/today_path.dart`.
- Today now renders a next-step card, path-mode card, guided review queue, optional new section, and summary card without changing planner or DB contracts.
