using System.Text.RegularExpressions;

namespace Musicals.AgentGateway.Features.SecurityPolicy;

internal sealed record SecretRule(string Name, Regex Pattern);

// The patterns live in code, not in appsettings: the plugin's guard hook denies writing
// connection-string fragments into appsettings*.json, and a rule is a decision, not a setting.
internal static partial class SecretRules
{
    public static IReadOnlyList<SecretRule> All { get; } =
    [
        new("anthropic-api-key", AnthropicApiKey()),
        new("github-token", GitHubToken()),
        new("github-token", GitHubFineGrainedToken()),
        new("aws-access-key", AwsAccessKey()),
        new("private-key", PrivateKey()),
        new("azure-storage-key", AzureStorageKey()),
        new("connection-string-password", ConnectionStringPassword()),
        new("jwt", Jwt()),
    ];

    [GeneratedRegex(@"sk-ant-[A-Za-z0-9_\-]{20,}")]
    private static partial Regex AnthropicApiKey();

    [GeneratedRegex(@"\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}\b")]
    private static partial Regex GitHubToken();

    [GeneratedRegex(@"\bgithub_pat_[A-Za-z0-9_]{50,}")]
    private static partial Regex GitHubFineGrainedToken();

    [GeneratedRegex(@"\b(AKIA|ASIA)[A-Z0-9]{16}\b")]
    private static partial Regex AwsAccessKey();

    [GeneratedRegex(@"-----BEGIN [A-Z ]*PRIVATE KEY-----")]
    private static partial Regex PrivateKey();

    [GeneratedRegex(@"AccountKey=[A-Za-z0-9+/=]{40,}")]
    private static partial Regex AzureStorageKey();

    [GeneratedRegex(@"\b(Password|Pwd)\s*=\s*[^;\s""'{}]{4,}", RegexOptions.IgnoreCase)]
    private static partial Regex ConnectionStringPassword();

    [GeneratedRegex(@"\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}")]
    private static partial Regex Jwt();
}
