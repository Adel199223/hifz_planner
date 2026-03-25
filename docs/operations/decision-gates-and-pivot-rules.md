# Decision Gates and Pivot Rules

This file exists so the roadmap can stay flexible without drifting.

## Main rule

When the codebase or implementation reality pushes back, do **not** abandon the product direction.
Instead, reduce complexity while preserving the core direction.

---

## 1. What must stay stable

These should remain stable unless there is a very strong reason otherwise:

- solo learner first
- daily path as product center
- reader preserved as support system
- audio preserved as strength
- review debt controls new memorization
- weak spots are surfaced
- accessibility affects defaults

---

## 2. What may flex

These can flex if implementation friction is high:

- exact folder names
- exact route names
- exact interval values
- whether the first queue uses ayah or chunk units
- whether similar-verse detection is manual first
- how much gamification appears in Wave 1

---

## 3. If the route structure is hard to change

Fallback:
- keep the current internal route structure
- make Today the launcher and organizer of the Hifz Path
- deep-link into existing companion flow instead of rewriting routes early

---

## 4. If the current data model is complex

Fallback:
- add adapter fields
- add small new tables if necessary
- do not replace stable tables early without clear need

---

## 5. If automatic scoring is unreliable

Fallback:
- manual self-grade remains authoritative
- AI feedback becomes advisory only

This is especially important for solo mode.

---

## 6. If mutashabihat automation is too hard

Fallback:
- allow manual confusion flags
- add a simple compare-two-passages drill
- postpone full automatic similarity detection

---

## 7. If the home screen gets crowded again

Stop and simplify.

Ask:
- What is the one next action?
- What can be demoted?
- What belongs in settings or secondary screens?

If the answer is unclear, the UX is regressing.

---

## 8. If the team wants to add more gamification early

Check this first:
- Is the queue already protecting retention?
- Is recovery mode already working?
- Are weak spots already visible?

If no, postpone the extra gamification.

---

## 9. If implementation time is limited

Minimum acceptable sequence:

1. next-step daily flow
2. due review + new unlock rules
3. recovery mode
4. weak spots
5. accessibility defaults

Everything else can come later.

---

## 10. End-of-wave review questions

At the end of each wave, answer:

1. Does the app now feel more like a daily companion?
2. Is the learner more protected from false forward progress?
3. Is the solo learner more likely to continue after a bad week?
4. Is the UX calmer and clearer?
5. Did we preserve existing reader/audio strengths?

If most answers are no, do not advance to flashy features.

---

## 11. Summary

This roadmap should bend where needed, but not break.

What can bend:
- implementation shape

What must not break:
- product truth
