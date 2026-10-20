---
issue: 0
feature: kebab-case-del-nombre
status: draft
---

# Plan: título corto de la issue

## Objetivo

Una o dos frases con el comportamiento observable que cambia para quien usa la API.

## Guardarraíles aplicados

- Cada regla de `dotnet-guardrails` que condiciona este plan, en una línea, y cómo se respeta.

## Supuestos

- Cada ambigüedad de la issue, resuelta en una línea. Si no hay, escribe "Ninguno".

## Tareas

### T1 · NombreDelSlice · command

- Capas: Domain, Application, Infrastructure, Api
- Ficheros: `src/<App>.Application/Features/<Feature>/<Slice>/`, `src/<App>.Api/Features/<Feature>/<Feature>Endpoints.cs`
- Contrato HTTP: `POST /api/<recurso>` → 201 | 400 | 404
- Errores: `<Agregado>.<Motivo>` (Validation), `<Agregado>.NoEncontrada` (NotFound)
- Tests: `<Clase>Tests.<Caso>_..._devuelve_201`, `..._devuelve_400`, `..._devuelve_404`

## Tests de aceptación

| Test | Fichero | Por qué falla hoy |
|---|---|---|
| `Caso_escenario_resultado` | `tests/<App>.AcceptanceTests/Features/<Feature>/<Clase>Tests.cs` | El endpoint no existe (404) |

Un bloque por fichero nuevo, con su ruta en el encabezado. `/apply` lo copia tal cual a esa ruta y comprueba que falla antes de implementar.

#### `tests/<App>.AcceptanceTests/Features/<Feature>/<Clase>Tests.cs`

```csharp
// El fichero completo: usings, namespace y clase.
```

## Fuera de alcance

- Lo que alguien podría esperar y no se hace en este plan.
