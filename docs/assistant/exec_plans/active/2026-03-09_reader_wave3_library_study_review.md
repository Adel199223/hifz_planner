# ExecPlan: Reader Wave 3 - Library-Connected Study Review

## Purpose
- Make saved Reader study items easier to reopen and continue from `Library`.
- Strengthen bookmarks and notes as study follow-up, not just storage.

## Scope
- In scope:
  - Library improvements tied directly to Reader study follow-up
  - More context for bookmarked and noted verses so the learner can understand why something was saved
  - Lightweight filters or grouping only if they clearly reduce friction
  - Focused Library tests and any linked Reader handoff coverage
- Out of scope:
  - Broad knowledge-management features
  - New top-level destinations
  - DB schema changes unless proven unavoidable
  - New external explanation sources

## Assumptions
- Reader Wave 2 is now stable on `main`, so `Library` can build on the new study-sheet/save-for-later flow.
- The best Wave 3 outcome is simpler study follow-up, not a more complex information-management system.
- Any grouping or filtering must stay plain-language and low-friction for non-coders.

## Milestones
1. Identify the minimum Library context missing from saved Reader study items.
2. Add Reader-study-friendly context to bookmarks and notes.
3. Add only the lightest Library organization needed to reduce friction.
4. Validate Wave 3 with focused Library and linked Reader tests.

## Detailed Steps
1. Audit the current `Library`, `Bookmarks`, and `Notes` flows from the perspective of returning to a saved study item.
2. Improve the saved-item context so a learner can tell what was saved and reopen it with less guesswork.
3. Add lightweight grouping or filters only if they directly support the study follow-up flow.
4. Add or update focused tests for the changed Library behavior.
5. Run the Wave 3 validation set and prepare for a narrow docs sync.

## Decision Log
- 2026-03-09: Wave 3 stays inside the existing `Library` surface and does not open a separate study-management area.
- 2026-03-09: Wave 3 keeps grouping and filters out of scope because Arabic verse context plus clearer study-oriented copy solves the return-to-study friction without extra UI.

## Validation
- `flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/notes_screen_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Start Wave 3 ExecPlan
- [x] Audit Library study follow-up friction
- [x] Improve saved-item context
- [x] Add focused Library tests
- [x] Validate and prepare for docs sync / closeout

## Surprises and Adjustments
- 2026-03-09: `Library` itself did not need structural changes; updating its study-oriented copy plus adding Arabic verse previews in bookmarks and notes was enough to make saved items recognizable.
- 2026-03-09: Fresh-worktree Flutter validation touched `pubspec.lock` again before the test run. The incidental lockfile churn was reverted so Wave 3 stays dependency-neutral.

## Implementation Summary
- `Library` descriptions now frame bookmarks and notes as study follow-up, not generic storage.
- Bookmarks now show a short "saved for later study" cue, an Arabic verse preview when local ayah text is available, and a study-oriented `Reopen in Reader` action label.
- Notes now show the linked Arabic verse preview in the list so the learner can reconnect a note to its verse without opening the editor first.
- No grouping or filters were added because the context improvements were sufficient for this wave.

## Validation Status
- Green on 2026-03-09:
  - `flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart`
  - `flutter test -j 1 -r expanded test/screens/notes_screen_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
  - `dart tooling/validate_workspace_hygiene.dart`
- Narrow Assistant Docs Sync completed on 2026-03-09 for:
  - `APP_KNOWLEDGE.md`
  - `docs/assistant/APP_KNOWLEDGE.md`
  - `docs/assistant/features/APP_USER_GUIDE.md`

## Handoff
- Wave 3 should end with:
  - clearer saved-study context inside `Library`
  - bookmarks and notes that are easier to reopen for continued study
  - only minimal grouping/filtering, if it proves necessary
  - focused Library tests covering the updated follow-up flow
