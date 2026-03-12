# ExecPlan: Planner Reinforcement Weighting

## Purpose
- Use existing Companion retention signals to make the planner react earlier when memorization quality is weak.
- Keep the active roadmap on the Companion/Planner track; in repo conversations, `roadmap`, `master plan`, and `next milestone` continue to mean that track unless the user redirects.
- Improve daily planning without adding schema or changing the shipped UI copy.

## Scope
- In scope:
- add planner-side reinforcement weighting using existing `companion_step_proficiency` data
- prioritize weaker due reviews earlier when overdue pressure ties or is close
- make weaker retention consume more review budget so new allocation shrinks sooner
- add targeted tests for planner ordering and budget behavior
- Out of scope:
- live ASR, recording, transcription, permissions, or evaluator changes
- new database columns or Drift migrations
- user-facing wording changes unless validation forces them

## Assumptions
- Existing Companion proficiency rows provide enough signal through `proficiencyEma`, pass rate, and last evaluator confidence to derive a useful reinforcement weight.
- Weighting should be additive to the current scheduler, not a replacement for overdue ordering, lifecycle governance, or Stage-4 blocking.
- The first milestone should stay planner-local and avoid expanding into weekly scheduling contracts unless validation shows a consistency gap.

## Milestones
1. Define a planner-side reinforcement signal from existing Companion proficiency data.
2. Apply that signal to due-review ordering and review/new budget pressure.
3. Extend targeted planner tests and validate.

## Detailed Steps
1. Add an active ExecPlan for this milestone under `docs/assistant/exec_plans/active/`.
2. Update `lib/data/services/daily_planner.dart` to:
   - load Companion step-proficiency rows for due units,
   - aggregate per-unit reinforcement weight from existing proficiency/pass/confidence signals,
   - use that weight in due-review sorting,
   - use a weighted review-demand calculation so weaker retention reduces new allocation earlier.
3. Keep `lib/data/services/scheduling/planning_projection_engine.dart` and `ScheduleRepo` contracts stable unless planner validation reveals a required follow-up.
4. Extend `test/data/services/daily_planner_test.dart` with coverage for:
   - weak-retention units sorting ahead of stronger ones when overdue pressure is otherwise equal,
   - weak-retention demand increasing review pressure and reducing/clearing new allocation sooner.
5. Run targeted validation:
   - `flutter analyze --no-fatal-infos --no-fatal-warnings`
   - `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
   - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
6. If implementation becomes significant enough to require docs sync, follow the repo closeout contract after validation.

## Decision Log
- 2026-03-12: Start reinforcement weighting in `DailyPlanner` first because the current gap is planner consumption of already-persisted Companion quality signals, not missing data collection.
- 2026-03-12: Keep schema stable and use existing Companion proficiency rows instead of introducing new planner-specific persistence.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`

## Progress
- [x] Create active ExecPlan
- [x] Implement planner reinforcement weighting
- [x] Add or update planner tests
- [x] Run targeted validation

## Surprises and Adjustments
- Planner tests that seed `companion_step_proficiency` must also seed a real `companion_chain_session` because `last_session_id` is enforced by a foreign key; the helper was updated instead of weakening the test fixture.

## Handoff
- Completed implementation:
  - added planner-side reinforcement weighting derived from existing `companion_step_proficiency` rows,
  - made weak retention sort earlier in due-review planning when overdue pressure is equal or close,
  - weighted review demand so weaker retention increases review pressure and reduces new allocation sooner,
  - kept schema, Stage-4 governance, and the current Today UI wording unchanged.
- Validation completed:
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
  - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- If this milestone is closed out, the next likely Companion/Planner slice is live ASR integration on top of the evaluator foundation, unless planner behavior review identifies another planner-specific follow-up first.
