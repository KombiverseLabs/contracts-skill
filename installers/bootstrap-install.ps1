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
& pwsh -NoProfile -ExecutionPolicy Bypass -File $tmp
Write-Host "Cleaning up" -ForegroundColor Cyan
Remove-Item -Force $tmp -ErrorAction SilentlyContinue
