<#
.SYNOPSIS
    Installs the Contracts skill to detected AI coding assistants.

.DESCRIPTION
    Detects AI coding assistants (Copilot, Claude, Cursor, Codex) and installs
    the Contracts skill for spec-driven development.

.PARAMETER Agents
    Comma-separated list of agents (e.g., "copilot,claude"). Default: all detected.

.PARAMETER Auto
    Install to all detected agents without prompting.

.PARAMETER GitBranch
    Git branch to install from (default: main).

.PARAMETER NoUI
    Skip Contracts Web UI installation.

.PARAMETER UseLocalSource
    Use skill from local repo (for development/testing).

.PARAMETER SkillSourcePath
    Path to a local skill folder (overrides download).

.EXAMPLE
    irm https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.ps1 | iex

.EXAMPLE
    .\install.ps1 -Agents "copilot,claude" -Auto
#>

& {
[CmdletBinding()]
param(
    [string]$Agents = $null,
    [switch]$Auto,
    [string]$GitBranch = 'main',
    [switch]$NoUI,
    [switch]$UseLocalSource,
    [string]$SkillSourcePath = $null
)

$ErrorActionPreference = 'Stop'

$RepoOwner = 'kombifyio'
$RepoName  = 'contracts-skill'
$SkillName = 'contracts'
$HomeDir = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { [Environment]::GetFolderPath('UserProfile') }
$TempRoot = [System.IO.Path]::GetTempPath()

# --- Agent Configurations ---

$AgentConfigs = @(
    @{
        Name = 'GitHub Copilot'
        Id = 'copilot'
        Paths = @(
            $(if ($HomeDir) { Join-Path $HomeDir ".copilot/skills/$SkillName" })
        )
        DetectPaths = @(
            $(if ($HomeDir) { Join-Path $HomeDir '.copilot' }),
            $(if ($env:APPDATA)     { Join-Path $env:APPDATA 'Code/User/settings.json' })
        )
        InstructionFile = '.github/copilot-instructions.md'
        InstructionSnippet = @"

## Contracts System (MANDATORY)
Before any code changes: locate CONTRACT.md in target module, read spec + metadata, verify source_hash, summarize constraints briefly, then proceed.
"@
    },
    @{
        Name = 'Claude Code'
        Id = 'claude'
        Paths = @(
            $(if ($HomeDir) { Join-Path $HomeDir ".claude/skills/$SkillName" })
        )
        DetectPaths = @(
            $(if ($HomeDir) { Join-Path $HomeDir '.claude' }),
            $(if ($env:APPDATA)     { Join-Path $env:APPDATA 'Claude' })
        )
        InstructionFile = 'CLAUDE.md'
        InstructionSnippet = @"

## Contracts System
Before any code changes, determine the target module(s) and locate the nearest CONTRACT.md.
Read CONTRACT.md + CONTRACT.yaml and check drift (source_hash vs current hash); if drift exists, sync YAML first.
Before editing, give the user a very short "Contract Notes" summary of MUST / MUST NOT constraints (max 5 sentences).
CONTRACT.md is user-owned (never edit directly).
When creating a new module, propose generating a matching contract via init-agent (--module).
"@
    },
    @{
        Name = 'Cursor'
        Id = 'cursor'
        Paths = @(
            $(if ($HomeDir) { Join-Path $HomeDir ".cursor/skills/$SkillName" })
        )
        DetectPaths = @(
            $(if ($HomeDir) { Join-Path $HomeDir '.cursor' }),
            $(if ($env:APPDATA)     { Join-Path $env:APPDATA 'Cursor' })
        )
        InstructionFile = '.cursor/rules/contracts-system.mdc'
        InstructionSnippet = @"
---
description: "Contracts System preflight - MANDATORY before code changes"
alwaysApply: true
---

# Contracts System (MANDATORY)
Before code changes: locate CONTRACT.md in target module, read spec + metadata, verify source_hash, summarize constraints briefly.
"@
    },
    @{
        Name = 'OpenAI Codex'
        Id = 'codex'
        Paths = @(
            $(if ($HomeDir) { Join-Path $HomeDir ".codex/skills/$SkillName" })
        )
        DetectPaths = @(
            $(if ($HomeDir) { Join-Path $HomeDir '.codex' })
        )
        InstructionFile = 'codex.md'
        InstructionSnippet = @"

## Contracts System (MANDATORY)
Before any code changes: locate CONTRACT.md in target module, read spec + metadata, verify source_hash, summarize constraints briefly, then proceed.
"@
    },
    @{
        Name = 'Project Local'
        Id = 'local'
        Paths = @(
            (Join-Path (Get-Location) ".agent/skills/$SkillName")
        )
        DetectPaths = @(
            (Join-Path (Get-Location) '.git'),
            (Join-Path (Get-Location) 'package.json')
        )
        InstructionFile = $null
        InstructionSnippet = $null
        AlwaysOffer = $true
    }
)

# --- Helper Functions ---

function Get-InstallPath($Agent) {
    foreach ($p in $Agent.Paths) {
        if (-not $p) { continue }
        $parent = Split-Path $p -Parent
        if ((Test-Path $parent) -or $Agent.AlwaysOffer) { return $p }
    }
    return $Agent.Paths[0]
}

function Test-AgentDetected($Agent) {
    foreach ($p in $Agent.DetectPaths) {
        if ($p -and (Test-Path $p)) { return $true }
    }
    return $false
}

function Get-SkillSource {
    param([string]$TempDir)

    Write-Host '  Downloading skill...' -ForegroundColor Yellow

    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            git clone --quiet --depth 1 --branch $GitBranch "https://github.com/$RepoOwner/$RepoName.git" $TempDir 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0 -and (Test-Path $TempDir)) {
                Write-Host '  Downloaded via git' -ForegroundColor Green
                return Join-Path $TempDir 'skill'
            }
        } catch { }
    }

    $zipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$GitBranch.zip"
    $zipPath = Join-Path $TempRoot 'contracts-skill.zip'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
    Expand-Archive -Path $zipPath -DestinationPath $TempDir -Force
    Remove-Item $zipPath -ErrorAction SilentlyContinue
    $extracted = Get-ChildItem $TempDir -Directory | Select-Object -First 1
    Write-Host '  Downloaded via ZIP' -ForegroundColor Green
    return Join-Path $extracted.FullName 'skill'
}

