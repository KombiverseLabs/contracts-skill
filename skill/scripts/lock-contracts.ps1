<#
.SYNOPSIS
    Locks approved CONTRACT.md files as read-only guardrails.

.DESCRIPTION
    StackKit contract lock standard. By default this locks CONTRACT.md files
    under a project path and leaves CONTRACT.yaml writable because YAML is the
    AI-maintained technical mapping.

    Windows uses the file ReadOnly attribute as a best-effort guardrail.
    Linux and macOS use chmod a-w.
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

function Set-ContractFileReadOnly {
    param([string]$FilePath)

    if (Test-WindowsPlatform) {
        $item = Get-Item -LiteralPath $FilePath
        $item.IsReadOnly = $true
        return
    }

    & chmod "a-w" $FilePath
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
    Write-Output "No contract files found to lock."
    exit 0
}

$count = 0
foreach ($target in $uniqueTargets) {
    if ($PSCmdlet.ShouldProcess($target, "Lock contract file")) {
        Set-ContractFileReadOnly -FilePath $target
        Write-Output "[locked] $target"
        $count++
    }
}

Write-Output "Locked $count contract file(s)."
