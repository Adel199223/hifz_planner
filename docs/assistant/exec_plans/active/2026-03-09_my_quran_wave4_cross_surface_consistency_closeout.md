# ExecPlan: My Quran Wave 4 Cross-Surface Consistency and Closeout

## Purpose
- Align learner-facing vocabulary across `My Quran`, `Library`, `Reader`, and support docs so the final My Quran roadmap state feels coherent instead of mixing `Save for later` language with `Bookmarks`.

## Scope
- In scope:
  - align learner-facing saved-study wording across `Reader`, `My Quran`, and `Library`
  - keep internal bookmark data models, routes, and storage names unchanged
  - update focused widget tests for the revised wording
  - prepare the roadmap for final closeout after Wave 4 publish
- Out of scope:
  - DB schema changes
  - route renames such as `/bookmarks`
  - new save types or Library structure changes
  - Quran Radio work

## Assumptions
- Wave 3 is merged to `main` and is the stable base for this final roadmap wave.
- The main inconsistency to fix is user-facing naming, not data architecture.
- `Save for later` remains the action language in Reader, while `Saved verses` is the clearest noun label for stored bookmark-style items in summary and Library surfaces.

## Milestones
1. Start Wave 4 with a wave-specific plan and active worktree state.
2. Align saved-study vocabulary across runtime surfaces.
3. Validate the final Wave 4 runtime and prepare for docs sync and roadmap closeout.

## Detailed Steps
1. Create the Wave 4 ExecPlan and update `docs/assistant/SESSION_RESUME.md` plus the active roadmap tracker inside this isolated worktree.
2. Update `lib/l10n/app_strings.dart` so learner-facing saved-study wording consistently uses `Save for later` and `Saved verses` where appropriate, without renaming internal bookmark data types.
3. Update the touched runtime screens so `Reader`, `My Quran`, and `Library` present one coherent saved-study vocabulary.
4. Refresh focused tests for the affected screens:
   - `test/screens/reader_screen_test.dart`
   - `test/screens/my_quran_screen_test.dart`
   - `test/screens/bookmarks_screen_test.dart`
   - `test/app/navigation_shell_menu_test.dart` if menu-facing wording changes
5. Run the targeted validation set before any docs sync or publish step.

## Decision Log
- 2026-03-09: Start Wave 4 only after Wave 3 merged and the active Wave 3 plan was archived.
- 2026-03-09: Keep the route and persistence layer stable; this wave should finish the roadmap through UI language alignment, not architecture churn.

## Validation
- `flutter test -j 1 -r expanded test/screens/my_quran_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Create Wave 4 ExecPlan
- [x] Align saved-study vocabulary across runtime surfaces
- [x] Update focused tests
- [x] Run targeted validation
- [x] Run Assistant Docs Sync

## Surprises and Adjustments
- 2026-03-09: The runtime consistency pass stayed narrower than expected because the main mismatch lived in shared strings, so most UI alignment landed without touching widget structure or routes.
- 2026-03-09: `test/widget_test.dart` still assumed an older direct-bookmark navigation path; Wave 4 updated that smoke test to use the current `Library` -> saved-verses flow instead of preserving the stale assumption.
- 2026-03-09: Fresh-worktree Flutter bootstrap touched `pubspec.lock` before validation again; the incidental churn was reverted so Wave 4 remains dependency-neutral.
- 2026-03-09: The trusted validation record uses sequential Flutter commands in this worktree.
- 2026-03-09: Narrow Assistant Docs Sync updated the canonical brief, assistant bridge, app user guide, beginner guide, and issue memory so the final saved-study vocabulary stays consistent outside runtime code too.

## Handoff
- Final state summary:
  - learner-facing saved-study wording is now aligned around `Save for later` and `Saved verses` across `Reader`, `My Quran`, `Library`, and the saved-verses screen while internal bookmark routes and storage names stay unchanged.
  - French, Portuguese, and Arabic overrides now match the new saved-verses wording for the touched Wave 4 strings instead of falling back to stale bookmark terms.
  - Narrow Assistant Docs Sync is complete for the canonical brief, assistant bridge, app user guide, beginner guide, and repeatable workflow issue memory.
  - Wave 4 implementation is complete, validated locally, and docs-synced; the next step is PR closeout.
- Follow-up risks:
  - If user-facing wording starts fighting localized terminology quality, favor localization clarity over literal English parity.
