param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('intake', 'context', 'claim', 'release', 'assign', 'checkpoint', 'handover', 'failover', 'resume', 'sync', 'status', 'list')]
    [string]$Action,
    [string]$Root = '',
    [string]$TaskId,
    [Alias('Project')]
    [string]$ProjectName,
    [string]$Title,
    [string]$Objective,
    [string[]]$Files = @(),
    [string[]]$Dependencies = @(),
    [string]$Priority = 'medium',
    [string]$Specialist = '',
    [string]$Agent = '',
    [string]$SessionId = '',
    [string]$Worktree = '',
    [string]$Branch = '',
    [string]$TestCommand = '',
    [int]$TimeoutSeconds = 600,
    [int]$Minutes = 120,
    [string]$NextStep = '',
    [string[]]$Blockers = @(),
    [string[]]$Risks = @(),
    [string[]]$Decisions = @(),
    [string]$Reason = '',
    [string]$Notes = '',
    [switch]$Force,
    [switch]$Complete
)

$ErrorActionPreference = 'Continue'
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = Split-Path -Parent $PSScriptRoot }
$root = (Resolve-Path -LiteralPath $Root).Path
$knowledgeDir = Join-Path $root 'docs/ai/knowledge'
$tasksDir = Join-Path $root 'docs/ai/tasks'
$handoffsDir = Join-Path $root 'docs/ai/handoffs'

function Get-MainRoot {
    if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { return $root }
    try {
        $list = @(git -C $root worktree list --porcelain 2>$null)
        if ($list.Count -gt 0 -and $list[0] -match '^worktree\s+(.+)$') { return $Matches[1] }
    } catch { }
    return $root
}

