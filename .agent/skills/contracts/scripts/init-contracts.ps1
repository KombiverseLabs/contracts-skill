<#
.SYNOPSIS
    Initializes the contracts system for a project.

.DESCRIPTION
    Scans the project for modules and existing specifications, then creates
    CONTRACT.md and CONTRACT.yaml files with a central registry.

.PARAMETER Path
    Root path of the project. Defaults to current directory.

.PARAMETER DryRun
    Show what would be created without actually creating files.

.PARAMETER Interactive
    Prompt for approval at each step (default: true).

.PARAMETER Templates
    Path to custom templates directory.

.EXAMPLE
    .\init-contracts.ps1 -Path "C:\myproject" -DryRun
#>

param(
    [string]$Path = ".",
    [switch]$DryRun,
    [bool]$Interactive = $true,
    [string]$Templates = ""
)

$ErrorActionPreference = "Stop"
$Path = Resolve-Path $Path

# Default template path
if ([string]::IsNullOrEmpty($Templates)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $Templates = Join-Path $scriptDir "..\references\templates"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Contracts System Initialization" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project: $Path"
Write-Host "Templates: $Templates"
Write-Host "Dry Run: $DryRun"
Write-Host ""

# Phase 1: Discovery
Write-Host "[Phase 1] Discovery" -ForegroundColor Yellow
Write-Host "-" * 40

# Find existing spec files
$specPatterns = @(
    "SPEC.md", "SPECIFICATION.md",
    "ARCHITECTURE.md", "DESIGN.md",
    "README.md"
)

$existingSpecs = @()
foreach ($pattern in $specPatterns) {
    $found = Get-ChildItem -Path $Path -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
    $existingSpecs += $found
}

Write-Host "Found $($existingSpecs.Count) specification file(s):"
foreach ($spec in $existingSpecs) {
    $rel = $spec.FullName.Replace($Path, "").TrimStart("\", "/")
    Write-Host "  - $rel"
}

# Identify module structure
$modulePatterns = @(
    @{ Path = "src/features/*"; Type = "feature" },
    @{ Path = "src/core/*"; Type = "core" },
    @{ Path = "src/lib/*"; Type = "utility" },
    @{ Path = "src/components/*"; Type = "feature" },
    @{ Path = "src/services/*"; Type = "core" },
    @{ Path = "packages/*"; Type = "feature" },
    @{ Path = "apps/*"; Type = "feature" }
)

$detectedModules = @()

foreach ($pattern in $modulePatterns) {
    $searchPath = Join-Path $Path $pattern.Path.Replace("/*", "")
    if (Test-Path $searchPath) {
        $subdirs = Get-ChildItem -Path $searchPath -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $subdirs) {
            # Skip if already has CONTRACT.md
            $existingContract = Join-Path $dir.FullName "CONTRACT.md"
            $hasContract = Test-Path $existingContract
            
            $detectedModules += @{
                Path = $dir.FullName.Replace($Path, "").TrimStart("\", "/")
                Name = $dir.Name
                Type = $pattern.Type
                HasContract = $hasContract
            }
        }
    }
}

Write-Host ""
Write-Host "Detected $($detectedModules.Count) module(s):"
foreach ($mod in $detectedModules) {
    $status = if ($mod.HasContract) { "[EXISTS]" } else { "[NEW]" }
    Write-Host "  $status $($mod.Path) ($($mod.Type))"
}

# Phase 2: Planning
Write-Host ""
Write-Host "[Phase 2] Planning" -ForegroundColor Yellow
Write-Host "-" * 40

$newModules = $detectedModules | Where-Object { -not $_.HasContract }
Write-Host "Will create contracts for $($newModules.Count) module(s)"

if ($Interactive -and -not $DryRun -and $newModules.Count -gt 0) {
    $confirm = Read-Host "Proceed with initialization? [y/N]"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Aborted." -ForegroundColor Red
        exit 0
    }
}

# Phase 3: Generation
Write-Host ""
Write-Host "[Phase 3] Generation" -ForegroundColor Yellow
Write-Host "-" * 40

# Create .contracts directory
$contractsDir = Join-Path $Path ".contracts"
if (-not $DryRun) {
    if (-not (Test-Path $contractsDir)) {
        New-Item -ItemType Directory -Path $contractsDir | Out-Null
        Write-Host "Created: .contracts/"
    }
}

# Registry data
$registry = @{
    project = @{
        name = Split-Path $Path -Leaf
        initialized = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    contracts = @()
}

foreach ($mod in $newModules) {
    $modPath = Join-Path $Path $mod.Path
    $contractMd = Join-Path $modPath "CONTRACT.md"
    $contractYaml = Join-Path $modPath "CONTRACT.yaml"
    
    # Select template based on type
    $templateFile = Join-Path $Templates "$($mod.Type).md"
    if (-not (Test-Path $templateFile)) {
        $templateFile = Join-Path $Templates "feature.md"
    }
    
    Write-Host ""
    Write-Host "Creating: $($mod.Path)/CONTRACT.md" -ForegroundColor Green
    
    if (-not $DryRun) {
        # Read and customize template
        $template = Get-Content $templateFile -Raw
        $template = $template.Replace("[Module Name]", $mod.Name)
        $template = $template.Replace("[Core Module Name]", $mod.Name)
        $template = $template.Replace("[Integration Name]", $mod.Name)
        
        # Write CONTRACT.md
        Set-Content -Path $contractMd -Value $template -Encoding UTF8
        
        # Compute hash
        $hash = (Get-FileHash -Path $contractMd -Algorithm SHA256).Hash.ToLower()
        
        # Create CONTRACT.yaml
        $yamlContent = @"
# CONTRACT.yaml - Technical specification derived from CONTRACT.md
# This file is auto-synced with CONTRACT.md.

meta:
  source_hash: "sha256:$hash"
  last_sync: "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
  tier: $($mod.Type -eq 'core' ? 'core' : 'standard')
  version: "1.0"

module:
  name: "$($mod.Name)"
  type: "$($mod.Type)"
  path: "$($mod.Path.Replace('\', '/'))"

features: []

constraints:
  must: []
  must_not: []

relationships:
  depends_on: []
  consumed_by: []

validation:
  exports: []
  test_pattern: "*.test.ts"
  custom_script: null

changelog:
  - date: "$(Get-Date -Format 'yyyy-MM-dd')"
    version: "1.0"
    change: "Initial contract (auto-generated)"
    author: "init-contracts"
"@
        
        Set-Content -Path $contractYaml -Value $yamlContent -Encoding UTF8
        Write-Host "Created: $($mod.Path)/CONTRACT.yaml" -ForegroundColor Green
    }
    
    # Add to registry
    $registry.contracts += @{
        path = $mod.Path.Replace('\', '/')
        name = $mod.Name
        tier = if ($mod.Type -eq 'core') { 'core' } else { 'standard' }
        type = $mod.Type
        summary = "Auto-generated contract"
    }
}

# Write registry
$registryPath = Join-Path $contractsDir "registry.yaml"
if (-not $DryRun) {
    $registryYaml = @"
# .contracts/registry.yaml
# Central index of all contracts in this project

project:
  name: "$($registry.project.name)"
  initialized: "$($registry.project.initialized)"
  initialized_by: "contracts-skill v1.0"

contracts:
"@
    
    foreach ($c in $registry.contracts) {
        $registryYaml += @"

  - path: "$($c.path)"
    name: "$($c.name)"
    tier: $($c.tier)
    type: $($c.type)
    summary: "$($c.summary)"
"@
    }
    
    Set-Content -Path $registryPath -Value $registryYaml -Encoding UTF8
    Write-Host ""
    Write-Host "Created: .contracts/registry.yaml" -ForegroundColor Green
}

# Phase 4: Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Initialization Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created:"
Write-Host "  - $($newModules.Count) CONTRACT.md files"
Write-Host "  - $($newModules.Count) CONTRACT.yaml files"
Write-Host "  - 1 registry.yaml"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review each CONTRACT.md and customize for your project"
Write-Host "  2. Run: .\validate-contracts.ps1 -Path `"$Path`""
Write-Host "  3. Add hooks to your IDE instruction files"
