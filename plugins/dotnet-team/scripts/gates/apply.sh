#!/usr/bin/env bash
# Puerta de /apply: lo implementado compila, la arquitectura sigue en verde, TODOS los tests pasan
# (los del plan y los que ya había) y los tests del plan siguen siendo los aprobados.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

errors=()
[ -f "$WORK_DIR/apply/paths" ] || { echo "✖ Falta .work/apply/paths: lanza /dotnet-team:apply desde el principio."; exit 1; }
paths=()
while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done < "$WORK_DIR/apply/paths"

# 1. Los tests del plan son el contrato: idénticos a los aprobados
for p in "${paths[@]}"; do
  cmp -s "$WORK_DIR/apply/tests/$p" "$PROJECT_DIR/$p" ||
    errors+=("'$p' no es el test aprobado en el plan. No se cambia para que pase; si está mal, vuelve a /dotnet-team:plan")
done

# 2. Solo se toca src/, tests unitarios y los tests del plan
while IFS= read -r f; do
  [ -n "$f" ] || continue
  printf '%s\n' "${paths[@]}" | grep -qxF "$f" && continue
  case "$f" in
    src/*|tests/*UnitTests*/*) ;;
    *) errors+=("'$f' está fuera de lo que /apply puede tocar (src/ y tests unitarios)") ;;
  esac
done < <(changed_files)

if [ ${#errors[@]} -gt 0 ]; then
  echo "✖ La implementación no respeta el plan:"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi

# 3. Compila y la arquitectura sigue en verde
mkdir -p "$WORK_DIR/gate"
SLN="$(find_solution)"
ARCH="$(find_test_project ArchitectureTests)"
if ! dotnet build "$SLN" -nologo -v q > "$WORK_DIR/gate/build.log" 2>&1; then
  echo "✖ La solución no compila."
  grep -E 'error' "$WORK_DIR/gate/build.log" | sed -E 's/ \[.*//' | sort -u | head -n 15
  exit 1
fi
if ! dotnet test "$ARCH" --no-build -nologo -v q > "$WORK_DIR/gate/arch.log" 2>&1; then
  echo "✖ Los tests de arquitectura se han puesto en rojo."
  grep -E 'Failed|Error Message' -A2 "$WORK_DIR/gate/arch.log" | head -n 20
  exit 1
fi

# 4. Verde: todos los tests de la solución pasan
run_tests_trx "$SLN" "$WORK_DIR/gate/green" ||
  { echo "✖ No se han podido ejecutar los tests (ver .work/gate/green.log)."; tail -n 15 "$WORK_DIR/gate/green.log"; exit 1; }
if [ -n "$TRX_FAILED" ]; then
  echo "✖ Estos tests fallan:"
  printf '%s\n' "$TRX_FAILED" | sed 's/^/  - /'
  exit 1
fi

classes="$(test_class_filter "${paths[@]/#/$PROJECT_DIR/}" | sed 's/FullyQualifiedName~//g')"
plan_green="$(printf '%s\n' "$TRX_PASSED" | grep -cE "\.($classes)\.")"
total="$(printf '%s\n' "$TRX_PASSED" | grep -c .)"
echo "✔ Implementación válida: compila, arquitectura en verde y $total tests en verde ($plan_green del plan)."
