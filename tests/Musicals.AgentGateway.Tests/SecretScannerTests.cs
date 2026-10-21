using System.Text.Json;
using Musicals.AgentGateway.Features.SecurityPolicy;
using Shouldly;

namespace Musicals.AgentGateway.Tests;

public class SecretScannerTests
{
    [Theory]
    [MemberData(nameof(Secrets))]
    public void Scan_each_rule_detects_its_secret(string rule, string secret)
    {
        var finding = Scan(Messages(Text(secret)));

        finding.ShouldNotBeNull().Rule.ShouldBe(rule);
    }

    [Fact]
    public void Scan_clean_prompt_finds_nothing()
    {
        var finding = Scan(Messages(Text("Implement issue #1: POST /api/shows/{showId}/songs returns 201. Password={password} comes from config.")));

        finding.ShouldBeNull();
    }

    [Fact]
    public void Scan_secret_in_system_is_found()
    {
        var finding = Scan($$"""{ "system": [{ "type": "text", "text": "{{Fake.GitHub}}" }], "messages": [] }""");

        finding.ShouldBe(new SecretFinding("github-token", "system"));
    }

    [Fact]
    public void Scan_secret_in_string_content_is_found()
    {
        var finding = Scan($$"""{ "messages": [{ "role": "user", "content": "use {{Fake.Anthropic}}" }] }""");

        finding.ShouldBe(new SecretFinding("anthropic-api-key", "messages[0].text"));
    }

    [Fact]
    public void Scan_secret_in_nested_tool_result_is_found_with_its_location()
    {
        var finding = Scan($$"""
            {
              "messages": [
                { "role": "user", "content": [{ "type": "text", "text": "read the env file" }] },
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "a", "name": "Read", "input": { "file_path": ".env" } }] },
                { "role": "user", "content": [{ "type": "tool_result", "tool_use_id": "a", "content": [{ "type": "text", "text": "AWS_KEY={{Fake.Aws}}" }] }] }
              ]
            }
            """);

        finding.ShouldBe(new SecretFinding("aws-access-key", "messages[2].tool_result"));
    }

    [Fact]
    public void Scan_secret_in_tool_use_input_is_found()
    {
        var finding = Scan($$"""
            {
              "messages": [
                { "role": "assistant", "content": [{ "type": "tool_use", "id": "w", "name": "Write", "input": { "content": "{{Fake.ConnectionString}}" } }] }
              ]
            }
            """);

        finding.ShouldBe(new SecretFinding("connection-string-password", "messages[0].tool_use"));
    }

    [Fact]
    public void Scan_secret_in_earlier_message_still_blocks()
    {
        var finding = Scan($$"""
            {
              "messages": [
                { "role": "user", "content": "{{Fake.GitHub}}" },
                { "role": "assistant", "content": "I can't use that." },
                { "role": "user", "content": "ok, something else" }
              ]
            }
            """);

        finding.ShouldBe(new SecretFinding("github-token", "messages[0].text"));
    }

    [Fact]
    public void Scan_opaque_payloads_are_skipped()
    {
        var finding = Scan($$"""
            {
              "messages": [
                { "role": "user", "content": [{ "type": "image", "source": { "type": "base64", "media_type": "image/png", "data": "{{Fake.Aws}}" } }] },
                { "role": "assistant", "content": [{ "type": "thinking", "thinking": "hmm", "signature": "{{Fake.Jwt}}" }] }
              ]
            }
            """);

        finding.ShouldBeNull();
    }

    [Fact]
    public void Scan_finding_never_carries_the_secret()
    {
        var finding = Scan(Messages(Text(Fake.GitHub)));

        finding.ShouldNotBeNull().ToString().ShouldNotContain(Fake.GitHub);
    }

    public static TheoryData<string, string> Secrets() => new()
    {
        { "anthropic-api-key", Fake.Anthropic },
        { "github-token", Fake.GitHub },
        { "github-token", "github" + "_pat_" + new string('b', 60) },
        { "aws-access-key", Fake.Aws },
        { "private-key", "-----BEGIN RSA " + "PRIVATE KEY-----" },
        { "azure-storage-key", "Account" + "Key=" + new string('c', 44) },
        { "connection-string-password", Fake.ConnectionString },
        { "jwt", Fake.Jwt },
    };

    private static SecretFinding? Scan(string json)
    {
        using var doc = JsonDocument.Parse(json);
        return SecretScanner.Scan(doc.RootElement);
    }

    private static string Messages(string block) =>
        $$"""{ "messages": [{ "role": "user", "content": [{{block}}] }] }""";

    private static string Text(string text) =>
        $$"""{ "type": "text", "text": {{JsonSerializer.Serialize(text)}} }""";

    // Built by concatenation so secret scanners (GitHub push protection) don't flag this file.
    internal static class Fake
    {
        public static readonly string Anthropic = "sk-" + "ant-api03-" + new string('x', 40);
        public static readonly string GitHub = "gh" + "p_" + new string('a', 36);
        public static readonly string Aws = "AKIA" + "IOSFODNN7EXAMPLE";
        public static readonly string ConnectionString = "Server=db;User Id=sa;Pass" + "word=hunter2!";
        public static readonly string Jwt = "eyJ" + "hbGciOiJIUzI1NiJ9.eyJ" + "zdWIiOiIxMjM0NTY3ODkwIn0.c2lnbmF0dXJlLXZhbHVl";
    }
}
