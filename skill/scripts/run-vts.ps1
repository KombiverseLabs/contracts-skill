<#
.SYNOPSIS
    Run verification tests (VTs) defined in CONTRACT.yaml files and report results as JSON.

.DESCRIPTION
    Scans for CONTRACT.yaml files (via registry.yaml or directory walk), extracts VTs with
    test_command defined, executes them, and outputs structured JSON results.

    The output format is compatible with Agent Arena's metrics.vt_results for contract scoring.

.PARAMETER Path
    Project root. Defaults to current directory.

.PARAMETER Registry
    Path to registry.yaml. If not found, falls back to scanning for CONTRACT.yaml files.

.PARAMETER Module
    Run VTs only for a specific module (by name or path).

.PARAMETER UpdateYaml
    Update CONTRACT.yaml status fields in-place after running VTs.

.PARAMETER OutputFormat
    Output format: console (default) or json.

.EXAMPLE
    pwsh run-vts.ps1 -Path . -OutputFormat json
    pwsh run-vts.ps1 -Path . -Module auth -UpdateYaml
#>

[CmdletBinding()]
param(
    [string]$Path = ".",
    [string]$Registry = "",
    [string]$Module = "",
    [switch]$UpdateYaml,
    [ValidateSet("console", "json", "cvr")]
    [string]$OutputFormat = "console"
)

$ErrorActionPreference = "Stop"
$VtTimeoutMs = 120000  # 2 minutes per VT command

function Find-ContractYamls([string]$Root, [string]$RegistryPath) {
    $yamls = @()

    # Try registry first
    if ($RegistryPath -and (Test-Path $RegistryPath)) {
        $content = Get-Content $RegistryPath -Raw
        $paths = [regex]::Matches($content, 'path:\s*"([^"]*)"') | ForEach-Object { $_.Groups[1].Value }
        foreach ($p in $paths) {
            $yamlPath = Join-Path (Join-Path $Root $p) 'CONTRACT.yaml'
            if (Test-Path $yamlPath) {
                $yamls += $yamlPath
            }
        }
        if ($yamls.Count -gt 0) { return $yamls }
    }

    # Fallback: recursive scan
    Get-ChildItem -Path $Root -Recurse -Filter 'CONTRACT.yaml' -File |
        Where-Object { $_.FullName -notmatch '(node_modules|\.git|dist|build)' } |
        ForEach-Object { $yamls += $_.FullName }

    return $yamls
}

function Parse-VerificationTests([string]$YamlPath) {
    $content = Get-Content $YamlPath -Raw
    $vts = @()

    # Extract module name
    $moduleName = ""
    if ($content -match 'name:\s*"([^"]*)"') {
        $moduleName = $matches[1]
    }

    # Extract module path
    $modulePath = ""
    if ($content -match 'module:[\s\S]*?path:\s*"([^"]*)"') {
        $modulePath = $matches[1]
    }

    # Parse verification_tests section
    $inVtSection = $false
    $currentVt = $null
    $lines = $content -split "`n"

    foreach ($line in $lines) {
        if ($line -match '^\s*verification_tests:\s*$') {
            $inVtSection = $true
            continue
        }

        # Stop at next top-level section
        if ($inVtSection -and $line -match '^\w' -and $line -notmatch '^\s') {
            if ($currentVt) { $vts += $currentVt }
            $inVtSection = $false
            continue
        }

        if (-not $inVtSection) { continue }

        # New VT entry
        if ($line -match '^\s+-\s+id:\s*"([^"]*)"') {
            if ($currentVt) { $vts += $currentVt }
            $currentVt = @{
                id = $matches[1]
                name = ""
                status = "defined"
                test_command = ""
                assertion_type = "exit_code"
                expected_output = ""
                test_file = ""
            }
            continue
        }

        if ($null -eq $currentVt) { continue }

        if ($line -match '^\s+name:\s*"([^"]*)"') { $currentVt.name = $matches[1] }
        if ($line -match '^\s+status:\s*(\S+)') { $currentVt.status = $matches[1] }
        if ($line -match '^\s+test_command:\s*"([^"]*)"') { $currentVt.test_command = $matches[1] }
        if ($line -match '^\s+assertion_type:\s*(\S+)') { $currentVt.assertion_type = $matches[1] }
        if ($line -match '^\s+expected_output:\s*"([^"]*)"') { $currentVt.expected_output = $matches[1] }
        if ($line -match '^\s+test_file:\s*"([^"]*)"') { $currentVt.test_file = $matches[1] }
    }

    if ($currentVt) { $vts += $currentVt }

    return @{
        module_name = $moduleName
        module_path = $modulePath
        yaml_path = $YamlPath
        vts = $vts
    }
}

