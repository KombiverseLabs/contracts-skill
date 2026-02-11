# Contracts Skill (Base Variant)

**Spec-driven development with living contracts for AI-assisted coding.**

This is the **base variant** with instruction-based (advisory) enforcement. For dependency-blocking enforcement via Beads, see [`../skill-beads/`](../skill-beads/).

## Overview

The Contracts skill maintains alignment between user intent and implementation through a two-file system:

- **CONTRACT.md** — User-owned specification that defines what a module should do
- **CONTRACT.yaml** — AI-editable technical mapping that tracks implementation status

This prevents spec drift where implementations gradually diverge from original requirements.

## Structure

```
skill/
├── SKILL.md                          # Skill definition (base variant)
├── references/
│   ├── assistant-hooks/
│   │   ├── contract-preflight.md     # Preflight check workflow
│   │   └── init-contracts.md         # Initialization workflow
│   └── templates/                    # CONTRACT.md templates per tier
│       ├── core.md
│       ├── feature.md
│       ├── integration.md
│       └── utility.md
├── scripts/
│   ├── init-contracts.ps1            # Project initialization
│   ├── validate-contracts.ps1        # CI/CD validation
│   ├── contract-preflight.ps1        # Preflight check for changed files
│   └── compute-hash.ps1             # SHA256 hash utility
├── ai/init-agent/                    # Semantic project analyzer (Node.js)
└── ui/
    ├── minimal-ui/                   # Lightweight HTML/JS UI
    └── contracts-ui/                 # Full PHP-based UI
```

## Quick Start

### Initialize a Project

Ask your AI assistant:
> "Initialize contracts for this project"

Or run the script:
```powershell
pwsh scripts/init-contracts.ps1 -Path .
```

### Create a Contract for a Module

Ask the AI: "Create a contract for src/features/auth"

### Check for Drift

```powershell
pwsh scripts/validate-contracts.ps1 -Path .
```

## CI/CD Integration

```yaml
- name: Validate Contracts
  run: pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -OutputFormat github-actions
```

## License

MIT
