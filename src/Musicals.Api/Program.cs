using Musicals.Api.Common;
using Musicals.Api.Features.Shows;
using Musicals.Application;
using Musicals.Infrastructure;

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

app.MapShowsEndpoints();
app.MapDefaultEndpoints();

await app.RunAsync();

public partial class Program;
