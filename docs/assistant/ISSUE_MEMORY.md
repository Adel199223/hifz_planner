# Issue Memory

This is the reusable issue registry for repeated workflow, tooling, and docs failures in this repo.

Use it to:
- record repeatable issue classes, not one-off frustration
- help Assistant Docs Sync decide when touched-scope docs should widen
- surface generalized lessons that may later matter for bootstrap maintenance

## Update Rules

- Start empty. Do not seed fake incidents.
- Prefer operational triggers over wording:
  - wrong app, build, branch, or worktree opened
  - accepted feature stranded on a side branch
  - repeated docs/governance correction
  - repeated tool, host, or auth preflight failure
  - same workaround required more than once
  - regression after a previously accepted fix
- Keep entries concise. Long narratives belong in thread history, reports, or ExecPlans.

## Record Shape

Each issue entry should include:
- `id`
- `first_seen`
- `last_seen`
- `repeat_count`
- `status`
- `trigger_source`
- `symptoms`
- `likely_root_cause`
- `attempted_fix_history`
- `accepted_fix`
- `regressed_after_fix`
- `affected_workflows`
- `bootstrap_relevance`
- `docs_sync_relevance`
- `evidence_refs`

## Assistant Docs Sync Rule

Before widening touched-scope docs, check whether the current change matches a repeatable issue class.
If yes, update only the relevant workflow, guide, or routing docs and refresh this registry at the same time.

## Bootstrap Maintenance Rule

If bootstrap maintenance is ever requested explicitly, only consider entries whose `bootstrap_relevance` is `possible` or `required`.

## Current Registry

### `roadmap_resume_state_fragmentation_across_trackers`

- first seen: 2026-03-09
- last seen: 2026-03-09
- repeat count: 1
- status: mitigated
- trigger source:
  - fresh-session roadmap resume after multiple completed roadmaps and active-wave detours
- symptoms:
  - fresh sessions required reconstructing roadmap state from multiple active tracker files and recent chat context
  - the next exact roadmap step was recoverable, but not from one stable resume entrypoint
- likely root cause:
  - roadmap status existed in active trackers and wave plans, but there was no single stable session-resume file
- attempted fix history:
  - added a dedicated `docs/assistant/SESSION_RESUME.md` file as the first resume stop
  - routed fresh-session and resume-trigger docs to that file before the deeper tracker files
  - added validator coverage so resume routing and update order do not drift
- accepted fix:
  - keep `docs/assistant/SESSION_RESUME.md` as the stable fresh-session resume entrypoint and keep active roadmap trackers and active wave ExecPlans as the deeper execution sources
- regressed after fix:
  - no
- affected workflows:
  - future_restart_handoff
  - assistant_docs_sync
  - roadmap_closeout
- bootstrap relevance:
  - possible
- docs sync relevance:
  - required
- evidence refs:
  - `docs/assistant/SESSION_RESUME.md`
  - `docs/assistant/exec_plans/active/2026-03-09_my_quran_execution.md`
  - `docs/assistant/exec_plans/completed/2026-03-09_my_quran_wave2_saved_study_resume.md`

### `user_support_guide_density_after_multi_wave_growth`

- first seen: 2026-03-09
- last seen: 2026-03-09
- repeat count: 1
- status: mitigated
- trigger source:
  - repeated assistant-doc sync passes after many roadmap waves
- symptoms:
  - the broad app support guide became too dense for first-time orientation
  - future restarts depended too much on scattered roadmap memory instead of one beginner entrypoint
- likely root cause:
  - repeated feature-by-feature support updates were added to the same broad user guide without a dedicated first-time entrypoint
- attempted fix history:
  - created a separate primary beginner guide instead of continuing to widen the broad app support guide
  - updated routing docs and docs-sync rules so the beginner guide is maintained intentionally
- accepted fix:
  - keep `docs/assistant/features/START_HERE_USER_GUIDE.md` as the primary beginner guide, keep `APP_USER_GUIDE.md` as the broader support guide, and update the beginner guide only when beginner navigation or mental model changes
- regressed after fix:
  - no
- affected workflows:
  - assistant_docs_sync
  - support_doc_maintenance
  - future_restart_handoff
- bootstrap relevance:
  - possible
- docs sync relevance:
  - required
- evidence refs:
  - `docs/assistant/exec_plans/completed/2026-03-09_my_quran_wave2_saved_study_resume.md`
  - `docs/assistant/exec_plans/active/2026-03-09_my_quran_execution.md`
  - `docs/assistant/features/APP_USER_GUIDE.md`

### `flutter_parallel_test_plugin_symlink_race`

- first seen: 2026-03-08
- last seen: 2026-03-09
- repeat count: 3
- status: mitigated
- trigger source:
  - local Flutter validation in isolated worktrees
- symptoms:
  - overlapping Flutter commands in one worktree can break plugin-symlink state or stall on the startup lock
  - validation output becomes noisy or untrustworthy until rerun sequentially
- likely root cause:
  - concurrent Flutter startup/plugin work races shared ephemeral state inside one worktree
- attempted fix history:
  - Wave 1: reran the same validation set sequentially after the parallel run failed noisily
  - Wave 2: kept Flutter validation sequential from the start
  - My Quran Wave 1: stopped overlapping `flutter test` and `flutter analyze`, then reran validation sequentially