function Run-SingleVt([hashtable]$Vt, [string]$WorkDir) {
    $result = @{
        id = $Vt.id
        name = $Vt.name
        status = "skipped"
        assertion_matched = $false
        duration_ms = 0
        details = ""
    }

    if ([string]::IsNullOrWhiteSpace($Vt.test_command)) {
        $result.details = "No test_command defined"
        return $result
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $output = ""
        $exitCode = 0

        # Run the command capturing output
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = if ($IsWindows -or $env:OS -match 'Windows') { "cmd.exe" } else { "/bin/sh" }
        $psi.Arguments = if ($IsWindows -or $env:OS -match 'Windows') { "/c $($Vt.test_command)" } else { "-c `"$($Vt.test_command)`"" }
        $psi.WorkingDirectory = $WorkDir
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $process = [System.Diagnostics.Process]::Start($psi)
        $stdout = $process.StandardOutput.ReadToEnd()
        $null = $process.StandardError.ReadToEnd()
        $completed = $process.WaitForExit($VtTimeoutMs)

        if (-not $completed) {
            try { $process.Kill() } catch { }
            $sw.Stop()
            $result.duration_ms = [int]$sw.ElapsedMilliseconds
            $result.status = "failing"
            $result.details = "Command timed out after $($VtTimeoutMs / 1000)s"
            return $result
        }

        $exitCode = $process.ExitCode
        $output = $stdout

        $sw.Stop()
        $result.duration_ms = [int]$sw.ElapsedMilliseconds

        # Check assertion based on type
        switch ($Vt.assertion_type) {
            "exit_code" {
                $result.assertion_matched = ($exitCode -eq 0)
                $result.status = if ($exitCode -eq 0) { "passing" } else { "failing" }
                $result.details = "Exit code: $exitCode"
            }
            "content" {
                $expected = $Vt.expected_output
                $result.assertion_matched = [bool]($output -match [regex]::Escape($expected))
                $result.status = if ($result.assertion_matched) { "passing" } else { "failing" }
                $result.details = if ($result.assertion_matched) { "Content match found" } else { "Expected content not found in output" }
            }
            "regex" {
                $pattern = $Vt.expected_output
                $result.assertion_matched = [bool]($output -match $pattern)
                $result.status = if ($result.assertion_matched) { "passing" } else { "failing" }
                $result.details = if ($result.assertion_matched) { "Regex match found" } else { "Regex pattern not matched" }
            }
            "json_path" {
                # Simple JSON field check: expected_output = "field.path=expected_value"
                try {
                    $json = $output | ConvertFrom-Json
                    if ($Vt.expected_output -match '^(.+?)=(.+)$') {
                        $jsonPath = $matches[1]
                        $expectedVal = $matches[2]
                        $actualVal = $json
                        foreach ($part in $jsonPath.Split('.')) {
                            if ($null -eq $actualVal) { break }
                            $actualVal = $actualVal.$part
                        }
                        $result.assertion_matched = ("$actualVal" -eq "$expectedVal")
                        $result.status = if ($result.assertion_matched) { "passing" } else { "failing" }
                        $result.details = if ($result.assertion_matched) { "JSON path matched" } else { "Expected '$expectedVal' at '$jsonPath', got '$actualVal'" }
                    } else {
                        $result.status = "failing"
                        $result.details = "Invalid expected_output format for json_path. Use 'field.path=value'."
                    }
                } catch {
                    $result.status = "failing"
                    $result.details = "JSON parse error: $($_.Exception.Message)"
                }
            }
            default {
                $result.assertion_matched = ($exitCode -eq 0)
                $result.status = if ($exitCode -eq 0) { "passing" } else { "failing" }
                $result.details = "Exit code: $exitCode (unknown assertion_type: $($Vt.assertion_type))"
            }
        }
    } catch {
        $sw.Stop()
        $result.duration_ms = [int]$sw.ElapsedMilliseconds
        $result.status = "failing"
        $result.details = "Execution error: $($_.Exception.Message)"
    }

    return $result
}

function Update-YamlVtStatus([string]$YamlPath, [array]$Results) {
    $content = Get-Content $YamlPath -Raw
    $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    foreach ($r in $Results) {
        if ($r.status -eq "skipped") { continue }

        # Update status field for this VT
        $content = $content -replace "(id:\s*`"$($r.id)`"[\s\S]*?)status:\s*\S+", "`$1status: $($r.status)"
        $content = $content -replace "(id:\s*`"$($r.id)`"[\s\S]*?)last_run:\s*\S+", "`$1last_run: `"$now`""
        $content = $content -replace "(id:\s*`"$($r.id)`"[\s\S]*?)last_result:\s*\S+", "`$1last_result: $(if ($r.status -eq 'passing') { 'pass' } else { 'fail' })"
    }

    $allRunnablePassed = ($Results | Where-Object { $_.status -ne "skipped" -and $_.status -ne "passing" }).Count -eq 0 -and
                         ($Results | Where-Object { $_.status -ne "skipped" }).Count -gt 0
    $passText = if ($allRunnablePassed) { "true" } else { "false" }
    $confidence = if ($allRunnablePassed) { "high" } elseif (($Results | Where-Object { $_.status -eq "failing" }).Count -gt 0) { "medium" } else { "low" }

    if ($content -match "(?m)^attestation\s*:") {
        $content = $content -replace "(verification_tests_pass:\s*)\S+", "`$1$passText"
        $content = $content -replace "(last_verified:\s*)\S+", "`$1`"$now`""
        $content = $content -replace "(confidence:\s*)\S+", "`$1$confidence"
    }

    Set-Content $YamlPath -Value $content -NoNewline
}

