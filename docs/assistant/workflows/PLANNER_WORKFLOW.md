# Planner Workflow

## What This Workflow Is For

Use this workflow for onboarding questionnaire, plan activation, daily planning, review grading, calibration, forecast, and scheduler behavior.

## When To Use

Use when changes touch:
- `PlanScreen` or `TodayScreen`
- daily plan generation logic
- spaced repetition scheduler calculations
- calibration sample/apply behavior
- planner settings and progress persistence
- shared planner/forecast projection behavior (`PlanningProjectionEngine`)
- For deep scheduling availability rules or companion chain work, route to `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`.

## What Not To Do

- Do not change DB schema without migration updates.
- Do not bypass transactional writes for review-log + schedule updates.
- Do not change planner constants without updating related tests.

## Primary Files

- `lib/screens/plan_screen.dart`
- `lib/screens/today_screen.dart`
- `lib/data/services/daily_planner.dart`
- `lib/data/services/spaced_repetition_scheduler.dart`
- `lib/data/services/calibration_service.dart`
- `lib/data/services/forecast_simulation_service.dart`
- `lib/data/services/scheduling/planning_projection_engine.dart`
- `lib/data/repositories/settings_repo.dart`
- `lib/data/repositories/schedule_repo.dart`
- `lib/data/repositories/review_log_repo.dart`
- `lib/data/database/app_database.dart`
- `test/screens/plan_screen_test.dart`
- `test/screens/today_screen_test.dart`
- `test/data/services/daily_planner_test.dart`
- `test/data/services/spaced_repetition_scheduler_test.dart`
- `test/data/database/app_database_test.dart`

## Minimal Commands

```powershell
git status --short
rg -n "planToday|applyReviewWithScheduler|Calibration|Forecast" lib/screens lib/data/services lib/data/repositories
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/screens/plan_screen_test.dart
flutter test -j 1 -r expanded test/screens/today_screen_test.dart
flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart
flutter test -j 1 -r expanded test/data/services/spaced_repetition_scheduler_test.dart
flutter test -j 1 -r expanded test/data/database/app_database_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: today plan fails to load.
   - Check settings singleton row and progress row initialization.
2. Symptoms: grading actions fail or schedule state not updating.
   - Verify review-log insert + schedule apply transaction path.
3. Symptoms: forecast/calibration output unexpected.
   - Re-check defaults and distribution parsing in `plan_screen.dart` and services.
   - Verify both planner and forecast paths consume `PlanningProjectionEngine`.
4. Symptoms: planner works on one screen but not another.
   - Trace provider wiring in `database_providers.dart`.

## Handoff Checklist

- planner writes remain transaction-safe where required
- singleton settings/progress assumptions still hold
- targeted planner/scheduler tests pass
- schema-affecting changes include migration updates and DB tests
- keep `docs/assistant/features/PLANNER_USER_GUIDE.md` aligned when planner UX/logic changes materially
