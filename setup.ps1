<#
.SYNOPSIS
    Automated installer that detects AI coding assistants and installs to all of them.

.DESCRIPTION
    Scans for known AI coding assistant configurations and offers to install
    the Contracts skill to each detected environment.

.PARAMETER Auto
    Automatically install to all detected agents without prompting.

.EXAMPLE
    # Interactive mode (recommended)
    irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.ps1 | iex

.EXAMPLE
    # Auto-install to all detected agents
    .\setup.ps1 -Auto
#>

param(
    [switch]$Auto
)

$ErrorActionPreference = "Stop"

# Configuration
$RepoOwner = "KombiverseLabs"
$RepoName = "contracts-skill"
$Branch = "main"
$SkillName = "contracts"

# Colors for output
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    Write-Host ""
    Write-Color "========================================" Cyan
    Write-Color " Contracts Skill - Automated Installer" Cyan
    Write-Color " Spec-Driven Development for AI Assistants" Cyan
    Write-Color "========================================" Cyan
    Write-Host ""
}

# Agent detection configurations
$AgentConfigs = @(
    @{
        Name = "GitHub Copilot (VS Code)"
        Icon = "🤖"
        Paths = @(
            (Join-Path $env:USERPROFILE ".copilot\skills\$SkillName"),
            (Join-Path $env:USERPROFILE ".github\copilot\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".copilot"),
            (Join-Path $env:APPDATA "Code\User\settings.json")
        )
        InstructionFile = ".github\copilot-instructions.md"
        InstructionSnippet = @"

## Contracts System
Before modifying any module, check for CONTRACT.md files.
Consult the ``contracts`` skill for spec-driven development workflow.
Never edit CONTRACT.md files directly - they are user-owned specifications.
"@
    },
    @{
        Name = "Claude Code"
        Icon = "🧠"
        Paths = @(
            (Join-Path $env:USERPROFILE ".claude\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".claude"),
            (Join-Path $env:APPDATA "Claude")
        )
        InstructionFile = "CLAUDE.md"
        InstructionSnippet = @"

## Contracts System
Before any code changes, check for CONTRACT.md in the target directory.
Use the contracts skill for spec-driven development.
CONTRACT.md files are user-owned - never edit them directly.
See ``.claude/skills/contracts/SKILL.md`` for full workflow.
"@
    },
    @{
        Name = "Cursor"
        Icon = "⚡"
        Paths = @(
            (Join-Path $env:USERPROFILE ".cursor\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".cursor"),
            (Join-Path $env:APPDATA "Cursor")
        )
        InstructionFile = ".cursorrules"
        InstructionSnippet = @"

# Contracts System
Always check for CONTRACT.md before modifying code in any module.
CONTRACT.md files are user-owned specifications - never edit them.
When CONTRACT.md changes, sync the corresponding CONTRACT.yaml.
"@
    },
    @{
        Name = "Windsurf (Codeium)"
        Icon = "🏄"
        Paths = @(
            (Join-Path $env:USERPROFILE ".windsurf\skills\$SkillName"),
            (Join-Path $env:USERPROFILE ".codeium\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".windsurf"),
            (Join-Path $env:USERPROFILE ".codeium"),
            (Join-Path $env:APPDATA "Windsurf")
        )
        InstructionFile = ".windsurfrules"
        InstructionSnippet = @"

# Contracts System
Check for CONTRACT.md before modifying any module.
CONTRACT.md = user-owned specs (never edit), CONTRACT.yaml = AI-maintained.
"@
    },
    @{
        Name = "Aider"
        Icon = "🔧"
        Paths = @(
            (Join-Path $env:USERPROFILE ".aider\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".aider"),
            (Join-Path $env:USERPROFILE ".aider.conf.yml")
        )
        InstructionFile = $null
        InstructionSnippet = $null
    },
    @{
        Name = "Cline (VS Code)"
        Icon = "📟"
        Paths = @(
            (Join-Path $env:USERPROFILE ".cline\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".cline"),
            (Join-Path $env:APPDATA "Code\User\globalStorage\saoudrizwan.claude-dev")
        )
        InstructionFile = ".clinerules"
        InstructionSnippet = @"

# Contracts System
Before code changes, check for CONTRACT.md files.
CONTRACT.md = user specs (read-only), CONTRACT.yaml = sync when MD changes.
"@
    },
    @{
        Name = "Project Local (.agent)"
        Icon = "📁"
        Paths = @(
            (Join-Path (Get-Location) ".agent\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path (Get-Location) ".agent"),
            (Join-Path (Get-Location) "package.json"),
            (Join-Path (Get-Location) ".git")
        )
        InstructionFile = $null
        InstructionSnippet = $null
        AlwaysOffer = $true
    }
)

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
        $skillFile = Join-Path $path "SKILL.md"
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
        [string]$SourcePath
    )
    
    $parent = Split-Path $TargetPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    
    if (Test-Path $TargetPath) {
        Remove-Item -Recurse -Force $TargetPath
    }
    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
    
    return (Test-Path (Join-Path $TargetPath "SKILL.md"))
}

function Download-Skill {
    param([string]$TempDir)
    
    Write-Color "Downloading skill from GitHub..." Yellow
    
    # Try git clone first
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            $gitOutput = git clone --quiet --depth 1 --branch $Branch "https://github.com/$RepoOwner/$RepoName.git" $TempDir 2>&1
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path $TempDir)) {
                Write-Color "Downloaded via git" Green
                return Join-Path $TempDir "skill"
            }
        }
        catch {
            Write-Color "Git clone failed, trying ZIP fallback..." Yellow
        }
    }
    
    # Fallback to ZIP
    Write-Color "Downloading ZIP archive..." Yellow
    $zipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
    $zipPath = Join-Path $env:TEMP "contracts-skill.zip"
    
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $TempDir -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue
        
        $extractedFolder = Get-ChildItem $TempDir -Directory | Select-Object -First 1
        if (-not $extractedFolder) {
            throw "ZIP extraction failed - no directory found in $TempDir"
        }
        Write-Color "Downloaded via ZIP" Green
        
        return Join-Path $extractedFolder.FullName "skill"
    }
    catch {
        throw "Failed to download skill from GitHub: $_"
    }
}

