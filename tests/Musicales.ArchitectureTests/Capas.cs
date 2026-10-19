using System.Reflection;

namespace Musicales.ArchitectureTests;

internal static class Capas
{
    public const string Domain = "Musicales.Domain";
    public const string Application = "Musicales.Application";
    public const string Infrastructure = "Musicales.Infrastructure";
    public const string Api = "Musicales.Api";

    public static Assembly DomainAssembly => typeof(Domain.Obras.Obra).Assembly;
    public static Assembly ApplicationAssembly => typeof(Application.DependencyInjection).Assembly;
    public static Assembly InfrastructureAssembly => typeof(Infrastructure.DependencyInjection).Assembly;
    public static Assembly ApiAssembly => typeof(Program).Assembly;
}