# ─── Main ────────────────────────────────────────────────────

$root = (Resolve-Path $Path).Path

# Find registry
$registryPath = $Registry
if (-not $registryPath) {
    $registryPath = Join-Path $root '.contracts' 'registry.yaml'
}

$yamlFiles = Find-ContractYamls -Root $root -RegistryPath $registryPath

$allResults = @()

foreach ($yamlFile in $yamlFiles) {
    $parsed = Parse-VerificationTests -YamlPath $yamlFile

    # Filter by module if specified
    if ($Module -and $parsed.module_name -ne $Module -and $parsed.module_path -ne $Module) {
        continue
    }

    $runnableVts = $parsed.vts | Where-Object { -not [string]::IsNullOrWhiteSpace($_.test_command) }

    if ($runnableVts.Count -eq 0) {
        if ($OutputFormat -eq 'console') {
            Write-Host "  $($parsed.module_name): No runnable VTs (no test_command defined)" -ForegroundColor DarkGray
        }
        continue
    }

    $workDir = Split-Path $yamlFile -Parent
    $moduleResults = @()

    foreach ($vt in $runnableVts) {
        $vtResult = Run-SingleVt -Vt $vt -WorkDir $workDir
        $moduleResults += $vtResult
    }

    if ($UpdateYaml) {
        Update-YamlVtStatus -YamlPath $yamlFile -Results $moduleResults
    }

    $allResults += [pscustomobject]@{
        module = $parsed.module_name
        path = $parsed.module_path
        vt_results = $moduleResults
    }
}

