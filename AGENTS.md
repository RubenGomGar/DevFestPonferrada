# AGENTS.md

Instructions for coding agents working in this repo. Humans start with `README.md` (in Spanish).

## What this is

- **Musicals**: a .NET 10 API orchestrated with Aspire, built to the Plain Concepts Platform rules (Clean Architecture, vertical slices, `ErrorOr`, minimal APIs).
- **The demo** for the talk "Del MVP al harness" (DevFest Ponferrada 2026). `plugins/dotnet-team` is the harness built live, step by step.
- **Language**: code, comments, tests, issues and commits in English. READMEs and the talk script (`steps/`, `Internal-Demo-Readme.md`) in Spanish.

## Map

| Path | What |
|---|---|
| `src/Musicals.Domain` | Entities and domain errors. Depends on nothing |
| `src/Musicals.Application` | Handlers by feature (`Features/<Feature>`), return `ErrorOr<T>` |
| `src/Musicals.Infrastructure` | EF Core and persistence behind Application interfaces |
| `src/Musicals.Api` | Composition root; minimal API endpoints grouped by feature; ProblemDetails |
| `src/Musicals.AppHost` | Aspire: API, SQL Server, agent gateway, dashboard |
| `src/Musicals.ServiceDefaults` | `AddServiceDefaults()`: OpenTelemetry, health, resilience |
| `src/Musicals.AgentGateway` | Local YARP proxy in front of `api.anthropic.com`: telemetry and team-security-policy |
| `tests/Musicals.ArchitectureTests` | Layer and convention rules (NetArchTest). Guardrail |
| `tests/Musicals.AcceptanceTests` | HTTP tests with WebApplicationFactory + Testcontainers (needs Docker) |
| `tests/Musicals.AgentGateway.Tests` | Gateway unit tests |
| `plugins/dotnet-team` | Claude Code plugin: `/plan`, `/apply`, `/validate`, `/guardrails`, skills and hooks |
| `steps/` | Talk script, `step.ps1` (demo steps n0…n7), `gateway.ps1`, cached issues |

## Commands

```powershell
dotnet build Musicals.slnx                                       # warnings as errors + NuGet audit
dotnet test Musicals.slnx                                        # all tests (acceptance needs Docker)
dotnet test tests/Musicals.ArchitectureTests                     # fast: layers and conventions
dotnet run --project src/Musicals.AppHost --launch-profile http  # dashboard http://localhost:15056, gateway :5180
bash plugins/dotnet-team/tests/run.sh                            # harness script tests (no dotnet, no Docker)
```

A change is done when the build is green and the tests pass. Don't report success without running them.

## Rules

The source of truth is `plugins/dotnet-team/references/platform-rules.md`; every rule has an ID. Do not copy it here. The ones that bite most often:

- **Layers** (BE-ARCH-01/02, enforced by `tests/Musicals.ArchitectureTests`): Domain depends on nothing, Application doesn't use EF Core or Infrastructure, Api doesn't use the `DbContext` directly.
- **Slices** (BE-ARCH-03): organize by feature. No `Services`, `Repositories` or `Helpers` folders. Handlers are sealed and live in `Features`.
- **Errors** (BE-ERR-01/02): errors as values with `ErrorOr<T>`, translated to ProblemDetails at the endpoint. No exceptions for control flow.
- **Tests** (BE-TEST-01): new behavior gets acceptance tests over HTTP, following the existing `Shows` feature.
- **Time** (BE-TIME-01): `TimeProvider`, never `DateTime.Now` or `DateTime.UtcNow`.
- **Secrets** (BE-SEC-01, BE-ASPIRE-05): never in logs, never in `appsettings*.json`. Aspire injects connection strings by name.

When in doubt, copy the shape of the `Shows` feature across the four layers.

## Do not touch

These are guardrails. If one gets in your way, fix the code, not the rule. Changing a rule is a human decision.

- `Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`, `global.json`
- `tests/Musicals.ArchitectureTests/**`
- No `#pragma warning disable`, `<NoWarn>` or `[SuppressMessage]`. Fix the cause of the warning.

The list matches `is_guardrail_path` in `plugins/dotnet-team/scripts/lib.sh`, and the plugin's `guard-edits.sh` hook blocks those edits.

## Agent gateway and team-security-policy

When launched with `./steps/gateway.ps1`, every model request goes through `src/Musicals.AgentGateway` (`http://localhost:5180`):

- It listens only on localhost and never logs bodies or auth headers.
- **team-security-policy**: if any message, the system prompt or a tool result contains something that looks like a secret (API keys, GitHub/AWS tokens, private keys, connection-string passwords, JWTs), the request is **not** forwarded and the agent gets `403 permission_error` with the rule that matched.
- If that happens: don't retry and don't try to bypass it. Remove the secret from the conversation (`/rewind`) and stop reading files that contain secrets (`.env`, user secrets).
- Rules live in `Features/SecurityPolicy/SecretRules.cs`; `Enabled` and `FailClosed` live in the `TeamSecurityPolicy` section of `appsettings.json`.

## Demo constraints

- **Don't create `CLAUDE.md`.** Demo step N0 shows the agent looking for one and not finding it.
- Don't commit to `demo-live` by hand: `./steps/step.ps1 <step>` creates the commits and tags.
- `.work/` holds the plugin's runtime state (phase, plan, traces). Don't edit it by hand.
