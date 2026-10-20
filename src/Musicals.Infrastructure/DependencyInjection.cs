using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Musicals.Application.Features.Shows;
using Musicals.Infrastructure.Features.Shows;
using Musicals.Infrastructure.Persistence;

namespace Musicals.Infrastructure;

public static class DependencyInjection
{
    public const string DatabaseName = "musicalsdb";

    public static IHostApplicationBuilder AddInfrastructure(this IHostApplicationBuilder builder)
    {
        ArgumentNullException.ThrowIfNull(builder);

        builder.AddSqlServerDbContext<MusicalsDbContext>(DatabaseName);
        builder.Services.AddScoped<IShowRepository, ShowRepository>();
        builder.Services.AddScoped<IShowQueries, ShowQueries>();
        return builder;
    }

    public static async Task InitializeDatabaseAsync(this IServiceProvider services, CancellationToken cancellationToken = default)
    {
        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<MusicalsDbContext>();
        await db.Database.EnsureCreatedAsync(cancellationToken).ConfigureAwait(false);
    }
}
