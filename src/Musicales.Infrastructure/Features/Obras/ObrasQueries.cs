using Microsoft.EntityFrameworkCore;
using Musicales.Application.Features.Obras;
using Musicales.Application.Features.Obras.ObtenerObra;
using Musicales.Infrastructure.Persistence;

namespace Musicales.Infrastructure.Features.Obras;

internal sealed class ObrasQueries(MusicalesDbContext db) : IObrasQueries
{
    public Task<ObraDto?> ObtenerAsync(Guid id, CancellationToken cancellationToken) =>
        db.Obras
            .AsNoTracking()
            .Where(o => o.Id == id)
            .Select(o => new ObraDto(o.Id, o.Titulo, o.Compositor, o.CreadaEn))
            .SingleOrDefaultAsync(cancellationToken);
}
