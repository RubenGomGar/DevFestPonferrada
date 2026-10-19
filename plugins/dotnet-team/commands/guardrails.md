---
description: Instala en la solución los guardarraíles ejecutables de Platform (build estricto, estilo y tests de arquitectura) y enseña qué falla hoy. Equivale al /make-guardrails de Platform.
allowed-tools: Read, Bash(bash:*), Bash(dotnet build:*), Bash(dotnet test:*)
---

# /guardrails · las reglas del equipo, convertidas en código

## Qué haces

1. Ejecuta `bash "${CLAUDE_PLUGIN_ROOT}/scripts/guardrails/init.sh"` y muestra su salida tal cual.
2. Ejecuta `dotnet build` de la solución y después `dotnet test` del proyecto `tests/*ArchitectureTests`.
3. No arreglas nada, ni código ni reglas: esta orden instala las reglas y enseña dónde se rompen.

## Al terminar

Resume en cinco líneas como máximo:

- Qué guardarraíles se han instalado y cuáles ya existían.
- Qué falla ahora (errores de build o tests en rojo), agrupado y con la regla de Platform que lo exige.
- El siguiente paso: arreglar la base hasta que esté en verde. Hasta entonces, `/dotnet-team:plan` no arranca porque su precondición lo impide.
