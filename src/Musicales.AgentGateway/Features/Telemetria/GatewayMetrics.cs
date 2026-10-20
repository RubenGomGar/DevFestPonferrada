using System.Diagnostics.Metrics;

namespace Musicales.AgentGateway.Features.Telemetria;

internal sealed class GatewayMetrics
{
    public const string MeterName = "Musicales.AgentGateway";

    private readonly Counter<long> _requests;
    private readonly Counter<long> _toolUses;
    private readonly Counter<long> _tokens;

    public GatewayMetrics(IMeterFactory meterFactory)
    {
        var meter = meterFactory.Create(MeterName);
        _requests = meter.CreateCounter<long>("gateway.requests", description: "Peticiones de inferencia que pasan por el gateway");
        _toolUses = meter.CreateCounter<long>("gateway.tool_use", description: "Herramientas que el agente ha ejecutado (skills, MCP, builtin)");
        _tokens = meter.CreateCounter<long>("gateway.tokens", unit: "{token}", description: "Tokens por tipo según el stream de respuesta");
    }

    public void Request(string? model, int status) =>
        _requests.Add(1, new("model", model ?? "unknown"), new("status", status));

    public void ToolUse(ToolUse use, string? agent) =>
        _toolUses.Add(1,
            new("tool", use.Tool),
            new("kind", use.Kind.ToString().ToLowerInvariant()),
            new("skill", use.Skill ?? ""),
            new("agent", agent ?? "main"));

    public void Tokens(string? model, TokenUsage usage)
    {
        var m = model ?? "unknown";
        Add(m, "input", usage.Input);
        Add(m, "output", usage.Output);
        Add(m, "cache_read", usage.CacheRead);
        Add(m, "cache_creation", usage.CacheCreation);
    }

    private void Add(string model, string type, long value)
    {
        if (value > 0)
        {
            _tokens.Add(value, new("model", model), new("type", type));
        }
    }
}
