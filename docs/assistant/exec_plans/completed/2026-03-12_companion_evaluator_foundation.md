# ExecPlan: Companion Evaluator Foundation

## Purpose
- Refactor the Companion attempt-evaluation boundary so future ASR can plug in without another engine or screen contract rewrite.
- Keep the current manual Companion UX unchanged while moving evaluation input through a single submission model.
- Treat the active roadmap for this work as the Companion/Planner track; `roadmap`, `master plan`, and `next milestone` refer to that track unless the user redirects.

## Scope
- In scope:
- Add a unified evaluation-submission model in the Companion evaluator layer.
- Replace the manual-only evaluator provider with a generic active evaluator provider bound to the manual fallback evaluator for now.
- Refactor `ProgressiveRevealChainEngine.submitAttempt(...)` and stage/review submission paths to consume the unified submission model.
- Keep current attempt persistence fields and current manual UI behavior unchanged.
- Add focused tests for the evaluator boundary, engine persistence, and provider override path on the Companion screen.
- Out of scope:
- Live ASR, audio recording, transcription, permissions, external speech APIs, and planner reinforcement weighting.
- UI/label changes beyond the internal evaluator wiring needed to preserve the existing flow.

## Assumptions
- Manual pass/fail remains the only active evaluation input in this milestone.
- Existing persistence columns for evaluator mode, evaluator confidence, and auto-check metadata are sufficient; no schema change is needed.
- Assistant Docs Sync will happen only after implementation validation and explicit user approval per repo policy.

## Milestones
1. Create the evaluator submission model and generic provider boundary.
2. Refactor the engine and screen to use the new evaluator contract without changing UX.
3. Add targeted tests and run validation.

## Detailed Steps
1. Add an active ExecPlan for the evaluator-foundation milestone in `docs/assistant/exec_plans/active/`.
2. Update `lib/data/services/companion/verse_evaluator.dart` to introduce a unified submission payload that includes manual decision plus optional future ASR transcript/confidence fields.
3. Update `lib/data/providers/database_providers.dart` to expose `activeVerseEvaluatorProvider`, bound to `ManualFallbackVerseEvaluator`.
4. Refactor `lib/data/services/companion/progressive_reveal_chain_engine.dart` so `submitAttempt(...)` and all stage/review submission paths accept the unified submission model and persist evaluator mode/confidence from the evaluator result.
5. Update `lib/screens/companion_chain_screen.dart` to use the generic evaluator provider and build the unified submission model while keeping the current manual correct/incorrect flow.
6. Add `test/data/services/companion/verse_evaluator_test.dart` and extend the engine/screen tests to cover the new evaluator boundary and provider override behavior.
7. Run:
   - `flutter analyze --no-fatal-infos --no-fatal-warnings`
   - `flutter test -j 1 -r expanded test/data/services/companion/verse_evaluator_test.dart`
   - `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
   - `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
   - `dart run tooling/validate_localization.dart` only if strings change
8. After implementation validation, ask exactly: `Would you like me to run Assistant Docs Sync for this change now?`

## Decision Log
- 2026-03-12: Implement evaluator foundation before live ASR so the engine and UI contract stabilize once.
- 2026-03-12: Preserve the current manual `Record / Start` flow and bottom-sheet grading to avoid changing the shipped Companion UX in this milestone.
- 2026-03-12: Treat `roadmap`, `master plan`, and `next milestone` as Companion/Planner aliases unless the user explicitly redirects.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/companion/verse_evaluator_test.dart`
- `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `dart run tooling/validate_localization.dart` only if strings change
- After docs sync, if approved:
  - `dart run tooling/validate_agent_docs.dart`
  - `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`

## Progress
- [x] Create active ExecPlan
- [x] Refactor evaluator boundary and provider wiring
- [x] Update Companion engine and screen usage
- [x] Add or update tests
- [x] Run targeted implementation validation
- [x] Ask the required Assistant Docs Sync prompt

## Surprises and Adjustments
- The screen override test needed to cross the first cold-probe submission boundary, not just reach it, because the evaluator only runs once the current manual flow actually submits a graded cold attempt.

## Handoff
- Completed implementation:
  - added `VerseEvaluationSubmission` to carry manual input now and future ASR metadata later,
  - replaced the manual-only provider with `activeVerseEvaluatorProvider`,
  - refactored `ProgressiveRevealChainEngine.submitAttempt(...)` and stage/review paths to consume unified evaluator submissions,
  - kept the Companion `Record / Start` flow and manual correct/incorrect sheet unchanged,
  - added evaluator, engine, and screen coverage for the new boundary.
- Validation completed:
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `flutter test -j 1 -r expanded test/data/services/companion/verse_evaluator_test.dart`
  - `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
  - `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `dart run tooling/validate_localization.dart` was not needed because no localization strings changed.
- Planner reinforcement weighting remains the next Companion/Planner milestone after this evaluator foundation is in place.
