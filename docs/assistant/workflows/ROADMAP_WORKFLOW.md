# Roadmap Workflow

## What This Workflow Is For

Use this workflow for long-running, multi-wave product or architecture programs that need restart-safe sequencing, flexible resequencing, explicit detour handling, and staged closeout.

## Expected Outputs

- The repo uses one consistent roadmap/master-plan system instead of ad-hoc multi-wave planning.
- Fresh sessions can resume from one stable anchor file.
- The active worktree, active roadmap tracker, and active wave ExecPlan stay aligned.
- Completed roadmap trackers and finished ExecPlans do not stay stranded in `docs/assistant/exec_plans/active/`.
- Future stages or waves can be restructured when new discoveries force a better sequence.
- Small tasks do not pay roadmap overhead.

## When To Use

Use no roadmap when work is:
- small isolated work
- a single-file fix
- a narrow bug fix
- a small UI text tweak

Use ExecPlan-only when work is:
- multi-file but still one-merge work
- a bounded refactor
- a single feature addition without likely detours

Use a roadmap or master plan when work is likely to need:
- multiple waves or PRs
- fresh-session resume support
- detours and return-to-sequence handling
- worktree isolation
- cross-surface product coordination

Stages are optional research/spec/design phases.
Waves are implementation slices.
Some projects may use waves only, while others may use stages first and then waves.

If the user explicitly asks for a roadmap or master plan, use one even if a lighter flow might have been possible.

## What Not To Do

- Do not treat roadmap mode as the default for every small task.
- Do not start a multi-wave stream without an active roadmap tracker and `docs/assistant/SESSION_RESUME.md`.
- Do not treat `main` as the authoritative live roadmap source while a wave is active in a separate worktree.
- Do not use issue memory as a substitute for roadmap history.
- Do not let detours skip the roadmap update order.
- Do not collapse wave-specific implementation detail into `docs/assistant/SESSION_RESUME.md`; keep that file summary-level only.
- Do not leave completed roadmap trackers or finished ExecPlans parked in `docs/assistant/exec_plans/active/` when no roadmap is live.
- Don't use this workflow when a small isolated change or one-merge bounded task can stay lighter. Instead use ExecPlan-only planning or `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`, whichever fits the safer smaller mode.

## Primary Files

- `docs/assistant/SESSION_RESUME.md`
- `docs/assistant/exec_plans/PLANS.md`
- active roadmap tracker in `docs/assistant/exec_plans/active/`
- active wave ExecPlan in `docs/assistant/exec_plans/active/`
- `docs/assistant/ISSUE_MEMORY.md`
- `docs/assistant/ISSUE_MEMORY.json`
- `docs/assistant/manifest.json`
- `AGENTS.md`
- `agent.md`

## Minimal Commands

```powershell
git worktree list
git status --short --branch
dart run tooling/validate_agent_docs.dart
```

## Targeted Tests

```powershell
flutter test --no-pub -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: it is unclear whether to use a roadmap or a lighter plan.
   - Apply the adaptive trigger policy:
     - small isolated work -> no roadmap
     - bounded major change -> ExecPlan only
     - multi-wave/restart-sensitive program -> roadmap
2. Symptoms: a fresh session opens the stable repo and misses active wave state.
   - Open the roadmap anchor file `docs/assistant/SESSION_RESUME.md` first, then the linked active roadmap tracker, then the linked active wave ExecPlan.
3. Symptoms: roadmap state drifts after a detour.
   - Update:
     1. active wave ExecPlan
     2. active roadmap tracker
     3. `docs/assistant/SESSION_RESUME.md`
4. Symptoms: new discoveries or blockers force a different future order.
   - Resequence future stages or waves in the active roadmap tracker, then surface the resulting exact next step back through `docs/assistant/SESSION_RESUME.md`.
5. Symptoms: roadmap history becomes mixed with repeatable workflow failures.
   - Keep normal roadmap history in the active tracker and wave ExecPlans; use issue memory only for reusable governance or operational issue classes.
6. Symptoms: the roadmap process becomes too heavy for simple work.
   - Drop back to ExecPlan-only or no-roadmap flow unless the user explicitly wants roadmap mode.
7. Symptoms: the roadmap is complete but `SESSION_RESUME.md` still points into `active/`.
   - Archive the completed roadmap tracker and any finished ExecPlans to `docs/assistant/exec_plans/completed/`, then point `docs/assistant/SESSION_RESUME.md` to the latest completed roadmap tracker and relevant completed closeout plan.

## Handoff Checklist

- the task classification is explicit:
  - no roadmap
  - ExecPlan-only
  - roadmap/master plan
- `docs/assistant/SESSION_RESUME.md` is still the roadmap anchor file and stable first fresh-session stop
- the active roadmap tracker still carries current stage/wave, exact next step, blockers, detours, and any sequence revisions
- the active worktree is explicitly treated as authoritative during in-flight wave work
- if a wave is active in a separate worktree, that active worktree is the live roadmap source
- if no roadmap is active, `docs/assistant/SESSION_RESUME.md` points to completed roadmap history and `docs/assistant/exec_plans/active/` contains only genuinely live plans
- the update order is preserved:
  1. active wave ExecPlan
  2. active roadmap tracker
  3. `docs/assistant/SESSION_RESUME.md`
- issue memory contains only repeatable governance or workflow failures
- the roadmap still points to one exact next step
