#!/usr/bin/env bash
# Qué hace: comprueba las precondiciones de /apply (plan aprobado, base limpia, compila, arquitectura en verde), copia los tests del plan a su sitio y verifica que compilan y fallan todos (rojo TDD).
# Para qué sirve: lo ejecuta la inyección `!` de /dotnet-team:apply antes de que el modelo lea nada; deja .work/apply/ con la copia aprobada que luego usa la puerta de /apply.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

created=()
fail() {
  local p
  for p in "${created[@]}"; do rm -f "$PROJECT_DIR/$p"; done
  echo "PRECONDITION FAILED: $1"
  echo
  echo "Do not implement anything. Explain the reason in one sentence; if the plan is wrong, suggest /dotnet-team:plan <issue>."
  exit 0
}

git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || fail "$PROJECT_DIR is not a git repository."
[ -f "$PLAN_FILE" ] || fail "there is no .work/plan.md. Start with /dotnet-team:plan <issue>."
status="$(frontmatter_value "$PLAN_FILE" status)"
[ "$status" = "approved" ] || fail "the plan is '$status'. A person approves it by changing 'status: draft' to 'status: approved'."
SLN="$(find_solution)" || fail "there is no .slnx/.sln solution at the root."
ARCH="$(find_test_project ArchitectureTests)"
ACC="$(find_test_project AcceptanceTests)"
[ -n "$ARCH" ] || fail "there is no tests/*ArchitectureTests project."
[ -n "$ACC" ] || fail "there is no tests/*AcceptanceTests project."

if [ -n "$(changed_files)" ]; then
  fail "there are uncommitted changes. /apply starts from a clean base: commit or stash."
fi

ensure_work_dir
log="$WORK_DIR/precondition.log"
dotnet build "$SLN" -nologo -v q > "$log" 2>&1 || fail "the solution does not build (see .work/precondition.log)."
dotnet test "$ARCH" --no-build -nologo -v q >> "$log" 2>&1 || fail "the architecture tests are red (see .work/precondition.log)."

# The plan tests, into place. The copy in .work/apply/tests is the approved version.
stage="$WORK_DIR/apply/tests"
rm -rf "$WORK_DIR/apply"; mkdir -p "$stage"
extract_plan_tests "$stage"
paths=()
while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done < <(plan_test_paths)
[ ${#paths[@]} -ge 1 ] || fail "the plan defines no acceptance tests."
for p in "${paths[@]}"; do
  case "$p" in *..*) fail "'$p' is not a valid path." ;; esac
  is_acceptance_test_path "$p" || fail "'$p' is not under tests/*AcceptanceTests*/."
  [ ! -e "$PROJECT_DIR/$p" ] || fail "'$p' already exists; the plan only defines new test files."
  mkdir -p "$PROJECT_DIR/$(dirname "$p")"
  cp "$stage/$p" "$PROJECT_DIR/$p"
  created+=("$p")
done

# Red: they all compile and fail
dotnet build "$SLN" -nologo -v q >> "$log" 2>&1 || fail "the plan tests do not compile (see .work/precondition.log). They get fixed in /dotnet-team:plan."
filter="$(test_class_filter "${paths[@]/#/$PROJECT_DIR/}")"
run_tests_trx "$ACC" "$WORK_DIR/apply/red" "$filter" || fail "the plan tests could not be run (see .work/apply/red.log)."
if [ -n "$TRX_PASSED" ]; then
  fail "these plan tests already pass, so they describe nothing new: $(printf '%s\n' "$TRX_PASSED" | paste -sd',' | sed 's/,/, /g')."
fi
red="$(printf '%s\n' "$TRX_FAILED" | grep -c .)"
[ "$red" -ge 1 ] || fail "the filter '$filter' ran no tests."

printf '%s\n' "${paths[@]}" > "$WORK_DIR/apply/paths"
phase_set apply

echo "✔ Precondition: plan approved (issue #$(frontmatter_value "$PLAN_FILE" issue)); the solution builds and the architecture is green."
echo "✔ Red: $red plan tests compile and fail today."
echo
echo "Plan tests, already in place (they are the contract; do not touch them):"
for p in "${paths[@]}"; do echo "- \`$p\`"; done
echo
echo "Existing slices (reference pattern):"
found=0
for d in "$PROJECT_DIR"/src/*.Application/Features/*/*/; do
  [ -d "$d" ] || continue
  found=1
  echo "- \`$(to_relative "${d%/}")\`"
done
[ "$found" = 0 ] && echo "- (none)"
