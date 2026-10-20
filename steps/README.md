# Guion de la charla · Del MVP al harness

45 minutos. Acto 1 contado (sin prompts), acto 2 en directo, cierre con un `aspire new`.

| Min | Bloque | Material |
|---|---|---|
| 0–3 | Gancho: suena la canción de Rasputín. «¿Cómo repito esto mañana?» | MP3 del musical |
| 3–15 | **Acto 1** · la escalera del musical | [act1/README.md](act1/README.md) |
| 15–18 | Puente · vibe coding de la issue #1 | Vídeo grabado (N0) |
| 18–38 | **Acto 2** · la misma escalera en .NET | [act2/README.md](act2/README.md) |
| 38–43 | **Cierre** · `aspire new` → marketplace → `/validate` → `/guardrails` → `/plan` | [act2/README.md#cierre](act2/README.md#cierre) |
| 43–45 | Conclusión | «The guardrails are the product of phase 2, not a tax on it» |

## La escalera (la idea de la charla)

| Peldaño | Musical | .NET |
|---|---|---|
| Sin harness | Conversación → rock un día, ranchera al siguiente | Vibe coding: endpoint con lógica, sin tests |
| Skill | `maqueta-suno` | `dotnet-guardrails` + tests de arquitectura |
| Contrato de entrada | Instrumentos, estilo, tempo | La issue de GitHub vía MCP |
| Comando | `/compositor` | `/dotnet-team:plan <issue>` → `/dotnet-team:apply` |
| Orquestador | `letra-musical` → `maqueta-suno` | `dotnet-guardrails` + `dotnet-testing` |
| Hooks | Trazas | Trazas + guardia + puertas TDD (rojo antes, verde después) |
| Plugin | `musical@musical-marketplace` | `dotnet-team@netcoreconf-2026` |

## Antes de subir al escenario

- [ ] Docker arrancado y la imagen `mcr.microsoft.com/mssql/server:2022-latest` descargada.
- [ ] `dotnet build Musicals.slnx && dotnet test Musicals.slnx` en verde (calienta NuGet y Testcontainers).
- [ ] `gh auth status` correcto (el MCP de GitHub del plugin reutiliza esa sesión).
- [ ] Issues #1–#3 creadas y su copia en `steps/cache/` (plan B sin red).
- [ ] `./steps/step.ps1 n0` ejecutado: rama `demo-live` sin plugin.
- [ ] Ventana de terminal con fuente grande; `.work/` vacío.
- [ ] Vídeos de respaldo de N0 (vibe coding) y N5 (`/plan 3` → aprobar → `/apply`, de rojo a verde).

## Chuleta

```powershell
./steps/step.ps1 list          # qué trae cada paso
./steps/step.ps1 n0            # rama demo-live sin harness
./steps/step.ps1 n3            # ponerse al día si el directo se tuerce
git checkout n5                # saltar a un estado conocido
claude --plugin-dir plugins/dotnet-team
Get-Content .work/trace.jsonl  # qué se ha invocado
```
