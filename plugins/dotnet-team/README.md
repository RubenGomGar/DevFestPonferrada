# dotnet-team

El expertise .NET del equipo como harness de Claude Code: los guardarraíles de [Platform](https://platform.plainconcepts.com/docs/backend), un `/plan` que parte de una issue y deja los tests en rojo, y un `/validate` que contrasta cualquier carpeta con Platform.

```text
/plugin marketplace add RubenGomGar/NetCoreConfMadrid2026
/plugin install dotnet-team@netcoreconf-2026
```

## Comandos

| Comando | Recibe | Entrega | Puerta (hook `Stop`) |
|---|---|---|---|
| `/dotnet-team:plan <issue>` | Número de issue de GitHub | `.work/plan.md` en `draft` + tests de aceptación | Forma del plan; compila; arquitectura en verde; **todos** los tests nuevos en rojo |
| `/dotnet-team:validate [carpeta]` | Carpeta .NET | `.work/validate.md` con hallazgos | Cada hallazgo cita una regla existente, severidad válida, fichero existente, veredicto coherente |
| `/dotnet-team:guardrails` | La solución actual | `Directory.Build.props`, `.editorconfig`, `tests/*.ArchitectureTests` | — (enseña qué falla) |

## Piezas

| Pieza | Tipo | Responsabilidad |
|---|---|---|
| `dotnet-guardrails` | Skill | Cómo se construye un backend según Platform |
| `dotnet-testing` | Skill | Qué tests escribir y dónde (trofeo de Platform) |
| `platform-reviewer` | Agente (solo lectura) | Contrastar hechos y código con `references/platform-rules.md` |
| `scripts/ctx/plan.sh` | Script | Precondición y contexto precalculado de `/plan` |
| `scripts/validate/facts.sh` | Script | Hechos deterministas de una carpeta |
| `scripts/guardrails/init.sh` | Script | Instalar los guardarraíles sin sobrescribir nada |
| `.mcp.json` + `scripts/mcp/github-headers.sh` | MCP | GitHub remoto **solo lectura de issues** (6 herramientas en vez de 49), autenticado con la sesión de `gh auth login` vía `headersHelper`; sin tokens propios. Plan B: `gh issue view` |

## Hooks

| Evento | Script | Qué hace |
|---|---|---|
| `UserPromptSubmit`, `PostToolUse`, `SubagentStop` | `trace.sh` | Una línea por evento en `.work/trace.jsonl` |
| `PreToolUse` (Edit, Write) | `guard-edits.sh` | Bloquea guardarraíles, `#pragma`/`NoWarn`, connection strings en `appsettings` y escrituras fuera de la fase |
| `Stop` | `stop-gate.sh` | Ejecuta la puerta de la fase activa; tras 3 fallos cede a una persona (`.work/NEEDS_HUMAN.md`) |

## Desarrollo

```bash
claude plugin validate plugins/dotnet-team
bash plugins/dotnet-team/tests/run.sh
claude --plugin-dir plugins/dotnet-team
```

## Limitaciones conocidas

- La guardia no ve escrituras hechas con `Bash`; la puerta de `/plan` vuelve a comprobar el diff completo.
- Si interrumpes un comando, borra `.work/phase` para que la puerta no salte en el siguiente turno.
- `references/platform-rules.md` es un snapshot (2026-10-19). Si Platform cambia, se actualiza el fichero.
