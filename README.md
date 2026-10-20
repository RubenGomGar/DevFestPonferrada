# Del MVP al harness

Charla de NetCoreConf Madrid 2026. Cómo convertir una idea hecha con AI en algo que se repite, se distribuye y se usa siempre igual, primero con un musical y después en un equipo .NET.

> Un agente no es un modelo: es un modelo **más el harness que lo rodea**. El valor no está en el prompt, está en una arquitectura de piezas pequeñas con responsabilidades claras.

## La historia

Llevo dos años buscando cómo la AI puede trabajar con música. La última iteración fue un micro musical sobre Rasputín: el malo malísimo que empieza odiado y acaba querido, con los instrumentos de *Next to Normal*.

Conversando con la AI llegué al MIDI, pero no a una producción con instrumentos reales. Suno sí suena bien, aunque es muy poco determinista: con el mismo prompt sale un rock un día y una ranchera al siguiente. El MVP fue este: **¿y si a Suno le paso un MIDI y un prompt muy concreto?** Funcionó. Tengo un MP3 que no paro de tararear.

El problema llega después: **¿cómo lo repito mañana?** Aunque entienda cómo lo hice, en una sesión nueva vuelvo a empezar y no saco lo mismo. Ahí entra el harness: contexto, skills, comandos, agentes, guardarraíles y hooks que rodean a la AI y reducen el no determinismo.

## La escalera

La charla sube la misma escalera dos veces. Primero con el musical, contado. Después con .NET, en directo.

| Peldaño | Acto 1 · Musical | Acto 2 · .NET |
|---|---|---|
| Sin harness | Conversación: rock un día, ranchera al siguiente | Vibe coding: lógica en el endpoint, sin tests |
| Skill | `maqueta-suno`: el paso a paso extraído | `dotnet-guardrails`: Platform condensado, más tests de arquitectura |
| Contrato de entrada | Instrumentos, estilo, tempo | La issue de GitHub, vía MCP |
| Comando | `/compositor`: nadie tiene que escribir el prompt bueno | `/dotnet-team:plan <issue>` |
| Orquestador | `letra-musical` → puerta humana → `maqueta-suno` | `/plan` → puerta humana (`approved`) → `/apply`, con `dotnet-guardrails` + `dotnet-testing` |
| Hooks | Trazas de qué se invoca | Trazas + guardia de escrituras + puertas TDD deterministas (rojo antes, verde después) |
| Plugin | `musical@musical-marketplace` | `dotnet-team@netcoreconf-2026` |

El expertise que el equipo lleva en la cabeza solo escala si la AI lo puede leer (skills) y si hay algo que la obliga a respetarlo (tests, hooks, puertas).

## Qué hay en el repo

