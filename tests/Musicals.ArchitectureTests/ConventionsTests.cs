using System.Reflection;
using ErrorOr;
using NetArchTest.Rules;
using Shouldly;

namespace Musicals.ArchitectureTests;

public class ConventionsTests
{
    private static readonly Assembly[] All =
        [Layers.DomainAssembly, Layers.ApplicationAssembly, Layers.InfrastructureAssembly, Layers.ApiAssembly];

    [Fact]
    public void There_are_no_generic_technical_folders()
    {
        var result = Types.InAssemblies(All)
            .ShouldNot().ResideInNamespaceMatching(@"\.(Services|Repositories|Helpers|Managers)(\.|$)")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(DependenciesTests.Offenders(result));
    }

    [Fact]
    public void Handlers_are_sealed_and_live_in_Features()
    {
        var result = Types.InAssembly(Layers.ApplicationAssembly)
            .That().HaveNameEndingWith("Handler")
            .Should().BeSealed()
            .And().ResideInNamespaceStartingWith($"{Layers.Application}.Features")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(DependenciesTests.Offenders(result));
    }

    [Fact]
    public void Handlers_return_errors_as_values()
    {
        var offenders = Layers.ApplicationAssembly.GetTypes()
            .Where(t => t.Name.EndsWith("Handler", StringComparison.Ordinal))
            .Where(t => t.GetMethod("Handle") is not { } handle || !ReturnsErrorOr(handle.ReturnType))
            .Select(t => t.FullName)
            .ToList();

        offenders.ShouldBeEmpty("Handle must return Task<ErrorOr<T>> (https://platform.plainconcepts.com/docs/backend)");
    }

    [Fact]
    public void Endpoints_are_grouped_by_feature()
    {
        var result = Types.InAssembly(Layers.ApiAssembly)
            .That().HaveNameEndingWith("Endpoints")
            .Should().ResideInNamespaceStartingWith($"{Layers.Api}.Features")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(DependenciesTests.Offenders(result));
    }

    private static bool ReturnsErrorOr(Type type) =>
        type.IsGenericType
        && type.GetGenericTypeDefinition() == typeof(Task<>)
        && type.GetGenericArguments()[0] is { IsGenericType: true } inner
        && inner.GetGenericTypeDefinition() == typeof(ErrorOr<>);
}
