# ExecPlan: Meaning Cue System

## Purpose
- Replace the Companion meaning-cue placeholder with a real, source-backed cue path.
- Keep semantic cues optional, tagged with their source, and safely fall back to existing non-semantic hints when no cue is available.

## Scope
- In scope:
  - Add a Companion meaning cue service/provider that derives concise cues from existing Quran.com verse translation data.
  - Wire Companion hint rendering to use the new service for `HintLevel.meaningCue`.
  - Show a source tag alongside the cue so the hint remains attributable.
  - Add targeted tests for cue extraction and Companion rendering/fallback behavior.
- Out of scope:
  - New routes, schema changes, or Drift migration.
  - Reader tafsir screen work.
  - Planner reinforcement or ASR work.
  - A broader theology/tafsir catalog.

## Assumptions
- The repo already trusts Quran.com verse translation data for Reader translation rendering, so it is acceptable as the first source-backed semantic cue layer for Companion.
- The meaning cue should stay conservative: summarize only by truncation/cleaning of fetched source text, not by model generation.
- If source data is missing or fails to load, Companion should behave exactly as before except that meaning-cue requests fall back to the next non-semantic hint.

## Milestones
1. Add source-backed meaning cue provider and result model.
2. Integrate meaning cue loading and rendering in Companion.
3. Add targeted tests and validation.

## Detailed Steps
1. Add a new service under `lib/data/services/companion/` for fetching and formatting verse meaning cues from `QuranComApi.getVerseDataByPage(...)`.
2. Add a Riverpod provider in `lib/data/providers/database_providers.dart` for the meaning cue service.
3. Update `lib/screens/companion_chain_screen.dart` to:
   - preload cues for verses when possible,
   - render cue text + source label for `HintLevel.meaningCue`,
   - keep letters/first-word/chunk/full-text fallback stable when a cue is unavailable.
4. Add/adjust strings in `lib/l10n/app_strings.dart` only for the new source tag/loading/unavailable messaging if required.
5. Add tests in:
   - `test/data/services/companion/meaning_cue_service_test.dart`
   - `test/screens/companion_chain_screen_test.dart`
6. Run targeted validation commands and move this plan to `completed/` when done.

## Decision Log
- 2026-03-12: Use existing Quran.com verse translation data as the first source-backed meaning cue implementation because it is already integrated locally, attributed by resource name, and avoids adding an unsourced or generated cue path.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/companion/meaning_cue_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
- `dart run tooling/validate_localization.dart`

## Progress
- [x] Milestone 1
- [x] Milestone 2
- [x] Milestone 3

## Surprises and Adjustments
- Current Companion already loads word-level verse data from Quran.com for rendering, but meaning cues are still hardcoded placeholders. The new service can reuse the same verse/page lookup inputs instead of adding a new fetch path.
- The cleanest integration was screen-side cue preloading rather than engine changes, because the hint ladder already supported `HintLevel.meaningCue` and only the rendered text was missing.

## Handoff
- Completed implementation:
  - added `CompanionMeaningCueService` and Riverpod provider,
  - preloaded verse meaning cues in Companion from Quran.com verse translation data,
  - rendered attributed meaning cues in the active hint card and verse body,
  - fell back to chunk hints when no semantic cue source existed,
  - added service and screen coverage.
- Validation completed:
  - `flutter test -j 1 -r expanded test/data/services/companion/meaning_cue_service_test.dart`
  - `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
  - `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart run tooling/validate_localization.dart`
