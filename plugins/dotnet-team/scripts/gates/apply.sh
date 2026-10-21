#!/usr/bin/env bash
# Qué hace: puerta de /apply; comprueba que los tests del plan siguen siendo los aprobados, que solo se ha tocado src/ y tests unitarios, que compila, que la arquitectura sigue en verde y que pasan TODOS los tests.
# Para qué sirve: la ejecuta el hook Stop (stop-gate.sh) cuando la fase activa es `apply`; si falla, el turno no termina y el agente recibe el motivo.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

errors=()
[ -f "$WORK_DIR/apply/paths" ] || { echo "✖ .work/apply/paths is missing: run /dotnet-team:apply from the start."; exit 1; }
paths=()
while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done < "$WORK_DIR/apply/paths"

# 1. The plan tests are the contract: identical to the approved ones
for p in "${paths[@]}"; do
  cmp -s "$WORK_DIR/apply/tests/$p" "$PROJECT_DIR/$p" ||
    errors+=("'$p' is not the test approved in the plan. It is not changed to make it pass; if it is wrong, go back to /dotnet-team:plan")
done

# 2. Only src/, unit tests and the plan tests are touched
while IFS= read -r f; do
  [ -n "$f" ] || continue
  printf '%s\n' "${paths[@]}" | grep -qxF "$f" && continue
  case "$f" in
    src/*|tests/*UnitTests*/*) ;;
    *) errors+=("'$f' is outside what /apply may touch (src/ and unit tests)") ;;
  esac
done < <(changed_files)

if [ ${#errors[@]} -gt 0 ]; then
  echo "✖ The implementation does not respect the plan:"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi

# 3. It builds and the architecture is still green
mkdir -p "$WORK_DIR/gate"
SLN="$(find_solution)"
ARCH="$(find_test_project ArchitectureTests)"
if ! dotnet build "$SLN" -nologo -v q > "$WORK_DIR/gate/build.log" 2>&1; then
  echo "✖ The solution does not build."
  grep -E 'error' "$WORK_DIR/gate/build.log" | sed -E 's/ \[.*//' | sort -u | head -n 15
  exit 1
fi
if ! dotnet test "$ARCH" --no-build -nologo -v q > "$WORK_DIR/gate/arch.log" 2>&1; then
  echo "✖ The architecture tests have turned red."
  grep -E 'Failed|Error Message' -A2 "$WORK_DIR/gate/arch.log" | head -n 20
  exit 1
fi

# 4. Green: every test in the solution passes
run_tests_trx "$SLN" "$WORK_DIR/gate/green" ||
  { echo "✖ The tests could not be run (see .work/gate/green.log)."; tail -n 15 "$WORK_DIR/gate/green.log"; exit 1; }
if [ -n "$TRX_FAILED" ]; then
  echo "✖ These tests fail:"
  printf '%s\n' "$TRX_FAILED" | sed 's/^/  - /'
  exit 1
fi

classes="$(test_class_filter "${paths[@]/#/$PROJECT_DIR/}" | sed 's/FullyQualifiedName~//g')"
plan_green="$(printf '%s\n' "$TRX_PASSED" | grep -cE "\.($classes)\.")"
total="$(printf '%s\n' "$TRX_PASSED" | grep -c .)"
echo "✔ Valid implementation: it builds, architecture is green and $total tests are green ($plan_green from the plan)."
