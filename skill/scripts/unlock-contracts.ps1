<#
.SYNOPSIS
    Unlocks CONTRACT.md files for human-approved edits.

.DESCRIPTION
    StackKit contract lock standard. By default this unlocks CONTRACT.md files
    under a project path. Use -IncludeYaml only when CONTRACT.yaml was
    intentionally locked too.

    Windows clears the file ReadOnly attribute. Linux and macOS use chmod u+w.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Path = ".",
    [string[]]$Files = @(),
    [switch]$IncludeYaml
)

$ErrorActionPreference = "Stop"

function Test-WindowsPlatform {
    return $env:OS -eq "Windows_NT"
}

function Add-ContractFile {
    param(
        [System.Collections.Generic.List[string]]$TargetList,
        [string]$Candidate,
        [bool]$IncludeYamlFile
    )

    if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
        $item = Get-Item -LiteralPath $Candidate
        if ($item.Name -eq "CONTRACT.md" -or $item.Name -eq "CONTRACT.yaml") {
            $TargetList.Add($item.FullName)
        } else {
            Write-Warning "Skipping non-contract file: $Candidate"
        }
        return
    }

    if (Test-Path -LiteralPath $Candidate -PathType Container) {
        foreach ($match in Get-ChildItem -LiteralPath $Candidate -Filter "CONTRACT.md" -File -Recurse) {
            $TargetList.Add($match.FullName)
        }
        if ($IncludeYamlFile) {
            foreach ($match in Get-ChildItem -LiteralPath $Candidate -Filter "CONTRACT.yaml" -File -Recurse) {
                $TargetList.Add($match.FullName)
            }
        }
        return
    }

    throw "Not found: $Candidate"
}

function Set-ContractFileWritable {
    param([string]$FilePath)

    if (Test-WindowsPlatform) {
        $item = Get-Item -LiteralPath $FilePath
        $item.IsReadOnly = $false
        return
    }

    & chmod "u+w" $FilePath
    if ($LASTEXITCODE -ne 0) {
        throw "chmod failed for $FilePath"
    }
}

$root = (Resolve-Path -LiteralPath $Path).Path
$targets = [System.Collections.Generic.List[string]]::new()

if ($Files.Count -gt 0) {
    foreach ($file in $Files) {
        $candidate = $file
        if (-not [System.IO.Path]::IsPathRooted($candidate)) {
            $candidate = Join-Path $root $candidate
        }
        Add-ContractFile -TargetList $targets -Candidate $candidate -IncludeYamlFile ([bool]$IncludeYaml)
    }
} else {
    Add-ContractFile -TargetList $targets -Candidate $root -IncludeYamlFile ([bool]$IncludeYaml)
}

$uniqueTargets = $targets | Sort-Object -Unique

if (-not $uniqueTargets -or $uniqueTargets.Count -eq 0) {
    Write-Output "No contract files found to unlock."
    exit 0
}

$count = 0
foreach ($target in $uniqueTargets) {
    if ($PSCmdlet.ShouldProcess($target, "Unlock contract file")) {
        Set-ContractFileWritable -FilePath $target
        Write-Output "[unlocked] $target"
        $count++
    }
}

Write-Output "Unlocked $count contract file(s)."
