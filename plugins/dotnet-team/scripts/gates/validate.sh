#!/usr/bin/env bash
# Qué hace: puerta de /validate; comprueba que .work/validate.md tiene la forma del contrato, que cada hallazgo cita una regla existente con severidad válida y un fichero que existe, y que el veredicto es coherente.
# Para qué sirve: la ejecuta el hook Stop (stop-gate.sh) cuando la fase activa es `validate`; si falla, el turno no termina y el agente recibe el motivo.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

RULES="$PLUGIN_ROOT/references/platform-rules.md"
errors=()
[ -f "$VALIDATE_FILE" ] || { echo "✖ .work/validate.md does not exist"; exit 1; }

target="$(cat "$WORK_DIR/validate-target" 2>/dev/null)"
verdict="$(frontmatter_value "$VALIDATE_FILE" verdict)"
case "$verdict" in NON_COMPLIANT|COMPLIANT_WITH_WARNINGS|COMPLIANT) ;; *) errors+=("verdict must be NON_COMPLIANT, COMPLIANT_WITH_WARNINGS or COMPLIANT (now: '$verdict')") ;; esac
grep -qx "## Findings" "$VALIDATE_FILE" || errors+=("section '## Findings' is missing")

rows="$(awk '/^## Findings/{f=1;next} /^## /{f=0} f && /^\| *[A-Z]+-[A-Z0-9-]+ *\|/' "$VALIDATE_FILE")"
highs=0; total=0
while IFS= read -r row; do
  [ -n "$row" ] || continue
  total=$((total + 1))
  id="$(echo "$row" | awk -F'|' '{gsub(/ /,"",$2); print $2}')"
  sev="$(echo "$row" | awk -F'|' '{gsub(/ /,"",$3); print $3}')"
  file="$(echo "$row" | awk -F'|' '{gsub(/^ +| +$|`/,"",$4); print $4}')"
  cols="$(echo "$row" | awk -F'|' '{print NF-2}')"
  grep -q "^| $id |" "$RULES" || errors+=("$id does not exist in references/platform-rules.md")
  case "$sev" in high) highs=$((highs + 1)) ;; medium|low) ;; *) errors+=("$id: invalid severity '$sev' (high|medium|low)") ;; esac
  [ "$cols" -eq 5 ] || errors+=("$id: the row must have 5 columns (it has $cols)")
  if [ -n "$file" ] && [ "$file" != "—" ] && [ "$file" != "-" ]; then
    [ -e "$target/$file" ] || [ -e "$PROJECT_DIR/$file" ] || errors+=("$id: file '$file' does not exist")
  fi
done <<< "$rows"

if [ "$highs" -gt 0 ] && [ "$verdict" != "NON_COMPLIANT" ]; then errors+=("there are $highs high-severity findings: the verdict must be NON_COMPLIANT"); fi
if [ "$highs" -eq 0 ] && [ "$verdict" = "NON_COMPLIANT" ]; then errors+=("NON_COMPLIANT requires at least one high-severity finding"); fi
if [ "$total" -eq 0 ] && [ "$verdict" != "COMPLIANT" ]; then errors+=("with no findings the verdict is COMPLIANT"); fi
if [ "$total" -gt 0 ] && [ "$verdict" = "COMPLIANT" ]; then errors+=("COMPLIANT allows no findings"); fi

if [ ${#errors[@]} -gt 0 ]; then
  echo "✖ The report does not meet the contract (.work/validate.md):"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi
echo "✔ Valid report: $verdict, $total findings ($highs high-severity)."
