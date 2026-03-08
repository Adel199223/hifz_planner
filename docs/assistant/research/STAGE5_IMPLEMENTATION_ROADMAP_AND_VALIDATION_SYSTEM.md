# Stage 5 Implementation Roadmap and Validation System

## Executive Summary

Stage 5 turns the approved product and algorithm specs into a build order.

The key delivery rule is:
- do not try to ship the redesign as one giant branch

The right implementation order is:
1. simplify what users see
2. strengthen Today as the action center
3. redesign planner setup around presets and recovery
4. add plan-health and explanation layers
5. replace the daily allocation policy with Scheduler V2
6. refine forecast and calibration around the new planner behavior
7. consider optional adaptive follow-up only after deterministic behavior is proven

## Inputs Locked by Earlier Stages

Stage 1 locked:
- Today should become the primary learner home
- Plan is the main simplification target

Stage 2 locked:
- simple-first app map:
  - Today
  - Read
  - My Plan
  - Library
  - More

Stage 3 locked:
- planner behaves like a coach
- presets and recovery are first-class product concepts

Stage 4 locked:
- deterministic scheduler V2
- delayed durability first
- critical review next
- sustainable new memorization last

## Delivery Principles

1. Separate UX simplification from algorithm replacement.
2. Keep changes explainable and testable at each step.
3. Prefer thin vertical slices over giant architectural upheaval.
4. Preserve current data structures unless a later wave proves a schema change is necessary.
5. Land the highest user-value improvements before the hardest backend changes.

## Recommended Branch and Worktree Strategy

Implementation should not start on `main`.

Recommended pattern:
- one feature branch per wave
- separate worktree when a wave is likely to run for more than one focused session

Suggested branch sequence:
- `feat/ux-wave1-navigation-copy`
- `feat/ux-wave2-today-coaching`
- `feat/ux-wave3-my-plan-preset-flow`
- `feat/planner-wave4-health-explanations`
- `feat/planner-wave5-scheduler-v2`
- `feat/planner-wave6-forecast-calibration-refine`
- `feat/planner-wave7-optional-adaptive-followup`

Rule:
- do not combine Wave 5 scheduler replacement with Wave 1-3 IA/copy work in one branch

## Wave 1: Navigation and Copy Simplification

## Goal

Reduce first-run cognitive load without changing planner logic.

## Scope

In scope:
- rename and regroup destinations in user-facing copy
- demote secondary surfaces from the main path
- introduce the target mental model:
  - Today
  - Read
  - My Plan
  - Library
  - More
- hide or visually mark unfinished actions in Reader
- start replacing internal planner jargon in UI strings

Out of scope:
- planner algorithm changes
- recovery logic
- scheduler refactor

## Why first

This delivers immediate user benefit at low technical risk.

## Acceptance criteria

- a first-time user can tell where to read and where to do today’s work
- placeholder/secondary surfaces no longer compete with core journeys
- jargon is reduced in the first-run path

## Wave 2: Today as Coaching Home

## Goal

Turn Today from a task list into a guided daily coach using mostly current data.

## Scope

In scope:
- top coaching card
- `Do this next`
- `Why it matters today`
- short-day / minimum-day surface copy
- clearer delayed-check explanation
- empty states and completion states
- clearer recovery entry point from Today

Out of scope:
- full scheduler replacement
- full preset-first plan redesign

## Why second

Today is already the strongest learner-facing surface.
Improving it early gives the user value before deeper planner work lands.

## Acceptance criteria

- Today explains priority order in plain language
- Today offers a clear next step
- Today has a visible low-time fallback entry

## Wave 3: My Plan Preset-First Flow

## Goal

Replace the current plan-first control panel feel with a guided setup flow.

## Scope

In scope:
- Easy / Normal / Intensive presets
- initial goal and available-time questions
- simple confirmation summary
- advanced settings gate
- recovery and revision-only framing in product copy

Out of scope:
- final scheduler V2 allocation rules
- deep forecast rewrite

## Why third

This changes the planner product without yet destabilizing the backend allocation engine.

## Acceptance criteria

