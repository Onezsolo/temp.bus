$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
. (Join-Path $PSScriptRoot 'rule-hash.ps1')

$script:failures = 0

function Pass([string]$message) { Write-Host "PASS  $message" -ForegroundColor Green }
function Fail([string]$message) { Write-Host "FAIL  $message" -ForegroundColor Red; $script:failures++ }
function Warn([string]$message) { Write-Host "WARN  $message" -ForegroundColor Yellow }

$registryPath = Join-Path $root 'projects.json'
if (-not (Test-Path -LiteralPath $registryPath)) {
    Fail 'projects.json is missing.'
    exit 1
}

try {
    $registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
} catch {
    Fail "projects.json is not valid JSON: $($_.Exception.Message)"
    exit 1
}

# House repository
if (Test-Path -LiteralPath (Join-Path $root '.git')) {
    Pass 'House .git exists.'
} else {
    Fail 'House .git is missing. Run git init in the house root.'
}

$houseRemote = git -C $root remote get-url origin 2>$null
if ($houseRemote -eq $registry.remote) {
    Pass "House remote is $houseRemote"
} else {
    Fail "House remote is '$houseRemote'; expected '$($registry.remote)'."
}

$houseAgents = Join-Path $root 'AGENTS.md'
if ((Test-Path -LiteralPath $houseAgents) -and ((Get-Content -LiteralPath $houseAgents -Raw) -match 'HOUSE RULE: TEMPLATE BUSINESS')) {
    Pass 'House AGENTS.md contains the house rule marker.'
} else {
    Fail 'House AGENTS.md is missing or does not contain HOUSE RULE: TEMPLATE BUSINESS.'
}

$hooksPath = git -C $root config --get core.hooksPath 2>$null
if ($hooksPath -eq '.githooks' -and (Test-Path -LiteralPath (Join-Path $root '.githooks/pre-commit'))) {
    Pass 'House pre-commit hook is configured.'
} else {
    Fail 'House pre-commit hook is missing or core.hooksPath is not .githooks.'
}

$ignorePath = Join-Path $root '.gitignore'
$ignore = if (Test-Path -LiteralPath $ignorePath) { Get-Content -LiteralPath $ignorePath -Raw } else { '' }

$registeredPaths = @($registry.projects | ForEach-Object { $_.path })
$detectedRepos = @(Get-ChildItem -LiteralPath $root -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') } | Select-Object -ExpandProperty Name)

foreach ($name in $detectedRepos) {
    if ($registeredPaths -notcontains $name) {
        Fail "Unregistered child repository: $name. Add it to projects.json and .gitignore."
    }
}

$lockPath = Join-Path $root 'docs/ai/rules.lock.json'
$lock = $null
if (Test-Path -LiteralPath $lockPath) {
    try {
        $lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
    } catch {
        Fail "Rule lock is not valid JSON: $($_.Exception.Message)"
    }
} else {
    Fail 'Rule lock is missing. Run scripts/sync-rule-hashes.ps1.'
}

$tracked = @(git -C $root ls-files 2>$null)

foreach ($project in $registry.projects) {
    $path = [string]$project.path
    $projectDir = Join-Path $root $path

    if (-not (Test-Path -LiteralPath $projectDir)) {
        Fail "Project folder is missing: $path"
        continue
    }

    if (-not (Test-Path -LiteralPath (Join-Path $projectDir '.git'))) {
        Fail "Project is not a Git repository: $path"
        continue
    }

    $projectRemote = git -C $projectDir remote get-url origin 2>$null
    if ($projectRemote -eq $project.remote) {
        Pass "$path remote is $projectRemote"
    } else {
        Fail "$path remote is '$projectRemote'; expected '$($project.remote)'."
    }

    if ($ignore -match ('(?m)^/' + [regex]::Escape($path) + '/\s*$')) {
        Pass "$path is ignored by the house repository."
    } else {
        Fail "$path is not ignored by the house repository."
    }

    foreach ($file in $tracked) {
        if ($file -like "$path/*") {
            Fail "House repository tracks child file: $file"
        }
    }

    $detectedRules = New-Object System.Collections.Generic.List[string]
    foreach ($fileName in @('AGENTS.md', 'CLAUDE.md', 'CONTEXT.md', '.github/copilot-instructions.md', '.cursorrules', '.windsurfrules', '.clinerules')) {
        if (Test-Path -LiteralPath (Join-Path $projectDir $fileName)) {
            $detectedRules.Add($fileName.Replace('\', '/'))
        }
    }

    foreach ($rulesDir in @('.ai/rules', '.cursor/rules', '.claude/skills', '.claude/agents', '.claude/commands', '.claude/rules', '.kilo/agent', '.kilo/command')) {
        $fullRulesDir = Join-Path $projectDir $rulesDir
        if (Test-Path -LiteralPath $fullRulesDir) {
            if ($rulesDir -eq '.claude/skills') {
                Get-ChildItem -LiteralPath $fullRulesDir -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue | ForEach-Object {
                    $detectedRules.Add($_.FullName.Substring($projectDir.Length + 1).Replace('\', '/'))
                }
            } else {
                Get-ChildItem -LiteralPath $fullRulesDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $detectedRules.Add($_.FullName.Substring($projectDir.Length + 1).Replace('\', '/'))
                }
            }
        }
    }

    $declaredRules = @($project.rules | ForEach-Object { $_.Replace('\', '/') })

    foreach ($ruleFile in $declaredRules) {
        if (-not (Test-Path -LiteralPath (Join-Path $projectDir $ruleFile))) {
            Fail "Declared rule source is missing: $path/$ruleFile"
            continue
        }

        $key = "$path/$ruleFile"
        $hash = Get-HouseRuleHash -Path (Join-Path $projectDir $ruleFile)

        if ($null -ne $lock) {
            $entry = $lock.files.PSObject.Properties[$key]
            if ($null -eq $entry) {
                Fail "Rule lock has no entry for $key. Run scripts/sync-rule-hashes.ps1."
            } elseif ([string]$entry.Value -ne $hash) {
                Fail "Rule changed since the lock: $key. Review it, then run scripts/sync-rule-hashes.ps1."
            }
        }
    }

    foreach ($ruleFile in $detectedRules) {
        if ($declaredRules -notcontains $ruleFile) {
            Fail "Unindexed rule source: $path/$ruleFile. Add it to projects.json and docs/ai/PROJECT_RULES.md."
        }
    }
}

Write-Host ''
if ($script:failures -gt 0) {
    Write-Host "House audit failed with $($script:failures) issue(s)." -ForegroundColor Red
    exit 1
}

Write-Host 'House audit passed.' -ForegroundColor Green
exit 0
