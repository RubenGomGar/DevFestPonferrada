---
issue: 0
feature: kebab-case-name
status: draft
---

# Plan: short issue title

## Goal

One or two sentences with the observable behavior that changes for whoever uses the API.

## Guardrails applied

- Each `dotnet-guardrails` rule that shapes this plan, in one line, and how it is respected.

## Assumptions

- Each ambiguity in the issue, resolved in one line. If there are none, write "None".

## Tasks

### T1 · SliceName · command

- Layers: Domain, Application, Infrastructure, Api
- Files: `src/<App>.Application/Features/<Feature>/<Slice>/`, `src/<App>.Api/Features/<Feature>/<Feature>Endpoints.cs`
- HTTP contract: `POST /api/<resource>` → 201 | 400 | 404
- Errors: `<Aggregate>.<Reason>` (Validation), `<Aggregate>.NotFound` (NotFound)
- Tests: `<Class>Tests.<Case>_..._returns_201`, `..._returns_400`, `..._returns_404`

## Acceptance tests

| Test | File | Why it fails today |
|---|---|---|
| `Case_scenario_result` | `tests/<App>.AcceptanceTests/Features/<Feature>/<Class>Tests.cs` | The endpoint does not exist (404) |

One block per new file, with its path in the heading. `/apply` copies it as is to that path and checks that it fails before implementing.

#### `tests/<App>.AcceptanceTests/Features/<Feature>/<Class>Tests.cs`

```csharp
// The full file: usings, namespace and class.
```

## Out of scope

- What someone might expect and is not done in this plan.
