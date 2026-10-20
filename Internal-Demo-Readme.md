# Internal Demo Readme · la charla paso a paso

Guía interna para dar la demo de **«Del MVP al harness»** (NetCoreConf Madrid 2026, 45 min) y para ensayarla antes.

## El objetivo

Responder en directo a una sola pregunta: **«Tengo algo que me flipa hecho con AI, ¿cómo lo repito mañana, igual, y lo comparto con el equipo?»**

El público tiene que irse con tres ideas:

1. **Un agente es un modelo más el harness que lo rodea.** El valor está en piezas pequeñas con responsabilidades claras: skill, contrato, comando, orquestador, hooks y plugin.
2. **La misma escalera sirve para un musical y para un equipo .NET.** Acto 1 contado, acto 2 en directo.
3. **Las reglas se ejecutan, no se recomiendan.** Una skill aconseja; un test de arquitectura, una precondición y una puerta TDD obligan.

> **Frase final:** «Lo que tengo en la cabeza ya no depende de mí: está en un plugin que el equipo instala en dos líneas».

Cómo está organizado:

- **Parte 1** · preparación (la víspera, la mañana y 15 minutos antes).
- **Parte 2** · el guion en directo, minuto a minuto: qué se teclea, qué se dice, qué tiene que salir y el plan B.
- **Parte 3** · el ensayo: comprobar cada pieza con el modelo real antes del día.

---

# Parte 1 · Preparación

## La víspera

```powershell
cd C:\Charlas\NetCoreConfMadrid2026
git restore src/Musicales.Api/Features/Obras/ObrasEndpoints.cs   # quita el DbContext comentado del ensayo: no debe subir a main
git status                                                       # solo deben quedar los cambios del MCP y los README
git add -A; git commit -m "MCP de GitHub con la sesión de gh y guía interna"; git push
```

- [ ] `main` publicado en GitHub con `plugins/dotnet-team/scripts/mcp/` incluido (`step.ps1 n2` y el marketplace lo leen de `main`)
- [ ] Parte 3 completa, con todas las casillas marcadas
- [ ] Vídeos de respaldo grabados (N0, N5 y cierre)
- [ ] Traza real del musical en `steps/act1/trace.jsonl`

## La mañana de la charla

```powershell
docker pull mcr.microsoft.com/mssql/server:2022-latest
gh auth status
cd C:\Charlas\NetCoreConfMadrid2026
dotnet build Musicales.slnx; dotnet test Musicales.slnx      # calienta NuGet, Docker y Testcontainers
dotnet new aspire-starter -o $env:TEMP\Calentar; Remove-Item -Recurse -Force $env:TEMP\Calentar   # calienta la plantilla
```

## 15 minutos antes

```powershell
cd C:\Charlas\NetCoreConfMadrid2026
git switch main; git status                       # limpio
Remove-Item -Recurse -Force .work -ErrorAction SilentlyContinue
./steps/step.ps1 n0                               # rama demo-live sin plugin, tag n0
Remove-Item -Recurse -Force $env:TEMP\EquipoX -ErrorAction SilentlyContinue
Get-ChildItem Env:ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue   # no debe salir nada
```

Ventanas abiertas, con fuente grande:

| Ventana | Dónde | Para qué |
|---|---|---|
| **T1** · terminal principal | `C:\Charlas\NetCoreConfMadrid2026`, rama `demo-live` | `step.ps1`, `claude --plugin-dir plugins/dotnet-team` |
| **T2** · terminal del gateway | Misma carpeta | AppHost y `gateway.ps1` (solo en N5b) |
| **T3** · terminal del cierre | `$env:TEMP` | `aspire-starter` y el plugin instalado desde GitHub |
| **Editor** · VS Code | Dos carpetas: el repo y `C:\Charlas\musical-plugin` | Enseñar ficheros |
| **Navegador** | Issues #1–#3 y el dashboard `http://localhost:15056` | Contexto |
| **Reproductor** | MP3 de Rasputín y vídeos de respaldo | Gancho y plan B |

- [ ] Notificaciones silenciadas, Teams y correo cerrados
- [ ] Red comprobada (si no hay, plan B: `steps/cache/issue-*.json` y vídeos)

---

# Parte 2 · El guion en directo