- a user can activate a plan without touching advanced controls
- advanced controls remain available but hidden behind `Advanced`
- the plan flow feels like guided setup, not a simulator

## Wave 4: Plan Health, Recovery, and Explanation Layer

## Goal

Add the coaching concepts defined in Stage 3, still before full scheduler replacement.

## Scope

In scope:
- plan health states:
  - on track
  - tight
  - overloaded
- recovery recommendations
- missed-session recovery wizard
- minimum viable day mode
- daily explanation packet in the UI
- backlog burn-down framing

Out of scope:
- final V2 weighted-demand implementation if the current engine cannot yet support it fully

## Why fourth

It creates the user-facing contract that the V2 scheduler must satisfy.

## Acceptance criteria

- the app can explain why new work is reduced or paused
- the user can choose or accept a recovery path
- planner health is visible without forecast expertise

## Wave 5: Scheduler and Daily Allocation V2

## Goal

Replace the current allocation behavior with the Stage 4 deterministic scheduler policy.

## Scope

In scope:
- weighted stress computation
- learner mode resolution
- plan health classification
- pass-based daily allocation
- new-assignment gating by stress and quality
- explicit fallback plan outputs
- shared policy path for Today and Forecast

Out of scope:
- adaptive scheduling
- speculative ML or ASR-driven optimization

## Why fifth

By this point, the product and UI know what behavior they need.
Now the engine can be changed with clear acceptance targets.

## Acceptance criteria

- daily planner follows the Stage 4 priority order
- forecast uses the same rules as Today
- deterministic scenario tests pass
- explanations map cleanly to real algorithm decisions

## Wave 6: Forecast and Calibration Refinement

## Goal

Make calibration and forecast support the new planner instead of feeling like raw diagnostics.

## Scope

In scope:
- default forecast summary
- confidence band output
- calibration wording cleanup
- quality-signal integration into planner stress/new-share behavior
- advanced forecast curves kept behind advanced mode

Out of scope:
- fully adaptive schedule tuning

## Why sixth

Forecast and calibration become much more useful after the planner and scheduler contracts are stable.

## Acceptance criteria

- forecast shows plain-language recommendation first
- calibration improves planner realism without requiring expert knowledge
- confidence is surfaced simply

## Wave 7: Optional Adaptive Follow-Up

## Goal

Explore whether deterministic V2 should later gain adaptive upgrades.

## Scope

Possible in scope:
- richer stability estimation
- smarter per-user pace adaptation
- improved uncertainty handling

Out of scope for initial commitment:
- any opaque model that weakens explainability

## Why last

Adaptive systems should only be considered after the deterministic planner has proven itself in practice.

## Validation System

Validation must happen at five levels.

## 1. Product Scenario Checks

These are human-readable scenario tests against the product spec.

Required canonical scenarios:
- first-time solo learner with no teacher
- learner who only wants reading and light support
- learner who wants a plan but does not understand scheduler jargon
- learner who misses one session
- learner who misses several days
- learner whose real pace is slower than expected
- learner whose review backlog starts dominating new memorization
- learner with mandatory Stage-4 due work
- learner using revision-only recovery
- learner using a phone-sized mental model

Rule:
- every wave must name which scenarios it improves and which scenarios it must not regress

## 2. Targeted Code Tests

Use targeted tests before broad suites.

Core planner/runtime tests already relevant:
- `test/screens/plan_screen_test.dart`
- `test/screens/today_screen_test.dart`
- `test/screens/companion_chain_screen_test.dart`
- `test/data/services/daily_planner_test.dart`
- `test/data/services/forecast_simulation_service_test.dart`
- `test/data/services/spaced_repetition_scheduler_test.dart`
- `test/data/repositories/settings_repo_test.dart`
- `test/data/repositories/companion_repo_test.dart`
- `test/data/database/app_database_test.dart`

Reader/navigation/copy waves should also lean on:
- `test/screens/reader_screen_test.dart`
- `test/app/navigation_shell_menu_test.dart`
- `test/app/app_preferences_test.dart`

## 3. Algorithm Regression and Simulation

Wave 5 and beyond need dedicated deterministic simulation tests.

