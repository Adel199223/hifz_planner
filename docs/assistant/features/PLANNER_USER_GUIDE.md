# Planner User Guide (Non-Technical)

This guide explains the Planner system in plain language so you can set up a realistic memorization routine, keep daily momentum, and avoid the common trap of adding new material faster than you can retain it.

## Use This Guide When

Use this guide for:
- user support about planning/scheduling behavior
- non-technical explanations of plan and today decisions
- onboarding and troubleshooting around planner settings and outcomes

## Do Not Use This Guide For

Do not use this guide for:
- schema/migration or repository internals
- scheduler implementation details or algorithm-level code reasoning
- authoritative architecture decisions when technical docs/code disagree

## For Agents: Support Interaction Contract

When using this guide in support replies:
- explain planner behavior in plain language first
- provide numbered next steps with exact UI labels from this guide
- run a canonical cross-check against `APP_KNOWLEDGE.md` for behavior claims
- avoid implementation-level speculation; escalate to planner/scheduling workflows for technical details
- explicitly mention uncertainty when behavior may still be evolving
- define unavoidable technical terms in one short sentence

## Canonical Deference Rule

If this guide conflicts with technical docs:
- `APP_KNOWLEDGE.md` is canonical for app-level architecture/status
- source code is final truth

## Quick Start (No Technical Background)

1. Open `Plan` and enter realistic weekly or weekday minutes.
2. Set conservative caps for new work before enabling advanced options.
3. Press `Activate Plan`, then open `Today` and execute due tasks consistently.
4. Use calibration only after collecting real sessions so forecast quality improves.

## Terms in Plain English

- Calibration: teaching the planner your real speed so future assignments fit better.
- Forecast: a forward estimate of workload based on your current settings and history.
- Revision-only day: a day focused on review without adding new memorization.
- Canonical: the final source to trust if two docs disagree (`APP_KNOWLEDGE.md`, then source code).

## Purpose and Audience

Use this guide if you want to:
- understand what the Planner is doing and why
- configure the app to match your real available time
- know what each option changes in your day-to-day memorization flow
- recover quickly when your plan falls behind

This guide is for learners, teachers, and anyone supporting a learner.

## Where Planner Fits in the Full Learning Cycle

The app lifecycle is:
- `Plan` -> define your capacity and schedule rules
- `Today` -> execute what is due (reviews, new memorization, delayed checks)
- `Companion` -> run memorization/retrieval stages for each unit
- Delayed consolidation checks -> verify stability after time has passed (especially next day)
- Maintenance reviews -> keep strong units strong over time after they become stable

Planner is the system that decides how much to assign and in what order, so your memorization load stays sustainable.

## Scope Boundaries

This guide covers planning execution behavior and user decisions.
It does not define scheduler internals, DB/storage contracts, or implementation-level algorithms.

## Core Outcomes Planner Is Designed to Achieve

Planner tries to optimize for:
- consistency: steady daily work instead of bursts and collapse
- durability: enough review and delayed checks to reduce forgetting
- balance: new memorization without drowning in backlog
- realism: assignments that fit your actual minutes and days
- adaptability: calibration + forecast to tune your pace over time

## Plan Screen Walkthrough (Top to Bottom)

Location: open the left navigation rail and select `Plan`.

Each section below explains:
- where it appears
- what it controls
- when to use it
- how it changes daily behavior

## 1) Time and Capacity Inputs

### Weekly minutes or weekday minutes
- Where: top onboarding questions.
- What it controls: your baseline available study time.
- When to use:
  - weekly total if your days are flexible
  - weekday-specific if your week is predictable
- Daily impact: sets the planner's total budget before splitting between review and new work.

### Fluency setup
- Where: onboarding-style questions near the top.
- What it controls: initial defaults for new/review minutes per ayah.
- When to use: first setup, or when your current defaults feel unrealistic.
- Daily impact: shifts how much content can be assigned per day for both new and review.

### Profile mode
- Where: onboarding-style questions.
- What it controls: default planning posture (balanced/support/accelerated style behaviors).
- When to use: choose based on your tolerance for review pressure.
- Daily impact: influences review/new split and risk handling.

### Force revision-only
- Where: onboarding questions and advanced controls.
- What it controls: temporarily pauses new memorization assignment.
- When to use: backlog is heavy or retention quality has dropped.
- Daily impact: `Today` focuses on review and stabilization only.

