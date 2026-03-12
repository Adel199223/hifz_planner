# ExecPlan: Companion Live ASR Integration

## Purpose
- Add live ASR to the Companion/Planner roadmap on top of the existing evaluator foundation.
- Preserve the current manual Companion flow while making local speech evaluation practical on the user's Windows CUDA machine.
- Keep future chats aligned on one concrete next milestone instead of rediscovering ASR scope from completed plans.

## Scope
- In scope:
- add Windows-safe attempt audio capture for Companion
- integrate a local ASR-backed evaluator behind `activeVerseEvaluatorProvider`
- prefer a local CUDA-backed Whisper-family runtime, with manual grading as fallback
- score ASR output through a verse-constrained Arabic-normalization layer instead of raw transcript equality
- add targeted tests for evaluator/provider/screen behavior
- Out of scope:
- cloud speech APIs or non-essential external network dependencies
- planner weighting changes unrelated to live ASR
- broad user-flow redesign outside the minimal ASR capture/evaluation path
- schema changes unless persistence needs prove they are unavoidable
- broad model bake-offs unless the preferred Whisper-family path is clearly unusable

## Assumptions
- The active roadmap remains the Companion/Planner track unless the user explicitly redirects.
- The user has a CUDA-capable NVIDIA GPU available locally; `nvidia-smi` verified GPU availability on 2026-03-12.
- The user reports Whisper is already available somewhere locally, but the exact runtime/environment has not yet been identified from the stock Python installations.
- A dedicated Python `3.11` environment is the safest target for local ASR runtime setup on this machine.

## Milestones
1. Identify the real local ASR runtime and lock the integration target.
2. Add attempt recording and a narrow local ASR service boundary.
3. Implement verse-constrained ASR evaluation behind the existing evaluator seam.
4. Validate, close out, and docs-sync the milestone using the standardized stage-closeout flow.

## Detailed Steps
1. Confirm the local ASR runtime strategy before code changes:
   - run `nvidia-smi`
   - run `py -0p`
   - probe likely interpreters or envs for `whisper`, `faster_whisper`, `ctranslate2`, and `torch`
   - if Whisper is not discoverable from an existing usable env, create or pin a dedicated Python `3.11` environment outside repo root
2. Prefer `faster-whisper` on CUDA as the primary runtime target:
   - keep `openai-whisper` as a baseline/prototype reference only
   - treat `whisper.cpp` as the packaging fallback if Python-side deployment becomes the bottleneck
   - benchmark at least one latency-oriented model choice and one accuracy-oriented model choice before locking the default
3. Add minimal attempt recording support for Companion:
   - update `pubspec.yaml` with the chosen recording dependency
   - add a narrow recording abstraction under `lib/data/services/companion/`
   - keep the current `Record / Start` user intent intact unless platform validation forces a small copy change
4. Add the local ASR integration boundary:
   - add a local ASR service under `lib/data/services/companion/` (for example, a process-backed transcriber or similar narrow client)
   - keep Flutter-side code responsible only for audio capture, request/response plumbing, and fallback handling
   - keep model/runtime installation assumptions out of the UI layer
5. Implement the ASR-backed evaluator:
   - extend `lib/data/services/companion/verse_evaluator.dart` only as needed while preserving `VerseEvaluationSubmission`
   - add a non-manual evaluator implementation and switch `lib/data/providers/database_providers.dart` to expose it through `activeVerseEvaluatorProvider`
   - keep manual grading available when ASR confidence is low or transcription fails
6. Add a verse-constrained scorer instead of raw transcript comparison:
   - extract or reuse normalization logic from `lib/data/services/companion/stage1_auto_check_engine.dart`
   - normalize expected verse text and ASR output before scoring
   - keep the first milestone conservative: pass/fail gating should be stricter than display-only transcript rendering
7. Update the engine and screen only through the existing seam:
   - keep `lib/data/services/companion/progressive_reveal_chain_engine.dart` on the current evaluator submission/result contract
   - update `lib/screens/companion_chain_screen.dart` to drive recording and ASR-backed evaluation without reworking the broader stage/review UX
8. Add targeted tests:
   - evaluator tests in `test/data/services/companion/verse_evaluator_test.dart`
   - engine persistence/telemetry tests in `test/data/services/companion/progressive_reveal_chain_engine_test.dart`
   - screen/provider override tests in `test/screens/companion_chain_screen_test.dart`
   - add new ASR-service or scorer tests under `test/data/services/companion/` if new files are introduced
9. Close out with the repo standard:
   - run targeted validation
   - commit implementation files first
   - ask the exact Assistant Docs Sync prompt
   - if approved, run targeted docs sync
   - commit docs-only changes separately
   - end with a clean local worktree

## Decision Log
- 2026-03-12: Prefer local `faster-whisper` on CUDA as the first implementation target because the repo already has an evaluator seam, the user has a local NVIDIA GPU, and this is a better engineering fit than building the first milestone around the baseline `openai-whisper` package.
- 2026-03-12: Treat Python `3.11` as the preferred ASR runtime base because the machine default is Python `3.14.3`, which is not the planned target for this milestone.
- 2026-03-12: Keep manual grading as a first-class fallback even after live ASR ships because Quran recitation scoring cannot rely on unconstrained transcript output alone.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/companion/verse_evaluator_test.dart`
- `flutter test -j 1 -r expanded test/data/services/companion/progressive_reveal_chain_engine_test.dart`
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- run new targeted ASR-service/scorer tests if introduced
- `dart run tooling/validate_localization.dart` only if strings change
- after docs sync: `dart run tooling/validate_agent_docs.dart`
- after docs sync: `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`

## Progress
- [x] Create a persistent roadmap continuity anchor for the ASR milestone
- [x] Create this active ExecPlan
- [ ] Verify the actual local Whisper runtime/environment
- [ ] Implement recording and local ASR service boundary
- [ ] Implement ASR-backed evaluator and fallback behavior
- [ ] Run targeted validation
- [ ] Close out with separate feature/docs commits if implementation lands

## Surprises and Adjustments
- `nvidia-smi` confirms CUDA availability, but stock `py -3`, `py -3.11`, and `py -3.12` probes did not expose `whisper`, `faster_whisper`, `ctranslate2`, or `torch`; the user-reported Whisper install is likely in a different environment or toolchain.

## Handoff
- This plan is intentionally created before implementation so future chats can resume the next roadmap milestone directly.
- First resume action: identify the exact local ASR runtime/environment and decide whether the repo should talk to an existing Whisper install or provision a dedicated Python `3.11` env for `faster-whisper`.
- Keep the current evaluator/provider seam intact; do not restart the design from raw screen-engine primitives.
