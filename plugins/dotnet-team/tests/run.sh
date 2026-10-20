#!/usr/bin/env bash
# Tests de los scripts deterministas del harness: guardia, trazas y puerta de /validate.
# No necesitan dotnet ni Docker: trabajan sobre un repositorio temporal.
set -uo pipefail

PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export CLAUDE_PLUGIN_ROOT="$PLUGIN" CLAUDE_PROJECT_DIR="$TMP"
git -C "$TMP" init -q

pass=0; fail=0
check() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass=$((pass + 1)); echo "✔ $name"; else fail=$((fail + 1)); echo "✖ $name (esperado $expected, obtenido $actual)"; fi
}

guard() {
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"}}' "$TMP/$1" "$2" |
    bash "$PLUGIN/scripts/hooks/guard-edits.sh" 2>/dev/null
  echo $?
}

check "guardia: código libre fuera de fase" 0 "$(guard src/App.Api/Program.cs 'ok')"
check "guardia: Directory.Build.props es un guardarraíl" 2 "$(guard Directory.Build.props 'x')"
check "guardia: tests de arquitectura son guardarraíl" 2 "$(guard tests/App.ArchitectureTests/CapasTests.cs 'x')"
check "guardia: no se silencian avisos" 2 "$(guard src/App.Api/Program.cs '#pragma warning disable CA1')"
check "guardia: no hay connection strings en appsettings" 2 "$(guard src/App.Api/appsettings.json 'Server=x;Password=y')"

mkdir -p "$TMP/.work" && echo plan > "$TMP/.work/phase"
check "guardia plan: src/ bloqueado" 2 "$(guard src/App.Domain/Obra.cs 'x')"
check "guardia plan: tests de aceptación bloqueados (van en el plan)" 2 "$(guard tests/App.AcceptanceTests/Features/X/XTests.cs 'x')"
check "guardia plan: .work permitido" 0 "$(guard .work/plan.md 'x')"
echo apply > "$TMP/.work/phase"
check "guardia apply: src/ permitido" 0 "$(guard src/App.Domain/Obra.cs 'x')"
check "guardia apply: tests del plan bloqueados" 2 "$(guard tests/App.AcceptanceTests/Features/X/XTests.cs 'x')"
check "guardia apply: tests unitarios permitidos" 0 "$(guard tests/App.UnitTests/ObraTests.cs 'x')"
check "guardia apply: fuera de src/ bloqueado" 2 "$(guard README.md 'x')"
echo validate > "$TMP/.work/phase"
check "guardia validate: solo lectura" 2 "$(guard tests/App.AcceptanceTests/Features/X/XTests.cs 'x')"
rm -f "$TMP/.work/phase"

printf '{"hook_event_name":"PostToolUse","tool_name":"Skill","tool_input":{"skill":"dotnet-team:dotnet-guardrails"}}' | bash "$PLUGIN/scripts/hooks/trace.sh"
check "trazas: registra la skill" 1 "$(grep -c '"detail":"dotnet-team:dotnet-guardrails"' "$TMP/.work/trace.jsonl")"

# Puerta de /plan: forma y convenciones de los tests escritos dentro del plan (sin dotnet).
plan_gate() {
  sed -e "s/__METODO__/$1/" -e "s/__EXTRA__/$2/" > "$TMP/.work/plan.md" <<'PLAN'
---
issue: 3
feature: titulo-en-blanco
status: draft
---

# Plan: título en blanco

## Objetivo

Un título en blanco devuelve 400.

## Guardarraíles aplicados

- Errores como valores.

## Tareas

### T1 · CrearObra · command

- Capas: Domain
- Ficheros: `src/App.Domain/Obra.cs`
- Contrato HTTP: `POST /api/obras` → 201 | 400
- Tests: `XTests.__METODO__`

## Tests de aceptación

#### `tests/App.AcceptanceTests/Features/X/XTests.cs`

```csharp
[Collection(ApiFixture.Name)]
public class XTests
{
    [Fact__EXTRA__]
    public async Task __METODO__()
    {
        response.StatusCode.ShouldBe(HttpStatusCode.BadRequest);
        problem.GetProperty("errors").TryGetProperty("Obra.TituloInvalido", out _).ShouldBeTrue();
    }
}
```

## Fuera de alcance

- Nada.
PLAN
  bash "$PLUGIN/scripts/gates/plan.sh" > /dev/null 2>&1
  echo $?
}
check "puerta plan: plan válido" 0 "$(plan_gate CrearObra_titulo_en_blanco_devuelve_400 '')"
check "puerta plan: nombre sin <Caso>_<Escenario>_<Resultado>" 1 "$(plan_gate CrearObraEnBlanco '')"
check "puerta plan: nada de Skip" 1 "$(plan_gate CrearObra_titulo_en_blanco_devuelve_400 '(Skip = \"luego\")')"
plan_gate CrearObra_titulo_en_blanco_devuelve_400 '' > /dev/null
sed -i '/^```csharp$/,/^```$/d' "$TMP/.work/plan.md"
check "puerta plan: sin bloque de test" 1 "$(bash "$PLUGIN/scripts/gates/plan.sh" > /dev/null 2>&1; echo $?)"
mkdir -p "$TMP/tests/App.AcceptanceTests" && touch "$TMP/tests/App.AcceptanceTests/Suelto.cs"
check "puerta plan: no escribe ficheros fuera del plan" 1 "$(plan_gate CrearObra_titulo_en_blanco_devuelve_400 '')"
rm -rf "$TMP/tests" "$TMP/.work/plan.md"

mkdir -p "$TMP/src" && touch "$TMP/src/Program.cs"
echo "$TMP" > "$TMP/.work/validate-target"
report() {
  printf -- '---\ntarget: .\nverdict: %s\n---\n\n# Validación\n\n## Hallazgos\n\n| Regla | Severidad | Fichero | Evidencia | Arreglo |\n|---|---|---|---|---|\n%s\n' "$1" "$2" > "$TMP/.work/validate.md"
  bash "$PLUGIN/scripts/gates/validate.sh" > /dev/null 2>&1
  echo $?
}
check "validate: informe coherente" 0 "$(report NO_CUMPLE '| BE-ARCH-01 | alta | — | sin capas | separar |')"
check "validate: regla inventada" 1 "$(report NO_CUMPLE '| BE-NOPE-01 | alta | — | x | y |')"
check "validate: veredicto incoherente" 1 "$(report CUMPLE '| BE-TIME-01 | baja | `src/Program.cs` | x | y |')"
check "validate: fichero inexistente" 1 "$(report CUMPLE_CON_AVISOS '| BE-TIME-01 | baja | `src/Nope.cs` | x | y |')"

echo
echo "$pass correctos, $fail fallidos"
[ "$fail" -eq 0 ]