### Max new pages per day / max new units per day
- Where: onboarding/caps area.
- What it controls: hard ceilings for daily new assignment.
- When to use: prevent over-ambition even on high-energy days.
- Daily impact: planner will not exceed these caps even if time budget suggests more.

### Avg new minutes per ayah / avg review minutes per ayah
- Where: onboarding/caps area.
- What it controls: pacing assumptions used to convert time into assigned content.
- When to use: if assigned load consistently feels too light or too heavy.
- Daily impact: directly changes planned unit size and count.

### Require page metadata
- Where: options/caps area.
- What it controls: whether planner can create new units only when page metadata coverage is valid.
- When to use: keep enabled for stronger mushaf-page consistency.
- Daily impact: may block new generation until metadata quality is sufficient.

### Activate Plan
- Where: primary action in plan setup card.
- What it controls: saves your planner settings and applies them to scheduling.
- When to use: after changing setup values.
- Daily impact: `Today` starts using your updated rules.

## 2) Automatic Scheduling Section

Location: scheduling card on the Plan screen.

### Sessions per day
- Option: usually `2 sessions/day` toggle.
- What it controls: number of study sessions planned per day.
- Daily impact: splits workload into one or two blocks.

### Exact times
- Option: fixed times for Session A / Session B.
- What it controls: when session windows are targeted.
- Daily impact: weekly/day cards show timed sessions instead of untimed blocks.

### Study days
- Option: weekday chips.
- What it controls: which weekdays are active study days.
- Daily impact: disabled days receive no normal assignments.

### Revision-only days
- Option: weekday chips in revision-only row.
- What it controls: days dedicated to review without new content.
- Daily impact: protects retention by inserting predictable consolidation days.

### Advanced scheduling mode
- Option: advanced mode switch.
- What it controls: access to richer availability models and constraints.
- Daily impact: planner becomes more context-aware than simple minutes/day rules.

### Availability model
- Options:
  - minutes per day
  - minutes per week
  - specific windows
- What it controls: how your capacity is interpreted.
- Daily impact:
  - per-day is stable daily pacing
  - per-week allows flexible distribution
  - specific windows ties planning to real clock ranges

### Windows editor and flex outside windows
- Where: advanced mode, specific windows path.
- What it controls:
  - exact day/time windows for study
  - whether planner can spill outside windows when needed
- Daily impact: more realistic plans around work/school/family constraints.

## 3) Weekly Calendar Section

Location: weekly calendar card on Plan.

How to read each day card:
- focus: new + review or revision-only
- minutes: estimated workload
- session lines: session label, focus, minutes, time, status
- status labels: pending/completed/missed/due-soon style indicators

Day-level controls:
- skip day: mark holiday/paused day
- session time overrides: set custom A/B time for that day

What this changes:
- immediate recalculation of the weekly distribution
- clearer detection of overload days before they happen

## 4) Calibration Section

Location: calibration card on Plan.

Purpose:
- teach the planner your real pace instead of relying only on defaults.

What you can do:
- add `new` sample: duration + ayah count
- add `review` sample: duration + ayah count
- provide grade distribution percentages (optional but useful for realism)
- apply calibration:
  - now
  - tomorrow

What changes after calibration:
- new/review pace assumptions become better matched to your actual performance
- forecast and daily assignment quality improve over time

## 5) Forecast Section

Location: forecast card on Plan.

Purpose:
- run a deterministic projection of expected planning pressure and output.

How to use:
- run forecast after changing schedule, caps, or calibration
- compare projected workload against your real tolerance

How to interpret:
- if review pressure trend is rising too fast, reduce new load or add revision-only structure
- if capacity is underused and retention is strong, increase cautiously

## 6) Today Screen Execution Flow

Location: `Today` in navigation rail.

Execution order is designed to protect retention quality:

### Next best step card
- shows the one action the app thinks you should do first
- usually points to the most urgent delayed check, review, weak spot, or unlocked new memorization

### Path mode card
- tells you whether today is in `Green`, `Protect`, or `Recovery`
- explains whether new memorization is open, paused, or unavailable
- includes a short path-length summary so the day feels easier to size up

