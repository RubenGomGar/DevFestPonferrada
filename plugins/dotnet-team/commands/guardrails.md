---
description: Installs the Platform executable guardrails in the solution (strict build, style and architecture tests) and shows what fails today. Equivalent to Platform's /make-guardrails.
allowed-tools: Read, Bash(bash:*), Bash(dotnet build:*), Bash(dotnet test:*)
---

# /guardrails · the team's rules, turned into code

Reply to the user in the language they write in. Script output, Platform rule IDs and `.work/validate.md` keys and verdicts stay exactly as specified.

## What you do

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/guardrails/init.sh"` and show its output as is.
2. Run `dotnet build` on the solution and then `dotnet test` on the `tests/*ArchitectureTests` project.
3. You fix nothing, neither code nor rules: this command installs the rules and shows where they break.

## When you finish

Summarize in at most five lines:

- Which guardrails were installed and which already existed.
- What fails now (build errors or red tests), grouped and with the Platform rule that requires it.
- The next step: fix the codebase until it is green. Until then, `/dotnet-team:plan` will not start because its precondition prevents it.
