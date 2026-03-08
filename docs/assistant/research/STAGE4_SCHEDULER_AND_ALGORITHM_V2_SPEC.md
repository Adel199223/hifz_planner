# Stage 4 Scheduler and Algorithm V2 Spec

## Executive Summary

Stage 4 defines the first planner algorithm that fully matches the redesigned product:
- heuristic first
- deterministic
- auditable
- plain-language explainable
- resilient when the learner misses work or slows down

This algorithm is not trying to be maximally clever.
It is trying to be:
- trustworthy
- understandable
- strong enough to protect retention under real-life disruption

Core decision:
- delayed durability first
- critical review next
- sustainable new memorization last

## Design Constraints

The V2 algorithm must:
- work with the current repo’s main planning data wherever possible
- preserve the app’s Stage-4 delayed durability concept
- stay deterministic and reproducible
- produce user-facing explanations, not only internal outputs

The V2 algorithm must not:
- depend on opaque machine learning
- require advanced knobs for normal use
- optimize volume at the expense of retention stability

## Primary Evidence Inputs

Current product/code baseline:
- `lib/data/services/daily_planner.dart`
- `lib/data/services/spaced_repetition_scheduler.dart`
- `lib/data/services/forecast_simulation_service.dart`
- `lib/data/services/calibration_service.dart`
- `lib/data/services/scheduling/planning_projection_engine.dart`
- `lib/data/services/scheduling/daily_content_allocator.dart`
- `lib/data/services/scheduling/weekly_plan_generator.dart`

External references:
- Anki deck options / FSRS framing:
  - https://docs.ankiweb.net/deck-options
- SuperMemo algorithm reference:
  - https://www.super-memory.com/help/smalg.htm
- Tarteel goals and memorization workflow references:
  - https://support.tarteel.ai/hc/en-us/articles/32486640388877-How-do-I-use-the-Goals-feature
  - https://support.tarteel.ai/en/articles/12414416-hide-ayahs
- Learning-science references collected in Stage 1:
  - https://pubmed.ncbi.nlm.nih.gov/33094555/
  - https://pubmed.ncbi.nlm.nih.gov/37856684/
  - https://pubmed.ncbi.nlm.nih.gov/27027887/
  - https://pubmed.ncbi.nlm.nih.gov/27530500/

## Objective Priorities

The V2 scheduler optimizes in this order:

1. delayed durability
2. critical review protection
3. sustainable new memorization
4. continuity after disruption
5. explainable tradeoffs

Meaning:
- mandatory Stage-4 due work and failed/overdue delayed checks come before fresh new memorization
- overdue review is more urgent than ideal new progress
- new memorization is only assigned when the day still looks sustainable after retention protection

## Core State Model

The scheduler produces two related states.

## Learner mode

This is the current planning posture:
- `easy`
- `normal`
- `intensive`
- `recovery`
- `revision_only`

## Plan health

This is the current stress state of the plan:
- `on_track`
- `tight`
- `overloaded`

Rules:
- learner mode can be user-chosen or system-suggested
- plan health is computed from current pressure
- `recovery` and `revision_only` override normal new-work behavior

## Capacity Model

The algorithm separates ideal capacity from effective capacity.

## 1. Base capacity

Base capacity comes from current scheduling interpretation:
- `scheduling_prefs_json`
- `scheduling_overrides_json`
- `daily_minutes_default`
- active weekday structure
- day overrides and revision-only days

This is already supported by:
- `PlanningProjectionEngine`
- `AvailabilityInterpreter`
- `WeeklyPlanGenerator`

## 2. Effective capacity

Effective capacity is what the scheduler actually spends today after applying planner state.

It is influenced by:
- base capacity minutes
- learner mode
- current review pressure
- mandatory Stage-4 due work
- missed-session or missed-day recovery
- calibrated pace

Effective capacity rule:
- do not assume the full day can be spent on new memorization just because the time exists on paper

## 3. Capacity floor

The algorithm defines a practical minimum threshold for new work.