### Stage-4 delayed checks section
- shows delayed consolidation items (especially mandatory next-day checks)
- these are high priority because they verify durability after delay

### Warm-up / due review / weak spots sections
- review rows are now grouped into a calmer queue instead of feeling like one flat dashboard list
- warm-up gives you an easier review entry point when one is available
- due review holds the remaining priority review work
- weak spots pulls out higher-risk review items so they are easier to notice
- supports immediate scheduler updates based on your quality
- same review can also be saved from the Companion review summary if you open it there first
- when two due items are similarly urgent, weaker recent Companion retention can move one earlier in the list

### Optional new section
- new unit rows with actions:
  - open in reader
  - open companion chain (new mode)
- this section appears only when new memorization is truly unlocked
- if recent Companion retention is weak, this section may shrink sooner because the planner gives more of today's time back to review

### Summary section
- keeps the secondary numbers together, such as planned minutes, review pressure, recovery signal, and session blocks

## 7) Stage-4 Priority and Soft-Block Behavior

You may see new memorization paused when:
- mandatory delayed checks are due
- review pressure is high enough that the day has shifted into protect/recovery behavior
- the planner is in revision-only mode
- required page metadata setup is still missing

Why this happens:
- the app protects retention quality first
- unresolved delayed checks are a strong signal that stability needs attention
- very high review pressure is also treated as a signal that review needs the day's budget first
- lifecycle badges alone do not block new memorization

Override behavior:
- when mandatory Stage-4 delayed checks are the blocker, the existing explicit override path still applies
- that override is logged (not ignored)

When override is reasonable:
- rare exceptional days
- you commit to catch-up shortly after

When not to overuse override:
- repeated override usually means your weekly load is too aggressive

## 8) How Planner Helps Your Goals

### Consistency
- regular sessions and realistic capacity prevent start-stop cycles.

### Avoiding overload
- caps, revision-only settings, and due prioritization keep backlog manageable.

### Balanced growth
- new and review are balanced so you do not trade retention for volume.

### Delayed durability
- delayed checks reduce false confidence from same-session fluency.

### Maintenance after stability
- once a unit passes Stage 4, it becomes stable
- a later good scheduled review can move it to maintained
- a weaker later review can lower it back to stable or ready without reopening Stage 4 automatically

## 9) Real-Life Usage Playbooks

### A) Beginner with limited time
- choose conservative profile and strict caps
- keep `2 sessions/day` only if truly practical; otherwise reduce complexity
- prioritize completion over volume

### B) Catch-up after missed days
- enable or keep revision-only behavior temporarily
- clear delayed checks and heavy review backlog first
- resume new gradually after pressure normalizes

### C) Stabilization before adding more
- hold new caps steady
- focus on Stage-4 completion quality
- increase only after several stable days

## 10) Troubleshooting by Symptom

### Symptom: review pressure is too high
- reduce new caps
- add more revision-only structure
- recalibrate review pace
- treat weak-retention units first; the planner now does this more aggressively when recent Companion quality is low

### Symptom: too many missed sessions
- reduce session complexity (fewer timed constraints)
- use availability model that matches reality
- remove overly strict windows

### Symptom: new retention is weak
- lower daily new volume
- complete delayed checks before adding more
- ensure companion new-stage flow is being completed properly
- expect Today to reduce new assignment sooner until recent Companion retention signals improve

### Symptom: delayed checks keep piling up
- treat Stage-4 due items first in Today
- avoid repeated overrides
- reduce new workload until delayed items stabilize

## 11) Quick Glossary (Plain Language)

- New memorization: newly assigned content for first encoding.
- Review: previously learned content brought back for recall.
- Revision-only day: no new assignments, review only.
- Calibration: teaching the app your real pace.
- Forecast: projection of likely workload and pressure.
- Stage-4 delayed check: short, strict verification after time delay.
- Soft-block: planner discourages/blocks new by default but still allows explicit override.
- Companion chain: staged memorization flow used to encode, retrieve, and stabilize.

## 12) Related Links

- Main canonical architecture brief: `APP_KNOWLEDGE.md`
- Whole-app non-technical guide: `docs/assistant/features/APP_USER_GUIDE.md`
- Planner workflow runbook: `docs/assistant/workflows/PLANNER_WORKFLOW.md`
- Scheduling + companion runbook: `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`
