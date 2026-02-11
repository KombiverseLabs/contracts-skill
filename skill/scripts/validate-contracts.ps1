<#
.SYNOPSIS
    Validates all contracts in a project for drift and specification compliance.

.DESCRIPTION
    This script scans for CONTRACT.md and CONTRACT.yaml pairs, checks for:
    - Hash mismatches (drift detection)
    - Missing YAML files
    - Invalid YAML structure
    - Feature status consistency
    - Test coverage for implemented features

.PARAMETER Path
    Root path to scan for contracts. Defaults to current directory.

.PARAMETER Fix
    Attempt to auto-fix issues (update hashes, regenerate YAML).

.PARAMETER OutputFormat
    Output format: 'console' (default), 'json', 'github-actions'

.EXAMPLE
    .\validate-contracts.ps1 -Path "C:\project" -OutputFormat json
#>

param(
    [string]$Path = ".",
    [switch]$Fix,
    [ValidateSet("console", "json", "github-actions")]
    [string]$OutputFormat = "console"
)

$ErrorActionPreference = "Stop"

# Results collector
$results = @{
    scanned = 0
    passed = 0
    warnings = @()
    errors = @()
}

function Get-FileHash256 {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    return "sha256:$($hash.Hash.ToLower())"
}

function Test-YamlStructure {
    param([string]$YamlPath)

    # Structure validation via top-level key detection.
    # Matches keys at column 0 followed by colon (YAML mapping keys).
    # PowerShell has no native YAML parser, so we use line-anchored regex.
    $content = Get-Content $YamlPath -Raw

    $requiredKeys = @("meta", "module", "features", "constraints", "changelog")
    $missing = @()

    foreach ($key in $requiredKeys) {
        if ($content -notmatch "(?m)^${key}\s*:") {
            $missing += $key
        }
    }

    return $missing
}

function Test-FeatureCoverage {
    param([string]$YamlPath)

    $content = Get-Content $YamlPath -Raw
    $dir = Split-Path $YamlPath -Parent
    $warnings = @()

    # Find features with status implemented or in-progress
    $implementedFeatures = [regex]::Matches($content, 'status:\s*(implemented|in-progress)')

    if ($implementedFeatures.Count -eq 0) {
        return $warnings
    }

    # Get test pattern from YAML
    $testPattern = "*.test.*"
    if ($content -match 'test_pattern:\s*"([^"]*)"') {
        $testPattern = $matches[1]
    }

    # Check if test files exist
    $testFiles = Get-ChildItem -Path $dir -Filter $testPattern -Recurse -ErrorAction SilentlyContinue

    if ($testFiles.Count -eq 0) {
        $warnings += "$($implementedFeatures.Count) feature(s) marked implemented/in-progress but no test files found (pattern: $testPattern)"
    }

    return $warnings
}

