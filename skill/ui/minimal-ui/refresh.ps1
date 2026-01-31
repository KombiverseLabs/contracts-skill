param(
  [string]$ProjectRoot = $null
)

$ErrorActionPreference = 'Stop'

function Get-RelPath([string]$Base, [string]$Full) {
  $b = (Resolve-Path $Base).Path
  $f = (Resolve-Path $Full).Path
  if ($f.Length -le $b.Length) { return '' }
  return ($f.Substring($b.Length).TrimStart('\','/') -replace '\\','/')
}

function Get-YamlSourceHash([string]$YamlText) {
  $m = [regex]::Match($YamlText, '^\s*source_hash\s*:\s*("?)([^"\r\n#]+)\1\s*(?:#.*)?$', 'IgnoreCase,Multiline')
  if ($m.Success) { return $m.Groups[2].Value.Trim() }
  return $null
}

if (-not $ProjectRoot) {
  # Default: assume installed at <project>/contracts-ui; project root is the parent folder.
  $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

  # If this is running inside a git repo, prefer the nearest git root.
  $probe = (Resolve-Path $PSScriptRoot).Path
  for ($i = 0; $i -lt 15; $i++) {
    if (Test-Path (Join-Path $probe '.git')) {
      $ProjectRoot = $probe
      break
    }
    $parent = Split-Path -Parent $probe
    if (-not $parent -or $parent -eq $probe) { break }
    $probe = $parent
  }
}

$root = (Resolve-Path $ProjectRoot).Path
$ignore = @('.git','node_modules','vendor','.idea','.vscode','.agent','dist','build','out','.next','coverage','contracts-ui')

$mdFiles = Get-ChildItem -Path $root -Recurse -Filter 'CONTRACT.md' -File -ErrorAction SilentlyContinue |
  Where-Object { $ignore -notcontains $_.Directory.Name }
$yamlFiles = Get-ChildItem -Path $root -Recurse -Filter 'CONTRACT.yaml' -File -ErrorAction SilentlyContinue |
  Where-Object { $ignore -notcontains $_.Directory.Name }

$map = @{}
foreach ($f in $mdFiles) {
  $dir = Get-RelPath $root $f.Directory.FullName
  if ($dir -eq '') { $dir = '.' }
  if (-not $map.ContainsKey($dir)) { $map[$dir] = @{ dir=$dir } }
  $map[$dir].md_path = Get-RelPath $root $f.FullName
  $map[$dir].md_text = Get-Content $f.FullName -Raw
  $map[$dir].md_hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash.ToLower()
}
foreach ($f in $yamlFiles) {
  $dir = Get-RelPath $root $f.Directory.FullName
  if ($dir -eq '') { $dir = '.' }
  if (-not $map.ContainsKey($dir)) { $map[$dir] = @{ dir=$dir } }
  $map[$dir].yaml_path = Get-RelPath $root $f.FullName
  $map[$dir].yaml_text = Get-Content $f.FullName -Raw
  $map[$dir].yaml_source_hash = Get-YamlSourceHash $map[$dir].yaml_text
}

$contracts = @($map.Values | Sort-Object dir)
$bundle = [ordered]@{
  generated_at = (Get-Date).ToUniversalTime().ToString('o')
  project_root = '.'
  contracts = $contracts
}

$json = $bundle | ConvertTo-Json -Depth 6
$js = "window.__CONTRACTS_BUNDLE__ = $json;"

$targetDir = $PSScriptRoot
Set-Content -Path (Join-Path $targetDir 'contracts-bundle.js') -Value $js -Encoding UTF8
Write-Host "Wrote: $((Join-Path $targetDir 'contracts-bundle.js'))"
