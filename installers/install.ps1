<#
.SYNOPSIS
    One-liner installer for the Contracts skill with agent selection.

.DESCRIPTION
    Installs the Contracts skill to detected AI coding assistants.
    Supports GitHub Copilot, Claude Code, Cursor, Windsurf, Aider, Cline, and project-local installation.

.PARAMETER Scope
    Installation scope: 'project' (default) or 'global'

.PARAMETER Agents
    Comma-separated list of agents to install to (e.g., "copilot,claude,cursor")
    If not specified, will detect and prompt for selection

.PARAMETER Auto
    Install to all detected agents without prompting

.PARAMETER Init
    Run initialization after installation

.PARAMETER GitBranch
    Git branch to install from (default: main)

.EXAMPLE
    # Install to project with interactive agent selection
    .\install.ps1

.EXAMPLE
    # Install to specific agents
    .\install.ps1 -Agents "copilot,claude"

.EXAMPLE
    # Auto-install to all detected agents
    .\install.ps1 -Auto

.EXAMPLE
    # One-liner via Invoke-Expression
    irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex
#>

& {
[CmdletBinding()]
param(
    [ValidateSet('project','global')]
    [string]$Scope = 'project',
    
    [string]$Agents = $null,
    
    [switch]$Auto,
    
    [switch]$Init,

    [ValidateSet('minimal-ui','php-ui','none')]
    [Alias('UI')]
    [string]$UiMode = $null,

    [switch]$InstallUI,

    [switch]$ForceUI,

    [switch]$SkipUI,

    [switch]$UpdateInstructions,

    [switch]$SkipInstructions,

    [switch]$UpdateAgentMd,

    [switch]$SkipAgentMd,

    [ValidateSet('ask','on','off','once')]
    [string]$UIAutoStart = 'ask',

    [switch]$StartUI,
    
    [string]$GitBranch = 'main',

    # Testing / offline support
    [switch]$UseLocalSource,

    # If provided, must point to the skill folder (the one containing SKILL.md)
    [string]$SkillSourcePath = $null
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = (Get-Location).Path

# Configuration
$RepoOwner = 'KombiverseLabs'
$RepoName  = 'contracts-skill'
$SkillName = 'contracts'

# Colors
function Write-Color {
    param(
        [string]$Text,
        [string]$Color = 'White'
    )
    $colorMap = @{
        'Red' = 'Red'
        'Green' = 'Green'
        'Yellow' = 'Yellow'
        'Cyan' = 'Cyan'
        'Gray' = 'Gray'
        'White' = 'White'
    }
    Write-Host $Text -ForegroundColor $colorMap[$Color]
}

function Write-Header {
    Write-Host ''
    Write-Color '========================================' 'Cyan'
    Write-Color ' Contracts Skill Installer' 'Cyan'
    Write-Color ' Spec-Driven Development for AI Assistants' 'Cyan'
    Write-Color '========================================' 'Cyan'
    Write-Host ''
}

# Beads integration detection and setup
function Test-BeadsInstalled {
    param([string]$ProjectPath = '.')
    
    # Check for .beads directory (beads is initialized in project)
    $beadsDir = Join-Path $ProjectPath '.beads'
    if (Test-Path $beadsDir) {
        return @{ Installed = $true; Path = $beadsDir; HasCli = $null -ne (Get-Command bd -ErrorAction SilentlyContinue) }
    }
    
    # Check if bd CLI is available globally
    $bdCmd = Get-Command bd -ErrorAction SilentlyContinue
    if ($bdCmd) {
        return @{ Installed = $false; Path = $null; HasCli = $true }
    }
    
    return @{ Installed = $false; Path = $null; HasCli = $false }
}

function Initialize-BeadsContractsIntegration {
    param([string]$ProjectPath = '.')
    
    $bdCmd = Get-Command bd -ErrorAction SilentlyContinue
    if (-not $bdCmd) {
        Write-Color '    Beads CLI (bd) not found in PATH - skipping task creation' 'Yellow'
        return $false
    }
    
    try {
        # Check if preflight task already exists
        $existingTasks = & bd list --json 2>$null | ConvertFrom-Json
        $hasPreflight = $existingTasks | Where-Object { $_.title -match 'CONTRACT|contract preflight' }
        
        if ($hasPreflight) {
            Write-Color '    Beads contract preflight task already exists' 'Gray'
            return $true
        }
        
        # Create the preflight task template
        Write-Color '    Creating Beads contract preflight task...' 'Cyan'
        $taskId = & bd create "PREFLIGHT: Check CONTRACT.md before code changes" -p 0 --json 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty id
        
        if ($taskId) {
            & bd update $taskId --design "Before implementing ANY feature or fix:
1. Identify affected module(s) by path
2. Read MODULE/CONTRACT.md (user-owned spec)
3. Read MODULE/CONTRACT.yaml and verify source_hash matches
4. Summarize MUST/MUST NOT constraints (max 5 sentences)
5. If drift detected, sync YAML before proceeding

This task should be a dependency for all feature work." 2>$null | Out-Null
            
            Write-Color "    Created preflight task: $taskId" 'Green'
            return $true
        }
    } catch {
        Write-Color "    Warning: Could not create Beads task ($_)" 'Yellow'
    }
    
    return $false
}

# Agent configurations
$AgentConfigs = @(
    @{
        Name = 'GitHub Copilot (VS Code)'
        Id = 'copilot'
        Icon = '[COP]'
        Paths = @(
            $(
                if ($Scope -eq 'global') {
                    Join-Path $env:USERPROFILE ".copilot\skills\$SkillName"
                } else {
                    Join-Path $ProjectRoot ".github\skills\$SkillName"
                }
            )
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE '.copilot'),
            (Join-Path $env:APPDATA 'Code\User\settings.json')
        )
        InstructionFile = '.github\copilot-instructions.md'
        InstructionSnippet = @"

## Contracts System (MANDATORY)
**STOP before any code changes.** This is not optional.

1. LOCATE: Find CONTRACT.md in the target module directory (walk up if needed)
2. READ: Load CONTRACT.md (spec) + CONTRACT.yaml (metadata)
3. VERIFY: Check source_hash in YAML matches current CONTRACT.md hash
   - If mismatch → STOP → Sync YAML first → Then continue
4. SUMMARIZE: Tell user the MUST / MUST NOT constraints (max 5 sentences)
5. PROCEED: Only after steps 1-4 are done, begin implementation

CONTRACT.md is USER-OWNED. Never edit it directly.
For new modules: ask user if they want a contract, then use init-agent --module.
"@
    },
    @{
        Name = 'Claude Code'
        Id = 'claude'
        Icon = '[CLD]'
        Paths = @(
            (Join-Path $env:USERPROFILE ".claude\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE '.claude'),
            (Join-Path $env:APPDATA 'Claude')
        )
        InstructionFile = 'CLAUDE.md'
        InstructionSnippet = @"

## Contracts System
    Before any code changes, determine the target module(s) and locate the nearest CONTRACT.md.
    Read CONTRACT.md + CONTRACT.yaml and check drift (source_hash vs current hash); if drift exists, sync YAML first.
    Before editing, give the user a very short “Contract Notes” summary of MUST / MUST NOT constraints (max 5 sentences).
    CONTRACT.md is user-owned (never edit directly).
    When creating a new module, propose generating a matching contract via init-agent (--module).
"@
    },
    @{
        Name = 'Cursor'
        Id = 'cursor'
        Icon = '[CUR]'
        Paths = @(
            (Join-Path $env:USERPROFILE ".cursor\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE '.cursor'),
            (Join-Path $env:APPDATA 'Cursor')
        )
        InstructionFile = '.cursor\rules\contracts-system.mdc'
        InstructionSnippet = @"
---
description: "Contracts System preflight - MANDATORY before code changes"
alwaysApply: true
---

# Contracts System (MANDATORY)
**STOP before any code changes.** This is not optional.

1. LOCATE: Find CONTRACT.md in target module (walk up directories if needed)
2. READ: Load CONTRACT.md + CONTRACT.yaml
3. VERIFY: source_hash must match → if mismatch, sync YAML first
4. SUMMARIZE: Tell user MUST / MUST NOT constraints (max 5 sentences)
5. PROCEED: Only then begin implementation

CONTRACT.md is USER-OWNED → never edit directly.
"@
    },
    @{
        Name = 'Windsurf (Codeium)'
        Id = 'windsurf'
        Icon = '[WND]'
        Paths = @(
            (Join-Path $env:USERPROFILE ".windsurf\skills\$SkillName"),
            (Join-Path $env:USERPROFILE ".codeium\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE '.windsurf'),
            (Join-Path $env:USERPROFILE '.codeium'),
            (Join-Path $env:APPDATA 'Windsurf')
        )
        InstructionFile = '.windsurf\rules\01-contracts-system.md'
        InstructionSnippet = @"

# Contracts System (MANDATORY)
**STOP before any code changes.** This is not optional.

1. LOCATE: Find CONTRACT.md in target module (walk up directories if needed)
2. READ: Load CONTRACT.md + CONTRACT.yaml
3. VERIFY: source_hash must match → if mismatch, sync YAML first
4. SUMMARIZE: Tell user MUST / MUST NOT constraints (max 5 sentences)
5. PROCEED: Only then begin implementation

CONTRACT.md is USER-OWNED → never edit directly.
"@
    },
    @{
        Name = 'Aider'
        Id = 'aider'
        Icon = '[AID]'
        Paths = @(
            (Join-Path $env:USERPROFILE ".aider\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE '.aider'),
            (Join-Path $env:USERPROFILE '.aider.conf.yml')
        )
        InstructionFile = $null
        InstructionSnippet = $null
    },
    @{
        Name = 'Cline (VS Code)'
        Id = 'cline'
        Icon = '[CLN]'
        Paths = @(
            (Join-Path $env:USERPROFILE ".cline\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE '.cline'),
            (Join-Path $env:APPDATA 'Code\User\globalStorage\saoudrizwan.claude-dev')
        )
        InstructionFile = '.clinerules\01-contracts-system.md'
        InstructionSnippet = @"

# Contracts System (MANDATORY)
**STOP before any code changes.** This is not optional.

1. LOCATE: Find CONTRACT.md in target module (walk up directories if needed)
2. READ: Load CONTRACT.md + CONTRACT.yaml
3. VERIFY: source_hash must match → if mismatch, sync YAML first
4. SUMMARIZE: Tell user MUST / MUST NOT constraints (max 5 sentences)
5. PROCEED: Only then begin implementation

CONTRACT.md is USER-OWNED → never edit directly.
"@
    },
    @{
        Name = 'OpenCode'
        Id = 'opencode'
        Icon = '[OPN]'
        Paths = @(
            (Join-Path $env:USERPROFILE ".opencode\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE '.opencode'),
            (Join-Path $env:APPDATA 'OpenCode')
        )
        InstructionFile = '.opencodesettings'
        InstructionSnippet = @"

# Contracts System (MANDATORY)
**STOP before any code changes.** This is not optional.

1. LOCATE: Find CONTRACT.md in target module (walk up directories if needed)
2. READ: Load CONTRACT.md + CONTRACT.yaml
3. VERIFY: source_hash must match → if mismatch, sync YAML first
4. SUMMARIZE: Tell user MUST / MUST NOT constraints (max 5 sentences)
5. PROCEED: Only then begin implementation

CONTRACT.md is USER-OWNED → never edit directly.
"@
    },
    @{
        Name = 'Custom Target Path'
        Id = 'custom'
        Icon = '[CST]'
        Paths = @()
        DetectPaths = @()
        InstructionFile = $null
        InstructionSnippet = $null
        AlwaysOffer = $false
    },
    @{
        Name = 'Project Local (.agent)'
        Id = 'local'
        Icon = '[LOC]'
        Paths = @(
            (Join-Path (Get-Location) ".agent\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path (Get-Location) '.agent'),
            (Join-Path (Get-Location) 'package.json'),
            (Join-Path (Get-Location) '.git')
        )
        InstructionFile = $null
        InstructionSnippet = $null
        AlwaysOffer = $true
    }
)

function Test-HostInteractive {
    try {
        # Multiple checks for interactive capability
        if (-not $Host -or -not $Host.UI -or -not $Host.UI.RawUI) { return $false }
        
        # Check if stdin is redirected (piped input)
        $stdin = [Console]::OpenStandardInput()
        if ($null -eq $stdin) { return $false }
        
        # Try to check if keyboard is available
        try {
            $null = [Console]::KeyAvailable
        } catch {
            return $false
        }
        
        # Check if we're in an actual interactive terminal
        if ($Host.Name -match 'ServerRemoteHost') { return $false }
        
        return $true
    } catch { 
        return $false 
    }
}

function Select-AgentsCheckbox {
    param(
        [array]$AllAgents,
        [hashtable]$DetectedById,
        [hashtable]$InstalledById
    )

    # Fallback to old-style prompt if RawUI is not available
    if (-not (Test-HostInteractive)) {
        Write-Color 'Interactive checkbox UI not available in this host.' 'Yellow'
        Write-Color 'Enter selection as comma-separated ids (e.g., copilot,claude,local) or "all":' 'Gray'
        $raw = Read-Host 'Agents'
        if ($raw -match '^(all|a)$') {
            return $AllAgents
        }
        $ids = $raw -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
        return @($AllAgents | Where-Object { $ids -contains $_.Id })
    }

    $selected = @{}
    foreach ($agent in $AllAgents) {
        $selected[$agent.Id] = ($DetectedById.ContainsKey($agent.Id) -and $DetectedById[$agent.Id])
    }

    $cursor = 0
    $startTop = [Console]::CursorTop

    function Render {
        [Console]::SetCursorPosition(0, $startTop)
        Write-Host ''
        Write-Color 'Select agents to install to (Space=toggle, Enter=confirm, Q=quit):' 'White'
        Write-Color 'Detected agents are preselected; you can also pick non-detected.' 'Gray'
        Write-Host ''

        for ($i = 0; $i -lt $AllAgents.Count; $i++) {
            $agent = $AllAgents[$i]
            $isOn = $selected[$agent.Id]
            $box = if ($isOn) { '[*]' } else { '[ ]' }
            $status = if ($InstalledById.ContainsKey($agent.Id) -and $InstalledById[$agent.Id]) {
                'INSTALLED'
            } elseif ($DetectedById.ContainsKey($agent.Id) -and $DetectedById[$agent.Id]) {
                'DETECTED'
            } else {
                'NOT FOUND'
            }

            $prefix = if ($i -eq $cursor) { '>' } else { ' ' }
            $name = "$($agent.Icon) $($agent.Name)"
            $hint = switch ($agent.Id) {
                'custom' { ' -> prompts for target path' }
                default {
                    try {
                        $p = Get-PreferredInstallPath -Agent $agent
                        " -> $p"
                    } catch { '' }
                }
            }

            $line = " $prefix $box $name [$status]$hint"
            $color = if ($i -eq $cursor) { 'Cyan' } elseif ($status -eq 'DETECTED') { 'Yellow' } elseif ($status -eq 'INSTALLED') { 'Green' } else { 'Gray' }
            Write-Color $line $color
        }
        Write-Host ''
        Write-Color 'Tips: A=toggle all, D=toggle detected only, I=toggle installed only' 'Gray'
    }

    Render

    $timeout = 300 # 5 minutes
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $confirmed = $false
    
    while (-not $confirmed) {
        # Check for timeout
        if ($timer.Elapsed.TotalSeconds -gt $timeout) {
            Write-Color "`nTimeout waiting for input. Falling back to text mode." 'Yellow'
            Write-Color 'Enter selection as comma-separated ids (e.g., copilot,claude,local) or "all":' 'Gray'
            $raw = Read-Host 'Agents'
            if ($raw -match '^(all|a)$') {
                return $AllAgents
            }
            $ids = $raw -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
            return @($AllAgents | Where-Object { $ids -contains $_.Id })
        }

        # Try to read a key with timeout
        try {
            if (-not $Host.UI.RawUI.KeyAvailable) {
                Start-Sleep -Milliseconds 100
                continue
            }
            $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        } catch {
            # If ReadKey fails, fall back to text mode
            Write-Color "`nInteractive mode failed. Using text mode." 'Yellow'
            Write-Color 'Enter selection as comma-separated ids (e.g., copilot,claude,local) or "all":' 'Gray'
            $raw = Read-Host 'Agents'
            if ($raw -match '^(all|a)$') {
                return $AllAgents
            }
            $ids = $raw -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
            return @($AllAgents | Where-Object { $ids -contains $_.Id })
        }
        
        switch ($key.VirtualKeyCode) {
            38 { if ($cursor -gt 0) { $cursor-- } Render } # Up
            40 { if ($cursor -lt ($AllAgents.Count - 1)) { $cursor++ } Render } # Down
            32 {
                $agent = $AllAgents[$cursor]
                $selected[$agent.Id] = -not $selected[$agent.Id]
                Render
            }
            65 {
                # A
                $anyOff = $false
                foreach ($agent in $AllAgents) {
                    if (-not $selected[$agent.Id]) { $anyOff = $true; break }
                }
                foreach ($agent in $AllAgents) { $selected[$agent.Id] = $anyOff }
                Render
            }
            68 {
                # D
                foreach ($agent in $AllAgents) {
                    if ($DetectedById.ContainsKey($agent.Id) -and $DetectedById[$agent.Id]) {
                        $selected[$agent.Id] = -not $selected[$agent.Id]
                    }
                }
                Render
            }
            73 {
                # I
                foreach ($agent in $AllAgents) {
                    if ($InstalledById.ContainsKey($agent.Id) -and $InstalledById[$agent.Id]) {
                        $selected[$agent.Id] = -not $selected[$agent.Id]
                    }
                }
                Render
            }
            13 {
                # Enter
                $confirmed = $true
            }
            81 {
                # Q
                return @()
            }
        }
    }

    return @($AllAgents | Where-Object { $selected[$_.Id] })
}

function Update-AgentMarkdown {
    param(
        [string]$ProjectPath
    )

    $agentMdPath = Join-Path $ProjectPath 'agent.md'
    $snippet = @"

## Contracts System
When creating a new module, ask whether to create a matching CONTRACT.md/CONTRACT.yaml using the contracts init tool (e.g., `node .github/skills/contracts/ai/init-agent/index.js --module ./path/to/module --yes`).
"@

    if (Test-Path $agentMdPath) {
        $content = Get-Content $agentMdPath -Raw
        if ($content -notmatch '##\s+Contracts System') {
            Add-Content -Path $agentMdPath -Value $snippet
            Write-Color '    -> Updated agent.md' 'Gray'
        }
    } else {
        Set-Content -Path $agentMdPath -Value ($snippet.Trim())
        Write-Color '    -> Created agent.md' 'Gray'
    }
}

function Test-AgentInstalled {
    param($Agent)
    
    foreach ($path in $Agent.DetectPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

function Test-SkillInstalled {
    param($Agent)
    
    foreach ($path in $Agent.Paths) {
        $skillFile = Join-Path $path 'SKILL.md'
        if (Test-Path $skillFile) {
            return $path
        }
    }
    return $null
}

function Get-PreferredInstallPath {
    param($Agent)
    
    foreach ($path in $Agent.Paths) {
        $parent = Split-Path $path -Parent
        if ((Test-Path $parent) -or $Agent.AlwaysOffer) {
            return $path
        }
    }
    return $Agent.Paths[0]
}

function Install-SkillToAgent {
    param(
        [string]$TargetPath,
        [string]$SourcePath,
        [hashtable]$Agent
    )
    
    $parent = Split-Path $TargetPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    
    if (Test-Path $TargetPath) {
        Remove-Item -Recurse -Force $TargetPath
    }
    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
    
    return (Test-Path (Join-Path $TargetPath 'SKILL.md'))
}

function Add-InstructionHook {
    param(
        [hashtable]$Agent,
        [string]$ProjectPath
    )
    
    if (-not $Agent.InstructionFile -or -not $Agent.InstructionSnippet) {
        return
    }
    
    $instructionPath = Join-Path $ProjectPath $Agent.InstructionFile
    
    if (Test-Path $instructionPath) {
        $content = Get-Content $instructionPath -Raw
        if ($content -notmatch 'Contracts System') {
            Add-Content -Path $instructionPath -Value $Agent.InstructionSnippet
            Write-Color "    -> Added hook to $($Agent.InstructionFile)" 'Gray'
            return
        }

        # If a Contracts section already exists, ensure the "new module -> propose contract" note exists.
        if ($content -notmatch 'When (creating|adding) a new module') {
            $lines = $Agent.InstructionSnippet -split "`r?`n" | Where-Object { $_ -match 'When (creating|adding) a new module' }
            if ($lines -and $lines.Count -gt 0) {
                Add-Content -Path $instructionPath -Value ("`n" + ($lines -join "`n") + "`n")
                Write-Color "    -> Updated $($Agent.InstructionFile)" 'Gray'
            }
        }
    } else {
        $dir = Split-Path $instructionPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Set-Content -Path $instructionPath -Value $Agent.InstructionSnippet.Trim()
        Write-Color "    -> Created $($Agent.InstructionFile)" 'Gray'
    }
}

function Get-SkillSource {
    param([string]$TempDir)
    
    Write-Color 'Downloading skill from GitHub...' 'Yellow'
    
    # Try git clone first
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            git clone --quiet --depth 1 --branch $GitBranch "https://github.com/$RepoOwner/$RepoName.git" $TempDir 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path $TempDir)) {
                Write-Color 'Downloaded via git' 'Green'
                return Join-Path $TempDir 'skill'
            }
        }
        catch {
            Write-Color "Git clone failed, trying ZIP fallback..." 'Yellow'
        }
    }
    
    # Fallback to ZIP
    Write-Color 'Downloading ZIP archive...' 'Yellow'
    $zipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$GitBranch.zip"
    $zipPath = Join-Path $env:TEMP 'contracts-skill.zip'
    
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $TempDir -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue
        
        $extractedFolder = Get-ChildItem $TempDir -Directory | Select-Object -First 1
        if (-not $extractedFolder) {
            throw "ZIP extraction failed - no directory found in $TempDir"
        }
        Write-Color 'Downloaded via ZIP' 'Green'
        
        return Join-Path $extractedFolder.FullName 'skill'
    }
    catch {
        throw "Failed to download skill from GitHub: $_"
    }
}

function Install-ContractsUI {
    param(
        [string]$SkillSource,
        [string]$ProjectPath,
        [ValidateSet('minimal-ui','php-ui')]
        [string]$UI,
        [switch]$Force
    )

    function Test-IsContractsSkillRepo {
        param([string]$Path)
        return (Test-Path (Join-Path $Path 'skill\SKILL.md')) -and (Test-Path (Join-Path $Path 'installers\install.ps1')) -and (Test-Path (Join-Path $Path 'setup.ps1'))
    }

    $relative = if ($UI -eq 'php-ui') { 'ui\\contracts-ui' } else { 'ui\\minimal-ui' }
    $uiSource = Join-Path $SkillSource $relative
    if (-not (Test-Path $uiSource)) {
        Write-Color "Contracts UI not found in downloaded skill ($relative)." 'Yellow'
        return $false
    }

    $target = Join-Path $ProjectPath 'contracts-ui'

    if ((Test-IsContractsSkillRepo -Path $ProjectPath) -and -not $Force) {
        Write-Color "Refusing to install Contracts UI into the contracts-skill repository itself ($ProjectPath)." 'Yellow'
        Write-Color "Run the installer from your project folder, or use -ForceUI to override." 'Gray'
        return $false
    }

    if ((Test-Path $target) -and -not $Force) {
        Write-Color "Contracts UI already exists at: $target (use -ForceUI to overwrite)" 'Yellow'
        return $false
    }

    if (Test-Path $target) {
        Remove-Item -Recurse -Force $target
    }
    Copy-Item -Path $uiSource -Destination $target -Recurse -Force

    function Write-ContractsBundle {
        param(
            [string]$ProjectRoot,
            [string]$UiDir
        )

        function Get-Sha256Text([string]$Text) {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Text)
                $hash = $sha.ComputeHash($bytes)
                return -join ($hash | ForEach-Object { $_.ToString('x2') })
            }
            finally {
                $sha.Dispose()
            }
        }

        function Get-RelPath([string]$Base, [string]$Full) {
            $b = (Resolve-Path $Base).Path
            $f = (Resolve-Path $Full).Path
            if ($f.Length -le $b.Length) { return '' }
            return ($f.Substring($b.Length).TrimStart('\\','/') -replace '\\','/')
        }

        function Get-YamlSourceHash([string]$YamlText) {
            $m = [regex]::Match($YamlText, '^\s*source_hash\s*:\s*("?)([^"\r\n#]+)\1\s*(?:#.*)?$', 'IgnoreCase,Multiline')
            if ($m.Success) { return $m.Groups[2].Value.Trim() }
            return $null
        }

        $root = (Resolve-Path $ProjectRoot).Path
        $ignore = @('.git','node_modules','vendor','.idea','.vscode','.agent','dist','build','out','.next','coverage','contracts-ui')

        $mdFiles = Get-ChildItem -Path $root -Recurse -Filter 'CONTRACT.md' -File -ErrorAction SilentlyContinue |
            Where-Object { $ignore -notcontains $_.Directory.Name }
        $yamlFiles = Get-ChildItem -Path $root -Recurse -Filter 'CONTRACT.yaml' -File -ErrorAction SilentlyContinue |
            Where-Object { $ignore -notcontains $_.Directory.Name }

        $map = @{}
        foreach ($f in $mdFiles) {
            $dir = Get-RelPath $root $f.Directory.FullName
            if ($dir -eq '') { $dir = '.' }
            if (-not $map.ContainsKey($dir)) { $map[$dir] = @{ dir = $dir } }
            $map[$dir].md_path = Get-RelPath $root $f.FullName
            $map[$dir].md_text = Get-Content $f.FullName -Raw
            $map[$dir].md_hash = (Get-Sha256Text $map[$dir].md_text)
        }
        foreach ($f in $yamlFiles) {
            $dir = Get-RelPath $root $f.Directory.FullName
            if ($dir -eq '') { $dir = '.' }
            if (-not $map.ContainsKey($dir)) { $map[$dir] = @{ dir = $dir } }
            $map[$dir].yaml_path = Get-RelPath $root $f.FullName
            $map[$dir].yaml_text = Get-Content $f.FullName -Raw
            $map[$dir].yaml_source_hash = Get-YamlSourceHash $map[$dir].yaml_text
        }

        $contracts = @($map.Values | Sort-Object dir)
        $bundle = [ordered]@{
            generated_at = (Get-Date).ToUniversalTime().ToString('o')
            project_root  = '.'
            contracts     = $contracts
        }
        $json = $bundle | ConvertTo-Json -Depth 6
        $js = "window.__CONTRACTS_BUNDLE__ = $json;"
        Set-Content -Path (Join-Path $UiDir 'contracts-bundle.js') -Value $js -Encoding UTF8
    }

    $index = Join-Path $target 'index.php'
    $html = Join-Path $target 'index.html'
    if ($UI -eq 'php-ui') {
        if (Test-Path $index) {
            Write-Color "Installed Contracts UI (php-ui) -> $target" 'Green'
            Write-Color 'Run: php -S localhost:8080 -t contracts-ui' 'Gray'
            return $true
        }
        Write-Color 'Contracts UI installation failed (missing index.php).' 'Red'
        return $false
    }

    if (Test-Path $html) {
        try { Write-ContractsBundle -ProjectRoot $ProjectPath -UiDir $target } catch { Write-Color "Warning: failed to generate contracts-bundle.js ($_ )" 'Yellow' }

        # Default config (best-effort)
        try {
            $cfgPath = Join-Path $target 'contracts-ui.config.json'
            if (-not (Test-Path $cfgPath)) {
                $cfg = [ordered]@{ autoStart = $false; port = 8787; openBrowser = $true; projectRoot = '.' } | ConvertTo-Json -Depth 4
                Set-Content -Path $cfgPath -Value $cfg -Encoding UTF8
            }
        } catch { }

        Write-Color "Installed Contracts UI (minimal-ui) -> $target" 'Green'
        Write-Color 'Start (recommended): ./contracts-ui/start.ps1  (or start.sh)' 'Gray'
        Write-Color 'Open (snapshot, read-only): contracts-ui/index.html' 'Gray'
        return $true
    }

    Write-Color 'Contracts UI installation failed (missing index.html).' 'Red'
    return $false
}

# Main installation flow
Write-Header

# Detect agents
Write-Color 'Scanning for AI coding assistants...' 'Cyan'
Write-Host ''

$detectedAgents = @()
$installedAgents = @()

$detectedById = @{}
$installedById = @{}

foreach ($agent in $AgentConfigs) {
    $isInstalled = Test-AgentInstalled -Agent $agent
    $existingPath = Test-SkillInstalled -Agent $agent

    if ($agent.Id -eq 'custom') {
        Write-Color "  $($agent.Icon) $($agent.Name): [OPTION]" 'Gray'
        continue
    }
    
    $status = if ($existingPath) {
        $installedAgents += @{ Agent = $agent; Path = $existingPath }
        $installedById[$agent.Id] = $true
        '[INSTALLED]'
    } elseif ($isInstalled -or $agent.AlwaysOffer) {
        if ($isInstalled -or $agent.AlwaysOffer) {
            $detectedAgents += $agent
            $detectedById[$agent.Id] = $true
        }
        '[DETECTED]'
    } else {
        '[NOT FOUND]'
    }
    
    $color = switch ($status) {
        '[INSTALLED]' { 'Green' }
        '[DETECTED]' { 'Yellow' }
        default { 'Gray' }
    }
    
    Write-Color "  $($agent.Icon) $($agent.Name): $status" $color
}

Write-Host ''

# Show already installed
if ($installedAgents.Count -gt 0) {
    Write-Color 'Already installed:' 'Green'
    foreach ($item in $installedAgents) {
        Write-Color "  v $($item.Agent.Name) -> $($item.Path)" 'Gray'
    }
    Write-Host ''
}

# Determine which agents to install to
$selectedAgents = @()

# Offer all known agents (plus Custom) in interactive mode so users can install even if not detected
$allOfferAgents = @($AgentConfigs | Where-Object { $_.Id -ne $null })

# If -Agents parameter specified
if ($Agents) {
    $agentIds = $Agents -split ',' | ForEach-Object { $_.Trim().ToLower() }
    foreach ($agent in $detectedAgents) {
        if ($agentIds -contains $agent.Id) {
            $selectedAgents += @{ Agent = $agent; Path = (Get-PreferredInstallPath -Agent $agent) }
        }
    }
}
# If -Auto specified
elseif ($Auto) {
    foreach ($agent in $detectedAgents) {
        $selectedAgents += @{ Agent = $agent; Path = (Get-PreferredInstallPath -Agent $agent) }
    }
}
# Interactive selection
else {
    $chosenAgents = Select-AgentsCheckbox -AllAgents $allOfferAgents -DetectedById $detectedById -InstalledById $installedById
    if ($chosenAgents.Count -eq 0) {
        Write-Color 'No agents selected.' 'Yellow'
        return
    }

    foreach ($agent in $chosenAgents) {
        if ($agent.Id -eq 'custom') {
            $raw = Read-Host 'Enter custom target directory for the skill (e.g., C:\path\to\skills\contracts)'
            if (-not $raw) { continue }
            $p = $raw.Trim()
            if (-not (Split-Path $p -Leaf)) { continue }
            $selectedAgents += @{ Agent = $agent; Path = $p }
        } else {
            $selectedAgents += @{ Agent = $agent; Path = (Get-PreferredInstallPath -Agent $agent) }
        }
    }
}

if ($selectedAgents.Count -eq 0) {
    Write-Color 'No agents selected.' 'Yellow'
    return
}

Write-Host ''
Write-Color "Installing to $($selectedAgents.Count) agent(s)..." 'Cyan'

    # Download skill once (or use local source)
    $tempDir = Join-Path $env:TEMP ("contracts-skill-{0:yyyyMMddHHmmss}" -f (Get-Date))

try {
    $skillSource = $null

    if ($SkillSourcePath) {
        $skillSource = (Resolve-Path $SkillSourcePath).Path
        Write-Color "Using skill source: $skillSource" 'Gray'
    }
    elseif ($UseLocalSource) {
        # installers/ -> repo root -> skill/
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $local = Join-Path $repoRoot 'skill'
        if (-not (Test-Path $local)) {
            throw "UseLocalSource was specified but local skill folder not found at: $local"
        }
        $skillSource = (Resolve-Path $local).Path
        Write-Color "Using local repo skill source: $skillSource" 'Gray'
    }
    else {
        $skillSource = Get-SkillSource -TempDir $tempDir
    }
    
    if (-not (Test-Path $skillSource)) {
        throw "Skill source not found at: $skillSource"
    }
    
    Write-Host ''
    
    # Install to each selected agent
    $successCount = 0
    $projectPath = Get-Location

    # Ask once whether to update project instruction hooks
    $shouldUpdateInstructions = $UpdateInstructions
    if (-not $UpdateInstructions -and -not $SkipInstructions) {
        try {
            $resp = Read-Host 'Update project instruction files (CLAUDE.md, .github/copilot-instructions.md, etc.)? (y/N)'
            if ($resp -match '^(y|yes)$') { $shouldUpdateInstructions = $true }
        } catch { }
    }
    
    foreach ($item in $selectedAgents) {
        $agent = $item.Agent
        $targetPath = $item.Path
        
        Write-Host "  Installing to $($agent.Name)..." -NoNewline
        
        try {
            $success = Install-SkillToAgent -TargetPath $targetPath -SourcePath $skillSource -Agent $agent
            
            if ($success) {
                Write-Color ' v' 'Green'
                $successCount++

                if ($shouldUpdateInstructions) {
                    Add-InstructionHook -Agent $agent -ProjectPath $projectPath
                }
            } else {
                Write-Color ' x Failed' 'Red'
            }
        }
        catch {
            Write-Color " x Error: $($_.Exception.Message)" 'Red'
        }
    }
    
    Write-Host ''
    Write-Color ('=' * 65) 'Cyan'
    Write-Color " Installation Complete: $successCount/$($selectedAgents.Count) agents" $(if ($successCount -eq $selectedAgents.Count) { 'Green' } else { 'Yellow' })
    Write-Color ('=' * 65) 'Cyan'
    
    # Beads Integration Check
    Write-Host ''
    $beadsStatus = Test-BeadsInstalled -ProjectPath $projectPath
    
    if ($beadsStatus.Installed) {
        Write-Color 'Beads detected in project!' 'Green'
        Write-Color '  Beads + Contracts = stronger enforcement via dependency blocking.' 'Gray'
        
        try {
            $resp = Read-Host '  Create Beads preflight task for contract checks? (Y/n)'
            if ($resp -notmatch '^(n|no)$') {
                Initialize-BeadsContractsIntegration -ProjectPath $projectPath
            }
        } catch {
            Initialize-BeadsContractsIntegration -ProjectPath $projectPath
        }
    } elseif ($beadsStatus.HasCli) {
        Write-Color 'Beads CLI found but not initialized in this project.' 'Yellow'
        Write-Color '  Tip: Run "bd init" to enable persistent task memory + contract enforcement.' 'Gray'
        Write-Color '  Learn more: https://github.com/steveyegge/beads' 'Gray'
    } else {
        Write-Color 'Tip: Install Beads for stronger contract enforcement via dependency blocking.' 'Gray'
        Write-Color '  npm install -g @beads/bd && bd init' 'Gray'
        Write-Color '  Learn more: https://github.com/steveyegge/beads' 'Gray'
    }
    
    Write-Host ''
    Write-Color 'Next steps:' 'Yellow'
    Write-Host '  1. Open a project and run: ' -NoNewline
    Write-Color 'init contracts' 'Cyan'
    Write-Host '  2. Or ask your AI: ' -NoNewline
    Write-Color '"Initialize contracts for this project"' 'Cyan'
    Write-Host ''

    # Optional: install web UI into the current project
    $uiChoice = $UiMode
    if (-not $uiChoice) {
        if ($SkipUI) {
            $uiChoice = 'none'
        } elseif ($InstallUI) {
            # Back-compat: old switch installs minimal-ui
            $uiChoice = 'minimal-ui'
        }
    }

    if (-not $uiChoice -and -not $SkipUI) {
        try {
            Write-Host 'Install Contracts Web UI into this project?' -ForegroundColor White
            Write-Host '  [1] minimal-ui (browser-only)'
            Write-Host '  [2] php-ui     (PHP)'
            Write-Host '  [3] none' -ForegroundColor Gray
            $resp = Read-Host 'Selection (default: 3)'
            $uiChoice = switch ($resp.Trim()) {
                '1' { 'minimal-ui' }
                '2' { 'php-ui' }
                default { 'none' }
            }
        } catch {
            $uiChoice = 'none'
        }
    }

    if ($uiChoice -and $uiChoice -ne 'none') {
        Write-Host ''
        Write-Color "Installing Contracts UI ($uiChoice)..." 'Cyan'
        Install-ContractsUI -SkillSource $skillSource -ProjectPath $projectPath -UI $uiChoice -Force:$ForceUI | Out-Null

        if ($uiChoice -eq 'minimal-ui') {
            $uiDir = Join-Path $projectPath 'contracts-ui'
            $cfgPath = Join-Path $uiDir 'contracts-ui.config.json'
            $startPs1 = Join-Path $uiDir 'start.ps1'

            # Decide auto-start preference
            $mode = $UIAutoStart
            if ($mode -eq 'ask') {
                try {
                    Write-Host ''
                    Write-Host 'Contracts UI Auto-Start konfigurieren?' -ForegroundColor White
                    Write-Host '  [1] aus (default)'
                    Write-Host '  [2] einmalig starten (ohne merken)'
                    Write-Host '  [3] an (bei init-contracts automatisch starten)'
                    $resp = Read-Host 'Selection (default: 1)'
                    $mode = switch ($resp.Trim()) {
                        '2' { 'once' }
                        '3' { 'on' }
                        default { 'off' }
                    }
                } catch {
                    $mode = 'off'
                }
            }

            # Persist config
            try {
                $openBrowser = $true
                $port = 8787
                $autoStart = $false
                if (Test-Path $cfgPath) {
                    try {
                        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
                        if ($cfg.openBrowser -eq $false) { $openBrowser = $false }
                        if ($cfg.port) { try { $port = [int]$cfg.port } catch {} }
                    } catch {}
                }

                if ($mode -eq 'on') { $autoStart = $true }
                if ($mode -eq 'off' -and -not (Test-Path $cfgPath)) { $autoStart = $false }

                $cfgOut = [ordered]@{ autoStart = $autoStart; port = $port; openBrowser = $openBrowser; projectRoot = '.' } | ConvertTo-Json -Depth 4
                Set-Content -Path $cfgPath -Value $cfgOut -Encoding UTF8
            } catch { }

            # Start now (explicit switch OR once/on selection)
            $shouldStartNow = $StartUI -or ($mode -eq 'once') -or ($mode -eq 'on')
            if ($shouldStartNow -and (Test-Path $startPs1)) {
                try {
                    Write-Host ''
                    Write-Color 'Starting Contracts UI...' 'Cyan'
                    & $startPs1 -ProjectRoot $projectPath | Out-Null
                } catch {
                    Write-Color "Warning: failed to start UI ($_ )" 'Yellow'
                }
            }
        }
    }

    # Optional: update agent.md with a short usage note
    $shouldUpdateAgentMd = $UpdateAgentMd
    if (-not $UpdateAgentMd -and -not $SkipAgentMd) {
        try {
            $resp = Read-Host 'Create/update agent.md in this project with a contracts usage note? (y/N)'
            if ($resp -match '^(y|yes)$') { $shouldUpdateAgentMd = $true }
        } catch { }
    }
    if ($shouldUpdateAgentMd) {
        Update-AgentMarkdown -ProjectPath $projectPath
    }
    
    # Run initialization if requested
    if ($Init) {
        Write-Host ''
        Write-Color 'Running initialization...' 'Cyan'
        
        $localInstall = $selectedAgents | Where-Object { $_.Agent.Id -eq 'local' }
        if ($localInstall) {
            $initScript = Join-Path $localInstall.Path 'ai\init-agent\index.js'
            if (Test-Path $initScript) {
                & node $initScript --path . --analyze
            }
        }
    }
}
finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}

# Export function for module usage
try { Export-ModuleMember -Function Install-ContractsSkill -ErrorAction Stop } catch { }

} @args
