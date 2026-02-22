# Reader Workflow

## What This Workflow Is For

Use this workflow for Verse by Verse and Reading (Mushaf) UI/interaction work, including Quran.com parity adjustments.

## When To Use

Use when changes touch:
- `lib/screens/reader_screen.dart`
- reader actions, highlights, hover/click behavior
- mushaf/verse-by-verse shell controls
- chapter header/basmala rendering in reader context

## What Not To Do

- Do not make schema changes here unless explicitly required.
- Do not bypass fallback paths that protect against missing font/API/cache.
- Do not skip reader widget tests after UI or interaction changes.

## Primary Files

- `lib/screens/reader_screen.dart`
- `lib/data/services/qurancom_api.dart`
- `lib/ui/qcf/qcf_font_manager.dart`
- `lib/ui/tajweed/tajweed_markup.dart`
- `lib/ui/tajweed/tajweed_colors.dart`
- `test/screens/reader_screen_test.dart`
- `test/app/navigation_shell_menu_test.dart`

## Minimal Commands

```powershell
git status --short
rg -n "_ReaderViewMode|Verse by Verse|Reading|_MushafNavTab" lib/screens/reader_screen.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
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

## Handoff Checklist

- modified files are scoped to reader concerns
- fallback behavior still works for partial Quran.com failures
- `test/screens/reader_screen_test.dart` passes
- any control/key changes are reflected in tests
