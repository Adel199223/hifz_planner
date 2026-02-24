# Stage-3 Hidden Recall Design Spec (Repo-Grounded, Spec-Only)

## Executive summary
Stage 3 is the final in-session stage for NEW memorization, focused on hidden retrieval robustness and sequence binding (rabt) across the chunk. This spec defines a deterministic Stage-3 runtime contract for later implementation while preserving current repo constraints: existing stage codes, hint ladder, guarded weak-prelude behavior, review-mode behavior, typed telemetry columns, and schema version. This document is spec-only; it introduces no runtime or schema changes in this task.

## Stage-3 goals + measurable outcomes
Stage 3 goals:
1. Stabilize hidden recall with minimal cue dependence.
2. Strengthen sequence binding (`k-1 -> k`) to reduce skips, order breaks, and intrusions.
3. Improve discrimination on weak/confusable verses using targeted, deterministic micro-drills.
4. Produce reliable lifecycle signals for delayed consolidation (Stage 4 candidate) and long-term maintenance (Stage 5 candidate), without introducing new in-session stages now.

Measurable outcomes for Stage 3 completion (defaults, tunable in Stage3Config):
1. Chunk checkpoint pass rate reaches configured threshold (default `0.75`).
2. Every verse meets Stage-3 readiness criteria (windowed counted-pass criteria + linking requirement).
3. Guarded weak-prelude target list is empty before normal completion.
4. Failure handling includes correction exposure before next cold attempt in correction-required states.

## Repo grounding map
Current repo truth that this spec must preserve:

1. Stage code and hint ladder:
- `enum HintLevel` in `lib/data/services/companion/companion_models.dart:1`
- `enum CompanionStage` with `hidden_reveal` in `lib/data/services/companion/companion_models.dart:101`

2. Existing Stage-3 weak-prelude state:
- `ChainRunState.stage3WeakPreludeTargets`
- `ChainRunState.stage3WeakPreludeCursor`
- in `lib/data/services/companion/companion_models.dart:1064`

3. Current hidden-stage execution path:
- `submitAttempt(...)` entrypoint in `lib/data/services/companion/progressive_reveal_chain_engine.dart:534`
- fallback into `_submitLegacyAttempt(...)` in `lib/data/services/companion/progressive_reveal_chain_engine.dart:593`
- legacy hidden handler `_submitLegacyAttempt(...)` in `lib/data/services/companion/progressive_reveal_chain_engine.dart:1746`

4. Guarded weak-prelude routing + `H1` cap:
- weak-prelude active check and hint cap in legacy path around `lib/data/services/companion/progressive_reveal_chain_engine.dart:1762`
- `_routeStage3WeakPrelude(...)` in `lib/data/services/companion/progressive_reveal_chain_engine.dart:3143`
- prelude routing uses `HintLevel.letters` at `lib/data/services/companion/progressive_reveal_chain_engine.dart:3174`

5. Existing hidden interleave routing:
- `_routeNextHiddenVerse(...)` in `lib/data/services/companion/progressive_reveal_chain_engine.dart:3222`
- interleave controls from config (`maxAttemptsBeforeInterleave`, `maxInterleaveCyclesPerVerse`) around `lib/data/services/companion/progressive_reveal_chain_engine.dart:3258`

6. Attempt persistence path:
- engine persistence helper `_persistAttempt(...)` in `lib/data/services/companion/progressive_reveal_chain_engine.dart:2844`
- repo insert API `insertVerseAttempt(...)` in `lib/data/repositories/companion_repo.dart:53`

7. Typed telemetry column constraints:
- `CompanionVerseAttempt` table in `lib/data/database/app_database.dart:297`
- `stage_code` allowed set in `lib/data/database/app_database.dart:319`
- `attempt_type` allowed set in `lib/data/database/app_database.dart:327`
- `telemetry_json` in `lib/data/database/app_database.dart:389`

8. Existing Stage-3 UI signal:
- weak-prelude banner key `companion_stage3_weak_prelude_banner` in `lib/screens/companion_chain_screen.dart:1164`
- dynamic prelude baseline and effective hint capping in `lib/screens/companion_chain_screen.dart:668`

## Deterministic Stage-3 state machine (phases + transitions)
Proposed implementation-phase state machine (not implemented in this task):

