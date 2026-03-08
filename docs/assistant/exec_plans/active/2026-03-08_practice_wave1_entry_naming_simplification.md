# ExecPlan: Practice Wave 1 - Entry and Naming Simplification

## Purpose
- Make memorization practice easier to find and start without asking the learner to understand `Companion` or stage jargon.
- Reframe top-level practice entry points around simple actions:
  - start new practice
  - continue review practice
  - do delayed check

## Scope
- In scope:
  - learner-facing language on `Today`, `Learn`, and other top-level practice launch points
  - a durable roadmap tracker entry for this new practice roadmap
  - focused tests for the new launch copy and routes
- Out of scope:
  - deep practice-screen wording simplification
  - hidden-recall runtime changes
  - persistence or schema changes
  - route contract changes

## Assumptions
- `/companion/chain` with `mode=new|review|stage4` must remain unchanged.
- `Today` already has the strongest source of truth for what the learner should do next.
- `Learn` can safely surface practice options by reusing the current daily planner path.

## Milestones
1. Add the new practice roadmap tracker and start Wave 1 on an isolated branch.
2. Replace top-level `Companion` entry language with `Practice from Memory` wording.
3. Make `Learn` expose direct practice entry buttons without exposing engine jargon.
4. Validate the new launch behavior with focused tests.

## Detailed Steps
1. Add the new roadmap tracker at `docs/assistant/exec_plans/active/2026-03-08_practice_from_memory_execution.md`.
2. Update `lib/l10n/app_strings.dart` with Wave 1 practice-entry labels and simple copy.
3. Update `lib/screens/today_screen.dart` so the visible practice actions use the new learner-facing labels and the new-practice primary route points into the practice flow.
4. Update `lib/screens/learn_screen.dart` to surface direct practice entry cards backed by the current day plan.
5. Update focused tests in:
   - `test/screens/today_screen_test.dart`
   - `test/app/navigation_shell_menu_test.dart`
   - add a dedicated `test/screens/learn_screen_test.dart` if needed for direct practice entry coverage
6. Run the targeted Flutter tests plus localization and agent-doc validators.

## Decision Log
- 2026-03-08: Keep internal `Companion` names in routes, keys, and engine code for compatibility while simplifying only the learner-facing entry copy.
- 2026-03-08: Route `Today` new-work coaching into practice instead of Reader so the user gets one clear action for practice-first daily flow.
- 2026-03-08: Keep `Learn` side-effect free by resolving only already-existing direct practice targets; when no target exists yet, fall back to `/today` instead of generating new units from the Learn screen.

## Validation
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `flutter test -j 1 -r expanded test/screens/learn_screen_test.dart`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Add tracker and Wave 1 ExecPlan
- [x] Update learner-facing practice entry copy
- [x] Update Learn practice launch behavior
- [x] Run focused validation

## Surprises and Adjustments
- The first Learn-screen pass overflowed vertically in standard test-sized layouts, so the screen was converted to a scrollable layout before validation continued.

## Handoff
- Wave 1 should end with:
  - `Today` using plain-language practice action labels
  - `Learn` exposing direct practice entry cards
  - no learner needing the word `Companion` to start a session
- Current state:
  - implemented, docs-synced, and validated locally
  - not yet published
- Validation run:
  - `flutter test -j 1 -r expanded test/screens/learn_screen_test.dart`
  - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
  - `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
  - `dart tooling/validate_workspace_hygiene.dart`
- Follow-up risk:
  - the core practice screen will still show stage-heavy language until Wave 2.
