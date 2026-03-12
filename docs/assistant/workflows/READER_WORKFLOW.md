# Reader Workflow

## What This Workflow Is For

Use this workflow for Verse by Verse and Reading (Mushaf) UI/interaction work, including Quran.com parity adjustments.

## Expected Outputs

- Reader behavior changes are scoped to reader UI/interaction files.
- Fallback/no-crash behavior remains intact when Quran.com/font/audio paths degrade.
- Reader-targeted tests pass for touched behavior.

## When To Use

Use when changes touch:
- `lib/screens/reader_screen.dart`
- reader actions, highlights, hover/click behavior
- shared Quran word rendering (`lib/ui/quran/quran_word_wrap.dart`)
- mushaf/verse-by-verse shell controls
- chapter header/basmala rendering in reader context
- tajweed legend/control placement and visibility
- locale-specific reader directionality/alignment behavior
- reader recitation playback (per-ayah play, queue, mini-player controls)
- Reader offline audio download/remove behavior
- Reader-specific display preferences for translations and word-by-word aids

## What Not To Do

- Don't use this workflow when the task is primarily localization terminology/routing work. Instead use `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`.
- Don't use this workflow when the task is primarily Quran.com transport/cache contract changes. Instead use `docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md`.
- Don't use this workflow when the task is primarily planner/scheduling logic. Instead use `docs/assistant/workflows/PLANNER_WORKFLOW.md` or `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`.
- Do not make schema changes here unless explicitly required.
- Do not bypass fallback paths that protect against missing font/API/cache.
- Do not skip reader widget tests after UI or interaction changes.
- Do not define localization terms here; route terminology/locale changes through `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` and `docs/assistant/LOCALIZATION_GLOSSARY.md`.

## Primary Files

- `lib/screens/reader_screen.dart`
- `lib/data/services/qurancom_api.dart`
- `lib/data/services/qurancom_chapters_service.dart`
- `lib/data/services/ayah_audio_source.dart`
- `lib/data/services/ayah_audio_service.dart`
- `lib/data/services/ayah_audio_download_service.dart`
- `lib/data/services/ayah_audio_playback_resolver.dart`
- `lib/data/services/ayah_audio_preferences.dart`
- `lib/data/services/ayah_reciter_catalog_service.dart`
- `lib/data/providers/audio_providers.dart`
- `lib/app/reader_display_preferences.dart`
- `lib/app/reader_display_preferences_store.dart`
- `lib/ui/audio/reciter_selection_list.dart`
- `lib/screens/reciters_screen.dart`
- `lib/ui/qcf/qcf_font_manager.dart`
- `lib/ui/quran/quran_word_wrap.dart`
- `lib/data/services/quran_wording.dart`
- `lib/ui/tajweed/tajweed_markup.dart`
- `lib/ui/tajweed/tajweed_colors.dart`
- `test/screens/reader_screen_test.dart`
- `test/ui/quran/quran_word_wrap_test.dart`
- `test/data/services/qurancom_chapters_service_test.dart`
- `test/data/services/ayah_audio_download_service_test.dart`
- `test/data/services/ayah_audio_source_test.dart`
- `test/data/services/ayah_reciter_catalog_service_test.dart`
- `test/data/providers/audio_providers_test.dart`
- `test/app/reader_display_preferences_test.dart`
- `test/screens/reciters_screen_test.dart`
- `test/app/navigation_shell_menu_test.dart`

## Minimal Commands

