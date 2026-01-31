# Contracts Skill

**Spec-driven development with living contracts for AI-assisted coding.**

## Overview

The Contracts skill maintains alignment between user intent and implementation through a two-file system:

- **CONTRACT.md** — User-owned specification that defines what a module should do
- **CONTRACT.yaml** — AI-editable technical mapping that tracks implementation status

This prevents the common problem of "spec drift" where implementations gradually diverge from original requirements.

## Installation

Copy the `contracts` folder to your agent skills directory:

```
.github/skills/contracts/
├── SKILL.md                 # Main skill definition
├── references/
│   ├── initialization.md    # Full init workflow
│   ├── cheatsheet.md        # Quick reference
│   └── templates/           # File templates
└── scripts/
    ├── init-contracts.ps1   # Project initialization
  ├── init-contracts.sh    # Project initialization (bash)
    ├── validate-contracts.ps1  # CI/CD validation
    └── compute-hash.ps1     # Hash utility
```

## Quick Start

### Initialize a Project

```
init contracts
```

Or run the PowerShell script:

```powershell
.\.agent\skills\contracts\scripts\init-contracts.ps1 -Path "."
```

Or run the Bash script:

```bash
./.github/skills/contracts/scripts/init-contracts.sh --path .
```

### Create a Contract for a Module

Ask the AI: "Create a contract for src/features/auth"

### Check for Drift

Ask the AI: "Check contracts" or run:

```powershell
.\.agent\skills\contracts\scripts\validate-contracts.ps1
```

## How It Works

### The User Workflow

1. Define requirements in `CONTRACT.md`
2. AI generates matching `CONTRACT.yaml`
3. When requirements change, update `CONTRACT.md`
4. AI automatically syncs `CONTRACT.yaml`

### The AI Workflow

1. Before any code change, check for `CONTRACT.md`
2. Verify planned changes align with constraints
3. Flag any drift (hash mismatch)
4. Update `CONTRACT.yaml` when specs change

## File Formats

### CONTRACT.md (Max 50 lines)

```markdown
# Authentication

## Purpose
Handles user login, logout, and session management.

## Core Features
- [ ] Email/password login
- [ ] Session tokens with refresh
- [ ] OAuth2 (Google, GitHub)

## Constraints
- MUST: Use bcrypt for password hashing
- MUST: Expire sessions after 24h
- MUST NOT: Store passwords in plain text

## Success Criteria
Users can log in and maintain sessions across page reloads.
```

### CONTRACT.yaml (Max 100 lines)

```yaml
meta:
  source_hash: "sha256:abc123..."
  last_sync: "2026-01-29T10:00:00Z"
  tier: core
  version: "1.1"

module:
  name: "auth"
  type: "core"
  path: "src/core/auth"

features:
  - id: "email-password-login"
    status: implemented
    entry_point: "./login.ts"
    
  - id: "oauth2"
    status: planned
    notes: "Waiting for API keys"

constraints:
  must:
    - "Use bcrypt for password hashing"
    - "Expire sessions after 24h"
  must_not:
    - "Store passwords in plain text"

changelog:
  - date: "2026-01-29"
    change: "Added OAuth2 requirement"
```

## Integration

Add to your IDE instruction files:

**`.github/copilot-instructions.md`:**
```markdown
## Contracts
Consult `contracts` skill before modifying any module. Check for CONTRACT.md files.
```

**`CLAUDE.md`:**
```markdown
## Contracts System
Before code changes, check for CONTRACT.md. See `.github/skills/contracts/SKILL.md`.
```

## CI/CD Integration

Add to your pipeline:

```yaml
- name: Validate Contracts
  run: |
    pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -OutputFormat github-actions
```

## License

MIT
