<#
.SYNOPSIS
    Automated installer that detects AI coding assistants and installs to all of them.

.DESCRIPTION
    Scans for known AI coding assistant configurations and offers to install
    the Contracts skill to each detected environment.

.PARAMETER Auto
    Automatically install to all detected agents without prompting.

.EXAMPLE
    # Interactive mode (recommended)
    irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.ps1 | iex

.EXAMPLE
    # Auto-install to all detected agents
    .\setup.ps1 -Auto
#>

& {
[CmdletBinding()]
param(
    [switch]$Auto,

    [ValidateSet('minimal-ui','php-ui','none')]
    [Alias('UI')]
    [string]$UiMode = $null,

    [switch]$InstallUI,

    [switch]$SkipUI,

    [string]$UIDir = 'contracts-ui',

    [switch]$ForceUI,

    [switch]$UpdateInstructions,

    [switch]$SkipInstructions,

    [switch]$UpdateAgentMd,

    [switch]$SkipAgentMd
)

$ErrorActionPreference = "Stop"

# Configuration
$RepoOwner = "KombiverseLabs"
$RepoName = "contracts-skill"
$Branch = "main"
$SkillName = "contracts"

# Colors for output
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    Write-Host ""
    Write-Color "========================================" Cyan
    Write-Color " Contracts Skill - Automated Installer" Cyan
    Write-Color " Spec-Driven Development for AI Assistants" Cyan
    Write-Color "========================================" Cyan
    Write-Host ""
}

