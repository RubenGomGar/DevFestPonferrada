#!/usr/bin/env bash
# Hook de trazas: una línea JSON por evento en .work/trace.jsonl.
# Autocontenido a propósito: es el mismo fichero en el plugin musical y en dotnet-team.
input="$(cat)"
dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
dir="${dir//\\//}/.work"
mkdir -p "$dir"

field() {
  printf '%s' "$input" | grep -oE '"'"$1"'"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -n1 |
    sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\"/"/g'
}

event="$(field hook_event_name)"
tool="$(field tool_name)"
case "$event" in
  UserPromptSubmit) detail="$(field prompt | cut -c1-80)" ;;
  SubagentStop) detail="$(field agent_type)" ;;
  *)
    case "$tool" in
      Skill) detail="$(field skill)" ;;
      Agent|Task) detail="$(field subagent_type)" ;;
      Bash) detail="$(field command | cut -c1-80)" ;;
      *) detail="" ;;
    esac ;;
esac

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"ts":"%s","event":"%s","tool":"%s","detail":"%s"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(esc "$event")" "$(esc "$tool")" "$(esc "$detail")" >> "$dir/trace.jsonl"
exit 0
