using Microsoft.Extensions.DependencyInjection;
using Musicals.Application.Features.Shows.CreateShow;
using Musicals.Application.Features.Shows.GetShow;

namespace Musicals.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddSingleton(TimeProvider.System);
        services.AddScoped<CreateShowHandler>();
        services.AddScoped<GetShowHandler>();
        return services;
    }
}
