# Explainer HTML Prompt

Use this template only when the user explicitly asks for a local HTML explainer or HTML study guide.

## Intent

- Create explanation artifacts for the user, not shipped app features.
- Default to a two-page pair:
  - main guide with sidebar/navigation
  - calmer reading edition
- Optimize for plain language, dyslexia-friendly defaults, and ADHD-friendly scan order.

## Ready-To-Paste Prompt

```text
Read these first, in order:
1. docs/assistant/features/APP_USER_GUIDE.md
2. docs/assistant/features/PLANNER_USER_GUIDE.md if the topic touches planning or Companion
3. APP_KNOWLEDGE.md
4. docs/assistant/ROADMAP_ANCHOR.md if the explanation touches the current roadmap state
5. only the touched workflow docs if needed for accuracy

Create a local HTML explainer for the user.
This is not a shipped app feature.
Do not treat it as product scope.

Default output:
- a main guide at docs/assistant/features/<TOPIC>_EXPLAINER.html
- a calmer reading edition at docs/assistant/features/<TOPIC>_EXPLAINER_READING.html

Requirements:
- plain-language-first
- verify claims against APP_KNOWLEDGE.md before simplifying them
- dyslexia-friendly defaults
- ADHD-friendly chunking, scan order, and lower visual noise
- main guide first, then calmer reading edition for dense topics
- Edge/browser speech controls when useful
- reading edition should favor one-column flow, chunked sections, and sentence-level read-aloud when useful

Hard boundaries:
- these HTML files are explanation artifacts only, not app features
- keep them local-only by default
- do not add them to normal feature commits unless the user explicitly asks
- if the user explicitly promotes a stable pair, that specific pair may be committed while future explainers still default to local-only
- if needed, use repo-local exclude rules so the generated explainer files do not dirty git status

After generating the files:
- open them in Edge if visual/readability review is useful
- iterate on font, spacing, voice curation, and interaction polish only within the explainer files
- do not leak explainer polish into app implementation unless separately requested
```
