## What happens

`POST /api/shows` with a whitespace-only title (`"title": "   "`) returns **201** and stores a show with an empty title.

## What should happen

Return **400** with the error `Show.InvalidTitle`, same as with an empty title.

## How to reproduce it

```http
POST /api/shows
Content-Type: application/json

{ "title": "   ", "composer": "Boney M." }
```
