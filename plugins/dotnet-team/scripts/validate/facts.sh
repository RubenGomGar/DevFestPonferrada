#!/usr/bin/env bash
# Qué hace: calcula hechos deterministas de una carpeta .NET (capas, referencias, paquetes, build, Aspire, seguridad...) y los imprime como tabla markdown. Uso: facts.sh [carpeta]
# Para qué sirve: lo ejecuta /dotnet-team:validate para que el modelo lea los hechos en vez de descubrirlos; además activa la fase `validate` para la guardia y la puerta.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

target="${1:-.}"
target="${target//\\//}"
[ -d "$target" ] || { echo "✖ Folder '$target' does not exist."; exit 1; }
root="$(cd "$target" && pwd)"

phase_set validate
rm -f "$VALIDATE_FILE"
printf '%s\n' "$root" > "$WORK_DIR/validate-target"

src() { grep -rlE "$1" "$root" --include="${2:-*.cs}" --exclude-dir={bin,obj,node_modules,.git,.work} 2>/dev/null; }
count() { src "$@" | wc -l | tr -d ' '; }
rel() { sed "s#^$root/##"; }
list() { local out; out="$(rel | head -n "${1:-5}" | paste -sd',' | sed 's/,/, /g')"; echo "${out:-—}"; }
row() { printf '| %s | %s | %s |\n' "$1" "$2" "$3"; }

csprojs="$(find "$root" -name '*.csproj' -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/node_modules/*' | sort)"
props="$(find "$root" -maxdepth 2 -name Directory.Build.props | head -n1)"

echo "# Facts for \`$root\`"
echo
echo "| Fact | Value | Evidence |"
echo "|---|---|---|"
row solution "$(find "$root" -maxdepth 2 \( -name '*.slnx' -o -name '*.sln' \) | wc -l | tr -d ' ')" "$(find "$root" -maxdepth 2 \( -name '*.slnx' -o -name '*.sln' \) | list)"
row projects "$(printf '%s\n' "$csprojs" | grep -c .)" "$(printf '%s\n' "$csprojs" | list 20)"

layers=""
for l in Domain Application Infrastructure Api; do
  printf '%s\n' "$csprojs" | grep -qE "\.$l\.csproj$" && layers="$layers $l"
done
row layers "${layers:- none}" "projects *.Domain/*.Application/*.Infrastructure/*.Api"

