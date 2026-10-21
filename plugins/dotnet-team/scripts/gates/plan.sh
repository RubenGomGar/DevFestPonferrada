#!/usr/bin/env bash
# Qué hace: puerta de /plan; comprueba la forma del plan (frontmatter, secciones, tareas y campos) y que los tests de aceptación escritos dentro siguen las convenciones de dotnet-testing. No compila ni ejecuta, y no juzga si el plan es bueno.
# Para qué sirve: la ejecuta el hook Stop (stop-gate.sh) cuando la fase activa es `plan`; si falla, el turno no termina y el agente recibe el motivo. /apply comprobará luego que los tests están en rojo.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

errors=()
[ -f "$PLAN_FILE" ] || { echo "✖ .work/plan.md does not exist"; exit 1; }

# 1. Shape of the plan
issue="$(frontmatter_value "$PLAN_FILE" issue)"
feature="$(frontmatter_value "$PLAN_FILE" feature)"
status="$(frontmatter_value "$PLAN_FILE" status)"
[[ "$issue" =~ ^[0-9]+$ ]] || errors+=("frontmatter 'issue' must be the issue number (now: '$issue')")
[[ "$feature" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || errors+=("frontmatter 'feature' must be kebab-case (now: '$feature')")
[ "$status" = "draft" ] || errors+=("the plan is delivered with 'status: draft'; a person approves it (now: '$status')")
for section in "## Goal" "## Guardrails applied" "## Tasks" "## Acceptance tests" "## Out of scope"; do
  grep -qx "$section" "$PLAN_FILE" || errors+=("section '$section' is missing")
done
tasks="$(grep -cE '^### T[0-9]+ · [A-Z][A-Za-z0-9]+ · (command|query)$' "$PLAN_FILE")"
[ "$tasks" -ge 1 ] || errors+=("there are no tasks in the format '### T1 · SliceName · command|query'")
[ "$tasks" -le 6 ] || errors+=("$tasks tasks is too much for one issue; split it (6 at most)")
for field in "- Layers:" "- Files:" "- HTTP contract:" "- Tests:"; do
  n="$(grep -c "^$field" "$PLAN_FILE")"
  [ "$n" -ge "$tasks" ] || errors+=("every task needs '$field' ($n of $tasks)")
done

# 2. The plan neither implements nor creates files: everything lives in .work/plan.md
while IFS= read -r f; do
  [ -n "$f" ] && errors+=("the plan modified '$f'; in /plan only .work/plan.md is written")
done < <(changed_files)

# 3. The acceptance tests, inside the plan: a heading with the path and a csharp block
stage="$WORK_DIR/gate/plan-tests"
rm -rf "$stage"; mkdir -p "$stage"
extract_plan_tests "$stage"
paths=()
while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done < <(plan_test_paths)
[ ${#paths[@]} -ge 1 ] || errors+=("there are no tests in the plan: a heading #### \`tests/<App>.AcceptanceTests/Features/<Feature>/<Class>Tests.cs\` followed by the file in a csharp block")
dupes="$(printf '%s\n' "${paths[@]}" | sort | uniq -d)"
[ -z "$dupes" ] || errors+=("test files repeated in the plan: $dupes")

# 4. dotnet-testing conventions that can be checked without building
namespaces="$(grep -rhoE '^namespace [A-Za-z0-9_.]+' "$PROJECT_DIR/src" "$PROJECT_DIR/tests" --include='*.cs' 2>/dev/null | awk '{print $2}' | sort -u)"
app_roots="$(grep -rhoE '^namespace [A-Za-z0-9_.]+' "$PROJECT_DIR/src" --include='*.cs' 2>/dev/null | awk '{split($2, a, "."); print a[1]}' | sort -u)"
tests=0
for p in "${paths[@]}"; do
  f="$stage/$p"
  case "$p" in *..*) errors+=("'$p': invalid path"); continue ;; esac
  is_acceptance_test_path "$p" || { errors+=("'$p' is not under tests/*AcceptanceTests*/"); continue; }
  [ ! -e "$PROJECT_DIR/$p" ] || errors+=("'$p' already exists; the plan only defines new test files")
  [ -s "$f" ] || { errors+=("'$p' has no csharp block with the file below it"); continue; }

  grep -q '\[Collection(' "$f" || errors+=("'$p': use the project's shared collection, [Collection(...)]")
  n="$(grep -cE '\[(Fact|Theory)' "$f")"
  [ "$n" -ge 1 ] || errors+=("'$p': it has no [Fact] or [Theory]")
  tests=$((tests + n))
  grep -qE 'Skip *=' "$f" && errors+=("'$p': no Skip")
  grep -q 'Thread\.Sleep' "$f" && errors+=("'$p': no Thread.Sleep")
  grep -q '\.Should' "$f" || errors+=("'$p': no Shouldly assertions")
  while IFS= read -r m; do
    [[ "$m" =~ ^[A-Z][A-Za-z0-9]*(_[A-Za-z0-9]+){2,}$ ]] || errors+=("'$p': '$m' does not follow <Case>_<Scenario>_<Result>")
  done < <(grep -oE 'public (async )?Task [A-Za-z0-9_]+\(' "$f" | sed -E 's/.*Task ([A-Za-z0-9_]+)\(/\1/')
  if grep -qE 'HttpStatusCode\.(BadRequest|NotFound|Conflict)' "$f" && ! grep -q 'GetProperty(' "$f"; then
    errors+=("'$p': errors are checked by reading the ProblemDetails (title or errors), not just the status")
  fi
  while IFS= read -r ns; do
    printf '%s\n' "$app_roots" | grep -qxF "${ns%%.*}" || continue
    printf '%s\n' "$namespaces" | grep -qxF "$ns" || errors+=("'$p': 'using $ns;' does not exist yet; speak HTTP and JSON only")
  done < <(grep -oE '^using [A-Za-z0-9_.]+;' "$f" | sed -E 's/^using ([^;]+);/\1/')
done

if [ ${#errors[@]} -gt 0 ]; then
  echo "✖ The plan does not meet the contract:"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi

echo "✔ Valid plan: $tasks tasks and $tests acceptance tests in ${#paths[@]} files, following the dotnet-testing conventions. /apply will check that they compile and fail."
