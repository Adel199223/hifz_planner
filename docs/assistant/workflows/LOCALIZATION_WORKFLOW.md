# Localization Workflow

## What This Workflow Is For

Use this workflow for language additions, label changes, terminology consistency, RTL behavior, and Reader translation-resource mapping.

## When To Use

Use when changes touch:
- `lib/l10n/app_language.dart`
- `lib/l10n/app_strings.dart`
- `lib/main.dart` locale/delegate wiring
- `lib/screens/reader_screen.dart` text labels/messages
- any screen text in `lib/screens/*`
- localization tests or localization validation tooling

## What Not To Do

- Do not hardcode new user-facing labels directly in screen widgets.
- Do not duplicate term tables across multiple docs; update glossary first.
- Do not break Arabic global RTL behavior.
- Do not change Reader translation-resource mapping (`en=85`, `fr=31`, `pt=43`, `ar=85`) unless the task explicitly targets data/mapping behavior.
- Do not add Python CI/tooling for localization in this repo unless Python tooling is actually introduced.

## Primary Files

- `docs/assistant/LOCALIZATION_GLOSSARY.md`
- `lib/l10n/app_language.dart`
- `lib/l10n/app_strings.dart`
- `lib/main.dart`
- `lib/screens/reader_screen.dart`
- `test/l10n/app_strings_test.dart`
- `tooling/validate_localization.dart`
- `test/tooling/validate_localization_test.dart`

## Localization Source Priority

1. Quran.com locale files and live localized UI for overlapping Reader terms.
2. `docs/assistant/LOCALIZATION_GLOSSARY.md` as the internal canonical term layer.
3. English fallback text only when no approved localized term exists yet.

## Execution Sequence

1. Update glossary terms first.
2. Update string keys/values in `lib/l10n/app_strings.dart`.
3. Update UI usage in Reader and affected screens.
4. Update/add tests.
5. Run localization validator and targeted tests.

## Minimal Commands

```powershell
git status --short
rg -n "AppLanguage|AppStrings|flutter_localizations|translationResourceId" lib
dart run tooling/validate_localization.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/l10n/app_strings_test.dart
flutter test -j 1 -r expanded test/tooling/validate_localization_test.dart
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: labels regress to English unexpectedly.
   - Verify locale selected in `app_preferences` and key coverage in `app_strings.dart`.
2. Symptoms: Arabic layout stays LTR.
   - Check `AppLanguage.arabic.isRtl`, locale wiring in `main.dart`, and Directionality behavior in tests.
3. Symptoms: Reader translation line uses wrong resource.
   - Re-check `_translationResourceIdForLanguage(...)` in `reader_screen.dart`.
4. Symptoms: inconsistent terms between Reader and shell.
   - Update `LOCALIZATION_GLOSSARY.md` first, then align `app_strings.dart`, then re-run validator/tests.

## Handoff Checklist

- glossary updated before string keys when terminology changed
- `app_strings.dart` and screen usage are consistent
- Arabic RTL remains correct
- Reader translation mapping remains `en=85`, `fr=31`, `pt=43`, `ar=85` unless explicitly changed
- `dart run tooling/validate_localization.dart` passes
- localization tests pass
