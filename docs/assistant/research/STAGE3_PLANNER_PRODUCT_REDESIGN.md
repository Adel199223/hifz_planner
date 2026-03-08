# Stage 3 Planner Product Redesign

## Executive Summary

The planner should stop presenting itself as a configuration engine and start behaving like a coach.

Current problem:
- the app already has meaningful planning depth
- but much of that depth is exposed as knobs, timings, and technical concepts before the learner has enough trust or context

Stage 3 redesign decision:
- the planner becomes a plain-language system that recommends a realistic daily rhythm
- advanced controls still exist, but are no longer the default experience
- `Today` becomes the execution surface
- `My Plan` becomes the plan-setup and plan-repair surface

In product terms:
- the learner should feel guided, not configured

## Design Goal

The planner should help a solo learner answer five questions without needing scheduler jargon:

1. How much should I try to memorize?
2. What should I do today?
3. What happens if I miss a day?
4. Is my current plan too heavy?
5. How do I recover without losing momentum?

## Planner Reframed as a Coaching System

The planner is no longer primarily:
- a place to set many parameters
- a place to inspect raw forecast curves
- a place to manually tune internal scheduling logic

The planner becomes:
- a guided setup
- a daily workload policy
- a recovery assistant
- a plan-health explainer
- a trust layer between the learner and the scheduling engine

## Plain-Language Product Promise

The planner should promise:
- a realistic amount of work
- protection against silent overload
- steady progress when life is normal
- graceful recovery when life is not normal
- clear reasons when the app slows down new memorization

## Evidence Alignment

This planner redesign is consistent with the Stage 1 benchmark and research baseline:
- Quran-specific apps like Tarteel, Thabit, and Quranki reinforce the value of clear daily action, guided goals, and low-jargon memorization workflows.
- Spaced-practice and retrieval-practice research support protecting delayed checks and review quality rather than maximizing same-day volume.
- Anki/FSRS and SuperMemo patterns support hiding many low-level scheduler knobs while still giving the user understandable workload outcomes.
- Learning-science guidance supports continuity and repeated retrieval over heroic but unsustainable daily overload.

## What the Planner Is Optimizing For

Before any later algorithm details, the product behavior should be locked around these priorities:

1. durable retention
2. critical review protection
3. sustainable new memorization
4. psychological continuity
5. understandable daily decisions

Plain meaning:
- if the learner is overloaded, the app should protect memory quality before protecting volume
- if the learner is behind, the app should reduce ambition before it reduces clarity
- if the learner is uncertain, the app should explain the decision rather than expose more controls

## What the Planner Sacrifices When Overloaded

The planner must be explicit about what gets reduced first.

Overload sacrifice order:
1. reduce new memorization
2. switch to a lighter daily version of the plan
3. allow recovery mode or revision-only mode
4. preserve the most important delayed and review work

This means the product should never imply:
- “just do more”
- “keep full new load even though review is collapsing”

Instead it should say:
- `Today is heavier than your current capacity. New memorization has been reduced so you can protect what you already learned.`

## Core Product States

The planner should operate in a small number of understandable states.

## 1. On Track

Meaning:
- the current plan fits the learner’s recent pace
- normal new/review balance can continue

User-facing message:
- `Your plan looks manageable. Keep going with today's work.`

## 2. Tight but Manageable

Meaning:
- review pressure is rising or recent pacing is slower
- the plan is still viable, but needs caution

User-facing message:
- `Your plan is getting tight. Keep today's priority work first and avoid adding extra load.`

## 3. Overloaded

Meaning:
- due work and actual pace are no longer matching the current ambition
- quality is at risk if the plan stays unchanged

User-facing message:
- `Your plan is too heavy right now. The app is reducing new work so you can recover without losing stability.`

## 4. Recovery Mode

Meaning:
- the learner missed work or accumulated too much pressure
- the app temporarily changes behavior to stabilize retention

User-facing message:
- `Recovery mode is active. Focus on catch-up and stability before building new load again.`

## 5. Revision-Only Mode

Meaning:
- the learner or the planner has intentionally paused new memorization
- only review and delayed checks should drive the day