| Min | Bloque | Modo |
|---|---|---|
| 0–3 | Gancho | MP3 |
| 3–15 | Acto 1 · el musical | Contado, enseñando ficheros |
| 15–18 | Puente · vibe coding | Vídeo N0 |
| 18–38 | Acto 2 · .NET | `step.ps1` + dos momentos en directo (N1 y N5) |
| 38–43 | Cierre | En directo desde GitHub |
| 43–45 | Conclusión | Diapositiva |

**Regla de oro:** en directo solo N1 (el test en rojo), N5 (`/plan 3`) y el cierre. El resto avanza con `step.ps1` y se cuenta enseñando el fichero.

---

## 0–3 · Gancho

1. Suena el MP3 de Rasputín (30–40 s).
2. **Decir:** «Esto lo hice con AI en una tarde. El problema es que no sé repetirlo. Si abro otra sesión, vuelvo a empezar. Esta charla va de cómo se repite esto mañana, igual, y se comparte».
3. Enseñar la escalera (tabla de `README.md`, «La escalera»): «La vamos a subir dos veces. Primero con el musical y después con .NET».

---

## 3–15 · Acto 1 · el musical (contado)

Todo en el editor, carpeta `C:\Charlas\musical-plugin`. **No se lanza nada.**

| Min | Peldaño | Fichero a enseñar | Qué decir |
|---|---|---|---|
| 3–5 | **M1 · MVP** | Ninguno (o la conversación original) | Suno es muy poco determinista: rock un día, ranchera al siguiente. MIDI más un prompt controlado → resultados parecidos. «Lo entiendo, pero si abro otra sesión, vuelvo a empezar» |
| 5–7 | **M2 · Skill** | `skills/maqueta-suno/SKILL.md`, de `## Flujo` a `### 9. Escribir los prompts`; después `scripts/prosody.py` y `scripts/engine.py` | La receta sale de la conversación y entra en una skill. El modelo no cuenta sílabas ni sintetiza audio: lo hace un script. «Una habilidad, una finalidad» |
| 7–8 | **M3 · Contrato de entrada** | `## Entradas` y `## Paleta fija` de `maqueta-suno/SKILL.md` | Si falta algo, lo pide. Lo que es fijo no se pregunta: menos decisiones, salida más predecible |
| 8–10 | **M4 · Comando** | `commands/compositor.md`, sección «Decide la ruta» | Nadie tiene que escribir el prompt bueno: `/compositor` lo lleva dentro. Se pregunta una sola vez |
| 10–12 | **M5 · Orquestador** | `skills/letra-musical/references/formato-letra.md` y la «Fase 1 / Fase 2» del comando | No soy letrista → segunda skill. Letra → **puerta humana** → maqueta. El contrato entre skills es un fichero. «Úsalas, no reimplementes lo que hacen» |
| 12–15 | **M6 · Hooks y plugin** | `hooks/hooks.json`, `scripts/hooks/trace.sh`, `steps/act1/trace.jsonl` y `.claude-plugin/marketplace.json` | La traza dice qué comando, qué skill y qué script, y en qué orden. Un marketplace es un JSON. Instalación en dos líneas |

Cierre del acto, en pantalla:

```text
/plugin marketplace add C:\Charlas\musical-plugin
/plugin install musical@musical-marketplace
```

**Transición:** «Esto es un musical. ¿Funciona igual con un equipo .NET y su expertise? Vamos a verlo».

---

## 15–18 · Puente · vibe coding (vídeo N0)

1. Reproducir el vídeo N0: `Implementa la issue #1 del repo` sin harness.
2. Señalar en el vídeo: endpoint con `DbContext`, excepciones y ningún test. **Y el build no se queja.**
3. **Decir:** «El expertise está en nuestras cabezas, no en el repo. Vamos a subir la misma escalera».

---

## 18–38 · Acto 2 · la misma escalera en .NET

Todo en **T1**, rama `demo-live`, que ya está en `n0`.

**Decir antes de empezar (30 s):** «La app ya sigue Platform: Clean Architecture, slices, `ErrorOr` y Aspire. Ya tiene `Directory.Build.props` y tests de arquitectura. Eso no se construye hoy; hoy se construye el harness que hace que la AI lo respete».

> **Después de cada `step.ps1`, reinicia Claude Code** (`/exit` y `claude --plugin-dir plugins/dotnet-team`). Los comandos, hooks y el MCP se cargan al arrancar.

