<#
.SYNOPSIS
    Agent-led contract initialization helper.

.DESCRIPTION
    Thin wrapper around the deterministic Node init helper. Analyze and dry-run
    modes are read-only. Any mode that writes files must use -Apply -Yes.
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

    # Accepted for backward compatibility; UI is not auto-started by this wrapper.
    [ValidateSet('ask','on','off','once')]
    [string]$UI = 'off',
    [int]$UIPort = 8787,
    [switch]$UINoOpen
)

$ErrorActionPreference = "Stop"

if ($Apply -and -not $Yes) {
    Write-Host "Error: -Apply requires -Yes after the user has approved the drafts." -ForegroundColor Red
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillDir = Split-Path -Parent $scriptDir
$initAgentPath = Join-Path $skillDir "ai\init-agent\index.js"

if (-not (Test-Path $initAgentPath)) {
    Write-Host "Error: init helper not found at $initAgentPath" -ForegroundColor Red
    exit 1
}

$arguments = @("--path", $Path)

if ($Module) {
    $arguments += @("--module", $Module)
}

if ($Apply) {
    $arguments += "--apply"
} elseif ($Recommend) {
    $arguments += "--recommend"
} elseif ($DryRun) {
    $arguments += "--dry-run"
} else {
    $arguments += "--analyze"
}

if ($Force) { $arguments += "--force" }
if ($Yes) { $arguments += "--yes" }

try {
    $resolvedPath = (Resolve-Path $Path).Path
    Write-Host "Analyzing project at: $resolvedPath" -ForegroundColor Cyan
    Write-Host ""

    & node "$initAgentPath" $arguments

    if ($LASTEXITCODE -ne 0) {
        throw "init helper exited with code $LASTEXITCODE"
    }
}
catch {
    Write-Host "Error running init helper: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
