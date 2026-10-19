using Musicales.Api.Common;
using Musicales.Api.Features.Obras;
using Musicales.Application;
using Musicales.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.AddInfrastructure();
builder.Services.AddApplication();
builder.Services.AddProblemDetails();
builder.Services.AddOpenApi();

var app = builder.Build();

app.UseNoIndex();
app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    await app.Services.InitializeDatabaseAsync();
}

app.MapObrasEndpoints();
app.MapDefaultEndpoints();

await app.RunAsync();

public partial class Program;
