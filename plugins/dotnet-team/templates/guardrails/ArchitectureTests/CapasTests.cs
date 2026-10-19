using System.Reflection;
using NetArchTest.Rules;
using Shouldly;

namespace PlatformGuardrails.ArchitectureTests;

public class CapasTests
{
    private const string Fuente = "https://platform.plainconcepts.com/docs/backend";

    private static readonly Assembly[] Todas = [.. Proyectos.Nombres.Select(Assembly.Load)];

    private static Assembly? Capa(string sufijo) =>
        Todas.FirstOrDefault(a => a.GetName().Name!.EndsWith($".{sufijo}", StringComparison.Ordinal));

    private static string NombreDe(string sufijo) => Capa(sufijo)?.GetName().Name ?? $"*.{sufijo}";

    [Fact]
    public void La_solucion_tiene_las_capas_de_Platform()
    {
        string[] capas = ["Domain", "Application", "Infrastructure", "Api"];

        var faltan = capas.Where(c => Capa(c) is null).ToList();

        faltan.ShouldBeEmpty($"Faltan proyectos de Clean Architecture ({Fuente}). Proyectos actuales: {string.Join(", ", Proyectos.Nombres)}");
    }

    [Fact]
    public void Domain_no_depende_de_otras_capas()
    {
        if (Capa("Domain") is not { } domain)
        {
            return;
        }

        NoReferencia(domain, NombreDe("Application"), NombreDe("Infrastructure"), NombreDe("Api"), "Microsoft.EntityFrameworkCore");
    }

    [Fact]
    public void Application_no_depende_de_Infrastructure_ni_de_Api()
    {
        if (Capa("Application") is not { } application)
        {
            return;
        }

        NoReferencia(application, NombreDe("Infrastructure"), NombreDe("Api"), "Microsoft.EntityFrameworkCore");
    }

    [Fact]
    public void Api_no_usa_EF_Core_directamente()
    {
        if (Capa("Api") is not { } api)
        {
            return;
        }

        NoReferencia(api, "Microsoft.EntityFrameworkCore");
    }

    [Fact]
    public void No_hay_carpetas_tecnicas_genericas()
    {
        var result = Types.InAssemblies(Todas)
            .ShouldNot().ResideInNamespaceMatching(@"\.(Services|Repositories|Helpers|Managers)(\.|$)")
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

        infractores.ShouldBeEmpty($"{assembly.GetName().Name} no puede depender de estos ensamblados ({Fuente})");
    }

    private static string Infractores(TestResult result) =>
        $"Infractores ({Fuente}): " + string.Join(", ", result.FailingTypeNames ?? []);
}
