using Musicals.AgentGateway.Features.Telemetry;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.Services.AddOpenTelemetry().WithMetrics(metrics => metrics.AddMeter(GatewayMetrics.MeterName));
builder.Services.AddSingleton<GatewayMetrics>();
builder.Services.AddReverseProxy().LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

var app = builder.Build();

app.UseMiddleware<TrafficCaptureMiddleware>();
app.MapDefaultEndpoints();
app.MapReverseProxy();

await app.RunAsync();
