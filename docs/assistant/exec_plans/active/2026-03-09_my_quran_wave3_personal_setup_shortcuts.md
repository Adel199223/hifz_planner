# ExecPlan: My Quran Wave 3 Personal Setup Shortcuts

## Purpose
- Add lightweight personal study-setup shortcuts to `My Quran` so a learner can quickly see and adjust the simplest daily defaults without opening deeper settings screens.

## Scope
- In scope:
  - show a plain-language study setup summary in `My Quran`
  - add lightweight inline controls for:
    - translation visibility
    - word-help visibility
    - transliteration visibility
    - companion auto-recite
  - keep reciter selection linked out to `Reciters`
  - focused widget and preference tests for the new shortcuts and summary
- Out of scope:
  - theme or language controls
  - full reciter selection inside `My Quran`
  - global settings duplication
  - Quran Radio work

## Assumptions
- Wave 2 resume and saved-study depth is now merged to `main`.
- The existing app-preferences path remains the right place for the new lightweight study defaults.
- `My Quran` should stay summary-first and shortcut-oriented, not become another full settings screen.

## Milestones
1. Add study-setup summary content to `My Quran`.
2. Add lightweight inline study-default toggles.
3. Validate the new shortcuts and update roadmap memory.

## Detailed Steps
1. Reuse the existing preferences/state wiring for translation, word help, transliteration, and companion auto-recite.
2. Add a `Study setup` card or section to `My Quran` that summarizes the current defaults in plain language.
3. Add simple inline toggles for the four in-scope study defaults without duplicating deeper settings screens.
4. Keep the reciter path as a linked shortcut to `/reciters`, not an inline selector.
5. Add focused coverage for:
   - summary rendering
   - toggle persistence
   - calm fallback behavior when no extra study data exists
6. Run targeted validation before any docs sync or publish step.

## Decision Log
- 2026-03-09: Start Wave 3 only after Wave 2 merged and the active Wave 2 plan was archived.
- 2026-03-09: Keep `My Quran` as a personal hub with quick defaults, not a duplicate Settings screen.

## Validation
- `flutter test -j 1 -r expanded test/screens/my_quran_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Create Wave 3 ExecPlan
- [ ] Add study-setup summary to My Quran
- [ ] Add lightweight inline study-default controls
- [ ] Add focused tests
- [ ] Run targeted validation

## Surprises and Adjustments
- Use this section for scope corrections, detours, or repeated workflow issues discovered while implementing Wave 3.

## Handoff
- Final state summary:
  - pending
- Follow-up risks:
  - The shortcut list should stay narrow; if this starts duplicating full Settings behavior, cut scope back immediately.