# Output
if ($OutputFormat -eq 'json') {
    if ($allResults.Count -eq 0) {
        Write-Output "[]"
    } else {
        $allResults | ConvertTo-Json -Depth 10
    }
} elseif ($OutputFormat -eq 'cvr') {
    # Contract Verification Report — one CVR per module
    $cvrReports = @()
    foreach ($module in $allResults) {
        $yamlFile = $yamlFiles | Where-Object { (Split-Path $_ -Parent) -match [regex]::Escape($module.path) } | Select-Object -First 1
        $contractMdPath = if ($yamlFile) { Join-Path (Split-Path $yamlFile -Parent) 'CONTRACT.md' } else { $null }

        # Compute contract hash
        $contractHash = ""
        if ($contractMdPath -and (Test-Path $contractMdPath)) {
            $contractContent = Get-Content $contractMdPath -Raw -ErrorAction SilentlyContinue
            if ($contractContent) {
                $sha = [System.Security.Cryptography.SHA256]::Create()
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($contractContent -replace "`r`n", "`n")
                $hashBytes = $sha.ComputeHash($bytes)
                $contractHash = "sha256:" + [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
                $sha.Dispose()
            }
        }

        # Read drift status from YAML if available
        $driftStatus = "missing_yaml"
        $sourceHash = ""
        if ($yamlFile -and (Test-Path $yamlFile)) {
            $driftStatus = "ok"
            $yamlContent = Get-Content $yamlFile -Raw
            if ($yamlContent -match 'source_hash:\s*"([^"]*)"') {
                $sourceHash = $matches[1]
                if ($contractHash -and $sourceHash -and $sourceHash -ne $contractHash) {
                    $driftStatus = "mismatch"
                }
            } else {
                $driftStatus = "missing_source_hash"
            }
        }

        $vtResults = $module.vt_results
        $passing = ($vtResults | Where-Object { $_.status -eq 'passing' }).Count
        $failing = ($vtResults | Where-Object { $_.status -eq 'failing' }).Count
        $skipped = ($vtResults | Where-Object { $_.status -eq 'skipped' }).Count
        $total = $vtResults.Count

        # Extract title from CONTRACT.md
        $title = ""
        if ($contractMdPath -and (Test-Path $contractMdPath)) {
            $firstLine = Get-Content $contractMdPath -TotalCount 1 -ErrorAction SilentlyContinue
            if ($firstLine -match '^#\s+(.+)') { $title = $matches[1] }
        }

        $cvr = [ordered]@{
            schema_version = "1.0"
            contract = [ordered]@{
                path = $module.path
                hash = $contractHash
                title = $title
            }
            drift = [ordered]@{
                status = $driftStatus
                source_hash = $sourceHash
                computed_hash = $contractHash
            }
            verification_tests = [ordered]@{
                total = $total
                passing = $passing
                failing = $failing
                skipped = $skipped
                results = $vtResults
            }
            generated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            generated_by = "contracts-skill/run-vts.ps1"
        }

        $cvrReports += $cvr
    }

    if ($cvrReports.Count -eq 1) {
        $cvrReports[0] | ConvertTo-Json -Depth 10
    } else {
        $cvrReports | ConvertTo-Json -Depth 10
    }
} else {
    if ($allResults.Count -eq 0) {
        Write-Host "No VTs found to run." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Verification Test Results:" -ForegroundColor Cyan
    Write-Host ""

    foreach ($module in $allResults) {
        $passing = ($module.vt_results | Where-Object { $_.status -eq 'passing' }).Count
        $total = $module.vt_results.Count
        $color = if ($passing -eq $total) { 'Green' } elseif ($passing -gt 0) { 'Yellow' } else { 'Red' }

        Write-Host "  $($module.module) ($($module.path)): $passing/$total passing" -ForegroundColor $color

        foreach ($vt in $module.vt_results) {
            $vtColor = switch ($vt.status) {
                'passing' { 'Green' }
                'failing' { 'Red' }
                'skipped' { 'DarkGray' }
                default { 'Yellow' }
            }
            Write-Host "    $($vt.id): $($vt.status) ($($vt.duration_ms)ms) - $($vt.details)" -ForegroundColor $vtColor
        }

        Write-Host ""
    }
}
