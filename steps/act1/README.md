# Acto 1 · El musical (contado, sin prompts)

Doce minutos. Se enseñan ficheros de `C:\Charlas\musical-plugin`; no se lanza nada.
La pregunta que vertebra el acto: **tengo un MP3 que me flipa, ¿cómo lo repito mañana, igual, y lo comparto?**

## M1 · El MVP: una conversación

- Rasputín: el malo que acaba siendo querido. Instrumentos de *Next to Normal*.
- La AI llega al MIDI pero no a la postproducción → Suno. Mismo prompt en Suno: rock un día, ranchera al siguiente.
- MIDI + prompt de Suno controlado → resultados parecidos entre iteraciones.
- **Frase:** «Lo entiendo, pero si abro otra sesión, vuelvo a empezar».

## M2 · Primera skill: encapsular el paso a paso

Enseñar `skills/maqueta-suno/SKILL.md`, de `## Flujo` a `### 9. Escribir los prompts`.

- Se extrae la receta de la conversación a una skill y se comprueba que el resultado es el mismo.
- El modelo no cuenta sílabas ni sintetiza audio: `scripts/prosody.py` y `scripts/engine.py` lo hacen (determinismo donde el LLM falla).
- **Frase:** «Una habilidad, una finalidad».

## M3 · Contrato de entrada

Enseñar `## Entradas` y `## Paleta fija` de `maqueta-suno/SKILL.md`.

- Entradas definidas (estilo, tempo, letra); si falta algo, lo pide.
- Paleta fija: no se pregunta. Menos decisiones, salida más predecible.

## M4 · El comando

Enseñar `commands/compositor.md`, la sección «Decide la ruta».

- Ya no hay que escribir el prompt bueno: `/compositor` lo lleva dentro.
- Preguntar una sola vez; lo que tiene un default razonable se decide y se dice.

## M5 · Segunda skill y orquestador

Enseñar `skills/letra-musical/references/formato-letra.md` (el contrato) y la «Fase 1 / Fase 2» del comando.

- No soy letrista → `letra-musical`. El comando orquesta: letra → **puerta humana** → maqueta.
- El contrato entre skills es un fichero, no una conversación: frontmatter + secciones.
- **Frase:** «Úsalas, no reimplementes lo que hacen».

## M6 · Hooks de trazas y plugin

Enseñar `hooks/hooks.json`, `scripts/hooks/trace.sh` y una traza real (`trace.jsonl` de un ensayo).

- Telemetría: qué comando, qué skill y qué script se invocan, y en qué orden.
- `.claude-plugin/marketplace.json` + `plugin.json`: distribución sin infraestructura.
- Instalación en dos líneas y **suena la canción**.

```text
/plugin marketplace add C:\Charlas\musical-plugin
/plugin install musical@musical-marketplace
```

> Guarda aquí la traza de un ensayo real: `steps/act1/trace.jsonl`.
