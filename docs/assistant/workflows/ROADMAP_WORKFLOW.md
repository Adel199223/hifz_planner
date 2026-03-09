# Roadmap Workflow

## What This Workflow Is For

Use this workflow for long-running, multi-wave product or architecture programs that need restart-safe sequencing, explicit detour handling, and staged closeout.

## Expected Outputs

- The repo uses one consistent roadmap system instead of ad-hoc multi-wave planning.
- Fresh sessions can resume from one stable entrypoint.
- The active worktree, active roadmap tracker, and active wave ExecPlan stay aligned.
- Small tasks do not pay roadmap overhead.

## When To Use

Use a roadmap when work is likely to need:
- multiple waves or PRs
- fresh-session resume support
- detours and return-to-sequence handling
- worktree isolation
- cross-surface product coordination

Use ExecPlan-only when work is:
- multi-file but still one-merge work
- a bounded refactor
- a single feature addition without likely detours

Do not open a roadmap for:
- single-file fixes
- narrow bug fixes
- small UI text tweaks
- one-shot docs cleanup

If the user explicitly asks for a roadmap or master plan, use one even if the work could have been handled more lightly.

Use no roadmap for small isolated work when the safer lighter flow is enough.

## What Not To Do

- Do not treat roadmap mode as the default for every small task.
- Do not start a multi-wave stream without an active roadmap tracker and `SESSION_RESUME.md`.
- Do not treat `main` as the authoritative live roadmap source while a wave is active in a separate worktree.
- Do not use issue memory as a substitute for roadmap history.
- Do not let detours skip the roadmap update order.
- Do not collapse wave-specific implementation detail into `SESSION_RESUME.md`; keep that file summary-level only.
- Don't use this workflow when a small isolated change or a one-merge bounded task can stay lighter. Instead use ExecPlan-only planning or `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`, whichever fits the safer smaller mode.

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
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: it is unclear whether to use a roadmap or a lighter plan.
   - Apply the adaptive trigger policy:
     - small change -> no roadmap
     - bounded major change -> ExecPlan only
     - multi-wave/restart-sensitive program -> roadmap
2. Symptoms: a fresh session opens the stable repo and misses active wave state.
   - Open `docs/assistant/SESSION_RESUME.md` first, then the linked active roadmap tracker, then the linked active wave ExecPlan.
3. Symptoms: roadmap state drifts after a detour.
   - Update:
     1. active wave ExecPlan
     2. active roadmap tracker
     3. `docs/assistant/SESSION_RESUME.md`
4. Symptoms: roadmap history becomes mixed with repeatable workflow failures.
   - Keep normal roadmap history in the active tracker and wave ExecPlans; use issue memory only for reusable governance or operational issue classes.
5. Symptoms: the roadmap process becomes too heavy for simple work.
   - Drop back to ExecPlan-only or no-roadmap flow unless the user explicitly wants roadmap mode.

## Handoff Checklist

- the task classification is explicit:
  - no roadmap
  - ExecPlan-only
  - roadmap
- `SESSION_RESUME.md` is still the stable first fresh-session stop
- the active worktree is explicitly treated as authoritative during in-flight wave work
- if a wave is active in a separate worktree, that active worktree is the live roadmap source
- the update order is preserved:
  1. active wave ExecPlan
  2. active roadmap tracker
  3. `SESSION_RESUME.md`
- issue memory contains only repeatable governance or workflow failures
- the roadmap still points to one exact next step
