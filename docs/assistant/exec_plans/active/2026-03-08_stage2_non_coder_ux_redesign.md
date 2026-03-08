# ExecPlan: Stage 2 Non-Coder UX and Journey Redesign

## Purpose
- Convert the Stage 1 product audit into a simple-first, non-coder UX redesign for the solo-learner target.
- Produce implementation-ready UX artifacts without changing runtime code yet.

## Scope
- In scope:
  - define the primary learner journeys
  - redesign the app map for simple-first use
  - assign clear responsibilities to each learner-facing screen
  - classify current features into default, advanced, and hidden/internal layers
  - create a prioritized UX backlog for later implementation
- Out of scope:
  - runtime UI changes
  - planner algorithm redesign
  - schema changes
  - localization changes

## Assumptions
- `Today` should become the main learner home for memorization execution.
- `Plan` should stop behaving like a control panel for first-run users.
- Mobile usability should drive information architecture decisions even before full mobile polish exists.
- Advanced planner controls remain valuable, but should not dominate the default path.

## Milestones
1. Reconfirm Stage 1 findings against current learner-facing docs and app navigation.
2. Define the target simple-first journeys and revised app map.
3. Produce the implementation-ready Stage 2 UX spec and validate docs.

## Detailed Steps
1. Review Stage 1 findings in `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`.
2. Review current learner-facing docs in:
   - `docs/assistant/features/APP_USER_GUIDE.md`
   - `docs/assistant/features/PLANNER_USER_GUIDE.md`
3. Review current routes/navigation in:
   - `lib/app/router.dart`
   - `lib/app/navigation_shell.dart`
   - `lib/screens/learn_screen.dart`
4. Reconfirm benchmark patterns from Quran.com, Tarteel, Thabit, and Quranki.
5. Write Stage 2 deliverable:
   - `docs/assistant/research/STAGE2_NON_CODER_UX_AND_JOURNEY_REDESIGN.md`
6. Validate with:
   - `dart tooling/validate_agent_docs.dart`

## Decision Log
- 2026-03-08: Continued Stage 2 in the isolated `feat/stage1-product-audit` worktree because it is the same research/spec stream and should not be mixed with the uncommitted remediation branch.
- 2026-03-08: Kept Stage 2 as a doc/spec stage only; no runtime edits before the planner product behavior is fully defined.

## Validation
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Reconfirm Stage 1 findings against learner docs and navigation
- [x] Define simple-first journeys and revised app map
- [x] Write Stage 2 UX spec
- [x] Validate docs

## Surprises and Adjustments
- The current route structure already defaults to `/today`, which supports the Stage 1 conclusion that `Today` should become the main learner home.
- The app has both primary navigation and a secondary menu with placeholder-like destinations, which increases choice complexity for first-run users.

## Handoff
- Stage 2 should end with a revised app map, feature visibility policy, and prioritized UX backlog.
- Stop after Stage 2 and ask whether to proceed to Stage 3 planner product redesign.
