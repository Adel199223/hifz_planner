# Adaptive Hifz Path — Solo Learner Roadmap

## Roadmap purpose

This roadmap is designed to keep development aligned with the actual goal:
**better Quran memorization and retention for solo learners.**

It is intentionally flexible.
Each wave ends with a decision point so Codex or a developer can adjust without losing direction.

## Development rule

When there is a conflict between:
- adding more features
- and protecting the clarity of the daily memorization path

always choose:
**clarity of the daily memorization path**

---

## Wave 0 — Product reset and alignment

### Goal
Align the repo documentation and product direction around the new core:
**Adaptive Hifz Path for solo learners**

### Deliverables
- new strategy docs added to repo
- active roadmap restored
- clear note that solo learner is the first target
- clear note that reader/audio stay as supporting strengths
- updated README summary
- updated app knowledge / session resume notes

### Acceptance criteria
- the repo no longer looks directionless
- the active roadmap is visible and current
- anyone entering the repo can understand the new goal quickly

### If blocked
If there is an established repo docs convention, preserve the convention and adapt paths instead of forcing new folders.

---

## Wave 1 — Guided daily path MVP

### Goal
Create the first version of the daily memorization flow.

### Deliverables
- Today becomes the main Hifz Path entry
- a daily queue with:
  - warm-up
  - due review
  - weak spots
  - optional new memorization
- manual self-grading after each attempt
- new memorization locked behind simple review-health rules
- simple progress and streak display
- recovery mode for missed days

### Acceptance criteria
- a solo learner can open the app and start a useful session immediately
- there is one obvious next step
- the user does not have to manually assemble a plan every day
- missed days do not create a “game over” feeling

### If blocked
If the current route structure is hard to rewrite, keep existing routes but deep-link the user into the Hifz Path from Today.

---

## Wave 2 — Adaptive scheduler core

### Goal
Upgrade the logic from static planning into a real memory engine.

### Deliverables
- per-unit mastery state
- due dates based on performance
- review debt calculation
- confidence-aware grading
- weak-spot resurfacing
- retention presets:
  - gentle
  - balanced
  - strong

### Acceptance criteria
- easy passes extend intervals
- hesitant passes extend less
- failures shorten intervals
- repeated failures surface in repair mode
- new material slows or pauses when debt is too high

### If blocked
If a full advanced algorithm is too heavy, start with a rules-based scheduler that stores the right fields for later calibration.

---

## Wave 3 — Weak spots and mutashabihat

### Goal
Handle the kinds of failures that ordinary spaced repetition misses.

### Deliverables
- weak-spot queue
- error typing:
  - omission
  - hesitation
  - wrong continuation
  - wording error
  - tajweed issue
  - similar-verse confusion
- simple similar-verse drills
- user flagging for confusing ayat or transitions

### Acceptance criteria
- repeated trouble spots are not buried in the generic due queue
- similar-verse confusion gets its own repair flow
- the learner can see why something is resurfacing

### If blocked
Allow manual flagging first.
Automatic similarity detection can come later.

---

## Wave 4 — Accessibility and motivational polish

### Goal
Make the app easier to sustain for ADHD/dyslexia users and more motivating without becoming noisy.

### Deliverables
- shorter default session sizes
- focus mode
- reduced clutter
- adjustable spacing and text density
- supportive language
- non-shaming streak recovery
- lightweight missions, sections, and milestones

### Acceptance criteria
- the default experience feels calm and guided
- text-heavy clutter is reduced
- the learner can recover after interruptions
- rewards do not overshadow memorization quality

### If blocked
Prioritize:
1. session chunking
2. one-next-step flow
3. spacing/text controls
4. shame-free recovery

---

## Wave 5 — Solo enhancement layer

### Goal
Strengthen the self-study experience without making the system depend on a teacher.

### Deliverables
- better audio-first flows
- self-note system for weak links
- optional AI-assisted recitation feedback where reliable
- fluency / tasmi’ sessions
- reflective summaries like:
  - “you are strong in recent review”
  - “your weak area is transitions in this surah”

### Acceptance criteria
- the app becomes a real standalone companion
- solo learners can self-correct better
- fluency is measured separately from basic recall

### If blocked
Keep manual self-grading as the source of truth.
AI scoring should support the learner, not replace core scheduling.

---

## Wave 6 — Teacher mode later

### Goal
Prepare for future teacher-linked workflows without letting them distort the solo-first build.

### Deliverables
- teacher-linked assignments
- approval overrides
- student summaries
- optional parent/teacher monitoring

### Rule
Do not let teacher-mode needs dominate the solo-first architecture.

---

## Anchor points and decision gates

At the end of every wave, stop and ask:

### Gate A — Is the product getting clearer?
If no, simplify the flow before adding more features.

### Gate B — Is the memory engine protecting retention?
If no, improve queue logic before adding more gamification.

### Gate C — Is the app friendlier to overwhelmed users?
If no, reduce branching and screen density.

### Gate D — Are we preserving the existing strengths?
If no, stop replacing mature systems that should be reused.

---

## Priority order if resources are limited

If time or engineering capacity becomes tight, keep this order:

1. guided daily path
2. adaptive review scheduling
3. review debt and recovery mode
4. weak-spot repair
5. accessibility defaults
6. mutashabihat drills
7. gamification polish
8. teacher mode

---

## What should not happen

Do **not** let the roadmap drift into:
- only adding charts and dashboards
- only beautifying the reader
- only adding badges and rewards
- building teacher systems first
- making the main flow depend on advanced AI
- overcomplicating the product before the daily path works

---

## Definition of success for the roadmap

The roadmap is working if, after Waves 1 and 2, the app already feels like this:

> “I open it, it tells me what to do, it protects what I memorized, and it helps me keep going even when life interrupts me.”
