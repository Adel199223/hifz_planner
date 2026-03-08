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
4. Open `Advanced` only if you need to fine-tune scheduling, pace calibration, or forecast later.

## Terms in Plain English

- Calibration: teaching the planner your real speed with a few real samples so future assignments fit better.
- Forecast: a forward estimate of workload based on your current settings, your calibration data, and current planner pressure.
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
- `Practice from Memory` -> run the memorization/retrieval session for each unit
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

### Weekly goal summary
- Where: below the main summary card and above `Plan health`.
- What it shows:
  - `Steady progress`
  - `Protect retention`
  - `Recovery and stabilize`
- What it means:
  - `Steady progress` = the current plan still has room for sustainable forward movement
  - `Protect retention` = review pressure is high enough that protecting old work matters more than pushing harder
  - `Recovery and stabilize` = the safest weekly target is to reduce pressure and rebuild consistency first
- Important:
  - this is not a separate goal-setting wizard
  - it changes automatically with your current planner pressure
  - it is meant to help you interpret the week, not to add more settings

### Last 7 days summary
- Where: inside the same summary area in `My Plan`.
- What it shows:
  - active days in the last 7 days
  - completed reviews
  - completed delayed checks
  - completed practice completions
  - a simple recent review-quality label
- What it is for:
  - helping you trust whether the current plan is actually being carried out
  - showing recent consistency without turning progress into a streak game
  - giving a calm no-history state when you are just starting or restarting
- Important:
  - it is count-based on purpose
  - it does not pretend to measure everything with exact minutes
- completed non-stage4 practice is currently shown as generic completed practice, not as a more specific label the app cannot yet prove reliably
- the no-history state is intentionally calm and supportive instead of looking like a failed or empty dashboard
- if recent activity is still sparse, the summary now says that you are getting back into rhythm instead of pretending the weekly signal is already strong

### Recommendation layer
- Where: directly alongside the summary area in `My Plan`.
- What it shows:
  - `Stay steady`
  - `Use the minimum day for now`
  - `Protect retention for a few days`
  - `Lighten the setup here`
- What it is for:
  - turning your current weekly picture into one calm recommendation
  - keeping `My Plan` aligned with the same guidance logic used by `Today`
  - helping you understand when the right move is to simplify rather than force more output
- Important:
- this is advice-only
- it does not silently change your settings
- it now says explicitly that only real completed practice, review, or delayed-check work counts as progress
- it now stays aligned with the same progress-state wording used by `Today`

### Activate
- Where: primary button in the summary card.
- What it does: saves your plan and starts using it in `Today`.
- When to use: after the summary looks realistic, not idealized.

## 3) Plan health

### Plan health card
- Where: below the summary and above `Advanced`.
- What it shows:
  - `On track`
  - `Tight`
  - `Overloaded`
- What it means:
  - `On track` = your current setup still looks sustainable
  - `Tight` = review pressure or due-soon pressure is rising, so new work should stay lighter
  - `Overloaded` = recovery pressure is high enough that protecting review is more important than pushing new material

### Extra hints under plan health
- You may also see:
  - minimum-day guidance
  - backlog burn-down guidance
  - recovery suggestions
- These are guidance-only. They do not silently change your plan.
- These hints now come from the same deterministic stress logic used by `Today`, the weekly calendar, and Forecast.

Simple rule:
- if you see `Tight`, stay conservative
- if you see `Overloaded`, lighten the next few days before increasing new work again

## Cross-Surface Consistency

`Today` and `My Plan` now use the same calm progress language for:
- no meaningful history yet
- sparse recent activity
- recovery-safe lighter weeks

That means the weekly summary, the hint text, and the surrounding guidance should no longer feel like two different systems.

## 4) Advanced

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
- The calendar now follows the same load-protection logic as `Today`:
  - tighter days can show `due soon`
  - overloaded days can switch sessions to review-only focus

### Calibration
- Purpose: teach the planner your real speed using real sessions.
- Use this after you have enough actual memorization/review samples.
- It is no longer part of the normal first-run path.
- It now gives plain guidance:
  - if you still need more samples
  - or if you have enough samples for a reasonably useful pace update
- Applying calibration can update the planner today or starting tomorrow.
- Recent calibration pace can now also give the shared planner one small adaptive nudge:
  - if your real pace is clearly slower than the active plan, the planner protects a little more review time
  - if your real pace is clearly faster, the planner may allow a little more new work
- This remains bounded and explainable; it does not become a black-box system.

### Forecast
- Purpose: run a deterministic workload projection.
- Use this after your base plan is already stable.
- It is also no longer part of the normal first-run path.
- Forecast now shares the same allocation policy as `Today`, so it should feel more consistent with the real day view.
- Forecast now starts with:
  - a plain-language summary
  - a simple confidence label
  - a short hint about why the estimate is strong or weak
