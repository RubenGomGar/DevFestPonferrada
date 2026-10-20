namespace Musicals.Application.Features.Shows.GetShow;

public sealed record ShowDto(Guid Id, string Title, string Composer, DateTimeOffset CreatedAt);
