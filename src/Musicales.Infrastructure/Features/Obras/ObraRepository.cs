using Musicales.Application.Features.Obras;
using Musicales.Domain.Obras;
using Musicales.Infrastructure.Persistence;

namespace Musicales.Infrastructure.Features.Obras;

internal sealed class ObraRepository(MusicalesDbContext db) : IObraRepository
{
    public async Task AddAsync(Obra obra, CancellationToken cancellationToken)
    {
        db.Obras.Add(obra);
        await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }
}
