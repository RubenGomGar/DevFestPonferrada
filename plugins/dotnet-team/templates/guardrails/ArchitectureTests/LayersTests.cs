using System.Reflection;
using NetArchTest.Rules;
using Shouldly;

namespace PlatformGuardrails.ArchitectureTests;

public class LayersTests
{
    private const string Source = "https://platform.plainconcepts.com/docs/backend";

    private static readonly Assembly[] All = [.. Projects.Names.Select(Assembly.Load)];

    private static Assembly? Layer(string suffix) =>
        All.FirstOrDefault(a => a.GetName().Name!.EndsWith($".{suffix}", StringComparison.Ordinal));

    private static string NameOf(string suffix) => Layer(suffix)?.GetName().Name ?? $"*.{suffix}";

    [Fact]
    public void Solution_has_the_Platform_layers()
    {
        string[] layers = ["Domain", "Application", "Infrastructure", "Api"];

        var missing = layers.Where(l => Layer(l) is null).ToList();

        missing.ShouldBeEmpty($"Clean Architecture projects are missing ({Source}). Current projects: {string.Join(", ", Projects.Names)}");
    }

    [Fact]
    public void Domain_does_not_depend_on_other_layers()
    {
        if (Layer("Domain") is not { } domain)
        {
            return;
        }

        DoesNotReference(domain, NameOf("Application"), NameOf("Infrastructure"), NameOf("Api"), "Microsoft.EntityFrameworkCore");
    }

    [Fact]
    public void Application_does_not_depend_on_Infrastructure_or_Api()
    {
        if (Layer("Application") is not { } application)
        {
            return;
        }

        DoesNotReference(application, NameOf("Infrastructure"), NameOf("Api"), "Microsoft.EntityFrameworkCore");
    }

    [Fact]
    public void Api_does_not_use_EF_Core_directly()
    {
        if (Layer("Api") is not { } api)
        {
            return;
        }

        DoesNotReference(api, "Microsoft.EntityFrameworkCore");
    }

    [Fact]
    public void There_are_no_generic_technical_folders()
    {
        var result = Types.InAssemblies(All)
            .ShouldNot().ResideInNamespaceMatching(@"\.(Services|Repositories|Helpers|Managers)(\.|$)")
            .GetResult();

        result.IsSuccessful.ShouldBeTrue(Offenders(result));
    }

    // The assembly references include what lambdas and async methods use,
    // which NetArchTest does not inspect.
    private static void DoesNotReference(Assembly assembly, params string[] forbidden)
    {
        var offenders = assembly.GetReferencedAssemblies()
            .Select(r => r.Name!)
            .Where(n => forbidden.Any(f => n == f || n.StartsWith($"{f}.", StringComparison.Ordinal)))
            .ToList();

        offenders.ShouldBeEmpty($"{assembly.GetName().Name} must not depend on these assemblies ({Source})");
    }

    private static string Offenders(TestResult result) =>
        $"Offenders ({Source}): " + string.Join(", ", result.FailingTypeNames ?? []);
}
