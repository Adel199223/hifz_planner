# ExecPlan: Reader Audio and Display Completion

## Purpose
- Replace remaining Reader placeholder controls with real behavior.
- Complete the next roadmap slice in two stages: Reader audio options first, Reader display settings second.

## Scope
- In scope:
- add Reader surah-audio download/cache support and local-first playback resolution
- replace Reader mini-player `Download` and `Experience` placeholders with real flows
- add persisted Reader display preferences and replace Translation / Word By Word placeholder tabs
- extend targeted Reader/audio/provider tests
- Out of scope:
- `Quran Radio` implementation
- translator selection or new translation catalogs
- schema changes, route changes, or Drift migration
- broad assistant-doc rewrites unless explicitly requested after implementation

## Assumptions
- Audio download scope is surah-only and based on the active mini-player ayah context.
- Reader display preferences should live in their own persisted store/provider, not inside `AppPreferencesState`.
- Translation source continues to follow app language in this milestone.

## Milestones
1. Add Reader audio cache/download plumbing and playback resolution.
2. Replace Reader audio placeholder actions with real UI flows.
3. Add Reader display preference persistence and wire Translation / Word By Word tabs.
4. Extend tests and run targeted validation.

## Detailed Steps
1. Add an audio download service/provider plus a playback resolver that prefers local cached files before remote URLs.
2. Update Reader mini-player actions so `Download` opens a surah download/remove flow and `Experience` opens a consolidated audio settings sheet.
3. Add a persisted Reader display preference model/store/provider for translation visibility, word tooltips, and word hover highlights.
4. Replace Translation / Word By Word placeholder tab bodies with real controls and wire them through Verse-by-Verse and Mushaf rendering.
5. Add service/provider/widget tests for the new audio and display behavior.
6. Run analyzer, targeted Reader/audio tests, localization validation, and agent-doc validation if docs are touched.

## Decision Log
- 2026-03-11: `Quran Radio` is explicitly deferred and excluded from this roadmap slice.
- 2026-03-11: Stage ordering is audio completion first, display settings second, to keep risk and UI churn lower.
- 2026-03-11: Translation-resource selection remains out of scope; display controls only in this milestone.
- 2026-03-11: Offline audio is surah-scoped and anchored to the active mini-player ayah context; no standalone library or route was added.
- 2026-03-11: Reader display preferences live in a dedicated store/provider instead of `AppPreferencesState` to avoid widening unrelated global settings state.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test\data\services\ayah_audio_download_service_test.dart`
- `flutter test -j 1 -r expanded test\app\reader_display_preferences_test.dart`
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter test -j 1 -r expanded test/ui/quran/quran_word_wrap_test.dart`
- `flutter test -j 1 -r expanded test/data/providers/audio_providers_test.dart`
- `flutter test -j 1 -r expanded test/data/services/ayah_audio_source_test.dart`
- `flutter test -j 1 -r expanded test/data/services/ayah_reciter_catalog_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/reciters_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `dart run tooling/validate_localization.dart`

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three
- [x] Milestone four

## Surprises and Adjustments
- The cleanest offline-audio seam was a playback resolver layered on top of the existing remote source, not changing the remote source into a storage manager.
- The Reader already had `showWordHover` and `showTooltips` hooks in shared word rendering, so the main new work for Stage 2 was persisted preference plumbing and Mushaf-specific hover/tooltip gating.

## Handoff
- Added a surah-scoped Reader audio download service plus playback resolver so cached local files are preferred and remote URLs remain the fallback.
- Replaced Reader mini-player `Download` and `Experience` placeholders with a download sheet and a consolidated experience sheet that routes into the existing reciter/speed/repeat flows.
- Added dedicated Reader display preferences for verse translation visibility, word tooltips, and word hover highlights, and wired the Translation / Word By Word tabs to those settings.
- Validation passed for analyzer, the new audio-download and reader-display preference tests, Reader screen coverage, shared word-wrap coverage, audio provider/source tests, reciter screen coverage, navigation shell coverage, and localization validation.
