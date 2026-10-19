using System.Net;
using System.Net.Http.Json;
using Musicales.AcceptanceTests.Infrastructure;
using Musicales.Application.Features.Obras.ObtenerObra;
using Shouldly;

namespace Musicales.AcceptanceTests.Features.Obras;

[Collection(ApiFixture.Name)]
public class ObrasTests(MusicalesApiFactory factory)
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task CrearObra_valida_devuelve_201_y_se_puede_obtener()
    {
        var response = await _client.PostAsJsonAsync("/api/obras", new { titulo = "Rasputín", compositor = "Boney M." });

        response.StatusCode.ShouldBe(HttpStatusCode.Created);
        var obra = await _client.GetFromJsonAsync<ObraDto>(response.Headers.Location);
        obra.ShouldNotBeNull();
        obra.Titulo.ShouldBe("Rasputín");
    }

    [Fact]
    public async Task CrearObra_sin_compositor_devuelve_400()
    {
        var response = await _client.PostAsJsonAsync("/api/obras", new { titulo = "Rasputín", compositor = "" });

        response.StatusCode.ShouldBe(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task ObtenerObra_inexistente_devuelve_404()
    {
        var response = await _client.GetAsync(new Uri($"/api/obras/{Guid.NewGuid()}", UriKind.Relative));

        response.StatusCode.ShouldBe(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Todas_las_respuestas_llevan_noindex()
    {
        var response = await _client.GetAsync(new Uri("/health", UriKind.Relative));

        response.Headers.GetValues("X-Robots-Tag").ShouldContain("noindex, nofollow");
    }
}
