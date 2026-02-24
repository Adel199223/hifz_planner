# Stage 3 Research Baseline (Hifz Chunk): Hidden Progressive Reveal + Rabt (Sequence Binding)

## Why Stage 3 exists (learning science intent)
Stage 3 is the “stabilization + sequencing” stage for a newly learned chunk:
- Move from verse-level recall to ordered production across the chunk (reduce skips, intrusions, and merge errors).
- Enforce cue-independence: default state is hidden; cues are temporary scaffolds.
- Maintain “desirable difficulty”: mostly successful retrieval with controlled failure + immediate correction + reattempt.
- Strengthen transitions (k-1 → k) to reduce interference/intrusion, especially in confusable passages.

Stage 3 must be harder than Stage 2 but not a collapse loop.
Stage 3 should also generate readiness signals for delayed consolidation (Stage 4) and long-term maintenance (Stage 5).

## Stage 3 definition (what it does)
### Default presentation
- Verse text is hidden by default.
- User attempts from memory; hint ladder exists, but counted progress prioritizes low-hint, unassisted attempts.

### Core mechanics (decision-complete)
1) Per-verse hidden attempts
- Each verse is attempted in a hidden state.
- Assisted attempts are allowed but should not count toward “ready” when above configured hint thresholds.
- After failure: require a brief correction exposure, then re-attempt (avoid long passive rereading).

2) Rabt (linking / sequence binding)
- Deterministic adjacency checks: k-1 → k continuation tasks.
- Each adjacency should be linked at least once over the chunk session (or at least one linking pass per verse, as your model supports).
- Linking can use existing auto-check forms (cloze/ordering/next-word MCQ) where ASR is unavailable.

3) Chunk checkpoint
- Short run-through requiring:
  - chunkPassRate >= threshold (default 0.75), AND
  - no unresolved weak verses, AND
  - linking requirements satisfied.

4) Remediation loop (failed-only)
- If checkpoint fails:
  - only failed verse indexes are cycled,
  - re-check only failed indexes,
  - cap remediation rounds to avoid infinite loops.

5) Output signals for lifecycle hooks (no new stages required now)
- Set telemetry hooks that mark:
  - stage4_candidate: needs delayed consolidation verification (same day pre-sleep or next day).
  - stage5_candidate: ready for long-term spaced maintenance.
These can be encoded via telemetry_json; no schema changes required.

## Guardrails / constraints
- No silent bypass: weak verses must be explicitly handled before declaring Stage 3 completion.
- Temporary cue relief is allowed to prevent collapse, but cue fading must resume and not become a permanent crutch.
- Deterministic scheduling + stable tests: Stage 3 target selection and mode ordering must be deterministic.
- Preserve existing attempt/telemetry conventions (attempt_type, assisted_flag, hint_level, auto_check_* fields, telemetry_json).

## Interface expectations with Stage 2
Stage 2 hands off:
- per-verse readiness signals
- unresolved weak verse list (if Stage 2 budgetFallback)
- optional prelude targets list already supported: stage3WeakPreludeTargets

Stage 3 must support “Guarded Weak Prelude”:
- If stage3WeakPreludeTargets is non-empty:
  - route attempts only through those targets first in deterministic order,
  - cap cue allowance for prelude attempts (e.g., max H1),
  - each target must earn at least one counted pass,
  - then remove it and proceed to normal Stage 3.

## Telemetry_json keys (recommended)
- stage3_step: hidden_attempt | linking | checkpoint | remediation | stage3_weak_prelude
- link_prev_verse_order
- readiness_counted_pass
- cue_baseline / cue_rotated_from (if applicable)
- risk_trigger (if used)
- lifecycle_hook: stage4_candidate | stage5_candidate