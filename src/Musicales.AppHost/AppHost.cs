var builder = DistributedApplication.CreateBuilder(args);

var sql = builder.AddSqlServer("sql")
    .WithLifetime(ContainerLifetime.Persistent)
    .WithDataVolume();

var db = sql.AddDatabase("musicalesdb");

builder.AddProject<Projects.Musicales_Api>("api")
    .WithReference(db)
    .WaitFor(db)
    .WithHttpHealthCheck("/health")
    .WithExternalHttpEndpoints();

await builder.Build().RunAsync();
