# Platform rules for .NET backends (snapshot)

Snapshot of https://platform.plainconcepts.com/docs/backend and https://platform.plainconcepts.com/docs/how-we-work taken on 2026-10-19.
Every `/validate` finding cites one of these IDs. If the website says otherwise, the website wins and this file gets updated.

Default severity: **high** breaks a guardrail that should fail the build or leaves the door open to the agent; **medium** departs from the convention; **low** is hygiene.

| ID | Rule | Fact that signals it | Severity |
|---|---|---|---|
| BE-ARCH-01 | Clean Architecture: Api, Application, Domain, Infrastructure projects (SharedKernel optional) | `layers` without the four layers | high |
| BE-ARCH-02 | Dependencies point inwards; Domain depends on nothing | project references pointing outwards | high |
| BE-ARCH-03 | Organize by feature (vertical slices), no `Services`, `Repositories`, `Helpers` folders | `generic_folders` | medium |
| BE-ARCH-04 | Commands and queries kept apart (CQS) | handlers that read and write at once; logic in `Program.cs` | medium |
| BE-ARCH-05 | Api is the composition root; minimal APIs grouped by feature | endpoints mapped loose in `Program.cs` | medium |
| BE-ERR-01 | Domain and application errors as values with `ErrorOr<T>` | `erroror` missing | high |
| BE-ERR-02 | Errors translated to ProblemDetails (RFC 7807) at the endpoint | `problem_details` missing | medium |
| BE-ERR-03 | Exceptions only for the exceptional, not for control flow | `throw_in_endpoints` | medium |
| BE-DATA-01 | EF Core in Infrastructure behind Application interfaces | `DbContext` outside Infrastructure | high |
| BE-DATA-02 | Reads with DTO projection and `AsNoTracking` | EF used without `AsNoTracking` | low |
| BE-TEST-01 | Trophy: mostly integration tests with WebApplicationFactory + Testcontainers over HTTP | `testcontainers` or `webapplicationfactory` missing | high |
| BE-TEST-02 | Unit tests only for logic with real branches; no tests of constants or mocks of your own code | trivial tests | low |
| BE-TEST-03 | Static analysis as the base: architecture tests that fail the build when crossing layers | `architecture_tests` missing | high |
| BE-BUILD-01 | Strict build: nullable, warnings as errors, analyzers | `treat_warnings_as_errors` or `nullable` missing | high |
| BE-BUILD-02 | Centralized package versions | `central_packages` missing | low |
| BE-BUILD-03 | Warnings are never silenced (`#pragma`, `NoWarn`, `SuppressMessage`) | `suppressions` | high |
| BE-ASPIRE-01 | A single AppHost; no docker-compose | `docker_compose` present or `apphost` missing | medium |
| BE-ASPIRE-02 | `.WaitFor(...)` on every resource reference | `with_reference` > `wait_for` | medium |
| BE-ASPIRE-03 | Every service calls `AddServiceDefaults()` | service without `add_service_defaults` | high |
| BE-ASPIRE-04 | Stateful containers: `ContainerLifetime.Persistent` and `.WithDataVolume()` | database without them | low |
| BE-ASPIRE-05 | Connection strings by name at runtime; never in `appsettings.json` | `appsettings_connection_strings` | high |
| BE-SEC-01 | `ILogger<T>` and OpenTelemetry; never secrets or personal data in logs | `console_writeline` or logs with sensitive data | medium |
| BE-SEC-02 | `X-Robots-Tag: noindex, nofollow` on every response from a middleware registered first | `x_robots_tag` missing | medium |
| BE-SEC-03 | Dependency and secret scanning in CI | `ci` without scanning | low |
| BE-TIME-01 | Dates from `TimeProvider`, not `DateTime.Now`/`UtcNow` | `datetime_now` | low |
| HWW-01 | Guardrails before giving the agent autonomy: "the guardrails are the product of phase 2, not a tax on it" | no architecture tests or strict build | high |
