using System.Diagnostics;
using System.Text.Json;
using Microsoft.AspNetCore.Http.Features;

namespace Musicales.AgentGateway.Features.Telemetria;

internal sealed partial class TrafficCaptureMiddleware(RequestDelegate next, GatewayMetrics metrics, ILogger<TrafficCaptureMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        if (!HttpMethods.IsPost(context.Request.Method) || !context.Request.Path.StartsWithSegments("/v1/messages"))
        {
            await next(context).ConfigureAwait(false);
            return;
        }

        var agent = Header(context, "x-claude-code-agent-id");
        Activity.Current?.SetTag("claude.session.id", Header(context, "x-claude-code-session-id"));
        Activity.Current?.SetTag("claude.agent.id", agent);
        Activity.Current?.SetTag("claude.prompt.id", Header(context, "x-claude-code-prompt-id"));

        var request = await ReadRequestAsync(context).ConfigureAwait(false);

        // Anthropic comprime el SSE con gzip si se le deja. Sin compresión entre gateway y upstream
        // se pueden leer los tokens al vuelo; el contenido y el streaming no cambian.
        context.Request.Headers.AcceptEncoding = "identity";

        var parser = new SseUsageParser();
        var originalBody = context.Features.Get<IHttpResponseBodyFeature>()!;
        var tee = new TeeStream(originalBody.Stream, chunk =>
        {
            if (IsUncompressedSse(context.Response))
            {
                parser.Feed(chunk.Span);
            }
        });
        context.Features.Set<IHttpResponseBodyFeature>(new StreamResponseBodyFeature(tee, originalBody));

        try
        {
            await next(context).ConfigureAwait(false);
        }
        finally
        {
            context.Features.Set(originalBody);
        }

        var model = request?.Model ?? parser.Model;
        metrics.Request(model, context.Response.StatusCode);
        metrics.Tokens(model, parser.Usage);
        foreach (var use in request?.ToolUses ?? [])
        {
            metrics.ToolUse(use, agent);
        }

        if (logger.IsEnabled(LogLevel.Debug))
        {
            var requestEncoding = context.Request.Headers.ContentEncoding.ToString();
            var responseType = context.Response.ContentType ?? "";
            var responseEncoding = context.Response.Headers.ContentEncoding.ToString();
            LogWire(logger, requestEncoding, context.Request.ContentLength ?? -1, responseType, responseEncoding, request is not null);
        }

        if (logger.IsEnabled(LogLevel.Information))
        {
            var path = context.Request.Path.Value ?? "";
            var tools = string.Join(", ", (request?.ToolUses ?? []).Select(u => u.Skill is null ? u.Tool : $"{u.Tool}({u.Skill})"));
            var usage = parser.Usage;
            LogRequest(logger, path, model, context.Response.StatusCode, agent ?? "main", tools, usage.Input, usage.Output, usage.CacheRead);
        }
    }

    private static async Task<RequestSummary?> ReadRequestAsync(HttpContext context)
    {
        if (context.Request.Headers.ContentEncoding.Count > 0)
        {
            return null;
        }

        context.Request.EnableBuffering();
        try
        {
            using var doc = await JsonDocument.ParseAsync(context.Request.Body, cancellationToken: context.RequestAborted).ConfigureAwait(false);
            return AnthropicTraffic.ParseRequest(doc.RootElement);
        }
        catch (JsonException)
        {
            return null;
        }
        finally
        {
            context.Request.Body.Position = 0;
        }
    }

    private static bool IsUncompressedSse(HttpResponse response) =>
        response.ContentType?.StartsWith("text/event-stream", StringComparison.OrdinalIgnoreCase) == true
        && response.Headers.ContentEncoding.Count == 0;

    private static string? Header(HttpContext context, string name) =>
        context.Request.Headers.TryGetValue(name, out var value) ? value.ToString() : null;

    [LoggerMessage(Level = LogLevel.Debug,
        Message = "wire · request encoding '{RequestEncoding}' length {Length} · response '{ResponseType}' encoding '{ResponseEncoding}' · request parsed {Parsed}")]
    private static partial void LogWire(ILogger logger, string requestEncoding, long length, string responseType, string responseEncoding, bool parsed);

    [LoggerMessage(Level = LogLevel.Information,
        Message = "{Path} {Model} → {Status} · agente {Agent} · herramientas [{Tools}] · tokens in {Input} out {Output} cache {CacheRead}")]
    private static partial void LogRequest(ILogger logger, string path, string? model, int status, string agent, string tools, long input, long output, long cacheRead);
}
