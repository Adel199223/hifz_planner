# ExecPlan: My Quran Dashboard Surface

## Purpose
- Replace the placeholder `My Quran` screen with a useful dashboard built from existing local data.
- Give the global menu a real personal-home surface without adding new routes or schema.

## Scope
- In scope:
- add a small overview service/provider for `My Quran` snapshot data
- replace the placeholder screen with a dashboard that shows counts, next cursor context, and quick actions
- add targeted screen tests
- Out of scope:
- `Quran Radio` implementation
- new tables, migrations, or route changes
- docs sync in this milestone unless explicitly requested after implementation

## Assumptions
- `My Quran` should stay local-first and reuse existing bookmark/note/progress/schedule/lifecycle data.
- A snapshot dashboard is sufficient; no always-live stream graph is required in this phase.
- Navigation should route users into existing screens rather than duplicating their full behavior.

## Milestones
1. Add a `MyQuranOverviewService` and provider.
2. Replace `MyQuranScreen` placeholder with dashboard UI and navigation actions.
3. Add targeted tests and run validation.

## Detailed Steps
1. Query bookmark, note, memorization, due-review, and Stage-4-due counts from existing tables/repos.
2. Include next cursor verse/page context and small recent bookmark/note previews.
3. Add quick actions into Today, Plan, Bookmarks, Notes, and Reader-from-cursor.
4. Add screen tests for populated and empty dashboard states.
5. Run targeted tests plus analyzer/localization validation.

## Decision Log
- 2026-03-11: Scope is `My Quran` only; `Quran Radio` remains a later milestone.
- 2026-03-11: The dashboard is a launch surface into existing screens, not a duplicate manager for bookmarks/notes/planner.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/screens/my_quran_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `dart run tooling/validate_localization.dart`

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three

## Surprises and Adjustments
- The existing repo surface already had enough local data for a useful dashboard, so a dedicated overview service was enough; no schema or route work was needed.
- `My Quran` needed stable test keys for stats, resume actions, and preview rows because navigation-shell tests only proved route reachability, not dashboard behavior.

## Handoff
- Added `MyQuranOverviewService` and provider to gather counts, cursor context, and recent bookmark/note previews from existing local data.
- Replaced the `My Quran` placeholder with a dashboard that links users back into Reader, Today, Plan, Bookmarks, and Notes.
- Validation passed for analyzer, the new My Quran screen suite, existing navigation-shell menu coverage, and localization consistency.
