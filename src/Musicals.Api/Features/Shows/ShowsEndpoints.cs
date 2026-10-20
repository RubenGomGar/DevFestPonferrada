using Musicals.Api.Common;
using Musicals.Application.Features.Shows.CreateShow;
using Musicals.Application.Features.Shows.GetShow;

namespace Musicals.Api.Features.Shows;

internal static class ShowsEndpoints
{
    public static IEndpointRouteBuilder MapShowsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/shows").WithTags("Shows");

        group.MapPost("/", CreateShow).WithName(nameof(CreateShow));
        group.MapGet("/{id:guid}", GetShow).WithName(nameof(GetShow));

        return app;
    }

    private static async Task<IResult> CreateShow(
        CreateShowCommand command,
        CreateShowHandler handler,
        CancellationToken cancellationToken)
    {
        var result = await handler.Handle(command, cancellationToken).ConfigureAwait(false);
        return result.Match(
            id => TypedResults.CreatedAtRoute(new { id }, nameof(GetShow), new { id }),
            errors => errors.ToProblem());
    }

    private static async Task<IResult> GetShow(
        Guid id,
        GetShowHandler handler,
        CancellationToken cancellationToken)
    {
        var result = await handler.Handle(id, cancellationToken).ConfigureAwait(false);
        return result.Match(show => TypedResults.Ok(show), errors => errors.ToProblem());
    }
}
