using System.Diagnostics.Metrics;

namespace Musicals.AgentGateway.Features.Telemetry;

internal sealed class GatewayMetrics
{
    public const string MeterName = "Musicals.AgentGateway";

    private readonly Counter<long> _requests;
    private readonly Counter<long> _toolUses;
    private readonly Counter<long> _tokens;

    public GatewayMetrics(IMeterFactory meterFactory)
    {
        var meter = meterFactory.Create(MeterName);
        _requests = meter.CreateCounter<long>("gateway.requests", description: "Inference requests that go through the gateway");
        _toolUses = meter.CreateCounter<long>("gateway.tool_use", description: "Tools the agent has executed (skills, MCP, builtin)");
        _tokens = meter.CreateCounter<long>("gateway.tokens", unit: "{token}", description: "Tokens by type according to the response stream");
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
