#!/usr/bin/env bash
# Contexto y precondiciones de /dotnet-team:apply. Se inyecta antes de que el modelo lea nada.
# Precondición: plan aprobado, base limpia y en verde, y los tests del plan compilan y FALLAN todos (TDD).
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

created=()
fail() {
  local p
  for p in "${created[@]}"; do rm -f "$PROJECT_DIR/$p"; done
  echo "PRECONDICIÓN FALLIDA: $1"
  echo
  echo "No implementes nada. Explica el motivo en una frase; si el plan está mal, sugiere /dotnet-team:plan <issue>."
  exit 0
}

git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || fail "$PROJECT_DIR no es un repositorio git."
[ -f "$PLAN_FILE" ] || fail "no hay .work/plan.md. Empieza por /dotnet-team:plan <issue>."
status="$(frontmatter_value "$PLAN_FILE" status)"
[ "$status" = "approved" ] || fail "el plan está en '$status'. Lo aprueba una persona cambiando 'status: draft' por 'status: approved'."
SLN="$(find_solution)" || fail "no hay ninguna solución .slnx/.sln en la raíz."
ARCH="$(find_test_project ArchitectureTests)"
ACC="$(find_test_project AcceptanceTests)"
[ -n "$ARCH" ] || fail "no hay proyecto tests/*ArchitectureTests."
[ -n "$ACC" ] || fail "no hay proyecto tests/*AcceptanceTests."

if [ -n "$(changed_files)" ]; then
  fail "hay cambios sin commitear. /apply parte de una base limpia: haz commit o stash."
fi

ensure_work_dir
log="$WORK_DIR/precondition.log"
dotnet build "$SLN" -nologo -v q > "$log" 2>&1 || fail "la solución no compila (ver .work/precondition.log)."
dotnet test "$ARCH" --no-build -nologo -v q >> "$log" 2>&1 || fail "los tests de arquitectura están en rojo (ver .work/precondition.log)."

# Los tests del plan, a su sitio. La copia de .work/apply/tests es la versión aprobada.
stage="$WORK_DIR/apply/tests"
rm -rf "$WORK_DIR/apply"; mkdir -p "$stage"
extract_plan_tests "$stage"
paths=()
while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done < <(plan_test_paths)
[ ${#paths[@]} -ge 1 ] || fail "el plan no define tests de aceptación."
for p in "${paths[@]}"; do
  case "$p" in *..*) fail "'$p' no es una ruta válida." ;; esac
  is_acceptance_test_path "$p" || fail "'$p' no está en tests/*AcceptanceTests*/."
  [ ! -e "$PROJECT_DIR/$p" ] || fail "'$p' ya existe; el plan solo define ficheros de test nuevos."
  mkdir -p "$PROJECT_DIR/$(dirname "$p")"
  cp "$stage/$p" "$PROJECT_DIR/$p"
  created+=("$p")
done

# Rojo: compilan y fallan todos
dotnet build "$SLN" -nologo -v q >> "$log" 2>&1 || fail "los tests del plan no compilan (ver .work/precondition.log). Se corrigen en /dotnet-team:plan."
filter="$(test_class_filter "${paths[@]/#/$PROJECT_DIR/}")"
run_tests_trx "$ACC" "$WORK_DIR/apply/red" "$filter" || fail "no se han podido ejecutar los tests del plan (ver .work/apply/red.log)."
if [ -n "$TRX_PASSED" ]; then
  fail "estos tests del plan ya pasan, así que no describen nada nuevo: $(printf '%s\n' "$TRX_PASSED" | paste -sd',' | sed 's/,/, /g')."
fi
red="$(printf '%s\n' "$TRX_FAILED" | grep -c .)"
[ "$red" -ge 1 ] || fail "el filtro '$filter' no ha ejecutado ningún test."

printf '%s\n' "${paths[@]}" > "$WORK_DIR/apply/paths"
phase_set apply

echo "✔ Precondición: plan aprobado (issue #$(frontmatter_value "$PLAN_FILE" issue)); la solución compila y la arquitectura está en verde."
echo "✔ Rojo: $red tests del plan compilan y fallan hoy."
echo
echo "Tests del plan, ya en su sitio (son el contrato; no se tocan):"
for p in "${paths[@]}"; do echo "- \`$p\`"; done
echo
echo "Slices existentes (patrón de referencia):"
found=0
for d in "$PROJECT_DIR"/src/*.Application/Features/*/*/; do
  [ -d "$d" ] || continue
  found=1
  echo "- \`$(to_relative "${d%/}")\`"
done
[ "$found" = 0 ] && echo "- (ninguno)"
