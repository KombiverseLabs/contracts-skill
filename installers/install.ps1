<#
.SYNOPSIS
    Installs the Contracts skill by copying the skill folder to a target path.

.DESCRIPTION
    Standards-first installer for the Contracts skill. It does not detect IDEs,
    install the UI, or create .contracts project files. It can optionally write a
    compact instruction hook to AGENTS.md and legacy instruction files.

.PARAMETER TargetPath
    Explicit skill target directory. Defaults to $CODEX_HOME/skills/contracts,
    or ~/.codex/skills/contracts when CODEX_HOME is not set.

.PARAMETER Profiles
    Comma-separated compatibility profiles: codex, claude, copilot, cursor, local.

.PARAMETER Agents
    Legacy alias for -Profiles.

.PARAMETER Hooks
    Instruction hook mode: auto, base, beads, none. Auto selects beads when .beads exists.

.PARAMETER LegacyHooks
    Mirror the selected hook to CLAUDE.md, codex.md, Copilot, and Cursor files.
#>

& {
[CmdletBinding()]
param(
    [string]$TargetPath = $null,
    [string]$Profiles = $null,
    [string]$Agents = $null,
    [ValidateSet('auto', 'base', 'beads', 'none')]
    [string]$Hooks = 'auto',
    [switch]$LegacyHooks,
    [string]$GitBranch = 'main',
    [switch]$UseLocalSource,
    [switch]$Local,
    [string]$SkillSourcePath = $null,
    [string]$Source = $null,
    [switch]$Auto,
    [switch]$NoUI
)

$ErrorActionPreference = 'Stop'

$RepoOwner = 'kombifyio'
$RepoName = 'contracts-skill'
$SkillName = 'contracts'
$TempRoot = [System.IO.Path]::GetTempPath()
$HomeDir = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { [Environment]::GetFolderPath('UserProfile') }

function Get-DefaultTarget {
    if ($env:CODEX_HOME) {
        return (Join-Path $env:CODEX_HOME "skills\$SkillName")
    }
    return (Join-Path $HomeDir ".codex\skills\$SkillName")
}

function Get-ProfileTarget([string]$ProfileName) {
    switch ($ProfileName.ToLowerInvariant()) {
        'codex'   { return (Get-DefaultTarget) }
        'claude'  { return (Join-Path $HomeDir ".claude\skills\$SkillName") }
        'copilot' { return (Join-Path $HomeDir ".copilot\skills\$SkillName") }
        'cursor'  { return (Join-Path $HomeDir ".cursor\skills\$SkillName") }
        'local'   { return (Join-Path (Get-Location).Path ".agent\skills\$SkillName") }
        default   { throw "Unknown profile '$ProfileName'. Use codex, claude, copilot, cursor, or local." }
    }
}

function Get-InstallTarget {
    if ($TargetPath) {
        return @((Resolve-TargetPath $TargetPath))
    }

    $profileText = if ($Profiles) { $Profiles } elseif ($Agents) { $Agents } else { $null }
    if (-not $profileText) {
        return @((Get-DefaultTarget))
    }

    $targets = @()
    $seen = @{}
    foreach ($raw in ($profileText -split ',')) {
        $profileName = $raw.Trim()
        if (-not $profileName) { continue }
        $target = Get-ProfileTarget $profileName
        $key = $target.ToLowerInvariant()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $targets += $target
        }
    }
    if ($targets.Count -eq 0) { throw 'No valid install profiles were provided.' }
    return $targets
}

function Resolve-TargetPath([string]$PathText) {
    if ([System.IO.Path]::IsPathRooted($PathText)) {
        return [System.IO.Path]::GetFullPath($PathText)
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $PathText))
}

