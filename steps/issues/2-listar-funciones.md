Como espectador quiero ver las funciones programadas de una obra para elegir cuándo ir.

## Criterios de aceptación

- `POST /api/obras/{obraId}/funciones` con `{ "fecha": "2026-12-01T20:00:00Z", "teatro": "Teatro Calderón", "aforo": 900 }` devuelve **201**.
- No se pueden programar funciones en el pasado ni con aforo menor o igual que 0: **400**.
- `GET /api/obras/{obraId}/funciones` devuelve solo las funciones futuras, ordenadas por fecha.
- Si la obra no existe: **404** en ambos endpoints.