User-facing message:
- `Today is for revision only. New memorization is paused so older material stays strong.`

## Preset-First Product Design

The first setup should ask for a small number of understandable decisions and then recommend a preset.

## Presets

### Easy

Use when:
- the learner is new
- the learner has low or inconsistent time
- the learner is recovering from overload

Behavior goal:
- slower new growth
- stronger review protection
- fewer daily surprises

### Normal

Use when:
- the learner has stable time
- the learner wants sustainable progress

Behavior goal:
- balanced new/review workload
- default recommended preset for most users

### Intensive

Use when:
- the learner has unusually strong available time and current stability
- the learner accepts lower comfort and tighter margins

Behavior goal:
- higher new load, but still bounded by review protection

Product rule:
- Intensive should never bypass retention protection

### Recovery

Use when:
- the learner missed multiple sessions or days
- plan health moved to overloaded

Behavior goal:
- reduce new work sharply or pause it
- prioritize delayed checks and essential review
- create a path back to normal mode

### Revision-Only

Use when:
- backlog is too heavy
- the learner chooses stabilization over expansion

Behavior goal:
- zero new assignment
- maximum clarity around review priorities

## Required High-Value Features

## 1. Missed-Session Recovery Wizard

Purpose:
- convert guilt and confusion into a safe next step

What it should do:
- ask what was missed:
  - one session
  - one full day
  - several days
- show the safe recommended response
- explain what will be reduced or postponed
- land the learner back in `Today`

Why it matters:
- this is the most important missing planner feature for solo learners

## 2. Minimum Viable Day Mode

Purpose:
- keep continuity when time is much lower than expected

What it should do:
- offer a reduced “do this first” version of the day
- protect the most important delayed and review work
- clearly say what can be postponed

Why it matters:
- continuity reduces dropout and keeps the learner attached to the routine

## 3. Plan Stress Indicator

Purpose:
- make plan health visible before collapse happens

What it should do:
- label plan state as:
  - on track
  - tight
  - overloaded
- explain what action is recommended

Why it matters:
- raw forecast curves are too indirect for most users

## 4. Weekly Tradeoff Preview

Purpose:
- help the learner see the cost of more ambition

What it should do:
- show plain-language outcomes such as:
  - more new work, tighter review margin
  - safer pace, slower completion
  - recovery week, stability first

Why it matters:
- this builds trust without exposing internal math

## 5. Daily Explanation Layer

Purpose:
- explain why the planner assigned today’s order and limits

What it should do:
- answer:
  - why delayed checks come first
  - why new work was reduced
  - why review-only is recommended
  - why the plan thinks the day is healthy or overloaded

Why it matters:
- the planner needs interpretability at the product layer, not just in code

## 6. Backlog Burn-Down Mode

Purpose:
- give a visible recovery posture for learners whose due work has grown too large

What it should do:
- prioritize shrinking backlog safely
- de-emphasize new memorization temporarily
- show progress toward returning to normal mode

Why it matters:
- learners need a concrete name and structure for catch-up periods

## 7. Daily Fallback Plan

Purpose:
- handle days when available time is lower than the original plan assumption

What it should do:
- show:
  - full day plan
  - short day plan
  - emergency minimum

Why it matters:
- planners fail in real life when they only support ideal conditions

## User Behavior Model

The planner should be understandable through a small number of user stories.

## Story A: First-time solo learner

The product should do this:
- recommend `Normal` or `Easy`
- avoid advanced controls by default
- land the learner in `Today`
- explain the first action clearly

Success condition:
- the learner can start without editing advanced settings

## Story B: Learner only wants reading plus light support

The product should do this:
- allow reading-first use without pressure to activate a full planner
- keep memorization planning optional, not mandatory

Success condition:
- the app still feels useful even without a heavy planner setup

## Story C: Learner misses one session

The product should do this:
- suggest a short recovery action
- preserve the day if possible
- avoid immediately forcing broad plan changes

Success condition:
- one miss feels recoverable, not catastrophic

## Story D: Learner misses several days

The product should do this:
- activate or suggest recovery mode
- reduce new work
- show a clear return path to normal mode

