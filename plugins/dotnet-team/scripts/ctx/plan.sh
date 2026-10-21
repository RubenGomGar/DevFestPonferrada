#!/usr/bin/env bash
# Qué hace: comprueba las precondiciones de /plan (repo git, solución, proyectos de tests, base limpia, compila y arquitectura en verde) y escribe el contexto precalculado.
# Para qué sirve: lo ejecuta la inyección `!` de /dotnet-team:plan antes de que el modelo lea nada; si algo falla, el modelo no planifica.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

fail() {
  echo "PRECONDITION FAILED: $1"
  echo
  echo "Do not write the plan. Explain the reason in one sentence and suggest /dotnet-team:validate or /dotnet-team:guardrails."
  exit 0
}

git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || fail "$PROJECT_DIR is not a git repository."
SLN="$(find_solution)" || fail "there is no .slnx/.sln solution at the root."
ARCH="$(find_test_project ArchitectureTests)"
ACC="$(find_test_project AcceptanceTests)"
[ -n "$ARCH" ] || fail "there is no tests/*ArchitectureTests project: no executable guardrails, no plan."
[ -n "$ACC" ] || fail "there is no tests/*AcceptanceTests project to write the plan tests in."

if [ -n "$(changed_files)" ]; then
  fail "there are uncommitted changes. The plan starts from a clean base: commit or stash."
fi

ensure_work_dir
if [ -f "$PLAN_FILE" ]; then
  mkdir -p "$WORK_DIR/archive"
  mv "$PLAN_FILE" "$WORK_DIR/archive/plan-$(date +%Y%m%d-%H%M%S).md"
fi

dotnet build "$SLN" -nologo -v q > "$WORK_DIR/precondition.log" 2>&1 || fail "the solution does not build (see .work/precondition.log)."
dotnet test "$ARCH" --no-build -nologo -v q >> "$WORK_DIR/precondition.log" 2>&1 || fail "the architecture tests are red (see .work/precondition.log)."

phase_set plan

echo "✔ Precondition: the solution builds and the architecture tests are green."
echo
echo "- Solution: \`$(basename "$SLN")\`"
echo "- Branch: \`$(git -C "$PROJECT_DIR" branch --show-current)\` · commit \`$(git -C "$PROJECT_DIR" rev-parse --short HEAD)\`"
echo "- GitHub repository: \`$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null | sed -E 's#(\.git)?$##; s#.*github.com[:/]##')\`"
echo "- Acceptance tests: \`$(to_relative "$(dirname "$ACC")")/\`"
echo
echo "Existing slices (reference pattern):"
found=0
for d in "$PROJECT_DIR"/src/*.Application/Features/*/*/; do
  [ -d "$d" ] || continue
  found=1
  echo "- \`$(to_relative "${d%/}")\`"
done
[ "$found" = 0 ] && echo "- (none)"
echo
echo "Existing acceptance tests:"
find "$(dirname "$ACC")/Features" -name '*.cs' 2>/dev/null | while read -r f; do echo "- \`$(to_relative "$f")\`"; done