function Get-SkillSource([string]$TempDir) {
    $explicitSource = if ($SkillSourcePath) { $SkillSourcePath } elseif ($Source) { $Source } else { $null }
    if ($explicitSource) {
        $resolved = (Resolve-Path $explicitSource).Path
        if (-not (Test-Path (Join-Path $resolved 'SKILL.md'))) {
            throw "Skill source does not contain SKILL.md: $resolved"
        }
        return $resolved
    }

    if ($UseLocalSource -or $Local) {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $localSkill = Join-Path $repoRoot 'skill'
        if (-not (Test-Path (Join-Path $localSkill 'SKILL.md'))) {
            throw "Local skill folder not found: $localSkill"
        }
        return $localSkill
    }

    Write-Host 'Downloading Contracts skill...' -ForegroundColor Cyan
    if (Get-Command git -ErrorAction SilentlyContinue) {
        git clone --quiet --depth 1 --branch $GitBranch "https://github.com/$RepoOwner/$RepoName.git" $TempDir 2>$null
        if ($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $TempDir 'skill\SKILL.md'))) {
            return (Join-Path $TempDir 'skill')
        }
    }

    $zipPath = Join-Path $TempRoot 'contracts-skill.zip'
    $zipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$GitBranch.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
    Expand-Archive -Path $zipPath -DestinationPath $TempDir -Force
    Remove-Item $zipPath -ErrorAction SilentlyContinue
    $extracted = Get-ChildItem $TempDir -Directory | Select-Object -First 1
    $skillDir = Join-Path $extracted.FullName 'skill'
    if (-not (Test-Path (Join-Path $skillDir 'SKILL.md'))) {
        throw "Downloaded archive does not contain skill/SKILL.md"
    }
    return $skillDir
}

function Copy-Skill([string]$SourceDir, [string]$TargetDir) {
    $parent = Split-Path $TargetDir -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path $TargetDir) {
        Remove-Item -LiteralPath $TargetDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Copy-Item -Path (Join-Path $SourceDir '*') -Destination $TargetDir -Recurse -Force
    if (-not (Test-Path (Join-Path $TargetDir 'SKILL.md'))) {
        throw "Install failed: SKILL.md missing at $TargetDir"
    }
}

function Get-HookMode {
    if ($Hooks -eq 'auto') {
        if (Test-Path (Join-Path (Get-Location).Path '.beads')) { return 'beads' }
        return 'base'
    }
    return $Hooks
}

function Set-ContractsHook([string]$FilePath, [string]$HookText) {
    $start = '<!-- contracts-skill:start -->'
    $end = '<!-- contracts-skill:end -->'
    $block = "$start`n$HookText`n$end"

    $dir = Split-Path $FilePath -Parent
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        $pattern = [regex]::Escape($start) + '[\s\S]*?' + [regex]::Escape($end)
        if ($content -match $pattern) {
            $content = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block }, 1)
        } else {
            $content = $content.TrimEnd() + "`n`n$block`n"
        }
    } else {
        $content = "$block`n"
    }

    Set-Content -Path $FilePath -Value $content -Encoding utf8
}

function Install-Hook([string]$SkillSource) {
    $mode = Get-HookMode
    if ($mode -eq 'none') { return }

    $template = Join-Path $SkillSource "references\instruction-hooks\$mode.md"
    if (-not (Test-Path $template)) {
        throw "Hook template not found: $template"
    }
    $hookText = (Get-Content $template -Raw).Trim()

    $projectRoot = (Get-Location).Path
    Set-ContractsHook -FilePath (Join-Path $projectRoot 'AGENTS.md') -HookText $hookText

    if ($LegacyHooks) {
        $legacyFiles = @(
            'CLAUDE.md',
            'codex.md',
            '.github\copilot-instructions.md',
            '.cursor\rules\contracts-system.mdc'
        )
        foreach ($file in $legacyFiles) {
            Set-ContractsHook -FilePath (Join-Path $projectRoot $file) -HookText $hookText
        }
    }

    Write-Host "Installed $mode contract hook -> AGENTS.md" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Contracts Skill Installer' -ForegroundColor Cyan
Write-Host ''

if ($Auto) {
    Write-Host 'Note: -Auto is accepted for compatibility and no longer changes target selection.' -ForegroundColor DarkGray
}
if ($NoUI) {
    Write-Host 'Note: -NoUI is accepted for compatibility; UI is not installed by this installer.' -ForegroundColor DarkGray
}

$tempDir = Join-Path $TempRoot ("contracts-skill-{0:yyyyMMddHHmmssfff}" -f (Get-Date))

try {
    $skillSource = Get-SkillSource -TempDir $tempDir
    $targets = Get-InstallTarget

    foreach ($target in $targets) {
        Copy-Skill -SourceDir $skillSource -TargetDir $target
        Write-Host "Installed Contracts skill -> $target" -ForegroundColor Green
    }

    Install-Hook -SkillSource $skillSource

    Write-Host ''
    Write-Host 'Done. Say "init contracts" to set up contracts for a project.' -ForegroundColor Yellow
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

} @args
