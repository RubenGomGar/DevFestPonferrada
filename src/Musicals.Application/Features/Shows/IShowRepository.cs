using Musicals.Domain.Shows;

namespace Musicals.Application.Features.Shows;

public interface IShowRepository
{
    Task AddAsync(Show show, CancellationToken cancellationToken);
}
