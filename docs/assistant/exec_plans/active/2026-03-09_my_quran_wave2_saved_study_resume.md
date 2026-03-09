# ExecPlan: My Quran Wave 2 Saved Study and Resume Depth

## Purpose
- Make `My Quran` feel genuinely useful by adding saved-study previews and meaningful resume depth.

## Scope
- In scope:
  - persist the last Reader location during normal Reader usage
  - show the latest saved bookmark preview in `My Quran` when available
  - show the latest updated note preview in `My Quran` when available
  - add direct reopen actions that route back into Reader with the correct target
  - focused widget and preference tests for the new resume and preview behavior
- Out of scope:
  - inline setup shortcuts
  - full Library duplication inside `My Quran`
  - theme, language, or reciter selection controls
  - Quran Radio work

## Assumptions
- Wave 1's three-card hub on `main` is the stable foundation for this wave.
- Reader can persist a lightweight last-location snapshot without changing routes or DB schema.
- `My Quran` should stay summary-first and route into Reader or Library, not become a second list-management screen.

## Milestones
1. Persist last-reader location from normal Reader usage.
2. Add saved bookmark and note previews to `My Quran`.
3. Add direct reopen actions and validate the new flows.

## Detailed Steps
1. Extend the current last-reader snapshot usage from read-only to write-on-normal-Reader-usage.
2. Add shared snapshot/provider fields for latest bookmark and latest updated note previews using existing local data.
3. Update `My Quran` cards so `Continue reading` and `Saved for later` show meaningful previews and direct reopen paths.
4. Add focused coverage for:
   - resume behavior with a saved Reader snapshot
   - useful fallback behavior with no snapshot
   - latest bookmark preview rendering and reopen action
   - latest note preview rendering and reopen action
5. Run targeted Wave 2 validation and record any repeatable workflow issues in issue memory if they recur.

## Decision Log
- 2026-03-09: Start Wave 2 only after Wave 1 merged and the active Wave 1 plan was archived.
- 2026-03-09: Keep `My Quran` as a personal entry point, not a duplicate Library screen.

## Validation
- `flutter test -j 1 -r expanded test/screens/my_quran_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/reader_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
- `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`
- `dart tooling/validate_workspace_hygiene.dart`

## Progress
- [x] Create Wave 2 ExecPlan
- [ ] Persist last-reader location from Reader usage
- [ ] Add saved-study previews to My Quran
- [ ] Add reopen actions and focused tests
- [ ] Run targeted validation

## Surprises and Adjustments
- Use this section for any scope correction or repeated local workflow issue discovered during Wave 2.

## Handoff
- Starting state summary:
  - Wave 1 is merged on `main` and archived.
  - `My Quran` already has three stable cards:
    - `Continue reading`
    - `Saved for later`
    - `Listening setup`
  - The current roadmap return point is to deepen resume and saved-study usefulness without changing routes or schema.
- Follow-up risks:
  - Reader location persistence may reveal edge cases between page mode and verse mode that need explicit fallback rules.
