Como productora quiero añadir números (canciones) a una obra para construir su repertorio.

## Criterios de aceptación

- `POST /api/obras/{obraId}/numeros` con `{ "titulo": "El monje loco", "orden": 1 }` devuelve **201** y la ubicación del número.
- El título es obligatorio (máximo 200 caracteres) y el orden es un entero mayor que 0. Si no, **400** con el código del error.
- Dos números de la misma obra no pueden tener el mismo orden: **409**.
- Si la obra no existe: **404**.
- `GET /api/obras/{obraId}/numeros` devuelve los números ordenados por `orden`.