# Main installation flow
Write-Header

# Detect agents
Write-Color "Scanning for AI coding assistants..." Cyan
Write-Host ""

$detectedAgents = @()
$installedAgents = @()

foreach ($agent in $AgentConfigs) {
    $isInstalled = Test-AgentInstalled -Agent $agent
    $existingPath = Test-SkillInstalled -Agent $agent
    
    $status = if ($existingPath) {
        $installedAgents += @{ Agent = $agent; Path = $existingPath }
        "[INSTALLED]"
    } elseif ($isInstalled -or $agent.AlwaysOffer) {
        $detectedAgents += $agent
        "[DETECTED]"
    } else {
        "[NOT FOUND]"
    }
    
    $color = switch ($status) {
        "[INSTALLED]" { "Green" }
        "[DETECTED]" { "Yellow" }
        default { "Gray" }
    }
    
    Write-Color "  $($agent.Icon) $($agent.Name): $status" $color
}

Write-Host ""

# Show already installed
if ($installedAgents.Count -gt 0) {
    Write-Color "Already installed:" Green
    foreach ($item in $installedAgents) {
        Write-Color "  v $($item.Agent.Name) -> $($item.Path)" Gray
    }
    Write-Host ""
}

# Nothing to install
if ($detectedAgents.Count -eq 0) {
    Write-Color "No new agents to install to." Yellow
    Write-Host ""
    Write-Color "Tip: Run this in a project directory to install locally to .agent/skills/" Cyan
    exit 0
}

# Interactive selection
Write-Color "Select agents to install to:" White
Write-Host ""

$selectedAgents = @()
$index = 1

