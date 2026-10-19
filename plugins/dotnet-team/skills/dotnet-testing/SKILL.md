---
name: dotnet-testing
description: Qué tests escribir y dónde en un backend .NET según el trofeo de testing de Platform (integración vía HTTP con WebApplicationFactory y Testcontainers, unitarios solo con ramas reales, un test de regresión por bug). Úsala al escribir, planificar o revisar tests.
user-invocable: false
---

# Tests que fijan comportamiento

Fuente: https://platform.plainconcepts.com/docs/backend (Testing). Un test solo vale si falla cuando el comportamiento cambia.

## El trofeo

| Tipo | Cuándo | Dónde |
|---|---|---|
| Análisis estático | Siempre: compilador, analizadores, tests de arquitectura | `Directory.Build.props`, `tests/*.ArchitectureTests/` (🔒 no se tocan) |
| **Integración (la mayoría)** | Todo contrato HTTP: éxito y cada error | `tests/*.AcceptanceTests/Features/<Feature>/` |
| Unitarios | Solo lógica con ramas reales: reglas de dominio, cálculos, parsers, máquinas de estado | `tests/*.UnitTests/` |
| End-to-end | Pocos, solo recorridos críticos | — |

- Cada bug corregido lleva **un** test de regresión que lo reproduce.
- No se testean constantes, valores por defecto, mocks de tu propio código ni detalles de markup.

## Tests de aceptación (integración)

- Usa la colección compartida del proyecto (en Musicales, `[Collection(ApiFixture.Name)]` con `MusicalesApiFactory`) para reutilizar el SQL Server de Testcontainers.
- Se habla **solo HTTP y JSON**: `PostAsJsonAsync`, `GetAsync`, `ReadFromJsonAsync<JsonElement>`. No se referencian tipos de `src/` que todavía no existen; así el test compila antes de que exista la implementación.
- Por endpoint nuevo, como mínimo: el caso de éxito y cada error del contrato (400 con su código, 404, 409).
- Los errores se comprueban leyendo el ProblemDetails (`title` o la clave de `errors`), no solo el status.

## Convenciones

- Nombre: `<Caso>_<Escenario>_<Resultado>`, por ejemplo `AnadirNumero_a_obra_inexistente_devuelve_404`.
- Arrange, Act, Assert separados por una línea en blanco. Un comportamiento por test.
- Aserciones con Shouldly sobre lo observable: status, cuerpo, cabeceras, estado leído de vuelta por la API.
- Nunca un test sin aserción, ni `Skip`, ni `Thread.Sleep`.

## Si un test no pasa

No cambies `src/` ni el test para que pase. En `/plan` los tests nuevos **deben** fallar: describen comportamiento que aún no existe.
