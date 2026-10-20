using System.Reflection;

namespace Musicals.ArchitectureTests;

internal static class Layers
{
    public const string Domain = "Musicals.Domain";
    public const string Application = "Musicals.Application";
    public const string Infrastructure = "Musicals.Infrastructure";
    public const string Api = "Musicals.Api";

    public static Assembly DomainAssembly => typeof(Domain.Shows.Show).Assembly;
    public static Assembly ApplicationAssembly => typeof(Application.DependencyInjection).Assembly;
    public static Assembly InfrastructureAssembly => typeof(Infrastructure.DependencyInjection).Assembly;
    public static Assembly ApiAssembly => typeof(Program).Assembly;
}
