namespace Musicales.Application.Features.Obras.ObtenerObra;

public sealed record ObraDto(Guid Id, string Titulo, string Compositor, DateTimeOffset CreadaEn);
