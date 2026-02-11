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

    [string]$Module = $null,

    [ValidateSet('ask','on','off','once')]
    [string]$UI = 'ask',

    [int]$UIPort = 8787,

    [switch]$UINoOpen
)

$ErrorActionPreference = "Stop"

function Get-UiDir([string]$ProjectPath) {
    $p = (Resolve-Path $ProjectPath).Path
    return (Join-Path $p 'contracts-ui')
}

function Read-UiConfig([string]$UiDir) {
    $cfgPath = Join-Path $UiDir 'contracts-ui.config.json'
    if (-not (Test-Path $cfgPath)) { return $null }
    try { return (Get-Content $cfgPath -Raw | ConvertFrom-Json) } catch { return $null }
}

function Write-UiConfig([string]$UiDir, [bool]$AutoStart, [int]$Port, [bool]$OpenBrowser) {
    $cfgPath = Join-Path $UiDir 'contracts-ui.config.json'
    $obj = [ordered]@{
        autoStart = $AutoStart
        port = $Port
        openBrowser = $OpenBrowser
        projectRoot = '.'
    }
    $json = $obj | ConvertTo-Json -Depth 4
    Set-Content -Path $cfgPath -Value $json -Encoding UTF8
}

function Start-UiIfAvailable([string]$ProjectPath) {
    $uiDir = Get-UiDir $ProjectPath
    $startPs1 = Join-Path $uiDir 'start.ps1'
    $serverJs = Join-Path $uiDir 'server.js'

    if (-not (Test-Path $uiDir)) { return }
    if (-not (Test-Path $startPs1) -and -not (Test-Path $serverJs)) { return }

    $cfg = Read-UiConfig $uiDir
    $port = if ($cfg -and $cfg.port) { [int]$cfg.port } else { $UIPort }
    $openBrowser = if ($cfg -and $cfg.openBrowser -eq $false) { $false } else { $true }

    # Determine mode
    $mode = $UI
    if ($mode -eq 'ask') {
        if ($cfg -and ($cfg.autoStart -eq $true)) { $mode = 'on' }
        elseif ($cfg -and ($cfg.autoStart -eq $false)) { $mode = 'off' }
        else {
            Write-Host ''
            Write-Host 'Start Contracts UI?' -ForegroundColor White
            Write-Host '  [1] No (skip this time)' -ForegroundColor Gray
            Write-Host '  [2] Start now (one-time)'
            Write-Host '  [3] Start now and auto-start in future'
            $resp = Read-Host 'Selection (default: 1)'
            $mode = switch ($resp.Trim()) {
                '2' { 'once' }
                '3' { 'on' }
                default { 'off' }
            }
        }
    }

    if ($mode -eq 'off') { return }
    if ($mode -eq 'on') {
        Write-UiConfig -UiDir $uiDir -AutoStart:$true -Port:$port -OpenBrowser:$openBrowser
    }

    # Start the UI
    $startArgs = @('-Port', $port, '-ProjectRoot', (Resolve-Path $ProjectPath).Path)
    if ($UINoOpen -or -not $openBrowser) { $startArgs += '-NoOpen' }

    if (Test-Path $startPs1) {
        & $startPs1 @startArgs | Out-Null
    } elseif (Test-Path $serverJs) {
        Start-Process -FilePath 'node' -ArgumentList @(
            "`"$serverJs`"", '--port', "$port",
            '--project-root', "`"$((Resolve-Path $ProjectPath).Path)`""
        ) -WorkingDirectory $uiDir -WindowStyle Hidden | Out-Null
        if (-not $UINoOpen -and $openBrowser) {
            Start-Sleep -Milliseconds 250
            Start-Process "http://127.0.0.1:$port/" | Out-Null
        }
    }
}

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

    # Optional UI startup (after init completes)
    Start-UiIfAvailable -ProjectPath $resolvedPath
}
catch {
    Write-Host "Error running init-agent: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
