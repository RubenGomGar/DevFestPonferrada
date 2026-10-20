#!/usr/bin/env bash
# Qué hace: instala en la solución los guardarraíles ejecutables de Platform (Directory.Build.props, .editorconfig y un proyecto de tests de arquitectura con LayersTests). Nunca sobrescribe: si un fichero ya existe, lo deja y lo dice.
# Para qué sirve: lo ejecuta /dotnet-team:guardrails (equivalente al /make-guardrails de Platform) para convertir las reglas del equipo en código antes de dar autonomía al agente.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

TPL="$PLUGIN_ROOT/templates/guardrails"
SLN="$(find_solution)" || { echo "✖ There is no .slnx/.sln solution at the root of $PROJECT_DIR."; exit 1; }
name="$(basename "$SLN")"; name="${name%.*}"

copy_once() {
  if [ -e "$PROJECT_DIR/$1" ]; then echo "• $1 already exists: left untouched."; else cp "$TPL/$1" "$PROJECT_DIR/$1"; echo "✔ $1"; fi
}
copy_once Directory.Build.props
copy_once .editorconfig

test_dir="tests/$name.ArchitectureTests"
if [ -d "$PROJECT_DIR/$test_dir" ] || [ -n "$(find_test_project ArchitectureTests)" ]; then
  echo "• There is already an architecture tests project: left untouched."
  exit 0
fi

apps="$(find "$PROJECT_DIR" -name '*.csproj' -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/node_modules/*' -not -path '*/tests/*' |
  grep -viE '(Tests?|AppHost|ServiceDefaults)\.csproj$' | sort)"
[ -n "$apps" ] || { echo "✖ There are no application projects to check."; exit 1; }

mkdir -p "$PROJECT_DIR/$test_dir"
cpm=false
grep -qs 'ManagePackageVersionsCentrally>true' "$PROJECT_DIR/Directory.Packages.props" && cpm=true

pkg() {
  if $cpm; then
    grep -q "Include=\"$1\"" "$PROJECT_DIR/Directory.Packages.props" ||
      sed -i "0,/<\/ItemGroup>/s##  <PackageVersion Include=\"$1\" Version=\"$2\" />\n  </ItemGroup>#" "$PROJECT_DIR/Directory.Packages.props"
    echo "    <PackageReference Include=\"$1\" />"
  else
    echo "    <PackageReference Include=\"$1\" Version=\"$2\" />"
  fi
}

{
  echo '<Project Sdk="Microsoft.NET.Sdk">'
  echo
  echo '  <PropertyGroup>'
  echo '    <TargetFramework>net10.0</TargetFramework>'
  echo '    <IsPackable>false</IsPackable>'
  echo '  </PropertyGroup>'
  echo
  echo '  <ItemGroup>'
  pkg Microsoft.NET.Test.Sdk 18.11.0
  pkg NetArchTest.Rules 1.3.2
  pkg Shouldly 4.3.0
  pkg xunit 2.9.3
  pkg xunit.runner.visualstudio 3.1.5
  echo '  </ItemGroup>'
  echo
  echo '  <ItemGroup>'
  for p in $apps; do echo "    <ProjectReference Include=\"../../$(to_relative "$p")\" />"; done
  echo '  </ItemGroup>'
  echo
  echo '  <ItemGroup>'
  echo '    <Using Include="Xunit" />'
  echo '  </ItemGroup>'
  echo
  echo '</Project>'
} > "$PROJECT_DIR/$test_dir/$name.ArchitectureTests.csproj"

{
  echo 'namespace PlatformGuardrails.ArchitectureTests;'
  echo
  echo 'internal static class Projects'
  echo '{'
  printf '    public static readonly string[] Names = [%s];\n' "$(for p in $apps; do printf '"%s", ' "$(basename "$p" .csproj)"; done | sed 's/, $//')"
  echo '}'
} > "$PROJECT_DIR/$test_dir/Projects.cs"

cp "$TPL/ArchitectureTests/LayersTests.cs" "$PROJECT_DIR/$test_dir/LayersTests.cs"
dotnet sln "$SLN" add "$PROJECT_DIR/$test_dir/$name.ArchitectureTests.csproj" > /dev/null && echo "✔ $test_dir (added to $(basename "$SLN"))"
echo
echo "Projects under control: $(for p in $apps; do basename "$p" .csproj; done | paste -sd',' | sed 's/,/, /g')"
