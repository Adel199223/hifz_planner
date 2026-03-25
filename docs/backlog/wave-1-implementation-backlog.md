# Wave 1 Implementation Backlog

This file is for Codex or a developer.

The goal is to implement the first useful solo-learner version **without breaking the current app strengths**.

## Global rule

Preserve:
- reader
- audio pipeline
- local-first persistence
- existing companion/session ideas where reusable

Do not start by rewriting everything.

---

## Epic A — Make the new direction visible

### Task A1
Add the new strategy docs and roadmap to the repo.

**Done when:**
- docs are placed in suitable repo folders
- README and planning files point to them

### Task A2
Update top-level wording so the repo no longer reads like a generic planner/project shell.

**Done when:**
- a newcomer can understand the product direction from the repo entry points

---

## Epic B — Make Today the main Hifz Path entry

### Task B1
Change Today so it becomes the primary adaptive memorization dashboard.

**Done when:**
- the user sees a next-step experience, not just a static dashboard

### Task B2
Surface the companion/session engine directly from Today.

**Done when:**
- the main session can be started from one obvious button

### Task B3
If full route replacement is risky, keep the current route structure and deep-link into the companion flow.

**Done when:**
- implementation risk is reduced without losing product clarity

---

## Epic C — Create the daily queue model

### Task C1
Create a simple daily queue builder with these sections:
- warm-up
- due review
- weak spots
- optional new memorization

**Done when:**
- a queue can be generated locally for the current user state

### Task C2
Add operating modes:
- green
- protect
- recovery

**Done when:**
- the UI can show whether new memorization is allowed

### Task C3
Add queue prioritization:
1. same-day lock-in
2. recent review
3. weak spots
4. overdue review
5. new memorization if unlocked

**Done when:**
- the order is enforced consistently

---

## Epic D — Add simple per-unit memory fields

### Task D1
Extend the data model to support:
- mastery stage
- next due
- last grade
- weak-spot score
- last error type
- difficulty/stability placeholders

**Done when:**
- each memorization unit can move through a basic life cycle

### Task D2
Use migrations or safe adapters rather than destructive rewrites.

**Done when:**
- existing data and repo patterns are respected

---

## Epic E — Add solo-friendly grading

### Task E1
Add simple self-grading after attempts:
- clean pass
- hesitant pass
- prompted fail
- wrong/confused

**Done when:**
- the user can influence scheduling with low friction

### Task E2
Allow optional error tagging on lower grades.

**Done when:**
- weak spots can later be repaired intelligently

---

## Epic F — Add new-memorization unlock rules

### Task F1
Prevent new memorization when review debt is too high.

**Done when:**
- new is shown as locked when due pressure is above the threshold

### Task F2
Explain the lock clearly in the UI.

**Done when:**
- the user understands why new is paused

---

## Epic G — Add recovery mode

### Task G1
Trigger recovery mode after missed days or heavy backlog.

**Done when:**
- the app shifts to stabilization before new material

### Task G2
Use supportive messaging.

**Done when:**
- there is no shame-heavy copy

---

## Epic H — Accessibility defaults

### Task H1
Add easy controls for:
- text size
- spacing if supported
- contrast/theme
- default session size
- reduce motion
- audio-first behavior

**Done when:**
- these settings are actually reachable and persist

### Task H2
Reduce home-screen clutter.

**Done when:**
- the screen emphasizes one next action

---

## Epic I — Lightweight motivational layer

### Task I1
Add a meaningful streak that counts review/recovery work.

**Done when:**
- the streak rewards consistency, not only new memorization

### Task I2
Add simple milestones or missions.

Examples:
- clear all fragile reviews today
- repair 2 weak spots
- lock in today’s new ayat

**Done when:**
- the missions reinforce learning quality

---

## Epic J — Analytics and logging

### Task J1
Log:
- queue generated
- mode used
- grades selected
- new locked/unlocked
- recovery mode entered/exited

**Done when:**
- later tuning is possible

### Task J2
Keep logging lightweight and privacy-conscious.

---

## Suggested implementation order

1. docs + route surfacing
2. daily queue model
3. per-unit fields
4. self-grading
5. unlock rules
6. recovery mode
7. accessibility defaults
8. light motivation layer
9. analytics

---

## Important fallback rule

If a feature is hard to implement cleanly right now, prefer:
- a simpler version that keeps the product direction correct

over:
- a big rewrite that delays the useful experience

That rule matters a lot.
