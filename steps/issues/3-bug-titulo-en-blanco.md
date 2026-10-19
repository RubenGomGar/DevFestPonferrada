## Qué pasa

`POST /api/obras` con un título de solo espacios (`"titulo": "   "`) devuelve **201** y guarda una obra con el título vacío.

## Qué debería pasar

Devolver **400** con el error `Obra.TituloInvalido`, igual que con un título vacío.

## Cómo reproducirlo

```http
POST /api/obras
Content-Type: application/json

{ "titulo": "   ", "compositor": "Boney M." }
```
