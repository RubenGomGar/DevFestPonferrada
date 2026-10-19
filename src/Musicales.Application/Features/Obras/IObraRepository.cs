using Musicales.Domain.Obras;

namespace Musicales.Application.Features.Obras;

public interface IObraRepository
{
    Task AddAsync(Obra obra, CancellationToken cancellationToken);
}