### 18–22 · N1 · Skill de guardarraíles (con un momento en directo)

```powershell
./steps/step.ps1 n1
```

1. Enseñar `plugins/dotnet-team/skills/dotnet-guardrails/SKILL.md`: «Platform condensado. Lo que lleva 🔒 lo comprueba código».
2. **En directo, el 🔒:** pega esto en `src/Musicales.Api/Features/Obras/ObrasEndpoints.cs`, después de `ObtenerObra`:

   ```csharp
   group.MapGet("/todas", async (Musicales.Infrastructure.Persistence.MusicalesDbContext db) =>
       await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(db.Obras));
   ```

   ```powershell
   dotnet test tests/Musicales.ArchitectureTests
   ```

   Sale **rojo** en `Api_no_usa_EF_Core_directamente`: «Musicales.Api no puede depender de estos ensamblados».

3. **Decir la anécdota:** «NetArchTest no ve dentro de las lambdas. Lo descubrimos porque este test pasaba cuando no debía. Los guardarraíles también se testean».
4. Deshacer **antes de seguir** (si no, `step.ps1` lo commitea):

   ```powershell
   git checkout -- src
   ```

5. Enseñar `plugins/dotnet-team/.claude-plugin/plugin.json`: «Plugin desde el día uno».

### 22–24 · N2 · La issue con MCP, a mano

```powershell
./steps/step.ps1 n2
```

1. Enseñar `plugins/dotnet-team/.mcp.json` y `scripts/mcp/github-headers.sh`: «GitHub remoto, solo lectura de issues: 6 herramientas en vez de 49. Se autentica con la sesión de `gh`, sin tokens en el repo».
2. Opcional, si va bien de tiempo: `claude --plugin-dir plugins/dotnet-team` y el prompt `Lee la issue #1 de RubenGomGar/NetCoreConfMadrid2026 y hazme un plan siguiendo la skill dotnet-guardrails`. Si no, solo contarlo.
3. **Decir:** «Funciona, pero cada persona lo pide distinto y sale distinto. Falta el comando».

Plan B sin red: `steps/cache/issue-1.json`.

### 24–27 · N3 · El comando `/plan`

```powershell
./steps/step.ps1 n3
```

1. Enseñar `plugins/dotnet-team/commands/plan.md`:
   - El prompt bueno, versionado.
   - La línea `` !`…ctx/plan.sh` ``: **contexto precalculado y precondición** (compila y la arquitectura en verde) antes de que el modelo lea nada.
2. Enseñar `plugins/dotnet-team/templates/plan.md`: «Es el contrato del plan, como `formato-letra.md` en el musical».
3. **Decir:** «Esto ya escribe `.work/plan.md` y los tests de aceptación. Pero todavía falla: nada obliga a que los tests compilen ni a que estén en rojo».

> No lances `/plan` aquí. Si lo haces, limpia antes de N4, porque `step.ps1` hace `git add -A` y commitearía los tests generados:
> `git checkout -- .; git clean -fd tests; Remove-Item -Recurse -Force .work`

### 27–29 · N4 · Orquestador: segunda skill

```powershell
./steps/step.ps1 n4
```

1. Enseñar `plugins/dotnet-team/skills/dotnet-testing/SKILL.md`: el trofeo de Platform, integración vía HTTP con Testcontainers.
2. `git diff n3 n4 -- plugins/dotnet-team/commands/plan.md`: el comando carga las dos skills, no las reimplementa.
3. **Decir:** «Letrista → compositor otra vez. El mismo patrón que en el musical».

### 29–35 · N5 · Hooks: el momento central (en directo)

```powershell
./steps/step.ps1 n5
git status                                     # limpio: la precondición lo exige
claude --plugin-dir plugins/dotnet-team
```

1. Mientras arranca, enseñar `plugins/dotnet-team/hooks/hooks.json`:

   | Hook | Script | Qué hace |
   |---|---|---|
   | `UserPromptSubmit`, `PostToolUse`, `SubagentStop` | `trace.sh` | El **mismo** fichero que en el musical |
   | `PreToolUse` (Edit\|Write) | `guard-edits.sh` | En `/plan` no se toca `src/`; nunca los guardarraíles ni `#pragma` |
   | `Stop` | `stop-gate.sh` → `gates/plan.sh` | **TDD determinista:** compila, arquitectura en verde y todos los tests nuevos en rojo |