refs="$(for p in $csprojs; do grep -oE 'ProjectReference Include="[^"]+"' "$p" | sed -E "s#.*Include=\"##; s#\"##; s#.*[\\\\/]##; s#^#$(basename "$p" .csproj) -> #"; done)"
row project_references "$(printf '%s\n' "$refs" | grep -c .)" "$(printf '%s\n' "$refs" | paste -sd';' | sed 's/;/; /g')"

generic="$(find "$root" -type d \( -name Services -o -name Repositories -o -name Helpers -o -name Managers \) -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/node_modules/*')"
row generic_folders "$(printf '%s\n' "$generic" | grep -c .)" "$(printf '%s\n' "$generic" | list)"
row map_in_program "$(src 'app\.Map(Get|Post|Put|Delete|Patch)\(' Program.cs | wc -l | tr -d ' ')" "$(src 'app\.Map(Get|Post|Put|Delete|Patch)\(' Program.cs | list)"
row erroror "$(count 'PackageReference Include="ErrorOr"' '*.csproj')" "$(src 'PackageReference Include="ErrorOr"' '*.csproj' | list)"
row problem_details "$(count 'AddProblemDetails|TypedResults\.Problem|Results\.Problem|ValidationProblem')" "$(src 'AddProblemDetails|TypedResults\.Problem|Results\.Problem|ValidationProblem' | list)"
row throw_in_endpoints "$(src 'throw new' | grep -iE 'Endpoints?\.cs$|Program\.cs$' | wc -l | tr -d ' ')" "$(src 'throw new' | grep -iE 'Endpoints?\.cs$|Program\.cs$' | list)"
row dbcontext_outside_infrastructure "$(src ':[[:space:]]*DbContext\b' | grep -v 'Infrastructure' | wc -l | tr -d ' ')" "$(src ':[[:space:]]*DbContext\b' | grep -v 'Infrastructure' | list)"
row ef_core "$(count 'Microsoft.EntityFrameworkCore' '*.csproj')" "$(src 'EntityFrameworkCore' '*.csproj' | list)"
row as_no_tracking "$(count 'AsNoTracking')" "$(src 'AsNoTracking' | list)"
row architecture_tests "$(printf '%s\n' "$csprojs" | grep -ciE 'Architecture')" "$(printf '%s\n' "$csprojs" | grep -iE 'Architecture' | list)"
row test_projects "$(printf '%s\n' "$csprojs" | grep -ciE 'Tests?\.csproj$')" "$(printf '%s\n' "$csprojs" | grep -iE 'Tests?\.csproj$' | list)"
row testcontainers "$(count 'Testcontainers' '*.csproj')" "$(src 'Testcontainers' '*.csproj' | list)"
row webapplicationfactory "$(count 'WebApplicationFactory')" "$(src 'WebApplicationFactory' | list)"
row treat_warnings_as_errors "$(count '<TreatWarningsAsErrors>true' '*.props')" "${props:+$(echo "$props" | rel)}"
row nullable "$(count '<Nullable>enable' '*.props')+$(count '<Nullable>enable' '*.csproj') props+csproj" "${props:+$(echo "$props" | rel)}"
row analysis_level "$(src '<AnalysisLevel>' '*.props' | wc -l | tr -d ' ')" "$(src '<AnalysisLevel>' '*.props' | list)"
row central_packages "$(count 'ManagePackageVersionsCentrally>true' '*.props')" "$(src 'ManagePackageVersionsCentrally' '*.props' | list)"
row suppressions "$( (src '#pragma warning disable|SuppressMessage\('; src '<NoWarn>' '*.csproj'; src '<NoWarn>' '*.props') | wc -l | tr -d ' ')" "$( (src '#pragma warning disable|SuppressMessage\('; src '<NoWarn>' '*.csproj') | list)"
row apphost "$(count 'DistributedApplication\.CreateBuilder')" "$(src 'DistributedApplication\.CreateBuilder' | list)"
row docker_compose "$(find "$root" -maxdepth 3 -iname 'docker-compose*.y*ml' -o -maxdepth 3 -iname 'compose.y*ml' | wc -l | tr -d ' ')" "$(find "$root" -maxdepth 3 \( -iname 'docker-compose*.y*ml' -o -iname 'compose.y*ml' \) | list)"
row with_reference "$(cat $(src 'DistributedApplication\.CreateBuilder') /dev/null 2>/dev/null | grep -oE '\.WithReference\(' | wc -l | tr -d ' ')" "AppHost"
row wait_for "$(cat $(src 'DistributedApplication\.CreateBuilder') /dev/null 2>/dev/null | grep -oE '\.WaitFor\(' | wc -l | tr -d ' ')" "AppHost"
row persistent_lifetime "$(count 'ContainerLifetime\.Persistent')" "$(src 'ContainerLifetime\.Persistent' | list)"
row data_volume "$(count 'WithDataVolume')" "$(src 'WithDataVolume' | list)"

services="$(src 'WebApplication\.CreateBuilder|Host\.CreateApplicationBuilder' Program.cs)"
without_defaults="$(for f in $services; do grep -q 'AddServiceDefaults' "$f" || echo "$f"; done)"
row services "$(printf '%s\n' "$services" | grep -c .)" "$(printf '%s\n' "$services" | list)"
row services_without_add_service_defaults "$(printf '%s\n' "$without_defaults" | grep -c .)" "$(printf '%s\n' "$without_defaults" | list)"
row appsettings_connection_strings "$(src '(Server|Data Source|User Id|Password|AccountKey)=' 'appsettings*.json' | wc -l | tr -d ' ')" "$(src '(Server|Data Source|User Id|Password|AccountKey)=' 'appsettings*.json' | list)"
row x_robots_tag "$(count 'X-Robots-Tag')" "$(src 'X-Robots-Tag' | list)"
row console_writeline "$(count 'Console\.Write')" "$(src 'Console\.Write' | list)"
row datetime_now "$(count 'DateTime(Offset)?\.(Now|UtcNow)')" "$(src 'DateTime(Offset)?\.(Now|UtcNow)' | list)"
row ci "$(find "$root" -path '*/.github/workflows/*' -name '*.y*ml' | wc -l | tr -d ' ')" "$(find "$root" -path '*/.github/workflows/*' -name '*.y*ml' | list)"
