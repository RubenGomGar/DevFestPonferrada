namespace Musicals.AgentGateway.Features.SecurityPolicy;

internal sealed class TeamSecurityPolicyOptions
{
    public const string SectionName = "TeamSecurityPolicy";

    public bool Enabled { get; set; } = true;

    // A body the gateway cannot read (compressed, not JSON) is blocked rather than trusted.
    public bool FailClosed { get; set; } = true;
}