function Test-DependencyImpact {
    param(
        [string]$ModulePath,
        [string]$RootPath
    )

    $registryPath = Join-Path (Join-Path $RootPath ".contracts") "registry.yaml"
    if (-not (Test-Path $registryPath)) {
        return @()
    }

    $content = Get-Content $registryPath -Raw
    $resolvedRoot = (Resolve-Path $RootPath).Path
    $relativePath = $ModulePath.Replace($resolvedRoot, "").TrimStart('\', '/').Replace('\', '/')
    $dirPath = Split-Path $relativePath -Parent

    $dependents = @()
    $escaped = [regex]::Escape($dirPath)
    if ($content -match "depends_on:.*$escaped") {
        $dependents += "Module has dependents - changes may require updating their contracts"
    }

    return $dependents
}

function Write-Result {
    param(
        [string]$Type,      # "pass", "warn", "error"
        [string]$Path,
        [string]$Message
    )
    
    switch ($OutputFormat) {
        "console" {
            $icon = switch ($Type) {
                "pass"  { "✅" }
                "warn"  { "⚠️" }
                "error" { "❌" }
            }
            Write-Host "$icon $Path : $Message"
        }
        "github-actions" {
            switch ($Type) {
                "warn"  { Write-Host "::warning file=$Path::$Message" }
                "error" { Write-Host "::error file=$Path::$Message" }
            }
        }
    }
}

# Find all CONTRACT.md files
Write-Host "Scanning for contracts in: $Path" -ForegroundColor Cyan
$contractFiles = Get-ChildItem -Path $Path -Recurse -Filter "CONTRACT.md" -File

if ($contractFiles.Count -eq 0) {
    Write-Host "No CONTRACT.md files found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($contractFiles.Count) contract(s)" -ForegroundColor Cyan
Write-Host ""

foreach ($mdFile in $contractFiles) {
    $results.scanned++
    $dir = $mdFile.DirectoryName
    $relativePath = $mdFile.FullName.Replace((Resolve-Path $Path).Path, "").TrimStart("\", "/")
    $yamlPath = Join-Path $dir "CONTRACT.yaml"
    
    # Check 1: YAML exists
    if (-not (Test-Path $yamlPath)) {
        $results.errors += @{
            path = $relativePath
            message = "Missing CONTRACT.yaml"
        }
        Write-Result -Type "error" -Path $relativePath -Message "Missing CONTRACT.yaml"
        continue
    }
    
    # Check 2: YAML structure
    $missingKeys = Test-YamlStructure -YamlPath $yamlPath
    if ($missingKeys.Count -gt 0) {
        $msg = "Invalid YAML structure, missing: $($missingKeys -join ', ')"
        $results.errors += @{
            path = $relativePath
            message = $msg
        }
        Write-Result -Type "error" -Path $relativePath -Message $msg
        continue
    }
    
    # Check 3: Hash comparison (drift detection)
    $currentHash = Get-FileHash256 -FilePath $mdFile.FullName
    $yamlContent = Get-Content $yamlPath -Raw
    
    if ($yamlContent -match 'source_hash:\s*"([^"]*)"') {
        $storedHash = $matches[1]
        
        if ([string]::IsNullOrWhiteSpace($storedHash)) {
            $results.warnings += @{
                path = $relativePath
                message = "Empty source_hash in YAML"
            }
            Write-Result -Type "warn" -Path $relativePath -Message "Empty source_hash - run sync"
        }
        elseif ($storedHash -ne $currentHash) {
            $results.errors += @{
                path = $relativePath
                message = "Hash mismatch - CONTRACT.md changed without YAML sync"
                stored = $storedHash
                current = $currentHash
            }
            Write-Result -Type "error" -Path $relativePath -Message "DRIFT DETECTED - Hash mismatch"
            
            if ($Fix) {
                Write-Host "  → Fix mode: Would update hash (not implemented)" -ForegroundColor DarkGray
            }
        }
        else {
            $results.passed++
            Write-Result -Type "pass" -Path $relativePath -Message "Synced"
        }
    }
    else {
        $results.warnings += @{
            path = $relativePath
            message = "Could not parse source_hash from YAML"
        }
        Write-Result -Type "warn" -Path $relativePath -Message "Could not parse source_hash"
    }

    # Check 4: Test coverage for implemented features
    $coverageWarnings = Test-FeatureCoverage -YamlPath $yamlPath
    foreach ($cw in $coverageWarnings) {
        $results.warnings += @{
            path = $relativePath
            message = $cw
        }
        Write-Result -Type "warn" -Path $relativePath -Message $cw
    }

    # Check 5: Dependency impact
    $depWarnings = Test-DependencyImpact -ModulePath $mdFile.FullName -RootPath $Path
    foreach ($dw in $depWarnings) {
        $results.warnings += @{
            path = $relativePath
            message = $dw
        }
        Write-Result -Type "warn" -Path $relativePath -Message $dw
    }
}

# Summary
Write-Host ""
Write-Host "=" * 50 -ForegroundColor DarkGray
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Scanned:  $($results.scanned)"
Write-Host "  Passed:   $($results.passed)" -ForegroundColor Green
Write-Host "  Warnings: $($results.warnings.Count)" -ForegroundColor Yellow
Write-Host "  Errors:   $($results.errors.Count)" -ForegroundColor Red

if ($OutputFormat -eq "json") {
    $results | ConvertTo-Json -Depth 5
}

# Exit code for CI
if ($results.errors.Count -gt 0) {
    exit 1
}
exit 0
