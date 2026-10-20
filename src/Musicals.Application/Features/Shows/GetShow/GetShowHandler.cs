using ErrorOr;
using Musicals.Domain.Shows;

namespace Musicals.Application.Features.Shows.GetShow;

public sealed class GetShowHandler(IShowQueries queries)
{
    public async Task<ErrorOr<ShowDto>> Handle(Guid id, CancellationToken cancellationToken)
    {
        var show = await queries.GetAsync(id, cancellationToken).ConfigureAwait(false);
        return show is null ? ShowErrors.NotFound : show;
    }
}