2. En Claude Code:

   ```text
   /dotnet-team:plan 3
   ```

3. Qué tiene que ir saliendo, y qué decir mientras:

   | Momento | Qué sale | Qué decir |
   |---|---|---|
   | Arranque | «✔ Precondición: la solución compila y los tests de arquitectura están en verde» | «Esto lo ha calculado un script, no el modelo» |
   | Lectura | `issue_read` del MCP (o `gh issue view 3`) | «La issue es el contrato de entrada» |
   | Skills | `dotnet-guardrails` y `dotnet-testing` cargadas | «Orquesta, no reimplementa» |
   | Escritura | `.work/plan.md` y un test en `tests/Musicales.AcceptanceTests/Features/Obras/` | «Solo HTTP y JSON: no conoce tipos de `src/` que aún no existen» |
   | **Puerta (~40 s)** | «dotnet-team: puerta 'plan' superada. ✔ Plan válido: N tareas, M tests de aceptación en rojo…» | **Rellena los 40 s:** compila, la arquitectura sigue en verde y el test nuevo está en **rojo**. Si el test ya pasara, no describiría nada nuevo y la puerta lo devolvería |

4. **La guardia, en la misma sesión** (10 s):

   ```text
   Arregla el bug directamente en src/Musicales.Domain/Obras/Obra.cs
   ```

   Bloqueado: «en /plan solo se escribe .work/plan.md y tests de aceptación».

5. La traza, en otra pestaña de T1:

   ```powershell
   Get-Content .work/trace.jsonl
   ```

   `UserPromptSubmit /dotnet-team:plan 3`, las dos skills y el MCP o `gh`. **Decir:** «El mismo `trace.sh` del musical».

6. Rematar: «Los scripts del harness también tienen tests» y enseñar `bash plugins/dotnet-team/tests/run.sh` (sin ejecutarlo si vas justo).

**Plan B:**

| Falla | Qué hacer |
|---|---|
| El modelo tarda o se lía | Vídeo N5: la puerta rechazando un test que ya pasa |
| «PRECONDICIÓN FALLIDA: hay cambios sin commitear» | `git status`; `git stash -u` y repetir |
| El MCP no conecta | Sigue solo con `gh issue view`; contarlo como el plan B que trae el propio comando |
| Sin red | `steps/cache/issue-3.json` y vídeo N5 |

Al salir de N5, limpiar para no commitear el test en N6:

```powershell
git checkout -- .; git clean -fd tests; Remove-Item -Recurse -Force .work
```

### 35–36 · N5b · Observar al agente (bonus de 2 min, solo si vas bien)

Mejor con una captura del dashboard. Si se hace en directo, **siempre en T2**, nunca en T1: `gateway.ps1` deja `ANTHROPIC_BASE_URL` puesta en esa terminal.

```powershell
# T2, con el AppHost ya arrancado antes de la charla:
# dotnet run --project src/Musicales.AppHost --launch-profile http
./steps/gateway.ps1 -Otel --plugin-dir plugins/dotnet-team
```

Prompt: `Carga la skill dotnet-guardrails y dime la regla de errores`. En el dashboard (`http://localhost:15056`):

- Logs de `agent-gateway`: `herramientas [Skill(dotnet-team:dotnet-guardrails)] · tokens in … out … cache …`.
- Logs de `claude-code`: `skill_activated`.

**Decir:** «Tres capas: el hook lo decide el autor del plugin; el gateway, quien controla la red; OpenTelemetry, el propio agente. Y ojo: el gateway ve tokens y código, por eso solo escucha en localhost».

### 36–38 · N6 y N7 · Marketplace y bonus

```powershell
./steps/step.ps1 n6
./steps/step.ps1 n7
```

1. Enseñar `.claude-plugin/marketplace.json` en la raíz: «Este repo **es** el marketplace. Un JSON».
2. No hace falta `git push origin demo-live:main`: `main` ya tiene el mismo contenido publicado.
3. N7 en una frase: `/validate` contrasta la carpeta con las reglas de Platform con un agente de solo lectura; `/guardrails` instala las reglas ejecutables. «Lo vemos ahora en un proyecto que no es el mío».

---

## 38–43 · Cierre (en directo desde GitHub)

En **T3**, delante del público:

```powershell
cd $env:TEMP
dotnet new aspire-starter -o EquipoX; cd EquipoX
git init; git add -A; git commit -m init
claude
```

