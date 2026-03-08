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

1. Open `My Plan` and choose `Easy`, `Normal`, or `Intensive`.
2. Enter realistic weekly or weekday minutes, then choose the fluency option that best matches you.
3. Check the summary card and press `Activate`.
4. Open `Advanced` only if you need to fine-tune scheduling, calibration, or forecast later.

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
- `My Plan` -> define your capacity and schedule rules
- `Today` -> execute what is due (reviews, new memorization, delayed checks)
- `Companion` -> run memorization/retrieval stages for each unit
- Delayed consolidation checks -> verify stability after time has passed (especially next day)

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

## My Plan Screen Walkthrough (Top to Bottom)

Location: open the left navigation rail and select `My Plan`.

The screen now has three layers:
- guided setup first
- summary second
- `Advanced` only when you need expert controls

## 1) Guided setup

### Pace preset
- Where: top of the screen.
- Options:
  - `Easy`
  - `Normal`
  - `Intensive`
- What it controls: the starting posture of the planner.
- Daily impact:
  - `Easy` protects review more aggressively and keeps new work lighter
  - `Normal` balances review and new work
  - `Intensive` allows faster new work if your schedule is stable

### Weekly minutes or weekday minutes
- Where: guided setup card.
- What it controls: your realistic available study time.
- When to use:
  - `Weekly total` if your days are flexible
  - `Per weekday` if your week is predictable
- Daily impact: drives both the summary and the weekly planner preview.

### Fluency
- Where: guided setup card.
- What it controls: the starting pace assumptions for new and review time.
- Daily impact: changes how much content the app thinks fits into your time budget.

Important behavior:
- the weekly planner preview now follows the time values you enter in the guided setup
- it no longer depends on old hidden advanced defaults

## 2) Plan summary and activation

### Summary card
- Where: directly below the guided setup.
- What it shows:
  - chosen pace
  - weekly and daily time summary
  - new-work limits
  - review-priority posture
- Why it matters: this is the plain-language confirmation step before activation.

### Activate
- Where: primary button in the summary card.
- What it does: saves your plan and starts using it in `Today`.
- When to use: after the summary looks realistic, not idealized.

## 3) Advanced

Location: `Advanced` card below the summary.

Use `Advanced` only when you need to fine-tune details.
Most learners do not need it on first setup.

### Fine-tune this plan
- Includes:
  - planner profile
  - review-protection toggle
  - new-work caps
  - new/review minutes per ayah
  - page-metadata requirement
- Use this when:
  - the default preset is close, but not quite right
  - your real pace is clearly lighter or heavier than the summary suggests

### Automatic scheduling
- Includes:
  - sessions per day
  - exact times
  - study days
  - revision-only days
  - availability model
  - windows and flex rules
- Use this when:
  - you need the plan to match a real weekly structure
  - you need fixed times or study windows

### Weekly calendar
- Shows:
  - next 7 days
  - session focus, minutes, timing, and status
  - day-level overrides
- Use this to spot overload days before they happen.

### Calibration
- Purpose: teach the planner your real speed using real sessions.
- Use this after you have enough actual memorization/review samples.
- It is no longer part of the normal first-run path.

### Forecast
- Purpose: run a deterministic workload projection.
- Use this after your base plan is already stable.
- It is also no longer part of the normal first-run path.

## 6) Today Screen Execution Flow

Location: `Today` in the main navigation rail.

Execution order is designed to protect retention quality:

### Coaching card
- the top card tells you:
  - what to do next
  - why it matters today
  - what to do if you only have a short amount of time
- if the day feels too heavy, use the recovery entry to jump back to `My Plan`

### Session section
- shows today session blocks and status
- helps you anchor when to study

### Stage-4 delayed checks section
- shows delayed consolidation items (especially mandatory next-day checks)
- these are high priority because they verify durability after delay

### Planned reviews section
- review rows with grading actions
- supports immediate scheduler updates based on your quality

### Planned new section
- new unit rows with actions:
  - open in reader
  - open companion chain (new mode)

## 7) Stage-4 Priority and Soft-Block Behavior

You may see new memorization blocked by default when mandatory delayed checks are due.

Why this happens:
- the app protects retention quality first
- unresolved delayed checks are a strong signal that stability needs attention

Override behavior:
- you can override once and continue to new memorization
- override is logged (not ignored)

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

### Symptom: too many missed sessions
- reduce session complexity (fewer timed constraints)
- use availability model that matches reality
- remove overly strict windows

### Symptom: new retention is weak
- lower daily new volume
- complete delayed checks before adding more
- ensure companion new-stage flow is being completed properly

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
