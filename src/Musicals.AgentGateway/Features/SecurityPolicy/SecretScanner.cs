using System.Text.Json;

namespace Musicals.AgentGateway.Features.SecurityPolicy;

// Rule and place only: the matched value never leaves the scanner, so it cannot end up in a log.
internal sealed record SecretFinding(string Rule, string Location);

internal static class SecretScanner
{
    // Opaque payloads: base64 images and documents, encrypted thinking. Random bytes, not prompt text.
    private static readonly string[] OpaqueTypes = ["base64", "image", "redacted_thinking"];

    // Claude Code resends the whole history, so every message is scanned, not just the last one:
    // a blocked secret keeps blocking until it is removed from the conversation (/rewind).
    public static SecretFinding? Scan(JsonElement root)
    {
        if (root.TryGetProperty("system", out var system) && Find(system) is { } rule)
        {
            return new SecretFinding(rule, "system");
        }

        if (!root.TryGetProperty("messages", out var messages) || messages.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var index = 0;
        foreach (var message in messages.EnumerateArray())
        {
            if (message.TryGetProperty("content", out var content) && ScanContent(content) is { } found)
            {
                return new SecretFinding(found.Rule, $"messages[{index}].{found.Location}");
            }

            index++;
        }

        return null;
    }

    private static SecretFinding? ScanContent(JsonElement content)
    {
        if (content.ValueKind != JsonValueKind.Array)
        {
            return Find(content) is { } rule ? new SecretFinding(rule, "text") : null;
        }

        foreach (var block in content.EnumerateArray())
        {
            if (Find(block) is { } rule)
            {
                var type = block.TryGetProperty("type", out var t) && t.ValueKind == JsonValueKind.String ? t.GetString() : null;
                return new SecretFinding(rule, type ?? "content");
            }
        }

        return null;
    }

    // Walks every string in the element: text, tool_use input, tool_result content and nested blocks.
    private static string? Find(JsonElement element)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.String:
                var text = element.GetString() ?? "";
                return SecretRules.All.FirstOrDefault(r => r.Pattern.IsMatch(text))?.Name;

            case JsonValueKind.Array:
                foreach (var item in element.EnumerateArray())
                {
                    if (Find(item) is { } rule)
                    {
                        return rule;
                    }
                }

                return null;

            case JsonValueKind.Object:
                if (IsOpaque(element))
                {
                    return null;
                }

                foreach (var property in element.EnumerateObject())
                {
                    if (property.NameEquals("signature"))
                    {
                        continue;
                    }

                    if (Find(property.Value) is { } rule)
                    {
                        return rule;
                    }
                }

                return null;

            default:
                return null;
        }
    }

    private static bool IsOpaque(JsonElement element) =>
        element.TryGetProperty("type", out var type)
        && type.ValueKind == JsonValueKind.String
        && OpaqueTypes.Contains(type.GetString());
}
