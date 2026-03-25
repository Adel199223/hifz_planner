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

As of 2026-03-25, the roadmap has been reset at the documentation layer.

Wave 0 status:
- product-reset docs imported into top-level `docs/`
- repo entrypoints being updated to reflect the new center of gravity
- the current shipped UI remains Today + Plan + Reader + `/companion/chain` while the reset is in progress

Current continuity ExecPlan:
- `docs/assistant/exec_plans/active/2026-03-25_adaptive_hifz_path_wave0_docs.md`

## Next Milestone

The next implementation milestone is:
- **Wave 1 - Guided daily path MVP**

Practical meaning:
- make Today the main Hifz Path entry
- generate a daily queue with warm-up, due review, weak spots, and optional new memorization
- use simple self-grading and review-health unlock rules
- preserve existing route structure when rewrite friction is high
- launch the current Companion flow directly from the daily path instead of rebuilding everything first

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
5. Open `docs/assistant/exec_plans/active/2026-03-25_adaptive_hifz_path_wave0_docs.md` if Wave 0 is still in progress.
6. For Wave 1 implementation, start with `lib/screens/today_screen.dart` and `lib/data/services/daily_planner.dart`.

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
