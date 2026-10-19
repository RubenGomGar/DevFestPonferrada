using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.SqlClient;
using Testcontainers.MsSql;

namespace Musicales.AcceptanceTests.Infrastructure;

public sealed class MusicalesApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _sql = new MsSqlBuilder("mcr.microsoft.com/mssql/server:2022-latest")
        .Build();

    public Task InitializeAsync() => _sql.StartAsync();

    public new async Task DisposeAsync()
    {
        await _sql.DisposeAsync();
        await base.DisposeAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        var connectionString = new SqlConnectionStringBuilder(_sql.GetConnectionString())
        {
            InitialCatalog = "musicalesdb",
        }.ConnectionString;

        builder.UseEnvironment("Development");
        builder.UseSetting("ConnectionStrings:musicalesdb", connectionString);
    }
}

[CollectionDefinition(Name)]
public sealed class ApiFixture : ICollectionFixture<MusicalesApiFactory>
{
    public const string Name = "api";
}
