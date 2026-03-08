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

### `flutter_parallel_test_plugin_symlink_race`

- first seen: 2026-03-08
- last seen: 2026-03-08
- repeat count: 2
- status: mitigated
- trigger source:
  - local Flutter validation in isolated worktrees
- symptoms:
  - parallel `flutter test` runs in one worktree can break plugin-symlink state and make the validation result noisy or untrustworthy
- likely root cause:
  - concurrent Flutter test processes racing shared ephemeral/plugin-symlink state inside one worktree
- attempted fix history:
  - Wave 1: reran the same validation set sequentially after the parallel run failed noisily
  - Wave 2: kept Flutter validation sequential from the start
- accepted fix:
  - run Flutter test commands sequentially per worktree
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

### `fresh_worktree_flutter_validation_lockfile_churn`

- first seen: 2026-03-08
- last seen: 2026-03-08
- repeat count: 1
- status: mitigated
- trigger source:
  - first Flutter validation in a fresh isolated worktree
- symptoms:
  - the first validation run can resolve dependencies and touch `pubspec.lock` even when the feature work is not changing dependencies
- likely root cause:
  - lazy dependency/bootstrap work happening on the first Flutter command in a new worktree
- attempted fix history:
  - Wave 2: allowed the initial validation bootstrap to complete, then manually reverted incidental `pubspec.lock` churn before closeout
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