```powershell
git status --short
rg -n "_ReaderViewMode|Verse by Verse|Reading|_MushafNavTab" lib/screens/reader_screen.dart
rg -n "_buildVerseByVerseChapterHeader|_buildMushafExternalChapterHeader|_buildTajweedLegendSection|searchSurah|Directionality\\(textDirection: TextDirection.ltr\\)" lib/screens/reader_screen.dart
rg -n "ayahAudio|playFrom|playAyah|mini_player|reader_audio_options_button" lib/screens/reader_screen.dart lib/data/services/ayah_audio_service.dart
rg -n "downloadSurah|removeSurahDownload|resolveAyahUri|reader_audio_download|reader_audio_experience" lib/screens/reader_screen.dart lib/data/services/ayah_audio_download_service.dart lib/data/services/ayah_audio_playback_resolver.dart
rg -n "readerDisplayPreferences|showVerseTranslations|showWordTooltips|highlightHoveredWords" lib/screens/reader_screen.dart lib/app/reader_display_preferences.dart
rg -n "edition|reciter|fallback|versebyverse" lib/data/services/ayah_reciter_catalog_service.dart lib/data/providers/audio_providers.dart
rg -n "QuranComChapterEntry|getChapters|getChapter" lib/data/services/qurancom_chapters_service.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/ui/quran/quran_word_wrap_test.dart
flutter test -j 1 -r expanded test/data/services/qurancom_chapters_service_test.dart
flutter test -j 1 -r expanded test/data/services/ayah_audio_download_service_test.dart
flutter test -j 1 -r expanded test/data/services/ayah_audio_source_test.dart
flutter test -j 1 -r expanded test/data/services/ayah_reciter_catalog_service_test.dart
flutter test -j 1 -r expanded test/data/providers/audio_providers_test.dart
flutter test -j 1 -r expanded test/app/reader_display_preferences_test.dart
flutter test -j 1 -r expanded test/screens/reciters_screen_test.dart
flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: row rendering errors, missing Arabic text, crashes in verse list.
   - Check Quran.com row fallback path in `reader_screen.dart`.
2. Symptoms: wrong/blank glyphs or tajweed rendering regression.
   - Verify QCF font selection and fallback in `qcf_font_manager.dart`.
3. Symptoms: action sheet or bookmark/note/copy interactions fail.
   - Validate action handlers and existing key-based test coverage in `reader_screen_test.dart`.
4. Symptoms: parity drift after control updates.
   - Re-check shell controls and settings pane behavior under both reader modes.
5. Symptoms: surah header title/subtitle mismatch or language fallback drift.
   - Verify chapter metadata flow in `qurancom_chapters_service.dart` and reader fallback paths.
6. Symptoms: Arabic translation punctuation/order appears broken in Arabic UI.
   - Verify translation line is explicitly wrapped in LTR `Directionality` and Arabic ayah remains RTL/right-anchored.
7. Symptoms: `MissingPluginException` for `just_audio` on Windows.
   - Ensure `just_audio_media_kit` + `media_kit_libs_windows_audio` are in `pubspec.yaml`, run `flutter pub get`, and fully restart the app (not only hot reload).
8. Symptoms: old `just_audio_windows` thread-channel logs or app drop during playback after dependency changes.
   - Perform a full plugin refresh on Windows: `flutter clean`, `flutter pub get`, then `flutter run -d windows`.
9. Symptoms: reciter list fails to load.
   - Confirm AlQuran Cloud editions endpoint response shape, then verify bundled fallback list is still present in `ayah_reciter_catalog_service.dart`.
10. Symptoms: speed/repeat/reciter settings reset after restart.
   - Verify SharedPreferences keys and notifier write-through in `ayah_audio_preferences.dart` and `audio_providers.dart`.
11. Symptoms: download sheet never reaches fully downloaded state or cached playback never takes over.
   - Verify app-support path resolution, atomic temp-file rename, and local-first resolver wiring in `ayah_audio_download_service.dart`, `ayah_audio_playback_resolver.dart`, and `ayah_audio_service.dart`.
12. Symptoms: translation visibility, word tooltip, or hover highlight settings do not persist or apply in both reader modes.
   - Verify `reader_display_preferences.dart`, its store, and both Verse-by-Verse and Mushaf call sites in `reader_screen.dart`.
13. Symptoms: verse-by-verse still shows circular end markers.
   - Verify end-marker suppression is enabled in shared word rendering for Verse-by-Verse paths.

## Handoff Checklist

- modified files are scoped to reader concerns
- fallback behavior still works for partial Quran.com failures
- verse-by-verse uses shared word rendering with end-marker suppression enabled
- `test/screens/reader_screen_test.dart` passes
- `test/ui/quran/quran_word_wrap_test.dart` passes
- `test/data/services/qurancom_chapters_service_test.dart` passes
- `test/data/services/ayah_audio_download_service_test.dart` passes for surah download/remove and cached-path status behavior
- `test/data/services/ayah_audio_source_test.dart` passes for ayah index/url mapping
- `test/data/services/ayah_reciter_catalog_service_test.dart` passes for API parsing + fallback
- `test/data/providers/audio_providers_test.dart` passes for persisted reciter/speed/repeat state
- `test/app/reader_display_preferences_test.dart` passes for Reader display preference restore/write behavior
- `test/screens/reciters_screen_test.dart` passes for searchable selector behavior
- any control/key changes are reflected in tests
