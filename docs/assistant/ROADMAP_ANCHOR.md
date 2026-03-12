# Roadmap Anchor

Persistent continuity anchor for future chats and handoffs.

## Default Meaning Of "Roadmap"

- Unless the user explicitly redirects, `roadmap`, `master plan`, and `next milestone` mean the Companion/Planner track.
- Stay on that track until the user explicitly changes routes.
- For new-chat continuation, read this file after `agent.md` and `APP_KNOWLEDGE.md`.

## Current Roadmap State

As of 2026-03-12, the current Companion/Planner roadmap has these recently completed milestones:

- Meaning cue system:
  - feature commit `3927160` - `feat(companion): add source-backed meaning cues`
  - docs commit `348aa21` - `docs(assistant): sync meaning cue behavior and codify stage closeout flow`
- Evaluator foundation:
  - feature commit `148f889` - `feat(companion): add evaluator submission foundation`
  - docs commit `cff43cf` - `docs(assistant): sync evaluator foundation and roadmap defaults`
- Planner reinforcement weighting:
  - feature commit `66323aa` - `feat(planner): add companion reinforcement weighting`
  - docs commit `93ab6d8` - `docs(assistant): sync planner reinforcement weighting behavior`

The latest completed roadmap handoff is:
- `docs/assistant/exec_plans/completed/2026-03-12_planner_reinforcement_weighting.md`

## Next Milestone

The next roadmap milestone is live ASR integration for Companion attempts.

Practical meaning:
- add microphone capture for Companion attempts
- run local transcription/evaluation through the existing evaluator boundary
- keep `activeVerseEvaluatorProvider` as the swap point
- preserve manual grading as a fallback path
- avoid another screen/engine contract rewrite

The active resume plan for that work is:
- `docs/assistant/exec_plans/active/2026-03-12_companion_live_asr.md`

## Local Machine Notes

Verified on 2026-03-12:
- `nvidia-smi` reports an NVIDIA GeForce RTX 4070 Laptop GPU
- driver version `595.79`
- CUDA version `13.2`
- `py -0p` shows installed interpreters for Python `3.11`, `3.12`, `3.13`, and `3.14`
- default `py -3` resolves to Python `3.14.3`

Current runtime caveat:
- package probes on the stock `py -3`, `py -3.11`, and `py -3.12` interpreters did not find `whisper`, `faster_whisper`, `ctranslate2`, or `torch`
- the user reports that Whisper is available somewhere locally, so future work must first identify the actual environment or install path that contains it

## Recommended ASR Direction

Recommended default path:
- use local `faster-whisper` on CUDA in a dedicated Python `3.11` environment
- expose it to Flutter through a narrow local-process boundary
- keep manual grading available whenever ASR is unavailable, low-confidence, or clearly wrong

Why this is the best current fit:
- the app already has a future-ASR-ready evaluator boundary via `VerseEvaluationSubmission` and `activeVerseEvaluatorProvider`
- local GPU inference is practical on this machine
- `faster-whisper` is a more production-friendly Whisper-family runtime than the baseline `openai-whisper` package for desktop latency/resource use

Important constraint:
- do not treat raw transcript equality as the pass/fail rule
- ASR should feed a verse-constrained scorer that normalizes Arabic text and keeps manual fallback available
- the current text-normalization work in `lib/data/services/companion/stage1_auto_check_engine.dart` is the first place to look for extraction or reuse

Fallback options:
- `openai-whisper` is acceptable as a baseline/prototyping reference, but it is not the preferred long-term runtime here
- `whisper.cpp` is the main packaging-oriented fallback if Python-side deployment becomes the bottleneck
- do not expand the first milestone into a broad model bake-off unless Whisper-family results are clearly unusable

## Resume Checklist

1. Open `docs/assistant/exec_plans/active/2026-03-12_companion_live_asr.md`.
2. Verify which local runtime actually contains Whisper, Torch, or CTranslate2.
3. If needed, create or pin a dedicated Python `3.11` environment for the local ASR service.
4. Keep the current manual Companion UX shippable while ASR is added behind the existing evaluator/provider seam.
5. Use the standardized closeout flow when the milestone finishes.

## Code Anchors

- `lib/data/services/companion/verse_evaluator.dart`
- `lib/data/providers/database_providers.dart`
- `lib/data/services/companion/progressive_reveal_chain_engine.dart`
- `lib/data/services/companion/stage1_auto_check_engine.dart`
- `lib/screens/companion_chain_screen.dart`
- `test/data/services/companion/verse_evaluator_test.dart`
- `test/data/services/companion/progressive_reveal_chain_engine_test.dart`
- `test/screens/companion_chain_screen_test.dart`
