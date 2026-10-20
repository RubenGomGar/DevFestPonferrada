# Acto 2 · La misma escalera en .NET (en directo)

Veinte minutos. Se construye `plugins/dotnet-team` sobre la marcha en la rama `demo-live`.
Si algo se tuerce: `./steps/step.ps1 <paso>` trae el fichero terminado desde `main`, o `git checkout <tag>`.

Punto de partida, que se cuenta y no se construye: `src/Musicales` sigue Platform (Clean Architecture, slices, `ErrorOr`, Aspire) y ya tiene guardarraíles de build (`Directory.Build.props`) y de arquitectura (`tests/Musicales.ArchitectureTests`).

## N0 · Vibe coding (vídeo, 3 min)

Prompt: `Implementa la issue #1 del repo`.

Qué se ve: **sale bien**. Imita la feature `Obras`: capas, `ErrorOr`, 400/404/409 y tests de aceptación. En `.work/trace.jsonl` se ve el coste: busca un `CLAUDE.md` que no existe y se lee el README, toda `Obras` y los tests de arquitectura antes de escribir nada.

**Frase:** «Sin harness, a veces sale bien… porque había un ejemplo que copiar. Ha tardado 3 minutos leyendo el repo, otra vez puede salir distinto, y lo que no está en el código (por qué `ErrorOr`, qué se testea, cuándo un 409) no lo puede deducir».

**Idea de la escalera:** convertir conocimiento implícito y aleatorio en explícito y determinista.

## N1 · Skill de guardarraíles

```powershell
./steps/step.ps1 n1   # o escribirla en directo
```

- `skills/dotnet-guardrails/SKILL.md`: Platform condensado. Los 🔒 los comprueba código.
- La skill aconseja: con el `DbContext` pegado en un endpoint, `Revisa el endpoint /todas… Solo la revisión, no cambies nada` → la skill se carga sola por su `description` (`user-invocable: false`, no hay comando) y cita «`Api` no usa EF Core directamente».
- El test obliga, demo del 🔒: añadir `MusicalesDbContext` en un endpoint → `dotnet test tests/Musicales.ArchitectureTests` → **rojo** (`Api_no_usa_EF_Core_directamente`).
- Anécdota real: NetArchTest no ve dentro de las lambdas; el test comprueba también las referencias del ensamblado. **Los guardarraíles también se testean**.
- `plugin.json` desde el día uno: `claude --plugin-dir plugins/dotnet-team`.

## N2 · Issue con MCP, a mano

```powershell
./steps/step.ps1 n2   # .mcp.json con el servidor de GitHub
```

Prompt: `Lee la issue #1 de RubenGomGar/NetCoreConfMadrid2026 y hazme un plan siguiendo la skill dotnet-guardrails`.

Funciona, pero cada persona lo pide distinto y sale distinto. Plan B sin red: `steps/cache/issue-1.json`.

## N3 · Comando `/plan`

```powershell
./steps/step.ps1 n3
```

- `commands/plan.md`: el prompt bueno, versionado. `!`script`` → **contexto precalculado** y precondición (compila + arquitectura en verde).
- `templates/plan.md`: el contrato del plan, como `formato-letra.md` en el musical.
- `/dotnet-team:plan 1` → solo `.work/plan.md` en `draft`, con los tests de aceptación dentro: todo se revisa en un fichero.
- **Falla todavía:** nada obliga a que los tests compilen, ni a que estén en rojo, ni a que alguien los implemente sin cambiarlos.

## N4 · Orquestador: segunda skill

```powershell
./steps/step.ps1 n4
```

- `skills/dotnet-testing/SKILL.md`: el trofeo de Platform (integración vía HTTP con Testcontainers).
- El comando carga las dos skills sin reimplementarlas. Es letrista → compositor otra vez.

## N5 · Hooks y `/apply`: de rojo a verde

```powershell
./steps/step.ps1 n5   # hooks, puertas de /plan y /apply, y el comando /apply
```

| Hook | Script | Qué demuestra |
|---|---|---|
| `UserPromptSubmit`, `PostToolUse`, `SubagentStop` | `trace.sh` | El **mismo** fichero que en el musical. `Get-Content .work/trace.jsonl` |
| `PreToolUse` (Edit\|Write) | `guard-edits.sh` | En `/plan` solo se escribe el plan; en `/apply` no se tocan los tests del plan; nunca los guardarraíles ni `#pragma` |
| `Stop` en `/plan` | `stop-gate.sh` → `gates/plan.sh` | Forma del plan y convenciones de `dotnet-testing` en los tests. Rápida: no compila |
| `!` de `/apply` | `ctx/apply.sh` | **Rojo:** plan aprobado; los tests del plan compilan y **todos** fallan antes de implementar |
| `Stop` en `/apply` | `stop-gate.sh` → `gates/apply.sh` | **Verde:** tests del plan intactos, compila, arquitectura y **todos** los tests en verde |

