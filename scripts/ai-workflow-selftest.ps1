$ErrorActionPreference = 'Stop'
$houseScripts = $PSScriptRoot
$orchestrator = Join-Path $houseScripts 'ai-orchestrator.ps1'
$bootstrap = Join-Path $houseScripts 'ai-knowledge-bootstrap.ps1'
$temp = Join-Path $env:TEMP ('ai-workflow-selftest-' + [guid]::NewGuid().ToString('N'))
$demo = Join-Path $temp 'demo'
$script:failures = 0

function Assert([bool]$Condition, [string]$Name) {
    if ($Condition) { Write-Host "PASS  $Name" -ForegroundColor Green }
    else { Write-Host "FAIL  $Name" -ForegroundColor Red; $script:failures++ }
}

function Invoke-Orchestrator {
    param([string[]]$Arguments)
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $orchestrator @Arguments 2>&1
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
    } finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Get-LatestTaskId {
    $taskDir = Get-ChildItem -LiteralPath (Join-Path $temp 'docs/ai/tasks') -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $taskDir.Name
}

try {
    New-Item -ItemType Directory -Force -Path $demo, (Join-Path $demo 'app') | Out-Null
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Join-Path $demo 'README.md'), "# Demo`n`nA temporary project for the AI workflow self-test.`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $demo 'app/Greeter.php'), "<?php`nfunction demo_greeter(string `$name): string { return 'hello ' . `$name; }`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $demo 'secret.html'), "<p>not relevant to the greeter task</p>`n", $utf8)

    & git init -b main $demo 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { & git init $demo 2>$null | Out-Null; & git -C $demo symbolic-ref HEAD refs/heads/main }
    & git -C $demo config user.name 'AI Selftest'
    & git -C $demo config user.email 'ai-selftest@example.test'
    & git -C $demo add README.md app/Greeter.php
    & git -C $demo commit -m 'test: demo baseline' 2>$null | Out-Null

    $projects = @{
        projects = @(
            @{
                name = 'demo'
                path = 'demo'
                type = 'Laravel'
                remote = 'local'
                branch = 'main'
                rules = @()
                verify = @('php -l app/Greeter.php')
            }
        )
    }
    [System.IO.File]::WriteAllText((Join-Path $temp 'projects.json'), ($projects | ConvertTo-Json -Depth 10), $utf8)

    $boot = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap -Root $temp 2>&1
    Assert ($LASTEXITCODE -eq 0) 'knowledge bootstrap runs'
    Assert (Test-Path -LiteralPath (Join-Path $temp 'docs/ai/knowledge/projects/demo.md')) 'project knowledge file exists'

    $intake = Invoke-Orchestrator @('-Root', $temp, '-Action', 'intake', '-Project', 'demo', '-Title', 'Add demo greeter', '-Objective', 'Verify the greeter and preserve the demo state', '-Files', 'README.md')
    Assert ($intake.ExitCode -eq 0) 'task intake succeeds'
    $task1 = Get-LatestTaskId
    $task1Dir = Join-Path $temp ('docs/ai/tasks/' + $task1)
    $contextPath = Join-Path $task1Dir 'context.md'
    Assert (Test-Path -LiteralPath $contextPath) 'task context package exists'
    $context = Get-Content -LiteralPath $contextPath -Raw
    Assert ($context.Contains('Task context package')) 'context is task-specific'
    Assert ($context.Contains('Expected files') -and $context.Contains('README.md')) 'context contains expected file references'
    Assert (-not $context.Contains('secret.html')) 'context does not include unrelated files'
    Assert ($context.Contains('Project knowledge')) 'context includes central project knowledge'

    $intake2 = Invoke-Orchestrator @('-Root', $temp, '-Action', 'intake', '-Project', 'demo', '-Title', 'Conflicting demo task', '-Objective', 'Conflict test', '-Files', 'README.md')
    Assert ($intake2.ExitCode -eq 0) 'second task intake succeeds'
    $task2 = Get-LatestTaskId

    $claim1 = Invoke-Orchestrator @('-Root', $temp, '-Action', 'claim', '-TaskId', $task1)
    Assert ($claim1.ExitCode -eq 0) 'first task claims README.md'
    $claim2 = Invoke-Orchestrator @('-Root', $temp, '-Action', 'claim', '-TaskId', $task2)
    Assert ($claim2.ExitCode -ne 0 -and $claim2.Output.Contains('Claim conflict')) 'overlapping claim is rejected'

    $assign = Invoke-Orchestrator @('-Root', $temp, '-Action', 'assign', '-TaskId', $task1, '-Agent', 'demo-agent', '-SessionId', 'ses-demo', '-Worktree', $temp, '-Branch', 'main')
    Assert ($assign.ExitCode -eq 0) 'task assignment succeeds'

    Add-Content -LiteralPath (Join-Path $demo 'README.md') -Value "`nGreeter verification completed.`n"
    Remove-Item -LiteralPath (Join-Path $demo 'secret.html') -Force
    $checkpoint = Invoke-Orchestrator @('-Root', $temp, '-Action', 'checkpoint', '-TaskId', $task1, '-TestCommand', 'php -l app/Greeter.php')
    Assert ($checkpoint.ExitCode -eq 0) 'checkpoint with test evidence succeeds'
    $checkpointFile = Get-ChildItem -LiteralPath (Join-Path $task1Dir 'checkpoints') -Filter '*.json' | Select-Object -First 1
    $checkpointData = Get-Content -LiteralPath $checkpointFile.FullName -Raw | ConvertFrom-Json
    Assert ($checkpointData.test.passed -eq $true) 'checkpoint records passing tests'
    Assert (@($checkpointData.changedFiles).Count -gt 0) 'checkpoint captures changed files'

    $handover = Invoke-Orchestrator @('-Root', $temp, '-Action', 'handover', '-TaskId', $task1, '-NextStep', 'Commit the verified change and sync knowledge')
    Assert ($handover.ExitCode -eq 0) 'handover succeeds'
    $handoverText = Get-Content -LiteralPath (Join-Path $task1Dir 'handover.md') -Raw
    Assert ($handoverText.Contains('Original task') -and $handoverText.Contains('README.md')) 'handover captures task and changed files'
    Assert ($handoverText.Contains('Required next action')) 'handover includes replacement instructions'

    $failover = Invoke-Orchestrator @('-Root', $temp, '-Action', 'failover', '-TaskId', $task1, '-Reason', 'quota exhausted')
    Assert ($failover.ExitCode -eq 0) 'failover package succeeds'
    Assert (Test-Path -LiteralPath (Join-Path $task1Dir 'failover.md')) 'failover package exists'
    $failoverContext = Get-Content -LiteralPath $contextPath -Raw
    Assert ($failoverContext.Contains('Original task')) 'replacement context includes prior handover'
    Assert (-not $failoverContext.Contains('Task is complete')) 'interrupted task is not assumed complete'

    $resume = Invoke-Orchestrator @('-Root', $temp, '-Action', 'resume', '-TaskId', $task1)
    Assert ($resume.ExitCode -eq 0) 'resume context succeeds'
    Assert (Test-Path -LiteralPath $contextPath) 'resume context is persisted'

    & git -C $demo add README.md
    & git -C $demo commit -m 'docs: complete demo greeter verification' 2>$null | Out-Null
    $newHead = (& git -C $demo rev-parse HEAD | Out-String).Trim()
    $sync = Invoke-Orchestrator @('-Root', $temp, '-Action', 'sync', '-TaskId', $task1, '-Complete')
    Assert ($sync.ExitCode -eq 0) 'knowledge sync succeeds after clean commit'
    $verified = Get-Content -LiteralPath (Join-Path $temp 'docs/ai/knowledge/VERIFIED_STATE.json') -Raw | ConvertFrom-Json
    Assert ($verified.demo.commit -eq $newHead) 'verified knowledge records the actual commit'
    Assert ($verified.demo.tests.passed -eq $true) 'verified knowledge records test evidence'
    $changelog = Get-Content -LiteralPath (Join-Path $temp 'docs/ai/knowledge/CHANGELOG.md') -Raw
    Assert ($changelog.Contains($task1)) 'knowledge changelog records the task'
    $taskData = Get-Content -LiteralPath (Join-Path $task1Dir 'task.json') -Raw | ConvertFrom-Json
    Assert ($taskData.status -eq 'done') 'completed task status is persisted'
    $knowledgeText = Get-Content -LiteralPath (Join-Path $temp 'docs/ai/knowledge/projects/demo.md') -Raw
    Assert ($knowledgeText.Contains("Current HEAD: $newHead")) 'project knowledge reflects the verified commit'

    Assert (Test-Path -LiteralPath (Join-Path $temp 'docs/ai/tasks')) 'task state survives independent of a session'
    Assert (Test-Path -LiteralPath (Join-Path $temp 'docs/ai/knowledge/VERIFIED_STATE.json')) 'knowledge survives independent of a session'

    Write-Host ''
    Write-Host "Self-test workspace: $temp"
    if ($script:failures -gt 0) {
        Write-Host "AI workflow self-test failed: $($script:failures) failure(s)." -ForegroundColor Red
        exit 1
    }
    Write-Host 'AI workflow self-test passed.' -ForegroundColor Green
    exit 0
} catch {
    Write-Host "AI workflow self-test error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Workspace: $temp"
    exit 1
}
