param(
    [string]$Root = '',
    [string]$ConfigPath = "$env:USERPROFILE\.config\kilo\kilo.jsonc",
    [string[]]$Projects = @('AFA-GHANA', 'patu-research')
)

$ErrorActionPreference = 'Continue'
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = Split-Path -Parent $PSScriptRoot }
$root = (Resolve-Path -LiteralPath $Root).Path
$skillPath = Join-Path $root '.kilo/skills/unslop/SKILL.md'
$compatPath = Join-Path $root '.kilocode/skills/unslop/SKILL.md'
$expectedHash = '313522e7233030030e0c74e2e6ece42df700bbf2c7625b56f876f05bdce013b8'
$script:failures = 0

function Pass([string]$Message) { Write-Host "PASS  $Message" -ForegroundColor Green }
function Fail([string]$Message) { Write-Host "FAIL  $Message" -ForegroundColor Red; $script:failures++ }

if (Test-Path -LiteralPath $skillPath) {
    $hash = (Get-FileHash -LiteralPath $skillPath -Algorithm SHA256).Hash.ToLower()
    if ($hash -eq $expectedHash) { Pass "Canonical Unslop SKILL.md hash matches the installed official copy." }
    else { Fail "Unslop SKILL.md hash differs from the recorded official copy: $hash" }
    $head = (Get-Content -LiteralPath $skillPath -TotalCount 10 | Out-String)
    if ($head -match 'name:\s*unslop' -and $head -match 'license:\s*CC-BY-4.0') { Pass 'Skill frontmatter identifies unslop and CC-BY-4.0.' }
    else { Fail 'Skill frontmatter is missing the unslop name or CC-BY-4.0 license.' }
    if (Test-Path -LiteralPath (Join-Path $root '.kilo/skills/unslop/LICENSE')) { Pass 'Unslop license file is present.' }
    else { Fail 'Unslop license file is missing.' }
} else {
    Fail "Canonical skill is missing: $skillPath"
}

if (Test-Path -LiteralPath $compatPath) { Pass "Compatibility path resolves: $compatPath" }
else { Fail "Compatibility path is missing: $compatPath" }

if (Test-Path -LiteralPath $ConfigPath) {
    try {
        $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        $paths = @($config.skills.paths)
        $normalizedSkillDir = (Join-Path $root '.kilo/skills').Replace('\', '/').TrimEnd('/').ToLowerInvariant()
        $registered = $false
        foreach ($path in $paths) {
            if (([string]$path).Replace('\', '/').TrimEnd('/').ToLowerInvariant() -eq $normalizedSkillDir) { $registered = $true }
        }
        if ($registered) { Pass 'Global Kilo skills.paths registers the parent skills directory.' }
        else { Fail 'Global Kilo skills.paths does not register the parent skills directory.' }
    } catch {
        Fail "Global Kilo config is not valid JSON: $($_.Exception.Message)"
    }
} else {
    Fail "Global Kilo config is missing: $ConfigPath"
}

foreach ($project in $Projects) {
    $projectDir = Join-Path $root $project
    if (-not (Test-Path -LiteralPath $projectDir)) { Fail "Test project is missing: $project"; continue }
    try {
        Push-Location -LiteralPath $projectDir
        $first = (Get-Content -LiteralPath $skillPath -TotalCount 20 | Out-String)
        if ($first -match '# Unslop') { Pass "$project can read the shared Unslop skill." }
        else { Fail "$project could not read the shared Unslop skill." }
        $localCopy = Join-Path $projectDir '.kilo/skills/unslop'
        $legacyCopy = Join-Path $projectDir '.kilocode/skills/unslop'
        if ((Test-Path -LiteralPath $localCopy) -or (Test-Path -LiteralPath $legacyCopy)) { Fail "$project contains a copied Unslop skill." }
        else { Pass "$project has no copied Unslop skill." }
    } finally {
        Pop-Location
    }
}

Write-Host ''
if ($script:failures -gt 0) {
    Write-Host "Unslop verification failed: $($script:failures) issue(s)." -ForegroundColor Red
    exit 1
}
Write-Host 'Unslop verification passed.' -ForegroundColor Green
exit 0
