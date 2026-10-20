#!/usr/bin/env bash
# Qué hace: prueba los scripts deterministas del harness (guardia, trazas, puerta de /plan y puerta de /validate) sobre un repositorio git temporal, sin dotnet ni Docker.
# Para qué sirve: red de seguridad del propio plugin; se lanza a mano (`bash plugins/dotnet-team/tests/run.sh`) antes de tocar scripts o de la demo.
set -uo pipefail

PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export CLAUDE_PLUGIN_ROOT="$PLUGIN" CLAUDE_PROJECT_DIR="$TMP"
git -C "$TMP" init -q

pass=0; fail=0
check() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass=$((pass + 1)); echo "✔ $name"; else fail=$((fail + 1)); echo "✖ $name (expected $expected, got $actual)"; fi
}

guard() {
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"}}' "$TMP/$1" "$2" |
    bash "$PLUGIN/scripts/hooks/guard-edits.sh" 2>/dev/null
  echo $?
}

check "guard: free code outside any phase" 0 "$(guard src/App.Api/Program.cs 'ok')"
check "guard: Directory.Build.props is a guardrail" 2 "$(guard Directory.Build.props 'x')"
check "guard: architecture tests are a guardrail" 2 "$(guard tests/App.ArchitectureTests/LayersTests.cs 'x')"
check "guard: warnings are not silenced" 2 "$(guard src/App.Api/Program.cs '#pragma warning disable CA1')"
check "guard: no connection strings in appsettings" 2 "$(guard src/App.Api/appsettings.json 'Server=x;Password=y')"

mkdir -p "$TMP/.work" && echo plan > "$TMP/.work/phase"
check "guard plan: src/ blocked" 2 "$(guard src/App.Domain/Show.cs 'x')"
check "guard plan: acceptance tests blocked (they go in the plan)" 2 "$(guard tests/App.AcceptanceTests/Features/X/XTests.cs 'x')"
check "guard plan: .work allowed" 0 "$(guard .work/plan.md 'x')"
echo apply > "$TMP/.work/phase"
check "guard apply: src/ allowed" 0 "$(guard src/App.Domain/Show.cs 'x')"
check "guard apply: plan tests blocked" 2 "$(guard tests/App.AcceptanceTests/Features/X/XTests.cs 'x')"
check "guard apply: unit tests allowed" 0 "$(guard tests/App.UnitTests/ShowTests.cs 'x')"
check "guard apply: outside src/ blocked" 2 "$(guard README.md 'x')"
echo validate > "$TMP/.work/phase"
check "guard validate: read-only" 2 "$(guard tests/App.AcceptanceTests/Features/X/XTests.cs 'x')"
rm -f "$TMP/.work/phase"

printf '{"hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"dotnet-team:dotnet-guardrails"}}' | bash "$PLUGIN/scripts/hooks/trace.sh"
check "traces: records the skill" 1 "$(grep -c '"detail":"dotnet-team:dotnet-guardrails"' "$TMP/.work/trace.jsonl")"

# /plan gate: shape and conventions of the tests written inside the plan (no dotnet).
plan_gate() {
  sed -e "s/__METHOD__/$1/" -e "s/__EXTRA__/$2/" > "$TMP/.work/plan.md" <<'PLAN'
---
issue: 3
feature: blank-title
status: draft
---

# Plan: blank title

## Goal

A blank title returns 400.

## Guardrails applied

- Errors as values.

## Tasks

### T1 · CreateShow · command

- Layers: Domain
- Files: `src/App.Domain/Show.cs`
- HTTP contract: `POST /api/shows` → 201 | 400
- Tests: `XTests.__METHOD__`

## Acceptance tests

#### `tests/App.AcceptanceTests/Features/X/XTests.cs`

```csharp
[Collection(ApiFixture.Name)]
public class XTests
{
    [Fact__EXTRA__]
    public async Task __METHOD__()
    {
        response.StatusCode.ShouldBe(HttpStatusCode.BadRequest);
        problem.GetProperty("errors").TryGetProperty("Show.InvalidTitle", out _).ShouldBeTrue();
    }
}
```

## Out of scope

- Nothing.
PLAN
  bash "$PLUGIN/scripts/gates/plan.sh" > /dev/null 2>&1
  echo $?
}
check "plan gate: valid plan" 0 "$(plan_gate CreateShow_blank_title_returns_400 '')"
check "plan gate: name without <Case>_<Scenario>_<Result>" 1 "$(plan_gate CreateBlankShow '')"
check "plan gate: no Skip" 1 "$(plan_gate CreateShow_blank_title_returns_400 '(Skip = \"later\")')"
plan_gate CreateShow_blank_title_returns_400 '' > /dev/null
sed -i '/^```csharp$/,/^```$/d' "$TMP/.work/plan.md"
check "plan gate: no test block" 1 "$(bash "$PLUGIN/scripts/gates/plan.sh" > /dev/null 2>&1; echo $?)"
mkdir -p "$TMP/tests/App.AcceptanceTests" && touch "$TMP/tests/App.AcceptanceTests/Loose.cs"
check "plan gate: writes no files outside the plan" 1 "$(plan_gate CreateShow_blank_title_returns_400 '')"
rm -rf "$TMP/tests" "$TMP/.work/plan.md"

mkdir -p "$TMP/src" && touch "$TMP/src/Program.cs"
echo "$TMP" > "$TMP/.work/validate-target"
report() {
  printf -- '---\ntarget: .\nverdict: %s\n---\n\n# Validation\n\n## Findings\n\n| Rule | Severity | File | Evidence | Fix |\n|---|---|---|---|---|\n%s\n' "$1" "$2" > "$TMP/.work/validate.md"
  bash "$PLUGIN/scripts/gates/validate.sh" > /dev/null 2>&1
  echo $?
}
check "validate: consistent report" 0 "$(report NON_COMPLIANT '| BE-ARCH-01 | high | — | no layers | split |')"
check "validate: made-up rule" 1 "$(report NON_COMPLIANT '| BE-NOPE-01 | high | — | x | y |')"
check "validate: inconsistent verdict" 1 "$(report COMPLIANT '| BE-TIME-01 | low | `src/Program.cs` | x | y |')"
check "validate: missing file" 1 "$(report COMPLIANT_WITH_WARNINGS '| BE-TIME-01 | low | `src/Nope.cs` | x | y |')"
check "validate: Spanish severity rejected" 1 "$(report NON_COMPLIANT '| BE-ARCH-01 | alta | — | x | y |')"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
