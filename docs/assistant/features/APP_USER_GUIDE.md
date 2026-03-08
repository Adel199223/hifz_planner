# App User Guide (Non-Technical)

This is a plain-language guide to how the app works as a complete system, so you can choose the right screen at the right time and keep memorization quality high over months, not just days.

## Use This Guide When

Use this guide for:
- user support and non-technical app explanation
- onboarding conversations about what each area of the app is for
- high-level feature expectations and day-to-day usage flow

## Do Not Use This Guide For

Do not use this guide for:
- DB schema/migration details
- implementation internals or architecture decisions
- authoritative behavior when this guide conflicts with canonical docs/code

## For Agents: Support Interaction Contract

When using this guide in support replies:
- answer in plain language first
- provide numbered next steps with exact UI labels from this guide
- run a canonical cross-check with `APP_KNOWLEDGE.md` when details affect behavior claims
- avoid unsupported promises and call out uncertainty if behavior is evolving
- define unavoidable technical terms in one short sentence
- route technical follow-ups to canonical docs/workflows instead of extending assumptions

## Canonical Deference Rule

If this guide conflicts with technical docs:
- `APP_KNOWLEDGE.md` is canonical for app-level architecture/status
- source code is final truth

## Quick Start (No Technical Background)

1. Open `My Plan`, choose `Easy`, `Normal`, or `Intensive`, then enter a realistic weekly or weekday time budget.
2. Open `Today` and complete tasks in the shown order (delayed checks, review, then new work).
3. Use Companion stages only from `Today` actions to avoid skipping required sequence.
4. Open `Advanced` in `My Plan` only if you need to fine-tune scheduling, forecast, or pace calibration later.
5. If the app says the plan is `Tight` or `Overloaded`, use the lighter-day guidance before forcing more new work.

## Terms in Plain English

- Delayed check: a later memory check (usually next day) to confirm recall is still stable.
- Calibration: teaching the planner your real session pace using a few real samples.
- Canonical: the final source to trust if two docs disagree (`APP_KNOWLEDGE.md`, then source code).

## What This App Is For

Hifz Planner combines:
- Quran reading tools
- planning and scheduling
- guided memorization stages
- delayed durability checks

The goal is not just to finish more pages, but to build reliable long-term retention with a sustainable daily rhythm.

## Who This Guide Is For

Use this guide if you are:
- a learner managing your own memorization plan
- a parent/teacher supporting a learner
- a support agent helping users navigate the app clearly

## Main Navigation Map

Primary areas:
- Today
- Read
- My Plan
- Library

Inside `Library`:
- Bookmarks
- Notes

Inside `More`:
- Settings
- About
- Reciters
- Learn
- My Quran
- Quran Radio

`More` is the top-right menu button.

## Known Limits and Placeholder Areas

- `My Quran` and `Quran Radio` are currently placeholder/coming-soon surfaces.
- `Reciters` is not a placeholder: it is a functional searchable reciter selector for playback preferences.

## What Each Area Is For

- Today: execute the day’s work in priority order.
- Read: open the Reader for focused Quran reading, listening, and verse tools.
- My Plan: start with a guided plan setup, then open `Advanced` only when you need expert controls.
- Library: open saved material and writing tools in one place.
- Companion chain: run the memorization stages for specific units.
- More: open settings, reciters, about, and secondary exploration areas.

## Core User Journeys

## 1) Read and Reflect

Go to `Read` when your goal is comprehension, listening, and context.

Typical actions:
- navigate by surah/ayah/page/juz
- listen to recitation
- use translation and word interactions
- add bookmarks/notes from the Reader, then revisit them later in `Library`

## 2) Plan Your Memorization

Go to `My Plan` when you need to set or revise:
- your pace preset (`Easy`, `Normal`, `Intensive`)
- your available time
- new/review pacing
- weekly schedule structure
- calibration and forecast in `Advanced`

This is where you define your system before execution.
The default setup path is intentionally simple, and the expert tools are hidden under `Advanced`.

What is new in `My Plan`:
- a `Plan health` card
- simple status labels: `On track`, `Tight`, `Overloaded`
- plain-language hints when you should use a lighter day, burn down backlog, or switch into recovery
- a weekly preview and forecast that now follow the same load-protection logic as `Today`
- a forecast summary that explains the big picture first, before showing detailed curves
- a simple forecast confidence label so you know whether the estimate is strong or still rough
- calibration guidance that tells you when you have enough real samples to update planner pace with better confidence
- a forecast pace-trend note that can tell you when recent real sessions are making the planner slightly more cautious or slightly more permissive than your baseline plan

