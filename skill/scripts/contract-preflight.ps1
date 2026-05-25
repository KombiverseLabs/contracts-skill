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
    pwsh skill/scripts/contract-preflight.ps1 -Path . -Changed

.EXAMPLE
    pwsh skill/scripts/contract-preflight.ps1 -Path . -Files src/core/auth/index.ts -OutputFormat json
#>

[CmdletBinding()]
param(
    [string]$Path = ".",

    [string[]]$Files = @(),

    [switch]$Changed,

    [switch]$RunVts,

    [ValidateSet("console", "json")]
    [string]$OutputFormat = "console"
)

$ErrorActionPreference = "Stop"

function Get-Sha256([string]$FilePath) {
    if (-not (Test-Path $FilePath)) { return $null }
    $rawBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $FilePath).Path)
    $normalized = [System.Collections.Generic.List[byte]]::new($rawBytes.Length)
    for ($i = 0; $i -lt $rawBytes.Length; $i++) {
        if ($rawBytes[$i] -eq 0x0D -and ($i + 1) -lt $rawBytes.Length -and $rawBytes[$i + 1] -eq 0x0A) {
            continue
        }
        $normalized.Add($rawBytes[$i])
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash($normalized.ToArray())
    $hex = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    return "sha256:$hex"
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

        $must = [regex]::Matches($body, '(?m)^\s*-\s*MUST(?:\s+\[REQ-\d{3}\])?:\s*(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value.Trim() }
        $mustNot = [regex]::Matches($body, '(?m)^\s*-\s*MUST\s+NOT(?:\s+\[REQ-\d{3}\])?:\s*(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value.Trim() }
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

function Get-YamlSection([string]$YamlContent, [string]$Section) {
    if ([string]::IsNullOrWhiteSpace($YamlContent)) { return "" }
    if ($YamlContent -match "(?ms)^$([regex]::Escape($Section))\s*:\s*(?<body>.*?)(?:\r?\n\w[^\r\n]*:\s*|\z)") {
        return $matches['body']
    }
    return ""
}

function Convert-ToBool($Value) {
    return "$Value".Trim().ToLowerInvariant() -eq "true"
}

function Parse-Lifecycle([string]$YamlContent) {
    $section = Get-YamlSection -YamlContent $YamlContent -Section "lifecycle"
    $status = "missing"
    if ($section -match '(?m)^\s*status:\s*"?([^"\r\n]+)"?') {
        $status = $matches[1].Trim()
    }

    $result = [ordered]@{
        status = $status
        specify = $false
        clarify = $false
        plan = $false
        test_first = $false
        implement = $false
        verify = $false
        attest = $false
    }

    foreach ($key in @("specify", "clarify", "plan", "test_first", "implement", "verify", "attest")) {
        if ($section -match "(?m)^\s*$key\s*:\s*(true|false)") {
            $result[$key] = Convert-ToBool $matches[1]
        }
    }

    return [pscustomobject]$result
}

function Parse-Tdd([string]$YamlContent) {
    $section = Get-YamlSection -YamlContent $YamlContent -Section "tdd"
    $red = $false
    $green = $false
    if ($section -match '(?m)^\s*red_verified:\s*(true|false)') { $red = Convert-ToBool $matches[1] }
    if ($section -match '(?m)^\s*green_verified:\s*(true|false)') { $green = Convert-ToBool $matches[1] }
    return [pscustomobject]@{
        red_verified = $red
        green_verified = $green
    }
}

function Parse-StatusCounts([string]$YamlContent, [string]$Section) {
    $body = Get-YamlSection -YamlContent $YamlContent -Section $Section
    $total = ([regex]::Matches($body, '(?m)^\s*-\s+(?:id|name):')).Count
    $passing = ([regex]::Matches($body, '(?m)^\s*status:\s*passing')).Count
    $failing = ([regex]::Matches($body, '(?m)^\s*status:\s*failing')).Count
    $implemented = ([regex]::Matches($body, '(?m)^\s*status:\s*implemented')).Count
    return [pscustomobject]@{
        total = $total
        passing = $passing
        failing = $failing
        implemented = $implemented
    }
}

function Parse-AcceptanceTests([string]$YamlContent) {
    $body = Get-YamlSection -YamlContent $YamlContent -Section "acceptance_tests"
    $total = ([regex]::Matches($body, '(?m)^\s*-\s+(?:id|name):')).Count
    $passed = ([regex]::Matches($body, '(?m)^\s*passed:\s*true')).Count
    return [pscustomobject]@{
        total = $total
        passed = $passed
    }
}

function Get-TraceabilityGaps([string]$ContractMdPath, [string]$YamlContent) {
    $gaps = @()
    $md = if (Test-Path $ContractMdPath) { Get-Content $ContractMdPath -Raw } else { "" }
    $ids = @([regex]::Matches($md + "`n" + $YamlContent, '\bREQ-\d{3}\b') | ForEach-Object { $_.Value } | Sort-Object -Unique)

    foreach ($id in $ids) {
        $escaped = [regex]::Escape($id)
        $coveredBy = $YamlContent -match "id:\s*""?$escaped""?[\s\S]*?covered_by:\s*\[[^\]]*(VT-\d{3}|AC-\d{3})"
        $verifies = $YamlContent -match "verifies:\s*\[[^\]]*$escaped"
        if (-not ($coveredBy -or $verifies)) {
            $gaps += "$id not covered"
        }
    }

    if ($md -match "(?ms)##\s+Core Features\s*(?<body>.*?)(?:\r?\n##\s+|\z)") {
        $featureLines = @($matches['body'] -split "`n" | Where-Object { $_ -match '^\s*-\s*\[[ xX]\]' })
        foreach ($line in $featureLines) {
            if ($line -notmatch '\[F-\d{3}\]') {
                $gaps += "missing feature id"
                break
            }
        }
    }

    return @($gaps)
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
    $yamlContent = if (Test-Path $yaml) { Get-Content $yaml -Raw } else { "" }

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
        lifecycle = Parse-Lifecycle -YamlContent $yamlContent
        tdd = Parse-Tdd -YamlContent $yamlContent
        verification_tests = Parse-StatusCounts -YamlContent $yamlContent -Section "verification_tests"
        acceptance_tests = Parse-AcceptanceTests -YamlContent $yamlContent
        traceability = [pscustomobject]@{
            gaps = @(Get-TraceabilityGaps -ContractMdPath $md -YamlContent $yamlContent)
        }
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
    Write-Host "  Lifecycle: $($m.lifecycle.status)" -ForegroundColor Gray
    Write-Host "  TDD: red=$($m.tdd.red_verified), green=$($m.tdd.green_verified)" -ForegroundColor Gray
    Write-Host "  VTs: $($m.verification_tests.total), Acceptance: $($m.acceptance_tests.total), Traceability gaps: $($m.traceability.gaps.Count)" -ForegroundColor Gray

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

# ─── Optional VT Execution ────────────────────────────────────
if ($RunVts) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $runVtsScript = Join-Path $scriptDir 'run-vts.ps1'
    if (Test-Path $runVtsScript) {
        Write-Host "Running verification tests..." -ForegroundColor Cyan
        Write-Host ""
        & $runVtsScript -Path $root -UpdateYaml -OutputFormat $OutputFormat
    } else {
        Write-Host "Warning: run-vts.ps1 not found at $runVtsScript" -ForegroundColor Yellow
    }
}
