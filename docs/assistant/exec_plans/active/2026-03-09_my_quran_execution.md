# ExecPlan: My Quran Personal Hub Execution Tracker

## Purpose
- Keep the My Quran roadmap durable inside the repo.
- Track the execution order for the four My Quran-focused waves.
- Provide one file to return to after interruptions, docs sync, or publish steps.

## Scope
- In scope:
  - Wave 1 through Wave 4 status tracking
  - branch and worktree mapping
  - current blockers
  - detours and plan updates
  - next recommended action
- Out of scope:
  - replacing wave-specific ExecPlans
  - detailed implementation steps for each wave

## Assumptions
- The planner, Practice from Memory, Goals + Progress, and Reader Understanding roadmaps are complete and now serve as historical context.
- `My Quran` stays a secondary support surface, not a new top-level destination.
- Route stability and DB-schema stability are preferred.
- One SharedPreferences-backed last-reader snapshot is acceptable for practical resume behavior.

## Milestones
1. Start and complete Wave 1 real My Quran hub foundation.
2. Start and complete Wave 2 saved study and resume depth.
3. Start and complete Wave 3 personal setup shortcuts.
4. Start and complete Wave 4 cross-surface consistency and closeout.
5. Close the roadmap and define the next backlog.

## Detailed Steps
1. Start Wave 1 on an isolated worktree and add a wave-specific ExecPlan.
2. Keep Wave 1 focused on the three-card My Quran hub using existing local data and a lightweight last-reader snapshot shape.
3. Start Wave 2 only after Wave 1 closes so saved-study previews build on a stable hub.
4. Keep Wave 3 focused on lightweight study-setup shortcuts, not full settings duplication.
5. Use Wave 4 to align My Quran, Library, Reader, and user-facing docs around one vocabulary.

## Decision Log
- 2026-03-09: Start a new roadmap instead of extending the completed Reader roadmap.
- 2026-03-09: Keep the roadmap integrated and practical, using existing local data first.
- 2026-03-09: Allow one lightweight SharedPreferences-backed last-reader snapshot; do not open DB migrations.
- 2026-03-09: Keep Quran Radio out of scope for this roadmap.

## Validation
- For each active wave, run the focused screen and preference tests listed in that wave's ExecPlan.
- Run `dart tooling/validate_agent_docs.dart` after tracker or ExecPlan updates.
- Run `dart tooling/validate_localization.dart` when wave work changes learner-facing wording.

## Progress
- [x] Start Wave 1
- [ ] Merge Wave 1
- [ ] Start Wave 2
- [ ] Merge Wave 2
- [ ] Start Wave 3
- [ ] Merge Wave 3
- [ ] Start Wave 4
- [ ] Merge Wave 4
- [ ] Close the roadmap

## Surprises and Adjustments
- Use this section for sequence changes, blockers, or scope corrections discovered during implementation.

## Handoff
- Roadmap order:
  - Wave 1: Real My Quran Hub Foundation
  - Wave 2: Saved Study and Resume Depth
  - Wave 3: Personal Setup Shortcuts
  - Wave 4: Cross-Surface Consistency and Closeout
- Wave status:

| Stream | Status | Branch | Worktree | Notes |
|---|---|---|---|---|
| Previous planner roadmap | merged | historical | removed | Wave 1-7 completed before this roadmap started |
| Practice from Memory roadmap | merged | historical | removed | Focused 4-wave practice roadmap completed before this roadmap started |
| Goals + Progress roadmap | merged | historical | removed | Supportive 4-wave goals roadmap completed before this roadmap started |
| Reader Understanding roadmap | merged | historical | removed | Integrated 4-wave reader roadmap completed before this roadmap started |
| My Quran Wave 1 | active | `feat/my-quran-wave1-real-hub` | `/home/fa507/dev/hifz_planner_my_quran_wave1` | Three-card hub foundation implemented locally and awaiting closeout |

- Current blockers:
  - No blocker is recorded at roadmap start.
- Detours and plan updates:
  - 2026-03-09: New roadmap opened after the Reader Understanding roadmap completed.
  - 2026-03-09: Wave 1 started in isolated worktree `/home/fa507/dev/hifz_planner_my_quran_wave1` on branch `feat/my-quran-wave1-real-hub`.
  - 2026-03-09: Wave 1 now replaces the My Quran placeholder with a real three-card hub:
    - `Continue reading`
    - `Saved for later`
    - `Listening setup`
  - 2026-03-09: Wave 1 adds one lightweight last-reader snapshot shape to app preferences without changing routes or DB schema.
  - 2026-03-09: Wave 1 validation is green in the isolated worktree:
    - `flutter test -j 1 -r expanded test/screens/my_quran_screen_test.dart`
    - `flutter test -j 1 -r expanded test/app/app_preferences_test.dart`
    - `flutter test -j 1 -r expanded test/app/app_preferences_store_test.dart`
    - `flutter analyze --no-fatal-infos --no-fatal-warnings`
    - `dart tooling/validate_localization.dart`
    - `dart tooling/validate_agent_docs.dart`
    - `dart tooling/validate_workspace_hygiene.dart`
  - 2026-03-09: Fresh-worktree Flutter bootstrap touched `pubspec.lock` before validation; the incidental churn was reverted so Wave 1 remains dependency-neutral.
  - 2026-03-09: Starting overlapping Flutter commands in the same worktree triggered the known local startup-lock pattern again; the trusted validation record uses sequential Flutter runs.
  - 2026-03-09: Narrow Assistant Docs Sync completed for the canonical brief, assistant bridge, app user guide, and issue memory so future restarts do not need to reconstruct the Wave 1 My Quran scope from source diffs.
- Next recommended action:
  - close Wave 1 with commit, PR, and merge