# --- Main ---

Write-Host ''
Write-Host '  Contracts Skill Installer' -ForegroundColor Cyan
Write-Host '  Spec-Driven Development for AI Assistants' -ForegroundColor Cyan
Write-Host ''

# Detect agents
Write-Host '  Scanning for AI coding assistants...' -ForegroundColor Cyan
Write-Host ''

$detected = @()
$installed = @()

foreach ($agent in $AgentConfigs) {
    $installPath = Get-InstallPath $agent
    $skillFile = if ($installPath) { Join-Path $installPath 'SKILL.md' } else { $null }
    $isInstalled = $skillFile -and (Test-Path $skillFile)
    $isDetected = (Test-AgentDetected $agent) -or $agent.AlwaysOffer

    $status = if ($isInstalled) { 'INSTALLED'; $installed += $agent }
              elseif ($isDetected) { 'DETECTED'; $detected += $agent }
              else { 'NOT FOUND' }

    $color = switch ($status) { 'INSTALLED' { 'Green' } 'DETECTED' { 'Yellow' } default { 'Gray' } }
    Write-Host "    $($agent.Name): [$status]" -ForegroundColor $color
}
Write-Host ''

# Select agents
$selected = @()

if ($Agents) {
    $ids = $Agents -split ',' | ForEach-Object { $_.Trim().ToLower() }
    $selected = @($detected | Where-Object { $ids -contains $_.Id })
} elseif ($Auto) {
    $selected = $detected
} else {
    if ($detected.Count -eq 0) {
        Write-Host '  No new agents to install to.' -ForegroundColor Yellow
        return
    }

    for ($i = 0; $i -lt $detected.Count; $i++) {
        Write-Host "    [$($i + 1)] $($detected[$i].Name)" -ForegroundColor White
    }
    Write-Host "    [A] All detected" -ForegroundColor White
    Write-Host ''

    $resp = Read-Host '  Select (e.g., 1,2 or A)'
    if ($resp -match '^[Aa]$') {
        $selected = $detected
    } else {
        $indices = $resp -split ',' | ForEach-Object { $_.Trim() }
        foreach ($idx in $indices) {
            if ($idx -match '^\d+$') {
                $n = [int]$idx - 1
                if ($n -ge 0 -and $n -lt $detected.Count) { $selected += $detected[$n] }
            }
        }
    }
}

