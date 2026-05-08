# Installation Guide

The Contracts skill uses standards-first installation: clone or download this repo, copy `skill/` to a skill directory, and optionally install a short project instruction hook.

## One-Line Install

PowerShell:

```powershell
irm https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.ps1 | iex
```

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.sh | bash
```

Default target:

- `$CODEX_HOME/skills/contracts` when `CODEX_HOME` is set
- otherwise `~/.codex/skills/contracts`

## Explicit Target

PowerShell:

```powershell
.\installers\install.ps1 -TargetPath "$env:USERPROFILE\.codex\skills\contracts"
```

Bash:

```bash
./installers/install.sh --target ~/.codex/skills/contracts
```

## Compatibility Profiles

Profiles are path aliases. They do not depend on agent detection.

| Profile | Target |
|---------|--------|
| `codex` | `$CODEX_HOME/skills/contracts` or `~/.codex/skills/contracts` |
| `claude` | `~/.claude/skills/contracts` |
| `copilot` | `~/.copilot/skills/contracts` |
| `cursor` | `~/.cursor/skills/contracts` |
| `local` | `./.agent/skills/contracts` |

PowerShell:

```powershell
.\installers\install.ps1 -Profiles "codex,local"
```

Bash:

```bash
./installers/install.sh --profiles codex,local
```

Legacy `-Agents` / `--agents` maps to profiles.

## Hooks

By default, the installer writes a compact Contracts hook to `AGENTS.md` in the current project.

Modes:

- `auto`: use Beads hook when `.beads/` exists, otherwise base hook
- `base`: standard contract preflight hook
- `beads`: Beads-enforced contract preflight hook
- `none`: do not write hooks

PowerShell:

```powershell
.\installers\install.ps1 -Hooks auto
.\installers\install.ps1 -Hooks beads -LegacyHooks
```

Bash:

```bash
./installers/install.sh --hooks auto
./installers/install.sh --hooks beads --legacy-hooks
```

`-LegacyHooks` / `--legacy-hooks` mirrors the same hook to `CLAUDE.md`, `codex.md`, `.github/copilot-instructions.md`, and `.cursor/rules/contracts-system.mdc`.

The installer does not create `.contracts/`, does not install `contracts-ui/`, and does not ask project setup questions. Say `init contracts` to let the agent initialize project contracts after installation.

## Manual Installation

```bash
git clone --depth 1 https://github.com/kombifyio/contracts-skill.git /tmp/contracts-skill
mkdir -p ~/.codex/skills/contracts
cp -R /tmp/contracts-skill/skill/. ~/.codex/skills/contracts/
test -f ~/.codex/skills/contracts/SKILL.md && echo OK
```

PowerShell:

```powershell
git clone --depth 1 https://github.com/kombifyio/contracts-skill.git "$env:TEMP\contracts-skill"
$target = Join-Path $env:USERPROFILE ".codex\skills\contracts"
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path "$env:TEMP\contracts-skill\skill\*" -Destination $target -Recurse -Force
Test-Path (Join-Path $target "SKILL.md")
```

## Development Install

From this repository:

```powershell
.\installers\install.ps1 -UseLocalSource -TargetPath "$env:TEMP\contracts-skill-test" -Hooks none
```

```bash
./installers/install.sh --local --target /tmp/contracts-skill-test --hooks none
```
