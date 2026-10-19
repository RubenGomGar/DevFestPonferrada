---
name: dotnet-guardrails
description: Guardarraíles de backend .NET de Platform (Clean Architecture, vertical slices, CQS, errores como valores con ErrorOr, EF Core, Aspire, seguridad). Úsala siempre que diseñes, planifiques, escribas o revises código C# de backend.
user-invocable: false
---

# Guardarraíles de backend .NET

Fuente: https://platform.plainconcepts.com/docs/backend. Si el código del repositorio y esta skill discrepan, manda el slice de referencia del repositorio y lo señalas.

Los marcados con 🔒 los comprueba código (tests de arquitectura, build o hooks): si los rompes, falla algo. Los demás dependen de tu criterio.

## Capas

Las dependencias apuntan hacia dentro.

| Proyecto | Contiene | Puede depender de |
|---|---|---|
| `*.Domain` | Entidades, value objects, errores de dominio | `ErrorOr` |
| `*.Application` | Casos de uso (commands y queries), DTOs, interfaces que necesita | `Domain` |
| `*.Infrastructure` | EF Core e integraciones; implementa las interfaces de `Application` | `Application` |
| `*.Api` | Endpoints minimal API por feature; raíz de composición | todas |

- 🔒 `Domain` no depende de nadie. `Application` no conoce EF Core ni ASP.NET Core. `Api` no usa EF Core directamente.
- 🔒 Nada de carpetas técnicas genéricas (`Services`, `Repositories`, `Helpers`, `Managers`).

## Vertical slices y CQS

- Todo un caso de uso vive junto: `Features/<Feature>/<Slice>/`.
- Un command cambia estado y devuelve lo mínimo (normalmente el id). Una query lee y nunca muta.
- 🔒 Handlers `sealed` en `Features`, registrados en DI e inyectados en el endpoint. Sin mediador hasta que duela.

## Errores como valores

- 🔒 `Handle` devuelve `Task<ErrorOr<T>>`. Las excepciones son para lo excepcional, no para control de flujo.
- Códigos `<Agregado>.<Motivo>` en una clase estática `<Agregado>Errors` del dominio.
- El endpoint traduce a ProblemDetails (RFC 7807) con `ToProblem()`: Validation → 400, NotFound → 404, Conflict → 409.

## Dominio

- Fábrica estática que devuelve `ErrorOr<Entidad>` y valida invariantes; constructor privado.
- Fechas desde `TimeProvider` inyectado; nunca `DateTime.Now` ni `DateTime.UtcNow`.

## Datos con EF Core

- Interfaces en `Application` (`I<Agregado>Repository` escribe, `I<Feature>Queries` lee); `Infrastructure` las implementa.
- Lecturas con `AsNoTracking()` y proyección a DTO con `Select`. Evita N+1 con `Include` explícito o consultas divididas.
- Configuración con `IEntityTypeConfiguration<T>` en `Persistence/Configurations/`.

## Aspire

- Un único AppHost; sin docker-compose.
- Contenedores con estado: `ContainerLifetime.Persistent` y `.WithDataVolume()`.
- `.WaitFor(...)` en cada referencia.
- Todo servicio llama a `AddServiceDefaults()`.
- 🔒 Las connection strings llegan por nombre desde el AppHost; nunca en `appsettings*.json`.

## Seguridad y observabilidad

- `ILogger<T>` con plantillas de mensaje; nunca secretos ni datos personales en logs.
- `X-Robots-Tag: noindex, nofollow` en todas las respuestas, desde un middleware registrado primero.

## Higiene de build

- 🔒 `Directory.Build.props` (nullable, warnings como errores, analizadores) y `Directory.Packages.props` (versiones centralizadas). No se tocan para que algo compile.
- 🔒 Nunca `#pragma warning disable`, `NoWarn` ni `SuppressMessage`. Arregla la causa.