1. Phases:
- `prelude`
- `acquisition`
- `checkpoint`
- `remediation`
- `completed`
- `budgetFallback`
- `skipped`

2. High-level transition graph:
- Enter Stage 3 -> `prelude` when `stage3WeakPreludeTargets` is non-empty, else `acquisition`.
- `prelude` -> `acquisition` only when all prelude targets are cleared by counted passes.
- `acquisition` -> `checkpoint` when all verses satisfy `Stage3Ready` defaults.
- `checkpoint` -> `completed` on pass.
- `checkpoint` -> `remediation` on fail when remediation rounds remain.
- `remediation` -> `checkpoint` after failed-only remediation cycle.
- Any phase -> `budgetFallback` if budget cap is reached with unresolved requirements.
- Any retrieval-mode failure can transition mode to `correction` gate before next cold attempt.

3. Runtime concepts for later implementation:
- `Stage3Mode`: `weakPrelude|hiddenRecall|linking|discrimination|correction|checkpoint|remediation`
- `Stage3Phase`: `prelude|acquisition|checkpoint|remediation|completed|budgetFallback|skipped`
- Future types: `Stage3Config`, `Stage3WindowEntry`, `Stage3VerseStats`, `Stage3CheckpointOutcome`, `Stage3Runtime`
- Future extension points: `ProgressiveRevealChainConfig`, `ChainVerseState`, `ChainRunState`, `VerseAttemptTelemetry` (implementation phase only)

## Mode definitions
1. `weakPrelude`:
- Mandatory first when `stage3WeakPreludeTargets` is non-empty.
- Routes only through prelude targets in deterministic order.
- Cue allowance capped at `H1` (`letters`).
- Target removed only after counted pass.

2. `hiddenRecall`:
- Default Stage-3 retrieval mode.
- Verse text hidden by default.
- User may request hints; counted readiness remains strict.

3. `linking`:
- Deterministic adjacency checks (`k-1 -> k` continuation).
- Used to enforce sequence stability beyond isolated verse retrieval.

4. `discrimination`:
- Telemetry-triggered drill mode for weak/risk/confusable cases.
- Uses existing deterministic auto-check primitives (no lexical-similarity layer in this milestone).

5. `correction`:
- Any failed retrieval/linking/discrimination/checkpoint attempt enters correction-required gate.
- Requires correction exposure before next cold attempt.

6. `checkpoint`:
- Chunk-level hidden gate using strict counted criteria.

7. `remediation`:
- Failed-only retry loop.
- Re-check failed-only set.
- Bounded by remediation round cap.

## Verse selection/interleaving/confusable policy
Deterministic target priority order (exact):
`weak-prelude list -> correction-required -> unresolved weak/risk -> linking deficits -> readiness deficits -> deterministic random-start probes -> fallback hidden interleave`

Policy details:
1. Prelude lock:
- When prelude targets exist, no non-prelude verse can be selected.

2. Risk targeting:
- Weak/risk verses are prioritized ahead of general unresolved verses.

3. Linking priority:
- Verses lacking required linking passes are prioritized before already-linked verses.

4. Readiness deficits:
- Verses below readiness window thresholds are prioritized next.

5. Deterministic random-start probes:
- Random-start probes are deterministic (seeded by stable session/context identifiers) and scheduled at a fixed cadence.

6. Fallback interleave:
- Reuse hidden interleave principles from existing hidden routing logic to avoid repetitive lock-on failures.

7. Confusable policy (this milestone):
- Triggered by telemetry/risk signals only, not lexical similarity modeling.

## Pass/fail/readiness thresholds (Stage3Config defaults (tunable))
All values below are defaults and must remain tunable in future `Stage3Config`.

1. Counted pass default:
- evaluator pass AND required auto-check pass AND `assisted_flag == 0` AND `hint_level <= H1`.

2. Verse readiness default:
- rolling window size `4`
- counted passes in window `>=3`
- counted `H0` passes `>=2`
- linking passes `>=1`
- weak/confusable verses require `>=1` counted `H0` pass.

3. Chunk gate default:
- `chunkPassRate >= 0.75`
- all verses ready
- weak-prelude list empty
- linking requirements satisfied.

4. Remediation defaults:
- failed-only targeting
- failed-only re-check
- remediation round cap `2`.

