<#
.SYNOPSIS
    Contract preflight: finds relevant contracts for changed/target files and prints constraints.

.DESCRIPTION
    Given a set of file paths (or the current git diff), locates the nearest CONTRACT.md for each
    impacted module, checks CONTRACT.yaml drift via meta.source_hash, and extracts MUST/MUST NOT
    constraints from CONTRACT.md.

.PARAMETER Path
    Project root to treat as the boundary for contract lookup. Defaults to current directory.

.PARAMETER Files
    One or more file paths (relative to -Path or absolute) that are planned/changed.

.PARAMETER Changed
    Auto-detect changed files via git (staged + unstaged).

.PARAMETER OutputFormat
    Output format: console (default) or json.

.EXAMPLE
    pwsh .github/skills/contracts/scripts/contract-preflight.ps1 -Path . -Changed

.EXAMPLE
    pwsh .github/skills/contracts/scripts/contract-preflight.ps1 -Path . -Files src/core/auth/index.ts -OutputFormat json
#>

[CmdletBinding()]
param(
    [string]$Path = ".",

    [string[]]$Files = @(),

    [switch]$Changed,

    [ValidateSet("console", "json")]
    [string]$OutputFormat = "console"
)

$ErrorActionPreference = "Stop"

function Get-Sha256([string]$FilePath) {
    if (-not (Test-Path $FilePath)) { return $null }
    $h = Get-FileHash -Path $FilePath -Algorithm SHA256
    return "sha256:$($h.Hash.ToLower())"
}

function Get-RelativePath([string]$Root, [string]$FullPath) {
    $rootFull = [System.IO.Path]::GetFullPath($Root)
    $full = [System.IO.Path]::GetFullPath($FullPath)

    if ($full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $full.Substring($rootFull.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        return ($rel -replace '\\', '/')
    }

    return ($full -replace '\\', '/')
}

function Find-ContractDir([string]$StartDir, [string]$RootDir) {
    $rootFull = [System.IO.Path]::GetFullPath($RootDir).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    $current = [System.IO.Path]::GetFullPath($StartDir)
    while ($true) {
        # Stop if we walked above root
        if (-not $current.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $null
        }

        $contractMd = Join-Path $current 'CONTRACT.md'
        if (Test-Path $contractMd) {
            return $current
        }

        $parent = Split-Path $current -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or ($parent -eq $current)) {
            return $null
        }
        $current = $parent
    }
}

function Parse-ContractConstraints([string]$ContractMdPath) {
    $content = Get-Content $ContractMdPath -Raw

    $name = $null
    if ($content -match '(?m)^#\s+(.+?)\s*$') {
        $name = $matches[1].Trim()
    }

    $must = @()
    $mustNot = @()

    if ($content -match '(?ms)##\s+Constraints\s*(?<body>.*?)(?:\r?\n##\s+|\z)') {
        $body = $matches['body']

        $must = [regex]::Matches($body, '(?m)^\s*-\s*MUST:\s*(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value.Trim() }
        $mustNot = [regex]::Matches($body, '(?m)^\s*-\s*MUST\s+NOT:\s*(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value.Trim() }
    }

    return [pscustomobject]@{
        name = $name
        constraints = [pscustomobject]@{
            must = @($must)
            must_not = @($mustNot)
        }
    }
}

function Read-SourceHashFromYaml([string]$YamlPath) {
    if (-not (Test-Path $YamlPath)) { return $null }
    $yaml = Get-Content $YamlPath -Raw
    if ($yaml -match 'source_hash:\s*"([^"]*)"') {
        $val = $matches[1]
        if ([string]::IsNullOrWhiteSpace($val)) { return $null }
        return $val.Trim()
    }
    return $null
}

$root = (Resolve-Path $Path).Path

if ($Changed) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        throw "-Changed requires 'git' in PATH. Provide -Files instead."
    }

    $unstaged = @(git diff --name-only)
    $staged = @(git diff --name-only --cached)
    $Files = @($unstaged + $staged | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
}

if (-not $Files -or $Files.Count -eq 0) {
    $empty = [pscustomobject]@{
        root = ($root -replace '\\', '/')
        modules = @()
        note = "No input files provided (use -Files or -Changed)."
    }

    if ($OutputFormat -eq 'json') {
        $empty | ConvertTo-Json -Depth 8
    } else {
        Write-Host "No input files provided. Use -Files or -Changed." -ForegroundColor Yellow
    }
    exit 0
}

$contractDirs = New-Object System.Collections.Generic.HashSet[string]

foreach ($f in $Files) {
    $candidate = $f

    # If relative, anchor under root
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $candidate = Join-Path $root $candidate
    }

    # For deleted/renamed files, Resolve-Path may fail; use directory inference
    $dir = Split-Path $candidate -Parent
    if ([string]::IsNullOrWhiteSpace($dir)) {
        continue
    }

    $cdir = Find-ContractDir -StartDir $dir -RootDir $root
    if ($cdir) {
        [void]$contractDirs.Add([System.IO.Path]::GetFullPath($cdir))
    }
}

