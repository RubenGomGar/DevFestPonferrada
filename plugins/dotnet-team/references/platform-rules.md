# Reglas de Platform para backends .NET (snapshot)

Snapshot de https://platform.plainconcepts.com/docs/backend y https://platform.plainconcepts.com/docs/how-we-work tomado el 2026-10-19.
Cada hallazgo de `/validate` cita uno de estos IDs. Si la web dice otra cosa, manda la web y se actualiza este fichero.

Severidad por defecto: **alta** rompe un guardarraíl que debería fallar el build o deja la puerta abierta al agente; **media** se aparta de la convención; **baja** es higiene.

| ID | Regla | Hecho que lo indica | Severidad |
|---|---|---|---|
| BE-ARCH-01 | Clean Architecture: proyectos Api, Application, Domain, Infrastructure (SharedKernel opcional) | `layers` sin las cuatro capas | alta |
| BE-ARCH-02 | Las dependencias apuntan hacia dentro; Domain no depende de nada | referencias de proyecto hacia fuera | alta |
| BE-ARCH-03 | Organizar por feature (vertical slices), sin carpetas `Services`, `Repositories`, `Helpers` | `generic_folders` | media |
| BE-ARCH-04 | Commands y queries separados (CQS) | handlers que leen y escriben a la vez; lógica en `Program.cs` | media |
| BE-ARCH-05 | Api es la raíz de composición; minimal APIs agrupadas por feature | endpoints mapeados sueltos en `Program.cs` | media |
| BE-ERR-01 | Errores de dominio y aplicación como valores con `ErrorOr<T>` | `erroror` ausente | alta |
| BE-ERR-02 | Errores traducidos a ProblemDetails (RFC 7807) en el endpoint | `problem_details` ausente | media |
| BE-ERR-03 | Excepciones solo para lo excepcional, no control de flujo | `throw_in_endpoints` | media |
| BE-DATA-01 | EF Core en Infrastructure tras interfaces de Application | `DbContext` fuera de Infrastructure | alta |
| BE-DATA-02 | Lecturas con proyección a DTO y `AsNoTracking` | EF usado sin `AsNoTracking` | baja |
| BE-TEST-01 | Trofeo: la mayoría tests de integración con WebApplicationFactory + Testcontainers vía HTTP | `testcontainers` o `webapplicationfactory` ausentes | alta |
| BE-TEST-02 | Unitarios solo para lógica con ramas reales; nada de tests de constantes ni mocks propios | tests triviales | baja |
| BE-TEST-03 | Análisis estático como base: tests de arquitectura que fallan el build al cruzar capas | `architecture_tests` ausente | alta |
| BE-BUILD-01 | Build estricto: nullable, warnings como errores, analizadores | `treat_warnings_as_errors` o `nullable` ausentes | alta |
| BE-BUILD-02 | Versiones de paquetes centralizadas | `central_packages` ausente | baja |
| BE-BUILD-03 | Nunca se silencian avisos (`#pragma`, `NoWarn`, `SuppressMessage`) | `suppressions` | alta |
| BE-ASPIRE-01 | Un único AppHost; sin docker-compose | `docker_compose` presente o `apphost` ausente | media |
| BE-ASPIRE-02 | `.WaitFor(...)` en cada referencia de recurso | `with_reference` > `wait_for` | media |
| BE-ASPIRE-03 | Todo servicio llama a `AddServiceDefaults()` | servicio sin `add_service_defaults` | alta |
| BE-ASPIRE-04 | Contenedores con estado: `ContainerLifetime.Persistent` y `.WithDataVolume()` | base de datos sin ellos | baja |
| BE-ASPIRE-05 | Connection strings por nombre en runtime; nunca en `appsettings.json` | `appsettings_connection_strings` | alta |
| BE-SEC-01 | `ILogger<T>` y OpenTelemetry; nunca secretos ni datos personales en logs | `console_writeline` o logs con datos sensibles | media |
| BE-SEC-02 | `X-Robots-Tag: noindex, nofollow` en toda respuesta desde un middleware registrado primero | `x_robots_tag` ausente | media |
| BE-SEC-03 | Escaneo de dependencias y secretos en CI | `ci` sin escaneo | baja |
| BE-TIME-01 | Fechas desde `TimeProvider`, no `DateTime.Now`/`UtcNow` | `datetime_now` | baja |
| HWW-01 | Guardarraíles antes de dar autonomía al agente: "the guardrails are the product of phase 2, not a tax on it" | sin tests de arquitectura ni build estricto | alta |
