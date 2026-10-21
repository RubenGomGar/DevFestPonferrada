---
name: dotnet-guardrails
description: Platform .NET backend guardrails (Clean Architecture, vertical slices, CQS, errors as values with ErrorOr, EF Core, Aspire, security). Use it whenever you design, plan, write or review backend C# code.
user-invocable: false
---

# .NET backend guardrails

Source: https://platform.plainconcepts.com/docs/backend. If the repository code and this skill disagree, the repository's reference slice wins and you point it out.

Those marked with 🔒 are checked by code (architecture tests, build or hooks): if you break them, something fails. The rest depend on your judgment.

## Layers

Dependencies point inwards.

| Project | Contains | May depend on |
|---|---|---|
| `*.Domain` | Entities, value objects, domain errors | `ErrorOr` |
| `*.Application` | Use cases (commands and queries), DTOs, the interfaces it needs | `Domain` |
| `*.Infrastructure` | EF Core and integrations; implements the `Application` interfaces | `Application` |
| `*.Api` | Minimal API endpoints per feature; composition root | all |

- 🔒 `Domain` depends on nobody. `Application` knows neither EF Core nor ASP.NET Core. `Api` does not use EF Core directly.
- 🔒 No generic technical folders (`Services`, `Repositories`, `Helpers`, `Managers`).

## Vertical slices and CQS

- A whole use case lives together: `Features/<Feature>/<Slice>/`.
- A command changes state and returns the minimum (usually the id). A query reads and never mutates.
- 🔒 `sealed` handlers in `Features`, registered in DI and injected into the endpoint. No mediator until it hurts.

## Errors as values

- 🔒 `Handle` returns `Task<ErrorOr<T>>`. Exceptions are for the exceptional, not for control flow.
- Codes `<Aggregate>.<Reason>` in a static `<Aggregate>Errors` class in the domain.
- The endpoint translates to ProblemDetails (RFC 7807) with `ToProblem()`: Validation → 400, NotFound → 404, Conflict → 409.

## Domain

- Static factory that returns `ErrorOr<Entity>` and validates invariants; private constructor.
- Dates from an injected `TimeProvider`; never `DateTime.Now` or `DateTime.UtcNow`.

## Data with EF Core

- Interfaces in `Application` (`I<Aggregate>Repository` writes, `I<Feature>Queries` reads); `Infrastructure` implements them.
- Reads with `AsNoTracking()` and DTO projection with `Select`. Avoid N+1 with explicit `Include` or split queries.
- Configuration with `IEntityTypeConfiguration<T>` in `Persistence/Configurations/`.

## Aspire

- A single AppHost; no docker-compose.
- Stateful containers: `ContainerLifetime.Persistent` and `.WithDataVolume()`.
- `.WaitFor(...)` on every reference.
- Every service calls `AddServiceDefaults()`.
- 🔒 Connection strings arrive by name from the AppHost; never in `appsettings*.json`.

## Security and observability

- `ILogger<T>` with message templates; never secrets or personal data in logs.
- `X-Robots-Tag: noindex, nofollow` on every response, from a middleware registered first.

## Build hygiene

- 🔒 `Directory.Build.props` (nullable, warnings as errors, analyzers) and `Directory.Packages.props` (centralized versions). They are not touched to make something compile.
- 🔒 Never `#pragma warning disable`, `NoWarn` or `SuppressMessage`. Fix the cause.
