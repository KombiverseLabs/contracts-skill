<#
.SYNOPSIS
  Install local git hooks for this repo (PowerShell)
#>

Write-Host "Setting git core.hooksPath to .githooks"
git config core.hooksPath .githooks
Write-Host "Done. To verify: git config core.hooksPath"