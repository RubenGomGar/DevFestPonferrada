---
description: Turns a GitHub issue into a vertical-slice plan that respects the guardrails, with the acceptance tests (TDD) written inside the plan itself. Does not implement.
argument-hint: "<issue number>"
allowed-tools: Read, Glob, Grep, Write(.work/**), Edit(.work/**), Skill, Bash(gh issue view:*), mcp__plugin_dotnet-team_github__issue_read
---

# /plan · from an issue to a plan with its tests

Reply to the user in the language they write in. Plan headings and field names stay exactly as in the template.

## Precomputed context

A script generated this before you read anything. Use it; do not rediscover it.

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ctx/plan.sh"`

## Issue

$ARGUMENTS

## What you do

1. If the context says **PRECONDITION FAILED**, stop: explain the reason in one sentence and go no further.
2. If there is no issue number, ask for one in one sentence.
3. Read the issue from the context's GitHub repository with the GitHub MCP (`issue_read`). If the MCP is not available, use `gh issue view <n> --json title,body,labels`.
4. Load the `dotnet-guardrails` skill (how things are built here). Use it; do not reimplement what it says.
5. Read the reference slice from the context and the code the issue touches. Read-only.
6. Write `.work/plan.md` copying the exact structure of `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`:
   - `issue` is the number; `status: draft`. Approval is human: you never write `approved`.
   - One task per slice: `### T<n> · <SliceName> · command|query`, with `Layers`, `Files`, `HTTP contract`, `Errors` and `Tests`.
   - Under `Guardrails applied`, the specific rules that shape this plan.
7. Write the acceptance tests **inside the plan**: one heading `` #### `tests/<App>.AcceptanceTests/Features/<Feature>/<Class>Tests.cs` `` per file and below it the full file in a `csharp` block. They must compile and **all fail** today.
8. You only write `.work/plan.md`.

## When you finish

Summarize in at most five lines: tasks, tests and important assumptions. End with:

> Review `.work/plan.md`: the tests are inside. If you are happy with it, change `status: draft` to `status: approved`.