## 3) Execute Today’s Work

Go to Today to act on:
- delayed consolidation checks
- planned reviews
- planned new memorization

This screen is intentionally action-oriented: less setup, more execution.

What you will now see first:
- a `Do this next` card at the top
- a short explanation of why that action comes first
- an `If you only have 10 minutes` fallback
- a recovery entry that sends you back to `My Plan` if the day feels too heavy
- a health label that shows whether today is `On track`, `Tight`, or `Overloaded`
- an explanation box that tells you why new work is normal, lighter, or paused
- a `Recovery assistant` button on heavier days
- stricter protection against token new work when delayed checks and review already consume the safe part of the day

## 4) Memorize with Companion Stages

Open Companion from Today rows to run staged memorization flows:
- review mode for hidden-first review
- new mode for staged acquisition to robustness flow
- delayed mode for Stage-4 consolidation checks

## Companion Lifecycle in Plain Terms

The app supports a staged learning progression:

- Stage 1 (acquisition): listen-repeat plus early retrieval so memory traces start correctly.
- Stage 2 (bridge): reduce cue support, add discrimination and early linking.
- Stage 3 (hidden robustness): hidden recall, stronger linking, correction loops.
- Stage 4 (delayed consolidation): verify stability after delay, especially next day.
- Stage 5 (maintenance concept): long-term upkeep scheduling after stable delayed checks.

Simple rule:
- earlier stages build access
- later stages prove stability

## Why Today Prioritizes Certain Items First

Today prioritization is quality-driven:
- delayed checks are high priority because they detect false fluency
- review protects previously learned material
- new memorization is important, but not at the cost of collapsing retention

If delayed checks are due, new memorization can be soft-blocked by default to protect quality.
Even when that block is overridden, delayed checks still take real planner time before new work is assigned.

Plain-language rule:
- do the one thing at the top of `Today` first
- if your day is tight, use the short-day suggestion before trying to finish everything
- if the app marks the day as `Overloaded`, use the `Recovery assistant` or return to `My Plan` before pushing extra new work

## Personalization and Preferences

You can personalize:
- app language
- app theme
- companion autoplay behavior

Plan-level personalization also exists:
- session structure
- day availability
- pace assumptions

## Data and Reliability Expectations

The app is local-first in core planning and memorization data.

What this means:
- your planning/scheduling state is saved locally
- memorization telemetry and progress are persisted locally
- many features continue working even if some external data is unavailable

If some remote assets fail temporarily:
- core planner and companion flows continue
- reading/presentation may use fallback behaviors where needed

## Where to Go for X (Quick Decision Table)

- I want to set a realistic memorization pace quickly -> My Plan
- I want to do what is due right now -> Today
- I missed sessions and need a safe recovery path -> Today -> Recovery assistant
- I need to run a memorization stage -> Companion
- I want pure Quran reading/listening -> Read
- I need to revisit saved locations -> Library -> Bookmarks
- I want to store verse-linked thoughts -> Library -> Notes
- I need language/theme adjustments -> More -> Settings
- I want forecast or pace calibration tools -> My Plan -> Advanced
- I want to check whether the week and Today are using the same workload logic -> My Plan -> Advanced -> Forecast

## Common First-Week Path

1. Set a conservative plan in `My Plan` with `Easy` or `Normal`.
2. Execute `Today` consistently for several days.
3. Use Companion for new units and reviews from Today actions.
4. Respect delayed checks when they appear.
5. If `Today` or `My Plan` starts showing `Tight` or `Overloaded`, use the lighter-day and recovery guidance before increasing load.
6. Use `Advanced` and then calibration/forecast only after enough real samples.
7. When you open Forecast, read the summary and confidence line first; the detailed curves are there only if you want more detail.
7. Increase load only after quality is stable.

## Common Mistakes to Avoid

- adding too much new material too early
- ignoring delayed checks repeatedly
- using override as routine, not exception
- changing many planner variables at once
- judging progress by volume only, not stability

## Deeper Guides (only present with in the app folder/repo)

- Planner deep guide: `docs/assistant/features/PLANNER_USER_GUIDE.md`
- Canonical architecture/status: `APP_KNOWLEDGE.md`
- Planner workflow runbook: `docs/assistant/workflows/PLANNER_WORKFLOW.md`
- Scheduling + companion workflow: `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`
