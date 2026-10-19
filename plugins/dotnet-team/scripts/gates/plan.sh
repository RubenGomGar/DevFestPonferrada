#!/usr/bin/env bash
# Puerta de /plan (TDD): el plan tiene la forma del contrato y los tests de aceptación nuevos
# compilan, FALLAN todos y no rompen la arquitectura. No juzga si el plan es bueno: eso es humano.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

errors=()
[ -f "$PLAN_FILE" ] || { echo "✖ No existe .work/plan.md"; exit 1; }

# 1. Forma del plan
issue="$(frontmatter_value "$PLAN_FILE" issue)"
feature="$(frontmatter_value "$PLAN_FILE" feature)"
status="$(frontmatter_value "$PLAN_FILE" status)"
[[ "$issue" =~ ^[0-9]+$ ]] || errors+=("frontmatter 'issue' debe ser el número de la issue (ahora: '$issue')")
[[ "$feature" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || errors+=("frontmatter 'feature' debe ser kebab-case (ahora: '$feature')")
[ "$status" = "draft" ] || errors+=("el plan se entrega con 'status: draft'; lo aprueba una persona (ahora: '$status')")
for section in "## Objetivo" "## Guardarraíles aplicados" "## Tareas" "## Tests de aceptación" "## Fuera de alcance"; do
  grep -qx "$section" "$PLAN_FILE" || errors+=("falta la sección '$section'")
done
tasks="$(grep -cE '^### T[0-9]+ · [A-Z][A-Za-z0-9]+ · (command|query)$' "$PLAN_FILE")"
[ "$tasks" -ge 1 ] || errors+=("no hay tareas con el formato '### T1 · NombreSlice · command|query'")
[ "$tasks" -le 6 ] || errors+=("$tasks tareas es demasiado para una issue; divídela (máximo 6)")
for field in "- Capas:" "- Ficheros:" "- Contrato HTTP:" "- Tests:"; do
  n="$(grep -c "^$field" "$PLAN_FILE")"
  [ "$n" -ge "$tasks" ] || errors+=("cada tarea necesita '$field' ($n de $tasks)")
done

# 2. El plan no implementa: solo tests de aceptación fuera de .work/
new_tests=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if is_acceptance_test_path "$f"; then new_tests+=("$f"); else errors+=("el plan ha modificado '$f'; solo puede escribir tests de aceptación"); fi
done < <(changed_files)
[ ${#new_tests[@]} -ge 1 ] || errors+=("no hay tests de aceptación nuevos en tests/*AcceptanceTests*/")

if [ ${#errors[@]} -gt 0 ]; then
  echo "✖ El plan no cumple el contrato:"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi

# 3. Compila y la arquitectura sigue en verde
mkdir -p "$WORK_DIR/gate"
SLN="$(find_solution)"
ARCH="$(find_test_project ArchitectureTests)"
ACC="$(find_test_project AcceptanceTests)"
if ! dotnet build "$SLN" -nologo -v q > "$WORK_DIR/gate/build.log" 2>&1; then
  echo "✖ Los tests nuevos no compilan. Habla solo HTTP/JSON; no uses tipos de src/ que aún no existen."
  grep -E 'error' "$WORK_DIR/gate/build.log" | sed -E 's/ \[.*//' | sort -u | head -n 15
  exit 1
fi
if ! dotnet test "$ARCH" --no-build -nologo -v q > "$WORK_DIR/gate/arch.log" 2>&1; then
  echo "✖ Los tests de arquitectura se han puesto en rojo."
  grep -E 'Failed|Error Message' -A2 "$WORK_DIR/gate/arch.log" | head -n 20
  exit 1
fi

# 4. TDD: cada test nuevo falla (describe comportamiento que aún no existe)
classes="$(grep -hoE 'class [A-Z][A-Za-z0-9_]*' "${new_tests[@]/#/$PROJECT_DIR/}" | awk '{print $2}' | sort -u)"
filter="$(printf '%s\n' $classes | sed 's/^/FullyQualifiedName~/' | paste -sd'|')"
trx_dir="$WORK_DIR/gate/trx"
rm -rf "$trx_dir"
dotnet test "$ACC" --no-build -nologo -v q --filter "$filter" --results-directory "$trx_dir" --logger "trx;LogFileName=plan.trx" > "$WORK_DIR/gate/acceptance.log" 2>&1
trx="$trx_dir/plan.trx"
[ -f "$trx" ] || { echo "✖ No se han podido ejecutar los tests de aceptación (ver .work/gate/acceptance.log)."; tail -n 15 "$WORK_DIR/gate/acceptance.log"; exit 1; }

failed="$(grep -oE '<UnitTestResult [^>]*outcome="Failed"' "$trx" | wc -l | tr -d ' ')"
passed_names="$(grep -oE '<UnitTestResult [^>]*testName="[^"]*"[^>]*outcome="Passed"' "$trx" | sed -E 's/.*testName="([^"]*)".*/\1/')"
if [ "$failed" -eq 0 ] && [ -z "$passed_names" ]; then
  echo "✖ El filtro '$filter' no ha ejecutado ningún test."
  exit 1
fi
if [ -n "$passed_names" ]; then
  echo "✖ Estos tests nuevos ya pasan, así que no describen nada nuevo. Ajústalos al comportamiento de la issue:"
  printf '%s\n' "$passed_names" | sed 's/^/  - /'
  exit 1
fi

echo "✔ Plan válido: $tasks tareas, $failed tests de aceptación en rojo, arquitectura en verde."
