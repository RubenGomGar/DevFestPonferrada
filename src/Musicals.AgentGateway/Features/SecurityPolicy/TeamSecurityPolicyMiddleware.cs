using System.Text.Json;
using Microsoft.Extensions.Options;
using Musicals.AgentGateway.Features.Telemetry;

namespace Musicals.AgentGateway.Features.SecurityPolicy;

// Stops a prompt that carries a secret before it leaves the machine. The request never reaches
// upstream: the agent gets a 403 in the Anthropic error format and shows its message.
internal sealed partial class TeamSecurityPolicyMiddleware(
    RequestDelegate next,
    IOptions<TeamSecurityPolicyOptions> options,
    GatewayMetrics metrics,
    ILogger<TeamSecurityPolicyMiddleware> logger)
{
    private const string Uninspectable = "uninspectable-body";

    public async Task InvokeAsync(HttpContext context)
    {
        if (!options.Value.Enabled
            || !HttpMethods.IsPost(context.Request.Method)
            || !context.Request.Path.StartsWithSegments("/v1/messages"))
        {
            await next(context).ConfigureAwait(false);
            return;
        }

        var (finding, inspected) = await ScanAsync(context).ConfigureAwait(false);

        if (finding is not null)
        {
            await BlockAsync(context, finding.Rule,
                $"Blocked by team-security-policy: possible secret ({finding.Rule}) in {finding.Location}. Remove it from the conversation and use /rewind.")
                .ConfigureAwait(false);
            LogBlocked(logger, context.Request.Path.Value ?? "", finding.Rule, finding.Location);
            return;
        }

        if (!inspected && options.Value.FailClosed)
        {
            await BlockAsync(context, Uninspectable,
                "Blocked by team-security-policy: the request body could not be inspected.")
                .ConfigureAwait(false);
            LogBlocked(logger, context.Request.Path.Value ?? "", Uninspectable, "body");
            return;
        }

        await next(context).ConfigureAwait(false);
    }

    private static async Task<(SecretFinding? Finding, bool Inspected)> ScanAsync(HttpContext context)
    {
        if (context.Request.Headers.ContentEncoding.Count > 0)
        {
            return (null, false);
        }

        context.Request.EnableBuffering();
        try
        {
            using var doc = await JsonDocument.ParseAsync(context.Request.Body, cancellationToken: context.RequestAborted).ConfigureAwait(false);
            return (SecretScanner.Scan(doc.RootElement), true);
        }
        catch (JsonException)
        {
            return (null, false);
        }
        finally
        {
            context.Request.Body.Position = 0;
        }
    }

    private async Task BlockAsync(HttpContext context, string rule, string message)
    {
        metrics.SecurityBlocked(rule);
        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync(
            JsonSerializer.Serialize(new { type = "error", error = new { type = "permission_error", message } }),
            context.RequestAborted).ConfigureAwait(false);
    }

    [LoggerMessage(Level = LogLevel.Warning,
        Message = "team-security-policy blocked {Path} · rule {Rule} · at {Location}")]
    private static partial void LogBlocked(ILogger logger, string path, string rule, string location);
}
