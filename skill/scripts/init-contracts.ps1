<#
.SYNOPSIS
    Initialize contracts for a project using AI-assisted analysis.

.DESCRIPTION
    This script provides a PowerShell interface to the AI-assisted contract
    initialization tool. It analyzes the project structure semantically and
    generates contract recommendations.

.PARAMETER Path
    Root path of the project to analyze. Defaults to current directory.

.PARAMETER Analyze
    Analyze the project and show recommendations (default mode).

.PARAMETER Recommend
    Generate contract drafts for recommended modules.

.PARAMETER DryRun
    Show what would be created without writing files.

.PARAMETER Apply
    Write contract files to disk.

.PARAMETER Force
    Overwrite existing contracts.

.PARAMETER Yes
    Skip confirmation prompts.

.PARAMETER Module
    Create contract for a specific module path only.

.EXAMPLE
    # Analyze current project
    .\init-contracts.ps1

.EXAMPLE
    # Analyze specific path
    .\init-contracts.ps1 -Path "C:\Projects\MyApp"

.EXAMPLE
    # Generate and apply contracts
    .\init-contracts.ps1 -Apply -Yes

.EXAMPLE
    # Create contract for specific module
    .\init-contracts.ps1 -Module "./src/auth" -Yes
#>

[CmdletBinding()]
param(
    [string]$Path = ".",
    
    [switch]$Analyze,
    
    [switch]$Recommend,
    
    [switch]$DryRun,
    
    [switch]$Apply,
    
    [switch]$Force,
    
    [switch]$Yes,
    
    [string]$Module = $null
)

$ErrorActionPreference = "Stop"

# Resolve the skill path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillDir = Split-Path -Parent $scriptDir
$initAgentPath = Join-Path $skillDir "ai\init-agent\index.js"

# Verify init-agent exists
if (-not (Test-Path $initAgentPath)) {
    Write-Host "Error: init-agent not found at $initAgentPath" -ForegroundColor Red
    Write-Host "Please ensure the contracts skill is properly installed." -ForegroundColor Yellow
    exit 1
}

# Build command arguments
$arguments = @()
$arguments += "--path"
$arguments += $Path

if ($Analyze) {
    $arguments += "--analyze"
}
elseif ($Recommend) {
    $arguments += "--recommend"
}
elseif ($DryRun) {
    $arguments += "--dry-run"
}
elseif ($Apply) {
    $arguments += "--apply"
}
elseif ($Module) {
    $arguments += "--module"
    $arguments += $Module
}
else {
    # Default to analyze
    $arguments += "--analyze"
}

if ($Force) {
    $arguments += "--force"
}

if ($Yes) {
    $arguments += "--yes"
}

# Execute the init-agent
try {
    $resolvedPath = Resolve-Path $Path
    Write-Host "Analyzing project at: $resolvedPath" -ForegroundColor Cyan
    Write-Host ""
    
    & node "$initAgentPath" $arguments
    
    if ($LASTEXITCODE -ne 0) {
        throw "init-agent exited with code $LASTEXITCODE"
    }
}
catch {
    Write-Host "Error running init-agent: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