If remaining safe minutes after high-priority work are below the minimum viable new threshold:
- new memorization is paused for that day

This protects against tiny token new assignments that create future liability without meaningful progress.

## Demand Buckets

The daily workload is divided into deterministic buckets.

## Bucket A: Mandatory Stage-4 due

Includes:
- `retry_required`
- `next_day_required`

Priority:
- highest

Policy:
- planned before everything else
- blocks new memorization by default
- may allow explicit manual override, but only with explanation

## Bucket B: Critical review

Includes:
- overdue review
- due-today review
- high-lapse or low-stability units already in the review queue

Priority:
- second

Policy:
- sorted by:
  1. overdue days descending
  2. lower review maturity first
  3. higher lapse burden

This largely matches current repo sorting and should be preserved.

## Bucket C: Optional strengthening and catch-up

Includes:
- optional Stage-4 due
- unresolved but non-mandatory strengthening work
- near-due smoothing work when pressure is already rising

Priority:
- after mandatory retention work, before new only when stress is elevated

## Bucket D: New memorization

Includes:
- newly generated units from the cursor

Priority:
- last

Policy:
- limited by:
  - learner mode
  - daily caps
  - calibrated pace
  - current plan health
  - minimum viable threshold

## Stress Computation

The algorithm computes a deterministic stress score.

## Weighted demand

Define:
- `mandatoryStage4Minutes`
- `criticalReviewMinutes`
- `optionalCatchUpMinutes`
- `safeCapacityMinutes`

Then:

`weightedDemand = (mandatoryStage4Minutes * 1.25) + (criticalReviewMinutes * 1.10) + (optionalCatchUpMinutes * 0.35)`

`stressScore = weightedDemand / max(safeCapacityMinutes, 1)`

Why weighted:
- mandatory delayed checks are more expensive to ignore than optional catch-up
- near-due future work should influence caution, but not dominate today’s plan

## Health thresholds

Recommended deterministic thresholds:
- `on_track`: `stressScore < 0.85`
- `tight`: `0.85 <= stressScore < 1.15`
- `overloaded`: `stressScore >= 1.15`

Escalation rules:
- any overdue mandatory Stage-4 item can force at least `tight`
- repeated multi-day backlog or explicit recovery trigger forces `recovery`
- user-forced revision-only bypasses health-based new assignment and sets `revision_only`

## Daily Allocation Policy

The scheduler allocates minutes in four passes.

## Pass 1: Reserve mandatory durability work

Reserve minutes for:
- mandatory Stage-4 due
- required strengthening caused by Stage-4 failure or unresolved targets

If mandatory work alone consumes most of the day:
- show recovery or minimum-day plan
- pause new memorization

## Pass 2: Allocate critical review

Fill review budget using sorted critical-review rows.

Rules:
- overdue review is never ignored to preserve new volume
- if review cannot fully fit, leftover review becomes explicit backlog, not hidden loss

## Pass 3: Decide whether new memorization is allowed

New memorization is allowed only if:
- learner mode is not `revision_only`
- learner mode is not currently `recovery` without new allowance
- mandatory Stage-4 blocking is cleared or explicitly overridden
- remaining safe minutes exceed the minimum new threshold
- plan health and quality signals permit it

## Pass 4: Assign sustainable new memorization

Compute sustainable new budget from:
- remaining minutes after priority work
- preset target share
- current pace estimate
- quality modifier
- hard caps on pages/units

Suggested preset base new-share targets:
- `easy`: 0.15 to 0.22 of the day
- `normal`: 0.25 to 0.33 of the day
- `intensive`: 0.35 to 0.42 of the day
- `recovery`: 0.00 to 0.10 of the day
- `revision_only`: 0.00

State modifiers:
- `on_track`: full preset share
- `tight`: half preset share
- `overloaded`: zero or near-zero new share

Quality modifier:
- if recent quality is weak, reduce the new share further

## Soft Blocks and Overrides

## Soft blocks

