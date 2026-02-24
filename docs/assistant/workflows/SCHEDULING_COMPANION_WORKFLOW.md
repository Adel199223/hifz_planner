# Scheduling + Companion Workflow

## What This Workflow Is For

Use this workflow for automatic scheduling preferences, weekly calendar generation, availability interpretation, review-pressure rebalancing, and staged Companion Progressive Reveal Chain behavior.

## When To Use

Use when changes touch:
- scheduling preferences JSON contracts or day overrides
- weekly next-7-day plan/session generation
- daily planner and forecast shared projection behavior
- Plan screen scheduling/calendar UI or Today session rendering
- companion chain route, engine, telemetry, proficiency, or calibration bridge
- staged companion ramp contracts (`guided_visible`, `cued_recall`, `hidden_reveal`) and launch mode routing
- companion recitation controls (play + autoplay persistence) and Quran word-hover parity

## What Not To Do

- Do not bypass `PlanningProjectionEngine` with duplicate scheduling logic in UI or service layers.
- Do not store non-versioned scheduling payloads in `app_settings`.
- Do not bypass transactional boundaries for review log + scheduler updates.
- Do not auto-reveal full verse text on chain failure; hint progression is user-driven.

## Primary Files

- `lib/data/database/app_database.dart`
- `lib/data/repositories/settings_repo.dart`
- `lib/data/repositories/companion_repo.dart`
- `lib/data/providers/database_providers.dart`
- `lib/data/services/daily_planner.dart`
- `lib/data/services/forecast_simulation_service.dart`
- `lib/data/services/scheduling/scheduling_preferences_codec.dart`
- `lib/data/services/scheduling/availability_interpreter.dart`
- `lib/data/services/scheduling/weekly_plan_generator.dart`
- `lib/data/services/scheduling/daily_content_allocator.dart`
- `lib/data/services/scheduling/planning_projection_engine.dart`
- `lib/data/services/companion/companion_models.dart`
- `lib/data/services/companion/verse_evaluator.dart`
- `lib/data/services/companion/progressive_reveal_chain_engine.dart`
- `lib/data/services/companion/companion_calibration_bridge.dart`
- `lib/screens/plan_screen.dart`
- `lib/screens/today_screen.dart`
- `lib/screens/companion_chain_screen.dart`
- `lib/app/app_preferences.dart`
- `lib/app/app_preferences_store.dart`
- `lib/ui/quran/quran_word_wrap.dart`
- `lib/data/services/quran_wording.dart`
- `lib/app/router.dart`

## Minimal Commands

```powershell
git status --short
rg -n "scheduling_prefs_json|PlanningProjectionEngine|WeeklyPlan|ProgressiveReveal|companion" lib test
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/screens/plan_screen_test.dart
flutter test -j 1 -r expanded test/screens/today_screen_test.dart
flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart
flutter test -j 1 -r expanded test/ui/quran/quran_word_wrap_test.dart
flutter test -j 1 -r expanded test/app/app_preferences_test.dart
flutter test -j 1 -r expanded test/data/services/tajweed_tags_service_test.dart
flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart
flutter test -j 1 -r expanded test/data/services/forecast_simulation_service_test.dart
flutter test -j 1 -r expanded test/data/database/app_database_test.dart
flutter test -j 1 -r expanded test/data/repositories/settings_repo_test.dart
flutter test -j 1 -r expanded test/data/repositories/companion_repo_test.dart
flutter test -j 1 -r expanded test/data/services/scheduling
flutter test -j 1 -r expanded test/data/services/companion
```

## Failure Modes and Fallback Steps

1. Symptoms: weekly calendar minutes or session counts look stale or unrealistic.
   - Verify both Plan and forecast paths are calling `PlanningProjectionEngine` instead of local rule copies.
2. Symptoms: skip/holiday override does not rebalance the horizon.
   - Validate `AvailabilityInterpreter.resolveTargetMinutesForHorizon` with day overrides and enabled weekdays.
3. Symptoms: new memorization still appears during review overload.
   - Verify pressure bands in `DailyContentAllocator` and propagation into `DailyPlanner`.
4. Symptoms: companion chain gets stuck on one verse.
   - Check interleave threshold/cycle limits and active index transitions in `progressive_reveal_chain_engine.dart`.
5. Symptoms: telemetry/proficiency rows fail to persist.
   - Verify companion FK references and indexes in schema v5 migrations.
6. Symptoms: black circles still appear in Companion or Verse-by-Verse mode.
   - Verify hidden-stage placeholder text is not rendered and end-marker words are suppressed in shared word widget usage.
7. Symptoms: autoplay toggle resets after restart.
   - Verify `AppPreferencesStore.saveCompanionAutoReciteEnabled(...)` write-through and restore path.

## Handoff Checklist

- shared projection behavior is used by both weekly calendar and forecast simulation
- scheduling prefs/overrides are versioned and decode safely when JSON is null/invalid
- weekly calendar reflects recovery mode and review pressure
- companion chain persists per-attempt telemetry and session summary
- companion recitation controls remain optional and non-blocking (`Play current ayah`, persisted autoplay toggle)
- companion/reader shared word rendering suppresses end-marker circles in Verse-by-Verse scope
- retrieval-strength scoring remains hint+latency+confidence based
- all targeted tests and docs validators pass

## Companion Stage Contracts

- Launch mode contract:
  - `/companion/chain?unitId=<id>&mode=new` -> staged ramp for new units.
  - `/companion/chain?unitId=<id>&mode=review` -> hidden-first fast retrieval.
- Stage sequence for `mode=new`:
  - Stage 1 `guided_visible`: full text visible, graded pass per verse.
  - Stage 2 `cued_recall`: first-word baseline cue, graded pass per verse.
  - Stage 3 `hidden_reveal`: hidden-first reveal-on-pass with interleaving.
- Stage memory:
  - persist per-unit unlocked stage in `companion_unit_state`.
  - `mode=new` resumes at stored stage; `mode=review` ignores it.
- Stage events:
  - persist in `companion_stage_event` with `event_type`:
    - `auto_unlock`
    - `user_skip`
    - `resume_stage`
- Skip policy:
  - skip is only allowed in Stage 1 and Stage 2.
  - skip requires explicit confirm UI and applies to remaining verses in that stage for the current run.
  - skip writes telemetry event and advances immediately.

## Retrieval-Strength Scoring Policy

- Keep retrieval strength derived from hint usage, response latency, and evaluator confidence.
- Avoid binary pass/fail-only calibration inputs; preserve graded signal to improve adaptation.
- If constants are tuned, update both:
  - this workflow doc (policy notes)
  - `APP_KNOWLEDGE.md` validation/location references for impacted modules.
