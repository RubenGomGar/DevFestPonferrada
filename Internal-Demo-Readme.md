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
| 3–15 | Acto 1 · el musical | Improvisado: historia, slides y repo `musical-plugin` |
| 15–18 | Puente · vibe coding | Vídeo N0 |
| 18–38 | Acto 2 · .NET | `step.ps1` + dos momentos en directo (N1 y N5) |
| 38–43 | Cierre | En directo desde GitHub |
| 43–45 | Conclusión | Diapositiva |

**Regla de oro:** en directo solo N1 (el test en rojo), N5 (`/plan 3` → aprobar → `/apply`) y el cierre. El resto avanza con `step.ps1` y se cuenta enseñando el fichero.

---

## 0–3 · Gancho

1. Suena el MP3 de Rasputín (30–40 s).
2. **Decir:** «Esto lo hice con AI en una tarde. El problema es que no sé repetirlo. Si abro otra sesión, vuelvo a empezar. Esta charla va de cómo se repite esto mañana, igual, y se comparte».
3. Enseñar la escalera (tabla de `README.md`, «La escalera»): «La vamos a subir dos veces. Primero con el musical y después con .NET».

---

## 3–15 · Acto 1 · el musical (improvisado)

Contar la historia con las slides y el repo `C:\Charlas\musical-plugin` abierto en el editor.

**Transición:** «Esto es un musical. ¿Funciona igual con un equipo .NET y su expertise? Vamos a verlo».

---

## 15–18 · Puente · vibe coding (vídeo N0)

1. Reproducir el vídeo N0: `Implementa la issue #1 del repo` sin harness.
2. Señalar en el vídeo: **sale bien**. Capas, `ErrorOr`, 400/404/409 y tests de aceptación. Ha copiado la feature `Obras`.
3. Enseñar `.work/trace.jsonl`: busca un `CLAUDE.md` que no existe, lee el README, toda la feature `Obras` y los tests de arquitectura. **Se ha tenido que buscar la vida.**
4. **Decir:** «Sin harness, a veces sale bien… porque había un ejemplo que copiar. Ha tardado 3 minutos leyendo el repo, otra vez puede salir distinto, y lo que no está en el código (por qué `ErrorOr`, qué se testea, cuándo un 409) no lo puede deducir».
5. **Transición:** «La escalera va de convertir ese conocimiento implícito y aleatorio en explícito y determinista. Vamos a subirla».

---

## 18–38 · Acto 2 · la misma escalera en .NET

Todo en **T1**, rama `demo-live`, que ya está en `n0`.

**Decir antes de empezar (30 s):** «La app ya sigue Platform: Clean Architecture, slices, `ErrorOr` y Aspire. Ya tiene `Directory.Build.props` y tests de arquitectura. Eso no se construye hoy; hoy se construye el harness que hace que la AI lo respete».

> **Después de cada `step.ps1`, reinicia Claude Code** (`/exit` y `claude --plugin-dir plugins/dotnet-team`). Los comandos, hooks y el MCP se cargan al arrancar.

### 18–22 · N1 · Skill de guardarraíles: la skill aconseja, el test obliga (dos momentos en directo)

```powershell
./steps/step.ps1 n1
claude --plugin-dir plugins/dotnet-team
```

1. **(30 s)** Enseñar `plugins/dotnet-team/skills/dotnet-guardrails/SKILL.md`: «Platform condensado. Lo que lleva 🔒 lo comprueba código; lo demás es criterio». Señalar `user-invocable: false` y la `description`: no hay comando; Claude la carga sola cuando la tarea encaja.
2. Pega esto en `src/Musicales.Api/Features/Obras/ObrasEndpoints.cs`, después de `ObtenerObra`:

   ```csharp
   group.MapGet("/todas", async (Musicales.Infrastructure.Persistence.MusicalesDbContext db) =>
       await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(db.Obras));
   ```

3. **(1 min) En directo, la skill aconseja.** En Claude Code:

   ```text
   Revisa el endpoint /todas que acabo de añadir en src/Musicales.Api/Features/Obras/ObrasEndpoints.cs. Solo la revisión, no cambies nada.
   ```

   | Qué sale | Qué decir |
   |---|---|
   | `Skill(dotnet-team:dotnet-guardrails)` sin pedirla | «No le he dicho qué reglas usar: se ha cargado sola por su descripción» |
   | «`Api` no usa EF Core directamente»; slice `ListarObras` con una query en `Application`, `IObrasQueries`, `AsNoTracking` y proyección a DTO | «En N0 esto salió porque copió `Obras`. Ahora es una regla escrita, no suerte» |

