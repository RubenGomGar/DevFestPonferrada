using ErrorOr;
using Musicales.Domain.Obras;

namespace Musicales.Application.Features.Obras.ObtenerObra;

public sealed class ObtenerObraHandler(IObrasQueries queries)
{
    public async Task<ErrorOr<ObraDto>> Handle(Guid id, CancellationToken cancellationToken)
    {
        var obra = await queries.ObtenerAsync(id, cancellationToken).ConfigureAwait(false);
        return obra is null ? ObraErrors.NoEncontrada : obra;
    }
}