- accepted fix:
  - run Flutter commands sequentially per worktree
- regressed after fix:
  - no
- affected workflows:
  - feature validation
  - closeout validation
  - future wave implementation
- bootstrap relevance:
  - possible
- docs sync relevance:
  - required
- evidence refs:
  - `docs/assistant/exec_plans/active/2026-03-08_goals_progress_execution.md`
  - `docs/assistant/exec_plans/completed/2026-03-08_goals_wave2_weekly_progress.md`
  - `docs/assistant/exec_plans/completed/2026-03-09_my_quran_wave1_hub_foundation.md`

### `fresh_worktree_flutter_validation_lockfile_churn`

- first seen: 2026-03-08
- last seen: 2026-03-09
- repeat count: 4
- status: mitigated
- trigger source:
  - first Flutter validation in a fresh isolated worktree
- symptoms:
  - the first validation run can resolve dependencies and touch `pubspec.lock` even when the feature work is not changing dependencies
- likely root cause:
  - lazy dependency/bootstrap work happening on the first Flutter command in a new worktree
- attempted fix history:
  - Wave 2: allowed the initial validation bootstrap to complete, then manually reverted incidental `pubspec.lock` churn before closeout
  - Wave 3: the first fresh-worktree test run touched `pubspec.lock` again, and the incidental change was reverted after validation
  - Wave 4: `flutter test` touched `pubspec.lock` again in a fresh worktree, and the incidental change was reverted before closeout
  - My Quran Wave 1: fresh-worktree Flutter bootstrap touched `pubspec.lock` again, and the incidental change was reverted before docs sync
- accepted fix:
  - treat lockfile churn as incidental unless dependencies were intentionally changed, and revert it before closeout
- regressed after fix:
  - no
- affected workflows:
  - feature validation
  - commit/publish hygiene
- bootstrap relevance:
  - possible
- docs sync relevance:
  - possible
- evidence refs:
  - `docs/assistant/exec_plans/completed/2026-03-08_goals_wave2_weekly_progress.md`
  - `docs/assistant/exec_plans/completed/2026-03-08_goals_wave3_coaching_adjustment_guidance.md`
  - `docs/assistant/exec_plans/completed/2026-03-08_goals_wave4_cross_surface_consistency.md`
  - `docs/assistant/exec_plans/completed/2026-03-09_my_quran_wave1_hub_foundation.md`

### `roadmap_trigger_granularity_ambiguity`

- first seen: 2026-03-09
- last seen: 2026-03-09
- repeat count: 1
- status: mitigated
- trigger source:
  - repeated complex feature programs mixed with smaller bounded tasks
- symptoms:
  - it was unclear when to use a full roadmap versus a lighter ExecPlan-only flow
  - roadmap planning risked becoming heavier than necessary for smaller work
- likely root cause:
  - the repo had strong roadmap-return mechanics, but no explicit adaptive trigger thresholds for when roadmap mode was actually required
- attempted fix history:
  - added a dedicated roadmap workflow that defines no-roadmap, ExecPlan-only, and roadmap-grade work
  - added validator coverage so routing docs keep the adaptive thresholds visible
- accepted fix:
  - keep adaptive roadmap trigger thresholds explicit: no roadmap for small isolated work, ExecPlan-only for bounded major work, and roadmap mode only for long-running multi-wave restart-sensitive work
- regressed after fix:
  - no
- affected workflows:
  - roadmap_governance
  - assistant_docs_sync
  - future_restart_handoff
- bootstrap relevance:
  - possible
- docs sync relevance:
  - required
- evidence refs:
  - `docs/assistant/workflows/ROADMAP_WORKFLOW.md`
  - `docs/assistant/exec_plans/PLANS.md`
  - `AGENTS.md`
  - `agent.md`

### `active_worktree_resume_authority_confusion`

- first seen: 2026-03-09
- last seen: 2026-03-09
- repeat count: 1
- status: mitigated
- trigger source:
  - fresh sessions resumed from the stable repo while active wave work lived in a separate worktree
- symptoms:
  - a fresh session in the stable repo could mislead a beginner about where the real in-progress roadmap state lived
  - `main` looked clean and complete while the active wave state was actually in a feature worktree
- likely root cause:
  - resume routing existed, but the docs did not state strongly enough that the active worktree is authoritative during in-flight wave work
- attempted fix history:
  - added an explicit active-worktree authority rule to the roadmap workflow, routing docs, and validator coverage
  - updated session-resume and roadmap docs to point back to the active worktree during live wave work
- accepted fix:
  - document and enforce that the active worktree's `SESSION_RESUME.md`, active roadmap tracker, and active wave ExecPlan are authoritative for live roadmap state while a wave is in progress
- regressed after fix:
  - no
- affected workflows:
  - future_restart_handoff
  - roadmap_governance
  - worktree_build_identity
- bootstrap relevance:
  - possible
- docs sync relevance:
  - required
- evidence refs:
  - `docs/assistant/workflows/ROADMAP_WORKFLOW.md`
  - `docs/assistant/SESSION_RESUME.md`
  - `docs/assistant/exec_plans/active/2026-03-09_my_quran_execution.md`
