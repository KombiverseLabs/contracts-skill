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
$hashLower = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })

switch ($Format) {
    "full" {
        Write-Output "sha256:$hashLower"
    }
    "short" {
        Write-Output $hashLower.Substring(0, 12)
    }
}
