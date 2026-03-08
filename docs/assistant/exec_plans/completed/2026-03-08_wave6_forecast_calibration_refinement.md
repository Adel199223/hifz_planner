# ExecPlan: Wave 6 Forecast and Calibration Refinement

## Purpose
- Make forecast and calibration useful to a non-expert learner instead of feeling like raw planner diagnostics.
- Bring forecast messaging, confidence, and calibration behavior in line with the deterministic Wave 5 scheduler.

## Scope
- In scope:
  - default forecast summary in plain language
  - simple confidence band output
  - calibration wording and UX cleanup
  - quality-signal integration into planner stress and new-work behavior
  - keeping deeper forecast curves behind advanced mode
- Out of scope:
  - adaptive scheduling
  - schema or persistence-contract changes unless a very small compatibility bridge is unavoidable
  - a full scheduler rewrite
  - advanced analytics beyond what the current planner contract needs

## Assumptions
- All research stages are complete; implementation continues by wave.
- Wave 5 is merged, so Today, Forecast, and weekly planning already share one deterministic allocation policy.
- Wave 6 should refine forecast and calibration on top of that shared policy, not introduce a second rule system.
- The safest path is to improve current forecast outputs and calibration inputs before considering any deeper model changes.

## Milestones
1. Audit the current forecast and calibration pipeline against the Stage 5 Wave 6 goals.
2. Implement plain-language forecast summaries, confidence, and calibration cleanup on the existing contracts.
3. Add targeted regression coverage for forecast-vs-Today consistency and quality-signal effects.

## Detailed Steps
1. Audit the current Wave 6 surface:
   - `lib/data/services/forecast_simulation_service.dart`
   - `lib/data/services/daily_planner.dart`
   - `lib/data/services/scheduling/planning_projection_engine.dart`
   - `lib/screens/plan_screen.dart`
   - `lib/screens/today_screen.dart`
2. Identify where the current app already computes:
   - forecast horizon outputs
   - calibration adjustments
   - confidence or uncertainty hints
   - quality/grade signals that can influence planner load
3. Refine the default forecast path so it shows:
   - a plain-language recommendation first
   - a simple confidence band or confidence label
   - advanced forecast curves only behind the existing advanced surface
4. Clean up calibration so it:
   - uses non-expert wording
   - improves planner realism without exposing unnecessary knobs
   - feeds back into planner stress and sustainable new-work behavior where current data allows
5. Add or update targeted tests for:
   - forecast summary behavior
   - confidence output
   - forecast-vs-Today consistency
   - slower/faster quality signal effects on planner load
6. If the implementation reveals a better sequence or required compatibility bridge:
   - update this ExecPlan first
   - update `docs/assistant/exec_plans/active/2026-03-08_product_redesign_execution.md` second
   - then continue

## Decision Log
- 2026-03-08: Wave 6 starts only after Wave 5 so forecast can refine one stable deterministic planner instead of a moving target.
- 2026-03-08: Prefer clearer learner-facing summaries and confidence output before any advanced forecast redesign.
- 2026-03-08: Keep advanced curves available, but hidden behind advanced mode so the default path stays non-expert-friendly.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/forecast_simulation_service_test.dart`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `dart tooling/validate_agent_docs.dart`

## Progress
- [x] Create the Wave 6 branch/worktree and mark it active in the master tracker
- [x] Create this Wave 6 ExecPlan
- [x] Audit the current forecast/calibration path against the Wave 6 spec
- [x] Implement the Wave 6 forecast and calibration refinements
- [x] Validate the branch and prepare the publish path

## Surprises and Adjustments
- Use this section for any mismatch between the current forecast/calibration plumbing and the deterministic Wave 5 planner contract.
- The existing planner already had one shared allocation path from Wave 5, so the safest Wave 6 change was to add a small calibration-quality signal into that shared allocator instead of creating a second forecast-only rule layer.
- `PlanScreen` had one test coupled to the old calibration timing label text, so the test now follows the new plain-language wording instead of the previous label.

## Handoff
- Wave 6 is active on `feat/planner-wave6-forecast-calibration-refine` in `/home/fa507/dev/hifz_planner_wave6`.
- Wave 6 is implemented locally with:
  - a shared calibration-quality signal that adjusts planner stress and new-work budget
  - plain-language forecast summary and confidence output
  - cleaner calibration wording and guidance in `My Plan`
- Validation passed for the touched scope:
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `flutter test -j 1 -r expanded test/data/services/scheduling/daily_content_allocator_test.dart`
  - `flutter test -j 1 -r expanded test/data/services/forecast_simulation_service_test.dart`
  - `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
  - `flutter test -j 1 -r expanded test/screens/plan_screen_test.dart`
  - `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
  - `dart tooling/validate_localization.dart`
  - `dart tooling/validate_agent_docs.dart`
- All research stages are complete; implementation continues by wave.
- Next step: close Wave 6 with docs sync and PR merge
