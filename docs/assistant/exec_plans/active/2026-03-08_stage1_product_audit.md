# ExecPlan: Stage 1 Product Audit and Benchmark Matrix

## Purpose
- Produce the Stage 1 deliverables for the staged product evaluation and planner redesign program.
- Ground the redesign in actual repo behavior, official external references, and evidence-backed memorization patterns.

## Scope
- In scope:
- feature-purpose scorecard for current app surfaces
- external benchmark matrix using official product/research references
- ranked strengths, simplification targets, missing features, and planner-specific gaps
- stage handoff summary for the next UX redesign stage
- Out of scope:
- runtime app changes
- schema or algorithm implementation
- later-stage UX, planner, or algorithm specs

## Assumptions
- Stage 1 is research/spec only and should not change app behavior.
- The target product posture is locked to solo learner, simple-first UX, and cross-platform/mobile suitability.
- The planner algorithm remains deferred until later stages.

## Milestones
1. Gather repo-grounded truth on current app surfaces and planner complexity.
2. Gather official external references and learning-science inputs.
3. Publish the Stage 1 audit and benchmark artifact.

## Detailed Steps
1. Inspect current reader, planner, today, companion, and support surfaces from code/docs.
2. Gather official references for Quran.com, Tarteel, Thabit, Quranki, Anki/FSRS, SuperMemo, and learning-science sources.
3. Score current surfaces against the stage rubric.
4. Produce the benchmark matrix and ranked opportunity backlog in `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`.

## Decision Log
- 2026-03-08: Keep Stage 1 as a research artifact only, because the approved staged program requires pause-and-review before Stage 2.
- 2026-03-08: Use an isolated worktree from `main` so the product-evaluation stream does not mix with the unfinished critical-fixes branch.

## Validation
- Check that the research doc includes:
- feature-purpose scorecard
- benchmark matrix
- ranked opportunity backlog
- planner-specific gap list
- Verify no runtime files were changed outside the stage artifacts.

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three

## Surprises and Adjustments
- The current `Plan` screen is significantly more complex than the user-facing guide suggests; this became a primary Stage-1 finding.

## Handoff
- Stage 1 should end with a decision-ready audit artifact and no runtime changes, followed by a pause for approval before Stage 2.
