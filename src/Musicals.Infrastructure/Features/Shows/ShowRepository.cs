using Musicals.Application.Features.Shows;
using Musicals.Domain.Shows;
using Musicals.Infrastructure.Persistence;

namespace Musicals.Infrastructure.Features.Shows;

internal sealed class ShowRepository(MusicalsDbContext db) : IShowRepository
{
    public async Task AddAsync(Show show, CancellationToken cancellationToken)
    {
        db.Shows.Add(show);
        await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }
}