```text
/plugin marketplace add RubenGomGar/NetCoreConfMadrid2026
/plugin install dotnet-team@netcoreconf-2026
```

Reiniciar Claude Code si no aparecen los comandos, y después:

| Orden | Qué tiene que salir | Qué decir |
|---|---|---|
| `/dotnet-team:validate` | `NO_CUMPLE`, ~12 hallazgos: BE-ARCH-01 (sin capas), BE-ERR-01 (sin `ErrorOr`), BE-BUILD-01, BE-TEST-01/03, BE-ARCH-05, BE-SEC-02, BE-TIME-01 | «Cada hallazgo cita una regla que existe; lo comprueba una puerta» |
| `/dotnet-team:guardrails` | Instala `Directory.Build.props`, `.editorconfig` y `tests/EquipoX.ArchitectureTests`; build en **rojo** (paquetes vulnerables de la plantilla y `CA1852`) | «La plantilla oficial ya no cumple. No lo arreglo en directo» |
| `/dotnet-team:plan 2` | **PRECONDICIÓN FALLIDA** (ver la nota) | «El plan no arranca sobre una base que no cumple» |

> **Nota sobre `/plan 2`:** `ctx/plan.sh` comprueba antes que haya un proyecto `tests/*AcceptanceTests`, y la plantilla no lo trae. Lo más probable es que el motivo sea «no hay proyecto tests/*AcceptanceTests donde escribir los tests del plan», no «la solución no compila». Verifícalo en el ensayo (Parte 3, paso 4) y ajusta el texto de la diapositiva y de `steps/act2/README.md`. El mensaje de la charla es el mismo.

**Plan B:** vídeo del cierre. Si el marketplace no responde, `claude --plugin-dir C:\Charlas\NetCoreConfMadrid2026\plugins\dotnet-team` y seguir.

---

## 43–45 · Conclusión

1. La escalera completa, con las dos columnas.
2. Las lecciones de `README.md`, sobre todo «comando = orquestador, skills = expertos, scripts = músculo» y «las reglas se ejecutan, no se recomiendan».
3. **Frase final:** «Lo que tengo en la cabeza ya no depende de mí: está en un plugin que el equipo instala en dos líneas».
4. Cita: *«The guardrails are the product of phase 2, not a tax on it.»*
5. Volver a poner 10 s del MP3 de Rasputín.

---

# Parte 3 · Ensayo: probar todo de verdad

Ve en orden: lo menos probado va primero.

> **Lo que nunca se ha ejecutado con el modelo real:** `/dotnet-team:plan` y el MCP de GitHub dentro del plugin (el endpoint y la autenticación con `gh` sí están probados con curl). La puerta TDD se probó con un plan simulado. `/validate` y el gateway sí se probaron con Claude Code de verdad.

Marca cada casilla al terminar. Si algo falla, anota en **Notas** lo que salió.

## 1 · La app base (5 min)

```powershell
dotnet build Musicales.slnx
dotnet test Musicales.slnx
dotnet run --project src/Musicales.AppHost --launch-profile http
```

| Comprobación | Esperado |
|---|---|
| Build | `0 Warning(s)`, `0 Error(s)` |
| Tests | Gateway 6, arquitectura 8 y aceptación 4, todos en verde |
| Dashboard `http://localhost:15056` | `sql`, `api` y `agent-gateway` en *Running* y *Healthy* |
| `POST /api/obras` con `"titulo": "Rasputín"` (`src/Musicales.Api/Musicales.Api.http`) | 201 |
| `POST /api/obras` con `"titulo": "   "` | **201** (el bug de la issue #3; debería ser 400) |

- [ ] App base verificada

Notas:

## 2 · Los guardarraíles fallan cuando deben (2 min)

El mismo cambio que en N1 (Parte 2), sobre `main`:

```powershell
dotnet test tests/Musicales.ArchitectureTests
git checkout -- src
```

- [ ] Rojo en `Api_no_usa_EF_Core_directamente`

Notas:

## 3 · `/plan` con el modelo real (lo más importante, 10–15 min)

```powershell
git status          # limpio
claude --plugin-dir plugins/dotnet-team
```

```text
/dotnet-team:plan 3
```

| Comprobación | Esperado |
|---|---|
| Precondición | «✔ Precondición: la solución compila y los tests de arquitectura están en verde» |
| Lectura de la issue | MCP (`issue_read`) o `gh issue view 3`. En `/mcp`, `plugin:dotnet-team:github` con 6 herramientas |
| `.work/plan.md` | `issue: 3`, `status: draft`; secciones Objetivo, Guardarraíles aplicados, Tareas, Tests de aceptación y Fuera de alcance |
| Test nuevo | En `tests/Musicales.AcceptanceTests/Features/Obras/`; solo HTTP y JSON |
| Puerta (~40 s) | «dotnet-team: puerta 'plan' superada. ✔ Plan válido…» |
| `Get-Content .work/trace.jsonl` | `UserPromptSubmit /dotnet-team:plan 3`, las dos skills y el MCP o `gh` |

- [ ] `/plan 3` termina con la puerta superada
- [ ] El plan tiene sentido: si se implementa, arregla el bug
- [ ] Cronometrado: tarda menos de 5 min en total (si no, en la charla va el vídeo)

Pruebas negativas, en la misma sesión:

| Prompt | Esperado |
|---|---|
| «Arregla el bug directamente en src/Musicales.Domain/Obras/Obra.cs» | Bloqueado: «en /plan solo se escribe .work/plan.md y tests de aceptación» |
| «Añade NoWarn al csproj de tests» | Bloqueado: «no se silencian avisos» |
| Borra la sección `## Fuera de alcance` de `.work/plan.md` y pídele que termine | La puerta lo devuelve: «falta la sección '## Fuera de alcance'» |

- [ ] La guardia y la puerta bloquean

Limpieza entre intentos:

```powershell
git checkout -- .; git clean -fd tests; Remove-Item -Recurse -Force .work
```

Repetir con la issue grande:

```text
/dotnet-team:plan 1
```

- [ ] `/plan 1` sale razonable: slices `AnadirNumero` (command) y `ListarNumeros` (query), tests de 201, 400, 404 y 409

Notas:

## 4 · `/validate`, `/guardrails` y `/plan` sobre un proyecto nuevo (10 min)

```powershell
cd $env:TEMP; Remove-Item -Recurse -Force EquipoX -ErrorAction SilentlyContinue
dotnet new aspire-starter -o EquipoX; cd EquipoX
git init; git add -A; git commit -m init
claude --plugin-dir C:\Charlas\NetCoreConfMadrid2026\plugins\dotnet-team
```

| Comando | Esperado |
|---|---|
| `/dotnet-team:validate` | `NO_CUMPLE`, ~12 hallazgos en `.work/validate.md` |
| `/dotnet-team:guardrails` | Instala los tres guardarraíles; build en **rojo** (paquetes vulnerables y `CA1852`) |
| `/dotnet-team:plan 2` | «PRECONDICIÓN FALLIDA: …». **Anota el motivo exacto** (ver la nota del cierre) |

- [ ] Los tres comandos responden como se espera
- [ ] Motivo exacto de `/plan 2`: ______________________

Notas:

## 5 · El cierre real, instalando desde GitHub (5 min)

Repite el bloque del paso 4 con otro nombre, sin `--plugin-dir`:

```text
/plugin marketplace add RubenGomGar/NetCoreConfMadrid2026
/plugin install dotnet-team@netcoreconf-2026
/dotnet-team:validate
```

- [ ] El plugin se instala desde GitHub y `/validate` funciona igual que en el paso 4
- [ ] Sé si hace falta reiniciar Claude Code tras instalar para ver los comandos

Notas:

## 6 · Ensayo de los pasos del acto 2 (10 min)

```powershell
cd C:\Charlas\NetCoreConfMadrid2026
./steps/step.ps1 list
./steps/step.ps1 n0
./steps/step.ps1 n1   # … uno a uno hasta n7
git diff main demo-live -- plugins .claude-plugin
git switch main
```

- [ ] `n0` → `n7` sin errores
- [ ] `git diff main demo-live -- plugins .claude-plugin` vacío
- [ ] En `n3`, con `claude --plugin-dir plugins/dotnet-team`, `/plan` existe pero no hay puerta (es lo que se cuenta en N5)
- [ ] El guion completo de la Parte 2, de pie y cronometrado: _____ min

Notas:

## 7 · Gateway y OpenTelemetry (5 min)

```powershell
dotnet run --project src/Musicales.AppHost --launch-profile http
# en otra terminal:
./steps/gateway.ps1 -Otel --plugin-dir plugins/dotnet-team
```

Prompt: «Carga la skill dotnet-guardrails y dime la regla de errores».

| Dónde | Esperado |
|---|---|
| Logs de `agent-gateway` | `/v1/messages … herramientas [Skill(dotnet-team:dotnet-guardrails)] · tokens in … out … cache …` |
| Logs de `claude-code` | `user_prompt`, `api_request`, `skill_activated`, `tool_result` |
| Métricas de `agent-gateway` | `gateway.tool_use` con `skill`, y `gateway.tokens` por tipo |
| Desde consola | `aspire otel logs --dashboard-url http://localhost:15056 -n 40` |

- [ ] El gateway mide skills y tokens, y Claude Code no se cuelga
- [ ] Captura del dashboard guardada para la diapositiva

Notas:

## 8 · Acto 1: traza real del musical

```text
/plugin marketplace update musical-marketplace
/plugin update musical@musical-marketplace
/compositor una canción sobre un monje que nadie entiende
```

```powershell
Copy-Item .work/trace.jsonl C:\Charlas\NetCoreConfMadrid2026\steps\act1\trace.jsonl
```

- [ ] Traza guardada en `steps/act1/trace.jsonl`

## 9 · Vídeos de respaldo

- [ ] N0 · vibe coding de la issue #1 sin harness
- [ ] N5 · `/plan 3` completo y la puerta rechazando un test que ya pasa
- [ ] Cierre · `aspire-starter` → install → `/validate` → `/guardrails` → `/plan` rechazado

---

## Si algo falla

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| «PRECONDICIÓN FALLIDA: hay cambios sin commitear» | El árbol no está limpio | `git status`; commit o `git stash -u` |
| `step.ps1` commitea un test o un `DbContext` que no tocaba | Faltó limpiar tras N1 o N5 | `git reset --hard <tag anterior>` y repetir el paso |
| Un comando o hook nuevo no aparece | Claude Code no se ha reiniciado tras `step.ps1` | `/exit` y relanzar |
| La puerta salta en un turno que no toca | Quedó una fase a medias | `Remove-Item .work/phase` |
| Aparece `.work/NEEDS_HUMAN.md` | La puerta falló 3 veces | Lee `.work/gate/plan.log`, corrige y borra `NEEDS_HUMAN.md` |
| El MCP de GitHub no conecta | `gh` sin sesión, o el helper no se ha aprobado | `gh auth login`; `/mcp` para ver el estado. Si no, `/plan` usa `gh issue view` |
| Tests de aceptación lentos la primera vez | Testcontainers descargando la imagen de SQL Server | `docker pull mcr.microsoft.com/mssql/server:2022-latest` antes |
| `gateway.ps1`: «El gateway no responde» | AppHost apagado o puerto 5180 ocupado | Arranca el AppHost; `netstat -ano \| findstr 5180` |
| Claude Code va por el gateway sin quererlo | Se ejecutó `gateway.ps1` en esa terminal | `Remove-Item Env:ANTHROPIC_BASE_URL` o cambiar de terminal |
| Claude Code se cuelga vía gateway | Algo bufferiza el SSE | Sin `ANTHROPIC_BASE_URL` funciona; revisa `TrafficCaptureMiddleware` |
| Las trazas salen duplicadas en `trace.jsonl` | Conocido, causa sin investigar | No afecta a la demo |
| `step.ps1 n1`: el checkout falla | `main` no tiene el último commit | Parte 1, «La víspera»: commit y push |

## Recomendaciones para el día

1. **En directo, solo N1 (el test en rojo), N5 (`/plan 3`) y el cierre.** El resto, con `step.ps1` y enseñando ficheros.
2. **La issue #3 en directo**; la #1, en vídeo.
3. **Rellena los 40 s de la puerta** explicando qué comprueba: compila, la arquitectura sigue en verde y el test nuevo está en rojo.
4. **El cierre es un mensaje**: «el plan no arranca sobre una base que no cumple». No arregles el proyecto en directo.
5. **Gateway: bonus de 2 minutos** o una captura del dashboard.
6. **Sin `ANTHROPIC_BASE_URL` en T1 ni en T3**: si el gateway cae, cae todo.
7. **Si vas tarde a los 30 min**, salta N5b y N7 y ve directo al cierre.