$modules = @()
foreach ($dir in ($contractDirs | Sort-Object)) {
    $md = Join-Path $dir 'CONTRACT.md'
    $yaml = Join-Path $dir 'CONTRACT.yaml'

    $parsed = Parse-ContractConstraints -ContractMdPath $md

    $currentHash = Get-Sha256 -FilePath $md
    $storedHash = Read-SourceHashFromYaml -YamlPath $yaml

    $driftStatus = 'unknown'
    if ($storedHash -and $currentHash) {
        $driftStatus = if ($storedHash -eq $currentHash) { 'ok' } else { 'mismatch' }
    } elseif (-not (Test-Path $yaml)) {
        $driftStatus = 'missing_yaml'
    } elseif (-not $storedHash) {
        $driftStatus = 'missing_source_hash'
    }

    $modules += [pscustomobject]@{
        path = (Get-RelativePath -Root $root -FullPath $dir)
        name = $parsed.name
        contract_md = (Get-RelativePath -Root $root -FullPath $md)
        contract_yaml = if (Test-Path $yaml) { (Get-RelativePath -Root $root -FullPath $yaml) } else { $null }
        constraints = $parsed.constraints
        drift = [pscustomobject]@{
            status = $driftStatus
            current_hash = $currentHash
            stored_hash = $storedHash
        }
    }
}

$out = [pscustomobject]@{
    root = ($root -replace '\\', '/')
    input_files = @($Files)
    modules = @($modules)
}

if ($OutputFormat -eq 'json') {
    $out | ConvertTo-Json -Depth 10
    exit 0
}

if ($modules.Count -eq 0) {
    Write-Host "No CONTRACT.md found for provided paths." -ForegroundColor Yellow
    exit 0
}

Write-Host "Contract preflight:" -ForegroundColor Cyan
Write-Host "Root: $($out.root)" -ForegroundColor DarkGray
Write-Host "" 

foreach ($m in $modules) {
    $title = if ($m.name) { $m.name } else { $m.path }

    $color = switch ($m.drift.status) {
        'ok' { 'Green' }
        'mismatch' { 'Red' }
        default { 'Yellow' }
    }

    Write-Host "- $title ($($m.path))" -ForegroundColor White
    Write-Host "  Drift: $($m.drift.status)" -ForegroundColor $color

    if ($m.constraints.must.Count -gt 0) {
        Write-Host "  MUST:" -ForegroundColor Gray
        $m.constraints.must | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    }

    if ($m.constraints.must_not.Count -gt 0) {
        Write-Host "  MUST NOT:" -ForegroundColor Gray
        $m.constraints.must_not | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    }

    if (($m.constraints.must.Count -eq 0) -and ($m.constraints.must_not.Count -eq 0)) {
        Write-Host "  (No explicit MUST/MUST NOT constraints found in CONTRACT.md)" -ForegroundColor DarkGray
    }

    Write-Host "" 
}
