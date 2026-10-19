---
description: Convierte una issue de GitHub en un plan de vertical slices que respeta los guardarraíles y deja escritos los tests de aceptación en rojo (TDD). No implementa.
argument-hint: "<número de issue>"
allowed-tools: Read, Glob, Grep, Write(.work/**), Edit(.work/**), Write(tests/**), Edit(tests/**), Skill, Bash(gh issue view:*), mcp__plugin_dotnet-team_github__issue_read, mcp__plugin_dotnet-team_github__get_issue
---

# /plan · de una issue a un plan con tests en rojo

## Contexto precalculado

Lo ha generado un script antes de que leyeras nada. Úsalo; no lo vuelvas a descubrir.

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ctx/plan.sh"`

## Issue

$ARGUMENTS

## Qué haces

1. Si el contexto dice **PRECONDICIÓN FALLIDA**, para: explica el motivo en una frase y no sigas.
2. Si no hay número de issue, pide uno en una frase.
3. Lee la issue del repositorio GitHub del contexto con el MCP de GitHub (`issue_read`). Si el MCP no está disponible, usa `gh issue view <n> --json title,body,labels`.
4. Carga las skills `dotnet-guardrails` (cómo se construye aquí) y `dotnet-testing` (qué test y dónde). Úsalas; no reimplementes lo que dicen.
5. Lee el slice de referencia del contexto y el código que la issue toque. Solo lectura.
6. Escribe `.work/plan.md` copiando la estructura exacta de `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`:
   - `issue` es el número; `status: draft`. La aprobación es humana: nunca escribes `approved`.
   - Una tarea por slice: `### T<n> · <NombreSlice> · command|query`, con `Capas`, `Ficheros`, `Contrato HTTP`, `Errores` y `Tests`.
   - En `Guardarraíles aplicados`, las reglas concretas que condicionan este plan.
7. Escribe los tests de aceptación de la issue en `tests/*AcceptanceTests/Features/<Feature>/`:
   - Solo HTTP y JSON; ningún tipo de `src/` que no exista todavía. Tienen que compilar.
   - Tienen que **fallar todos** hoy: describen comportamiento que aún no existe. Si es un bug, un test que lo reproduzca.
8. No escribes en `src/` ni tocas guardarraíles. Un hook lo impide; si te bloquea, no lo rodees.

## Al terminar

Resume en cinco líneas como máximo: tareas, tests en rojo y supuestos importantes. Cierra con:

> Revisa `.work/plan.md` y los tests en rojo. Si te encajan, cambia `status: draft` por `status: approved`.

Cuando termines, una puerta automática compila, comprueba que la arquitectura sigue en verde y que **todos** los tests nuevos fallan. Si te bloquea, corrige según el motivo y vuelve a terminar.
