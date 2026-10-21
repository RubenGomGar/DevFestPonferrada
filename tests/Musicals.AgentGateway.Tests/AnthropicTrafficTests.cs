using System.Text.Json;
using Musicals.AgentGateway.Features.Telemetry;
using Shouldly;

namespace Musicals.AgentGateway.Tests;

public class AnthropicTrafficTests
{
    [Fact]
    public void ParseRequest_tools_answered_in_last_message_are_the_only_ones_counted()
    {
        var summary = Parse("""
            {
              "model": "claude-opus-5-5",
              "tools": [{}, {}, {}],
              "messages": [
                { "role": "user", "content": [{ "type": "text", "text": "hello" }] },
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "a", "name": "Read", "input": {} }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "a" }] },
                { "role": "assistant", "content": [
                  { "type": "text", "text": "on it" },
                  { "type": "tool_use", "id": "b", "name": "Bash", "input": { "command": "ls" } },
                  { "type": "tool_use", "id": "c", "name": "Grep", "input": {} }
                ] },
                { "role": "user", "content": [
                  { "type": "tool_result", "tool_use_id": "b" },
                  { "type": "tool_result", "tool_use_id": "c" }
                ] }
              ]
            }
            """);

        summary.Model.ShouldBe("claude-opus-5-5");
        summary.Tools.ShouldBe(3);
        summary.ToolUses.Select(u => u.Tool).ShouldBe(["Bash", "Grep"]);
    }

    [Fact]
    public void ParseRequest_skill_is_classified_and_keeps_its_name()
    {
        var summary = Parse("""
            {
              "messages": [
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "s", "name": "Skill", "input": { "skill": "dotnet-team:dotnet-guardrails" } }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "s" }] }
              ]
            }
            """);

        summary.ToolUses.ShouldHaveSingleItem().ShouldBe(new ToolUse("Skill", ToolKind.Skill, "dotnet-team:dotnet-guardrails"));
    }

    [Fact]
    public void ParseRequest_skill_followed_by_its_content_in_another_user_message_is_counted()
    {
        var summary = Parse("""
            {
              "messages": [
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "s", "name": "Skill", "input": { "skill": "dotnet-team:dotnet-guardrails" } }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "s" }] },
                { "role": "user", "content": [{ "type": "text", "text": "# .NET backend guardrails" }] }
              ]
            }
            """);

        summary.ToolUses.ShouldHaveSingleItem().ShouldBe(new ToolUse("Skill", ToolKind.Skill, "dotnet-team:dotnet-guardrails"));
    }

    [Fact]
    public void ParseRequest_mcp_tool_is_classified_as_mcp()
    {
        var summary = Parse("""
            {
              "messages": [
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "m", "name": "mcp__github__issue_read", "input": {} }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "m" }] }
              ]
            }
            """);

        summary.ToolUses.ShouldHaveSingleItem().Kind.ShouldBe(ToolKind.Mcp);
    }

    [Fact]
    public void ParseRequest_new_user_prompt_does_not_count_tools_from_previous_turns()
    {
        var summary = Parse("""
            {
              "messages": [
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "a", "name": "Read", "input": {} }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "a" }] },
                { "role": "assistant", "content": [{ "type": "text", "text": "done" }] },
                { "role": "user", "content": [{ "type": "text", "text": "something else" }] }
              ]
            }
            """);

        summary.Messages.ShouldBe(4);
        summary.ToolUses.ShouldBeEmpty();
    }

    private static RequestSummary Parse(string json)
    {
        using var doc = JsonDocument.Parse(json);
        return AnthropicTraffic.ParseRequest(doc.RootElement);
    }
}