| Carpeta | Qué es |
|---|---|
| [`steps/`](steps/README.md) | Guion de 45 minutos, chuleta, material de los dos actos y `step.ps1` para avanzar la demo |
| `src/Musicals.*` | API .NET 10 con Aspire siguiendo [Platform](https://platform.plainconcepts.com/docs/backend): Clean Architecture, vertical slices, CQS, `ErrorOr`, EF Core, SQL Server |
| `tests/Musicals.ArchitectureTests` | Los guardarraíles convertidos en código: capas, dependencias, handlers `sealed` que devuelven `ErrorOr` |
| `tests/Musicals.AcceptanceTests` | Tests de integración vía HTTP con `WebApplicationFactory` + Testcontainers |
| [`plugins/dotnet-team/`](plugins/dotnet-team/README.md) | El harness que se construye en el acto 2 |
| `src/Musicals.AgentGateway` | Gateway LLM local (YARP) que mide skills, herramientas y tokens de Claude Code |
| `.claude-plugin/marketplace.json` | Este repo es también el marketplace del plugin |

El musical vive aparte, en `C:\Charlas\musical-plugin`.

## Empezar

Requisitos: .NET SDK 10, Docker, Git Bash (en Windows) y Claude Code.

```powershell
dotnet build Musicals.slnx                                   # warnings como errores y auditoría de paquetes
dotnet test Musicals.slnx                                    # arquitectura, aceptación (Testcontainers) y gateway
dotnet run --project src/Musicals.AppHost --launch-profile http   # API + SQL + gateway + dashboard en http://localhost:15056
```

Las [issues #1–#3](https://github.com/RubenGomGar/NetCoreConfMadrid2026/issues) son las de la demo: un command, una query y un bug sembrado (un título de solo espacios se acepta).

## El harness: `dotnet-team`

```text
/plugin marketplace add RubenGomGar/NetCoreConfMadrid2026
/plugin install dotnet-team@netcoreconf-2026
```

| Comando | Qué hace | Puerta (hook `Stop`) |
|---|---|---|
| `/dotnet-team:plan <issue>` | Lee la issue con el MCP de GitHub y escribe solo `.work/plan.md` en `draft`, con los tests de aceptación dentro | Forma del plan y convenciones de `dotnet-testing` en los tests; nada fuera de `.work/` |
| `/dotnet-team:apply` | Con el plan en `approved`, copia sus tests, comprueba que **todos fallan** (TDD) e implementa | Tests del plan intactos, compila, arquitectura y **todos** los tests en verde |
| `/dotnet-team:validate [carpeta]` | `facts.sh` calcula los hechos; el agente `platform-reviewer` los contrasta con las reglas de Platform | Cada hallazgo cita una regla existente y el veredicto es coherente |
| `/dotnet-team:guardrails` | Instala build estricto, `.editorconfig` y tests de arquitectura genéricos en cualquier solución | — (enseña qué falla) |

Cada comando tiene la misma anatomía:

1. **Precondición** (script): si no se cumple, el comando no arranca.
2. **Contexto precalculado** (script): hechos inyectados antes de que el modelo lea nada.
3. **Juicio** (modelo, skills y agentes): lo único que no se puede automatizar.
4. **Puerta de salida** (hook): el turno no termina hasta que el resultado cumple el contrato.

La guardia `PreToolUse` impide tocar los guardarraíles, silenciar avisos o meter connection strings, en `/plan` solo deja escribir el plan y en `/apply` no deja tocar los tests del plan. Los scripts del harness tienen sus propios tests: `bash plugins/dotnet-team/tests/run.sh`.

Probado sobre un `dotnet new aspire-starter` recién creado:

- `/validate` devuelve `NON_COMPLIANT` con 12 hallazgos.
- `/guardrails` pone el build en rojo: la plantilla trae paquetes vulnerables.
- `/plan` se niega a arrancar sobre una base que no compila.

## Observar al agente: hook, gateway y OpenTelemetry

Así es como se monitoriza el uso de skills, pero hecho en .NET con YARP:

```powershell
./steps/gateway.ps1 -Otel     # claude vía http://localhost:5180 y su telemetría al dashboard de Aspire
```

| Capa | Quién decide qué se ve | Qué aparece |
|---|---|---|
| Hook (`trace.sh`) | El autor del plugin | `.work/trace.jsonl` |
| Gateway | Quien controla la red | `tools [Skill(dotnet-team:dotnet-testing)] · tokens in 4 out 93 cache 55626` y las métricas `gateway.tool_use` y `gateway.tokens` |
| OpenTelemetry nativo | El propio agente | `claude_code.user_prompt`, `api_request`, `skill_activated`, `tool_result`… |

Detalles del gateway:

- Lee los tokens del SSE mientras pasa, sin retenerlo; si lo retiene, Claude Code se cuelga.
- Cuenta cada herramienta una sola vez aunque el historial se reenvíe entero.
- Reenvía `anthropic-beta` intacto, que es lo que necesita la sesión OAuth.

Ve tokens de sesión y código, así que solo escucha en localhost y nunca registra cuerpos ni cabeceras de autenticación.

## Lecciones

1. **Comando = orquestador, skills = expertos, scripts = músculo.** No mezcles roles.
2. **Los artefactos intermedios son contratos.** El plan y la letra se documentan como una API.
3. **Puertas humanas antes de lo caro**, no después.
4. **Lo que se puede calcular, se calcula.** Y lo que se calcula, se testea, incluidos los propios guardarraíles: NetArchTest no veía dentro de las lambdas y un test lo destapó.
5. **Las reglas se ejecutan, no se recomiendan.** Una skill aconseja; un test de arquitectura y un hook obligan.
6. **Distribuye como plugin desde el día uno.** Un marketplace cuesta un fichero JSON.

> *The guardrails are the product of phase 2, not a tax on it.* — Platform, Plain Concepts
