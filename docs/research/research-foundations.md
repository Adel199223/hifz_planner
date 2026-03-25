# Research Foundations for the Solo Learner Rebuild

This file summarizes the strongest research ideas behind the rebuild direction.

It is written for product and implementation guidance, not for academic perfection.
Where evidence is strong, it should influence architecture and UX directly.
Where evidence is weaker or mixed, it should influence experimentation, not become a rigid rule.

---

## 1. The strongest general learning-science findings

### Retrieval practice matters
The learner should repeatedly **recall** from memory, not mostly reread or re-listen passively.

Product consequence:
- session design should center recall
- review should ask the learner to produce, continue, or recite from memory
- listening alone is helpful, but not enough

### Distributed practice matters
Study and review spread over time beats massed repetition.

Product consequence:
- daily review timing matters
- the app should schedule reviews at increasing intervals
- same-day lock-in is still important, but cannot replace later review

### Interleaving is helpful, but not everywhere
Interleaving is useful for discrimination tasks, but not always ideal during first encoding.

Product consequence:
- early memorization can stay focused and scaffolded
- similar-verse drills are a good place for discrimination and contrast practice

---

## 2. What Duolingo contributes

Duolingo’s useful lessons are not “cartoon mascots” or superficial rewards.
Its strongest transferable ideas are:

- one guided path
- one obvious next step
- layered mastery
- review built into the journey
- visible momentum
- transparent difficulty
- practice that resurfaces older material

Duolingo’s published work and public materials also support:
- review exercises as a way to measure retention
- higher mastery levels improving later recall
- adaptive difficulty and progression
- trainable spaced-repetition models outperforming simpler baselines

Product consequence:
- borrow the guided path and mastery logic
- do not copy language-course structure literally

---

## 3. What spaced-repetition systems contribute

Spaced-repetition systems show that review timing is not a cosmetic feature.
It is the memory engine.

Important ideas to carry over:
- items differ in difficulty
- confidence matters
- success and hesitation should not be treated the same
- there is a tradeoff between workload and retention target
- the system should store enough data to improve later

Product consequence:
- the app must track per-unit memory state
- it must slow down new material when review health is poor
- it should start simple, but store the right fields from day one

---

## 4. What Quran memorization research contributes

Across the hifz literature, several themes repeat:

### Muraja’ah is foundational
Revision is not a side activity.
It is the mechanism that keeps memorization alive.

### The sabaq / sabqi / manzil structure is highly practical
Traditional new/recent/old review structure maps very well to modern memory science.

### Mutashabihat are a major challenge
Similar verses create confusion that needs dedicated training.
A generic review queue is not enough.

### Tasmi’ and correction matter
Recitation assessment and correction remain important, even when the learner studies alone.

Product consequence:
- new memorization, recent review, old review, and similar-verse training should be separate buckets
- weak spots must be explicitly surfaced
- the system should later support fluency/tasmi’ as a distinct mode

---

## 5. What current digital Quran-memorization tools suggest

Recent app and literature reviews suggest:
- many apps track memorization and revision
- many apps include audio, progress tracking, and simple quizzes
- some use spaced repetition or continuation games
- dedicated mutashabihat and revision apps exist
- the category is increasingly active

Product consequence:
The opportunity is **not** just to add another tracker.
The opportunity is to integrate:
- guided daily flow
- real adaptive review
- Quran-native structure
- weak-spot repair
- accessibility
- long-term maintenance

---

## 6. Why the first version should optimize for solo learners

A solo learner lacks daily external structure.
That means the app must compensate for:

- decision fatigue
- uncertainty about what to review
- overconfidence in new memorization
- guilt after missed days
- lack of immediate correction
- inconsistency due to life interruptions

Product consequence:
- the app must be more than a planner
- it must actively guide, protect, and recover the learner

---

## 7. ADHD implications

Evidence-backed ADHD supports repeatedly point toward:
- positive reinforcement
- clear expectations
- immediate feedback
- reduced distraction
- shorter tasks
- breaks or movement
- technology that helps organization and consistency

Product consequence:
- default sessions should be short
- the home screen should stay simple
- progress feedback should be quick and supportive
- reminders should be routine-friendly
- backlog should be rescued, not used as punishment

---

## 8. Dyslexia implications

Dyslexia research does not support a single magical font solution.
What tends to matter more is presentation flexibility and reduction of visual strain.

Relevant implications:
- crowding and distractors can hurt performance
- extra spacing can help some readers
- customization is safer than forcing one style
- Arabic reading adds additional visual complexity because of script features and diacritics

Product consequence:
- adjustable spacing should matter
- dense UI should be avoided
- audio-first flows should be easy
- synchronized highlighting and clean chunking are important

---

## 9. Gamification implications

Gamification can help.
But the evidence is mixed enough that it should be treated as a support layer, not the main engine.

Most defensible interpretation:
- small positive effects are common
- motivational gains can help
- the effects are not guaranteed
- novelty can wear off
- badly chosen game mechanics can create noise or shallow behavior

Product consequence:
- keep rewards lightweight
- reward retention, consistency, and repair
- do not let points replace mastery logic

---

## 10. Product conclusion from the research

The most defensible rebuild direction is:

**guided path + adaptive spacing + sabaq/sabqi/manzil + weak-spot repair + mutashabihat support + ADHD/dyslexia-friendly defaults**

That is the best scientific basis for a serious solo-learning Quran memorization app.

---

## Source notes

The following sources informed this package.

### Learning science
- Dunlosky et al. (2013), *Improving Students’ Learning With Effective Learning Techniques*
- Agarwal, Nunes, and Blunt (2021), *Retrieval Practice Consistently Benefits Student Learning*
- Donoghue and Hattie (2021), *A Meta-Analysis of Ten Learning Techniques*

### Duolingo / adaptive learning
- Duolingo blog, *Measuring Lesson Recall on Duolingo*
- Duolingo blog, *How Difficult Lessons Motivate Learners*
- Settles and Meeder (2016), *A Trainable Spaced Repetition Model for Language Learning*
- Duolingo HLR GitHub repository

### Gamification
- Sailer and Homner (2020), *The Gamification of Learning: a Meta-analysis*
- Huang et al. (2020), *The impact of gamification in educational settings on student learning outcomes: a meta-analysis*

### ADHD / dyslexia / readability
- CDC, *ADHD in the Classroom: Helping Children Succeed in School*
- Zorzi et al. (2012), *Extra-large letter spacing improves reading in dyslexia*
- Galliussi et al. (2020), *Inter-letter spacing, inter-word spacing, and font with dyslexia-friendly features*
- Hejres and Tinker (2024), *Informing the Design of an Accessible Arabic Typeface*
- Abu-Rabia (1997), *Reading in Arabic orthography: the effect of vowels and context*
- Tarabya, Andria, and Khateb (2025), *Reading subtyping of Arabic-speaking university students*
- Boumaraf and Macoir (2019), *Orthographic connectivity in Arabic reading*

### Quran memorization / digital Quran systems
- Haryono, Rajagede, and Negara (2023), *Quran Memorization Technologies and Methods: Literature Review*
- Yusup, Abdul Rahim, and Borham (2025), *Murajaah in Quran Memorization among Islamic Students: A Systematic Literature Review*
- Ahmad et al. (2021), *Methods of Memorizing Mutashabihat Verses*
- recent public product examples such as Hifzer, Hifz Tracker, Quran Hifz Revision, Muraajah Map, and Tarteel for category signals
