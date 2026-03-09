# ExecPlan: Reader Understanding Execution Tracker

## Purpose
- Keep the Reader understanding roadmap durable inside the repo.
- Track the live execution order for the four Reader-focused waves.
- Provide one file to return to after interruptions, bugfix detours, or publish steps.

## Scope
- In scope:
  - Wave 1 through Wave 4 status tracking
  - Branch and worktree mapping
  - Current blockers
  - Detours and plan updates
  - Next recommended action
  - Links to the supporting roadmap definition
- Out of scope:
  - Replacing wave-specific ExecPlans
  - Detailed implementation steps for each wave

## Assumptions
- The earlier planner, Practice from Memory, and Goals + Progress roadmaps are complete and now serve as historical context.
- This is a new roadmap focused on Reader understanding using existing Quran.com translation, word-translation, transliteration, bookmark, and note data.
- Reader and Library remain the only product surfaces touched by this roadmap.
- Route stability and schema stability are preferred; local preference additions are acceptable if they use the existing SharedPreferences path.

## Milestones
1. Start and complete Wave 1 real Reader meaning controls.
2. Start and complete Wave 2 verse study sheet and meaning-first actions.
3. Start and complete Wave 3 Library-connected study review.
4. Start and complete Wave 4 placeholder cleanup and cross-surface consistency.
5. Close the roadmap and define the next backlog.

## Detailed Steps
1. Start Wave 1 on an isolated worktree and add a wave-specific ExecPlan.
2. Keep Wave 1 focused on persistent Reader meaning controls using existing local preferences and existing Quran.com data.
3. Start Wave 2 only after Wave 1 closes so verse study actions can build on stable meaning controls.
4. Keep Wave 3 integrated with Library instead of opening a new study destination.
5. Use Wave 4 to remove or hide unfinished Reader study placeholders that this roadmap does not replace.

## Decision Log
- 2026-03-08: Start a new roadmap instead of extending the completed Goals + Progress roadmap.
- 2026-03-08: Keep the roadmap understanding-first, not audio/download/share-first.
- 2026-03-08: Use existing Quran.com translation and word data only; do not add a tafsir source in this roadmap.
- 2026-03-08: Keep the work integrated into Reader and Library with no new top-level destination.

## Validation
- For each active wave, run the focused screen and service tests listed in that wave's ExecPlan.
- Run `dart tooling/validate_agent_docs.dart` after tracker or ExecPlan updates.
- Run `dart tooling/validate_localization.dart` when wave work changes learner-facing wording.

## Progress
- [x] Start Wave 1
- [x] Merge Wave 1
- [x] Start Wave 2
- [x] Merge Wave 2
- [x] Start Wave 3
- [ ] Merge Wave 3
- [ ] Start Wave 4
- [ ] Merge Wave 4
- [ ] Close the roadmap

## Surprises and Adjustments
- Use this section for sequence changes, blockers, or scope corrections discovered during implementation.

## Roadmap Return Protocol

- After every substantial closeout, explicitly report:
  - current roadmap status
  - exact next step by wave or stage name
- When research stages are already complete, say exactly:
  - `All research stages are complete; implementation continues by wave.`
- After any detour for bugfixes, tooling, docs, or environment:
  1. update the active wave ExecPlan first
  2. update this tracker second
  3. resume from this tracker unless it records a new sequence
- Every roadmap closeout message must end with:
  - `Next step: Wave X - <name>`
- If the next action is closeout instead of a new wave, end with:
  - `Next step: close Wave X with <closeout action>`

## Handoff
- Roadmap order:
  - Wave 1: Real Reader Meaning Controls
  - Wave 2: Verse Study Sheet and Meaning-First Actions
  - Wave 3: Library-Connected Study Review
  - Wave 4: Placeholder Cleanup and Cross-Surface Consistency
- Related context:
  - `APP_KNOWLEDGE.md`
  - `docs/assistant/features/APP_USER_GUIDE.md`
  - `docs/assistant/features/PLANNER_USER_GUIDE.md`
- Wave status:

| Stream | Status | Branch | Worktree | Notes |
|---|---|---|---|---|
| Previous planner roadmap | merged | historical | removed | Wave 1-7 completed before this roadmap started |
| Practice from Memory roadmap | merged | historical | removed | Focused 4-wave practice roadmap completed before this roadmap started |
| Goals + Progress roadmap | merged | historical | removed | Supportive 4-wave goals roadmap completed before this roadmap started |
| Reader Wave 1 | merged | historical | removed | Persistent Reader meaning controls are now in `main` after PR `#33`; closeout cleanup was corrected in PR `#35` |
| Reader Wave 2 | merged | historical | removed | Verse study sheet and meaning-first actions are now in `main` after PR `#36` and closeout PR `#37` |
| Reader Wave 3 | active | `feat/reader-wave3-library-study-review` | `/home/fa507/dev/hifz_planner_reader_wave3` | Library-connected study review is implemented locally and ready for docs sync / closeout |

