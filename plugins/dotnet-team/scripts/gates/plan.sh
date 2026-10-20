#!/usr/bin/env bash
# Puerta de /plan: el plan tiene la forma del contrato y sus tests de aceptación, escritos dentro
# del plan, siguen las convenciones de dotnet-testing. No compila ni ejecuta: /apply comprueba que
# están en rojo antes de implementar. No juzga si el plan es bueno: eso es humano.
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

# 2. El plan no implementa ni crea ficheros: todo vive en .work/plan.md
while IFS= read -r f; do
  [ -n "$f" ] && errors+=("el plan ha modificado '$f'; en /plan solo se escribe .work/plan.md")
done < <(changed_files)

# 3. Los tests de aceptación, dentro del plan: un encabezado con la ruta y un bloque csharp
stage="$WORK_DIR/gate/plan-tests"
rm -rf "$stage"; mkdir -p "$stage"
extract_plan_tests "$stage"
paths=()
while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done < <(plan_test_paths)
[ ${#paths[@]} -ge 1 ] || errors+=("no hay tests en el plan: un encabezado #### \`tests/<App>.AcceptanceTests/Features/<Feature>/<Clase>Tests.cs\` seguido del fichero en un bloque csharp")
dupes="$(printf '%s\n' "${paths[@]}" | sort | uniq -d)"
[ -z "$dupes" ] || errors+=("ficheros de test repetidos en el plan: $dupes")

# 4. Convenciones de dotnet-testing que se pueden comprobar sin compilar
namespaces="$(grep -rhoE '^namespace [A-Za-z0-9_.]+' "$PROJECT_DIR/src" "$PROJECT_DIR/tests" --include='*.cs' 2>/dev/null | awk '{print $2}' | sort -u)"
app_roots="$(grep -rhoE '^namespace [A-Za-z0-9_.]+' "$PROJECT_DIR/src" --include='*.cs' 2>/dev/null | awk '{split($2, a, "."); print a[1]}' | sort -u)"
tests=0
for p in "${paths[@]}"; do
  f="$stage/$p"
  case "$p" in *..*) errors+=("'$p': ruta no válida"); continue ;; esac
  is_acceptance_test_path "$p" || { errors+=("'$p' no está en tests/*AcceptanceTests*/"); continue; }
  [ ! -e "$PROJECT_DIR/$p" ] || errors+=("'$p' ya existe; el plan solo define ficheros de test nuevos")
  [ -s "$f" ] || { errors+=("'$p' no tiene debajo un bloque csharp con el fichero"); continue; }

  grep -q '\[Collection(' "$f" || errors+=("'$p': usa la colección compartida del proyecto, [Collection(...)]")
  n="$(grep -cE '\[(Fact|Theory)' "$f")"
  [ "$n" -ge 1 ] || errors+=("'$p': no tiene ningún [Fact] ni [Theory]")
  tests=$((tests + n))
  grep -qE 'Skip *=' "$f" && errors+=("'$p': nada de Skip")
  grep -q 'Thread\.Sleep' "$f" && errors+=("'$p': nada de Thread.Sleep")
  grep -q '\.Should' "$f" || errors+=("'$p': sin aserciones de Shouldly")
  while IFS= read -r m; do
    [[ "$m" =~ ^[A-Z][A-Za-z0-9]*(_[A-Za-z0-9]+){2,}$ ]] || errors+=("'$p': '$m' no sigue <Caso>_<Escenario>_<Resultado>")
  done < <(grep -oE 'public (async )?Task [A-Za-z0-9_]+\(' "$f" | sed -E 's/.*Task ([A-Za-z0-9_]+)\(/\1/')
  if grep -qE 'HttpStatusCode\.(BadRequest|NotFound|Conflict)' "$f" && ! grep -q 'GetProperty(' "$f"; then
    errors+=("'$p': los errores se comprueban leyendo el ProblemDetails (title o errors), no solo el status")
  fi
  while IFS= read -r ns; do
    printf '%s\n' "$app_roots" | grep -qxF "${ns%%.*}" || continue
    printf '%s\n' "$namespaces" | grep -qxF "$ns" || errors+=("'$p': 'using $ns;' no existe todavía; habla solo HTTP y JSON")
  done < <(grep -oE '^using [A-Za-z0-9_.]+;' "$f" | sed -E 's/^using ([^;]+);/\1/')
done

if [ ${#errors[@]} -gt 0 ]; then
  echo "✖ El plan no cumple el contrato:"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi

echo "✔ Plan válido: $tasks tareas y $tests tests de aceptación en ${#paths[@]} ficheros, con las convenciones de dotnet-testing. /apply comprobará que compilan y fallan."
