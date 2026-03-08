# ExecPlan: Practice Wave 3 - Hidden Recall Runtime Completion

## Purpose
- Complete the hidden-recall runtime so the deeper memory phase matches the existing design spec.
- Keep the learner-facing practice flow simple while strengthening the deterministic engine under the hood.

## Scope
- In scope:
  - implement the existing hidden-recall runtime spec in the current practice engine
  - preserve separate review behavior
  - preserve deterministic weak-prelude and correction-gate behavior
  - keep telemetry schema-compatible with existing fields
  - add focused tests for the hidden-recall runtime
- Out of scope:
  - new route contracts
  - schema or persistence redesign
  - microphone, voice-aware checking, or AI scoring
  - broad new product surfaces outside the practice runtime

## Assumptions
- The implementation contract is:
  - `docs/assistant/research/STAGE3_HIDDEN_RECALL_DESIGN_SPEC.md`
- `/companion/chain` and `mode=new|review|stage4` remain unchanged.
- Wave 2 already simplified the learner-facing practice screen, so Wave 3 can focus on runtime depth.

## Milestones
1. Re-read the hidden-recall design spec and compare it to the current engine/runtime.
2. Implement the missing hidden-recall behavior in the deterministic engine.
3. Add or update focused engine and screen tests.
4. Validate the hidden-recall runtime and prepare Wave 3 for docs sync and closeout.

## Detailed Steps
1. Inspect:
   - `lib/data/services/companion/progressive_reveal_chain_engine.dart`
   - `lib/data/services/companion/companion_models.dart`
   - `test/data/services/companion/progressive_reveal_chain_engine_test.dart`
   - `test/screens/companion_chain_screen_test.dart`
2. Cross-check the current implementation against `STAGE3_HIDDEN_RECALL_DESIGN_SPEC.md`.
3. Implement only the missing runtime depth required by the spec.
4. Preserve:
   - review-mode separation
   - weak-prelude ordering
   - correction-before-retry gates
   - existing telemetry field compatibility
5. Validate with focused tests before broader publish steps.

## Decision Log
- 2026-03-08: Wave 3 starts only after Wave 2 is merged and archived so the practice roadmap resumes from a clean baseline.
- 2026-03-08: Wave 3 remains engine-depth only; new learner-facing surface work waits for Wave 4.

## Validation
- `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Start Wave 3 ExecPlan
- [x] Audit current hidden-recall/runtime gaps against the Stage 3 spec
- [x] Implement hidden-recall runtime completion
- [x] Run focused validation

## Surprises and Adjustments
- Use this section for runtime mismatches between the existing engine and the Stage 3 spec, especially if a spec detail would force broader scope than planned.
- 2026-03-08: The current `main` already contains the hidden-recall runtime contract required by the Stage 3 spec, including deterministic weak-prelude routing, correction-before-retry gates, budget fallback, lifecycle hooks, and schema-free Stage-3 telemetry.
- 2026-03-08: Wave 3 therefore closed as a verification-and-alignment pass rather than a new engine patch; no route, schema, or runtime behavior changes were required on this branch.

## Handoff
- Wave 3 should end with:
  - hidden-recall runtime behavior aligned with the existing Stage 3 design spec
  - preserved route/schema compatibility
  - updated focused tests for the engine and practice screen
- Follow-up risk:
  - daily practice framing and integration still waits for Wave 4.
- Current closeout state:
  - focused validation is green
  - no docs sync is needed because no user-facing behavior changed in this verification pass
  - next closeout action is to archive this plan and advance the tracker to Wave 4
