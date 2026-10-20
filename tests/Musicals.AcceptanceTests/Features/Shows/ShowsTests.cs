using System.Net;
using System.Net.Http.Json;
using Musicals.AcceptanceTests.Infrastructure;
using Musicals.Application.Features.Shows.GetShow;
using Shouldly;

namespace Musicals.AcceptanceTests.Features.Shows;

[Collection(ApiFixture.Name)]
public class ShowsTests(MusicalsApiFactory factory)
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task CreateShow_valid_returns_201_and_can_be_retrieved()
    {
        var response = await _client.PostAsJsonAsync("/api/shows", new { title = "Rasputin", composer = "Boney M." });

        response.StatusCode.ShouldBe(HttpStatusCode.Created);
        var show = await _client.GetFromJsonAsync<ShowDto>(response.Headers.Location);
        show.ShouldNotBeNull();
        show.Title.ShouldBe("Rasputin");
    }

    [Fact]
    public async Task CreateShow_without_composer_returns_400()
    {
        var response = await _client.PostAsJsonAsync("/api/shows", new { title = "Rasputin", composer = "" });

        response.StatusCode.ShouldBe(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task GetShow_nonexistent_returns_404()
    {
        var response = await _client.GetAsync(new Uri($"/api/shows/{Guid.NewGuid()}", UriKind.Relative));

        response.StatusCode.ShouldBe(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task All_responses_carry_noindex()
    {
        var response = await _client.GetAsync(new Uri("/health", UriKind.Relative));

        response.Headers.GetValues("X-Robots-Tag").ShouldContain("noindex, nofollow");
    }
}
