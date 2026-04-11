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
    irm https://raw.githubusercontent.com/kombifyio/contract-skill/main/installers/install.ps1 | iex

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
$RepoName  = 'contract-skill'
$SkillName = 'contracts'

# --- Agent Configurations ---

$AgentConfigs = @(
    @{
        Name = 'GitHub Copilot'
        Id = 'copilot'
        Paths = @(
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".copilot\skills\$SkillName" })
        )
        DetectPaths = @(
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.copilot' }),
            $(if ($env:APPDATA)     { Join-Path $env:APPDATA 'Code\User\settings.json' })
        )
        InstructionFile = '.github\copilot-instructions.md'
        InstructionSnippet = @"

## Contracts System (MANDATORY)
Before any code changes: locate CONTRACT.md in target module, read spec + metadata, verify source_hash, summarize constraints briefly, then proceed.
"@
    },
    @{
        Name = 'Claude Code'
        Id = 'claude'
        Paths = @(
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".claude\skills\$SkillName" })
        )
        DetectPaths = @(
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.claude' }),
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
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".cursor\skills\$SkillName" })
        )
        DetectPaths = @(
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.cursor' }),
            $(if ($env:APPDATA)     { Join-Path $env:APPDATA 'Cursor' })
        )
        InstructionFile = '.cursor\rules\contracts-system.mdc'
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
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".codex\skills\$SkillName" })
        )
        DetectPaths = @(
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE '.codex' })
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
            (Join-Path (Get-Location) ".agent\skills\$SkillName")
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
    $zipPath = Join-Path $env:TEMP 'contracts-skill.zip'
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
$tempDir = Join-Path $env:TEMP ("contracts-skill-{0:yyyyMMddHHmmss}" -f (Get-Date))

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
                        Add-Content -Path $instrPath -Value $agent.InstructionSnippet
                        Write-Host "      -> Updated $($agent.InstructionFile)" -ForegroundColor Gray
                    }
                } else {
                    $dir = Split-Path $instrPath -Parent
                    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                    Set-Content -Path $instrPath -Value $agent.InstructionSnippet.Trim()
                    Write-Host "      -> Created $($agent.InstructionFile)" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host ' FAILED' -ForegroundColor Red
        }
    }

    # Install minimal-ui
    if (-not $NoUI) {
        $uiSource = Join-Path $skillSource 'ui\minimal-ui'
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