Soft blocks are automatic restrictions that protect retention.

Examples:
- mandatory Stage-4 due blocks new by default
- overloaded state reduces or pauses new
- revision-only mode pauses new

## Overrides

Overrides are allowed, but should be deliberate and temporary.

Rules:
- a one-day override should not silently rewrite the baseline plan
- override explanations must say what risk is being accepted
- forecast confidence should be lowered temporarily after repeated overrides

## Missed-Session Recovery Policy

The V2 algorithm treats disruption as a normal planner case, not an exception.

## One missed session

Policy:
- keep the learner in the current mode if stress remains manageable
- reduce new work for the next day if needed
- surface a short recovery recommendation, not a full reset

Recommended outcome:
- `minimum_day` or `short_day` plan

## One missed day

Policy:
- evaluate stress after due carryover
- often enter `tight`; sometimes `recovery`
- strongly reduce new work the next day

Recommended outcome:
- mandatory Stage-4 and most important review first
- new memorization reduced or paused once

## Several missed days

Policy:
- enter `recovery`
- pause new work or reduce it to near-zero
- prioritize backlog burn-down and delayed durability

Recommended outcome:
- explicit recovery workflow with visible return-to-normal criteria

## Chronic overload

Policy:
- suggest preset downgrade
- keep new work constrained until stress improves
- explain that the current ambition exceeds current capacity

Recommended outcome:
- shift from `intensive` to `normal` or `easy`
- possibly recommend temporary `revision_only`

## Calibration Policy

Calibration remains heuristic and robust.

## Pace calibration

Use existing recent sample medians:
- new minutes per ayah
- review minutes per ayah

Policy:
- keep median-based update for stability
- clip unrealistic jumps to avoid wild swings
- prefer recent consistent samples over one exceptional session

## Quality calibration

Quality affects assignment pressure even if the review scheduler remains SM-2-like.

Derived quality signals can come from:
- recent review grades
- Stage-4 failures
- repeated hard/very-hard outcomes

Quality effects:
- weak quality lowers sustainable new share
- strong quality can cautiously restore normal share

## Grade-signal use

The grade distribution should no longer be treated mainly as forecast decoration.
It should also influence:
- new-allocation caution
- forecast confidence
- plan-health interpretation

## Forecast Policy

The forecast must use the same decision rules as the daily planner.

Current rule to preserve:
- one shared projection path should drive both weekly planning and forecast

V2 forecast changes:
- keep raw curves for advanced mode
- add plain-language forecast summary by default

## Forecast inputs

Required inputs:
- settings snapshot
- scheduling preferences and overrides
- current cursor
- current schedule states
- current Stage-4 due state
- calibrated pace
- quality-risk state
- learner mode and health rules

## Forecast outputs

Default outputs:
- likely completion window
- current plan health
- weekly stress outlook
- recommendation
- confidence level

Advanced outputs:
- minutes curve
- revision-only ratio curve
- average new pages curve

## Forecast confidence

Deterministic confidence bands:
- `low`
- `medium`
- `high`

Suggested inputs for confidence:
- calibration sample counts
- recent pace variability
- recent overload frequency
- override frequency
- backlog instability

Example rule:
- high confidence requires enough calibration samples and no recent chronic overload

## Explainability Contract

Every material planner decision must be explainable in plain language.

The algorithm must produce an explanation packet with:
- plan health
- learner mode
- primary reason for today’s order
- whether new work was full, reduced, or paused
- what to do if time is shorter than expected
- what recovery action is recommended

## Required explanation examples

Examples of mandatory explainable decisions:
- why Stage-4 is first today
- why new work was reduced
- why revision-only is active
- why the app is suggesting recovery mode
- why the forecast confidence is low

## Formal Contracts

Stage 4 explicitly defines these contracts before implementation.

## 1. Settings interpretation contract

Inputs:
- current app settings
- scheduling preferences and overrides
- current calibration preview or applied calibration
- current learner mode

