<#
.SYNOPSIS
    One-liner installer for the Contracts skill.

.DESCRIPTION
    Downloads and installs the Contracts skill to the current project or globally.

.PARAMETER Scope
    Installation scope: 'project' (default) or 'global'

.PARAMETER Init
    Run initialization after installation.

.PARAMETER Branch
    Git branch to install from. Default: 'main'

.EXAMPLE
    # One-liner install (paste in PowerShell):
    irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/install.ps1 | iex

.EXAMPLE
    # Install globally:
    irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/install.ps1 | iex; Install-ContractsSkill -Scope global

.EXAMPLE
    # Install and initialize:
    irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/install.ps1 | iex; Install-ContractsSkill -Init
#>

$ErrorActionPreference = "Stop"

# Configuration
$RepoOwner = "KombiverseLabs"
$RepoName = "contracts-skill"
$Branch = "main"
$SkillName = "contracts"

function Install-ContractsSkill {
    param(
        [ValidateSet("project", "global")]
        [string]$Scope = "project",
        [switch]$Init,
        [string]$GitBranch = $Branch
    )
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Contracts Skill Installer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Determine target directory
    $targetDir = switch ($Scope) {
        "global" {
            $globalPath = Join-Path $env:USERPROFILE ".copilot\skills\$SkillName"
            Write-Host "Installing globally to: $globalPath" -ForegroundColor Yellow
            $globalPath
        }
        "project" {
            $projectPath = Join-Path (Get-Location) ".agent\skills\$SkillName"
            Write-Host "Installing to project: $projectPath" -ForegroundColor Yellow
            $projectPath
        }
    }
    
    # Check if already installed
    if (Test-Path $targetDir) {
        Write-Host ""
        Write-Host "Skill already installed at: $targetDir" -ForegroundColor Yellow
        $overwrite = Read-Host "Overwrite? [y/N]"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Host "Installation cancelled." -ForegroundColor Red
            return
        }
        Remove-Item -Recurse -Force $targetDir
    }
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "contracts-skill-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    try {
        Write-Host ""
        Write-Host "Downloading from GitHub..." -ForegroundColor Cyan
        
        # Method 1: Try git clone (faster, preserves structure)
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git clone --depth 1 --branch $GitBranch "https://github.com/$RepoOwner/$RepoName.git" $tempDir 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Downloaded via git clone" -ForegroundColor Green
            }
            else {
                throw "Git clone failed"
            }
        }
        else {
            # Method 2: Download ZIP (fallback)
            Write-Host "Git not found, downloading ZIP..." -ForegroundColor Yellow
            $zipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$GitBranch.zip"
            $zipPath = Join-Path $env:TEMP "contracts-skill.zip"
            
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
            Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
            Remove-Item $zipPath
            
            # ZIP extracts to subfolder
            $extractedFolder = Get-ChildItem $tempDir -Directory | Select-Object -First 1
            $tempDir = $extractedFolder.FullName
            
            Write-Host "Downloaded via ZIP" -ForegroundColor Green
        }
        
        # Copy skill to target
        Write-Host ""
        Write-Host "Installing skill..." -ForegroundColor Cyan
        
        $sourceSkill = Join-Path $tempDir "skill"
        if (-not (Test-Path $sourceSkill)) {
            # Fallback: skill might be in .agent/skills/contracts
            $sourceSkill = Join-Path $tempDir ".agent\skills\contracts"
        }
        
        if (-not (Test-Path $sourceSkill)) {
            throw "Could not find skill folder in downloaded content"
        }
        
        # Create parent directory
        $parentDir = Split-Path $targetDir -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        # Copy skill
        Copy-Item -Path $sourceSkill -Destination $targetDir -Recurse -Force
        
        Write-Host "Skill installed to: $targetDir" -ForegroundColor Green
        
        # Verify installation
        $skillFile = Join-Path $targetDir "SKILL.md"
        if (Test-Path $skillFile) {
            Write-Host "Verification: SKILL.md found ✓" -ForegroundColor Green
        }
        else {
            Write-Host "Warning: SKILL.md not found" -ForegroundColor Yellow
        }
        
    }
    finally {
        # Cleanup temp
        if (Test-Path $tempDir) {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }
    
    # Run initialization if requested
    if ($Init) {
        Write-Host ""
        Write-Host "Running initialization..." -ForegroundColor Cyan
        $initScript = Join-Path $targetDir "scripts\init-contracts.ps1"
        if (Test-Path $initScript) {
            & $initScript -Path (Get-Location) -Interactive $true
        }
        else {
            Write-Host "Init script not found at: $initScript" -ForegroundColor Yellow
        }
    }
    
    # Success message
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Initialize contracts:"
    Write-Host "     $targetDir\scripts\init-contracts.ps1 -Path `".`"" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. Or ask your AI assistant:"
    Write-Host "     `"Initialize contracts for this project`"" -ForegroundColor Cyan
    Write-Host ""
}

# Auto-run if invoked via one-liner
if ($MyInvocation.InvocationName -eq "&" -or $MyInvocation.Line -match "iex") {
    Write-Host "Run 'Install-ContractsSkill' to install, or 'Install-ContractsSkill -Init' to install and initialize." -ForegroundColor Cyan
}

# Export function for manual use
Export-ModuleMember -Function Install-ContractsSkill -ErrorAction SilentlyContinue