Success condition:
- the learner is guided back into the rhythm without guessing

## Story E: Learner is slower than expected

The product should do this:
- adapt assumptions through later calibration
- reduce pressure before increasing complexity
- frame the issue as normal, not failure

Success condition:
- the learner feels the plan became more realistic

## Story F: Review backlog dominates new memorization

The product should do this:
- make backlog visible
- recommend recovery or revision-only posture
- explain why new work is being constrained

Success condition:
- quality protection is visible and understandable

## Story G: Mandatory Stage-4 work is due

The product should do this:
- clearly state that delayed checks are high priority
- explain that long-term stability is being protected
- allow a deliberate override, but make the cost understandable

Success condition:
- the learner understands why Stage-4 can block new work

## What Moves to Advanced Settings

These should remain available, but not be part of the default planner path:
- sessions per day
- exact session times
- specific hour windows
- weekday overrides
- calibration timing
- forecast details
- detailed grade-distribution inputs
- low-level availability models

Product rule:
- advanced controls should tune a plan, not be required to create one

## What Becomes Internal-Only

These should not be part of the normal user vocabulary:
- q-value distributions
- deterministic simulation wording
- stage mechanics used only for engine logic
- raw pressure bands
- metadata readiness language
- allocator conflict internals

The user should see:
- recommendation
- explanation
- consequence

The user should not need to see:
- engine variable names

## Feature Additions, Removals, and Hiding Decisions

| Item | Decision | Rationale |
|---|---|---|
| Easy / Normal / Intensive presets | add | creates a safer beginner entry point |
| Recovery mode | add | necessary for missed-day resilience |
| Revision-only mode | keep and promote | already useful, but needs clearer product framing |
| Missed-session wizard | add | highest-value gap for solo learners |
| Minimum viable day | add | protects continuity on low-time days |
| Plan stress indicator | add | more useful than raw forecast alone |
| Backlog burn-down mode | add | names and structures heavy catch-up periods |
| Weekly forecast curves as default content | hide behind advanced | too technical for first-run users |
| Calibration timing choice | hide behind advanced | useful later, confusing early |
| Specific windows / advanced availability as default | hide behind advanced | high cognitive cost |
| Direct stage jargon in user-facing planner copy | remove | not needed for beginner understanding |

## Planner Screen Responsibilities

The redesigned `My Plan` surface should answer:
- what kind of learner are you right now?
- how much time is realistic?
- how ambitious should the plan be?
- is your plan healthy?
- what should change if the plan is too heavy?

The redesigned `My Plan` surface should not feel like:
- a simulator dashboard
- a calibration lab
- an operations console

## Acceptance Criteria

Stage 3 should be considered complete later in implementation only if:
- the planner can be activated from a preset-first flow
- a learner can understand the plan without forecast or calibration knowledge
- the app clearly distinguishes normal mode, recovery mode, and revision-only mode
- a missed-session recovery workflow exists
- the learner can see why new work was reduced or paused
- Stage-4 blocking behavior is explained in plain language
- advanced controls still exist, but are not required on first use
- the planner communicates health and tradeoffs without raw engine jargon

## Boundaries Before Stage 4

This stage intentionally does not define:
- algorithm equations
- scheduling pseudocode
- stability coefficients
- calibration formulas
- forecast data contracts

Those belong in Stage 4.

Stage 3 locks the product behavior so Stage 4 can design the algorithm around the right learner experience.

## Stage 3 Output Summary

The planner is redefined as:
- a guided setup system
- a workload policy
- a recovery assistant
- a health explainer
- a trust layer over the scheduler

Most important new features:
1. missed-session recovery wizard
2. minimum viable day mode
3. plan stress indicator
4. daily explanation layer
5. backlog burn-down mode
6. daily fallback plan
7. preset-first setup

Most important hiding decisions:
- forecast is no longer a default first-run concept
- calibration becomes optional and later
- advanced scheduling is not part of the default plan activation path

This creates the product shape needed for Stage 4:
- a deterministic, interpretable scheduler that serves a clear learner-facing coaching model

## Validation Notes

This stage is a product-spec artifact only.
No runtime app behavior or schemas changed.