if ($selected.Count -eq 0) {
    Write-Host '  No agents selected.' -ForegroundColor Yellow
    return
}

# Get skill source
$tempDir = Join-Path $TempRoot ("contracts-skill-{0:yyyyMMddHHmmss}" -f (Get-Date))

try {
    $skillSource = $null
    if ($SkillSourcePath) {
        $skillSource = (Resolve-Path $SkillSourcePath).Path
    } elseif ($UseLocalSource) {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $skillSource = Join-Path $repoRoot 'skill'
        if (-not (Test-Path $skillSource)) { throw "Local skill folder not found: $skillSource" }
    } else {
        $skillSource = Get-SkillSource -TempDir $tempDir
    }

    Write-Host ''
    Write-Host "  Installing to $($selected.Count) agent(s)..." -ForegroundColor Cyan

    $successCount = 0
    foreach ($agent in $selected) {
        $targetPath = Get-InstallPath $agent
        Write-Host "    $($agent.Name)..." -NoNewline

        $parent = Split-Path $targetPath -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        if (Test-Path $targetPath) { Remove-Item -Recurse -Force $targetPath }
        Copy-Item -Path $skillSource -Destination $targetPath -Recurse -Force

        if (Test-Path (Join-Path $targetPath 'SKILL.md')) {
            Write-Host ' OK' -ForegroundColor Green
            $successCount++

            # Inject instruction hook
            if ($agent.InstructionFile -and $agent.InstructionSnippet) {
                $instrPath = Join-Path (Get-Location) $agent.InstructionFile
                if (Test-Path $instrPath) {
                    $content = Get-Content $instrPath -Raw
                    if ($content -notmatch 'Contracts System') {
                        Add-Content -Path $instrPath -Value $agent.InstructionSnippet -Encoding utf8
                        Write-Host "      -> Updated $($agent.InstructionFile)" -ForegroundColor Gray
                    }
                } else {
                    $dir = Split-Path $instrPath -Parent
                    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                    Set-Content -Path $instrPath -Value $agent.InstructionSnippet.Trim() -Encoding utf8
                    Write-Host "      -> Created $($agent.InstructionFile)" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host ' FAILED' -ForegroundColor Red
        }
    }

    # Install minimal-ui
    if (-not $NoUI) {
        $uiSource = Join-Path $skillSource 'ui/minimal-ui'
        if (Test-Path $uiSource) {
            Write-Host ''
            $installUI = $Auto
            if (-not $Auto) {
                try {
                    $resp = Read-Host '  Install Contracts Web UI? (y/N)'
                    $installUI = $resp -match '^[Yy]'
                } catch { }
            }

            if ($installUI) {
                $uiTarget = Join-Path (Get-Location) 'contracts-ui'
                if (Test-Path $uiTarget) { Remove-Item -Recurse -Force $uiTarget }
                Copy-Item -Path $uiSource -Destination $uiTarget -Recurse -Force
                Write-Host '    Installed Contracts UI -> ./contracts-ui' -ForegroundColor Green
                Write-Host '    Start: ./contracts-ui/start.ps1' -ForegroundColor Gray
            }
        }
    }

    # --- Project Setup ---
    Write-Host ''
    Write-Host '  Project Setup' -ForegroundColor Cyan
    Write-Host ''

    $setupProject = $Auto
    if (-not $Auto) {
        try {
            $resp = Read-Host '  Set up .contracts/ directory in this project? (Y/n)'
            $setupProject = ($resp -match '^[Yy]$') -or ($resp -eq '')
        } catch { $setupProject = $true }
    }

    if ($setupProject) {
        # Gather project info
        $projectName   = ''
        $projectStack  = ''
        $projectOwner  = ''
        $projectConventions = '(Add your project conventions here â€” module layout, test location, naming rules, etc.)'

        if (-not $Auto) {
            # Auto-detect project name
            $detectedName = ''
            if (Test-Path 'package.json') {
                try { $detectedName = (Get-Content 'package.json' -Raw | ConvertFrom-Json).name } catch {}
            }
            if (-not $detectedName -and (Get-Command git -ErrorAction SilentlyContinue)) {
                try {
                    $remote = git remote get-url origin 2>$null
                    if ($remote) { $detectedName = ($remote -split '/')[-1] -replace '\.git$', '' }
                } catch {}
            }
            if (-not $detectedName) { $detectedName = (Get-Location | Split-Path -Leaf) }

            Write-Host "    Detected project name: $detectedName" -ForegroundColor Gray
            $ans = Read-Host "    Project name (Enter = $detectedName)"
            $projectName = if ($ans) { $ans } else { $detectedName }

            $ans = Read-Host '    Primary stack/language (e.g., TypeScript, Go, Python)'
            $projectStack = if ($ans) { $ans } else { '(not set)' }

            $ans = Read-Host '    Contracts owner/team (e.g., your name or team)'
            $projectOwner = if ($ans) { $ans } else { '(not set)' }

            $ans = Read-Host '    Project conventions? (e.g., "features in src/features/, tests in __tests__/") or press Enter to skip'
            if ($ans) { $projectConventions = $ans }
        } else {
            # Auto mode: detect what we can
            if (Test-Path 'package.json') {
                try { $projectName = (Get-Content 'package.json' -Raw | ConvertFrom-Json).name } catch {}
            }
            if (-not $projectName -and (Get-Command git -ErrorAction SilentlyContinue)) {
                try {
                    $remote = git remote get-url origin 2>$null
                    if ($remote) { $projectName = ($remote -split '/')[-1] -replace '\.git$', '' }
                } catch {}
            }
            if (-not $projectName) { $projectName = (Get-Location | Split-Path -Leaf) }
            $projectStack = '(not set)'
            $projectOwner = '(not set)'
        }

        # Create .contracts/ directory
        $contractsDir = Join-Path (Get-Location) '.contracts'
        if (-not (Test-Path $contractsDir)) {
            New-Item -ItemType Directory -Path $contractsDir -Force | Out-Null
        }

        # Build skill paths table
        $skillPathLines = @()
        foreach ($a in $selected) {
            $sp = Get-InstallPath $a
            $skillPathLines += "| $($a.Name) | ``$sp`` |"
        }
        $skillPathsTable = @"
| Agent | Skill Path |
|-------|-----------|
$($skillPathLines -join "`n")
"@

        # Build CONTRACTS-GUIDE.md
        $today = Get-Date -Format 'yyyy-MM-dd'
        $guideContent = @"
# Contracts System â€” Project Guide

> **Permanent project artifact.** Commit this file to version control.
> This guide tells every developer and AI agent how the Contracts system is set up in this project.

---

## Project

**Name:** $projectName
**Stack:** $projectStack
**Owner:** $projectOwner
**Initialized:** $today

---

## Where to Find Things

| What you need | Location |
|---------------|----------|
| All contracts (registry) | ``.contracts/registry.yaml`` |
| A module's specification | ``<module-dir>/CONTRACT.md`` |
| A module's technical mapping | ``<module-dir>/CONTRACT.yaml`` |
| Contract templates | Skill: ``references/templates/`` |
| Init workflow (AI hook) | Skill: ``references/assistant-hooks/init-contracts.md`` |
| Preflight workflow (AI hook) | Skill: ``references/assistant-hooks/contract-preflight.md`` |
| Review workflow (AI hook) | Skill: ``references/assistant-hooks/contract-review.md`` |
| Validation script (Windows) | Skill: ``scripts/validate-contracts.ps1`` |

## Skill Locations

$skillPathsTable

---

## Registered Modules

*(Run ``"init contracts"`` to discover and register modules.)*

| Module | Path | Tier | Contract |
|--------|------|------|----------|

---

## How Contracts Are Applied

### Before any code change

The AI runs a **contract preflight** automatically before touching any module:

1. Locate ``CONTRACT.md`` in or above the target directory.
2. Read spec + YAML, compare ``source_hash``. Hash mismatch â†’ sync YAML first.
3. Check attestation freshness and VT status.
4. Summarize MUST / MUST NOT constraints (max 5 sentences).

Say **``"contract preflight"``** to trigger manually at any time.

### When you change a module spec

1. Edit ``CONTRACT.md`` yourself â€” AI never modifies the spec.
2. Tell the AI: ``"I've updated the contract for [module]"``.
3. AI syncs ``CONTRACT.yaml``, resets attestation to ``low``, adds changelog entry.

### When you add a new module

Say **``"init contracts for [module-path]"``** or **``"create a contract for [module]"``**.
AI analyzes the module, picks the right tier (core / standard / complex), drafts from the matching template, and presents it for your review.

### When work is out of scope

If the AI says "this isn't in the contract" â€” that is **intended behavior**.
Options: update ``CONTRACT.md`` to include it, or tell the AI to mark it as Out of Scope.

---

## Quick Commands

| Intent | Say to your AI |
|--------|----------------|
| Initialize contracts for this project | ``"init contracts"`` |
| Check before implementing a feature | ``"contract preflight"`` |
| Review scope after completing work | ``"contract review"`` |
| Scan all contracts for drift | ``"check contracts"`` |
| Sync all YAMLs from changed MDs | ``"sync contracts"`` |

---

## Project Conventions

$projectConventions

---

## Contract Tiers

| Tier | MD line limit | Typical complexity | Verification tests |
|------|--------------|--------------------|--------------------|
| ``core`` | 30 lines | < 100 LOC, foundational module | 1 |
| ``standard`` | 50 lines | 100-500 LOC, feature module | 1-2 |
| ``complex`` | 80 lines | > 500 LOC, multi-concern module | 2-3 |

---

*Contracts Skill â€” https://github.com/kombifyio/contracts-skill*
"@

        $guidePath = Join-Path $contractsDir 'CONTRACTS-GUIDE.md'
        Set-Content -Path $guidePath -Value $guideContent -Encoding utf8
        Write-Host "    Created .contracts/CONTRACTS-GUIDE.md" -ForegroundColor Green

        # Create registry.yaml if it doesn't exist
        $registryPath = Join-Path $contractsDir 'registry.yaml'
        if (-not (Test-Path $registryPath)) {
            $registryContent = @"
# Contracts Registry
# Maintained by the Contracts Skill. Run "init contracts" to populate.
contracts: []
"@
            Set-Content -Path $registryPath -Value $registryContent -Encoding utf8
            Write-Host "    Created .contracts/registry.yaml" -ForegroundColor Green
        }

        Write-Host ''
        Write-Host '    Tip: Commit .contracts/ to version control.' -ForegroundColor Gray
    }

    # Summary
    Write-Host ''
    $color = if ($successCount -eq $selected.Count) { 'Green' } else { 'Yellow' }
    Write-Host "  Done: $successCount/$($selected.Count) agents installed." -ForegroundColor $color
    Write-Host ''
    Write-Host '  Next: ask your AI "Initialize contracts for this project"' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
}

} @args
