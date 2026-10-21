---
description: Validates a .NET folder against the Platform best practices and writes a findings report to .work/validate.md. Read-only.
argument-hint: "[folder, defaults to the root]"
allowed-tools: Read, Glob, Grep, Write(.work/**), Bash(bash:*), Agent
---

# /validate · does this folder comply with Platform?

Reply to the user in the language they write in. The `.work/validate.md` keys and verdicts stay exactly as specified.

## Folder

$ARGUMENTS

## What you do

1. Run the facts script on the folder (if empty, `.`):

   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate/facts.sh" <folder>`

   If it fails, stop and explain the reason in one sentence.
2. Delegate to the `dotnet-team:platform-reviewer` agent. Pass it the folder, the rules path (`${CLAUDE_PLUGIN_ROOT}/references/platform-rules.md`) and the full facts table, as is. Do not review yourself: the agent is the expert. Run it in the foreground and wait for its answer: never in the background, because you cannot finish until `.work/validate.md` exists.
3. Write its answer, untouched, to `.work/validate.md`.
4. You modify nothing else. A hook prevents it.

## When you finish

Summarize in at most four lines: verdict, number of findings per severity and the two most important ones. If there are layer, build or test findings, suggest `/dotnet-team:guardrails`.

When you finish, an automatic gate checks that each finding cites an existing rule, with a valid severity and a file that exists, and that the verdict is consistent.
