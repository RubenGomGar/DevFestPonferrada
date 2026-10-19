using ErrorOr;

namespace Musicales.Domain.Obras;

public static class ObraErrors
{
    public static readonly Error TituloInvalido = Error.Validation(
        "Obra.TituloInvalido",
        $"El título es obligatorio y no puede superar {Obra.TituloMaxLength} caracteres.");

    public static readonly Error CompositorInvalido = Error.Validation(
        "Obra.CompositorInvalido",
        $"El compositor es obligatorio y no puede superar {Obra.CompositorMaxLength} caracteres.");

    public static readonly Error NoEncontrada = Error.NotFound(
        "Obra.NoEncontrada",
        "La obra no existe.");
}
