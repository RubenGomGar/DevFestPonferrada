---
description: Implementa un plan aprobado (.work/plan.md). Copia sus tests de aceptación, comprueba que están en rojo y escribe el código hasta dejarlos en verde sin romper los guardarraíles.
allowed-tools: Read, Glob, Grep, Write(src/**), Edit(src/**), Write(tests/**), Edit(tests/**), Write(.work/**), Skill, Bash(dotnet build:*), Bash(dotnet test:*), Bash(dotnet ef:*)
---

# /apply · del plan aprobado a los tests en verde

## Contexto precalculado

Lo ha generado un script antes de que leyeras nada: los tests del plan ya están en su sitio y en rojo. Úsalo; no lo vuelvas a descubrir.

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/ctx/apply.sh"`

## Qué haces

1. Si el contexto dice **PRECONDICIÓN FALLIDA**, para: explica el motivo en una frase y no sigas.
2. Lee `.work/plan.md` entero. Es el contrato: tareas, ficheros, contrato HTTP y errores. No amplíes el alcance; lo de `Fuera de alcance` no se hace.
3. Carga las skills `dotnet-guardrails` (cómo se construye aquí) y `dotnet-testing` (qué test y dónde). Úsalas; no reimplementes lo que dicen.
4. Lee el slice de referencia del contexto antes de escribir: el código nuevo se parece a él.
5. Implementa las tareas en orden, de dentro afuera (Domain → Application → Infrastructure → Api). Tras cada tarea, `dotnet build` y sus tests con `dotnet test --filter`.
6. Los tests de aceptación del plan no se tocan. Si uno te parece mal, para y explica por qué: se corrige en `/dotnet-team:plan`. Un hook lo impide; si te bloquea, no lo rodees.
7. Tests unitarios solo si una tarea mete lógica con ramas reales, según `dotnet-testing`.
8. Nunca tocas guardarraíles ni silencias avisos. No haces commit.

## Al terminar

Resume en cinco líneas como máximo: ficheros tocados, tests en verde y cualquier decisión que el plan no dejara clara. Cierra con:

> Revisa el diff (`git diff`) y, si te encaja, haz commit.

Cuando termines, una puerta automática comprueba que los tests del plan siguen siendo los aprobados, que solo has tocado `src/` y tests unitarios, que compila, que la arquitectura sigue en verde y que **todos** los tests pasan. Si te bloquea, corrige según el motivo y vuelve a terminar.
