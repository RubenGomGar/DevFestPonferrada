#!/usr/bin/env bash
# Contexto y precondiciones de /dotnet-team:plan. Se inyecta antes de que el modelo lea nada.
# Precondición: la base compila y los tests de arquitectura están en verde.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

fail() {
  echo "PRECONDICIÓN FALLIDA: $1"
  echo
  echo "No hagas el plan. Explica el motivo en una frase y sugiere /dotnet-team:validate o /dotnet-team:guardrails."
  exit 0
}

git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || fail "$PROJECT_DIR no es un repositorio git."
SLN="$(find_solution)" || fail "no hay ninguna solución .slnx/.sln en la raíz."
ARCH="$(find_test_project ArchitectureTests)"
ACC="$(find_test_project AcceptanceTests)"
[ -n "$ARCH" ] || fail "no hay proyecto tests/*ArchitectureTests: sin guardarraíles ejecutables no hay plan."
[ -n "$ACC" ] || fail "no hay proyecto tests/*AcceptanceTests donde escribir los tests del plan."

if [ -n "$(changed_files)" ]; then
  fail "hay cambios sin commitear. El plan parte de una base limpia: haz commit o stash."
fi

ensure_work_dir
if [ -f "$PLAN_FILE" ]; then
  mkdir -p "$WORK_DIR/archive"
  mv "$PLAN_FILE" "$WORK_DIR/archive/plan-$(date +%Y%m%d-%H%M%S).md"
fi

dotnet build "$SLN" -nologo -v q > "$WORK_DIR/precondition.log" 2>&1 || fail "la solución no compila (ver .work/precondition.log)."
dotnet test "$ARCH" --no-build -nologo -v q >> "$WORK_DIR/precondition.log" 2>&1 || fail "los tests de arquitectura están en rojo (ver .work/precondition.log)."

phase_set plan

echo "✔ Precondición: la solución compila y los tests de arquitectura están en verde."
echo
echo "- Solución: \`$(basename "$SLN")\`"
echo "- Rama: \`$(git -C "$PROJECT_DIR" branch --show-current)\` · commit \`$(git -C "$PROJECT_DIR" rev-parse --short HEAD)\`"
echo "- Repositorio GitHub: \`$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null | sed -E 's#(\.git)?$##; s#.*github.com[:/]##')\`"
echo "- Tests de aceptación: \`$(to_relative "$(dirname "$ACC")")/\`"
echo
echo "Slices existentes (patrón de referencia):"
found=0
for d in "$PROJECT_DIR"/src/*.Application/Features/*/*/; do
  [ -d "$d" ] || continue
  found=1
  echo "- \`$(to_relative "${d%/}")\`"
done
[ "$found" = 0 ] && echo "- (ninguno)"
echo
echo "Tests de aceptación existentes:"
find "$(dirname "$ACC")/Features" -name '*.cs' 2>/dev/null | while read -r f; do echo "- \`$(to_relative "$f")\`"; done
