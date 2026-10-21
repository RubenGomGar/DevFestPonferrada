using System.Diagnostics.Metrics;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Musicals.AgentGateway.Features.SecurityPolicy;
using Musicals.AgentGateway.Features.Telemetry;
using Shouldly;

namespace Musicals.AgentGateway.Tests;

public class TeamSecurityPolicyMiddlewareTests
{
    private const string CleanBody = """{ "messages": [{ "role": "user", "content": "hello" }] }""";

    [Fact]
    public async Task InvokeAsync_clean_prompt_is_forwarded_with_its_body_intact()
    {
        var (context, forwarded) = await RunAsync(CleanBody);

        forwarded.ShouldBeTrue();
        context.Response.StatusCode.ShouldBe(200);
        context.Request.Body.Position.ShouldBe(0);
    }

    [Fact]
    public async Task InvokeAsync_prompt_with_secret_is_blocked_with_an_anthropic_error()
    {
        var body = JsonSerializer.Serialize(new { messages = new[] { new { role = "user", content = "token " + SecretScannerTests.Fake.GitHub } } });

        var (context, forwarded) = await RunAsync(body);

        forwarded.ShouldBeFalse();
        context.Response.StatusCode.ShouldBe(403);
        using var error = JsonDocument.Parse(ResponseText(context));
        error.RootElement.GetProperty("type").GetString().ShouldBe("error");
        error.RootElement.GetProperty("error").GetProperty("type").GetString().ShouldBe("permission_error");
        var message = error.RootElement.GetProperty("error").GetProperty("message").GetString();
        message.ShouldNotBeNull().ShouldContain("github-token");
        message.ShouldNotContain(SecretScannerTests.Fake.GitHub);
    }

    [Fact]
    public async Task InvokeAsync_compressed_body_is_blocked_when_failing_closed()
    {
        var (context, forwarded) = await RunAsync(CleanBody, contentEncoding: "gzip");

        forwarded.ShouldBeFalse();
        context.Response.StatusCode.ShouldBe(403);
    }

    [Fact]
    public async Task InvokeAsync_compressed_body_is_forwarded_when_failing_open()
    {
        var (_, forwarded) = await RunAsync(CleanBody, contentEncoding: "gzip", options: new() { FailClosed = false });

        forwarded.ShouldBeTrue();
    }

    [Fact]
    public async Task InvokeAsync_other_paths_are_not_inspected()
    {
        var (_, forwarded) = await RunAsync("not json", path: "/v1/models");

        forwarded.ShouldBeTrue();
    }

    [Fact]
    public async Task InvokeAsync_disabled_policy_forwards_everything()
    {
        var body = JsonSerializer.Serialize(new { messages = new[] { new { role = "user", content = SecretScannerTests.Fake.Aws } } });

        var (_, forwarded) = await RunAsync(body, options: new() { Enabled = false });

        forwarded.ShouldBeTrue();
    }

    private static async Task<(HttpContext Context, bool Forwarded)> RunAsync(
        string body, string path = "/v1/messages", string? contentEncoding = null, TeamSecurityPolicyOptions? options = null)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = HttpMethods.Post;
        context.Request.Path = path;
        context.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(body));
        context.Response.Body = new MemoryStream();
        if (contentEncoding is not null)
        {
            context.Request.Headers.ContentEncoding = contentEncoding;
        }

        var forwarded = false;
        using var services = new ServiceCollection().AddMetrics().BuildServiceProvider();
        var middleware = new TeamSecurityPolicyMiddleware(
            _ => { forwarded = true; return Task.CompletedTask; },
            Options.Create(options ?? new TeamSecurityPolicyOptions()),
            new GatewayMetrics(services.GetRequiredService<IMeterFactory>()),
            NullLogger<TeamSecurityPolicyMiddleware>.Instance);

        await middleware.InvokeAsync(context);

        return (context, forwarded);
    }

    private static string ResponseText(HttpContext context)
    {
        context.Response.Body.Position = 0;
        return new StreamReader(context.Response.Body).ReadToEnd();
    }
}
