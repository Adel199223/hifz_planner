# ExecPlan: Adaptive Hifz Path Wave 0 Docs Alignment

## Purpose
- Re-center the repo around an Adaptive Hifz Path for solo learners without rewriting the app first.
- Import the new product-reset docs into the existing repo structure and make them the active planning canon.
- Keep the current reader, audio, and local-first foundations visible as strengths while the product center shifts to Today's Hifz Path.

## Scope
- In scope:
- add top-level product docs under `docs/strategy`, `docs/roadmap`, `docs/algorithms`, `docs/ux`, `docs/accessibility`, `docs/backlog`, `docs/operations`, `docs/research`, and `docs/domain`
- update `README.md`, `APP_KNOWLEDGE.md`, `docs/assistant/APP_KNOWLEDGE.md`, `docs/assistant/ROADMAP_ANCHOR.md`, `AGENTS.md`, `agent.md`, `docs/assistant/INDEX.md`, and `docs/assistant/manifest.json`
- mark the old live-ASR ExecPlan as dormant rather than completed
- keep routing and continuity clear for fresh chats and future contributors
- Out of scope:
- route rewrites or UI implementation of the Adaptive Hifz Path
- schema changes or queue-model changes
- importing package prompts, patch notes, or raw analysis files as canonical repo docs
- rewriting the non-technical user guides beyond minimal contradiction prevention

## Assumptions
- The reset is active now and replaces Companion/Planner as the default roadmap track.
- `docs/assistant/ROADMAP_ANCHOR.md` is the real continuity file because this repo does not use `SESSION_RESUME.md`.
- The current app surface remains `Today`, `Plan`, `Reader`, and `/companion/chain` until Wave 1 code work lands.
- The best Wave 1 implementation seam is the existing `TodayPlan` builder in `lib/data/services/daily_planner.dart`, with `TodayScreen` as launcher and `/companion/chain` as the session engine.

## Milestones
1. Import the product-reset docs into top-level `docs/`.
2. Update canonical repo entrypoints so they describe the new product direction honestly.
3. Replace roadmap continuity with the Adaptive Hifz Path track and mark the ASR plan dormant.
4. Validate docs contracts and leave a clean handoff for Wave 1.

## Detailed Steps
1. Import only the canonical product docs from the package:
   - `docs/strategy/adaptive-hifz-path-solo-master-plan.md`
   - `docs/roadmap/adaptive-hifz-path-solo-roadmap.md`
   - `docs/algorithms/adaptive-hifz-scheduler-v1.md`
   - `docs/ux/solo-learner-daily-flow.md`
   - `docs/accessibility/adhd-dyslexia-defaults.md`
   - `docs/backlog/wave-1-implementation-backlog.md`
   - `docs/operations/decision-gates-and-pivot-rules.md`
   - `docs/research/research-foundations.md`
   - `docs/domain/quran-memory-model.md`
2. Keep the package prompts, patches, and raw context files out of repo canon.
3. Update top-level docs so newcomers understand the shift:
   - `README.md`
   - `APP_KNOWLEDGE.md`
4. Update assistant routing docs so future chats find the new canon quickly:
   - `docs/assistant/APP_KNOWLEDGE.md`
   - `docs/assistant/ROADMAP_ANCHOR.md`
   - `AGENTS.md`
   - `agent.md`
   - `docs/assistant/INDEX.md`
   - `docs/assistant/manifest.json`
5. Mark `docs/assistant/exec_plans/active/2026-03-12_companion_live_asr.md` as dormant and keep it as reference-only.
6. Run:
   - `dart run tooling/validate_agent_docs.dart`
   - `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`
7. Review the final diff to confirm the pass stayed docs-first and conservative.

## Decision Log
- 2026-03-25: Use top-level `docs/` for product-reset canon and keep `docs/assistant/` as routing/continuity/contracts, because the repo already has a strong assistant-doc layer that should point at product docs rather than absorb them.
- 2026-03-25: Do not import package prompts, patch notes, or raw analysis files as repo canon in Wave 0; they are working aids, not product/source-of-truth docs.
- 2026-03-25: Keep the old live-ASR plan dormant in place instead of moving it to `completed/`, because the roadmap changed and the work was not actually finished.

## Validation
- `dart run tooling/validate_agent_docs.dart`
- `flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart`

## Progress
- [x] Import top-level product docs
- [x] Update repo entrypoints and continuity docs
- [x] Mark old ASR plan dormant
- [x] Run docs validation
- [x] Prepare Wave 1 handoff

## Surprises and Adjustments
- The repo already has meaningful Today/Planner/Companion seams, so Wave 1 should extend those seams rather than replacing them wholesale.
- There is no `SESSION_RESUME.md`; the continuity contract already lives in `docs/assistant/ROADMAP_ANCHOR.md`.

## Handoff
- After this pass, the active product direction should be easy to find from `README.md`, `APP_KNOWLEDGE.md`, and `docs/assistant/ROADMAP_ANCHOR.md`.
- The recommended Wave 1 starting point is:
  - `lib/screens/today_screen.dart`
  - `lib/data/services/daily_planner.dart`
  - `lib/screens/companion_chain_screen.dart`
  - `lib/data/database/app_database.dart`
  - `lib/data/repositories/companion_repo.dart`
