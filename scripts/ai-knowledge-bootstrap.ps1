param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $Root).Path
$registryPath = Join-Path $root 'projects.json'
if (-not (Test-Path -LiteralPath $registryPath)) {
    throw "projects.json is missing in $root"
}

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$knowledgeDir = Join-Path $root 'docs/ai/knowledge'
$projectsDir = Join-Path $knowledgeDir 'projects'
$stateDir = Join-Path $knowledgeDir 'state'
New-Item -ItemType Directory -Force -Path $projectsDir, $stateDir | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding($false)
function Write-Text([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Get-GitValue([string]$ProjectDir, [string]$Arguments) {
    try {
        $parts = $Arguments -split ' '
        return (git -C $ProjectDir @parts 2>$null | Out-String).Trim()
    } catch { return '' }
}

$manifestProjects = @()
$indexRows = @()

foreach ($project in $registry.projects) {
    $name = [string]$project.name
    $path = [string]$project.path
    $projectDir = Join-Path $root $path
    $knowledgeFile = "docs/ai/knowledge/projects/$name.md"
    $knowledgePath = Join-Path $root $knowledgeFile

    $keyPaths = @()
    foreach ($candidate in @('app', 'backend', 'frontend', 'worker', 'companion', 'routes', 'resources', 'database', 'tests', 'docs', 'public')) {
        if (Test-Path -LiteralPath (Join-Path $projectDir $candidate)) { $keyPaths += $candidate }
    }

    $docs = @()
    foreach ($candidate in @('README.md', 'AGENTS.md', 'CLAUDE.md', 'docs/ai-memory/INDEX.md', 'docs/IMPLEMENTATION_STATUS.md', 'docs/ARCHITECTURE.md', 'docs/LIMITATIONS.md', 'docs/implementation-notes.md')) {
        if (Test-Path -LiteralPath (Join-Path $projectDir $candidate)) { $docs += $candidate }
    }
    $planDir = Join-Path $projectDir 'docs/superpowers/plans'
    if (Test-Path -LiteralPath $planDir) {
        Get-ChildItem -LiteralPath $planDir -File -Filter '*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object {
            $docs += ($_.FullName.Substring($projectDir.Length + 1).Replace('\', '/'))
        }
    }

    $branch = Get-GitValue $projectDir 'branch --show-current'
    $head = Get-GitValue $projectDir 'rev-parse --short HEAD'
    $lastCommit = Get-GitValue $projectDir 'log -1 --format=%s'
    $lastCommitDate = Get-GitValue $projectDir 'log -1 --format=%cI'
    $dirtyCount = @(git -C $projectDir status --porcelain 2>$null).Count

    if (-not (Test-Path -LiteralPath $knowledgePath)) {
        $stack = switch -Wildcard ($project.type) {
            '*Laravel*' { 'Laravel monolith: routes in `routes/`, controllers in `app/Http/Controllers`, Blade views in `resources/views`, tests in `tests/`.' }
            '*SvelteKit*' { 'FastAPI backend under `backend/app` with SQLAlchemy async and PostgreSQL/Redis; SvelteKit 2 + TypeScript frontend under `frontend/src`.' }
            '*Next.js*' { 'FastAPI backend under `patu_engine/` with PostgreSQL/Redis; Next.js + TypeScript frontend under `frontend/`.' }
            default { 'See the project README and source before making changes.' }
        }
        $rules = if ($project.rules.Count -gt 0) { ($project.rules | ForEach-Object { "- ``$_``" }) -join "`n" } else { '- No project-specific rule files. House rules apply.' }
        $docsBlock = if ($docs.Count -gt 0) { ($docs | ForEach-Object { "- ``$_``" }) -join "`n" } else { '- No indexed project documentation.' }
        $verify = if ($project.verify.Count -gt 0) { ($project.verify | ForEach-Object { "- ``$_``" }) -join "`n" } else { '- No verify command recorded.' }
        $keyPathsBlock = if ($keyPaths.Count -gt 0) { ($keyPaths | ForEach-Object { "- ``$_``" }) -join "`n" } else { '- No standard key paths detected.' }

        $contentTemplate = @'
# __NAME__ - central project knowledge

> Verified summary. Code, git and executed test evidence are authoritative. Read the actual files before changing them. Do not use this file as a substitute for source inspection.

## Identity

- Type: __TYPE__
- Repository: __REMOTE__
- Current branch: __BRANCH__
- Current HEAD: __HEAD__
- Last commit: __LASTCOMMIT__
- Workspace state at bootstrap: __DIRTY__ changed path(s)

## Stack and architecture

__STACK__

## Key paths

__KEYPATHS__

## Rules and memory sources

__RULES__

## Project documentation and memory

__DOCS__

## Verification commands

__VERIFY__

## Verified state

See `docs/ai/knowledge/VERIFIED_STATE.json` and `docs/ai/knowledge/CHANGELOG.md`. A checkpoint is not verified until tests or equivalent evidence are recorded.

## Architecture and decisions

Maintained by the knowledge-scribe after verified changes. Record decisions, constraints and important implementation references here; never invent a decision.

## Outstanding work and known issues

- Not yet recorded in central knowledge. Update from verified task handovers and project memory.
'@
        $content = $contentTemplate.
            Replace('__NAME__', $name).
            Replace('__TYPE__', [string]$project.type).
            Replace('__REMOTE__', [string]$project.remote).
            Replace('__BRANCH__', $branch).
            Replace('__HEAD__', $head).
            Replace('__LASTCOMMIT__', "$lastCommitDate - $lastCommit").
            Replace('__DIRTY__', [string]$dirtyCount).
            Replace('__STACK__', $stack).
            Replace('__KEYPATHS__', $keyPathsBlock).
            Replace('__RULES__', $rules).
            Replace('__DOCS__', $docsBlock).
            Replace('__VERIFY__', $verify)
        Write-Text $knowledgePath $content
    }

    $lastVerified = $null
    $verifiedPath = Join-Path $knowledgeDir 'VERIFIED_STATE.json'
    if (Test-Path -LiteralPath $verifiedPath) {
        try {
            $verified = Get-Content -LiteralPath $verifiedPath -Raw | ConvertFrom-Json
            if ($verified.PSObject.Properties.Name -contains $name) { $lastVerified = $verified.$name }
        } catch { }
    }

    $manifestProjects += [ordered]@{
        name = $name
        path = $path
        website = $project.website
        role = $project.role
        type = $project.type
        remote = $project.remote
        branch = $branch
        rules = @($project.rules)
        verify = @($project.verify)
        knowledgeFile = $knowledgeFile
        keyPaths = @($keyPaths)
        docs = @($docs)
        lastCommit = $head
        lastCommitSubject = $lastCommit
        lastCommitAt = $lastCommitDate
        lastVerified = $lastVerified
    }
    $indexRows += "| $name | $($project.type) | ``$knowledgeFile`` | $($project.remote) |"
}

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    source = 'scripts/ai-knowledge-bootstrap.ps1'
    projects = $manifestProjects
    websites = @($registry.websites)
}
Write-Text (Join-Path $knowledgeDir 'projects.json') ($manifest | ConvertTo-Json -Depth 20)

if (-not (Test-Path -LiteralPath (Join-Path $knowledgeDir 'VERIFIED_STATE.json'))) {
    Write-Text (Join-Path $knowledgeDir 'VERIFIED_STATE.json') "{`n}`n"
}
if (-not (Test-Path -LiteralPath (Join-Path $knowledgeDir 'CHANGELOG.md'))) {
    Write-Text (Join-Path $knowledgeDir 'CHANGELOG.md') "# Verified knowledge changelog`n`nOnly entries backed by a checkpoint, git state and executed test evidence belong here.`n"
}
if (-not (Test-Path -LiteralPath (Join-Path $knowledgeDir 'DECISIONS.md'))) {
    Write-Text (Join-Path $knowledgeDir 'DECISIONS.md') "# House and project decisions`n`nDated decisions with rationale. Architecture changes require an explicit decision entry.`n"
}
if (-not (Test-Path -LiteralPath (Join-Path $knowledgeDir 'KNOWN_ISSUES.md'))) {
    Write-Text (Join-Path $knowledgeDir 'KNOWN_ISSUES.md') "# Known issues and limitations`n`nSeverity, status and evidence. Do not list unverified guesses as facts.`n"
}

$indexTemplate = @'
# Central knowledge index

This is the permanent, repository-backed knowledge layer for the Template Business house. Agents are temporary workers; code, verified checkpoints and this knowledge survive sessions.

## Load order

1. `AGENTS.md` - mandatory house rules.
2. `docs/ai/knowledge/INDEX.md` (this file).
3. `docs/ai/knowledge/MASTER_RULES.md` - adopted PATU Studio master rules.
4. The target project's summary below, its rule sources, and task context package.
5. Only then the task's expected files and immediate dependencies.

Do not perform a full-worktree onboarding before every task. The orchestrator prepares a task context package with the relevant knowledge and file references.

## Knowledge files

- `projects.json` - machine-readable project manifest (stack, rules, verify commands, key paths, current commits).
- `projects/<name>.md` - per-project verified summary and architecture notes.
- `VERIFIED_STATE.json` - latest verified checkpoint per project.
- `CHANGELOG.md` - verified changes, newest first.
- `DECISIONS.md` - settled decisions and rationale.
- `KNOWN_ISSUES.md` - confirmed issues and limitations.
- `studio-specialists.json` - adopted Studio specialist catalog.
- `studio-skill-map.json` - specialist-to-skill mapping.
- `MASTER_RULES.md` - adopted Studio master coding rules.

## Projects

| Project | Type | Knowledge | Remote |
|---|---|---|---|
__ROWS__

## Task lifecycle

`intake -> context -> claim -> assign -> checkpoint -> handover/failover -> resume -> sync`

Task state and handover records live under `docs/ai/tasks`. Runtime claims live under the house main worktree's `.kilo/ai/`. Use `scripts/ai-orchestrator.ps1`.
'@
$index = $indexTemplate.Replace('__ROWS__', ($indexRows -join "`n"))
$indexPath = Join-Path $knowledgeDir 'INDEX.md'
if (-not (Test-Path -LiteralPath $indexPath)) {
    Write-Text $indexPath $index
} else {
    Write-Host 'INDEX.md exists; preserved.' -ForegroundColor Yellow
}

Write-Host "Knowledge bootstrap complete: $($manifestProjects.Count) projects" -ForegroundColor Green
