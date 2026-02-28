# Contracts Skill

**Spec-driven development with living contracts for AI-assisted coding.**

## Overview

The Contracts skill maintains alignment between user intent and implementation through a two-file system:

- **CONTRACT.md** — User-owned specification that defines what a module should do
- **CONTRACT.yaml** — AI-editable technical mapping that tracks implementation status, verification tests, and attestation

This prevents the common problem of "spec drift" where implementations gradually diverge from original requirements.

## Installation

Copy the `contracts` folder to your agent skills directory:

```
.agent/skills/contracts/
├── SKILL.md                       # Main skill definition
├── references/
│   ├── assistant-hooks/
│   │   ├── contract-preflight.md  # Preflight workflow
│   │   └── init-contracts.md      # Initialization workflow
│   └── templates/                 # CONTRACT.md templates per tier
│       ├── core.md
│       ├── feature.md
│       ├── integration.md
│       └── utility.md
└── scripts/                       # (optional, from skill/ directory)
```

## Quick Start

### Initialize a Project

Ask the AI: "Initialize contracts for this project"

### Create a Contract for a Module

Ask the AI: "Create a contract for src/features/auth"

### Check for Drift

Ask the AI: "Check contracts"

## How It Works

### The User Workflow

1. Define requirements in `CONTRACT.md`
2. AI generates matching `CONTRACT.yaml`
3. When requirements change, update `CONTRACT.md`
4. AI automatically syncs `CONTRACT.yaml` and resets attestation

### The AI Workflow

1. Before any code change, check for `CONTRACT.md`
2. Verify constraints, attestation status, and VT results
3. Flag any drift (hash mismatch) or stale attestations
4. Update `CONTRACT.yaml` when specs change
5. After implementation, update attestation with VT results

## File Formats

### CONTRACT.md (Tier-dependent line limit: 30/50/80)

```markdown
# Authentication

## Purpose
Handles user authentication to enable secure access across the application.

## Core Features
- [x] Email/password login → Test: login.test.ts
- [x] Session tokens with refresh → Test: session.test.ts
- [ ] OAuth2 (Google, GitHub)

## Constraints
- MUST: Use bcrypt with cost factor 12 for password hashing
- MUST: Expire sessions after 24h inactivity
- MUST NOT: Store passwords in plain text

## Success Criteria
- Given valid credentials, when login() is called, then returns session token within 200ms

## Verification Tests
- [x] **VT-1: Full auth round-trip with credential verification**
  - Scenario: Create user → login → use token to access protected resource
  - Action: Register with known password, login, extract token, call /api/me
  - Verify: Response contains correct user email AND token expiry > now
  - Proves: Hashing, storage, login, token generation, token validation, protected routes
```

### CONTRACT.yaml (Tier-dependent line limit: 60/100/150)

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
    tests: "./login.test.ts"

constraints:
  must:
    - "Use bcrypt with cost factor 12"
  must_not:
    - "Store passwords in plain text"

verification_tests:
  - id: "VT-1"
    name: "Full auth round-trip"
    status: passing
    test_file: "./auth.vt.test.ts"
    last_run: "2026-02-15T14:00:00Z"
    last_result: pass

attestation:
  contract_version: "1.1"
  last_verified: "2026-02-15T14:00:00Z"
  verification_tests_pass: true
  features_implemented: ["email-password-login", "session-tokens"]
  confidence: high
  next_review: "2026-03-17T14:00:00Z"

changelog:
  - date: "2026-01-29"
    change: "Initial contract"
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
Before code changes, check for CONTRACT.md. See `.agent/skills/contracts/SKILL.md`.
```

## License

MIT