Rules:
- existing `profile` maps to learner presets:
  - `support` -> `easy`
  - `standard` -> `normal`
  - `accelerated` -> `intensive`
- existing `force_revision_only` maps to `revision_only`
- `recovery` may be derived first, then later stored explicitly if needed

## 2. Daily-plan explanation contract

The daily planner must output:
- `planHealth`
- `learnerMode`
- `newAssignmentState`:
  - `full`
  - `reduced`
  - `paused`
- `primaryReasons`
- `recommendedAction`
- `shortDayFallback`
- `minimumDayFallback`

## 3. Missed-session recovery contract

The recovery workflow must accept:
- `missed_session`
- `missed_day`
- `multi_day_gap`
- `chronic_overload`

It must return:
- recommended temporary mode
- new-work policy
- must-do bucket priority
- return-to-normal condition

## 4. Forecast contract

The forecast must accept:
- planner settings snapshot
- current cursor
- current schedule state
- current Stage-4 state
- calibration state
- scenario length / horizon

It must return:
- `completionWindow`
- `confidence`
- `weeklyStressStates`
- `recommendation`
- advanced curves when requested

## Pseudocode

```text
function buildTodayDecision(todayDay, settings, cursor, dueRows, stage4Due, calibration, qualitySignals):
    capacity = resolveCapacityMinutes(todayDay, settings.schedulingPrefs, settings.schedulingOverrides)
    if capacity <= 0:
        return noStudyDayDecision()

    learnerMode = resolveLearnerMode(settings, explicitRecoveryTrigger, derivedRecoveryTrigger)

    mandatoryStage4 = selectMandatoryStage4(stage4Due)
    optionalStage4 = selectOptionalStage4(stage4Due)
    criticalReview = sortDueReviewRows(dueRows)

    mandatoryStage4Minutes = estimateStage4Minutes(mandatoryStage4, calibration)
    criticalReviewMinutes = estimateReviewMinutes(criticalReview, calibration.reviewMinutesPerAyah)
    optionalCatchUpMinutes = estimateOptionalCatchUp(optionalStage4, criticalReview)

    stressScore = computeStress(
        capacity,
        mandatoryStage4Minutes,
        criticalReviewMinutes,
        optionalCatchUpMinutes
    )

    planHealth = classifyHealth(stressScore, mandatoryStage4, learnerMode)
    qualityModifier = deriveQualityModifier(qualitySignals)
    effectiveMode = refineModeFromHealth(learnerMode, planHealth)

    reservedStage4 = allocateMandatoryStage4(mandatoryStage4, capacity)
    remainingAfterStage4 = capacity - reservedStage4.minutes

    reservedReview = allocateCriticalReview(
        criticalReview,
        remainingAfterStage4,
        calibration.reviewMinutesPerAyah
    )
    remainingAfterReview = remainingAfterStage4 - reservedReview.minutes

    if shouldPauseNew(effectiveMode, planHealth, mandatoryStage4, remainingAfterReview):
        newAllocation = none
    else:
        baseNewShare = presetNewShare(effectiveMode)
        adjustedNewShare = applyQualityAndStressModifiers(baseNewShare, qualityModifier, planHealth)
        newBudgetMinutes = min(
            remainingAfterReview,
            capacity * adjustedNewShare,
            hardCapsToMinutes(settings)
        )
        if newBudgetMinutes < minimumViableNewMinutes:
            newAllocation = none
        else:
            newAllocation = generateNewUnits(newBudgetMinutes, cursor, settings, calibration)

    fallbacks = buildFallbackPlans(
        mandatoryStage4,
        reservedReview,
        newAllocation,
        effectiveMode
    )

    return explanationBackedDecision(
        planHealth,
        effectiveMode,
        reservedStage4,
        reservedReview,
        newAllocation,
        fallbacks,
        reasons = explainDecision(...)
    )
```

## Scenario Table

