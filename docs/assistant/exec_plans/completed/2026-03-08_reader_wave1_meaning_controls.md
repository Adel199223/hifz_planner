# ExecPlan: Reader Wave 1 - Real Reader Meaning Controls

## Purpose
- Replace the Reader's placeholder meaning settings with real, persistent controls.
- Make existing translation, word-help, and transliteration data usable without changing routes, caches, or schema.

## Scope
- In scope:
  - Persistent Reader study preferences
  - Real Translation and Word by Word settings panes
  - Reader UI changes that hide/show verse translation, word help, and transliteration
  - Focused Reader and app-preference tests
- Out of scope:
  - New tafsir/external explanation sources
  - Verse study sheet flow
  - Library workflow changes
  - Download/share/audio placeholder replacement

## Assumptions
- Verse translation should stay visible by default because it is already part of the current Reader behavior.
- Word help should stay enabled by default because it already exists as tooltip behavior.
- Transliteration should default to hidden to avoid broadening the Reader's default visual footprint.
- Local SharedPreferences are the correct persistence path for these settings.

## Milestones
1. Add persistent Reader meaning preferences.
2. Replace placeholder Reader settings panes with real controls.
3. Apply the controls to verse translation, word-help, and transliteration rendering.
4. Validate Wave 1 with focused Reader and preferences tests.

## Detailed Steps
1. Extend app preferences state/store/tests with Reader meaning flags and save/load methods.
2. Add a durable Reader roadmap tracker and keep this Wave 1 plan updated during implementation.
3. Replace the Reader Translation settings placeholder with a real settings body:
   - show/hide verse translation
   - current translation follows app language
4. Replace the Reader Word by Word settings placeholder with a real settings body:
   - show/hide word help
   - show/hide transliteration
5. Apply those settings to Reader rendering:
   - verse-by-verse translation block
   - word tooltips
   - word preview/popover meaning details where existing data is available
6. Update focused Reader and app-preference tests, then run the Wave 1 validation set.

## Decision Log
- 2026-03-08: Wave 1 stays inside existing data and local preferences instead of introducing a new study data source.
- 2026-03-08: Transliteration is implemented as an optional meaning aid, not a default-visible Reader layer.
- 2026-03-08: Word-help tooltips stay translation-only in Wave 1; transliteration is surfaced through the existing preview/popover path instead of widening tooltip behavior.

## Validation
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Add Wave 1 ExecPlan and Reader roadmap tracker
- [x] Add persistent Reader meaning preferences
- [x] Replace placeholder settings panes
- [x] Apply controls to Reader rendering
- [x] Validate Wave 1
- [x] Run narrow Assistant Docs Sync
- [x] Prepare for closeout

## Surprises and Adjustments
- 2026-03-08: Fresh-worktree Flutter bootstrap touched `pubspec.lock` again before focused validation. The incidental lockfile churn was reverted and the worktree stayed dependency-neutral.
- 2026-03-08: Extending `AppPreferencesStore` required updating fake stores in `navigation_shell_menu_test.dart`, `companion_chain_screen_test.dart`, and `reciters_screen_test.dart` before `flutter analyze` returned to green.

## Handoff
- Wave 1 should end with:
  - persistent Reader meaning controls merged
  - placeholder Translation and Word by Word settings removed
  - Reader tests covering translation visibility, word-help visibility, and transliteration behavior
  - roadmap tracker updated so the next action is Wave 2
- Validation completed in `/home/fa507/dev/hifz_planner_reader_wave1`:
  - `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
  - `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
  - `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
  - `dart tooling/validate_workspace_hygiene.dart`
- Narrow Assistant Docs Sync completed for:
  - `APP_KNOWLEDGE.md`
  - `docs/assistant/APP_KNOWLEDGE.md`
  - `docs/assistant/features/APP_USER_GUIDE.md`
- Feature merged to `main` in PR `#33`.
