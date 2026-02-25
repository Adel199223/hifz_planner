# Scheduling + Companion Workflow

## What This Workflow Is For

Use this workflow for automatic scheduling preferences, weekly calendar generation, availability interpretation, review-pressure rebalancing, and staged Companion Progressive Reveal Chain behavior.

## Expected Outputs

- Scheduling and companion staged behavior remain deterministic and persisted safely.
- Shared projection/calibration contracts remain consistent.
- Scheduling/companion targeted tests pass.

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

- Don't use this workflow when scope is baseline planner onboarding/today behavior without advanced scheduling/companion changes. Instead use `docs/assistant/workflows/PLANNER_WORKFLOW.md`.
- Don't use this workflow when changes are reader-only UI parity. Instead use `docs/assistant/workflows/READER_WORKFLOW.md`.
- Don't use this workflow when scope is docs-only routing/contract maintenance. Instead use `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`.
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
flutter test -j 1 -r expanded test/data/services/companion/stage1_auto_check_engine_test.dart
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
   - Verify companion FK references and indexes in schema v7 migrations.
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
  - `/companion/chain?unitId=<id>&mode=stage4` -> delayed consolidation runtime (Stage-4 lifecycle gate).
- Stage sequence for `mode=new`:
  - Stage 1 `guided_visible` (Talqin + Retrieval-first):
    - capped `model_echo` exposures, then forced hidden H0 probe
    - hints are user-triggered and locked for the first cold attempt in a probe cycle
    - failed cold attempts require correction exposure before retry
    - per-verse spaced H0 confirmation is time-based (`>= minSpacingMs`, default 120s)
    - checkpoint requires H0+auto-check performance and runs targeted remediation on failed verses only
    - budget fallback seeds unseen verses, marks weak verses, then advances to Stage 2
  - Stage 2 `cued_recall` (deterministic minimal-cue bridge):
    - adaptive cue baseline (`H2` weak / `H1` non-weak) with fading toward `H0`
    - required auto-check by default (until ASR), correction gate, and telemetry-triggered discrimination
    - per-verse readiness window + mandatory linking pass (`k-1 -> k`)
    - checkpoint (`>= 0.75`) + failed-only remediation + bounded remediation rounds
    - budget fallback carries unresolved weak verses into Stage-3 weak-prelude targets
  - Stage 3 `hidden_reveal` (NEW mode deterministic runtime):
    - NEW runs route through Stage-3 runtime (`state.stage3 != null`); review runs stay on legacy hidden-first routing
    - deterministic target priority:
      - weak-prelude targets
      - correction-required verses
      - unresolved weak/risk verses
      - linking deficits
      - readiness deficits
      - deterministic random probe
      - fallback hidden interleave
    - guarded weak-prelude is mandatory when `stage3WeakPreludeTargets` is non-empty (hint cap `H1`, no bypass)
    - any failed Stage-3 retrieval mode requires correction exposure before the next cold attempt
    - checkpoint/remediation remains failed-only with bounded remediation rounds
    - budget overflow is explicit `budgetFallback` (non-terminal), not silent completion
  - Stage 4 delayed consolidation (`hidden_reveal` + lifecycle runtime):
    - launched via `mode=stage4` and routed by runtime marker (`state.stage4 != null`)
    - review mode remains unchanged and never initializes Stage-4 runtime
    - deterministic target priority:
      - correction-required verses
      - unresolved weak/risk targets
      - pending random-start obligations
      - linking deficits
      - readiness deficits
      - checkpoint/remediation targets
    - counted passes stay strict (`unassisted`, hint cap `H1`, required auto-check where mode requires)
    - any failed Stage-4 retrieval mode requires correction exposure before retry
    - outcomes are explicit and persisted:
      - `pass` => lifecycle `stable` + Stage-5 candidate
      - `partial` => unresolved targets persisted + retry due
      - `fail` => strengthening route persisted + retry due
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
  - Stage-2 skip carries unresolved verses into Stage-3 weak-prelude targets.

## Retrieval-Strength Scoring Policy

- Keep retrieval strength derived from hint usage, response latency, and evaluator confidence.
- Exclude Stage-1 `encode_echo` attempts from retrieval-strength aggregates.
- Exclude Stage-3 `encode_echo` correction exposures from retrieval-strength aggregates.
- Exclude Stage-4 lifecycle attempts from Stage-1 `new_memorization` calibration samples.
- Allow Stage-4 lifecycle attempts to contribute to review-quality calibration path.
- Include Stage-1 elapsed chunk time in `new_memorization` calibration samples.
- Keep Stage-3/Stage-4 semantics schema-free in `telemetry_json` (`stage*_mode`, `stage*_phase`, `stage*_step`, risk/readiness/lifecycle keys).
- Avoid binary pass/fail-only calibration inputs; preserve graded signal to improve adaptation.
- If constants are tuned, update both:
  - this workflow doc (policy notes)
  - `APP_KNOWLEDGE.md` validation/location references for impacted modules.
