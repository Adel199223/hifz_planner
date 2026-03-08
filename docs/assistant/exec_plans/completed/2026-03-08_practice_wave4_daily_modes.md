# ExecPlan: Practice Wave 4 - Daily Practice Modes and Integration

## Purpose
- Make daily practice modes easier to understand from `Today` and `Learn`.
- Frame practice around simple learner goals:
  - new practice
  - review practice
  - delayed check
- Finish the current practice roadmap with clearer entry expectations and repeatable learner walkthroughs.

## Scope
- In scope:
  - clearer daily practice framing in `Today` and `Learn`
  - stronger review-first and delayed-check entry expectations where appropriate
  - minimal integration copy and UI improvements around practice launch paths
  - repeatable learner walkthrough coverage for the daily practice paths
- Out of scope:
  - new route contracts
  - schema or persistence changes
  - hidden-recall engine redesign
  - microphone or voice-aware scoring

## Assumptions
- `/companion/chain` and `mode=new|review|stage4` remain unchanged.
- Wave 1 and Wave 2 already simplified practice entry labels and the core practice screen.
- Wave 3 confirmed the hidden-recall runtime is already aligned with the Stage 3 spec.

## Milestones
1. Audit `Today` and `Learn` for remaining ambiguity in daily practice expectations.
2. Improve daily practice framing and review-first guidance.
3. Add or refine focused tests for the daily launch paths.
4. Validate the integrated practice flow and prepare the roadmap for final closeout.

## Detailed Steps
1. Inspect:
   - `lib/screens/today_screen.dart`
   - `lib/screens/learn_screen.dart`
   - `test/screens/today_screen_test.dart`
   - `test/screens/learn_screen_test.dart`
2. Identify where the learner still needs extra interpretation to choose:
   - start new practice
   - continue review practice
   - do delayed check
3. Refine copy, ordering, and affordances so the intended daily flow is clearer without exposing internal engine jargon.
4. Keep all route and data-model contracts stable.
5. Add or update focused tests to cover the daily integration behavior.

## Decision Log
- 2026-03-08: Wave 4 starts only after Wave 3 is merged and archived so the practice roadmap resumes from a clean baseline.
- 2026-03-08: Wave 4 closes the current practice roadmap and should avoid broadening into a new goals/streaks roadmap.

## Validation
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/learn_screen_test.dart`
- `flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart`
- `dart tooling/validate_localization.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Start Wave 4 ExecPlan
- [x] Audit daily practice integration points
- [x] Improve daily practice mode framing
- [x] Run focused validation

## Surprises and Adjustments
- Use this section for any scope corrections if a daily integration gap turns out to depend on deeper engine or planner changes.
- 2026-03-08: Wave 4 stayed narrow. `Learn` now teaches the best daily practice order and shows whether each entry is ready now or will route through `Today` for guidance.
- 2026-03-08: `Today` keeps one primary coaching action, but now exposes secondary practice-mode shortcuts when other valid modes remain, without changing any route or planner contracts.
- 2026-03-08: Focused validation passed with `today_screen`, `learn_screen`, `navigation_shell_menu`, `flutter analyze`, localization validation, agent docs validation, and workspace hygiene validation.
- 2026-03-08: Narrow Assistant Docs Sync completed for the canonical app brief, assistant bridge, app user guide, and planner guide. Wave 4 is now ready for commit/PR/merge closeout.
- 2026-03-08: PR #23 merged the feature work to `main`; this plan is now archived as part of the roadmap closeout.

## Handoff
- Wave 4 should end with:
  - clearer daily practice mode expectations from `Today` and `Learn`
  - stable route/schema compatibility
  - repeatable learner walkthroughs for new practice, review practice, and delayed checks
- Follow-up risk:
  - after Wave 4, this practice roadmap should close and hand off to a new backlog rather than silently opening more waves.