- Current blockers:
  - No blocker is recorded at roadmap start.
- Detours and plan updates:
  - 2026-03-08: New roadmap opened after the planner, practice, and goals roadmaps completed.
  - 2026-03-08: Wave 1 started in isolated worktree `/home/fa507/dev/hifz_planner_reader_wave1` on branch `feat/reader-wave1-meaning-controls`.
  - 2026-03-08: Wave 1 now adds persistent Reader meaning preferences, real Translation and Word by Word settings panes, translation visibility control, and transliteration-aware preview/popover details while keeping routes, caches, and schema unchanged.
  - 2026-03-08: Wave 1 validation is green in the isolated worktree:
    - `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
    - `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
    - `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
    - `flutter analyze --no-fatal-infos --no-fatal-warnings`
    - `dart tooling/validate_localization.dart`
    - `dart tooling/validate_agent_docs.dart`
    - `dart tooling/validate_workspace_hygiene.dart`
  - 2026-03-08: Fresh-worktree Flutter bootstrap touched `pubspec.lock` again before validation; the incidental churn was reverted so Wave 1 remains dependency-neutral.
  - 2026-03-08: Narrow Assistant Docs Sync completed for the canonical brief, assistant bridge, and app user guide so future restarts do not need to reconstruct the Reader meaning-controls scope from source diffs.
  - 2026-03-08: Wave 1 feature work merged to `main` in PR `#33`.
  - 2026-03-09: Wave 1 closeout merged in PR `#34`, then a follow-up docs fix PR `#35` removed the accidentally duplicated active Wave 1 plan so the roadmap state is clean again on `main`.
  - 2026-03-09: Wave 2 started in isolated worktree `/home/fa507/dev/hifz_planner_reader_wave2` on branch `feat/reader-wave2-verse-study-sheet`.
  - 2026-03-09: Wave 2 now adds a meaning-first `Study this verse` path from the Reader action sheet, backed by one verse study sheet that uses existing Arabic text, current translation, available word help/transliteration, and existing bookmark/note actions.
  - 2026-03-09: Wave 2 validation is green in the isolated worktree:
    - `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
    - `flutter analyze --no-fatal-infos --no-fatal-warnings`
    - `dart tooling/validate_localization.dart`
    - `dart tooling/validate_agent_docs.dart`
    - `dart tooling/validate_workspace_hygiene.dart`
  - 2026-03-09: Fresh-worktree Flutter bootstrap touched `pubspec.lock` again before validation; the incidental churn was reverted so Wave 2 remains dependency-neutral.
  - 2026-03-09: Narrow Assistant Docs Sync completed for the canonical brief, assistant bridge, and app user guide so the study-sheet flow is documented without reopening the source diff.
  - 2026-03-09: Wave 2 feature work merged to `main` in PR `#36`.
  - 2026-03-09: Wave 2 closeout merged in PR `#37`.
  - 2026-03-09: Wave 3 started in isolated worktree `/home/fa507/dev/hifz_planner_reader_wave3` on branch `feat/reader-wave3-library-study-review`.
  - 2026-03-09: Wave 3 now makes Library study follow-up clearer without adding new destinations or filters:
    - `Library` descriptions now frame bookmarks and notes as study follow-up.
    - Bookmarks now show an Arabic verse preview when local ayah text exists, a saved-for-later-study cue, and a clearer `Reopen in Reader` action.
    - Notes now show the linked Arabic verse preview directly in the list so saved study items are easier to recognize.
  - 2026-03-09: Wave 3 validation is green in the isolated worktree:
    - `flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart`
    - `flutter test -j 1 -r expanded test/screens/notes_screen_test.dart`
    - `flutter analyze --no-fatal-infos --no-fatal-warnings`
    - `dart tooling/validate_localization.dart`
    - `dart tooling/validate_agent_docs.dart`
    - `dart tooling/validate_workspace_hygiene.dart`
  - 2026-03-09: Fresh-worktree Flutter bootstrap touched `pubspec.lock` again before validation; the incidental churn was reverted so Wave 3 remains dependency-neutral.
  - 2026-03-09: Narrow Assistant Docs Sync completed for the canonical brief, assistant bridge, and app user guide so the Library saved-study follow-up flow is documented without widening into unrelated planner docs.
- Next recommended action:
  - close Wave 3 with docs sync and PR merge
