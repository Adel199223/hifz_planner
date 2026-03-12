# Explainer HTML Workflow

## What This Workflow Is For

Use this workflow when the user explicitly asks for a local HTML explainer that helps them understand the app, a subsystem, or a roadmap milestone in a calmer and more accessible format.

## Expected Outputs

- Explanation artifacts are accurate, plain-language-first, and grounded in canonical docs.
- Output defaults to a two-page pair:
  - a main guide with sidebar/navigation when that helps scanning
  - a calmer reading edition for focused reading and read-aloud
- Generated HTML files stay outside shipped app scope and remain local-only by default.
- If the user explicitly promotes a stable/reusable explainer pair, that specific pair may be committed and maintained as assistant reference docs.

## When To Use

Use when the user explicitly asks for:
- an HTML explainer
- a local study guide about how the app works
- a calmer/dyslexia-friendly explanation artifact
- a companion/planner explanation that is easier to read than normal chat output

Before writing, read in this order:
- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PLANNER_USER_GUIDE.md` when planner/companion topics are involved
- `APP_KNOWLEDGE.md`
- `docs/assistant/ROADMAP_ANCHOR.md` when the explanation touches the current roadmap state
- touched workflow docs only if needed for accuracy

## What Not To Do

- Don't use this workflow when the task is ordinary support or a normal plain-text explanation. Instead use `docs/assistant/features/APP_USER_GUIDE.md` and `docs/assistant/features/PLANNER_USER_GUIDE.md`.
- Don't use this workflow when the task is app implementation. Instead use the relevant feature workflow and keep explainer work separate.
- Do not treat generated explainer HTML files as shipped app features.
- Do not commit explainer artifacts by default.
- Do not assume a promoted explainer pair changes the default for future explainers; future pairs still stay local-only unless explicitly promoted.
- Do not simplify behavior claims without checking `APP_KNOWLEDGE.md` first.
- Do not let explainer polish change the real app unless the user separately requests implementation work.

## Primary Files

- `docs/assistant/features/APP_USER_GUIDE.md`
- `docs/assistant/features/PLANNER_USER_GUIDE.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/ROADMAP_ANCHOR.md`
- `docs/assistant/templates/EXPLAINER_HTML_PROMPT.md`
- `docs/assistant/features/*_EXPLAINER.html`
- `docs/assistant/features/*_EXPLAINER_READING.html`

## Minimal Commands

```powershell
git status --short --branch
dart run tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: the explanation drifts from real app behavior.
   - Re-read `APP_KNOWLEDGE.md` and any touched workflow doc before rewriting the HTML.
2. Symptoms: the guide is too dense or too technical.
   - Shorten paragraphs, add clearer headings, and keep the reading edition one-column and chunked.
3. Symptoms: the repo becomes dirty because explainer files show up as untracked.
   - Add the generated file paths or explainer wildcard patterns to `.git/info/exclude` and keep them local-only unless the user explicitly asks to commit them.
4. Symptoms: a stable explainer pair is worth preserving for future reference.
   - If the user explicitly promotes that pair, force-add the specific tracked files and keep the default local-only rule for future explainers.
5. Symptoms: Edge read-aloud is unreliable on the main guide.
   - Keep the calmer reading edition as the fallback surface and prefer sentence-level read-aloud controls there.
6. Symptoms: the user wants a simpler or denser explainer than the default pair.
   - Keep the default two-page pair, then iterate only on the requested surface without changing app scope.

## Handoff Checklist

- the explanation was explicitly user-triggered
- claims were checked against `APP_KNOWLEDGE.md`
- planner/companion explanations also checked `PLANNER_USER_GUIDE.md` and `ROADMAP_ANCHOR.md` when relevant
- output file names follow the `docs/assistant/features/*_EXPLAINER.html` and `docs/assistant/features/*_EXPLAINER_READING.html` pattern
- main guide was built first
- calmer reading edition was also produced for dense topics unless the user asked for a single page
- generated explainer files remain local-only by default
- promoted explainer pairs were committed only when the user explicitly asked to preserve them
- repo-local exclude rules keep explainer files from dirtying the worktree