4. **(1 min) En directo, el test obliga:**

   ```powershell
   dotnet test tests/Musicales.ArchitectureTests
   ```

   Sale **rojo** en `Api_no_usa_EF_Core_directamente`: «Musicales.Api no puede depender de estos ensamblados». **Decir:** «Pero la skill es un consejo: si el modelo o yo la ignoramos, nadie se entera. El 🔒 sí se entera».

5. **Decir la anécdota:** «NetArchTest no ve dentro de las lambdas. Lo descubrimos porque este test pasaba cuando no debía. Los guardarraíles también se testean».
6. Deshacer **antes de seguir** (si no, `step.ps1` lo commitea) y salir de Claude Code (`/exit`):

   ```powershell
   git checkout -- src
   ```

7. **(30 s)** Enseñar `plugins/dotnet-team/.claude-plugin/plugin.json`: «Plugin desde el día uno».

**Plan B:** si el modelo tarda o no carga la skill, salta el paso 3 y cuéntalo enseñando la sección «Capas» de `SKILL.md`. El rojo del test no depende del modelo.

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
3. **Decir:** «Esto ya escribe `.work/plan.md` con los tests de aceptación dentro: todo se revisa en un fichero. Pero todavía falla: nada obliga a que esos tests compilen, ni a que estén en rojo, ni a que quien implemente no los cambie».

> No lances `/plan` aquí. Si lo haces, borra `.work` antes de N4: `Remove-Item -Recurse -Force .work`

### 27–29 · N4 · Orquestador: segunda skill

```powershell
./steps/step.ps1 n4
```

1. Enseñar `plugins/dotnet-team/skills/dotnet-testing/SKILL.md`: el trofeo de Platform, integración vía HTTP con Testcontainers.
2. `git diff n3 n4 -- plugins/dotnet-team/commands/plan.md`: el comando carga las dos skills, no las reimplementa.
3. **Decir:** «Letrista → compositor otra vez. El mismo patrón que en el musical».

### 29–36 · N5 · Hooks y `/apply`: de rojo a verde (el momento central, en directo)

```powershell
./steps/step.ps1 n5
git status                                     # limpio: las precondiciones lo exigen
claude --plugin-dir plugins/dotnet-team
```

1. Mientras arranca, enseñar `plugins/dotnet-team/hooks/hooks.json` y `commands/apply.md`:

   | Pieza | Script | Qué hace |
   |---|---|---|
   | `UserPromptSubmit`, `PostToolUse`, `SubagentStop` | `trace.sh` | El **mismo** fichero que en el musical |
   | `PreToolUse` (Edit\|Write) | `guard-edits.sh` | En `/plan` solo se escribe el plan; en `/apply` no se tocan los tests del plan; nunca los guardarraíles ni `#pragma` |
   | `Stop` en `/plan` | `gates/plan.sh` | Forma del plan y convenciones de `dotnet-testing` en los tests. No compila: es rápida |
   | `!` de `/apply` | `ctx/apply.sh` | **Rojo:** plan aprobado; los tests del plan compilan y **todos** fallan antes de tocar código |
   | `Stop` en `/apply` | `gates/apply.sh` | **Verde:** tests del plan intactos, compila, arquitectura y **todos** los tests en verde |

2. **El plan.** En Claude Code:

   ```text
   /dotnet-team:plan 3
   ```

   | Momento | Qué sale | Qué decir |
   |---|---|---|
   | Arranque | «✔ Precondición: la solución compila y los tests de arquitectura están en verde» | «Esto lo ha calculado un script, no el modelo» |
   | Lectura | `issue_read` del MCP (o `gh issue view 3`) | «La issue es el contrato de entrada» |
   | Skills | `dotnet-guardrails` y `dotnet-testing` cargadas | «Orquesta, no reimplementa» |
   | Escritura | Solo `.work/plan.md`, con el test dentro | «Un único fichero que revisar. Solo HTTP y JSON: no conoce tipos de `src/` que aún no existen» |
   | Puerta (segundos) | «dotnet-team: puerta 'plan' superada. ✔ Plan válido: 1 tareas y 1 tests…» | «Comprueba las convenciones de testing del equipo: colección, nombres, ProblemDetails, nada de `Skip`» |

3. **La puerta humana.** Abrir `.work/plan.md` en VS Code, enseñar el test dentro y cambiar `status: draft` por `status: approved`. **Decir:** «Como la letra en el musical: una persona aprueba antes de componer».

