$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
. (Join-Path $PSScriptRoot 'rule-hash.ps1')

$registryPath = Join-Path $root 'projects.json'
if (-not (Test-Path -LiteralPath $registryPath)) {
    throw 'projects.json is missing.'
}

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$files = [ordered]@{}

foreach ($project in $registry.projects) {
    $projectDir = Join-Path $root ([string]$project.path)

    foreach ($ruleFile in @($project.rules)) {
        $rulePath = Join-Path $projectDir $ruleFile
        $key = "$($project.path)/$($ruleFile.Replace('\', '/'))"

        if (-not (Test-Path -LiteralPath $rulePath)) {
            Write-Host "WARN  Missing rule source: $key" -ForegroundColor Yellow
            continue
        }

        $hash = Get-HouseRuleHash -Path $rulePath
        $files[$key] = $hash
        Write-Host "HASH  $key"
    }
}

$lock = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    files = $files
}

$lockPath = Join-Path $root 'docs/ai/rules.lock.json'
$json = $lock | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($lockPath, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "Rule lock written: $lockPath" -ForegroundColor Green
