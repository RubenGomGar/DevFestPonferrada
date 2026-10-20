using Musicales.Api.Common;
using Musicales.Application.Features.Obras.CrearObra;
using Musicales.Application.Features.Obras.ObtenerObra;

namespace Musicales.Api.Features.Obras;

internal static class ObrasEndpoints
{
    public static IEndpointRouteBuilder MapObrasEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/obras").WithTags("Obras");

        group.MapPost("/", CrearObra).WithName(nameof(CrearObra));
        group.MapGet("/{id:guid}", ObtenerObra).WithName(nameof(ObtenerObra));
        // group.MapGet("/todas", async (Musicales.Infrastructure.Persistence.MusicalesDbContext db) =>
        //     await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(db.Obras));

        return app;
    }

    private static async Task<IResult> CrearObra(
        CrearObraCommand command,
        CrearObraHandler handler,
        CancellationToken cancellationToken)
    {
        var result = await handler.Handle(command, cancellationToken).ConfigureAwait(false);
        return result.Match(
            id => TypedResults.CreatedAtRoute(new { id }, nameof(ObtenerObra), new { id }),
            errors => errors.ToProblem());
    }

    private static async Task<IResult> ObtenerObra(
        Guid id,
        ObtenerObraHandler handler,
        CancellationToken cancellationToken)
    {
        var result = await handler.Handle(id, cancellationToken).ConfigureAwait(false);
        return result.Match(obra => TypedResults.Ok(obra), errors => errors.ToProblem());
    }
}
