#!/usr/bin/env bash
# Puerta de /validate: el informe tiene la forma del contrato y es coherente con las reglas.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

RULES="$PLUGIN_ROOT/references/platform-rules.md"
errors=()
[ -f "$VALIDATE_FILE" ] || { echo "✖ No existe .work/validate.md"; exit 1; }

target="$(cat "$WORK_DIR/validate-target" 2>/dev/null)"
verdict="$(frontmatter_value "$VALIDATE_FILE" verdict)"
case "$verdict" in NO_CUMPLE|CUMPLE_CON_AVISOS|CUMPLE) ;; *) errors+=("verdict debe ser NO_CUMPLE, CUMPLE_CON_AVISOS o CUMPLE (ahora: '$verdict')") ;; esac
grep -qx "## Hallazgos" "$VALIDATE_FILE" || errors+=("falta la sección '## Hallazgos'")

rows="$(awk '/^## Hallazgos/{f=1;next} /^## /{f=0} f && /^\| *[A-Z]+-[A-Z0-9-]+ *\|/' "$VALIDATE_FILE")"
altas=0; total=0
while IFS= read -r row; do
  [ -n "$row" ] || continue
  total=$((total + 1))
  id="$(echo "$row" | awk -F'|' '{gsub(/ /,"",$2); print $2}')"
  sev="$(echo "$row" | awk -F'|' '{gsub(/ /,"",$3); print $3}')"
  file="$(echo "$row" | awk -F'|' '{gsub(/^ +| +$|`/,"",$4); print $4}')"
  cols="$(echo "$row" | awk -F'|' '{print NF-2}')"
  grep -q "^| $id |" "$RULES" || errors+=("$id no existe en references/platform-rules.md")
  case "$sev" in alta) altas=$((altas + 1)) ;; media|baja) ;; *) errors+=("$id: severidad '$sev' no válida (alta|media|baja)") ;; esac
  [ "$cols" -eq 5 ] || errors+=("$id: la fila debe tener 5 columnas (tiene $cols)")
  if [ -n "$file" ] && [ "$file" != "—" ] && [ "$file" != "-" ]; then
    [ -e "$target/$file" ] || [ -e "$PROJECT_DIR/$file" ] || errors+=("$id: el fichero '$file' no existe")
  fi
done <<< "$rows"

if [ "$altas" -gt 0 ] && [ "$verdict" != "NO_CUMPLE" ]; then errors+=("hay $altas hallazgos de severidad alta: el veredicto debe ser NO_CUMPLE"); fi
if [ "$altas" -eq 0 ] && [ "$verdict" = "NO_CUMPLE" ]; then errors+=("NO_CUMPLE exige al menos un hallazgo de severidad alta"); fi
if [ "$total" -eq 0 ] && [ "$verdict" != "CUMPLE" ]; then errors+=("sin hallazgos el veredicto es CUMPLE"); fi
if [ "$total" -gt 0 ] && [ "$verdict" = "CUMPLE" ]; then errors+=("CUMPLE no admite hallazgos"); fi

if [ ${#errors[@]} -gt 0 ]; then
  echo "✖ El informe no cumple el contrato (.work/validate.md):"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi
echo "✔ Informe válido: $verdict, $total hallazgos ($altas de severidad alta)."
