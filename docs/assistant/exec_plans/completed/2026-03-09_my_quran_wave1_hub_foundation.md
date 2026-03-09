# ExecPlan: My Quran Wave 1 Hub Foundation

## Purpose
- Replace the placeholder My Quran screen with a real personal hub using existing local data.

## Scope
- In scope:
  - real My Quran screen with exactly three primary cards
  - shared dashboard snapshot/provider
  - lightweight last-reader snapshot shape in SharedPreferences-backed app preferences
  - focused screen and preference tests
- Out of scope:
  - persisting reader resume data from normal Reader usage
  - inline settings controls
  - saved-item previews
  - Quran Radio work

## Assumptions
- Wave 1 may read a last-reader snapshot if present, but it does not yet need to create that snapshot from Reader usage.
- My Quran should summarize and route, not duplicate Library or Settings.
- Bookmarks, notes, reciter settings, and reader preferences are the stable local data sources for this wave.

## Milestones
1. Add the Wave 1 roadmap files and shared dashboard snapshot shape.
2. Implement the My Quran three-card hub.
3. Add focused tests and run Wave 1 validation.

## Detailed Steps
1. Add the active roadmap tracker and a Wave 1 ExecPlan for the My Quran roadmap.
2. Extend app preferences/store with a lightweight last-reader snapshot shape and test coverage.
3. Add a shared My Quran dashboard snapshot/provider that combines bookmark/note counts with current app/audio preferences.
4. Replace the My Quran placeholder screen with cards for:
   - `Continue reading`
   - `Saved for later`
   - `Listening setup`
5. Add focused widget tests for:
   - useful no-history state
   - continue-reading route behavior with and without a saved snapshot
   - saved counts and listening summary rendering
6. Run the targeted Wave 1 validation set.

## Decision Log
- 2026-03-09: Keep Wave 1 read-only except for navigation.
- 2026-03-09: Use one shared dashboard provider so later waves can deepen the hub without replacing the screen structure.
- 2026-03-09: Add the last-reader snapshot shape now even though normal Reader persistence belongs to Wave 2.

## Validation
- `flutter test -j 1 -r expanded test/screens/my_quran_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Add roadmap files
- [x] Extend app preferences/store
- [x] Implement three-card My Quran hub
- [x] Add focused tests
- [x] Run Assistant Docs Sync
- [x] Run targeted validation

## Surprises and Adjustments
- 2026-03-09: Fresh-worktree Flutter bootstrap touched `pubspec.lock` before validation; the incidental churn was reverted so Wave 1 remains dependency-neutral.
- 2026-03-09: Starting overlapping Flutter commands in the same worktree hit the known local startup-lock pattern again; the trusted validation record uses sequential Flutter runs.

## Handoff
- Final state summary:
  - My Quran is now a real hub locally in the Wave 1 worktree.
  - Wave 1 remains scoped to summary cards and route shortcuts only.
  - Wave 1 validation is green:
    - `flutter test -j 1 -r expanded test/screens/my_quran_screen_test.dart`
    - `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
    - `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
    - `flutter analyze --no-fatal-infos --no-fatal-warnings`
    - `dart tooling/validate_localization.dart`
    - `dart tooling/validate_agent_docs.dart`
    - `dart tooling/validate_workspace_hygiene.dart`
  - Narrow Assistant Docs Sync is complete for canonical behavior, the assistant bridge, the non-technical app guide, and repeatable workflow issue memory.
  - The next closeout step should be PR publish.
- Follow-up risks:
  - The last-reader snapshot is only a data shape in Wave 1; Reader does not yet persist it during normal usage.
