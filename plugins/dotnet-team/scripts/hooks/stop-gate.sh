#!/usr/bin/env bash
# Stop: la definición de done del comando activo. Si la puerta falla, el turno no termina
# (exit 2) y el agente recibe el motivo. Tras MAX_GATE_ATTEMPTS fallos, cede a una persona.
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
  echo "{\"systemMessage\": \"dotnet-team: puerta '$phase' superada. $(tail -n1 "$log" | sed 's/"/\\"/g')\"}"
  exit 0
fi

attempts=$((attempts + 1))
echo "$attempts" > "$WORK_DIR/gate-attempts"

if [ "$attempts" -ge "$MAX_GATE_ATTEMPTS" ]; then
  {
    echo "# Necesita una persona"
    echo
    echo "La puerta \`$phase\` ha fallado $attempts veces. El agente ha parado para no seguir en bucle."
    echo
    echo "Último resultado: \`.work/gate/$phase.log\`"
  } > "$WORK_DIR/NEEDS_HUMAN.md"
  phase_clear
  echo "{\"systemMessage\": \"dotnet-team: la puerta '$phase' ha fallado $attempts veces. Ver .work/NEEDS_HUMAN.md\"}"
  exit 0
fi

{
  echo "dotnet-team: la puerta '$phase' no se cumple (intento $attempts de $MAX_GATE_ATTEMPTS). No termines todavía."
  echo "Corrige la causa; nunca debilites un guardarraíl para pasar."
  echo
  tail -n 60 "$log"
} >&2
exit 2
