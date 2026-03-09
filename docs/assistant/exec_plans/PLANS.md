# ExecPlan Playbook

Use ExecPlans for major or multi-file features/refactors.

## Trigger Rule

Create an ExecPlan when work is any of the following:
- multi-file feature implementation
- schema/migration-affecting change
- major workflow/process refactor
- high-risk behavior change spanning multiple modules

ExecPlans are optional for small, isolated fixes.

## Location and Lifecycle

- Active plans: `docs/assistant/exec_plans/active/`
- Completed plans: `docs/assistant/exec_plans/completed/`

When starting major work:
1. Create a new file under `active/` with a stable name: `YYYY-MM-DD_<scope>.md`.
2. Keep the plan self-contained so execution can restart from the plan alone.
3. Update Progress and Decision Log as work proceeds.
4. Move the finished plan to `completed/`.

## Required ExecPlan Structure

Each plan must include these headings:

1. `# ExecPlan: <title>`
2. `## Purpose`
3. `## Scope`
4. `## Assumptions`
5. `## Milestones`
6. `## Detailed Steps`
7. `## Decision Log`
8. `## Validation`
9. `## Progress`
10. `## Surprises and Adjustments`
11. `## Handoff`

## Template

```md
# ExecPlan: <Title>

## Purpose
- Why this work matters.

## Scope
- In scope:
- Out of scope:

## Assumptions
- Assumption 1
- Assumption 2

## Milestones
1. Milestone one
2. Milestone two

## Detailed Steps
1. Step and exact files/commands.
2. Step and exact files/commands.

## Decision Log
- YYYY-MM-DD: decision + rationale.

## Validation
- Commands/tests proving completion.

## Progress
- [ ] Milestone one
- [ ] Milestone two

## Surprises and Adjustments
- Capture unexpected findings and plan updates.

## Handoff
- Final state summary and follow-up risks.
```

## Quality Rules

- Keep commands PowerShell-compatible.
- Include exact test/validator commands.
- Do not rely on unstated context.
- Keep reasoning and rollback path explicit.

## Roadmap Return Protocol

For roadmap-driven work, every ExecPlan must support returning to the main sequence after detours.

Required rule:
1. After a detour for bugfixes, tooling, docs, or environment, update the active wave ExecPlan first.
2. Update the active roadmap tracker second.
3. Update `docs/assistant/SESSION_RESUME.md` third.
4. Resume from `docs/assistant/SESSION_RESUME.md` unless the active roadmap tracker explicitly records a new sequence.
5. Every roadmap closeout must state:
   - current roadmap status
   - exact next step by wave or stage name
6. When research stages are already done, say exactly:
   - `All research stages are complete; implementation continues by wave.`
7. Every roadmap closeout message must end with one explicit line in this shape:
   - `Next step: Wave X - <name>`
8. If the next action is closeout instead of a new wave, end with:
   - `Next step: close Wave X with <closeout action>`
