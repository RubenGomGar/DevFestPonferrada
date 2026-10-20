---
name: dotnet-testing
description: Which tests to write and where in a .NET backend according to the Platform testing trophy (integration over HTTP with WebApplicationFactory and Testcontainers, unit tests only for real branches, one regression test per bug). Use it when writing, planning or reviewing tests.
user-invocable: false
---

# Tests that pin down behavior

Source: https://platform.plainconcepts.com/docs/backend (Testing). A test is only worth it if it fails when the behavior changes.

## The trophy

| Type | When | Where |
|---|---|---|
| Static analysis | Always: compiler, analyzers, architecture tests | `Directory.Build.props`, `tests/*.ArchitectureTests/` (🔒 not touched) |
| **Integration (most of them)** | Every HTTP contract: success and each error | `tests/*.AcceptanceTests/Features/<Feature>/` |
| Unit | Only logic with real branches: domain rules, calculations, parsers, state machines | `tests/*.UnitTests/` |
| End-to-end | Few, only critical journeys | — |

- Every fixed bug gets **one** regression test that reproduces it.
- Do not test constants, default values, mocks of your own code or markup details.

## Acceptance tests (integration)

- Use the project's shared collection (in Musicals, `[Collection(ApiFixture.Name)]` with `MusicalsApiFactory`) to reuse the Testcontainers SQL Server.
- They speak **HTTP and JSON only**: `PostAsJsonAsync`, `GetAsync`, `ReadFromJsonAsync<JsonElement>`. No `src/` types that do not exist yet are referenced; that way the test compiles before the implementation exists.
- For each new endpoint, at least: the success case and each error in the contract (400 with its code, 404, 409).
- Errors are checked by reading the ProblemDetails (`title` or the `errors` key), not just the status.

## Conventions

- Name: `<Case>_<Scenario>_<Result>`, for example `AddSong_to_missing_show_returns_404`.
- Arrange, Act, Assert separated by a blank line. One behavior per test.
- Shouldly assertions on what is observable: status, body, headers, state read back through the API.
- Never a test without an assertion, nor `Skip`, nor `Thread.Sleep`.

## If a test does not pass

Do not change `src/` or the test to make it pass. In `/plan` the new tests **must** fail: they describe behavior that does not exist yet.
