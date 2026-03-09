# ExecPlan: Reader Wave 2 - Verse Study Sheet and Meaning-First Actions

## Purpose
- Add one clear verse study sheet from the Reader action flow.
- Make the default Reader study path meaning-first instead of generic extra actions.

## Scope
- In scope:
  - Verse study sheet entry from Reader verse actions
  - Existing-data study content only:
    - Arabic text
    - current translation
    - word help / transliteration where available
    - existing bookmark and note actions
  - Reader action-flow wording updates that make study clearer than generic overflow behavior
  - Focused Reader tests for the new study path
- Out of scope:
  - New tafsir or external explanation sources
  - Download/share network features
  - Library workflow changes
  - Route or schema changes

## Assumptions
- Wave 1 meaning controls are now stable on `main` and can be treated as a dependency for the study sheet.
- The study sheet should reuse existing Quran.com-backed Reader data instead of inventing a new study model.
- Bookmark and note actions remain part of the study flow because they already exist and reduce follow-up friction.

## Milestones
1. Define the verse study sheet entry point inside the current Reader action flow.
2. Build the study sheet using existing Arabic, translation, word-help, and transliteration data.
3. Reframe the verse action flow around understanding-first language.
4. Validate Wave 2 with focused Reader tests and docs-ready behavior notes.

## Detailed Steps
1. Inspect the current verse action sheet and identify the clearest stable entry point for `Study this verse`.
2. Build a study-sheet surface that uses existing Reader data only:
   - Arabic text
   - current translation
   - word help / transliteration where already available
   - bookmark and note actions
3. Keep copy/bookmark/note intact, but make the study path easier to discover than generic extra actions.
4. Add focused tests for:
   - opening the study sheet
   - showing existing meaning data
   - preserving calm fallback behavior when meaning data is unavailable
5. Run the Wave 2 validation set and prepare the branch for a narrow docs sync.

## Decision Log
- 2026-03-09: Wave 2 stays inside Reader and uses existing fetched data only.
- 2026-03-09: The study sheet is the new meaning-first action, not a separate top-level destination.

## Validation
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Start Wave 2 ExecPlan
- [x] Build the verse study sheet entry path
- [x] Show existing meaning data in the study sheet
- [x] Update focused Reader tests
- [x] Validate Wave 2
- [x] Run narrow Assistant Docs Sync
- [x] Prepare for closeout

## Surprises and Adjustments
- 2026-03-09: Fresh-worktree Flutter bootstrap touched `pubspec.lock` again before validation. The incidental lockfile churn was reverted so Wave 2 stays dependency-neutral.
- 2026-03-09: The first study-sheet assertion failed because the same translation text remained visible in the Reader behind the sheet; the focused test was tightened to the keyed study widgets instead of broad text matching.

## Handoff
- Wave 2 should end with:
  - one clear `Study this verse` path from Reader verse actions
  - a meaning-first study sheet using existing data only
  - bookmark and note actions preserved inside the study flow
  - focused Reader tests covering the new study path
- Validation completed in `/home/fa507/dev/hifz_planner_reader_wave2`:
  - `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
  - `dart tooling/validate_workspace_hygiene.dart`
- Narrow Assistant Docs Sync completed for:
  - `APP_KNOWLEDGE.md`
  - `docs/assistant/APP_KNOWLEDGE.md`
  - `docs/assistant/features/APP_USER_GUIDE.md`
- Next action in this branch:
  - close Wave 2 with commit, PR, and merge
