using Microsoft.Extensions.DependencyInjection;
using Musicales.Application.Features.Obras.CrearObra;
using Musicales.Application.Features.Obras.ObtenerObra;

namespace Musicales.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddSingleton(TimeProvider.System);
        services.AddScoped<CrearObraHandler>();
        services.AddScoped<ObtenerObraHandler>();
        return services;
    }
}
