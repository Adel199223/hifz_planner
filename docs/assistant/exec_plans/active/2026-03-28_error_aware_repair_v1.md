# ExecPlan: Error-Aware Repair V1

## Purpose
- Make weak spots feel more Quran-specific and actionable by letting low review grades optionally record what kind of repair is actually needed.

## Scope
- In scope:
  - optional low-grade repair tagging on the real scheduled-review surfaces
  - specific weak-spot reason text in Today
  - thin weak-spot ordering refinement from stored error type
  - focused service/planner/screen tests
- Out of scope:
  - schema changes
  - automatic similar-verse detection
  - route redesign
  - new settings surfaces
  - web/PWA plumbing

## Assumptions
- The current `last_error_type` enum/DB constraint already supports all required repair tags.
- The shared scheduled-review completion path remains the single source of truth.
- This pass should stay manual-first and low-friction.

## Milestones
1. Extend the shared review-completion path to accept an optional tagged repair type.
2. Add one shared low-grade bottom-sheet prompt for Today and Companion review saves.
3. Carry `lastErrorType` through planner rows and use it for thin weak-spot prioritization plus specific Today reason text.
4. Add focused tests and run the requested validation set.

## Current shipped truth
- Error-Aware Repair V1 is implemented in source on top of Adaptive Queue V1.
- low-grade scheduled-review saves in Today and Companion can optionally record an explicit repair tag.
- dismissing the repair-tag sheet cancels save; only explicit `Skip` or an explicit tag choice persists the review.
- Today now explains weak spots more specifically from stored `last_error_type`.
- No schema expansion was required for this wave.

## Validation
- `flutter pub get`
- `dart run tooling/validate_localization.dart`
- `dart run tooling/validate_agent_docs.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- targeted Flutter tests for the touched files if the environment allows
- `flutter build web`
- `npm run smoke` in `tooling/playwright`

## Handoff
- Keep this as a thin extension of Adaptive Queue V1, not a planner rewrite.
- If Flutter tests still fail, record the exact native-assets `objective_c` / `hook.dill` blocker and continue with the other validations.
