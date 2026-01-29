<#
.SYNOPSIS
    One-liner installer for the Contracts skill.
#>

$ErrorActionPreference = 'Stop'

$RepoOwner = 'KombiverseLabs'
$RepoName  = 'contracts-skill'
$Branch    = 'main'
$SkillName = 'contracts'

function Install-ContractsSkill {
    param(
        [ValidateSet('project','global')]
        [string]$Scope = 'project',
        [switch]$Init,
        [string]$GitBranch = $Branch
    )

    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ' Contracts Skill Installer' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''

    $targetDir = if ($Scope -eq 'global') { Join-Path $env:USERPROFILE ".copilot\skills\$SkillName" } else { Join-Path (Get-Location) ".agent\skills\$SkillName" }
    Write-Host "Installing to: $targetDir" -ForegroundColor Yellow

    if (Test-Path $targetDir) {
        $ok = Read-Host "Target exists. Overwrite? [y/N]"
        if ($ok -notin @('y','Y')) { Write-Host 'Cancelled.' -ForegroundColor Yellow; return }
        Remove-Item -Recurse -Force $targetDir
    }

    $tempDir = Join-Path $env:TEMP ('contracts-skill-{0:yyyyMMddHHmmss}' -f (Get-Date))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $outFile = Join-Path $env:TEMP 'contracts-skill-git-out.txt'
            $errFile = Join-Path $env:TEMP 'contracts-skill-git-err.txt'
            $gitArgs = @('clone','--depth','1','--branch',$GitBranch,"https://github.com/$RepoOwner/$RepoName.git",$tempDir)
            $proc = Start-Process -FilePath git -ArgumentList $gitArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
            if ($proc.ExitCode -ne 0) {
                $err = ''
                if (Test-Path $errFile) { $err = Get-Content $errFile -Raw }
                Throw "git clone failed: $err"
            } else {
                Write-Host 'Downloaded via git clone' -ForegroundColor Green
            }
        } else {
            $zip = Join-Path $env:TEMP 'contracts-skill.zip'
            Invoke-WebRequest -Uri "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$GitBranch.zip" -OutFile $zip -UseBasicParsing
            Expand-Archive -Path $zip -DestinationPath $tempDir -Force
            Remove-Item $zip -Force
            # adjust tempDir to extracted folder if needed
            $d = Get-ChildItem $tempDir -Directory | Select-Object -First 1
            if ($d) { $tempDir = $d.FullName }
        }

        $src = Join-Path $tempDir 'skill'
        if (-not (Test-Path $src)) { $src = Join-Path $tempDir '.agent\skills\contracts' }
        if (-not (Test-Path $src)) { Throw 'Skill folder not found in archive' }

        # ensure parent dir exists
        $parent = Split-Path $targetDir -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -Path $src -Destination $targetDir -Recurse -Force

        Write-Host 'Installed to:' -ForegroundColor Green; Write-Host $targetDir -ForegroundColor Cyan

        if ($Init) {
            $initScript = Join-Path $targetDir 'scripts\init-contracts.ps1'
            if (Test-Path $initScript) { & $initScript -Path (Get-Location) -Interactive $true } else { Write-Host 'Init script not found' -ForegroundColor Yellow }
        }

        Write-Host 'Installation complete.' -ForegroundColor Green
        Write-Host "Next: pwsh $targetDir\scripts\init-contracts.ps1 -Path ." -ForegroundColor Cyan
    }
    finally { if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue } }
}

# Auto-run if piped via iex or executed via Invoke-Expression
$invokedByIex = $false
try { if ($MyInvocation.Line -match 'iex') { $invokedByIex = $true } } catch { }

if ($MyInvocation.InvocationName -match 'Invoke-Expression' -or $invokedByIex) {
    try {
        Install-ContractsSkill -Scope project
    } catch {
        Write-Host "Auto-install failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

try { Export-ModuleMember -Function Install-ContractsSkill -ErrorAction Stop } catch { }
