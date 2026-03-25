# Terms In Plain English

## Canonical

The main source of truth. If two docs disagree, the canonical one wins.

## Bridge Doc

A helper doc that points people to the real source of truth.

## Manifest

A machine-readable map that tells agents which docs and tests to use.

## ExecPlan

A detailed working plan for major or multi-file changes.

## Roadmap Anchor

The file that says where long-running Companion/Planner work currently stands and what comes next.

## Harness

The set of runbooks, workflows, validators, and rules that help humans and AI agents work safely in the repo.

## Bootstrap Harness

A reusable starter system that can add or refresh that harness in a repo.

## Output Map

A small mapping file that tells the bootstrap system which existing repo docs already serve the same purpose as generic bootstrap outputs.

## Worktree

An isolated extra checkout of the same git repo, usually used to keep separate streams of work from colliding.

## Validation

Running checks and tests to prove the docs or code still make sense after a change.
