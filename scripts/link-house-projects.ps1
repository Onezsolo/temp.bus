param(
    [Parameter(Mandatory = $true)]
    [string]$WorktreePath
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

$worktree = (Resolve-Path -LiteralPath $WorktreePath).Path
if (-not (Test-Path -LiteralPath (Join-Path $worktree '.git'))) {
    throw "Not a Git worktree: $worktree"
}

$worktreeList = @(git worktree list --porcelain)
$mainRoot = (($worktreeList | Select-Object -First 1) -replace '^worktree\s+', '')
$registryPath = Join-Path $mainRoot 'projects.json'

if (-not (Test-Path -LiteralPath $registryPath)) {
    throw "projects.json is missing in $mainRoot"
}

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$names = @($registry.projects | ForEach-Object { $_.path }) + @('_archive', 'patutrade.worktrees')

foreach ($name in $names) {
    $source = Join-Path $mainRoot $name
    $target = Join-Path $worktree $name

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Host "SKIP  Missing project folder: $source" -ForegroundColor Yellow
        continue
    }

    if (Test-Path -LiteralPath $target) {
        Write-Host "SKIP  Already present: $target"
        continue
    }

    New-Item -ItemType Junction -Path $target -Target $source | Out-Null
    Write-Host "LINK  $target -> $source"
}

Write-Host ''
Write-Host "Projects linked into $worktree" -ForegroundColor Green
