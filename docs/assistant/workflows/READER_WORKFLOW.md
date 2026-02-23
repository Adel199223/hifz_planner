# Reader Workflow

## What This Workflow Is For

Use this workflow for Verse by Verse and Reading (Mushaf) UI/interaction work, including Quran.com parity adjustments.

## When To Use

Use when changes touch:
- `lib/screens/reader_screen.dart`
- reader actions, highlights, hover/click behavior
- mushaf/verse-by-verse shell controls
- chapter header/basmala rendering in reader context
- reader recitation playback (per-ayah play, queue, mini-player controls)

## What Not To Do

- Do not make schema changes here unless explicitly required.
- Do not bypass fallback paths that protect against missing font/API/cache.
- Do not skip reader widget tests after UI or interaction changes.
- Do not define localization terms here; route terminology/locale changes through `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md` and `docs/assistant/LOCALIZATION_GLOSSARY.md`.

## Primary Files

- `lib/screens/reader_screen.dart`
- `lib/data/services/qurancom_api.dart`
- `lib/data/services/ayah_audio_source.dart`
- `lib/data/services/ayah_audio_service.dart`
- `lib/data/services/ayah_audio_preferences.dart`
- `lib/data/services/ayah_reciter_catalog_service.dart`
- `lib/data/providers/audio_providers.dart`
- `lib/ui/audio/reciter_selection_list.dart`
- `lib/screens/reciters_screen.dart`
- `lib/ui/qcf/qcf_font_manager.dart`
- `lib/ui/tajweed/tajweed_markup.dart`
- `lib/ui/tajweed/tajweed_colors.dart`
- `test/screens/reader_screen_test.dart`
- `test/data/services/ayah_audio_source_test.dart`
- `test/data/services/ayah_reciter_catalog_service_test.dart`
- `test/data/providers/audio_providers_test.dart`
- `test/screens/reciters_screen_test.dart`
- `test/app/navigation_shell_menu_test.dart`

## Minimal Commands

```powershell
git status --short
rg -n "_ReaderViewMode|Verse by Verse|Reading|_MushafNavTab" lib/screens/reader_screen.dart
rg -n "ayahAudio|playFrom|playAyah|mini_player|reader_audio_options_button" lib/screens/reader_screen.dart lib/data/services/ayah_audio_service.dart
rg -n "edition|reciter|fallback|versebyverse" lib/data/services/ayah_reciter_catalog_service.dart lib/data/providers/audio_providers.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/data/services/ayah_audio_source_test.dart
flutter test -j 1 -r expanded test/data/services/ayah_reciter_catalog_service_test.dart
flutter test -j 1 -r expanded test/data/providers/audio_providers_test.dart
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
5. Symptoms: `MissingPluginException` for `just_audio` on Windows.
   - Ensure `just_audio_media_kit` + `media_kit_libs_windows_audio` are in `pubspec.yaml`, run `flutter pub get`, and fully restart the app (not only hot reload).
6. Symptoms: old `just_audio_windows` thread-channel logs or app drop during playback after dependency changes.
   - Perform a full plugin refresh on Windows: `flutter clean`, `flutter pub get`, then `flutter run -d windows`.
7. Symptoms: reciter list fails to load.
   - Confirm AlQuran Cloud editions endpoint response shape, then verify bundled fallback list is still present in `ayah_reciter_catalog_service.dart`.
8. Symptoms: speed/repeat/reciter settings reset after restart.
   - Verify SharedPreferences keys and notifier write-through in `ayah_audio_preferences.dart` and `audio_providers.dart`.

## Handoff Checklist

- modified files are scoped to reader concerns
- fallback behavior still works for partial Quran.com failures
- `test/screens/reader_screen_test.dart` passes
- `test/data/services/ayah_audio_source_test.dart` passes for ayah index/url mapping
- `test/data/services/ayah_reciter_catalog_service_test.dart` passes for API parsing + fallback
- `test/data/providers/audio_providers_test.dart` passes for persisted reciter/speed/repeat state
- `test/screens/reciters_screen_test.dart` passes for searchable selector behavior
- any control/key changes are reflected in tests
