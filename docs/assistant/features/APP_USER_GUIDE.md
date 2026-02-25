# App User Guide (Non-Technical)

This is a plain-language guide to how the app works as a complete system, so you can choose the right screen at the right time and keep memorization quality high over months, not just days.

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
- Reader
- Bookmarks
- Notes
- Plan
- Today
- Settings
- About

Additional top-right menu areas:
- Read
- Learn
- My Quran
- Quran Radio
- Reciters

## What Each Area Is For

- Reader: read Quran in focused reading modes, with audio and word-level aids.
- Bookmarks: keep important places for quick return.
- Notes: capture reflections or reminders linked to verses.
- Plan: configure memorization workload and scheduling rules.
- Today: execute the day’s work in priority order.
- Companion chain: run the memorization stages for specific units.
- Settings: language/theme and data/import controls.

## Core User Journeys

## 1) Read and Reflect

Go to Reader when your goal is comprehension, listening, and context.

Typical actions:
- navigate by surah/ayah/page/juz
- listen to recitation
- use translation and word interactions
- add bookmarks/notes

## 2) Plan Your Memorization

Go to Plan when you need to set or revise:
- your available time
- new/review pacing
- weekly schedule structure
- calibration and forecast

This is where you define your system before execution.

## 3) Execute Today’s Work

Go to Today to act on:
- delayed consolidation checks
- planned reviews
- planned new memorization

This screen is intentionally action-oriented: less setup, more execution.

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

- I want to set my daily/weekly memorization load -> Plan
- I want to do what is due right now -> Today
- I need to run a memorization stage -> Companion
- I want pure Quran reading/listening -> Reader
- I need to revisit saved locations -> Bookmarks
- I want to store verse-linked thoughts -> Notes
- I need language/theme adjustments -> Settings

## Common First-Week Path

1. Set a conservative plan in `Plan`.
2. Execute `Today` consistently for several days.
3. Use Companion for new units and reviews from Today actions.
4. Respect delayed checks when they appear.
5. Use calibration/forecast after enough real samples.
6. Increase load only after quality is stable.

## Common Mistakes to Avoid

- adding too much new material too early
- ignoring delayed checks repeatedly
- using override as routine, not exception
- changing many planner variables at once
- judging progress by volume only, not stability

## Deeper Guides

- Planner deep guide: `docs/assistant/features/PLANNER_USER_GUIDE.md`
- Canonical architecture/status: `APP_KNOWLEDGE.md`
- Planner workflow runbook: `docs/assistant/workflows/PLANNER_WORKFLOW.md`
- Scheduling + companion workflow: `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`

