# Stage 2 Non-Coder UX and Journey Redesign

## Executive Summary

Stage 2 converts the Stage 1 audit into a simple-first product shape for a solo learner who is not a planner expert and may not be technical at all.

Core decision:
- `Today` becomes the center of the memorization experience.
- `Read` stays the center of the reading experience.
- `Plan` becomes a guided setup and adjustment flow, not a daily control panel.
- `Companion` stays powerful, but moves behind clearer “Practice from memory” entry points.
- operational or placeholder surfaces move out of the main path.

The guiding rule is:
- first show the learner what to do next
- only later show how the planner thinks

## Inputs Used

Internal sources:
- `docs/assistant/research/STAGE1_PRODUCT_AUDIT_AND_BENCHMARK.md`
- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PLANNER_USER_GUIDE.md`
- `lib/app/router.dart`
- `lib/app/navigation_shell.dart`
- `lib/screens/learn_screen.dart`

External benchmark confirmations:
- Quran.com product updates: https://quran.com/product-updates
- Tarteel help center:
  - https://support.tarteel.ai/en/articles/12414416-hide-ayahs
  - https://support.tarteel.ai/hc/en-us/categories/25981364746637-Features
  - https://support.tarteel.ai/hc/en-us/articles/32486640388877-How-do-I-use-the-Goals-feature
- Thabit: https://thabitapp.io/
- Quranki: https://www.quranki.com/

## Design Target

Primary audience:
- solo learner

Primary product promise:
- help me keep a realistic Quran reading and memorization rhythm without making me think like an algorithm designer

UX posture:
- simple-first
- mobile-aware
- plain-language
- progressive disclosure for advanced controls

Non-goals for this stage:
- no new algorithm spec yet
- no teacher-classroom workflow design
- no heavy A.I. or speech-first dependency decisions

## Journey Model

The app should be structured around four learner journeys.

### 1. I just want to read

The learner wants:
- quick entry into reading
- comfortable display and audio
- minimal planning language
- optional bookmark/note support

What the app must do:
- open directly into a calm reading surface
- keep study tools available but secondary
- make reciter and translation changes easy

### 2. I want to memorize today

The learner wants:
- the next concrete action
- the right order of work
- simple buttons to begin
- clear confirmation when today is complete

What the app must do:
- explain what is due now
- separate delayed checks, review, and new work
- provide direct entry into hidden recall practice

### 3. I missed days and need recovery

The learner wants:
- reassurance
- a safe reduced plan
- clear guidance on what to skip, keep, or postpone

What the app must do:
- detect overload or missed sessions
- offer a recovery workflow
- protect quality before resuming normal growth

### 4. I want a realistic plan without understanding the algorithm

The learner wants:
- a setup that feels trustworthy
- a small number of understandable decisions
- confidence that the plan will adapt if life changes

What the app must do:
- start with presets and simple questions
- explain tradeoffs in plain language
- hide expert tuning unless requested

## Current vs Target Information Architecture

## Current Shape

Current main navigation and secondary menu spread the app across:
- Reader
- Bookmarks
- Notes
- Plan
- Today
- Settings
- About
- Learn
- My Quran
- Quran Radio
- Reciters

Problem:
- too many top-level choices for a first-run learner
- placeholder or secondary surfaces compete with the core reading and memorization flow
- the app exposes internal structure more than user intent

## Target Shape

### Primary navigation

The learner-facing primary structure should become:

| Destination | Purpose | Default audience |
|---|---|---|
| Today | Do today’s memorization and review work | every memorization user |
| Read | Read, listen, bookmark, note | every user |
| My Plan | Set or adjust the plan with guided defaults | users who want memorization planning |
| Library | Saved bookmarks, notes, reading progress | returning users |
| More | secondary tools and settings | occasional use |

### Secondary destinations under More

Move these out of the main daily path:
- Reciters
- Settings
- About
- Imports / operational tools

Keep these off the main path until they become clearly valuable:
- Learn
- My Quran
- Quran Radio

Stage-2 product rule:
- if a destination is not essential to reading or doing today’s memorization work, it should not sit beside the primary daily destinations

## Revised Screen Responsibilities

## Today

This should become the real learner home.

Responsibilities:
- show the single next best action
- explain why the current order matters
- separate delayed checks, review, new work, and catch-up
- offer a recovery path when the day is overloaded
- show completion state in plain language

Must not do:
- expose too many planner diagnostics
- require the learner to interpret scheduler jargon

Recommended additions:
- top coaching card:
  - `Do this next`
  - `Why it matters today`
  - `If you only have 10 minutes`
- plan health chip:
  - on track
  - tight but manageable
  - overloaded
- missed-day recovery action

## Read

This should be the calm reading surface.

Responsibilities:
- support reading, listening, bookmarks, notes, and reciter changes
- support a clear path into memorization practice
- keep display comfort high

Must not do:
- look like a dashboard
- expose unfinished actions beside core reading actions

Recommended additions:
- two entry modes:
  - Read
  - Study
- cleaner quick actions:
  - bookmark
  - note
  - play audio
  - practice from memory

## My Plan

This should become a guided setup and adjustment surface.

Responsibilities:
- ask a few simple questions
- recommend a preset
- let the learner see what daily life will feel like
- show whether the current plan is healthy

Must not do:
- expose advanced scheduling, forecast, and calibration as equal first-run choices
- force users to understand grade distributions or timing policies before they can begin

Recommended default sections:
- learning goal
- available time
- pace preset
- confirmation preview

Advanced section:
- session timing
- weekday overrides
- calibration
- forecast
- revision-only fine tuning

## Companion

This should be reframed as guided practice, not as an internal stage machine.

Responsibilities:
- run memorization and review exercises with strong recall-first behavior
- keep correction loops and delayed durability logic
- explain the current exercise simply

Must not do:
- expect the learner to understand stage mechanics before starting

Recommended user-facing framing:
- rename in user copy from `Companion` to `Practice`
- show one-sentence explanation before each run:
  - `You will recall from memory, then check and correct.`
  - `This is a delayed check to make sure yesterday’s memorization stayed strong.`

## Library

This combines the support tools that matter after reading or memorization.

Responsibilities:
- bookmarks
- notes
- reading bookmark / return point
- simple collections later if needed

Must not do:
- compete with Today or Read as a first-run destination

## More

This should hold operational and secondary tools.

Responsibilities:
- reciters
- settings
- about
- future optional tools

Must not do:
- distract the user during first-run memorization setup

## Feature Visibility Policy

Features should be split into three visibility layers.

## Default visible

These should be visible to almost every learner:
- Today task list
- Read surface
- simple plan preset flow
- basic available-time setup
- basic reciter selection
- bookmarks
- notes
- delayed-check explanation
- missed-day recovery entry
- plan-health state
- simple completion feedback

## Advanced but discoverable

These should exist, but only after the learner chooses to tune the system:
- sessions per day
- revision-only days
- advanced availability models
- weekly calendar controls
- session timing
- calibration samples
- forecast
- detailed grade controls
- reciter/audio fine tuning

UX rule:
- advanced options should live behind a clear `Advanced` section or `Adjust details` action

## Hidden or internal

These should not be part of the normal learner vocabulary:
- grade-distribution percentages
- q-value jargon
- raw forecast curves
- raw deterministic simulation language
- page metadata readiness toggles
- implementation-stage terminology
- low-level scheduler conflict details

UX rule:
- the learner sees the outcome and explanation, not the internal variable names

## Feature-Level Decisions

| Current feature or concept | Stage 2 decision | Rationale |
|---|---|---|
| `Today` route as initial location | keep and strengthen | already matches the best learner home |
| full `Plan` control stack on first screen | simplify and gate | too much initial cognitive load |
| Companion stage terminology | hide behind plain-language practice framing | engine is strong, wording is not beginner-friendly |
| Learn / My Quran / Quran Radio top visibility | demote from core path | not central to the app’s main promise right now |
| Reciters as separate root destination | move to secondary access | useful, but not a primary daily destination |
| Bookmarks and Notes as separate top-level items | combine as Library | cleaner mental model for non-coders |
| placeholder and coming-soon actions in Reader | hide or visually mark unavailable | reduce confusion and disappointment |

## Recommended Onboarding Flow

The first-run setup should become a guided conversation, not a settings form.

### Step 1: choose your goal
- I mainly want to read
- I want to memorize consistently
- I need to recover and stabilize review

### Step 2: choose your time reality
- a little time most days
- one steady daily session
- two study windows most days
- my schedule changes a lot

### Step 3: choose a starting intensity
- Easy
- Normal
- Intensive

### Step 4: confirm plan summary
- what your average day will look like
- what happens if you miss a day
- where to go next

### Step 5: land in Today
- show one clear first action

## Recommended Simple-First Planner Controls

The learner-facing planner should begin with only these controls visible:
- goal type
- available time
- study days
- pace preset
- revision-only switch
- hard cap on new work

Everything else moves under advanced settings.

## Plain-Language UX Rules

The app should prefer:
- `practice from memory` over `launch companion chain`
- `review only today` over `force revision-only`
- `your plan is too heavy` over `forecast overload`
- `teach the planner your real pace` over `calibration`
- `why this is due today` over scheduler jargon

Support rule:
- every technical term shown to the user must either be removed or explained in one sentence

## Implementation-Ready UX Backlog

## Wave A: high-value structure changes

1. Make `Today` the unmistakable learner home with a top coaching card.
2. Replace the current plan-first mental model with a guided `My Plan` setup flow.
3. Consolidate Bookmarks and Notes into a `Library` concept in navigation and copy.
4. Move secondary destinations out of the main path.
5. Hide placeholder and unfinished reader actions from the default surface.

## Wave B: non-coder friction reduction

1. Add plan presets:
   - Easy
   - Normal
   - Intensive
2. Add a missed-day recovery action from `Today`.
3. Add a minimum-viable-day suggestion when time is short.
4. Add plain-language explanation blocks:
   - why delayed checks come first
   - why new memorization may be reduced
   - why today is overload-prone
5. Reframe Companion entry as `Practice from memory`.

## Wave C: trust and transparency

1. Add a plan-health indicator with plain-language states.
2. Add a simple preview of a normal day before plan activation.
3. Add a clear completion state when today’s critical work is finished.
4. Add friendly empty states for users with no active plan or no tasks due.

## Wave D: mobile suitability cleanup

1. Reduce top-level destinations.
2. Make Today and Read work cleanly in a phone-sized mental model.
3. Collapse advanced details into progressive disclosure cards.
4. Prioritize one-handed and short-session flows for reading and memorization.

## What Should Not Be Built Yet

Do not do these before the planner product model is rewritten:
- expose more planner knobs
- build A.I.-heavy memorization feedback dependencies
- redesign the scheduler internals
- add teacher/classroom workflows into the default product path

## Acceptance Criteria for Future Implementation

Stage 2 should be considered successfully implemented later only if:
- a first-time user can choose between reading and memorization without confusion
- a memorization user can start with a preset and reach Today without expert decisions
- a missed-day user can find recovery guidance without entering advanced planner controls
- advanced planner settings are still available, but not required
- the app’s top-level navigation fits a mobile-first mental model
- Companion is understandable without stage jargon

## Stage 2 Output Summary

Revised app map:
- Today
- Read
- My Plan
- Library
- More

Simple-first screen responsibilities:
- Today = do today’s work
- Read = read and listen comfortably
- My Plan = guided setup and adjustment
- Library = saved places and thoughts
- More = secondary tools

Feature visibility policy:
- default visible
- advanced but discoverable
- hidden/internal

Top implementation priorities:
1. promote Today into a coaching home
2. redesign Plan into preset-first setup
3. add recovery and minimum-viable-day flows
4. simplify reader action density
5. hide internal planner language

## Validation Notes

This stage is a UX/spec artifact only.
No runtime app behavior or schemas changed.
