---
description: Implements an approved plan (.work/plan.md). Copies its acceptance tests, checks they are red and writes the code until they are green without breaking the guardrails.
allowed-tools: Read, Glob, Grep, Write(src/**), Edit(src/**), Write(tests/**), Edit(tests/**), Write(.work/**), Skill, Bash(dotnet build:*), Bash(dotnet test:*), Bash(dotnet ef:*)
---

# /apply · from the approved plan to green tests

Reply to the user in the language they write in. Plan headings and field names stay exactly as in the template.

## Precomputed context

A script generated this before you read anything: the plan tests are already in place and red. Use it; do not rediscover it.

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ctx/apply.sh"`

## What you do

1. If the context says **PRECONDITION FAILED**, stop: explain the reason in one sentence and go no further.
2. Read `.work/plan.md` in full. It is the contract: tasks, files, HTTP contract and errors. Do not widen the scope; whatever is under `Out of scope` is not done.
3. Load the `dotnet-guardrails` (how things are built here) and `dotnet-testing` (which test and where) skills. Use them; do not reimplement what they say.
4. Read the reference slice from the context before writing: the new code looks like it.
5. Implement the tasks in order, inside out (Domain → Application → Infrastructure → Api). After each task, run `dotnet build` and its tests with `dotnet test --filter`.
6. The plan's acceptance tests are not touched. If one looks wrong, stop and explain why: it gets fixed in `/dotnet-team:plan`. A hook prevents it; if it blocks you, do not work around it.
7. Unit tests only if a task adds logic with real branches, as `dotnet-testing` says.
8. You never touch guardrails or silence warnings. You do not commit.

## When you finish

Summarize in at most five lines: files touched, green tests and any decision the plan did not make clear. End with:

> Review the diff (`git diff`) and, if you are happy with it, commit.

When you finish, an automatic gate checks that the plan tests are still the approved ones, that you only touched `src/` and unit tests, that it builds, that the architecture is still green and that **all** tests pass. If it blocks you, fix according to the reason and finish again.
