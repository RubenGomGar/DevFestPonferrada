using ErrorOr;
using Musicals.Domain.Shows;

namespace Musicals.Application.Features.Shows.CreateShow;

public sealed class CreateShowHandler(IShowRepository repository, TimeProvider clock)
{
    public async Task<ErrorOr<Guid>> Handle(CreateShowCommand command, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        var show = Show.Create(command.Title, command.Composer, clock);
        if (show.IsError)
        {
            return show.Errors;
        }

        await repository.AddAsync(show.Value, cancellationToken).ConfigureAwait(false);
        return show.Value.Id;
    }
}