- Forecast can now also show a short pace-trend note when recent calibration is nudging the shared planner a bit slower or faster than your baseline settings.
- The detailed curves are still there, but they are no longer the first thing a learner has to interpret.

## 5) Today Screen Execution Flow

Location: `Today` in the main navigation rail.

Execution order is designed to protect retention quality:

### Coaching card
- the top card tells you:
  - what to do next
  - why it matters today
  - what to do if you only have a short amount of time
- it now also includes a small goal-focus block that tells you:
  - what counts as a good day today
  - how the main task supports the weekly goal
  - what still counts on a short day
- it now also includes a small last-7-days progress block that tells you:
  - whether recent consistency is building
  - what kind of real work you completed recently
  - whether review quality looks steady, mixed, or strained
- if more than one valid practice mode is available, the card can also show secondary shortcuts for the other modes
- if the day feels too heavy, use the recovery entry to jump back to `My Plan`

### Health and explanation layer
- Today now also shows:
  - a health label: `On track`, `Tight`, or `Overloaded`
  - an explanation packet that tells you why today is shaped this way
- The explanation can tell you:
  - new work is paused for now
  - new work is lighter today
  - backlog burn-down is the safer posture for the next few days

### Minimum day
- If pressure is high, you may see `Do the minimum day`.
- This means:
  - do the top priority check or first review row
  - then stop without guilt if time is gone
- This is now enforced more honestly:
  - if the safe time left for new work is too small, the app pauses new assignments instead of creating tiny token tasks

### Supportive goal framing
- the app now uses one shared goal posture across `Today` and `My Plan`
- it is intentionally supportive, not gamified
- there are:
  - no badges
  - no streak warnings
  - no punishment language for missed days
- the purpose is to help you see whether this week should emphasize:
  - steady progress
  - protecting retention
  - or recovery and stabilization

### Recovery assistant
- If the app thinks you are falling behind, you may see `Recovery assistant`.
- It asks what happened most recently, then gives one recommended next step.
- It can guide you to:
  - take the minimum day first
  - or open `My Plan` to lighten the setup
- It does not silently change planner settings for you.

### Session section
- shows today session blocks and status
- helps you anchor when to study

### Stage-4 delayed checks section
- shows delayed consolidation items (especially mandatory next-day checks)
- these are high priority because they verify durability after delay
- mandatory Stage-4 due now also reserves real planner minutes before new work is considered

### Planned reviews section
- review rows with grading actions
- supports immediate scheduler updates based on your quality

### Planned new section
- new unit rows with actions:
  - open in reader
  - open companion chain (new mode)

## 6) Stage-4 Priority and Soft-Block Behavior

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
- even with override, delayed checks still consume planner time first

When not to overuse override:
- repeated override usually means your weekly load is too aggressive

## 7) How Planner Helps Your Goals

### Consistency
- regular sessions and realistic capacity prevent start-stop cycles.

### Avoiding overload
- caps, revision-only settings, and due prioritization keep backlog manageable.

### Balanced growth
- new and review are balanced so you do not trade retention for volume.

### Delayed durability
- delayed checks reduce false confidence from same-session fluency.

## 8) Real-Life Usage Playbooks

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

## 9) Troubleshooting by Symptom

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

### Symptom: new work disappeared even though I still have some time
- the planner may have decided the remaining safe time is too small for meaningful new memorization
- finish the top priority check or review first
- use the minimum day or recovery guidance instead of forcing token new work

### Symptom: the app says `Tight`
- use the minimum day more often for a few days
- keep new work modest
- watch whether review pressure starts falling again

### Symptom: the app says `Overloaded`
- use Recovery assistant
- protect delayed checks and the oldest review first
- reduce or pause aggressive new work until the backlog shrinks

## 10) Quick Glossary (Plain Language)

- New memorization: newly assigned content for first encoding.
- Review: previously learned content brought back for recall.
- Revision-only day: no new assignments, review only.
- Calibration: teaching the app your real pace.
- Forecast: projection of likely workload and pressure.
- Stage-4 delayed check: short, strict verification after time delay.
- Soft-block: planner discourages/blocks new by default but still allows explicit override.
- Practice from Memory: the guided memorization session used for new practice, review practice, and delayed checks.

## 11) Related Links

- Main canonical architecture brief: `APP_KNOWLEDGE.md`
- Whole-app non-technical guide: `docs/assistant/features/APP_USER_GUIDE.md`
- Planner workflow runbook: `docs/assistant/workflows/PLANNER_WORKFLOW.md`
- Scheduling + companion runbook: `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`