# Agent detection configurations
$AgentConfigs = @(
    @{
        Name = "GitHub Copilot (VS Code)"
        Icon = "[COP]"
        Paths = @(
            (Join-Path $env:USERPROFILE ".copilot\skills\$SkillName"),
            (Join-Path $env:USERPROFILE ".github\copilot\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".copilot"),
            (Join-Path $env:APPDATA "Code\User\settings.json")
        )
        InstructionFile = ".github\copilot-instructions.md"
        InstructionSnippet = @"

## Contracts System
Before modifying any module, check for CONTRACT.md files.
Consult the ``contracts`` skill for spec-driven development workflow.
Never edit CONTRACT.md files directly - they are user-owned specifications.
When creating a new module, ask whether to create a new CONTRACT.md/CONTRACT.yaml for it (see init-agent --module).
"@
    },
    @{
        Name = "Claude Code"
        Icon = "[CLD]"
        Paths = @(
            (Join-Path $env:USERPROFILE ".claude\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".claude"),
            (Join-Path $env:APPDATA "Claude")
        )
        InstructionFile = "CLAUDE.md"
        InstructionSnippet = @"

## Contracts System
Before any code changes, check for CONTRACT.md in the target directory.
Use the contracts skill for spec-driven development.
CONTRACT.md files are user-owned - never edit them directly.
See ``.claude/skills/contracts/SKILL.md`` for full workflow.
When creating a new module, propose generating a matching contract via init-agent (use --module).
"@
    },
    @{
        Name = "Cursor"
        Icon = "[CUR]"
        Paths = @(
            (Join-Path $env:USERPROFILE ".cursor\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".cursor"),
            (Join-Path $env:APPDATA "Cursor")
        )
        InstructionFile = ".cursorrules"
        InstructionSnippet = @"

# Contracts System
Always check for CONTRACT.md before modifying code in any module.
CONTRACT.md files are user-owned specifications - never edit them.
When CONTRACT.md changes, sync the corresponding CONTRACT.yaml.
When creating a new module, propose creating a new CONTRACT.md/CONTRACT.yaml for it.
"@
    },
    @{
        Name = "Windsurf (Codeium)"
        Icon = "[WND]"
        Paths = @(
            (Join-Path $env:USERPROFILE ".windsurf\skills\$SkillName"),
            (Join-Path $env:USERPROFILE ".codeium\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".windsurf"),
            (Join-Path $env:USERPROFILE ".codeium"),
            (Join-Path $env:APPDATA "Windsurf")
        )
        InstructionFile = ".windsurfrules"
        InstructionSnippet = @"

# Contracts System
Check for CONTRACT.md before modifying any module.
CONTRACT.md = user-owned specs (never edit), CONTRACT.yaml = AI-maintained.
When creating a new module, propose creating a matching contract for it.
"@
    },
    @{
        Name = "Aider"
        Icon = "[AID]"
        Paths = @(
            (Join-Path $env:USERPROFILE ".aider\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".aider"),
            (Join-Path $env:USERPROFILE ".aider.conf.yml")
        )
        InstructionFile = $null
        InstructionSnippet = $null
    },
    @{
        Name = "Cline (VS Code)"
        Icon = "[CLN]"
        Paths = @(
            (Join-Path $env:USERPROFILE ".cline\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".cline"),
            (Join-Path $env:APPDATA "Code\User\globalStorage\saoudrizwan.claude-dev")
        )
        InstructionFile = ".clinerules"
        InstructionSnippet = @"

# Contracts System
Before code changes, check for CONTRACT.md files.
CONTRACT.md = user specs (read-only), CONTRACT.yaml = sync when MD changes.
When creating a new module, propose creating a matching contract for it.
"@
    },
    @{
        Name = "OpenCode"
        Icon = "[OPN]"
        Paths = @(
            (Join-Path $env:USERPROFILE ".opencode\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path $env:USERPROFILE ".opencode"),
            (Join-Path $env:APPDATA "OpenCode")
        )
        InstructionFile = ".opencodesettings"
        InstructionSnippet = @"

# Contracts System
Before modifying any module, check for CONTRACT.md files.
CONTRACT.md = user-owned specs (never edit), CONTRACT.yaml = AI-maintained.
When creating a new module, propose creating a matching contract for it.
"@
    },
    @{
        Name = "Custom Target Path"
        Icon = "[CUS]"
        Paths = @()
        DetectPaths = @()
        InstructionFile = $null
        InstructionSnippet = $null
        AlwaysOffer = $true
    },
    @{
        Name = "Project Local (.agent)"
        Icon = "[LOC]"
        Paths = @(
            (Join-Path (Get-Location) ".agent\skills\$SkillName")
        )
        DetectPaths = @(
            (Join-Path (Get-Location) ".agent"),
            (Join-Path (Get-Location) "package.json"),
            (Join-Path (Get-Location) ".git")
        )
        InstructionFile = $null
        InstructionSnippet = $null
        AlwaysOffer = $true
    }
)

function Test-AgentInstalled {
    param($Agent)
    
    foreach ($path in $Agent.DetectPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

function Test-SkillInstalled {
    param($Agent)
    
    foreach ($path in $Agent.Paths) {
        $skillFile = Join-Path $path "SKILL.md"
        if (Test-Path $skillFile) {
            return $path
        }
    }
    return $null
}

function Get-PreferredInstallPath {
    param($Agent)
    
    foreach ($path in $Agent.Paths) {
        $parent = Split-Path $path -Parent
        if ((Test-Path $parent) -or $Agent.AlwaysOffer) {
            return $path
        }
    }
    return $Agent.Paths[0]
}

function Test-HostInteractive {
    try {
        if (-not $Host -or -not $Host.UI -or -not $Host.UI.RawUI) { return $false }
        return $true
    } catch { return $false }
}

function Select-AgentsCheckbox {
    param(
        [array]$AllAgents,
        [hashtable]$DetectedByName,
        [hashtable]$InstalledByName
    )

    if (-not (Test-HostInteractive)) {
        Write-Color 'Interactive checkbox UI not available in this host.' Yellow
        Write-Color 'Enter selection as comma-separated names (e.g., "Claude Code,Project Local (.agent)") or "all":' Gray
        $raw = Read-Host 'Agents'
        if ($raw -match '^(all|a)$') { return $AllAgents }
        $names = $raw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        return @($AllAgents | Where-Object { $names -contains $_.Name })
    }

    $selected = @{}
    foreach ($agent in $AllAgents) {
        $selected[$agent.Name] = ($DetectedByName.ContainsKey($agent.Name) -and $DetectedByName[$agent.Name])
    }

    $cursor = 0
    $startTop = [Console]::CursorTop

    function Render {
        [Console]::SetCursorPosition(0, $startTop)
        Write-Host ''
        Write-Color 'Select agents to install to (Space=toggle, Enter=confirm, Q=quit):' White
        Write-Color 'Detected agents are preselected; you can also pick non-detected.' Gray
        Write-Host ''

        for ($i = 0; $i -lt $AllAgents.Count; $i++) {
            $agent = $AllAgents[$i]
            $isOn = $selected[$agent.Name]
            $box = if ($isOn) { '[*]' } else { '[ ]' }

            $status = if ($InstalledByName.ContainsKey($agent.Name) -and $InstalledByName[$agent.Name]) {
                'INSTALLED'
            } elseif ($DetectedByName.ContainsKey($agent.Name) -and $DetectedByName[$agent.Name]) {
                'DETECTED'
            } else {
                'NOT FOUND'
            }

            $prefix = if ($i -eq $cursor) { '>' } else { ' ' }
            $hint = if ($agent.Name -eq 'Custom Target Path') {
                ' -> prompts for target path'
            } else {
                try {
                    $p = Get-PreferredInstallPath -Agent $agent
                    " -> $p"
                } catch { '' }
            }

            $line = " $prefix $box $($agent.Icon) $($agent.Name) [$status]$hint"
            $color = if ($i -eq $cursor) { 'Cyan' } elseif ($status -eq 'DETECTED') { 'Yellow' } elseif ($status -eq 'INSTALLED') { 'Green' } else { 'Gray' }
            Write-Color $line $color
        }
        Write-Host ''
        Write-Color 'Tips: A=toggle all, D=toggle detected only, I=toggle installed only' Gray
    }

    Render

    $confirmed = $false
    while (-not $confirmed) {
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        switch ($key.VirtualKeyCode) {
            38 { if ($cursor -gt 0) { $cursor-- } Render } # Up
            40 { if ($cursor -lt ($AllAgents.Count - 1)) { $cursor++ } Render } # Down
            32 {
                $agent = $AllAgents[$cursor]
                $selected[$agent.Name] = -not $selected[$agent.Name]
                Render
            }
            65 {
                $anyOff = $false
                foreach ($agent in $AllAgents) {
                    if (-not $selected[$agent.Name]) { $anyOff = $true; break }
                }
                foreach ($agent in $AllAgents) { $selected[$agent.Name] = $anyOff }
                Render
            }
            68 {
                foreach ($agent in $AllAgents) {
                    if ($DetectedByName.ContainsKey($agent.Name) -and $DetectedByName[$agent.Name]) {
                        $selected[$agent.Name] = -not $selected[$agent.Name]
                    }
                }
                Render
            }
            73 {
                foreach ($agent in $AllAgents) {
                    if ($InstalledByName.ContainsKey($agent.Name) -and $InstalledByName[$agent.Name]) {
                        $selected[$agent.Name] = -not $selected[$agent.Name]
                    }
                }
                Render
            }
            13 { $confirmed = $true } # Enter
            81 { return @() } # Q
        }
    }

    return @($AllAgents | Where-Object { $selected[$_.Name] })
}

function Add-InstructionHook {
    param(
        [hashtable]$Agent,
        [string]$ProjectPath
    )

    if (-not $Agent.InstructionFile -or -not $Agent.InstructionSnippet) {
        return
    }

    $instructionPath = Join-Path $ProjectPath $Agent.InstructionFile

    if (Test-Path $instructionPath) {
        $content = Get-Content $instructionPath -Raw
        if ($content -notmatch 'Contracts System') {
            Add-Content -Path $instructionPath -Value $Agent.InstructionSnippet
            Write-Color "    -> Added hook to $($Agent.InstructionFile)" Gray
            return
        }

        if ($content -notmatch 'When (creating|adding) a new module') {
            $lines = $Agent.InstructionSnippet -split "`r?`n" | Where-Object { $_ -match 'When (creating|adding) a new module' }
            if ($lines -and $lines.Count -gt 0) {
                Add-Content -Path $instructionPath -Value ("`n" + ($lines -join "`n") + "`n")
                Write-Color "    -> Updated $($Agent.InstructionFile)" Gray
            }
        }
    } else {
        $dir = Split-Path $instructionPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Set-Content -Path $instructionPath -Value $Agent.InstructionSnippet.Trim()
        Write-Color "    -> Created $($Agent.InstructionFile)" Gray
    }
}

function Update-AgentMarkdown {
    param([string]$ProjectPath)

    $agentMdPath = Join-Path $ProjectPath 'agent.md'
    $snippet = @"

## Contracts System
When creating a new module, ask whether to create a matching CONTRACT.md/CONTRACT.yaml using the contracts init tool (e.g., `node .github/skills/contracts/ai/init-agent/index.js --module ./path/to/module --yes`).
"@

    if (Test-Path $agentMdPath) {
        $content = Get-Content $agentMdPath -Raw
        if ($content -notmatch '##\s+Contracts System') {
            Add-Content -Path $agentMdPath -Value $snippet
            Write-Color '    -> Updated agent.md' Gray
        }
    } else {
        Set-Content -Path $agentMdPath -Value ($snippet.Trim())
        Write-Color '    -> Created agent.md' Gray
    }
}

function Install-SkillToAgent {
    param(
        [string]$TargetPath,
        [string]$SourcePath
    )
    
    $parent = Split-Path $TargetPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    
    if (Test-Path $TargetPath) {
        Remove-Item -Recurse -Force $TargetPath
    }
    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
    
    return (Test-Path (Join-Path $TargetPath "SKILL.md"))
}

function Get-SkillSource {
    param([string]$TempDir)
    
    Write-Color "Downloading skill from GitHub..." Yellow
    
    # Try git clone first
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            git clone --quiet --depth 1 --branch $Branch "https://github.com/$RepoOwner/$RepoName.git" $TempDir 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path $TempDir)) {
                Write-Color "Downloaded via git" Green
                return Join-Path $TempDir "skill"
            }
        }
        catch {
            Write-Color "Git clone failed, trying ZIP fallback..." Yellow
        }
    }
    
    # Fallback to ZIP
    Write-Color "Downloading ZIP archive..." Yellow
    $zipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
    $zipPath = Join-Path $env:TEMP "contracts-skill.zip"
    
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $TempDir -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue
        
        $extractedFolder = Get-ChildItem $TempDir -Directory | Select-Object -First 1
        if (-not $extractedFolder) {
            throw "ZIP extraction failed - no directory found in $TempDir"
        }
        Write-Color "Downloaded via ZIP" Green
        
        return Join-Path $extractedFolder.FullName "skill"
    }
    catch {
        throw "Failed to download skill from GitHub: $_"
    }
}

function Test-IsContractsSkillRepo {
    param([string]$Path)
    return (Test-Path (Join-Path $Path 'skill\SKILL.md')) -and (Test-Path (Join-Path $Path 'installers\install.ps1')) -and (Test-Path (Join-Path $Path 'setup.ps1'))
}

function Install-ContractsUI {
    param(
        [Parameter(Mandatory = $true)][string]$SkillSource,
        [Parameter(Mandatory = $true)][ValidateSet('minimal-ui','php-ui')][string]$UiType,
        [string]$TargetDir = 'contracts-ui',
        [switch]$Force
    )

    $uiSource = if ($UiType -eq 'php-ui') {
        Join-Path $SkillSource 'ui\contracts-ui'
    } else {
        Join-Path $SkillSource 'ui\minimal-ui'
    }

    if (-not (Test-Path $uiSource)) {
        Write-Color "Contracts UI not found in downloaded skill: $uiSource" Yellow
        return $false
    }

    $dest = Join-Path (Get-Location) $TargetDir

    if ((Test-IsContractsSkillRepo -Path (Get-Location)) -and ($TargetDir -eq 'contracts-ui') -and -not $Force) {
        Write-Color "Refusing to install Contracts UI into the contracts-skill repository itself." Yellow
        Write-Color "Tip: use -UIDir test-installation-project\contracts-ui (or pass -ForceUI to override)." Gray
        return $false
    }

    if ((Test-Path $dest) -and -not $Force) {
        Write-Color "Contracts UI already exists at .\$TargetDir (use -ForceUI to overwrite)." Yellow
        return $false
    }

    if (Test-Path $dest) {
        Remove-Item -Recurse -Force $dest
    }
    Copy-Item -Path $uiSource -Destination $dest -Recurse -Force

    function Write-ContractsBundle {
        param(
            [string]$ProjectRoot,
            [string]$UiDir
        )

        function Get-Sha256Text([string]$Text) {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Text)
                $hash = $sha.ComputeHash($bytes)
                return -join ($hash | ForEach-Object { $_.ToString('x2') })
            }
            finally {
                $sha.Dispose()
            }
        }

        function Get-RelPath([string]$Base, [string]$Full) {
            $b = (Resolve-Path $Base).Path
            $f = (Resolve-Path $Full).Path
            if ($f.Length -le $b.Length) { return '' }
            return ($f.Substring($b.Length).TrimStart('\\','/') -replace '\\','/')
        }

        function Get-YamlSourceHash([string]$YamlText) {
            $m = [regex]::Match($YamlText, '^\s*source_hash\s*:\s*("?)([^"\r\n#]+)\1\s*(?:#.*)?$', 'IgnoreCase,Multiline')
            if ($m.Success) { return $m.Groups[2].Value.Trim() }
            return $null
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
            if (-not $map.ContainsKey($dir)) { $map[$dir] = @{ dir = $dir } }
            $map[$dir].md_path = Get-RelPath $root $f.FullName
            $map[$dir].md_text = Get-Content $f.FullName -Raw
            $map[$dir].md_hash = (Get-Sha256Text $map[$dir].md_text)
        }
        foreach ($f in $yamlFiles) {
            $dir = Get-RelPath $root $f.Directory.FullName
            if ($dir -eq '') { $dir = '.' }
            if (-not $map.ContainsKey($dir)) { $map[$dir] = @{ dir = $dir } }
            $map[$dir].yaml_path = Get-RelPath $root $f.FullName
            $map[$dir].yaml_text = Get-Content $f.FullName -Raw
            $map[$dir].yaml_source_hash = Get-YamlSourceHash $map[$dir].yaml_text
        }

        $contracts = @($map.Values | Sort-Object dir)
        $bundle = [ordered]@{
            generated_at = (Get-Date).ToUniversalTime().ToString('o')
            project_root  = '.'
            contracts     = $contracts
        }
        $json = $bundle | ConvertTo-Json -Depth 6
        $js = "window.__CONTRACTS_BUNDLE__ = $json;"
        Set-Content -Path (Join-Path $UiDir 'contracts-bundle.js') -Value $js -Encoding UTF8
    }

    if ($UiType -eq 'php-ui') {
        if (Test-Path (Join-Path $dest 'index.php')) {
            Write-Color "Installed Contracts UI (php-ui) -> .\$TargetDir" Green
            Write-Color "Run: php -S localhost:8080 -t $TargetDir" Gray
            return $true
        }
        Write-Color "UI install failed: missing index.php" Red
        return $false
    }

    if (Test-Path (Join-Path $dest 'index.html')) {
        try { Write-ContractsBundle -ProjectRoot (Get-Location) -UiDir $dest } catch { Write-Color "Warning: failed to generate contracts-bundle.js ($_)" Yellow }
        Write-Color "Installed Contracts UI (minimal-ui) -> .\$TargetDir" Green
        Write-Color "Open: $TargetDir\index.html (auto-loads this project)" Gray
        return $true
    }

    Write-Color "UI install failed: missing index.html" Red
    return $false
}

# Main installation flow
Write-Header

# Detect agents
Write-Color "Scanning for AI coding assistants..." Cyan
Write-Host ""

$detectedAgents = @()
$installedAgents = @()

$detectedByName = @{}
$installedByName = @{}
$allOfferAgents = @($AgentConfigs)

foreach ($agent in $AgentConfigs) {
    $isInstalled = Test-AgentInstalled -Agent $agent
    $existingPath = Test-SkillInstalled -Agent $agent

    if ($agent.Name -eq 'Custom Target Path') {
        Write-Color "  $($agent.Icon) $($agent.Name): [OPTION]" 'Gray'
        continue
    }
    
    $status = if ($existingPath) {
        $installedAgents += @{ Agent = $agent; Path = $existingPath }
        $installedByName[$agent.Name] = $true
        "[INSTALLED]"
    } elseif ($isInstalled -or $agent.AlwaysOffer) {
        $detectedAgents += $agent
        $detectedByName[$agent.Name] = $true
        "[DETECTED]"
    } else {
        "[NOT FOUND]"
    }
    
    $color = switch ($status) {
        "[INSTALLED]" { "Green" }
        "[DETECTED]" { "Yellow" }
        default { "Gray" }
    }
    
    Write-Color "  $($agent.Icon) $($agent.Name): $status" $color
}

Write-Host ""

# Show already installed
if ($installedAgents.Count -gt 0) {
    Write-Color "Already installed:" Green
    foreach ($item in $installedAgents) {
        Write-Color "  v $($item.Agent.Name) -> $($item.Path)" Gray
    }
    Write-Host ""
}


$selectedAgents = @()

if ($Auto) {
    if ($detectedAgents.Count -eq 0) {
        Write-Color "No detected agents found." Yellow
        Write-Host ""
        Write-Color "Tip: Run this in a project directory to install locally to .agent/skills/" Cyan
        return
    }
    foreach ($agent in $detectedAgents) {
        $selectedAgents += @{ Agent = $agent; Path = (Get-PreferredInstallPath -Agent $agent) }
    }
} else {
    $chosenAgents = Select-AgentsCheckbox -AllAgents $allOfferAgents -DetectedByName $detectedByName -InstalledByName $installedByName
    if ($chosenAgents.Count -eq 0) {
        Write-Color "No agents selected." Yellow
        return
    }

    foreach ($agent in $chosenAgents) {
        if ($agent.Name -eq 'Custom Target Path') {
            $raw = Read-Host 'Enter custom target directory for the skill (e.g., C:\\path\\to\\skills\\contracts)'
            if (-not $raw) { continue }
            $selectedAgents += @{ Agent = $agent; Path = $raw.Trim() }
        } else {
            $selectedAgents += @{ Agent = $agent; Path = (Get-PreferredInstallPath -Agent $agent) }
        }
    }
}

if ($selectedAgents.Count -eq 0) {
    Write-Color "No agents selected." Yellow
    return
}

Write-Host ""
Write-Color "Installing to $($selectedAgents.Count) agent(s)..." Cyan

# Download skill once
$tempDir = Join-Path $env:TEMP "contracts-skill-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    $skillSource = Get-SkillSource -TempDir $tempDir
    
    if (-not (Test-Path $skillSource)) {
        throw "Skill source not found at: $skillSource"
    }
    
    Write-Host ""
    
    # Install to each selected agent
    $successCount = 0

    $projectPath = Get-Location

    # Ask once whether to update project instruction hooks
    $shouldUpdateInstructions = $UpdateInstructions
    if (-not $UpdateInstructions -and -not $SkipInstructions) {
        try {
            $resp = Read-Host 'Update project instruction files (CLAUDE.md, .github/copilot-instructions.md, etc.)? (y/N)'
            if ($resp -match '^(y|yes)$') { $shouldUpdateInstructions = $true }
        } catch { }
    }
    
    foreach ($item in $selectedAgents) {
        $agent = $item.Agent
        $targetPath = $item.Path
        
        Write-Host "  Installing to $($agent.Name)..." -NoNewline
        
        try {
            $success = Install-SkillToAgent -TargetPath $targetPath -SourcePath $skillSource
            
            if ($success) {
                Write-Color " v" Green
                $successCount++

                if ($shouldUpdateInstructions) {
                    Add-InstructionHook -Agent $agent -ProjectPath $projectPath
                }
            } else {
                Write-Color " x Failed" Red
            }
        } catch {
            Write-Color " x Error: $($_.Exception.Message)" Red
        }
    }
    
    Write-Host ""
    Write-Color "========================================" Cyan
    Write-Color " Installation Complete: $successCount/$($selectedAgents.Count) agents" $(if ($successCount -eq $selectedAgents.Count) { "Green" } else { "Yellow" })
    Write-Color "========================================" Cyan
    
    Write-Host ""
    Write-Color "Next steps:" Yellow
    Write-Host "  1. Open a project and run: " -NoNewline
    Write-Color "init contracts" Cyan
    Write-Host "  2. Or ask your AI: " -NoNewline
    Write-Color '"Initialize contracts for this project"' Cyan
    Write-Host ""

    # Optional: install the web UI into the current project
    $uiType = $null
    if ($UiMode) { $uiType = $UiMode }
    elseif ($InstallUI) { $uiType = 'minimal-ui' }

    if (-not $uiType -and -not $SkipUI -and (Test-IsContractsSkillRepo -Path (Get-Location))) {
        Write-Color "Note: running inside the contracts-skill repo; skipping UI install prompt." Gray
        $uiType = 'none'
    }

    if (-not $uiType -and -not $SkipUI -and -not $Auto) {
        Write-Host "Install Contracts Web UI into this project?"
        Write-Host "  [1] minimal-ui (browser-only)"
        Write-Host "  [2] php-ui     (PHP)"
        Write-Host "  [3] none"
        $uiAnswer = Read-Host "Selection (default: 3)"
        $uiType = switch ($uiAnswer) {
            '1' { 'minimal-ui' }
            '2' { 'php-ui' }
            default { 'none' }
        }
    }

    if ($uiType -and $uiType -ne 'none') {
        Install-ContractsUI -SkillSource $skillSource -UiType $uiType -TargetDir $UIDir -Force:$ForceUI | Out-Null
        Write-Host ""
    }

    # Optional: update agent.md with a short usage note
    $shouldUpdateAgentMd = $UpdateAgentMd
    if (-not $UpdateAgentMd -and -not $SkipAgentMd -and -not $Auto) {
        try {
            $resp = Read-Host 'Create/update agent.md in this project with a contracts usage note? (y/N)'
            if ($resp -match '^(y|yes)$') { $shouldUpdateAgentMd = $true }
        } catch { }
    }
    if ($shouldUpdateAgentMd) {
        Update-AgentMarkdown -ProjectPath $projectPath
    }
    
} finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}

} @args
