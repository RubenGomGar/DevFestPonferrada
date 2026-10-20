namespace Musicals.Api.Common;

internal static class NoIndexMiddleware
{
    public static IApplicationBuilder UseNoIndex(this IApplicationBuilder app) =>
        app.Use(async (context, next) =>
        {
            context.Response.Headers["X-Robots-Tag"] = "noindex, nofollow";
            await next(context).ConfigureAwait(false);
        });
}
