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

No issue-memory entries recorded yet.
