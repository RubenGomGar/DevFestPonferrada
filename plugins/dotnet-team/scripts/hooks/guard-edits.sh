#!/usr/bin/env bash
# Qué hace: decide si una escritura (Edit|Write) está permitida ANTES de que ocurra: protege los guardarraíles, impide silenciar avisos y connection strings en appsettings, y limita qué se escribe según la fase activa (plan, apply, validate).
# Para qué sirve: es el hook PreToolUse del plugin; con exit 2 bloquea la herramienta y el texto de stderr le llega al agente como motivo.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

input="$(cat)"
file="$(printf '%s' "$input" | json_str file_path | sed -E 's#[\\]+#/#g')"
[ -n "$file" ] || exit 0
rel="$(to_relative "$file")"
phase="$(phase_get)"

deny() {
  echo "dotnet-team guard: $1" >&2
  echo "File: $rel" >&2
  exit 2
}

case "$rel" in .work/*) exit 0 ;; esac

if is_guardrail_path "$rel"; then
  deny "it is a guardrail (build, style or architecture). Fix the code, not the rule. Changing the rule is a human decision."
fi

if printf '%s' "$input" | grep -Eq '#pragma warning disable|<NoWarn>|SuppressMessage\('; then
  deny "compiler and analyzer warnings are not silenced. Fix the cause."
fi

case "$rel" in
  *appsettings*.json)
    if printf '%s' "$input" | grep -Eiq '(Server|Data Source|User Id|Password|AccountKey)='; then
      deny "connection strings do not go in appsettings. Aspire injects them by name."
    fi ;;
esac

case "$phase" in
  plan)
    deny "in /plan only .work/plan.md is written; the acceptance tests go inside the plan. The plan does not implement." ;;
  apply)
    case "$rel" in
      src/*|tests/*UnitTests*/*) ;;
      tests/*AcceptanceTests*/*)
        deny "the plan's acceptance tests are the contract: they are not changed to make them pass. If they are wrong, go back to /dotnet-team:plan." ;;
      *) deny "in /apply only src/ and unit tests are written." ;;
    esac ;;
  validate)
    deny "/validate is read-only: the report goes in .work/validate.md." ;;
esac

exit 0
