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

1. Open `Plan` and set a conservative daily/weekly load you can keep for at least 7 days.
2. Open `Today` and complete tasks in the shown order (delayed checks, review, then new work).
3. Use Companion stages only from `Today` actions to avoid skipping required sequence.
4. Re-check your plan after several consistent days before increasing new material.

## Terms in Plain English

- Delayed check: a later memory check (usually next day) to confirm recall is still stable.
- Calibration: adjusting planner estimates using your real session pace.
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

## Known Limits and Placeholder Areas

- `My Quran` is a working dashboard for resuming your next target, checking your current snapshot, and reopening saved places quickly.
- `Quran Radio` is still a placeholder/coming-soon surface.
- `Reciters` is not a placeholder: it is a functional searchable reciter selector for playback preferences.

## What Each Area Is For

- Reader: read Quran in focused reading modes, with audio and word-level aids.
- Bookmarks: keep important places for quick return.
- Notes: capture reflections or reminders linked to verses.
- Plan: configure memorization workload and scheduling rules.
- Today: execute the day’s work in priority order.
- My Quran: reopen your next target, check counts for due work/bookmarks/notes, and jump back into related areas.
- Companion chain: run the memorization stages for specific units.
- Settings: language/theme and data/import controls.
- About: get a quick overview of what the app does, see your current setup, and jump into the main areas.

## Core User Journeys

## 1) Read and Reflect

Go to Reader when your goal is comprehension, listening, and context.

Typical actions:
- navigate by surah/ayah/page/juz
- listen to recitation
- download the current surah's audio for offline replay in Reader
- use translation and word interactions
- show or hide verse translations, word tooltips, and hovered-word highlights
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
- review mode for hidden-first review, with a save-to-schedule step at the end
- new mode for staged acquisition to robustness flow
- delayed mode for Stage-4 consolidation checks

## Companion Lifecycle in Plain Terms

The app supports a staged learning progression:

- Stage 1 (acquisition): listen-repeat plus early retrieval so memory traces start correctly.
- Stage 2 (bridge): reduce cue support, add discrimination and early linking.
- Stage 3 (hidden robustness): hidden recall, stronger linking, correction loops.
- Stage 4 (delayed consolidation): verify stability after delay, especially next day.
- Stage 5 (maintenance): begins after a stable unit succeeds on a later scheduled review.

Simple rule:
- earlier stages build access
- later stages prove stability

What Stage 5 means in practice:
- after Stage 4 passes, the unit becomes stable
- the next good scheduled review can move it to maintained
- later weaker scheduled reviews can lower it back to stable or ready
- this quality drop does not reopen Stage 4 automatically in the current version

## Why Today Prioritizes Certain Items First

Today prioritization is quality-driven:
- delayed checks are high priority because they detect false fluency
- review protects previously learned material
- new memorization is important, but not at the cost of collapsing retention

Review rows can also show a small lifecycle badge such as Ready, Stable, or Maintained so you can see the unit's current quality state at a glance.

If delayed checks are due, new memorization can be soft-blocked by default to protect quality.

## Personalization and Preferences

You can personalize:
- app language
- app theme
- companion autoplay behavior
- Reader reciter, playback speed, and repeat count
- Reader translation visibility and word-by-word display aids

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

## Deeper Guides (only present with in the app folder/repo)

- Planner deep guide: `docs/assistant/features/PLANNER_USER_GUIDE.md`
- Canonical architecture/status: `APP_KNOWLEDGE.md`
- Planner workflow runbook: `docs/assistant/workflows/PLANNER_WORKFLOW.md`
- Scheduling + companion workflow: `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`