Demo con el bug (issue #3):

1. `/dotnet-team:plan 3` → `.work/plan.md` con el test dentro.
2. Puerta humana: `status: draft` → `status: approved`. Como la letra en el musical.
3. `/dotnet-team:apply` → «✔ Rojo: 2 tests del plan compilan y fallan hoy» → `IsNullOrWhiteSpace` en `Obra.cs` → «✔ Implementación válida… (2 del plan)».

Si un test del plan ya pasa, `/apply` no arranca: «estos tests del plan ya pasan, así que no describen nada nuevo». Si el modelo cambia el test para que pase, la guardia lo bloquea y la puerta lo detecta.
`bash plugins/dotnet-team/tests/run.sh`: los scripts del harness también tienen tests.

## N5b · Observar al agente: hook, gateway y OpenTelemetry

Cómo monitorizan Claude, Copilot y compañía el uso de skills: un proxy en medio del tráfico al modelo. Aquí, en .NET, con YARP dentro del mismo AppHost.

```powershell
dotnet run --project src/Musicales.AppHost --launch-profile http   # API + SQL + agent-gateway + dashboard
./steps/gateway.ps1 -Otel                                          # claude vía http://localhost:5180 + OTel al dashboard
aspire otel logs --dashboard-url http://localhost:15056 -n 40      # o el dashboard en el navegador
```

| Capa | Quién decide qué se ve | Qué sale en el dashboard |
|---|---|---|
| Hook (`trace.sh`) | El autor del plugin | `.work/trace.jsonl` |
| Gateway (`Musicales.AgentGateway`) | Quien controla la red | `agent-gateway`: `/v1/messages … herramientas [Skill(dotnet-team:dotnet-testing)] · tokens in 4 out 93 cache 55626` y las métricas `gateway.tool_use{tool,kind,skill}` y `gateway.tokens` |
| OTel nativo (`CLAUDE_CODE_ENABLE_TELEMETRY`) | El propio agente | `claude-code`: `user_prompt`, `api_request`, `skill_activated`, `tool_result`… |

Cómo funciona el gateway, en tres ficheros de `src/Musicales.AgentGateway/Features/Telemetria/`:

- `AnthropicTraffic`: lee la petición y cuenta solo los `tool_use` cuyo `tool_result` llega en el último mensaje, porque el historial se reenvía entero.
- `TeeStream` + `SseUsageParser`: leen los tokens del SSE **mientras pasa**, sin retenerlo; si lo bufferizas, Claude Code se cuelga.
- Se pide `Accept-Encoding: identity` a Anthropic: si no, el SSE llega en gzip.

**Riesgo:** el gateway ve tokens de sesión, prompts y código. Por eso solo escucha en localhost, no registra cuerpos ni cabeceras de autenticación y reenvía `anthropic-beta` intacto (la sesión OAuth lo necesita).

## N6 · Marketplace

```powershell
./steps/step.ps1 n6
git push origin demo-live:main   # o tenerlo ya publicado
```

`.claude-plugin/marketplace.json` en la raíz: este repo **es** el marketplace.

## N7 · Bonus: `/validate` y `/guardrails`

```powershell
./steps/step.ps1 n7
```

- `/dotnet-team:validate <carpeta>`: `facts.sh` calcula los hechos → agente `platform-reviewer` (solo lectura) los contrasta con `references/platform-rules.md` → `.work/validate.md`. La puerta comprueba que cada hallazgo cita una regla que existe y que el veredicto es coherente.
- `/dotnet-team:guardrails`: el equivalente a `/make-guardrails` de Platform. Instala `Directory.Build.props`, `.editorconfig` y tests de arquitectura genéricos.

## Cierre

En una carpeta nueva, delante del público:

```powershell
dotnet new aspire-starter -o EquipoX; cd EquipoX; git init; git add -A; git commit -m init
claude
```

```text
/plugin marketplace add RubenGomGar/NetCoreConfMadrid2026
/plugin install dotnet-team@netcoreconf-2026
/dotnet-team:validate
/dotnet-team:guardrails
/dotnet-team:plan 2
```

Resultado esperado (ensayado):

| Orden | Qué sale |
|---|---|
| `/validate` | `NO_CUMPLE`: sin capas (BE-ARCH-01), sin `ErrorOr` (BE-ERR-01), sin build estricto (BE-BUILD-01), sin tests de arquitectura ni Testcontainers (BE-TEST-01/03), endpoints en `Program.cs` (BE-ARCH-05), sin `X-Robots-Tag` (BE-SEC-02), `DateTime.Now` (BE-TIME-01) |
| `/guardrails` | Build en **rojo** al momento: paquetes vulnerables en la plantilla (`OpenTelemetry` 1.14, `MessagePack` 2.5.192, `Microsoft.OpenApi` 2.0) y `CA1852`. Con eso resuelto, `La_solucion_tiene_las_capas_de_Platform` en rojo |
| `/plan 2` | **PRECONDICIÓN FALLIDA**: la solución no compila. El plan no arranca sobre una base que no cumple |

**Frase final:** «Lo que tengo en la cabeza ya no depende de mí: está en un plugin que el equipo instala en dos líneas».