foreach ($agent in $detectedAgents) {
    $installPath = Get-PreferredInstallPath -Agent $agent
    
    if ($Auto) {
        $selectedAgents += @{ Agent = $agent; Path = $installPath }
        Write-Color "  [$index] $($agent.Icon) $($agent.Name)" Green
        Write-Color "      -> $installPath" Gray
    } else {
        Write-Host "  [$index] $($agent.Icon) $($agent.Name)" -NoNewline
        Write-Host " -> " -NoNewline -ForegroundColor Gray
        Write-Host $installPath -ForegroundColor Gray
    }
    $index++
}

if (-not $Auto) {
    Write-Host ""
    Write-Host "  [A] Install to ALL detected agents"
    Write-Host "  [Q] Quit"
    Write-Host ""
    
    $selection = Read-Host "Enter selection (e.g., '1,2' or 'A')"
    
    if ($selection -eq 'Q' -or $selection -eq 'q') {
        Write-Color "Installation cancelled." Yellow
        exit 0
    }
    
    if ($selection -eq 'A' -or $selection -eq 'a') {
        foreach ($agent in $detectedAgents) {
            $selectedAgents += @{ Agent = $agent; Path = (Get-PreferredInstallPath -Agent $agent) }
        }
    } else {
        $indices = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
        foreach ($i in $indices) {
            $idx = [int]$i - 1
            if ($idx -ge 0 -and $idx -lt $detectedAgents.Count) {
                $agent = $detectedAgents[$idx]
                $selectedAgents += @{ Agent = $agent; Path = (Get-PreferredInstallPath -Agent $agent) }
            }
        }
    }
}

if ($selectedAgents.Count -eq 0) {
    Write-Color "No agents selected." Yellow
    exit 0
}

Write-Host ""
Write-Color "Installing to $($selectedAgents.Count) agent(s)..." Cyan

# Download skill once
$tempDir = Join-Path $env:TEMP "contracts-skill-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    $skillSource = Download-Skill -TempDir $tempDir
    
    if (-not (Test-Path $skillSource)) {
        throw "Skill source not found at: $skillSource"
    }
    
    Write-Host ""
    
    # Install to each selected agent
    $successCount = 0
    
    foreach ($item in $selectedAgents) {
        $agent = $item.Agent
        $targetPath = $item.Path
        
        Write-Host "  Installing to $($agent.Name)..." -NoNewline
        
        try {
            $success = Install-SkillToAgent -TargetPath $targetPath -SourcePath $skillSource
            
            if ($success) {
                Write-Color " v" Green
                $successCount++
                
                # Add instruction snippet if applicable
                if ($agent.InstructionFile -and $agent.InstructionSnippet) {
                    $projectInstructionFile = Join-Path (Get-Location) $agent.InstructionFile
                    
                    if (Test-Path $projectInstructionFile) {
                        $content = Get-Content $projectInstructionFile -Raw
                        if ($content -notmatch "Contracts System") {
                            Add-Content -Path $projectInstructionFile -Value $agent.InstructionSnippet
                            Write-Color "    -> Added hook to $($agent.InstructionFile)" Gray
                        }
                    }
                }
            } else {
                Write-Color " x Failed" Red
            }
        } catch {
            Write-Color " x Error: $($_.Exception.Message)" Red
        }
    }
    
    Write-Host ""
    Write-Color "========================================" Cyan
    Write-Color " Installation Complete: $successCount/$($selectedAgents.Count) agents" $(if ($successCount -eq $selectedAgents.Count) { "Green" } else { "Yellow" })
    Write-Color "========================================" Cyan
    
    Write-Host ""
    Write-Color "Next steps:" Yellow
    Write-Host "  1. Open a project and run: " -NoNewline
    Write-Color "init contracts" Cyan
    Write-Host "  2. Or ask your AI: " -NoNewline
    Write-Color '"Initialize contracts for this project"' Cyan
    Write-Host ""
    
} finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}
