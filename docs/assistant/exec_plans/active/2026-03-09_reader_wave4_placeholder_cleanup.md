# ExecPlan: Reader Wave 4 - Placeholder Cleanup and Cross-Surface Consistency

## Purpose
- Remove or hide Reader study placeholders that still create false expectations.
- Align Reader, Library, and user-facing study vocabulary to one consistent understanding-first language.

## Scope
- In scope:
  - Hide or remove unfinished Reader study actions that this roadmap does not implement
  - Align Reader and Library wording around meaning, word help, translation, and saved-for-later study
  - Narrow user-facing consistency fixes tied directly to the Reader understanding flow
  - Focused Reader and Library regression coverage for any changed actions or labels
- Out of scope:
  - New tafsir or external explanation sources
  - Download/share infrastructure
  - New top-level destinations
  - DB schema changes

## Assumptions
- Wave 1 through Wave 3 are now stable on `main`, so Wave 4 can focus on cleanup and consistency instead of reopening earlier feature scope.
- The best Wave 4 outcome is a more truthful Reader/Library experience, not a broader study-feature expansion.
- Any placeholder removal must preserve currently working reading, bookmarking, note, and study-sheet flows.

## Milestones
1. Identify unfinished Reader study placeholders that still create false expectations.
2. Remove or hide only the placeholders this roadmap does not implement.
3. Align Reader, Library, and support wording to one consistent vocabulary.
4. Validate Wave 4 with focused Reader and Library coverage.

## Detailed Steps
1. Audit the current Reader actions and supporting Library language for unfinished understanding-related placeholders.
2. Remove or hide the misleading actions while preserving working study flows.
3. Align the touched strings and help text around:
   - meaning
   - word help
   - translation
   - saved for later
4. Update focused tests for the changed Reader and Library behavior.
5. Run the Wave 4 validation set and prepare for a narrow docs sync.

## Decision Log
- 2026-03-09: Wave 4 starts only after Wave 3 has been fully merged and archived on `main`.
- 2026-03-09: Wave 4 remains cleanup-and-consistency work, not a hidden expansion into download/share/tafsir infrastructure.

## Validation
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/notes_screen_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Start Wave 4 ExecPlan
- [ ] Audit Reader placeholder friction
- [ ] Remove or hide misleading placeholders
- [ ] Align cross-surface vocabulary
- [ ] Validate and prepare for docs sync / closeout

## Surprises and Adjustments
- Use this section for blockers, scope corrections, or test-loop issues discovered during implementation.

## Handoff
- Wave 4 should end with:
  - fewer misleading Reader study placeholders
  - one consistent study vocabulary across Reader and Library
  - no route, schema, or data-source expansion
  - focused regression coverage for the cleaned-up understanding flow
