using System.Reflection;
using NetArchTest.Rules;
using Shouldly;

namespace Musicales.ArchitectureTests;

public class DependenciasTests
{
    private const string EfCore = "Microsoft.EntityFrameworkCore";

    [Fact]
    public void Domain_no_depende_de_ninguna_otra_capa() =>
        NoReferencia(Capas.DomainAssembly, Capas.Application, Capas.Infrastructure, Capas.Api, EfCore);

    [Fact]
    public void Application_no_depende_de_Infrastructure_ni_de_EF_Core() =>
        NoReferencia(Capas.ApplicationAssembly, Capas.Infrastructure, Capas.Api, EfCore, "Microsoft.AspNetCore");

    [Fact]
    public void Infrastructure_no_depende_de_Api() =>
        NoReferencia(Capas.InfrastructureAssembly, Capas.Api);

    [Fact]
    public void Api_no_usa_EF_Core_directamente()
    {
        NoReferencia(Capas.ApiAssembly, EfCore);

        var result = Types.InAssembly(Capas.ApiAssembly)
            .ShouldNot().HaveDependencyOn($"{Capas.Infrastructure}.Persistence")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(Infractores(result));
    }

    // Las referencias del ensamblado incluyen lo que usan lambdas y métodos async,
    // que NetArchTest no inspecciona.
    private static void NoReferencia(Assembly assembly, params string[] prohibidos)
    {
        var infractores = assembly.GetReferencedAssemblies()
            .Select(r => r.Name!)
            .Where(n => prohibidos.Any(p => n == p || n.StartsWith($"{p}.", StringComparison.Ordinal)))
            .ToList();

        infractores.ShouldBeEmpty($"{assembly.GetName().Name} no puede depender de estos ensamblados");
    }

    internal static string Infractores(TestResult result) =>
        "Infractores: " + string.Join(", ", result.FailingTypeNames ?? []);
}
