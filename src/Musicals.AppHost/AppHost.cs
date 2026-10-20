var builder = DistributedApplication.CreateBuilder(args);

var sql = builder.AddSqlServer("sql")
    .WithLifetime(ContainerLifetime.Persistent)
    .WithDataVolume();

var db = sql.AddDatabase("musicalsdb");

builder.AddProject<Projects.Musicals_Api>("api")
    .WithReference(db)
    .WaitFor(db)
    .WithHttpHealthCheck("/health")
    .WithExternalHttpEndpoints();

builder.AddProject<Projects.Musicals_AgentGateway>("agent-gateway")
    .WithHttpHealthCheck("/health");

await builder.Build().RunAsync();
