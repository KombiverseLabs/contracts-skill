# Contracts Skill

> **Spec-driven development with living contracts for AI-assisted coding.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Works with: Copilot](https://img.shields.io/badge/Works%20with-GitHub%20Copilot-blue)](https://github.com/features/copilot)
[![Works with: Claude](https://img.shields.io/badge/Works%20with-Claude-orange)](https://claude.ai)
[![Works with: Cursor](https://img.shields.io/badge/Works%20with-Cursor-purple)](https://cursor.sh)

Keep your AI coding assistant aligned with your specifications. Never let implementations drift from requirements again.

---

## Quick Install

### Manual Installation

```bash
# Clone to your project
git clone https://github.com/KombiverseLabs/contracts-skill.git .contracts-skill-temp
cp -r .contracts-skill-temp/skill/ .agent/skills/contracts/
rm -rf .contracts-skill-temp

# Or clone globally
git clone https://github.com/KombiverseLabs/contracts-skill.git ~/.copilot/skills/contracts
```

### Simple One-Liner (Single Location)

**PowerShell:**
```powershell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex
```

**Bash/Zsh:**
```bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash
```

### Automated Installer (Recommended)

Automatically detects all your AI coding assistants and installs to each one:

**PowerShell:**
```powershell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.ps1 | iex
```

**Bash/Zsh:**
```bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.sh | bash
```

This will:
- Scan for installed AI assistants (Copilot, Claude, Cursor, Windsurf, Cline, Aider)
- Let you select which ones to install to
- Also offer project-local installation

---

## What Is This?

The Contracts skill solves **spec drift** — the gradual divergence between what you wanted to build and what actually gets built during long AI-assisted coding sessions.

### The Problem

```
Day 1: "Build auth with email login and OAuth"
Day 5: "Why does this have SMS verification? I never asked for that..."
Day 10: "Where did the OAuth integration go?!"
```

### The Solution

Every module gets two files:

| File | Owner | Purpose |
|------|-------|---------|
| `CONTRACT.md` | **You** (human) | Define what you want |
| `CONTRACT.yaml` | **AI** (synced) | Track implementation status |

The AI **cannot edit** your CONTRACT.md — it's your source of truth. When you change requirements, the AI syncs the technical spec automatically.

---

## How It Works

### 1. You Define the Contract

```markdown
# Authentication

## Purpose
Handle user login and session management.

## Core Features
- [ ] Email/password login
- [ ] OAuth2 (Google, GitHub)
- [ ] Session tokens

## Constraints
- MUST: Use bcrypt for passwords
- MUST NOT: Store plain text passwords
```

### 2. AI Generates Technical Spec

```yaml
meta:
  source_hash: "sha256:abc123..."  # Drift detection
  
features:
  - id: "email-login"
    status: implemented
  - id: "oauth2"
    status: planned
```

### 3. Changes Stay Synchronized

When you update CONTRACT.md, the AI:
1. Detects the change (hash mismatch)
2. Syncs CONTRACT.yaml
3. Logs the change

---

## Quick Start

### Initialize Your Project

```powershell
# After installation, run:
.agent/skills/contracts/scripts/init-contracts.ps1 -Path "."
```

Or ask your AI assistant: **"Initialize contracts for this project"**

### Check for Drift

```powershell
.agent/skills/contracts/scripts/validate-contracts.ps1
```

Or ask: **"Check contracts"**

---

## Project Structure After Init

```
your-project/
├── .contracts/
│   └── registry.yaml           # Index of all contracts
│
├── src/
│   ├── core/
│   │   └── auth/
│   │       ├── CONTRACT.md     # Your requirements
│   │       ├── CONTRACT.yaml   # AI-maintained spec
│   │       └── ...code...
│   │
│   └── features/
│       └── dashboard/
│           ├── CONTRACT.md
│           ├── CONTRACT.yaml
│           └── ...code...
```

---

## Commands

| Command | What It Does |
|---------|--------------|
| `init contracts` | Scan project and create contracts |
| `check contracts` | Report drift and sync status |
| `sync contracts` | Update all YAMLs from changed MDs |
| `contract for [module]` | Show or create specific contract |
| `validate contracts` | Run validation scripts |

---

## IDE Integration

The skill works with any AI coding assistant that supports custom instructions:

### GitHub Copilot

Add to `.github/copilot-instructions.md`:
```markdown
## Contracts
Before modifying any module, check for CONTRACT.md files and consult the contracts skill.
```

### Claude Code

Add to `CLAUDE.md`:
```markdown
## Contracts System
Check for CONTRACT.md before any code changes. Never edit CONTRACT.md files directly.
```

### Cursor

Add to `.cursorrules`:
```
Always check for CONTRACT.md before modifying code. Never edit CONTRACT.md files.
```

---

## CI/CD Integration

Add contract validation to your pipeline:

### GitHub Actions

```yaml
- name: Validate Contracts
  run: |
    pwsh .agent/skills/contracts/scripts/validate-contracts.ps1 -OutputFormat github-actions
```

### Pre-commit Hook

```bash
#!/bin/bash
pwsh .agent/skills/contracts/scripts/validate-contracts.ps1
```

---

## File Formats

### CONTRACT.md (You Write This)

```markdown
# [Module Name]

## Purpose
[Why does this exist?]

## Core Features
- [ ] Feature 1
- [ ] Feature 2

## Constraints
- MUST: [Requirement]
- MUST NOT: [Prohibition]

## Success Criteria
[How to verify it works]
```

### CONTRACT.yaml (AI Maintains This)

```yaml
meta:
  source_hash: "sha256:..."    # For drift detection
  last_sync: "2026-01-29"
  tier: standard               # core|standard|complex

module:
  name: "module-name"
  type: "feature"

features:
  - id: "feature-id"
    status: planned            # planned|in-progress|implemented|deprecated
    entry_point: "./file.ts"

constraints:
  must: ["requirement"]
  must_not: ["prohibition"]

changelog:
  - date: "2026-01-29"
    change: "Initial contract"
```

---

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

---

## License

MIT © KombiverseLabs

---

## Acknowledgments

Inspired by:
- [Architecture Decision Records](https://github.com/joelparkerhenderson/architecture-decision-record)
- [Rulebook AI](https://github.com/botingw/rulebook-ai)
- [Universal Rule Format](https://github.com/ydeng11/rulesify)
