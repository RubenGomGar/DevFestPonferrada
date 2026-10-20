---
description: Convierte una issue de GitHub en un plan de vertical slices que respeta los guardarraíles, con los tests de aceptación (TDD) escritos dentro del propio plan. No implementa.
argument-hint: "<número de issue>"
allowed-tools: Read, Glob, Grep, Write(.work/**), Edit(.work/**), Skill, Bash(gh issue view:*), mcp__plugin_dotnet-team_github__issue_read
---

# /plan · de una issue a un plan con sus tests

## Contexto precalculado

Lo ha generado un script antes de que leyeras nada. Úsalo; no lo vuelvas a descubrir.

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ctx/plan.sh"`

## Issue

$ARGUMENTS

## Qué haces

1. Si el contexto dice **PRECONDICIÓN FALLIDA**, para: explica el motivo en una frase y no sigas.
2. Si no hay número de issue, pide uno en una frase.
3. Lee la issue del repositorio GitHub del contexto con el MCP de GitHub (`issue_read`). Si el MCP no está disponible, usa `gh issue view <n> --json title,body,labels`.
4. Carga la skill `dotnet-guardrails` (cómo se construye aquí). Úsala; no reimplementes lo que dice.
5. Lee el slice de referencia del contexto y el código que la issue toque. Solo lectura.
6. Escribe `.work/plan.md` copiando la estructura exacta de `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`:
   - `issue` es el número; `status: draft`. La aprobación es humana: nunca escribes `approved`.
   - Una tarea por slice: `### T<n> · <NombreSlice> · command|query`, con `Capas`, `Ficheros`, `Contrato HTTP`, `Errores` y `Tests`.
   - En `Guardarraíles aplicados`, las reglas concretas que condicionan este plan.
7. Escribe los tests de aceptación **dentro del plan**: un encabezado `` #### `tests/<App>.AcceptanceTests/Features/<Feature>/<Clase>Tests.cs` `` por fichero y debajo el fichero completo en un bloque `csharp`. Tienen que compilar y **fallar todos** hoy.
8. Solo escribes `.work/plan.md`.

## Al terminar

Resume en cinco líneas como máximo: tareas, tests y supuestos importantes. Cierra con:

> Revisa `.work/plan.md`: los tests están dentro. Si te encaja, cambia `status: draft` por `status: approved`.