Required categories:
- stress-classification tests
- new-share reduction tests
- mandatory Stage-4 blocking tests
- one-missed-session recovery tests
- multi-day recovery tests
- backlog burn-down tests
- forecast-vs-today consistency tests

Recommended new test families when implementation begins:
- `test/data/services/planner_v2/`
- `test/data/services/planner_v2/planner_state_classifier_test.dart`
- `test/data/services/planner_v2/daily_allocation_policy_test.dart`
- `test/data/services/planner_v2/recovery_policy_test.dart`
- `test/data/services/planner_v2/explanation_packet_test.dart`

## 4. Beginner Usability Walkthroughs

Each UX wave should be checked with simple manual flows:
- can the user find Today?
- can the user start reading quickly?
- can the user activate a plan without advanced settings?
- can the user understand why new work is reduced?
- can the user recover after missed days without guessing?

These should be documented as repeatable checklists, not only informal impressions.

## 5. Mobile Suitability Review

Even if desktop remains the current strongest platform, every major learner-facing wave should be checked against a phone-sized mental model.

Questions to ask:
- are there too many top-level destinations?
- does the main daily flow fit a narrow screen?
- are advanced details collapsed by default?
- can the learner finish the core journey with short attention spans and short study sessions?

## Core Validation Commands

Always keep these in the validation set:

```bash
dart tooling/validate_agent_docs.dart
dart tooling/validate_localization.dart
dart tooling/validate_workspace_hygiene.dart
```

Preferred Flutter validation when environment is healthy:

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test -j 1 -r expanded test/screens/plan_screen_test.dart
flutter test -j 1 -r expanded test/screens/today_screen_test.dart
flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart
flutter test -j 1 -r expanded test/data/services/forecast_simulation_service_test.dart
flutter test -j 1 -r expanded test/data/services/spaced_repetition_scheduler_test.dart
```

Environment note:
- if WSL Flutter remains broken locally, use GitHub CI or a repaired same-host environment for Flutter-side gates
- do not treat the local toolchain blocker as proof that the product change failed

## Wave Gates

Every wave should satisfy these gates before merge.

## Gate A: scope discipline

- the wave matches its declared scope
- unrelated product redesign work is not mixed in

## Gate B: scenario coverage

- the wave names its core supported user scenarios
- no obvious regression is introduced in the primary learner journeys

## Gate C: targeted verification

- targeted tests and validators pass
- manual walkthroughs are recorded for the changed journeys

## Gate D: docs sync

- if behavior changed materially, relevant assistant docs are synced
- do not widen docs sync unnecessarily

## Dependency Policy

Default policy:
- no new runtime dependencies unless a specific wave proves they are necessary
- research-only tooling may be optional and isolated
- avoid heavy algorithm libraries when in-repo deterministic logic is sufficient

Practical interpretation:
- Waves 1-6 should not require heavy new packages by default
- if a dependency is proposed later, it must justify:
  - why the current codebase cannot reasonably implement the behavior
  - why the dependency does not reduce explainability or maintainability

## What Not To Do

Do not:
- start with Wave 5 before Wave 1-4 are clear
- mix UX copy cleanup and scheduler replacement in one giant branch
- expose new algorithm complexity before the user-facing behavior is understandable
- add adaptive scheduling before deterministic V2 is validated
- let forecast and Today use separate rule systems

## Recommended Immediate Next Step After Stage 5

Start implementation with Wave 1, not with the algorithm.

Reason:
- it is the lowest-risk, highest-clarity improvement
- it improves the user experience immediately
- it creates cleaner UI structure for Waves 2-4

## Final Program Output

The staged program now provides:
- Stage 1: audit and benchmark matrix
- Stage 2: non-coder UX and journey redesign
- Stage 3: planner product redesign
- Stage 4: deterministic scheduler and algorithm V2 spec
- Stage 5: implementation roadmap and validation system

This means the research/spec phase is complete.
The next phase should be deliberate implementation, wave by wave.

## Validation Notes

This stage is a roadmap/spec artifact only.
No runtime app behavior or schemas changed.
