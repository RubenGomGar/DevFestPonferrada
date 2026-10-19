<#
.SYNOPSIS
  Avanza la demo del acto 2 un paso: trae de main los ficheros de ese paso, hace commit y deja un tag.

.EXAMPLE
  ./steps/step.ps1 n0     # rama demo-live sin plugin (punto de partida)
  ./steps/step.ps1 n3     # añade el comando /plan
  ./steps/step.ps1 list   # qué trae cada paso
#>
param([Parameter(Mandatory)][string]$Step)

$ErrorActionPreference = 'Stop'
$root = git rev-parse --show-toplevel
Set-Location $root

$plugin = 'plugins/dotnet-team'
$steps = [ordered]@{
  n1 = @{ Title = 'Skill de guardarraíles'; Paths = @("$plugin/.claude-plugin/plugin.json", "$plugin/skills/dotnet-guardrails") }
  n2 = @{ Title = 'GitHub MCP en el plugin'; Paths = @("$plugin/.mcp.json") }
  n3 = @{ Title = 'Comando /plan'; Paths = @("$plugin/templates/plan.md", "$plugin/scripts/lib.sh", "$plugin/scripts/ctx/plan.sh"); Override = @("$plugin/commands/plan.md") }
  n4 = @{ Title = 'Orquestador: segunda skill'; Paths = @("$plugin/skills/dotnet-testing", "$plugin/commands/plan.md") }
  n5 = @{ Title = 'Hooks: trazas, guardia y puerta TDD'; Paths = @("$plugin/hooks", "$plugin/scripts/hooks", "$plugin/scripts/gates/plan.sh", "$plugin/tests") }
  n6 = @{ Title = 'Marketplace'; Paths = @('.claude-plugin/marketplace.json', "$plugin/README.md") }
  n7 = @{ Title = 'Bonus: /validate y /guardrails'; Paths = @("$plugin/commands/validate.md", "$plugin/commands/guardrails.md", "$plugin/agents", "$plugin/references", "$plugin/scripts/validate", "$plugin/scripts/gates/validate.sh", "$plugin/scripts/guardrails", "$plugin/templates/guardrails") }
}

function Commit-Step([string]$tag, [string]$message) {
  git add -A
  git commit -q -m "$tag · $message"
  git tag -f $tag | Out-Null
  Write-Host "✔ $tag · $message" -ForegroundColor Green
}

switch ($Step.ToLower()) {
  'list' {
    $steps.GetEnumerator() | ForEach-Object { "{0}  {1}`n      {2}" -f $_.Key, $_.Value.Title, (($_.Value.Paths + $_.Value.Override) -join "`n      ") }
    return
  }
  'n0' {
    if (git status --porcelain) { throw 'Hay cambios sin commitear en la rama actual.' }
    git switch -q -C demo-live main
    git rm -r -q --ignore-unmatch $plugin '.claude-plugin'
    Remove-Item -Recurse -Force $plugin, '.claude-plugin', '.work' -ErrorAction SilentlyContinue
    Commit-Step 'n0' 'App con guardarraíles de build y arquitectura, sin harness'
    return
  }
}

$def = $steps[$Step.ToLower()]
if (-not $def) { throw "Paso desconocido '$Step'. Usa: list, n0, $($steps.Keys -join ', ')" }
if ((git branch --show-current) -ne 'demo-live') { throw 'Ejecuta primero ./steps/step.ps1 n0' }

foreach ($path in $def.Paths) { git checkout main -- $path }
foreach ($path in $def.Override) {
  $source = Join-Path "steps/act2/$($Step.ToUpper())/files" $path
  New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
  Copy-Item -Force $source $path
}
Commit-Step $Step.ToLower() $def.Title
