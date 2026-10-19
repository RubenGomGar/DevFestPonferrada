using ErrorOr;
using Musicales.Domain.Obras;

namespace Musicales.Application.Features.Obras.CrearObra;

public sealed class CrearObraHandler(IObraRepository repository, TimeProvider reloj)
{
    public async Task<ErrorOr<Guid>> Handle(CrearObraCommand command, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        var obra = Obra.Crear(command.Titulo, command.Compositor, reloj);
        if (obra.IsError)
        {
            return obra.Errors;
        }

        await repository.AddAsync(obra.Value, cancellationToken).ConfigureAwait(false);
        return obra.Value.Id;
    }
}
