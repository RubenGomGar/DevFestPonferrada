using Microsoft.EntityFrameworkCore;
using Musicals.Application.Features.Shows;
using Musicals.Application.Features.Shows.GetShow;
using Musicals.Infrastructure.Persistence;

namespace Musicals.Infrastructure.Features.Shows;

internal sealed class ShowQueries(MusicalsDbContext db) : IShowQueries
{
    public Task<ShowDto?> GetAsync(Guid id, CancellationToken cancellationToken) =>
        db.Shows
            .AsNoTracking()
            .Where(s => s.Id == id)
            .Select(s => new ShowDto(s.Id, s.Title, s.Composer, s.CreatedAt))
            .SingleOrDefaultAsync(cancellationToken);
}
