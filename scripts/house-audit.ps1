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

# Website grouping: one website per repository, multiple working copies allowed.
$websiteGroups = @($registry.websites)
if ($websiteGroups.Count -gt 0) {
    Pass "Website grouping present ($($websiteGroups.Count) websites)."
} else {
    Fail 'projects.json has no websites grouping.'
}

$websiteNames = @()
foreach ($website in $websiteGroups) {
    $websiteName = [string]$website.name
    $websiteNames += $websiteName
    $copies = @($website.workingCopies)

    if ($copies.Count -eq 0) {
        Fail "Website '$websiteName' has no working copies."
        continue
    }

    $primary = [string]$website.primary
    $primaryFound = @($copies | Where-Object { [string]$_.path -eq $primary }).Count -gt 0
    if (-not $primaryFound) { Fail "Website '$websiteName' primary working copy is not listed: $primary" }

    foreach ($copy in $copies) {
        $copyPath = Join-Path $root ([string]$copy.path)
        if (-not (Test-Path -LiteralPath (Join-Path $copyPath '.git'))) {
            Fail "Website '$websiteName' working copy is missing or not a Git repo: $($copy.path)"
            continue
        }

        $copyRemote = git -C $copyPath remote get-url origin 2>$null
        if ($copyRemote -ne $website.repository) {
            Fail "Website '$websiteName' working copy '$($copy.path)' remote is '$copyRemote'; expected '$($website.repository)'."
        }

        $linkedProject = @($registry.projects | Where-Object { [string]$_.path -eq [string]$copy.path })
        if ($linkedProject.Count -gt 0) {
            if ([string]$linkedProject[0].website -ne $websiteName) {
                Fail "Working copy '$($copy.path)' points to website '$($linkedProject[0].website)'; expected '$websiteName'."
            }
            if ([string]$linkedProject[0].role -ne [string]$copy.role) {
                Fail "Working copy '$($copy.path)' role '$($linkedProject[0].role)' does not match website role '$($copy.role)'."
            }
        }
    }

    foreach ($linkedProject in @($registry.projects | Where-Object { [string]$_.website -eq $websiteName })) {
        if (@($copies | Where-Object { [string]$_.path -eq [string]$linkedProject.path }).Count -eq 0) {
            Fail "Project '$($linkedProject.path)' is not listed under website '$websiteName' working copies."
        }
    }

    Pass "Website '$($website.displayName)' groups $($copies.Count) working copy/copies."
}

foreach ($project in $registry.projects) {
    if (-not $project.website) {
        Fail "Project '$($project.path)' has no website group."
        continue
    }
    if ($websiteNames -notcontains [string]$project.website) {
        Fail "Project '$($project.path)' points to unknown website '$($project.website)'."
    }
}

$requiredKnowledgeFiles = @(    'docs/ai/knowledge/INDEX.md',
    'docs/ai/knowledge/projects.json',
    'docs/ai/knowledge/MASTER_RULES.md',
    'docs/ai/knowledge/studio-specialists.json',
    'docs/ai/knowledge/VERIFIED_STATE.json',
    'docs/ai/knowledge/DECISIONS.md',
    'docs/ai/knowledge/KNOWN_ISSUES.md',
    'docs/ai/knowledge/CHANGELOG.md',
    'docs/ai/knowledge/WEBSITES.md',
    'docs/ai/knowledge/studio-skill-map.json',
    'docs/ai/knowledge/UNSLOP.md',
    'docs/ai/tasks',
    'docs/ai/handoffs',
    '.kilo/agent/main-brain.md',
    '.kilo/agent/knowledge-scribe.md',
    '.kilo/command/design-review.md',
    '.kilo/skills/unslop/SKILL.md',
    'scripts/ai-orchestrator.ps1',
    'scripts/ai-knowledge-bootstrap.ps1',
    'scripts/verify-unslop.ps1',
    'kilo.json'
)

$missingKnowledge = @()
foreach ($file in $requiredKnowledgeFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $file))) { $missingKnowledge += $file }
}
if ($missingKnowledge.Count -eq 0) {
    Pass 'Central knowledge and orchestration files exist.'
} else {
    Fail "Central knowledge files missing: $($missingKnowledge -join ', ')"
}

$knowledgeManifestPath = Join-Path $root 'docs/ai/knowledge/projects.json'
if (Test-Path -LiteralPath $knowledgeManifestPath) {
    try {
        $knowledgeManifest = Get-Content -LiteralPath $knowledgeManifestPath -Raw | ConvertFrom-Json
        $knowledgeProjects = @($knowledgeManifest.projects)
        if ($knowledgeProjects.Count -eq @($registry.projects).Count) {
            Pass 'Knowledge manifest matches the project registry count.'
        } else {
            Fail "Knowledge manifest has $($knowledgeProjects.Count) projects; registry has $(@($registry.projects).Count). Run scripts/ai-knowledge-bootstrap.ps1."
        }
        foreach ($knowledgeProject in $knowledgeProjects) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $knowledgeProject.knowledgeFile))) {
                Fail "Missing knowledge file: $($knowledgeProject.knowledgeFile)"
            }
        }
    } catch {
        Fail "Knowledge manifest is not valid JSON: $($_.Exception.Message)"
    }
}

$taskRoot = Join-Path $root 'docs/ai/tasks'
if (Test-Path -LiteralPath $taskRoot) {
    $taskFiles = @(Get-ChildItem -LiteralPath $taskRoot -Directory | ForEach-Object {
        $candidate = Join-Path $_.FullName 'task.json'
        if (Test-Path -LiteralPath $candidate) { $candidate }
    })
    $taskProblems = @()
    foreach ($taskFile in $taskFiles) {
        try {
            $taskRecord = Get-Content -LiteralPath $taskFile -Raw | ConvertFrom-Json
            if (-not $taskRecord.id -or -not $taskRecord.project -or -not $taskRecord.status) {
                $taskProblems += $taskFile
            }
        } catch { $taskProblems += $taskFile }
    }
    if ($taskProblems.Count -eq 0) {
        Pass "Task records parse and contain required fields ($($taskFiles.Count) records)."
    } else {
        Fail "Invalid task record(s): $($taskProblems -join ', ')"
    }
}

$specialistFiles = @(Get-ChildItem -LiteralPath (Join-Path $root '.kilo/agent/specialists') -File -Filter '*.md' -ErrorAction SilentlyContinue)
if ($specialistFiles.Count -ge 19) {
    Pass "Adopted Studio specialist agents present ($($specialistFiles.Count))."
} else {
    Fail "Studio specialist agents are missing; run scripts/import-studio-specialists.py."
}

$kiloConfigPath = Join-Path $root 'kilo.json'
if (Test-Path -LiteralPath $kiloConfigPath) {
    try {
        $kiloConfig = Get-Content -LiteralPath $kiloConfigPath -Raw | ConvertFrom-Json
        if ($kiloConfig.default_agent -eq 'main-brain') {
            Pass 'House Kilo config defaults to the main-brain agent.'
        } else {
            Fail 'kilo.json does not default to the main-brain agent.'
        }
    } catch {
        Fail "kilo.json is not valid JSON: $($_.Exception.Message)"
    }
}

Write-Host ''
if ($script:failures -gt 0) {
    Write-Host "House audit failed with $($script:failures) issue(s)." -ForegroundColor Red
    exit 1
}

Write-Host 'House audit passed.' -ForegroundColor Green
exit 0
