<#
.SYNOPSIS
    Computes SHA256 hash for CONTRACT.md files.

.DESCRIPTION
    Utility script to compute the hash value that should be stored in CONTRACT.yaml.
    Used for manual verification and debugging.

.PARAMETER FilePath
    Path to the CONTRACT.md file.

.PARAMETER Format
    Output format: 'full' (sha256:hash) or 'short' (first 12 chars)

.EXAMPLE
    .\compute-hash.ps1 -FilePath "src/auth/CONTRACT.md"
    # Output: sha256:a1b2c3d4e5f6...

.EXAMPLE
    .\compute-hash.ps1 -FilePath "src/auth/CONTRACT.md" -Format short
    # Output: a1b2c3d4e5f6
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [ValidateSet("full", "short")]
    [string]$Format = "full"
)

if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

$hash = Get-FileHash -Path $FilePath -Algorithm SHA256
$hashLower = $hash.Hash.ToLower()

switch ($Format) {
    "full" {
        Write-Output "sha256:$hashLower"
    }
    "short" {
        Write-Output $hashLower.Substring(0, 12)
    }
}
