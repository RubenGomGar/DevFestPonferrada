using System.Reflection;
using NetArchTest.Rules;
using Shouldly;

namespace Musicals.ArchitectureTests;

public class DependenciesTests
{
    private const string EfCore = "Microsoft.EntityFrameworkCore";

    [Fact]
    public void Domain_does_not_depend_on_any_other_layer() =>
        DoesNotReference(Layers.DomainAssembly, Layers.Application, Layers.Infrastructure, Layers.Api, EfCore);

    [Fact]
    public void Application_does_not_depend_on_Infrastructure_or_EF_Core() =>
        DoesNotReference(Layers.ApplicationAssembly, Layers.Infrastructure, Layers.Api, EfCore, "Microsoft.AspNetCore");

    [Fact]
    public void Infrastructure_does_not_depend_on_Api() =>
        DoesNotReference(Layers.InfrastructureAssembly, Layers.Api);

    [Fact]
    public void Api_does_not_use_EF_Core_directly()
    {
        DoesNotReference(Layers.ApiAssembly, EfCore);

        var result = Types.InAssembly(Layers.ApiAssembly)
            .ShouldNot().HaveDependencyOn($"{Layers.Infrastructure}.Persistence")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(Offenders(result));
    }

    // The assembly references include what lambdas and async methods use,
    // which NetArchTest does not inspect.
    private static void DoesNotReference(Assembly assembly, params string[] forbidden)
    {
        var offenders = assembly.GetReferencedAssemblies()
            .Select(r => r.Name!)
            .Where(n => forbidden.Any(p => n == p || n.StartsWith($"{p}.", StringComparison.Ordinal)))
            .ToList();

        offenders.ShouldBeEmpty($"{assembly.GetName().Name} must not depend on these assemblies");
    }

    internal static string Offenders(TestResult result) =>
        "Offenders: " + string.Join(", ", result.FailingTypeNames ?? []);
}
