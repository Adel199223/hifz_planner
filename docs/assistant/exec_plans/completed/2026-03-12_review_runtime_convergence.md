# ExecPlan: Review Runtime Convergence

## Purpose
- Replace the legacy `mode=review` hidden-first engine path with a dedicated deterministic review runtime in the same runtime family as Stage 3 and Stage 4.
- Keep Companion review completion and lifecycle grading unchanged while making review-session behavior explicit, testable, and telemetry-clean.

## Scope
- In scope:
- add `ReviewMode`, `ReviewPhase`, `ReviewRuntime`, and `ChainRunState.review`
- initialize and run a dedicated review runtime for `launchMode=review`
- remove review reliance on the legacy hidden submission path and legacy review telemetry flag
- update Companion review UI labels/cards for the new runtime
- extend targeted engine and screen tests for deterministic review behavior
- Out of scope:
- meaning cue system changes
- planner reinforcement weighting
- ASR / evaluator work
- route changes, schema changes, or lifecycle policy changes

## Assumptions
- `launchMode=review` continues to use `activeStage=hiddenReveal`
- review readiness stays strict: assisted/high-hint attempts can continue practice but do not clear review obligations
- review failures must expose correction before the next counted cold attempt
- Stage 1, Stage 2, Stage 3, and Stage 4 behavior for non-review sessions must not regress

## Milestones
1. Add dedicated review runtime types and engine routing.
2. Update Companion review UI to surface review mode/phase cleanly.
3. Extend targeted tests and validate the milestone.

## Detailed Steps
1. Extend `lib/data/services/companion/companion_models.dart` with review runtime enums/class and add `review` to `ChainRunState`.
2. Refactor `lib/data/services/companion/progressive_reveal_chain_engine.dart` so review sessions initialize/use `ReviewRuntime`, enforce correction exposure, and remove the legacy review branch/flag.
3. Update `lib/screens/companion_chain_screen.dart` to render review runtime cards/labels without changing summary grade-save flow.
4. Extend `test/data/services/companion/progressive_reveal_chain_engine_test.dart` and `test/screens/companion_chain_screen_test.dart`, then run targeted companion/planner validation.

## Decision Log
- 2026-03-12: This milestone only converges review runtime behavior; future roadmap items stay deferred.
- 2026-03-12: Review runtime will reuse existing per-verse hidden-stage readiness signals rather than introducing a new persisted verse-stats model.
- 2026-03-12: Review session startup now seeds lightweight weak/proficiency signals from existing `companion_step_proficiency` rows so review targeting can prioritize weak/risky verses deterministically.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `flutter test -j 1 -r expanded test/data/services/review_completion_service_test.dart`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `dart run tooling/validate_localization.dart`

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three

## Surprises and Adjustments
- Review targeting could not meaningfully distinguish weak/risky verses from easier verses without reusing persisted proficiency data; the implementation now seeds review startup from existing per-ayah proficiency rows without introducing schema changes.
- Review UI tests that previously completed a one-ayah review in one tap had to be updated because the dedicated review runtime now requires the intended hidden-recall/checkpoint progression.

## Handoff
- `launchMode=review` now initializes a dedicated `ReviewRuntime` instead of falling through to the legacy hidden-first submission path.
- Review sessions persist `review_mode` / `review_phase` telemetry, surface a review-specific mode card in Companion, and require correction playback before the next counted review attempt.
- Shared review grade-save and lifecycle governance remain unchanged and continue to pass their existing planner/service regressions.
