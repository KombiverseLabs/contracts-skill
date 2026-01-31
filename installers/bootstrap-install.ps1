<#
.SYNOPSIS
    Bootstrap installer for the Contracts skill.

.DESCRIPTION
    Downloads the main installer to a temp file, then executes it.
    This is more robust than piping the script directly into Invoke-Expression.

.PARAMETER InstallerArgs
    Optional arguments forwarded to the downloaded installers/install.ps1.
    Example: -InstallerArgs @('-Agents','copilot,claude','-UI','minimal-ui')
#>

param(
    [string]$RepoOwner = 'KombiverseLabs',
    [string]$RepoName = 'contracts-skill',
    [string]$Branch = 'main',

    [string[]]$InstallerArgs = @()
)

$ErrorActionPreference = 'Stop'
$rawUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/installers/install.ps1"
$tmp = Join-Path $env:TEMP ("contracts-skill-install-{0:yyyyMMddHHmmss}.ps1" -f (Get-Date))
Write-Host "Downloading installer to: $tmp" -ForegroundColor Cyan
Invoke-RestMethod -Uri $rawUrl -OutFile $tmp -UseBasicParsing
Write-Host "Executing installer..." -ForegroundColor Cyan
# Prefer pwsh (PowerShell Core) when available, otherwise fall back to Windows PowerShell
$pwshCmd = (Get-Command pwsh -ErrorAction SilentlyContinue).Path
if ($pwshCmd) {
    & $pwshCmd -NoProfile -ExecutionPolicy Bypass -File $tmp @InstallerArgs
} else {
    $psCmd = (Get-Command powershell -ErrorAction SilentlyContinue).Path
    if ($psCmd) {
        & $psCmd -NoProfile -ExecutionPolicy Bypass -File $tmp @InstallerArgs
    } else {
        Write-Host "No PowerShell executable (pwsh or powershell) found. Please run the downloaded script at: $tmp" -ForegroundColor Red
        return
    }
}
Write-Host "Cleaning up" -ForegroundColor Cyan
Remove-Item -Force $tmp -ErrorAction SilentlyContinue
