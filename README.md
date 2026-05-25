# Contracts Skill

Spec-driven development with living contracts for AI-assisted coding.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Works with: Skills](https://img.shields.io/badge/Works%20with-Agent%20Skills-blue)](#installation)

Contracts keep code changes aligned with durable module specs:

- `CONTRACT.md` is the human-owned specification.
- `CONTRACT.yaml` is the AI-maintained technical mapping for hashes, status, VTs, acceptance tests, and attestation.
- A contract preflight checks drift and constraints before implementation.
- The default lifecycle is Spec-Kit-inspired without requiring `specify`: Specify -> Clarify -> Plan -> Test First -> Implement -> Verify -> Attest.
- New or migrated contracts use traceability IDs: `F-001`, `REQ-001`, `AC-001`, `AT-001`, and `VT-001`.

## Installation

Run one installer from the project where you want the Contracts hook:

PowerShell:

```powershell
irm https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.ps1 | iex
```

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.sh | bash
```

This installs to `$CODEX_HOME/skills/contracts` when set, otherwise `~/.codex/skills/contracts`, and writes an idempotent `AGENTS.md` hook in the current project. Advanced options for explicit targets, compatibility profiles, hook modes, legacy hook mirrors, and local-source installs remain available in [INSTALL.md](INSTALL.md).

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

## Contract Lock Mode

Approved `CONTRACT.md` files can be locked as read-only guardrails for agents:

```bash
skill/scripts/lock-contracts.sh --path .
skill/scripts/unlock-contracts.sh --file src/core/auth/CONTRACT.md
```

PowerShell equivalents are available as `skill/scripts/lock-contracts.ps1` and `skill/scripts/unlock-contracts.ps1`. `CONTRACT.yaml` stays writable by default for hash, VT, and attestation syncs.

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
│   │   ├── project-guide.md
│   │   ├── constitution.md
│   │   ├── spec-driven-methodology.md
│   │   ├── contract-locking.md
│   │   └── beads-enforcement.md
│   ├── scripts/
│   ├── ai/init-agent/
│   └── ui/minimal-ui/
├── installers/
└── examples/
```

## Thanks

Special thanks to [Beads](https://github.com/gastownhall/beads), the `bd` framework for agent-friendly issue tracking and task graphs. It is a great framework and one we genuinely enjoy using for AI-assisted development workflows.

## License

MIT © kombifyio
