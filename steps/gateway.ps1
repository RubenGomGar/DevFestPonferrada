<#
.SYNOPSIS
  Lanza Claude Code a través del gateway local (Musicals.AgentGateway). Deja las variables puestas en la terminal que lo ejecuta.

.DESCRIPTION
  Sirve para que en la demo el tráfico de Claude Code pase por el gateway del AppHost de Aspire y, con -Otel,
  para enviar la telemetría nativa de Claude Code al dashboard de Aspire. Lo lanza a mano el ponente.

.EXAMPLE
  ./steps/gateway.ps1                       # claude interactivo vía gateway
  ./steps/gateway.ps1 -Otel                 # + telemetría nativa de Claude Code al dashboard de Aspire
  ./steps/gateway.ps1 -Otel -p "hola"       # cualquier argumento extra va a claude

  Antes: dotnet run --project src/Musicals.AppHost --launch-profile http
#>
param([switch]$Otel)

$Gateway = 'http://localhost:5180'
$OtlpEndpoint = 'http://localhost:19152'

$ErrorActionPreference = 'Stop'

try { Invoke-RestMethod "$Gateway/health" | Out-Null }
catch { throw "The gateway is not responding at $Gateway. Start the AppHost: dotnet run --project src/Musicals.AppHost --launch-profile http" }

$env:ANTHROPIC_BASE_URL = $Gateway

if ($Otel) {
  $env:CLAUDE_CODE_ENABLE_TELEMETRY = '1'
  $env:OTEL_METRICS_EXPORTER = 'otlp'
  $env:OTEL_LOGS_EXPORTER = 'otlp'
  $env:OTEL_EXPORTER_OTLP_PROTOCOL = 'grpc'
  $env:OTEL_EXPORTER_OTLP_ENDPOINT = $OtlpEndpoint
  $env:OTEL_METRIC_EXPORT_INTERVAL = '5000'
  $env:OTEL_LOG_TOOL_DETAILS = '1'
}

Write-Host "claude → $Gateway$(if ($Otel) { " · OTel → $OtlpEndpoint" })" -ForegroundColor Cyan
claude @args
