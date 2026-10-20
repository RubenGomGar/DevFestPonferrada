using Musicals.Application.Features.Shows.GetShow;

namespace Musicals.Application.Features.Shows;

public interface IShowQueries
{
    Task<ShowDto?> GetAsync(Guid id, CancellationToken cancellationToken);
}
