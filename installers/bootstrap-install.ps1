# Bootstrap installer: download installer to temp file, then execute it (more robust than piping)
param(
    [string]$RepoOwner = 'KombiverseLabs',
    [string]$RepoName = 'contracts-skill',
    [string]$Branch = 'main'
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
    & $pwshCmd -NoProfile -ExecutionPolicy Bypass -File $tmp
} else {
    $psCmd = (Get-Command powershell -ErrorAction SilentlyContinue).Path
    if ($psCmd) {
        & $psCmd -NoProfile -ExecutionPolicy Bypass -File $tmp
    } else {
        Write-Host "No PowerShell executable (pwsh or powershell) found. Please run the downloaded script at: $tmp" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Cleaning up" -ForegroundColor Cyan
Remove-Item -Force $tmp -ErrorAction SilentlyContinue
