using System.Reflection;
using ErrorOr;
using NetArchTest.Rules;
using Shouldly;

namespace Musicales.ArchitectureTests;

public class ConvencionesTests
{
    private static readonly Assembly[] Todas =
        [Capas.DomainAssembly, Capas.ApplicationAssembly, Capas.InfrastructureAssembly, Capas.ApiAssembly];

    [Fact]
    public void No_hay_carpetas_tecnicas_genericas()
    {
        var result = Types.InAssemblies(Todas)
            .ShouldNot().ResideInNamespaceMatching(@"\.(Services|Repositories|Helpers|Managers)(\.|$)")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(DependenciasTests.Infractores(result));
    }

    [Fact]
    public void Los_handlers_son_sealed_y_viven_en_Features()
    {
        var result = Types.InAssembly(Capas.ApplicationAssembly)
            .That().HaveNameEndingWith("Handler")
            .Should().BeSealed()
            .And().ResideInNamespaceStartingWith($"{Capas.Application}.Features")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(DependenciasTests.Infractores(result));
    }

    [Fact]
    public void Los_handlers_devuelven_errores_como_valores()
    {
        var infractores = Capas.ApplicationAssembly.GetTypes()
            .Where(t => t.Name.EndsWith("Handler", StringComparison.Ordinal))
            .Where(t => t.GetMethod("Handle") is not { } handle || !DevuelveErrorOr(handle.ReturnType))
            .Select(t => t.FullName)
            .ToList();

        infractores.ShouldBeEmpty("Handle debe devolver Task<ErrorOr<T>> (https://platform.plainconcepts.com/docs/backend)");
    }

    [Fact]
    public void Los_endpoints_se_agrupan_por_feature()
    {
        var result = Types.InAssembly(Capas.ApiAssembly)
            .That().HaveNameEndingWith("Endpoints")
            .Should().ResideInNamespaceStartingWith($"{Capas.Api}.Features")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(DependenciasTests.Infractores(result));
    }

    private static bool DevuelveErrorOr(Type tipo) =>
        tipo.IsGenericType
        && tipo.GetGenericTypeDefinition() == typeof(Task<>)
        && tipo.GetGenericArguments()[0] is { IsGenericType: true } inner
        && inner.GetGenericTypeDefinition() == typeof(ErrorOr<>);
}
