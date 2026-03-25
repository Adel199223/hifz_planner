# Quran Memory Model for the Solo Learner

## Purpose

This file defines how the app should think about Quran memorization.
It is the domain model behind the product and algorithm.

The biggest rule:
**“memorized” is not one flat state.**

A learner can know something in one context and fail it in another.
The app must track stages, not just yes/no completion.

---

## 1. The three traditional foundations

The strongest practical foundation is:

- **Sabaq** — new memorization
- **Sabqi** — recent review
- **Manzil / Daur** — old review / long-term revision

These are not old-fashioned leftovers.
They are a very strong structure for a digital memory engine.

---

## 2. The six live buckets in the app

The product should run daily using six buckets:

1. **New**
2. **Today Lock-In**
3. **Recent Review**
4. **Old Review**
5. **Weak Spots**
6. **Similar Verses**

A seventh bucket becomes important later:

7. **Fluency / Tasmi’**

---

## 3. Recommended mastery stages

Each memorization unit should move through stages like this:

### Stage 0 — Exposure
The learner has listened, read, or previewed it.

### Stage 1 — Echo
The learner can repeat with support.

### Stage 2 — Cued Recall
The learner can recall with a small prompt.

### Stage 3 — Free Recall
The learner can recite from memory without visible text.

### Stage 4 — Same-Day Stability
The learner has passed same-day repetitions.

### Stage 5 — Recent Retention
The learner can recall it after delayed review over the next days.

### Stage 6 — Mature Retention
The learner can hold it over longer intervals.

### Stage 7 — Strong / Mutqin
The learner is strong enough for bigger fluency or maintenance sessions.

Important:
A unit can be strong in ordinary recall but still weak in transitions or similar-verse discrimination.
That is why separate weak-spot and mutashabihat signals matter.

---

## 4. Recommended unit hierarchy

The app should not force the same unit size at every stage.

### Acquisition unit
- ayah
- or short phrase / chunk

### Consolidation unit
- small passage
- 2–5 ayat
- or a line-based chunk

### Maintenance unit
- page
- half page
- ruku’
- or another larger stable review unit

This allows the app to be fine-grained early and efficient later.

---

## 5. What counts as a “memory event”

The system should record events like:

- listened with attention
- echoed after audio
- recited with prompt
- recited independently
- passed with hesitation
- failed recall
- confused with similar verse
- broke on transition
- fluency passed
- fluency failed

This helps the system understand not just that practice happened, but **what kind of practice happened**.

---

## 6. Error taxonomy

Every failed or imperfect attempt should be typed where possible.

Recommended first taxonomy:

- **omission** — something was left out
- **hesitation** — long pause or uncertainty
- **wrong continuation** — correct start, wrong next line/ayah
- **wording slip** — wording mix-up not mainly tajweed
- **tajweed / pronunciation issue**
- **similar-verse confusion**
- **position / transition confusion**
- **self-reported uncertainty**

Not every session needs perfect labeling.
But the taxonomy should exist from the start.

---

## 7. Similar verses (mutashabihat)

Mutashabihat should be first-class.

The app should allow:
- manual flagging of confusion pairs
- storing verse-to-verse confusion links
- drills that compare two similar passages
- emphasis on distinguishing words or transitions
- resurfacing of confusion pairs faster than ordinary review

This is a major differentiator.

---

## 8. What “done” means for a new memorization unit

A unit is **not** done because the learner passed it once.

A new unit is only truly “secure enough to move on” when:

1. it was encoded
2. it passed same-day lock-in
3. it survived delayed review
4. it did not immediately collapse under recent-review pressure

This is why the app must protect against false forward progress.

---

## 9. Solo-learner interpretation of tasmi’

For the solo learner, tasmi’ has to be partially simulated.

That means the app should support:
- uninterrupted recitation checks
- self-grading
- optional recording and playback
- optional AI feedback if reliable
- stronger distinction between:
  - clean recitation
  - hesitant but acceptable recitation
  - inaccurate recitation

In solo mode, self-grading remains necessary even if AI exists.

---

## 10. Meaning, audio, and page-location anchors

The app should support multiple memory anchors:

### Audio anchor
Listening to a reciter before recall.

### Meaning anchor
Simple thematic or meaning cue to strengthen retrieval.

### Visual anchor
Digital mushaf layout and page/line memory.

### Transition anchor
Knowing what comes before and after.

These anchors should support memorization, not distract from it.

---

## 11. Solo-first interpretation of progress

Progress should be shown in at least four ways:

1. **Coverage** — how much has been learned
2. **Stability** — how much is still strong
3. **Debt** — how much overdue review exists
4. **Weaknesses** — where confusion is concentrated

This is more honest than showing only total pages or total ayat memorized.

---

## 12. Full-Quran-first assumption

The first strong rebuild should optimize for a learner who wants a long journey, including full Quran memorization.

That does **not** prevent selected surah workflows later.
But the model should be able to scale to full-Quran retention from the beginning.

This affects:
- review debt design
- maintenance logic
- section progression
- long-term motivation

---

## 13. Recommended product language

Prefer terms like:

- Today’s Path
- New
- Review
- Weak Spots
- Similar Verses
- Fluency
- Recovery Mode
- Stable
- Due
- Strong
- Fragile

Avoid making the user think only in:
- done / not done
- complete / incomplete
- success / failure

The memory journey is more layered than that.

---

## 14. Final domain summary

The domain model should treat Quran memorization as:
- continuous
- staged
- error-sensitive
- review-heavy
- vulnerable to similar-verse confusion
- best supported by a daily adaptive path

That is the memory reality the app must be built around.
