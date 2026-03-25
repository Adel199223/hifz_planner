# Adaptive Hifz Scheduler V1

## Purpose

This file defines a practical first scheduler for the solo learner.
It is intentionally simpler than a full ML system, but it stores the right ideas so it can improve later.

The main idea:
**V1 should be smart enough to protect retention without becoming a fragile black box.**

---

## 1. Design goals

The scheduler must:

1. protect older memorization from silent decay
2. avoid overwhelming the learner
3. adapt to success, hesitation, and failure
4. create recovery mode after missed days
5. surface weak spots separately from generic due review
6. allow later migration to a stronger adaptive model

---

## 2. What is being scheduled

The scheduler works on a generic **memorization unit**.

A memorization unit can represent:
- an ayah
- a short chunk
- a small passage
- a page/ruku for mature maintenance

---

## 3. Suggested data fields per unit

Each unit should store at least:

- `unitId`
- `unitType`
- `surahNumber`
- `ayahStart`
- `ayahEnd`
- `masteryStage`
- `difficultyScore`
- `stabilityScore`
- `retrievabilityEstimate`
- `lastReviewedAt`
- `nextDueAt`
- `lastGrade`
- `consecutiveSuccesses`
- `lapseCount`
- `hesitationCount`
- `similarVerseFlags`
- `weakSpotScore`
- `lastErrorType`
- `confidenceTrend`
- `bucket` (new / lock-in / recent / old / weak / similar / fluency)
- `notes`

If the repo already has related companion tables, extend those structures rather than replacing them without reason.

---

## 4. Simple grade scale for solo learners

The grading model must stay simple enough for real daily use.

Recommended first scale:

### Grade 3 — Clean pass
- recalled correctly
- no major hesitation
- no prompt needed

### Grade 2 — Hesitant pass
- mostly correct
- some pause or uncertainty
- maybe needed a small cue

### Grade 1 — Hard fail / prompted
- recall broke down
- needed visible text or strong cue

### Grade 0 — Wrong / confusion
- wrong continuation
- wrong wording cluster
- similar-verse confusion
- major breakdown

Optional:
store a separate `errorType` when grade is 0 or 1.

---

## 5. Stage-sensitive interval logic

### For new material
Use tighter early intervals.

Suggested starter pattern:
- after first pass: `+10 min`
- next same-day pass: `+1 hr`
- next same-day/evening pass: `+8 hr`
- next pass: `+1 day`

### For recent review
As the unit stabilizes:
- `+2 days`
- `+4 days`
- `+7 days`

### For mature review
After enough clean passes:
- `+14 days`
- `+30 days`
- `+45 days`
- `+75 days`
- then adaptive growth based on performance

These are starter intervals.
The exact values can be tuned later.

---

## 6. How grades affect the next interval

### Clean pass
- increase stability
- decrease difficulty slightly
- grow interval normally or strongly

### Hesitant pass
- increase stability only a little
- keep or slightly raise difficulty
- grow interval modestly
- possibly keep in fragile/recent bucket a bit longer

### Prompted fail
- reduce stability
- shorten interval sharply
- add weak-spot weight
- send to repair if repeated

### Wrong/confused fail
- reduce stability more
- shorten interval sharply
- tag error type
- if similar-verse confusion is involved, add to similar-verse queue

---

## 7. Review debt rules

The scheduler must track total review pressure, not only item state.

Recommended measures:
- overdue item count
- estimated overdue minutes
- recent failure density
- weak-spot count
- missed-day count

### Suggested operating modes

#### Green mode
- review debt is healthy
- new memorization allowed

#### Protect mode
- some debt or shaky recent accuracy
- new memorization reduced

#### Recovery mode
- serious backlog or repeated instability
- no new memorization until stability improves

---

## 8. Suggested unlock rule for new memorization

New memorization is unlocked only if all of these are true:

- due review minutes are below a chosen threshold
- recent review accuracy is above a chosen threshold
- weak-spot overload is not present
- missed-day recovery is not active

Simple starter thresholds:
- due minutes below 20
- recent accuracy at least 75%
- weak-spot queue below 5 active items
- not in explicit recovery mode

These numbers should be configurable later.

---

## 9. Weak-spot rules

A unit should go to the weak-spot queue if any of these happen:

- 2 fails within 7 days
- 3 hesitant passes without maturing
- repeated wrong continuation
- repeated self-reported uncertainty
- high confusion with neighboring/similar verses

Weak-spot queue behavior:
- surfaces before ordinary new memorization
- uses smaller intervals
- uses more targeted drill types

---

## 10. Similar-verse rules

A unit should enter the similar-verse queue if:

- the learner marks it confusing
- a wrong continuation points to another known similar passage
- repeated errors suggest confusion between known parallels

V1 can start simple:
- manual flags
- curated comparison sets
- pairwise drills

V2 can add automatic candidate generation using text similarity.

---

## 11. Recovery mode

Recovery mode is one of the most important solo-learning features.

### Trigger examples
- missed 3 or more days
- overdue workload above threshold
- major recent-failure cluster

### Recovery behavior
- pause new memorization
- prioritize:
  1. fragile recent units
  2. weak spots
  3. overdue old review
- shorten sessions
- use encouraging language
- avoid shame messaging

### Exit condition
Exit recovery mode only when:
- overdue debt drops below threshold
- recent accuracy improves
- weak-spot pressure decreases

---

## 12. Session generator priority order

Recommended priority when building the daily queue:

1. same-day lock-in due now
2. fragile recent review
3. weak spots
4. overdue old review
5. similar-verse repair
6. new memorization if unlocked
7. optional fluency block

This keeps the product honest.

---

## 13. Suggested pseudocode

```text
buildDailyPlan(user, availableMinutes):
    mode = determineMode(user)

    queue = []

    queue += dueSameDayLockIns()
    queue += fragileRecentReviews()
    queue += weakSpotRepairs()
    queue += overdueOldReviews()

    if hasSimilarVersePressure():
        queue += similarVerseRepairs()

    if mode.allowsNew:
        queue += newMemorizationBlock()

    queue = trimToSessionBudget(queue, availableMinutes)

    return queue
```

```text
determineMode(user):
    if overdueMinutes > HARD_CAP:
        return RECOVERY
    if recentAccuracy < ACCURACY_FLOOR:
        return PROTECT
    if weakSpotCount >= WEAK_SPOT_CAP:
        return PROTECT
    return GREEN
```

---

## 14. Retention presets

Offer three learner-facing presets later:

### Gentle
- lower workload
- slower new progression
- more forgiving

### Balanced
- default
- healthy mix of growth and protection

### Strong
- higher review workload
- stricter retention target
- for serious/intensive memorizers

Do not expose too many advanced controls at first.

---

## 15. What to measure

The system should log enough data to answer:

- what proportion of due items were completed
- which grade distribution is most common
- how often new memorization gets paused
- whether recovery mode helps users return
- which error types dominate
- where weak spots cluster

These measurements will be important for future tuning.

---

## 16. V1 implementation advice

Do not start with a machine-learned scheduler.
Start with:
- transparent rules
- the right data fields
- good logging
- clear user states

That is the fastest path to a reliable first adaptive system.

---

## 17. Final algorithm summary

V1 should be:
- stage-aware
- debt-aware
- confidence-aware
- weak-spot-aware
- mutashabihat-aware
- simple enough to trust
- flexible enough to improve later
