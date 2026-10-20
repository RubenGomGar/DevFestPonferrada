#!/usr/bin/env bash
# headersHelper del MCP de GitHub: reutiliza la sesión de `gh auth login`, sin tokens propios.
token="$(gh auth token 2>/dev/null)" || { echo "dotnet-team: ejecuta 'gh auth login' para usar el MCP de GitHub" >&2; exit 1; }
printf '{"Authorization":"Bearer %s"}' "$token"
