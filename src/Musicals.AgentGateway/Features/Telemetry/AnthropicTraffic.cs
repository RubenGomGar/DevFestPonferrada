using System.Text.Json;

namespace Musicals.AgentGateway.Features.Telemetry;

internal enum ToolKind
{
    Builtin,
    Skill,
    Mcp,
}

internal sealed record ToolUse(string Tool, ToolKind Kind, string? Skill);

internal sealed record RequestSummary(string? Model, int Messages, int Tools, IReadOnlyList<ToolUse> ToolUses);

internal static class AnthropicTraffic
{
    private static readonly string[] SkillInputKeys = ["skill", "name", "command"];

    // Claude Code resends the full history on every request. To count each tool only once,
    // only the tool_use blocks whose result arrives in the last message are considered.
    public static RequestSummary ParseRequest(JsonElement root)
    {
        var model = root.TryGetProperty("model", out var m) && m.ValueKind == JsonValueKind.String ? m.GetString() : null;
        var tools = root.TryGetProperty("tools", out var t) && t.ValueKind == JsonValueKind.Array ? t.GetArrayLength() : 0;

        if (!root.TryGetProperty("messages", out var messages) || messages.ValueKind != JsonValueKind.Array)
        {
            return new RequestSummary(model, 0, tools, []);
        }

        var count = messages.GetArrayLength();
        if (count < 2 || Role(messages[count - 1]) != "user" || Role(messages[count - 2]) != "assistant")
        {
            return new RequestSummary(model, count, tools, []);
        }

        var answered = Blocks(messages[count - 1], "tool_result")
            .Select(b => b.TryGetProperty("tool_use_id", out var id) ? id.GetString() : null)
            .OfType<string>()
            .ToHashSet(StringComparer.Ordinal);

        var uses = Blocks(messages[count - 2], "tool_use")
            .Where(b => b.TryGetProperty("id", out var id) && answered.Contains(id.GetString() ?? ""))
            .Select(ToToolUse)
            .ToList();

        return new RequestSummary(model, count, tools, uses);
    }

    private static ToolUse ToToolUse(JsonElement block)
    {
        var name = block.TryGetProperty("name", out var n) ? n.GetString() ?? "unknown" : "unknown";

        if (name.StartsWith("mcp__", StringComparison.Ordinal))
        {
            return new ToolUse(name, ToolKind.Mcp, null);
        }

        if (name == "Skill")
        {
            return new ToolUse(name, ToolKind.Skill, SkillName(block));
        }

        return new ToolUse(name, ToolKind.Builtin, null);
    }

    private static string? SkillName(JsonElement block)
    {
        if (!block.TryGetProperty("input", out var input) || input.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        foreach (var key in SkillInputKeys)
        {
            if (input.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.String)
            {
                return value.GetString();
            }
        }

        return null;
    }

    private static string? Role(JsonElement message) =>
        message.TryGetProperty("role", out var role) ? role.GetString() : null;

    private static List<JsonElement> Blocks(JsonElement message, string type)
    {
        if (!message.TryGetProperty("content", out var content) || content.ValueKind != JsonValueKind.Array)
        {
            return [];
        }

        return content.EnumerateArray()
            .Where(b => b.TryGetProperty("type", out var bt) && bt.GetString() == type)
            .ToList();
    }
}
