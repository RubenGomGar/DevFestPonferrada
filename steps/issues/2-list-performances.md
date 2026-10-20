As an audience member I want to see the scheduled performances of a show to choose when to go.

## Acceptance criteria

- `POST /api/shows/{showId}/performances` with `{ "date": "2026-12-01T20:00:00Z", "theater": "Teatro Calderón", "capacity": 900 }` returns **201**.
- Performances cannot be scheduled in the past or with a capacity less than or equal to 0: **400**.
- `GET /api/shows/{showId}/performances` returns only future performances, sorted by date.
- If the show does not exist: **404** on both endpoints.
