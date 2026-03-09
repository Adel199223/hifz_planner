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
- [x] Add study-setup summary to My Quran
- [x] Add lightweight inline study-default controls
- [x] Add focused tests
- [x] Run targeted validation
- [x] Run Assistant Docs Sync

## Surprises and Adjustments
- 2026-03-09: The cleanest shape was to keep the original three primary My Quran cards and add `Study setup` as a separate section underneath them, so the hub stays personal without breaking the Wave 1 three-card promise.
- 2026-03-09: Fresh-worktree Flutter bootstrap touched `pubspec.lock` before validation again; the incidental churn was reverted so Wave 3 remains dependency-neutral.
- 2026-03-09: The trusted validation record uses sequential Flutter commands in this worktree.
- 2026-03-09: A docs-governance detour codified adaptive roadmap triggering, active-worktree authority, and validator coverage for future multi-wave work; the implementation sequence still returns to Wave 3 closeout.
- 2026-03-09: The reusable UCBS roadmap-governance module is now merged to `main`, and this worktree has been rebased onto that baseline so the project harness and template-layer contracts are aligned before Wave 3 closeout.

## Handoff
- Final state summary:
  - `My Quran` now includes a separate `Study setup` section with a plain-language summary and inline toggles for verse translation, word help, transliteration, and Practice from Memory autoplay.
  - Reciter selection still routes through `Listening setup` and `/reciters`; Wave 3 does not duplicate full reciter selection or deeper global settings.
  - Narrow Assistant Docs Sync is complete for `APP_KNOWLEDGE.md`, `docs/assistant/APP_KNOWLEDGE.md`, `docs/assistant/features/APP_USER_GUIDE.md`, and `docs/assistant/features/START_HERE_USER_GUIDE.md`.
  - Wave 3 implementation is complete, validated locally, and docs-synced; the next step is PR closeout.
- Follow-up risks:
  - The shortcut list should stay narrow; if this starts duplicating full Settings behavior, cut scope back immediately.
