# ExecPlan: Practice Wave 2 - Core Practice Screen Simplification

## Purpose
- Make the practice screen understandable without stage jargon.
- Reframe the visible runtime around simple learner questions:
  - what to do now
  - when to listen
  - when to recite
  - when correction is required
  - when the session is complete

## Scope
- In scope:
  - learner-facing wording on the practice screen
  - task-first framing for the current deterministic runtime
  - reducing visible stage/mode jargon in the default UI
  - focused tests for the updated screen language
- Out of scope:
  - hidden-recall runtime logic changes
  - route contract changes
  - persistence or schema changes
  - microphone or voice-aware scoring

## Assumptions
- `/companion/chain` and `mode=new|review|stage4` stay unchanged.
- The practice engine remains deterministic; Wave 2 is about clearer presentation, not new automation.
- Advanced/stateful detail can stay available where it is needed for understanding or debugging.

## Milestones
1. Audit the current practice screen for the stage/mode terms that still leak into the default UI.
2. Replace visible stage-first framing with task-first session guidance.
3. Update focused practice screen tests and localization assertions.
4. Validate the practice screen behavior and close out Wave 2.

## Detailed Steps
1. Inspect `lib/screens/companion_chain_screen.dart` and its supporting strings in `lib/l10n/app_strings.dart`.
2. Identify the default learner-facing labels that still expose:
   - `Stage 1/2/3/4`
   - `guided_visible`
   - `cued_recall`
   - `hidden_reveal`
   - raw mode labels that are unnecessary in the normal flow
3. Replace those with task-first copy while preserving keys and deterministic behavior.
4. Keep advanced or debugging details only where they are necessary for orientation or recovery from mistakes.
5. Update focused tests in `test/screens/companion_chain_screen_test.dart` and any supporting localization tests.

## Decision Log
- 2026-03-08: Wave 2 starts only after Wave 1 is fully merged and archived so the practice roadmap can resume from clean `main`.

## Validation
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/learn_screen_test.dart`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Start Wave 2 ExecPlan
- [ ] Audit visible practice-screen jargon
- [ ] Simplify learner-facing practice screen wording
- [ ] Run focused validation

## Surprises and Adjustments
- Use this section for any runtime-detail labels that turn out to be required for user orientation and therefore cannot be fully hidden.

## Handoff
- Wave 2 should end with:
  - task-first learner wording across the practice screen
  - less visible stage jargon in the default path
  - no route, schema, or engine-contract changes
- Follow-up risk:
  - the hidden recall runtime itself still waits for Wave 3.
