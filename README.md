# Contracts Skill

Spec-driven development with living contracts for AI-assisted coding.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Works with: Skills](https://img.shields.io/badge/Works%20with-Agent%20Skills-blue)](#installation)

Contracts keep code changes aligned with durable module specs:

- `CONTRACT.md` is the human-owned specification.
- `CONTRACT.yaml` is the AI-maintained technical mapping for hashes, status, VTs, acceptance tests, and attestation.
- A contract preflight checks drift and constraints before implementation.

## Installation

Recommended: install to a standard skill directory, then optionally add the project hook.

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

Explicit target:

```powershell
.\installers\install.ps1 -TargetPath "$env:USERPROFILE\.codex\skills\contracts"
```

```bash
./installers/install.sh --target ~/.codex/skills/contracts
```

Compatibility profiles:

```powershell
.\installers\install.ps1 -Profiles "codex,local"
```

```bash
./installers/install.sh --profiles codex,local
```

Profiles map to `codex`, `claude`, `copilot`, `cursor`, and `local`. Legacy `-Agents` / `--agents` is accepted as an alias for profiles; the installer no longer auto-detects IDEs or agents.

## Instruction Hooks

The installer writes a compact hook to the current project's `AGENTS.md` by default:

```bash
./installers/install.sh --hooks base
./installers/install.sh --hooks beads
./installers/install.sh --hooks none
```

`--hooks auto` is the default. It uses the Beads hook when `.beads/` exists, otherwise the base hook.

To also mirror the same hook into legacy files (`CLAUDE.md`, `codex.md`, `.github/copilot-instructions.md`, `.cursor/rules/contracts-system.mdc`):

```bash
./installers/install.sh --legacy-hooks
```

Hooks are idempotent and wrapped in `contracts-skill:start` / `contracts-skill:end` markers.

## Usage

Ask the agent:

> init contracts

The workflow is agent-led:

1. Read `.contracts/CONTRACTS-GUIDE.md` if it exists.
2. Inspect manifests, source layout, tests, exports, and existing contracts.
3. Recommend contract locations.
4. Draft `CONTRACT.md`, `CONTRACT.yaml`, registry, and project guide changes.
5. Write files only after explicit user approval.

Before code changes, ask:

> contract preflight

The agent finds the nearest `CONTRACT.md`, compares `CONTRACT.yaml` `meta.source_hash`, checks constraints, VT status, acceptance tests, attestation, and affected dependents, then summarizes the relevant contract notes.

## Beads Mode

Beads is now an optional enforcement mode of the main `contracts` skill, not a separate installable skill. In projects with `.beads/` and the `bd` CLI, use `--hooks beads` or `--hooks auto`. The skill loads `references/beads-enforcement.md` for the Beads task lifecycle.

## Validation

```powershell
pwsh skill/scripts/validate-contracts.ps1 -Path ./examples/sample-project
pwsh skill/scripts/contract-preflight.ps1 -Path . -Changed
```

The optional init helper is read-only by default:

```bash
node skill/ai/init-agent/index.js --path . --analyze
node skill/ai/init-agent/index.js --path . --dry-run
node skill/ai/init-agent/index.js --path . --apply --yes
```

`--apply` refuses to write without `--yes`.

## Repository Structure

```text
contracts-skill/
├── skill/
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   ├── references/
│   │   ├── assistant-hooks/
│   │   ├── instruction-hooks/
│   │   ├── templates/
│   │   ├── examples/
│   │   └── beads-enforcement.md
│   ├── scripts/
│   ├── ai/init-agent/
│   └── ui/minimal-ui/
├── installers/
└── examples/
```

## License

MIT © kombifyio