| Scenario | Expected state | New work policy | Explanation outcome |
|---|---|---|---|
| first-time learner with normal time | `normal` + `on_track` | moderate new assignment | explain that the plan starts conservatively and protects review |
| learner only wants reading | no planner required or planner idle | none | app remains useful without forcing plan complexity |
| one missed session | `normal` or `tight` | reduced temporarily | explain short recovery and next best action |
| one missed day | usually `tight` | reduced or paused once | explain carryover and priority order |
| several missed days | `recovery` | paused or near-zero | explain catch-up path and return condition |
| slower real pace than expected | `tight` or `recovery` if persistent | reduced until calibration stabilizes | explain that the planner is adapting to real pace |
| review backlog dominates | `overloaded` or `revision_only` | paused | explain why older material is being protected first |
| mandatory Stage-4 due | at least `tight` | blocked by default | explain long-term stability priority and override cost |
| revision-only recovery week | `revision_only` | none | explain stabilization period |
| phone-sized quick-use day | `minimum_day` fallback available | maybe none | explain must-do items in the shortest possible form |

## Required Data Contracts

## Reuse existing data first

The V2 algorithm can already reuse:
- `app_settings.profile`
- `app_settings.force_revision_only`
- `app_settings.daily_minutes_default`
- `app_settings.max_new_pages_per_day`
- `app_settings.max_new_units_per_day`
- `app_settings.avg_new_minutes_per_ayah`
- `app_settings.avg_review_minutes_per_ayah`
- `app_settings.typical_grade_distribution_json`
- `app_settings.scheduling_prefs_json`
- `app_settings.scheduling_overrides_json`
- `schedule_state`:
  - `ef`
  - `reps`
  - `interval_days`
  - `due_day`
  - `lapse_count`
  - `last_review_day`
  - `last_grade_q`
- Stage-4 lifecycle due fields already used by `DailyPlanner`

## New runtime contracts recommended

These do not require schema changes on day one:
- `PlannerHealth`
- `LearnerMode`
- `TodayExplanationPacket`
- `RecoveryRecommendation`
- `ForecastSummary`

## New persisted contracts that may be worth adding later

These are optional later improvements:
- explicit `planner_mode` field instead of only using `profile`
- explicit persisted `recovery_state`
- persisted session-adherence history
- persisted forecast confidence snapshot for user support

## Migration and Risk Notes

## Low-risk adoption path

1. keep current SM-2-style review scheduling in `schedule_state`
2. replace daily allocation policy first
3. add explanation packet and plan-health outputs
4. wrap forecast with summary outputs
5. add recovery workflow

## Important risks

### 1. No explicit session-adherence data

Current limitation:
- the system can infer pressure from overdue work
- but it cannot perfectly distinguish one missed session from other causes

Mitigation:
- start with user-declared recovery wizard inputs
- add explicit adherence logging later if needed

### 2. Forecast/Today divergence risk

Risk:
- forecast and today planning could drift apart if separate rule sets appear

Mitigation:
- keep one shared projection and policy path

### 3. Over-aggressive new suppression

Risk:
- if thresholds are too conservative, the app may feel stagnant

Mitigation:
- validate with scenario-based tests and calibration-driven tuning

### 4. Product-language mismatch

Risk:
- internal engine states may leak through raw terminology

Mitigation:
- enforce explanation packet translation in UI and support docs

## Validation System Requirements for Later Implementation

Before rollout, the implementation should be tested with:
- deterministic scenario simulations
- missed-session recovery scenarios
- slower-pace calibration scenarios
- heavy Stage-4 backlog scenarios
- forecast vs today consistency tests
- preset-mode acceptance tests

## Stage 4 Output Summary

The V2 scheduler should:
- protect delayed durability first
- allocate review before new
- reduce ambition when stress rises
- recover gracefully from disruption
- explain its decisions in plain language

The core algorithm remains:
- heuristic
- deterministic
- auditable
- deeply compatible with the current repo’s data model

That is the correct foundation before any later adaptive or higher-complexity scheduler work.

## Validation Notes

This stage is an algorithm/spec artifact only.
No runtime app behavior or schemas changed.
