using ErrorOr;

namespace Musicals.Domain.Shows;

public static class ShowErrors
{
    public static readonly Error InvalidTitle = Error.Validation(
        "Show.InvalidTitle",
        $"The title is required and cannot exceed {Show.TitleMaxLength} characters.");

    public static readonly Error InvalidComposer = Error.Validation(
        "Show.InvalidComposer",
        $"The composer is required and cannot exceed {Show.ComposerMaxLength} characters.");

    public static readonly Error NotFound = Error.NotFound(
        "Show.NotFound",
        "The show does not exist.");
}
