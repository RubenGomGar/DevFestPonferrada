using System.Text;
using System.Text.Json;

namespace Musicales.AgentGateway.Features.Telemetria;

internal sealed record TokenUsage(long Input, long Output, long CacheRead, long CacheCreation);

// Lee el stream SSE de /v1/messages según llega, sin retenerlo: solo guarda la línea en curso.
internal sealed class SseUsageParser
{
    private const string DataPrefix = "data:";

    private readonly List<byte> _line = [];
    private long _input;
    private long _output;
    private long _cacheRead;
    private long _cacheCreation;

    public string? Model { get; private set; }

    public TokenUsage Usage => new(_input, _output, _cacheRead, _cacheCreation);

    public void Feed(ReadOnlySpan<byte> chunk)
    {
        foreach (var b in chunk)
        {
            if (b == (byte)'\n')
            {
                ProcessLine(Encoding.UTF8.GetString([.. _line]).TrimEnd('\r'));
                _line.Clear();
            }
            else
            {
                _line.Add(b);
            }
        }
    }

    private void ProcessLine(string line)
    {
        if (!line.StartsWith(DataPrefix, StringComparison.Ordinal))
        {
            return;
        }

        try
        {
            using var doc = JsonDocument.Parse(line.AsMemory(DataPrefix.Length));
            var root = doc.RootElement;
            switch (root.TryGetProperty("type", out var type) ? type.GetString() : null)
            {
                case "message_start" when root.TryGetProperty("message", out var message):
                    Model = message.TryGetProperty("model", out var model) ? model.GetString() : Model;
                    if (message.TryGetProperty("usage", out var start))
                    {
                        _input = Read(start, "input_tokens", _input);
                        _cacheRead = Read(start, "cache_read_input_tokens", _cacheRead);
                        _cacheCreation = Read(start, "cache_creation_input_tokens", _cacheCreation);
                        _output = Read(start, "output_tokens", _output);
                    }

                    break;
                case "message_delta" when root.TryGetProperty("usage", out var delta):
                    _output = Read(delta, "output_tokens", _output);
                    break;
            }
        }
        catch (JsonException)
        {
            // Una línea que no es JSON (ping, comentario) no debe afectar al tráfico.
        }
    }

    private static long Read(JsonElement usage, string name, long current) =>
        usage.TryGetProperty(name, out var value) && value.TryGetInt64(out var tokens) ? tokens : current;
}
