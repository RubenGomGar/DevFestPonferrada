#!/usr/bin/env bash
# PreToolUse (Edit|Write): decide si una escritura está permitida ANTES de que ocurra.
# Exit 2 bloquea la herramienta y el texto de stderr llega al agente como motivo.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

input="$(cat)"
file="$(printf '%s' "$input" | json_str file_path | sed -E 's#[\\]+#/#g')"
[ -n "$file" ] || exit 0
rel="$(to_relative "$file")"
phase="$(phase_get)"

deny() {
  echo "dotnet-team guard: $1" >&2
  echo "Fichero: $rel" >&2
  exit 2
}

case "$rel" in .work/*) exit 0 ;; esac

if is_guardrail_path "$rel"; then
  deny "es un guardarraíl (build, estilo o arquitectura). Arregla el código, no la regla. Cambiar la regla es una decisión humana."
fi

if printf '%s' "$input" | grep -Eq '#pragma warning disable|<NoWarn>|SuppressMessage\('; then
  deny "no se silencian avisos del compilador ni de analizadores. Corrige la causa."
fi

case "$rel" in
  *appsettings*.json)
    if printf '%s' "$input" | grep -Eiq '(Server|Data Source|User Id|Password|AccountKey)='; then
      deny "las connection strings no van en appsettings. Aspire las inyecta por nombre."
    fi ;;
esac

case "$phase" in
  plan)
    is_acceptance_test_path "$rel" ||
      deny "en /plan solo se escribe .work/plan.md y tests de aceptación (tests/*AcceptanceTests*/). El plan no implementa." ;;
  validate)
    deny "/validate es de solo lectura: el informe va en .work/validate.md." ;;
esac

exit 0
