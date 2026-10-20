As a producer I want to add songs (musical numbers) to a show to build its repertoire.

## Acceptance criteria

- `POST /api/shows/{showId}/songs` with `{ "title": "The Mad Monk", "order": 1 }` returns **201** and the song's location.
- The title is required (200 characters max) and the order is an integer greater than 0. Otherwise, **400** with the error code.
- Two songs of the same show cannot have the same order: **409**.
- If the show does not exist: **404**.
- `GET /api/shows/{showId}/songs` returns the songs sorted by `order`.