$mainRoot = Get-MainRoot
$claimsDir = Join-Path $mainRoot '.kilo/ai'
New-Item -ItemType Directory -Force -Path $tasksDir, $handoffsDir, $knowledgeDir, $claimsDir | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Text([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Read-Json([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}

function Write-Json([string]$Path, $Object) {
    Write-Text $Path ($Object | ConvertTo-Json -Depth 30)
}

function NowIso { return (Get-Date).ToUniversalTime().ToString('o') }

function Get-ProjectRegistry {
    $path = Join-Path $root 'projects.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "projects.json is missing in $root" }
    return Read-Json $path
}

function Get-ProjectEntry([string]$Name) {
    $registry = Get-ProjectRegistry
    $entry = @($registry.projects | Where-Object { $_.name -eq $Name -or $_.path -eq $Name })
    if ($entry.Count -eq 0) { throw "Unknown project: $Name" }
    return $entry[0]
}

function Get-KnowledgeManifest {
    $path = Join-Path $knowledgeDir 'projects.json'
    if (Test-Path -LiteralPath $path) { return Read-Json $path }
    return $null
}

function Get-ProjectKnowledge([string]$Name) {
    $manifest = Get-KnowledgeManifest
    if ($null -ne $manifest) {
        $entry = @($manifest.projects | Where-Object { $_.name -eq $Name })
        if ($entry.Count -gt 0) {
            $file = Join-Path $root $entry[0].knowledgeFile
            if (Test-Path -LiteralPath $file) { return (Get-Content -LiteralPath $file -Raw) }
        }
    }
    return ''
}

function Get-TaskDir([string]$Id) {
    if ([string]::IsNullOrWhiteSpace($Id)) { throw 'TaskId is required.' }
    $direct = Join-Path $tasksDir $Id
    if (Test-Path -LiteralPath (Join-Path $direct 'task.json')) { return $direct }
    foreach ($dir in Get-ChildItem -LiteralPath $tasksDir -Directory -ErrorAction SilentlyContinue) {
        $taskFile = Join-Path $dir.FullName 'task.json'
        if (Test-Path -LiteralPath $taskFile) {
            $task = Read-Json $taskFile
            if ($task.id -eq $Id -or $dir.Name -eq $Id) { return $dir.FullName }
        }
    }
    throw "Task not found: $Id"
}

function Read-Task([string]$Dir) { return Read-Json (Join-Path $Dir 'task.json') }

function Set-Field($Object, [string]$Name, $Value) {
    if ($null -eq $Object) { return }
    $parts = $Name -split '\.'
    $target = $Object
    for ($i = 0; $i -lt ($parts.Count - 1); $i++) {
        $part = $parts[$i]
        $property = $target.PSObject.Properties[$part]
        if ($null -eq $property -or $null -eq $property.Value) {
            $child = [pscustomobject]@{}
            if ($null -eq $property) {
                $target | Add-Member -NotePropertyName $part -NotePropertyValue $child -Force
            } else {
                $target.$part = $child
            }
            $target = $child
        } else {
            $target = $property.Value
        }
    }
    $leaf = $parts[-1]
    if ($target.PSObject.Properties.Name -contains $leaf) { $target.$leaf = $Value }
    else { $target | Add-Member -NotePropertyName $leaf -NotePropertyValue $Value -Force }
}

function Save-Task([string]$Dir, $Task) {
    Set-Field $Task 'updatedAt' (NowIso)
    Write-Json (Join-Path $Dir 'task.json') $Task
}

function Get-AllTasks {
    $items = @()
    foreach ($dir in Get-ChildItem -LiteralPath $tasksDir -Directory -ErrorAction SilentlyContinue) {
        $file = Join-Path $dir.FullName 'task.json'
        if (Test-Path -LiteralPath $file) {
            try { $items += (Read-Json $file) } catch { }
        }
    }
    return $items
}

function Get-LatestCheckpoint([string]$Dir) {
    $checkpointDir = Join-Path $Dir 'checkpoints'
    if (-not (Test-Path -LiteralPath $checkpointDir)) { return $null }
    $files = @(Get-ChildItem -LiteralPath $checkpointDir -File -Filter '*.json' | Sort-Object Name)
    if ($files.Count -eq 0) { return $null }
    return Read-Json $files[-1].FullName
}

function Get-LatestHandover([string]$ProjectName) {
    $found = @()
    foreach ($task in Get-AllTasks) {
        if ($task.project -eq $ProjectName -and $task.PSObject.Properties.Name -contains 'handoverPath' -and $task.handoverPath) {
            $path = Join-Path $root $task.handoverPath
            if (Test-Path -LiteralPath $path) {
                $found += [pscustomobject]@{ Path = $path; Updated = (Get-Item $path).LastWriteTime }
            }
        }
    }
    if ($found.Count -eq 0) { return $null }
    $latest = $found | Sort-Object Updated -Descending | Select-Object -First 1
    return (Get-Content -LiteralPath $latest.Path -Raw)
}

function Get-Claims {
    $path = Join-Path $claimsDir 'claims.json'
    $data = Read-Json $path
    if ($null -eq $data) { return [pscustomobject]@{ claims = @() } }
    return $data
}

function Save-Claims($Claims) {
    Write-Json (Join-Path $claimsDir 'claims.json') $Claims
}

function Invoke-WithClaimsLock([scriptblock]$ActionBlock) {
    $lockPath = Join-Path $claimsDir 'claims.lock'
    $stream = $null
    for ($i = 0; $i -lt 50; $i++) {
        try {
            $stream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            break
        } catch { Start-Sleep -Milliseconds 100 }
    }
    if ($null -eq $stream) { throw 'Could not acquire the central claims lock.' }
    try { & $ActionBlock } finally { $stream.Dispose(); Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
}

function Normalize-ProjectPath([string]$Path) {
    return ($Path.Trim().Replace('\', '/').TrimStart('/')).ToLowerInvariant()
}

function Test-PathOverlap([string]$A, [string]$B) {
    $a = Normalize-ProjectPath $A
    $b = Normalize-ProjectPath $B
    return ($a -eq $b -or $a.StartsWith($b + '/') -or $b.StartsWith($a + '/'))
}

function Get-RecommendedSpecialists($Task) {
    $path = Join-Path $knowledgeDir 'studio-specialists.json'
    if (-not (Test-Path -LiteralPath $path)) { return @('architect', 'verify') }
    $catalog = Read-Json $path
    $haystack = (([string]$Task.title) + ' ' + ([string]$Task.objective)).ToLowerInvariant()
    $recommended = @()
    foreach ($specialist in @($catalog.specialists)) {
        foreach ($trigger in @($specialist.triggers)) {
            if ($trigger -eq 'always' -or $haystack.Contains(([string]$trigger).ToLowerInvariant())) {
                $recommended += [string]$specialist.key
                break
            }
        }
    }
    if ($recommended.Count -eq 0) { $recommended = @('architect', 'verify') }
    if ($recommended -notcontains 'verify') { $recommended += 'verify' }
    return ($recommended | Select-Object -Unique | Select-Object -First 5)
}

function New-Context([string]$Dir, $Task) {
    $project = Get-ProjectEntry ([string]$Task.project)
    $projectDir = Join-Path $root ([string]$project.path)
    $knowledge = Get-ProjectKnowledge ([string]$Task.project)
    if ($knowledge.Length -gt 6000) { $knowledge = $knowledge.Substring(0, 6000) + "`n...[truncated for context budget]" }

    $branch = (git -C $projectDir branch --show-current 2>$null | Out-String).Trim()
    $head = (git -C $projectDir rev-parse --short HEAD 2>$null | Out-String).Trim()
    $status = @(git -C $projectDir status --porcelain 2>$null)
    $recent = @(git -C $projectDir log -5 --oneline 2>$null)
    $diff = @(git -C $projectDir diff --stat 2>$null)
    $cached = @(git -C $projectDir diff --cached --stat 2>$null)

    $fileLines = @()
    foreach ($file in @($Task.files.expected)) {
        $full = Join-Path $projectDir $file
        if (Test-Path -LiteralPath $full) {
            $item = Get-Item -LiteralPath $full
            if ($item.PSIsContainer) {
                $children = @(Get-ChildItem -LiteralPath $full -Force -ErrorAction SilentlyContinue | Select-Object -First 30 | ForEach-Object { $_.Name })
                $fileLines += "- $file (directory; immediate entries: $($children -join ', '))"
            } else {
                $fileLines += "- $file ($($item.Length) bytes, modified $($item.LastWriteTime.ToString('s')))"
            }
        } else {
            $fileLines += "- $file (does not exist yet)"
        }
    }
    if ($fileLines.Count -eq 0) { $fileLines = @('- No specific files declared. Identify the smallest relevant file set before editing.') }

    $rules = @($project.rules | ForEach-Object { "- $($project.path)/$_" })
    if ($rules.Count -eq 0) { $rules = @('- No project rule file declared; house rules apply.') }
    $verify = @($project.verify | ForEach-Object { "- $_" })
    if ($verify.Count -eq 0) { $verify = @('- No verify command recorded.') }

    $claims = Get-Claims
    $otherClaims = @()
    foreach ($claim in @($claims.claims)) {
        if ($claim.taskId -ne $Task.id) {
            foreach ($path in @($claim.paths)) {
                $otherClaims += "- $($claim.project):$path claimed by $($claim.taskId) until $($claim.leaseUntil)"
            }
        }
    }
    if ($otherClaims.Count -eq 0) { $otherClaims = @('- No active claims by other tasks.') }

    $handover = ''
    if ($Task.PSObject.Properties.Name -contains 'handoverPath' -and $Task.handoverPath) {
        $hp = Join-Path $root $Task.handoverPath
        if (Test-Path -LiteralPath $hp) { $handover = Get-Content -LiteralPath $hp -Raw }
    }
    if (-not $handover) { $handover = Get-LatestHandover ([string]$Task.project) }
    if ($handover.Length -gt 5000) { $handover = $handover.Substring(0, 5000) + "`n...[truncated for context budget]" }

    $recommended = Get-RecommendedSpecialists $Task
    $uiPattern = '(?i)\b(ui|ux|design|frontend|layout|visual|copy|typography|motion|responsive|figma|screenshot|interface|component|tailwind|css|theme|mobile|accessibility|landing|dashboard)\b'
    $isUiTask = (([string]$Task.title + ' ' + [string]$Task.objective) -match $uiPattern)
    $taskDependencies = @()
    foreach ($dependency in @($Task.dependencies)) {
        $taskDependencies += "- $dependency"
    }
    if ($taskDependencies.Count -eq 0) { $taskDependencies = @('- None recorded.') }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Task context package")
    $lines.Add('')
    $lines.Add("Task: $($Task.id)")
    $lines.Add("Project: $($Task.project)")
    $lines.Add("Title: $($Task.title)")
    $lines.Add("Status: $($Task.status)")
    $lines.Add("Objective: $($Task.objective)")
    $lines.Add('')
    $lines.Add('## Mandatory operating rules')
    $lines.Add('- This package is task-specific. Do not perform a full worktree discovery or repeat onboarding.')
    $lines.Add('- Read AGENTS.md, docs/ai/knowledge/INDEX.md, MASTER_RULES.md and the project summary.')
    $lines.Add('- Read the actual expected files before changing them. Code and tests are the source of truth.')
    $lines.Add('- Claim every file before editing with scripts/ai-orchestrator.ps1 -Action claim -TaskId ' + $Task.id)
    $lines.Add('- Record a checkpoint after each verified step and hand over before switching agents or sessions.')
    $lines.Add('- Never overwrite another task claim. If a claim conflicts, stop and report.')
    $lines.Add('')
    $lines.Add('## Repository state')
    $lines.Add("- Branch: $branch")
    $lines.Add("- HEAD: $head")
    $lines.Add("- Working tree changes: $($status.Count)")
    $lines.Add('- Recent commits:')
    foreach ($line in $recent) { $lines.Add("  $line") }
    $lines.Add('- Unstaged diff stat:')
    foreach ($line in $diff) { $lines.Add("  $line") }
    $lines.Add('- Staged diff stat:')
    foreach ($line in $cached) { $lines.Add("  $line") }
    $lines.Add('')
    $lines.Add('## Expected files')
    foreach ($line in $fileLines) { $lines.Add($line) }
    $lines.Add('')
    $lines.Add('## Project rules and commands')
    if ($project.PSObject.Properties.Name -contains 'website' -and $project.website) {
        $lines.Add("- Website group: $($project.website) ($($project.role))")
    }
    foreach ($line in $rules) { $lines.Add($line) }
    $lines.Add('- Verify commands:')
    foreach ($line in $verify) { $lines.Add("  $line") }
    $lines.Add('')
    $lines.Add('## Project knowledge')
    $lines.Add($knowledge)
    $lines.Add('')
    $lines.Add('## Relevant prior handover')
    if ($handover) { $lines.Add($handover) } else { $lines.Add('- None recorded.') }
    $lines.Add('')
    $lines.Add('## Active claims by other tasks')
    foreach ($line in $otherClaims) { $lines.Add($line) }
    $lines.Add('')
    $lines.Add('## Dependencies')
    foreach ($line in $taskDependencies) { $lines.Add($line) }
    $lines.Add('')
    $lines.Add('## Recommended specialists')
    foreach ($specialist in $recommended) { $lines.Add("- $specialist") }
    $lines.Add('')
    $lines.Add('## Design skill')
    if ($isUiTask) {
        $lines.Add('- This is a UI/UX task. Read and apply the shared Unslop skill at C:/laragon/www/template-business/.kilo/skills/unslop/SKILL.md before implementation or review.')
        $lines.Add('- Preserve the project design system, tokens, brand and components; Unslop improves craft and direction, it does not replace product identity.')
    } else {
        $lines.Add('- Not a UI/UX task. Do not load Unslop; it is irrelevant to backend, data, infrastructure, API or payment-only work.')
    }
    $lines.Add('')
    $lines.Add('## Required completion evidence')
    $lines.Add('- Terminal output for the project verify command(s), with exit status.')
    $lines.Add('- A checkpoint JSON for the changed files and git state.')
    $lines.Add('- A handover record with remaining steps if the task is not complete.')
    $lines.Add('- Knowledge sync after the verified change.')

    $context = $lines -join "`n"
    if ($context.Length -gt 18000) { $context = $context.Substring(0, 18000) + "`n...[context truncated]" }
    $contextPath = Join-Path $Dir 'context.md'
    Write-Text $contextPath $context
    Set-Field $Task 'contextPath' ("docs/ai/tasks/" + (Split-Path -Leaf $Dir) + '/context.md')
    Set-Field $Task 'contextGeneratedAt' (NowIso)
    if ($Task.status -in @('queued', 'context_ready', 'failover_ready')) { Set-Field $Task 'status' 'context_ready' }
    Save-Task $Dir $Task
    return $contextPath
}

function Invoke-TestCommand([string]$WorkingDirectory, [string]$Command, [int]$Timeout) {
    if ([string]::IsNullOrWhiteSpace($Command)) {
        return [pscustomobject]@{ Command = $null; Passed = $null; ExitCode = $null; Output = 'No test command supplied.' }
    }
    $job = Start-Job -ScriptBlock {
        param($wd, $cmd)
        Set-Location -LiteralPath $wd
        try {
            $out = Invoke-Expression $cmd 2>&1 | Out-String
            $code = $LASTEXITCODE
            if ($null -eq $code) { $code = 0 }
            [pscustomobject]@{ Output = $out; ExitCode = [int]$code }
        } catch {
            [pscustomobject]@{ Output = ($_ | Out-String); ExitCode = 1 }
        }
    } -ArgumentList $WorkingDirectory, $Command
    $finished = Wait-Job $job -Timeout $Timeout
    if (-not $finished) {
        Stop-Job $job -ErrorAction SilentlyContinue
        $result = [pscustomobject]@{ Output = "Timed out after $Timeout seconds."; ExitCode = 124 }
    } else {
        $result = Receive-Job $job
    }
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    $passed = ($result.ExitCode -eq 0)
    return [pscustomobject]@{ Command = $Command; Passed = $passed; ExitCode = $result.ExitCode; Output = [string]$result.Output }
}

try {
    switch ($Action) {
        'intake' {
            if (-not $ProjectName -or -not $Title -or -not $Objective) { throw 'intake requires -Project, -Title and -Objective.' }
            $projectEntry = Get-ProjectEntry $ProjectName
            $slug = ($Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
            if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40).Trim('-') }
            $id = 'T-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $slug
            $dir = Join-Path $tasksDir $id
            New-Item -ItemType Directory -Force -Path $dir, (Join-Path $dir 'checkpoints'), (Join-Path $dir 'evidence') | Out-Null
            $task = [ordered]@{
                id = $id
                title = $Title
                objective = $Objective
                project = [string]$projectEntry.name
                priority = $Priority
                specialist = $Specialist
                status = 'queued'
                dependencies = @($Dependencies)
                files = [ordered]@{ expected = @($Files); claimed = @(); changed = @() }
                owner = [ordered]@{ agent = $null; sessionId = $null; worktree = $null; branch = $null }
                contextPath = $null
                handoverPath = $null
                failoverPath = $null
                lastCheckpoint = $null
                verification = [ordered]@{ commands = @($projectEntry.verify); last = $null }
                createdAt = (NowIso)
                updatedAt = (NowIso)
            }
            Write-Json (Join-Path $dir 'task.json') $task
            $contextPath = New-Context $dir (Read-Task $dir)
            Write-Host "Task created: $id"
            Write-Host "Context: $contextPath"
            Write-Host "Project: $($task.project)"
        }
        'context' {
            $dir = Get-TaskDir $TaskId
            $task = Read-Task $dir
            $contextPath = New-Context $dir $task
            Write-Host "Context written: $contextPath"
        }
        'claim' {
            $dir = Get-TaskDir $TaskId
            Invoke-WithClaimsLock {
                $task = Read-Task $dir
                $taskCopy = $task
                $expected = @($taskCopy.files.expected)
                if ($expected.Count -eq 0) { throw 'No files are declared for this task. Update task.files.expected before claiming.' }
                $project = [string]$taskCopy.project
                $claims = Get-Claims
                $now = Get-Date
                $active = @()
                foreach ($claim in @($claims.claims)) {
                    if ($claim.leaseUntil) {
                        try { if ([datetime]$claim.leaseUntil -gt $now) { $active += $claim } } catch { }
                    }
                }
                foreach ($claim in $active) {
                    if ($claim.taskId -eq $taskCopy.id) { continue }
                    foreach ($existing in @($claim.paths)) {
                        foreach ($wanted in $expected) {
                            if ((Test-PathOverlap $existing $wanted) -and $claim.project -eq $project) {
                                throw "Claim conflict: $project/$wanted overlaps $($claim.taskId) claim $existing (lease until $($claim.leaseUntil))."
                            }
                        }
                    }
                }
                $projectEntry = Get-ProjectEntry $project
                $projectDir = Join-Path $root ([string]$projectEntry.path)
                $baseHashes = [ordered]@{}
                foreach ($file in $expected) {
                    $full = Join-Path $projectDir $file
                    if (Test-Path -LiteralPath $full -PathType Leaf) {
                        $baseHashes[$file] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLower()
                    } else { $baseHashes[$file] = $null }
                }
                $active += [pscustomobject]@{
                    taskId = $taskCopy.id
                    project = $project
                    paths = @($expected)
                    owner = $taskCopy.owner.agent
                    sessionId = $taskCopy.owner.sessionId
                    worktree = $taskCopy.owner.worktree
                    branch = $taskCopy.owner.branch
                    claimedAt = (NowIso)
                    leaseUntil = ((Get-Date).AddMinutes($Minutes)).ToUniversalTime().ToString('o')
                    baseHashes = $baseHashes
                }
                Save-Claims ([pscustomobject]@{ claims = @($active) })
                Set-Field $taskCopy 'status' 'running'
                Set-Field $taskCopy 'files.claimed' @($expected)
                Save-Task $dir $taskCopy
                Write-Host "Claimed $($expected.Count) path(s) for $($taskCopy.id) until $((Get-Date).AddMinutes($Minutes).ToString('s'))"
            }
        }
        'release' {
            $dir = Get-TaskDir $TaskId
            Invoke-WithClaimsLock {
                $claims = Get-Claims
                $remaining = @($claims.claims | Where-Object { $_.taskId -ne $TaskId })
                Save-Claims ([pscustomobject]@{ claims = @($remaining) })
            }
            $task = Read-Task $dir
            Set-Field $task 'files.claimed' @()
            Save-Task $dir $task
            Write-Host "Claims released for $TaskId"
        }
        'assign' {
            $dir = Get-TaskDir $TaskId
            $task = Read-Task $dir
            Set-Field $task 'owner.agent' $Agent
            Set-Field $task 'owner.sessionId' $SessionId
            Set-Field $task 'owner.worktree' $Worktree
            Set-Field $task 'owner.branch' $Branch
            Set-Field $task 'status' 'assigned'
            Save-Task $dir $task
            Write-Host "Assigned $TaskId to $Agent / $SessionId"
        }
        'checkpoint' {
            $dir = Get-TaskDir $TaskId
            $task = Read-Task $dir
            $project = Get-ProjectEntry ([string]$task.project)
            $projectDir = Join-Path $root ([string]$project.path)
            $sequence = @(Get-ChildItem -LiteralPath (Join-Path $dir 'checkpoints') -File -Filter '*.json' -ErrorAction SilentlyContinue).Count + 1
            $test = Invoke-TestCommand $projectDir $TestCommand $TimeoutSeconds
            $status = @(git -C $projectDir status --porcelain 2>$null)
            $changed = @($status | ForEach-Object { if ($_.Length -gt 3) { $_.Substring(3).Trim() } })
            $branch = (git -C $projectDir branch --show-current 2>$null | Out-String).Trim()
            $head = (git -C $projectDir rev-parse --short HEAD 2>$null | Out-String).Trim()
            $diffStat = @(git -C $projectDir diff --stat 2>$null)
            $log = (git -C $projectDir log -1 --format='%h %s' 2>$null | Out-String).Trim()
            $evidenceName = ('checkpoint-{0:D3}.log' -f $sequence)
            $evidencePath = Join-Path $dir ('evidence/' + $evidenceName)
            $evidence = "Task: $TaskId`nCheckpoint: $sequence`nCaptured: $(NowIso)`nTest command: $($test.Command)`nExit code: $($test.ExitCode)`nPassed: $($test.Passed)`n`n$($test.Output)"
            Write-Text $evidencePath $evidence
            $checkpoint = [ordered]@{
                taskId = $TaskId
                sequence = $sequence
                capturedAt = (NowIso)
                project = [string]$task.project
                branch = $branch
                head = $head
                gitStatus = @($status)
                changedFiles = @($changed)
                diffStat = @($diffStat)
                lastCommit = $log
                notes = $Notes
                owner = $task.owner
                test = [ordered]@{
                    command = $test.Command
                    passed = $test.Passed
                    exitCode = $test.ExitCode
                    evidenceFile = ('docs/ai/tasks/' + (Split-Path -Leaf $dir) + '/evidence/' + $evidenceName)
                    outputPreview = if ($test.Output.Length -gt 4000) { $test.Output.Substring(0, 4000) } else { $test.Output }
                }
            }
            $checkpointName = ('checkpoint-{0:D3}.json' -f $sequence)
            Write-Json (Join-Path $dir ('checkpoints/' + $checkpointName)) $checkpoint
            Set-Field $task 'status' 'checkpointed'
            Set-Field $task 'lastCheckpoint' ('docs/ai/tasks/' + (Split-Path -Leaf $dir) + '/checkpoints/' + $checkpointName)
            Set-Field $task 'files.changed' @($changed)
            Set-Field $task 'verification.last' $checkpoint.test
            Save-Task $dir $task
            Write-Host "Checkpoint $sequence written. Test passed: $($test.Passed) (exit $($test.ExitCode))"
            Write-Host "Evidence: $evidencePath"
        }
        'handover' {
            $dir = Get-TaskDir $TaskId
            $task = Read-Task $dir
            $checkpoint = Get-LatestCheckpoint $dir
            if ($null -eq $checkpoint) { throw 'A handover requires at least one checkpoint.' }
            $project = Get-ProjectEntry ([string]$task.project)
            $projectDir = Join-Path $root ([string]$project.path)
            $status = @(git -C $projectDir status --porcelain 2>$null)
            $changed = @($checkpoint.changedFiles)
            $test = $checkpoint.test
            $lines = New-Object System.Collections.Generic.List[string]
            $lines.Add("# Agent handover - $($task.id)")
            $lines.Add('')
            $lines.Add("Created: $(NowIso)")
            $lines.Add("Project: $($task.project)")
            $lines.Add("Original task: $($task.title)")
            $lines.Add("Expected outcome: $($task.objective)")
            $lines.Add("Status: handover (not assumed complete)")
            $lines.Add('')
            $lines.Add('## Ownership')
            $lines.Add("- Agent: $($task.owner.agent)")
            $lines.Add("- Session: $($task.owner.sessionId)")
            $lines.Add("- Worktree: $($task.owner.worktree)")
            $lines.Add("- Branch: $($checkpoint.branch)")
            $lines.Add("- HEAD: $($checkpoint.head)")
            $lines.Add('')
            $lines.Add('## Work completed')
            foreach ($file in $changed) { $lines.Add("- $file") }
            if ($changed.Count -eq 0) { $lines.Add('- No changed files were captured in the latest checkpoint.') }
            $lines.Add('')
            $lines.Add('## Implementation details and decisions')
            if ($Notes) { $lines.Add($Notes) } else { $lines.Add('- No additional implementation notes were supplied. Read the actual changed files.') }
            foreach ($decision in @($Decisions)) { $lines.Add("- Decision: $decision") }
            $lines.Add('')
            $lines.Add('## Tests and evidence')
            $lines.Add("- Command: $($test.command)")
            $lines.Add("- Passed: $($test.passed)")
            $lines.Add("- Exit code: $($test.exitCode)")
            $lines.Add("- Evidence: $($test.evidenceFile)")
            $lines.Add('')
            $lines.Add('## Outstanding issues, blockers and risks')
            foreach ($blocker in @($Blockers)) { $lines.Add("- Blocker: $blocker") }
            foreach ($risk in @($Risks)) { $lines.Add("- Risk: $risk") }
            if ($status.Count -gt 0) { $lines.Add("- Uncommitted workspace paths remain: $($status.Count). Do not discard them.") }
            $lines.Add('')
            $lines.Add('## Remaining steps')
            if ($NextStep) { $lines.Add("- $NextStep") } else { $lines.Add('- Review the actual workspace and continue from the latest checkpoint.') }
            $lines.Add('')
            $lines.Add('## Required next action')
            $lines.Add('- The replacement agent must verify the actual workspace, claim the remaining files, continue from the latest checkpoint and never repeat completed work.')
            $lines.Add('- A task is not complete until tests/verification pass and knowledge sync records the evidence.')
            $handoverText = $lines -join "`n"
            $handoverPath = Join-Path $dir 'handover.md'
            Write-Text $handoverPath $handoverText
            $centralName = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $TaskId + '.md'
            $centralPath = Join-Path $handoffsDir $centralName
            Write-Text $centralPath $handoverText
            Set-Field $task 'status' 'handover'
            Set-Field $task 'handoverPath' ('docs/ai/tasks/' + (Split-Path -Leaf $dir) + '/handover.md')
            Save-Task $dir $task
            Write-Host "Handover written: $handoverPath"
            Write-Host "Central handoff: $centralPath"
        }
        'failover' {
            $dir = Get-TaskDir $TaskId
            $task = Read-Task $dir
            $checkpoint = Get-LatestCheckpoint $dir
            if ($null -eq $checkpoint) { throw 'Failover requires a checkpoint.' }
            $handoverText = ''
            $handoverPath = Join-Path $dir 'handover.md'
            if (Test-Path -LiteralPath $handoverPath) { $handoverText = Get-Content -LiteralPath $handoverPath -Raw }
            $lines = New-Object System.Collections.Generic.List[string]
            $lines.Add("# Failover package - $($task.id)")
            $lines.Add('')
            $lines.Add("Created: $(NowIso)")
            $lines.Add("Reason: $(if ($Reason) { $Reason } else { 'Agent became unavailable or task state is stale.' })")
            $lines.Add("Previous owner: $($task.owner.agent) / $($task.owner.sessionId) / $($task.owner.worktree)")
            $lines.Add("Project: $($task.project)")
            $lines.Add("Task: $($task.title)")
            $lines.Add('')
            $lines.Add('## Last verified checkpoint')
            $lines.Add("- Sequence: $($checkpoint.sequence)")
            $lines.Add("- Captured: $($checkpoint.capturedAt)")
            $lines.Add("- Branch: $($checkpoint.branch)")
            $lines.Add("- HEAD: $($checkpoint.head)")
            $lines.Add("- Tests passed: $($checkpoint.test.passed) (exit $($checkpoint.test.exitCode))")
            $lines.Add("- Evidence: $($checkpoint.test.evidenceFile)")
            $lines.Add("- Changed files: $((@($checkpoint.changedFiles) -join ', '))")
            $lines.Add('')
            $lines.Add('## Handover')
            if ($handoverText) { $lines.Add($handoverText) } else { $lines.Add('- No handover file existed. Read the checkpoint and actual workspace before continuing.') }
            $lines.Add('')
            $lines.Add('## Replacement instructions')
            $lines.Add('- Do not assume the interrupted task is complete.')
            $lines.Add('- Verify the actual workspace and git state before editing.')
            $lines.Add('- Claim the remaining files, continue from the last checkpoint and do not repeat completed work.')
            $lines.Add('- Create a new checkpoint and handover or final verification after the replacement agent acts.')
            $failoverText = $lines -join "`n"
            $failoverPath = Join-Path $dir 'failover.md'
            Write-Text $failoverPath $failoverText
            Set-Field $task 'status' 'failover_ready'
            Set-Field $task 'failoverPath' ('docs/ai/tasks/' + (Split-Path -Leaf $dir) + '/failover.md')
            Save-Task $dir $task
            New-Context $dir $task | Out-Null
            Set-Field $task 'status' 'failover_ready'
            Save-Task $dir $task
            Write-Host "Failover package written: $failoverPath"
        }
        'resume' {
            $dir = Get-TaskDir $TaskId
            $task = Read-Task $dir
            $contextPath = New-Context $dir $task
            Set-Field $task 'status' 'context_ready'
            Save-Task $dir $task
            Write-Host "Resume context written: $contextPath"
        }
        'sync' {
            $dir = Get-TaskDir $TaskId
            $task = Read-Task $dir
            $checkpoint = Get-LatestCheckpoint $dir
            if ($null -eq $checkpoint) { throw 'Knowledge sync requires a checkpoint.' }
            if ($checkpoint.test.passed -ne $true -and -not $Force) { throw 'Knowledge sync requires a passing test checkpoint, or -Force with a reason.' }
            $project = Get-ProjectEntry ([string]$task.project)
            $projectDir = Join-Path $root ([string]$project.path)
            $status = @(git -C $projectDir status --porcelain 2>$null)
            if ($status.Count -gt 0 -and -not $Force) { throw 'Knowledge sync requires a clean project working tree, or -Force with a reason.' }
            $head = (git -C $projectDir rev-parse HEAD 2>$null | Out-String).Trim()
            $branch = (git -C $projectDir branch --show-current 2>$null | Out-String).Trim()
            $verifiedPath = Join-Path $knowledgeDir 'VERIFIED_STATE.json'
            $verified = Read-Json $verifiedPath
            if ($null -eq $verified) { $verified = [pscustomobject]@{} }
            $entry = [ordered]@{
                project = [string]$task.project
                taskId = $task.id
                checkpoint = $task.lastCheckpoint
                branch = $branch
                commit = $head
                verifiedAt = (NowIso)
                tests = $checkpoint.test
                changedFiles = @($checkpoint.changedFiles)
                changedCount = @($checkpoint.changedFiles).Count
                verifiedBy = $checkpoint.owner
                forced = [bool]$Force
                reason = $Reason
            }
            if ($verified.PSObject.Properties.Name -contains $task.project) { $verified.$($task.project) = $entry }
            else { $verified | Add-Member -NotePropertyName ([string]$task.project) -NotePropertyValue $entry -Force }
            Write-Json $verifiedPath $verified

            $changelogPath = Join-Path $knowledgeDir 'CHANGELOG.md'
            $existing = if (Test-Path -LiteralPath $changelogPath) { Get-Content -LiteralPath $changelogPath -Raw } else { "# Verified knowledge changelog`n" }
            $entryLines = @(
                '',
                "## $(NowIso) - $($task.project) - $($task.id)",
                '',
                "- Branch: $branch",
                "- Commit: $head",
                "- Checkpoint: $($task.lastCheckpoint)",
                "- Tests: $($checkpoint.test.command) -> passed=$($checkpoint.test.passed) exit=$($checkpoint.test.exitCode)",
                "- Changed files: $((@($checkpoint.changedFiles) -join ', '))",
                "- Verified by: $($checkpoint.owner.agent) / $($checkpoint.owner.sessionId)",
                "- Forced: $([bool]$Force)"
            ) -join "`n"
            if (-not $existing.EndsWith("`n")) { $existing += "`n" }
            Write-Text $changelogPath ($existing + $entryLines + "`n")

            $manifestPath = Join-Path $knowledgeDir 'projects.json'
            $manifest = Read-Json $manifestPath
            if ($null -ne $manifest) {
                foreach ($p in @($manifest.projects)) {
                    if ($p.name -eq $task.project) {
                        Set-Field $p 'lastVerified' $entry
                        Set-Field $p 'lastCommit' $head
                        if ($p.PSObject.Properties.Name -contains 'knowledgeFile') {
                            $knowledgeFile = Join-Path $root $p.knowledgeFile
                            if (Test-Path -LiteralPath $knowledgeFile) {
                                $knowledgeText = Get-Content -LiteralPath $knowledgeFile -Raw
                                $lastLine = (git -C $projectDir log -1 --format='%cI - %s' 2>$null | Out-String).Trim()
                                $knowledgeText = [regex]::Replace($knowledgeText, '(?m)^- Current branch:.*$', "- Current branch: $branch")
                                $knowledgeText = [regex]::Replace($knowledgeText, '(?m)^- Current HEAD:.*$', "- Current HEAD: $head")
                                $knowledgeText = [regex]::Replace($knowledgeText, '(?m)^- Last commit:.*$', "- Last commit: $lastLine")
                                Write-Text $knowledgeFile $knowledgeText
                            }
                        }
                    }
                }
                Write-Json $manifestPath $manifest
            }

            Set-Field $task 'status' ($(if ($Complete) { 'done' } else { 'verified' }))
            Set-Field $task 'verifiedAt' (NowIso)
            Save-Task $dir $task
            Write-Host "Knowledge sync written for $($task.project) at $head"
            Write-Host "Verified state: $verifiedPath"
        }
        'status' {
            "HOUSE TASKS"
            $tasks = @(Get-AllTasks | Sort-Object updatedAt -Descending)
            if ($tasks.Count -eq 0) { '  none' }
            foreach ($task in $tasks) {
                "  $($task.status.PadRight(14)) $($task.id)  owner=$($task.owner.agent)  project=$($task.project)"
            }
            ''
            'ACTIVE CLAIMS'
            $claims = Get-Claims
            $active = @($claims.claims | Where-Object { $_.leaseUntil -and ([datetime]$_.leaseUntil) -gt (Get-Date) })
            if ($active.Count -eq 0) { '  none' }
            foreach ($claim in $active) { "  $($claim.taskId) $($claim.project): $((@($claim.paths) -join ', ')) until $($claim.leaseUntil)" }
            ''
            'VERIFIED KNOWLEDGE'
            $verified = Read-Json (Join-Path $knowledgeDir 'VERIFIED_STATE.json')
            if ($null -eq $verified -or @($verified.PSObject.Properties).Count -eq 0) { '  none' }
            else { foreach ($property in $verified.PSObject.Properties) { "  $($property.Name): $($property.Value.commit) ($($property.Value.tests.command) passed=$($property.Value.tests.passed))" } }
        }
        'list' {
            $tasks = @(Get-AllTasks | Sort-Object createdAt -Descending)
            foreach ($task in $tasks) { "$($task.id)`t$($task.status)`t$($task.project)`t$($task.title)" }
        }
    }
} catch {
    Write-Error $_
    exit 1
}
