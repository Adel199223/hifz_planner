# Roadmap Anchor

Persistent continuity anchor for future chats and handoffs.

## Default Meaning Of "Roadmap"

- Unless the user explicitly redirects, `roadmap`, `master plan`, and `next milestone` mean the Adaptive Hifz Path track.
- Treat this file as the canonical continuity file for roadmap resume work.
- This repo does not use `SESSION_RESUME.md`.

## Active Product Direction

The active product reset is:
- **Adaptive Hifz Path for solo learners**

Core truth to preserve:
- the app should increasingly behave like a daily adaptive Quran memorization companion
- the reader remains a strength and should stay as a support tool
- audio remains a strength and should stay as a support tool
- local-first persistence remains a strength and should stay intact where possible

Primary product docs:
- `docs/strategy/adaptive-hifz-path-solo-master-plan.md`
- `docs/roadmap/adaptive-hifz-path-solo-roadmap.md`
- `docs/algorithms/adaptive-hifz-scheduler-v1.md`
- `docs/ux/solo-learner-daily-flow.md`
- `docs/backlog/wave-1-implementation-backlog.md`

## Current Roadmap State

As of 2026-03-25, the roadmap reset has moved from documentation-only into active Wave 1 implementation.

Wave 0 status:
- product-reset docs imported into top-level `docs/`
- repo entrypoints updated to reflect the new center of gravity
- treat Wave 0 as complete enough for continuity purposes

Current continuity ExecPlan:
- `docs/assistant/exec_plans/active/2026-03-25_wave1_guided_daily_hifz_path.md`

Wave 1 status on the current feature branch:
- Today now leads with one obvious next action
- Today now shows a path mode (`green`, `protect`, `recovery`) and clearer new-lock messaging
- Today now groups work into warm-up, due review, weak spots, and optional new
- scheduler, DB schema, reader, and companion route structure remain intact

## Next Milestone

The next implementation milestone is:
- **Wave 1 - Guided daily path hardening and merge readiness**

Practical meaning:
- re-run targeted Today/planner validation once the local Flutter toolchain is stable
- verify the guided path flow end-to-end on Today
- keep the existing scheduler, DB contracts, and companion routes intact while landing the new surface
- after Wave 1 is stable, move to deeper adaptive queue tuning and weak-spot refinement in Wave 2

Recommended Wave 1 starting files:
- `lib/screens/today_screen.dart`
- `lib/data/services/daily_planner.dart`
- `lib/screens/companion_chain_screen.dart`
- `lib/data/database/app_database.dart`
- `lib/data/repositories/companion_repo.dart`

## Dormant Previous Milestone

The previous active milestone is now dormant:
- `docs/assistant/exec_plans/active/2026-03-12_companion_live_asr.md`

Status:
- keep it as reference-only
- do not treat it as the default next milestone unless the roadmap explicitly returns to ASR work
- it was superseded by the Adaptive Hifz Path reset, not completed

## Resume Checklist

1. Open `APP_KNOWLEDGE.md`.
2. Open this file.
3. Open `docs/strategy/adaptive-hifz-path-solo-master-plan.md`.
4. Open `docs/roadmap/adaptive-hifz-path-solo-roadmap.md`.
5. Open `docs/assistant/exec_plans/active/2026-03-25_wave1_guided_daily_hifz_path.md`.
6. For Wave 1 follow-up work, start with `lib/screens/today_screen.dart`, `lib/screens/today_path.dart`, and `lib/data/services/daily_planner.dart`.

## Code Anchors

- `lib/screens/today_screen.dart`
- `lib/data/services/daily_planner.dart`
- `lib/screens/companion_chain_screen.dart`
- `lib/data/services/review_completion_service.dart`
- `lib/data/database/app_database.dart`
- `lib/data/repositories/companion_repo.dart`
- `test/screens/today_screen_test.dart`
- `test/data/services/daily_planner_test.dart`
- `test/screens/companion_chain_screen_test.dart`

## Web V1 Continuity Update (2026-03-26)

A serious web implementation pass is now active.

Active continuity ExecPlan:
- `docs/assistant/exec_plans/active/2026-03-26_web_adaptive_hifz_v1.md`
- `docs/assistant/exec_plans/active/2026-03-26_review_followups_web_v1.md`

Current milestone overlay:
- keep the Adaptive Hifz Path product direction unchanged
- treat browser-first web support as the active platform milestone that strengthens Today, Reader, Companion, Plan, My Quran, and Settings
- preserve native Windows behavior while tightening platform seams

Immediate next checks:
- finish browser smoke validation in Chromium, especially guided setup completion and storage-gated persistence checks
- confirm `flutter build web` output and Drift web storage behavior
- keep Today, Plan, and Settings aligned with the typed planner/storage truth added in the browser-first follow-up pass
- keep zero-unit Today aligned with the new non-materializing first-run preview so guided setup remains the sole release-visible creator of the first memorization unit
- keep docs and harness profile aligned with the new web surface
