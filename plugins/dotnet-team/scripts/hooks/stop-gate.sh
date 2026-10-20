#!/usr/bin/env bash
# Qué hace: ejecuta la puerta (definición de done) del comando activo según .work/phase; si falla, el turno no termina (exit 2) y tras MAX_GATE_ATTEMPTS fallos cede a una persona con .work/NEEDS_HUMAN.md.
# Para qué sirve: es el hook Stop del plugin; convierte las puertas de /plan, /apply y /validate en un bucle que el agente no puede saltarse.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

cat > /dev/null
phase="$(phase_get)"
[ -n "$phase" ] || exit 0

gate="$PLUGIN_ROOT/scripts/gates/$phase.sh"
[ -f "$gate" ] || { phase_clear; exit 0; }

mkdir -p "$WORK_DIR/gate"
log="$WORK_DIR/gate/$phase.log"
attempts="$(cat "$WORK_DIR/gate-attempts" 2>/dev/null || echo 0)"

if bash "$gate" > "$log" 2>&1; then
  phase_clear
  echo "{\"systemMessage\": \"dotnet-team: gate '$phase' passed. $(tail -n1 "$log" | sed 's/"/\\"/g')\"}"
  exit 0
fi

attempts=$((attempts + 1))
echo "$attempts" > "$WORK_DIR/gate-attempts"

if [ "$attempts" -ge "$MAX_GATE_ATTEMPTS" ]; then
  {
    echo "# Needs a human"
    echo
    echo "The \`$phase\` gate failed $attempts times. The agent stopped so it does not keep looping."
    echo
    echo "Last result: \`.work/gate/$phase.log\`"
  } > "$WORK_DIR/NEEDS_HUMAN.md"
  phase_clear
  echo "{\"systemMessage\": \"dotnet-team: gate '$phase' failed $attempts times. See .work/NEEDS_HUMAN.md\"}"
  exit 0
fi

{
  echo "dotnet-team: gate '$phase' is not met (attempt $attempts of $MAX_GATE_ATTEMPTS). Do not finish yet."
  echo "Fix the cause; never weaken a guardrail to pass."
  echo
  tail -n 60 "$log"
} >&2
exit 2
