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
    // only the tool_use blocks whose result arrives in the trailing user messages are considered.
    // A Skill result is followed by another user message carrying the skill content.
    public static RequestSummary ParseRequest(JsonElement root)
    {
        var model = root.TryGetProperty("model", out var m) && m.ValueKind == JsonValueKind.String ? m.GetString() : null;
        var tools = root.TryGetProperty("tools", out var t) && t.ValueKind == JsonValueKind.Array ? t.GetArrayLength() : 0;

        if (!root.TryGetProperty("messages", out var messages) || messages.ValueKind != JsonValueKind.Array)
        {
            return new RequestSummary(model, 0, tools, []);
        }

        var count = messages.GetArrayLength();
        var assistant = count - 1;
        while (assistant >= 0 && Role(messages[assistant]) == "user")
        {
            assistant--;
        }

        if (assistant < 0 || assistant == count - 1 || Role(messages[assistant]) != "assistant")
        {
            return new RequestSummary(model, count, tools, []);
        }

        var answered = Enumerable.Range(assistant + 1, count - assistant - 1)
            .SelectMany(i => Blocks(messages[i], "tool_result"))
            .Select(b => b.TryGetProperty("tool_use_id", out var id) ? id.GetString() : null)
            .OfType<string>()
            .ToHashSet(StringComparer.Ordinal);

        var uses = Blocks(messages[assistant], "tool_use")
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
