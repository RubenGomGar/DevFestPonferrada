using Musicales.Application.Features.Obras.ObtenerObra;

namespace Musicales.Application.Features.Obras;

public interface IObrasQueries
{
    Task<ObraDto?> ObtenerAsync(Guid id, CancellationToken cancellationToken);
}
