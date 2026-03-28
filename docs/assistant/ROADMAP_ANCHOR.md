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

As of 2026-03-28, the roadmap reset has moved past the browser-first stabilization pass. Adaptive Queue V1 is now implemented in source and closed enough for continuity.

Wave 0 status:
- product-reset docs imported into top-level `docs/`
- repo entrypoints updated to reflect the new center of gravity
- treat Wave 0 as complete enough for continuity purposes

Current continuity ExecPlans:
- `docs/assistant/exec_plans/active/2026-03-25_wave1_guided_daily_hifz_path.md`
- `docs/assistant/exec_plans/active/2026-03-28_adaptive_queue_v1.md`

Wave 1 status on the current feature branch:
- Today now leads with one obvious next action
- Today now shows a path mode (`green`, `protect`, `recovery`) and clearer new-lock messaging
- Today now consumes planner-assigned adaptive buckets directly and groups work into warm-up / lock-in, weak spots, recent review, maintenance review, and optional new
- durable adaptive memory now lives on `companion_lifecycle_state`, and scheduled review grading updates weak-spot pressure and recent struggle state
- mature legacy/schedule-only units no longer stay stuck looking perpetually new when schedule truth already shows they are stable enough
- scheduler, DB schema, reader, and companion route structure remain intact
- browser-first stabilization is complete enough for continuity:
  - guided setup is the truthful zero-unit first-run path on Today and Settings
  - starter-plan repair is intent-safe
  - Plan no longer defaults fresh or repair-needed learners into revision-only
  - Playwright smoke is the browser validation path for this phase

## Next Milestone Direction

The next milestone should shift toward:
- **strengthening the memorization engine itself**

Practical meaning:
- deepen adaptive memorization truth and progression quality instead of doing more web plumbing
- keep the current web target as a supported platform surface, not the center of gravity
- preserve reader/audio/local-first strengths while improving memorization progression and review quality

Recommended next-step memorization-engine files:
- `lib/screens/today_screen.dart`
- `lib/data/services/daily_planner.dart`
- `lib/data/services/review_completion_service.dart`
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
5. Open `docs/assistant/exec_plans/active/2026-03-28_adaptive_queue_v1.md`.
6. For post-queue memorization-engine follow-up work, start with `lib/data/services/review_completion_service.dart`, `lib/data/services/daily_planner.dart`, `lib/screens/today_path.dart`, and `lib/screens/today_screen.dart`.

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

The browser-first stabilization pass is complete enough for continuity.

Active continuity ExecPlan:
- `docs/assistant/exec_plans/active/2026-03-26_web_adaptive_hifz_v1.md`
- `docs/assistant/exec_plans/active/2026-03-26_review_followups_web_v1.md`

Continuity overlay:
- keep the Adaptive Hifz Path product direction unchanged
- keep the real web target intact as a supported platform surface
- preserve native Windows behavior while the next milestone shifts back to product truth instead of platform plumbing

Known continuity caveats:
- local `flutter test` execution is still blocked in this environment by the native-assets `objective_c` `hook.dill` failure
- `flutter build web` still succeeds with the known non-fatal warnings about the missing `CupertinoIcons` font asset and the Drift wasm dry run
