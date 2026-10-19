using ErrorOr;

namespace Musicales.Domain.Obras;

public sealed class Obra
{
    public const int TituloMaxLength = 200;
    public const int CompositorMaxLength = 120;

    private Obra(Guid id, string titulo, string compositor, DateTimeOffset creadaEn)
    {
        Id = id;
        Titulo = titulo;
        Compositor = compositor;
        CreadaEn = creadaEn;
    }

    public Guid Id { get; private set; }

    public string Titulo { get; private set; }

    public string Compositor { get; private set; }

    public DateTimeOffset CreadaEn { get; private set; }

    public static ErrorOr<Obra> Crear(string titulo, string compositor, TimeProvider reloj)
    {
        ArgumentNullException.ThrowIfNull(reloj);

        List<Error> errores = [];

        if (string.IsNullOrEmpty(titulo) || titulo.Length > TituloMaxLength)
        {
            errores.Add(ObraErrors.TituloInvalido);
        }

        if (string.IsNullOrWhiteSpace(compositor) || compositor.Length > CompositorMaxLength)
        {
            errores.Add(ObraErrors.CompositorInvalido);
        }

        if (errores.Count > 0)
        {
            return errores;
        }

        return new Obra(Guid.CreateVersion7(), titulo.Trim(), compositor.Trim(), reloj.GetUtcNow());
    }
}