4. **La implementación:**

   ```text
   /dotnet-team:apply
   ```

   | Momento | Qué sale | Qué decir |
   |---|---|---|
   | **Rojo (~45 s)** | «✔ Rojo: 2 tests del plan compilan y fallan hoy» | **Rellena los 45 s:** el script ha copiado los tests del plan, ha compilado y los ha ejecutado. Si alguno ya pasara, no describiría nada nuevo y `/apply` no arrancaría |
   | Implementación | `IsNullOrEmpty` → `IsNullOrWhiteSpace` en `Obra.cs` | «Una línea, en el dominio, como dice el plan» |
   | **Verde (~20 s)** | «dotnet-team: puerta 'apply' superada. ✔ Implementación válida: … tests en verde (2 del plan)» | «Compila, arquitectura en verde, todos los tests en verde y los del plan sin tocar» |

5. La traza, en otra pestaña de T1: `Get-Content .work/trace.jsonl`. `/dotnet-team:plan 3`, `/dotnet-team:apply`, las dos skills y el MCP o `gh`. **Decir:** «El mismo `trace.sh` del musical».

6. Rematar: «Los scripts del harness también tienen tests» y enseñar `bash plugins/dotnet-team/tests/run.sh` (sin ejecutarlo si vas justo).

**Plan B:**

| Falla | Qué hacer |
|---|---|
| El modelo tarda o se lía | Vídeo N5: `/plan 3` → aprobar → `/apply`, de rojo a verde |
| Vas justo de tiempo | Haz `/plan 3` y la aprobación en directo; `/apply` en vídeo |
| «PRECONDICIÓN FALLIDA: hay cambios sin commitear» | `git status`; `git stash -u` y repetir |
| «PRECONDICIÓN FALLIDA: el plan está en 'draft'» | Falta la aprobación: `status: approved` en `.work/plan.md` |
| El MCP no conecta | Sigue solo con `gh issue view`; contarlo como el plan B que trae el propio comando |
| Sin red | `steps/cache/issue-3.json` y vídeo N5 |

Al salir de N5, limpiar para no commitear el arreglo ni el test en N6:

```powershell
git checkout -- .; git clean -fd src tests; Remove-Item -Recurse -Force .work
```

### 36–37 · N5b · Observar al agente (bonus de 1 min, solo si vas bien)

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

### 37–38 · N6 y N7 · Marketplace y bonus

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

> **Lo que nunca se ha ejecutado con el modelo real:** `/dotnet-team:apply` de principio a fin. `/plan 3` sí, con el formato anterior (tests en fichero). Las puertas nuevas se probaron con scripts sobre un clon: la de `/plan` pasa con el plan de la issue 3, la precondición de `/apply` da «2 tests en rojo» y su puerta da verde con `IsNullOrWhiteSpace` y rechaza un test cambiado. `/validate` y el gateway sí se probaron con Claude Code de verdad.

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

## 2 · La skill aconseja y los guardarraíles fallan cuando deben (5 min)

El mismo cambio que en N1 (Parte 2), sobre `main`. Primero la revisión con la skill:

```powershell
claude --plugin-dir plugins/dotnet-team
```

```text
Revisa el endpoint /todas que acabo de añadir en src/Musicales.Api/Features/Obras/ObrasEndpoints.cs. Solo la revisión, no cambies nada.
```

| Comprobación | Esperado |
|---|---|
| Skill | `Skill(dotnet-team:dotnet-guardrails)` cargada sin pedirla |
| Revisión | Cita «`Api` no usa EF Core directamente» y propone un slice `ListarObras` con query en `Application`, `IObrasQueries`, `AsNoTracking` y proyección a DTO |
| Ficheros | `git status`: solo `ObrasEndpoints.cs` cambiado; no ha tocado nada más |

Después el test, ya fuera de Claude Code:

```powershell
dotnet test tests/Musicales.ArchitectureTests
git checkout -- src
```

- [ ] La skill se carga sola y la revisión cita las reglas
- [ ] Cronometrado: la revisión tarda menos de 1 min (si no, va contada con `SKILL.md`)
- [ ] Rojo en `Api_no_usa_EF_Core_directamente`

Notas:

## 3a · `/plan` con el modelo real (lo más importante, 10–15 min)

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
| Test | **Dentro del plan**, bajo `` #### `tests/Musicales.AcceptanceTests/Features/Obras/….cs` ``; solo HTTP y JSON. `git status` limpio: ningún fichero nuevo |
| Puerta (segundos) | «dotnet-team: puerta 'plan' superada. ✔ Plan válido…» |
| `Get-Content .work/trace.jsonl` | `UserPromptSubmit /dotnet-team:plan 3`, las dos skills y el MCP o `gh` |

- [ ] `/plan 3` termina con la puerta superada
- [ ] El plan tiene sentido: si se implementa, arregla el bug
- [ ] Cronometrado: tarda menos de 5 min en total (si no, en la charla va el vídeo)

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

## 3b · `/apply` con el modelo real (10 min)

