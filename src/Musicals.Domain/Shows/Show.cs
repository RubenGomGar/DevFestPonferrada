using ErrorOr;

namespace Musicals.Domain.Shows;

public sealed class Show
{
    public const int TitleMaxLength = 200;
    public const int ComposerMaxLength = 120;

    private Show(Guid id, string title, string composer, DateTimeOffset createdAt)
    {
        Id = id;
        Title = title;
        Composer = composer;
        CreatedAt = createdAt;
    }

    public Guid Id { get; private set; }

    public string Title { get; private set; }

    public string Composer { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public static ErrorOr<Show> Create(string title, string composer, TimeProvider clock)
    {
        ArgumentNullException.ThrowIfNull(clock);

        List<Error> errors = [];

        if (string.IsNullOrEmpty(title) || title.Length > TitleMaxLength)
        {
            errors.Add(ShowErrors.InvalidTitle);
        }

        if (string.IsNullOrWhiteSpace(composer) || composer.Length > ComposerMaxLength)
        {
            errors.Add(ShowErrors.InvalidComposer);
        }

        if (errors.Count > 0)
        {
            return errors;
        }

        return new Show(Guid.CreateVersion7(), title.Trim(), composer.Trim(), clock.GetUtcNow());
    }
}