5. Budget safety default:
- explicit `partial/budgetFallback` if unresolved at budget end.
- no silent completion.

6. Desirable-difficulty controller defaults:
- target counted success band `0.70..0.85`
- temporary cue relief allowed on collapse
- mandatory return to strict baseline after temporary relief.

7. Spacing robustness defaults:
- deterministic in-session spaced re-probes for weak/risk verses.
- unresolved spacing obligations map to lifecycle hook instead of silent pass.

## Error handling + correction gating rules
1. Failure handling rule:
- Failed hidden recall/linking/discrimination/checkpoint/remediation attempt sets correction-required state.

2. Correction gate rule:
- No subsequent cold attempt is accepted until correction exposure is submitted.

3. Correction exposure semantics:
- Short, structured correction only (no long passive rereading loop).
- After correction, return to deterministic target/mode selection flow.

4. No blind failure loops:
- repeated failed cold attempts without correction are not permitted.

## Telemetry + metrics framework (schema-free)
No schema migration in this phase. Stage-3 semantics are encoded in `telemetry_json`.

Required `telemetry_json` keys for Stage 3:
1. `stage3_step`: `hidden_attempt|linking|discrimination|checkpoint|remediation|stage3_weak_prelude|correction_exposure`
2. `stage3_mode`
3. `stage3_phase`
4. `link_prev_verse_order`
5. `readiness_counted_pass`
6. `cue_baseline`
7. `cue_rotated_from`
8. `risk_trigger`
9. `stage3_error_type`
10. `lifecycle_hook`: `stage4_candidate|stage5_candidate`

Metrics interpretation defaults:
1. Chunk pass and verse readiness are computed from counted-pass attempts only.
2. Assisted attempts above threshold are retained diagnostically but excluded from counted readiness.
3. `encode_echo` remains excluded from retrieval-strength aggregates (invariant preserved).

## Stage-1/2 alignment contract + minimal required adjustments
Locked statements:
1. `stage3WeakPreludeTargets` must be consumed first with no bypass.
2. Review mode remains hidden-fast and unchanged.
3. Future patch note (spec-only, not implemented now): make `time_on_verse_ms` / `time_on_chunk_ms` attribution stage-aware for Stage-3 attempts.

Minimal compatibility notes:
1. Keep stage codes and hint ladder unchanged.
2. Keep typed telemetry columns unchanged and encode Stage-3 semantics in `telemetry_json`.

## Serious gamification model
Design rules:
1. Rewards correctness and consistency over speed.
2. Uses gentle streak cues to support adherence without punitive collapse.
3. Preserves reverence and avoids mechanics that incentivize sloppy throughput.

Quests (exact examples):
1. `3 cold-start H0 passes`
2. `1 linking set`
3. `1 discrimination set`

Mastery indicators:
1. Verse/chunk mastery indicators map directly to Stage-3 readiness and stability criteria.

Explicit bans:
1. speed bonuses
2. default leaderboard
3. hearts/lives punishment loops

## Risks/failure modes + mitigations
1. cue dependence
- Mitigation: counted-pass strictness requires low-hint unassisted performance.
- Mitigation: weak-prelude enforces `H1` cap and requires successful clearance before normal flow.

2. infinite remediation loops
- Mitigation: remediation rounds are bounded by configurable caps.
- Mitigation: explicit `budgetFallback` terminal path prevents endless retries.

3. silent weak bypass
- Mitigation: prelude targets are mandatory-first and cannot be bypassed.
- Mitigation: checkpoint completion requires no unresolved weak targets.

4. nondeterminism
- Mitigation: deterministic target-priority ordering is fixed and explicit.
- Mitigation: deterministic random-start probe scheduling uses stable seeding.

5. telemetry drift
- Mitigation: lock `telemetry_json` key contract for Stage-3 semantics.
- Mitigation: preserve retrieval aggregate invariants (`encode_echo` excluded).

## References (baseline report + inspected repo files)
1. `docs/assistant/research/STAGE3_RESEARCH_BASELINE.md`
2. `lib/data/services/companion/companion_models.dart`
3. `lib/data/services/companion/progressive_reveal_chain_engine.dart`
4. `lib/screens/companion_chain_screen.dart`
5. `lib/data/repositories/companion_repo.dart`
6. `lib/data/database/app_database.dart`
