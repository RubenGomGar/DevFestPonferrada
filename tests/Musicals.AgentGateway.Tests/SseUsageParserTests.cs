using System.Text;
using Musicals.AgentGateway.Features.Telemetry;
using Shouldly;

namespace Musicals.AgentGateway.Tests;

public class SseUsageParserTests
{
    private const string Stream = """
        event: message_start
        data: {"type":"message_start","message":{"model":"claude-opus-5-5","usage":{"input_tokens":12,"cache_read_input_tokens":3400,"cache_creation_input_tokens":80,"output_tokens":1}}}

        event: ping
        data: {"type": "ping"}

        event: content_block_delta
        data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello naïve ☕ world"}}

        event: message_delta
        data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":57}}

        event: message_stop
        data: {"type":"message_stop"}

        """;

    [Fact]
    public void Feed_message_start_and_message_delta_add_up_tokens()
    {
        var parser = new SseUsageParser();

        parser.Feed(Encoding.UTF8.GetBytes(Stream));

        parser.Model.ShouldBe("claude-opus-5-5");
        parser.Usage.ShouldBe(new TokenUsage(Input: 12, Output: 57, CacheRead: 3400, CacheCreation: 80));
    }

    [Fact]
    public void Feed_chunks_splitting_lines_and_utf8_characters_still_works()
    {
        var parser = new SseUsageParser();
        var bytes = Encoding.UTF8.GetBytes(Stream);

        foreach (var chunk in bytes.Chunk(7))
        {
            parser.Feed(chunk);
        }

        parser.Usage.ShouldBe(new TokenUsage(Input: 12, Output: 57, CacheRead: 3400, CacheCreation: 80));
    }
}
