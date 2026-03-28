# ExecPlan: Adaptive Queue V1

## Purpose
- Make Today feel more like a real solo memorization companion by surfacing lock-in, weak spots, recent review, and maintenance from durable per-unit signals instead of a thin surface split.

## Scope
- In scope:
  - minimal roadmap continuity update
  - durable adaptive state on `companion_lifecycle_state`
  - adaptive grade-to-memory updates from scheduled review completion
  - planner-derived adaptive buckets and adaptive debt
  - Today queue sections and calm reason text driven by planner truth
  - focused DB/service/widget tests for the touched scope
- Out of scope:
  - reader replacement
  - teacher mode
  - AI recitation scoring
  - mutashabihat automation
  - web plumbing, PWA work, or route redesign

## Assumptions
- The completed browser-first stabilization pass is now continuity-only, not the active product milestone.
- `schedule_state.last_grade_q`, `schedule_state.last_review_day`, `companion_lifecycle_state.lifecycle_tier`, and `companion_step_proficiency` remain the canonical existing truths to build on.
- Adaptive Queue V1 should stay deterministic, explainable, and reviewable.

## Milestones
1. Extend durable per-unit lifecycle state with narrow adaptive signals.
2. Persist adaptive updates from scheduled review completion.
3. Derive planner buckets and adaptive debt from durable signals.
4. Surface planner-backed queue sections and calm reasons on Today.
5. Validate touched scope, sync targeted docs, close out with commits, and verify a clean pushed branch.

## Detailed Steps
1. Update `docs/assistant/ROADMAP_ANCHOR.md` for continuity and create this active ExecPlan.
2. Bump the Drift schema in `lib/data/database/app_database.dart` and add `weak_spot_score`, `recent_struggle_count`, and `last_error_type` to `companion_lifecycle_state`.
3. Add typed adaptive-state helpers in `lib/data/services/adaptive_queue_policy.dart` and `lib/data/repositories/companion_repo.dart`.
4. Update `lib/data/services/review_completion_service.dart` so scheduled review grading persists adaptive state with exact V1 rules.
5. Update `lib/data/services/daily_planner.dart` so due rows are classified into `lockIn`, `weakSpot`, `recentReview`, and `maintenance`, and feed adaptive debt into the existing allocator.
6. Update `lib/screens/today_path.dart` and `lib/screens/today_screen.dart` so Today consumes planner buckets directly and shows one calm reason line for review rows.
7. Update focused tests:
   - `test/data/database/app_database_test.dart`
   - `test/data/services/review_completion_service_test.dart`
   - `test/data/services/daily_planner_test.dart`
   - `test/screens/today_path_test.dart`
   - `test/screens/today_screen_test.dart`
8. Run requested validation plus Drift regeneration, record the known Flutter test blocker if it still reproduces, and create a clean review ZIP in Downloads.

## Decision Log
- 2026-03-28: Reuse `companion_lifecycle_state` instead of creating a new table, because the repo already has a durable per-unit companion memory row keyed by `unitId`.
- 2026-03-28: Keep `DailyContentAllocator` unchanged and make review pressure more truthful by feeding it adaptive debt minutes.
- 2026-03-28: Keep Today route kinds stable (`dueReview`, `weakSpot`, `newUnit`, `stage4Due`, `resume`) and only change how rows are bucketed and explained.

## Validation
- `flutter pub get`
- `dart run tooling/validate_localization.dart`
- `dart run tooling/validate_agent_docs.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- targeted Flutter tests for touched files if the environment allows
- `flutter build web`
- existing Playwright smoke suite

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three
- [x] Milestone four
- [x] Milestone five

## Surprises and Adjustments
- The repo already had real reinforcement pressure from `companion_step_proficiency`; Adaptive Queue V1 can layer on top of that instead of replacing it.
- TodayPath was still inventing weak spots from `reinforcementWeight` alone, so the main UI adjustment is to trust planner-assigned buckets directly.
- Drift/build_runner regeneration for the generated lifecycle surface is still tooling debt in this environment; runtime schema repair and custom SQL are the intentional bridge for closeout.

## Handoff
- Adaptive Queue V1 is now implemented in source and closed enough for continuity.
- Browser-first stabilization remains continuity-only; the next milestone should strengthen the memorization engine itself rather than return to more web plumbing.
- Keep the exact validation caveats recorded:
  - local `flutter test` execution is still blocked by the `objective_c` `hook.dill` native-assets failure in this environment
  - `flutter build web` still succeeds with the known non-fatal `CupertinoIcons` and Drift wasm dry-run warnings
