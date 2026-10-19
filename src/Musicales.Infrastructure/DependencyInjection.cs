using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Musicales.Application.Features.Obras;
using Musicales.Infrastructure.Features.Obras;
using Musicales.Infrastructure.Persistence;

namespace Musicales.Infrastructure;

public static class DependencyInjection
{
    public const string DatabaseName = "musicalesdb";

    public static IHostApplicationBuilder AddInfrastructure(this IHostApplicationBuilder builder)
    {
        ArgumentNullException.ThrowIfNull(builder);

        builder.AddSqlServerDbContext<MusicalesDbContext>(DatabaseName);
        builder.Services.AddScoped<IObraRepository, ObraRepository>();
        builder.Services.AddScoped<IObrasQueries, ObrasQueries>();
        return builder;
    }

    public static async Task InitializeDatabaseAsync(this IServiceProvider services, CancellationToken cancellationToken = default)
    {
        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<MusicalesDbContext>();
        await db.Database.EnsureCreatedAsync(cancellationToken).ConfigureAwait(false);
    }
}
