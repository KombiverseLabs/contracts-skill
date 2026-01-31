param(
  [int]$Port = 8787,
  [string]$ProjectRoot = $null,
  [switch]$NoOpen,
  [switch]$Foreground,
  [switch]$StrictPort,
  [switch]$NoHealthCheck,
  [int]$HealthCheckTimeoutSec = 3,
  [string]$ConfigPath = $null
)

$ErrorActionPreference = 'Stop'

function Read-Config([string]$Path) {
  if (-not $Path) { return $null }
  if (-not (Test-Path $Path)) { return $null }
  try {
    return (Get-Content $Path -Raw | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Resolve-ProjectRoot([string]$ExplicitRoot) {
  if ($ExplicitRoot) { return (Resolve-Path $ExplicitRoot).Path }

  # Default: assume script is inside <project>/contracts-ui
  $uiDir = (Resolve-Path $PSScriptRoot).Path
  $parent = Split-Path -Parent $uiDir
  if ($parent) { return (Resolve-Path $parent).Path }

  return (Get-Location).Path
}

function Find-FreePort([int]$Preferred) {
  # Try a small range from preferred -> preferred+25
  for ($p = $Preferred; $p -lt ($Preferred + 25); $p++) {
    try {
      $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $p)
      $listener.Start()
      $listener.Stop()
      return $p
    } catch {
      continue
    }
  }
  return $Preferred
}

$uiDir = (Resolve-Path $PSScriptRoot).Path
$serverJs = Join-Path $uiDir 'server.js'
if (-not (Test-Path $serverJs)) {
  Write-Host "Missing server.js at $serverJs" -ForegroundColor Red
  exit 1
}

if (-not $ConfigPath) {
  $ConfigPath = Join-Path $uiDir 'contracts-ui.config.json'
}

$cfg = Read-Config $ConfigPath
if ($cfg) {
  if (-not $PSBoundParameters.ContainsKey('Port') -and $cfg.port) {
    try { $Port = [int]$cfg.port } catch {}
  }
  if (-not $PSBoundParameters.ContainsKey('ProjectRoot') -and $cfg.projectRoot) {
    $ProjectRoot = [string]$cfg.projectRoot
  }
  if (-not $PSBoundParameters.ContainsKey('NoOpen') -and $cfg.openBrowser -eq $false) {
    $NoOpen = $true
  }
}

$resolvedRoot = Resolve-ProjectRoot $ProjectRoot
$resolvedPort = Find-FreePort $Port
$portChanged = $resolvedPort -ne $Port
if ($portChanged) {
  if ($StrictPort) {
    Write-Host "Port $Port is already in use. Re-run with a free port or omit -Port to auto-select." -ForegroundColor Red
    exit 1
  }
  Write-Host "Port $Port is in use; using $resolvedPort instead." -ForegroundColor Yellow
}
$url = "http://127.0.0.1:$resolvedPort/"

if ($Foreground) {
  Write-Host "Starting Contracts UI server (foreground)" -ForegroundColor Cyan
  Write-Host "  Project root: $resolvedRoot" -ForegroundColor Gray
  Write-Host "  URL: $url" -ForegroundColor Gray
  if (-not $NoOpen) {
    Start-Process $url | Out-Null
  }
  & node $serverJs --port $resolvedPort --project-root $resolvedRoot
  exit $LASTEXITCODE
}

Write-Host "Starting Contracts UI server (background)" -ForegroundColor Cyan
Write-Host "  Project root: $resolvedRoot" -ForegroundColor Gray
Write-Host "  URL: $url" -ForegroundColor Gray

# Start-Process expects a single argument string in Windows PowerShell 5.1.
# Use PowerShell's escape character (backtick) for quoting paths with spaces.
$nodeArgString = "`"$serverJs`" --port $resolvedPort --project-root `"$resolvedRoot`""

$logDir = Join-Path $uiDir '.logs'
try { New-Item -ItemType Directory -Path $logDir -Force | Out-Null } catch {}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stdoutLog = Join-Path $logDir "contracts-ui-$stamp.out.log"
$stderrLog = Join-Path $logDir "contracts-ui-$stamp.err.log"

$proc = Start-Process -FilePath 'node' -ArgumentList $nodeArgString -WorkingDirectory $uiDir -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
Write-Host "  PID: $($proc.Id)" -ForegroundColor Gray
Write-Host "  Logs: $stderrLog" -ForegroundColor Gray

if (-not $NoHealthCheck) {
  $healthUrl = "http://127.0.0.1:$resolvedPort/api/contracts"
  $deadline = (Get-Date).AddSeconds([Math]::Max(1, $HealthCheckTimeoutSec))
  $ok = $false
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 150
    try {
      $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 $healthUrl
      if ($r.StatusCode -eq 200) { $ok = $true; break }
    } catch {
      # keep waiting
    }

    try {
      $p = Get-Process -Id $proc.Id -ErrorAction Stop
    } catch {
      break
    }
  }

  if (-not $ok) {
    Write-Host "Server failed health check: $healthUrl" -ForegroundColor Red
    try {
      if (Test-Path $stderrLog) {
        $tail = Get-Content -Path $stderrLog -Tail 60 -ErrorAction SilentlyContinue
        if ($tail) {
          Write-Host "--- stderr (tail) ---" -ForegroundColor DarkGray
          $tail | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        }
      }
    } catch {}
    exit 1
  }
}

# If this script is invoked from a host that reports $LASTEXITCODE, ensure a clean success code
# when the background process was started successfully.
$global:LASTEXITCODE = 0

if (-not $NoOpen) {
  Start-Sleep -Milliseconds 250
  Start-Process $url | Out-Null
}

# Persist discovered port (best-effort)
try {
  $out = [ordered]@{
    autoStart = $cfg.autoStart
    openBrowser = if ($cfg.openBrowser -eq $false) { $false } else { $true }
    port = $resolvedPort
    projectRoot = if ($cfg.projectRoot) { $cfg.projectRoot } else { '.' }
  } | ConvertTo-Json -Depth 4
  Set-Content -Path $ConfigPath -Value $out -Encoding UTF8
} catch {}

exit 0
