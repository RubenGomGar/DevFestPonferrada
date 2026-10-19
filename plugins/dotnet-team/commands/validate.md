---
description: Valida una carpeta .NET frente a las buenas prácticas de Platform y deja un informe con hallazgos en .work/validate.md. Solo lectura.
argument-hint: "[carpeta, por defecto la raíz]"
allowed-tools: Read, Glob, Grep, Write(.work/**), Bash(bash:*), Agent
---

# /validate · ¿cumple esta carpeta con Platform?

## Carpeta

$ARGUMENTS

## Qué haces

1. Ejecuta el script de hechos sobre la carpeta (si está vacía, `.`):

   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate/facts.sh" <carpeta>`

   Si falla, para y explica el motivo en una frase.
2. Delega en el agente `dotnet-team:platform-reviewer`. Pásale la carpeta, la ruta de las reglas (`${CLAUDE_PLUGIN_ROOT}/references/platform-rules.md`) y la tabla de hechos completa, tal cual. No revises tú: el agente es el experto.
3. Escribe su respuesta, sin tocarla, en `.work/validate.md`.
4. No modificas nada más. Un hook lo impide.

## Al terminar

Resume en cuatro líneas como máximo: veredicto, número de hallazgos por severidad y los dos más importantes. Si hay hallazgos de capas, build o tests, sugiere `/dotnet-team:guardrails`.

Cuando termines, una puerta automática comprueba que cada hallazgo cita una regla existente, con severidad válida y un fichero que existe, y que el veredicto es coherente.
