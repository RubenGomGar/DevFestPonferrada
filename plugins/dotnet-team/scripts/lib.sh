#!/usr/bin/env bash
# dotnet-team: helpers compartidos por contexto, hooks y puertas.
# Solo bash, grep, sed y awk (Git Bash en Windows). Sin jq ni Python.

set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_ROOT="${PLUGIN_ROOT//\\//}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROJECT_DIR="${PROJECT_DIR//\\//}"
WORK_DIR="$PROJECT_DIR/.work"
PLAN_FILE="$WORK_DIR/plan.md"
VALIDATE_FILE="$WORK_DIR/validate.md"
MAX_GATE_ATTEMPTS="${DOTNET_TEAM_MAX_GATE_ATTEMPTS:-3}"

# Valor de una clave string en el JSON que llega por stdin a un hook (claves cortas).
json_str() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n1 |
    sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//; s/"$//'
}

find_solution() {
  local f
  for f in "$PROJECT_DIR"/*.slnx "$PROJECT_DIR"/*.sln; do
    [ -f "$f" ] && { echo "$f"; return 0; }
  done
  return 1
}

find_test_project() {
  find "$PROJECT_DIR/tests" -maxdepth 2 -name "*$1*.csproj" 2>/dev/null | head -n1
}

ensure_work_dir() { mkdir -p "$WORK_DIR"; }

phase_get() { [ -f "$WORK_DIR/phase" ] && tr -d '[:space:]' < "$WORK_DIR/phase" || true; }
phase_set() { ensure_work_dir; printf '%s\n' "$1" > "$WORK_DIR/phase"; rm -f "$WORK_DIR/gate-attempts"; }
phase_clear() { rm -f "$WORK_DIR/phase" "$WORK_DIR/gate-attempts"; }

# Valor de una clave del frontmatter YAML de un markdown (solo claves planas).
frontmatter_value() {
  local file="$1" key="$2"
  [ -f "$file" ] || return 0
  awk -v k="$key" '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { exit }
    NR>1 && index($0, k":")==1 {
      v=substr($0, length(k)+2); gsub(/^[ \t]+|[ \t\r]+$/, "", v); gsub(/^"|"$/, "", v); print v; exit
    }' "$file"
}

# Ficheros que ningún agente puede tocar: son los guardarraíles.
is_guardrail_path() {
  case "$1" in
    Directory.Build.props|*/Directory.Build.props|Directory.Packages.props|.editorconfig|global.json) return 0 ;;
    tests/*ArchitectureTests*/*) return 0 ;;
    *) return 1 ;;
  esac
}

is_acceptance_test_path() {
  case "$1" in tests/*AcceptanceTests*/*.cs) return 0 ;; *) return 1 ;; esac
}

to_relative() {
  local p="${1//\\//}"
  p="${p#"$PROJECT_DIR"/}"
  p="${p#./}"
  echo "$p"
}

# Ficheros cambiados respecto a HEAD, incluidos los no versionados. Sin .work/.
changed_files() {
  {
    git -C "$PROJECT_DIR" diff --name-only HEAD -- . ':(exclude).work' ':(exclude).claude' 2>/dev/null
    git -C "$PROJECT_DIR" ls-files --others --exclude-standard -- . ':(exclude).work' ':(exclude).claude' 2>/dev/null
  } | sort -u
}
