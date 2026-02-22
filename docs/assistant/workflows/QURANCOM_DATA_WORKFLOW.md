# Quran.com Data Workflow

## What This Workflow Is For

Use this workflow for Quran.com data transport, by-page caching, in-memory dedupe, translation-aware payloads, and QCF font loading behavior.

## When To Use

Use when changes touch:
- by-page API request fields/shape
- cache key or cache file naming
- dedupe/in-flight request logic
- translation resource hydration
- QCF font download/load/fallback logic

## What Not To Do

- Do not add per-verse network fan-out.
- Do not break cache backward compatibility unless explicitly migrating.
- Do not remove no-crash fallback behavior in consumer UI.

## Primary Files

- `lib/data/services/qurancom_api.dart`
- `lib/ui/qcf/qcf_font_manager.dart`
- `lib/data/providers/database_providers.dart`
- `test/data/services/qurancom_api_test.dart`
- `test/screens/reader_screen_test.dart`

## Minimal Commands

```powershell
git status --short
rg -n "getPageWithVerses|getVerseDataByPage|getJuzIndex|_pageKey|translations" lib/data/services/qurancom_api.dart
rg -n "ensurePageFont|QcfFontVariant|fallback" lib/ui/qcf/qcf_font_manager.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/data/services/qurancom_api_test.dart
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: missing verses or translation text on cached pages.
   - Check translation-aware cache key (`_t{translationId}`) behavior and refresh path.
2. Symptoms: duplicated network calls for same page.
   - Verify pending-future dedupe maps keyed by page+mushaf(+translation).
3. Symptoms: font download/load failures.
   - Confirm v4->v2 fallback remains active and no hard throw reaches UI.
4. Symptoms: stale old cache shape breaks parser.
   - Validate backward-compatible parsing path and forced refresh guards.

## Handoff Checklist

- cache and dedupe behavior remains page-level and efficient
- translation-aware and non-translation cache paths both work
- reader still degrades gracefully when API/cache/font failures occur
- `test/data/services/qurancom_api_test.dart` passes
