using Musicals.AgentGateway.Features.SecurityPolicy;
using Musicals.AgentGateway.Features.Telemetry;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.Services.AddOpenTelemetry().WithMetrics(metrics => metrics.AddMeter(GatewayMetrics.MeterName));
builder.Services.AddSingleton<GatewayMetrics>();
builder.Services.Configure<TeamSecurityPolicyOptions>(builder.Configuration.GetSection(TeamSecurityPolicyOptions.SectionName));
builder.Services.AddReverseProxy().LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

var app = builder.Build();

// Telemetry first so a blocked request still shows up as → 403 in the log and the metrics.
app.UseMiddleware<TrafficCaptureMiddleware>();
app.UseMiddleware<TeamSecurityPolicyMiddleware>();
app.MapDefaultEndpoints();
app.MapReverseProxy();

await app.RunAsync();