Sobre el plan de la issue 3 del paso 3a, con `status: approved`:

```text
/dotnet-team:apply
```

| Comprobación | Esperado |
|---|---|
| Rojo (~45 s) | «✔ Rojo: 2 tests del plan compilan y fallan hoy» y el test copiado en `tests/Musicales.AcceptanceTests/Features/Obras/` |
| Implementación | Solo `src/Musicales.Domain/Obras/Obra.cs`: `IsNullOrWhiteSpace` |
| Puerta (~20 s) | «dotnet-team: puerta 'apply' superada. ✔ Implementación válida: … (2 del plan)» |

- [ ] `/apply` termina con la puerta superada
- [ ] Cronometrado: `/plan 3` + aprobar + `/apply` en menos de 7 min (si no, `/apply` va en vídeo)

Pruebas negativas:

| Qué | Esperado |
|---|---|
| `/dotnet-team:apply` con el plan en `draft` | «PRECONDICIÓN FALLIDA: el plan está en 'draft'…» |
| `/dotnet-team:apply` con el bug ya arreglado en `src/` (commiteado en una rama de prueba) | «PRECONDICIÓN FALLIDA: estos tests del plan ya pasan…» |

- [ ] Las precondiciones bloquean

Limpieza entre intentos:

```powershell
git checkout -- .; git clean -fd src tests; Remove-Item -Recurse -Force .work
```

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
- [ ] N5 · `/plan 3` → aprobar → `/apply`, de rojo a verde
- [ ] Cierre · `aspire-starter` → install → `/validate` → `/guardrails` → `/plan` rechazado

---

## Si algo falla

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| «PRECONDICIÓN FALLIDA: hay cambios sin commitear» | El árbol no está limpio | `git status`; commit o `git stash -u` |
| `step.ps1` commitea un test o un `DbContext` que no tocaba | Faltó limpiar tras N1 o N5 | `git reset --hard <tag anterior>` y repetir el paso |
| Un comando o hook nuevo no aparece | Claude Code no se ha reiniciado tras `step.ps1` | `/exit` y relanzar |
| La puerta salta en un turno que no toca | Quedó una fase a medias | `Remove-Item .work/phase` |
| Aparece `.work/NEEDS_HUMAN.md` | La puerta falló 3 veces | Lee `.work/gate/plan.log` o `.work/gate/apply.log` (según la fase), corrige y borra `NEEDS_HUMAN.md` |
| `/apply`: «no se han podido ejecutar los tests del plan» | Docker apagado o Testcontainers sin imagen | Arranca Docker; mira `.work/apply/red.log` |
| El MCP de GitHub no conecta | `gh` sin sesión, o el helper no se ha aprobado | `gh auth login`; `/mcp` para ver el estado. Si no, `/plan` usa `gh issue view` |
| Tests de aceptación lentos la primera vez | Testcontainers descargando la imagen de SQL Server | `docker pull mcr.microsoft.com/mssql/server:2022-latest` antes |
| `gateway.ps1`: «El gateway no responde» | AppHost apagado o puerto 5180 ocupado | Arranca el AppHost; `netstat -ano \| findstr 5180` |
| Claude Code va por el gateway sin quererlo | Se ejecutó `gateway.ps1` en esa terminal | `Remove-Item Env:ANTHROPIC_BASE_URL` o cambiar de terminal |
| Claude Code se cuelga vía gateway | Algo bufferiza el SSE | Sin `ANTHROPIC_BASE_URL` funciona; revisa `TrafficCaptureMiddleware` |
| Las trazas salen duplicadas en `trace.jsonl` | Conocido, causa sin investigar | No afecta a la demo |
| `step.ps1 n1`: el checkout falla | `main` no tiene el último commit | Parte 1, «La víspera»: commit y push |

## Recomendaciones para el día

1. **En directo, solo N1 (el test en rojo), N5 (`/plan 3` → aprobar → `/apply`) y el cierre.** El resto, con `step.ps1` y enseñando ficheros.
2. **La issue #3 en directo**; la #1, en vídeo.
3. **Rellena los 45 s del rojo de `/apply`** explicando qué comprueba: los tests del plan se han copiado, compilan y fallan todos. Y los ~20 s del verde: compila, arquitectura y todos los tests en verde, sin tocar los del plan.
4. **El cierre es un mensaje**: «el plan no arranca sobre una base que no cumple». No arregles el proyecto en directo.
5. **Gateway: bonus de 2 minutos** o una captura del dashboard.
6. **Sin `ANTHROPIC_BASE_URL` en T1 ni en T3**: si el gateway cae, cae todo.
7. **Si vas tarde a los 30 min**, `/apply` en vídeo, salta N5b y N7 y ve directo al cierre.
