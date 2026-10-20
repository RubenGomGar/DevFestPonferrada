using System.Text.Json;
using Musicales.AgentGateway.Features.Telemetria;
using Shouldly;

namespace Musicales.AgentGateway.Tests;

public class AnthropicTrafficTests
{
    [Fact]
    public void Solo_cuenta_las_herramientas_cuyo_resultado_llega_en_el_ultimo_mensaje()
    {
        var summary = Parse("""
            {
              "model": "claude-opus-5-5",
              "tools": [{}, {}, {}],
              "messages": [
                { "role": "user", "content": [{ "type": "text", "text": "hola" }] },
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "a", "name": "Read", "input": {} }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "a" }] },
                { "role": "assistant", "content": [
                  { "type": "text", "text": "voy" },
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
    public void Una_skill_se_clasifica_y_conserva_su_nombre()
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
    public void Una_herramienta_mcp_se_clasifica_como_mcp()
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
    public void Un_prompt_nuevo_del_usuario_no_cuenta_herramientas_de_turnos_anteriores()
    {
        var summary = Parse("""
            {
              "messages": [
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "a", "name": "Read", "input": {} }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "a" }] },
                { "role": "assistant", "content": [{ "type": "text", "text": "hecho" }] },
                { "role": "user", "content": [{ "type": "text", "text": "otra cosa" }] }
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
