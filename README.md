# Contracts Skill

> **Spec-driven development with living contracts for AI-assisted coding.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-blue.svg)](#)
[![Works with: Copilot](https://img.shields.io/badge/Works%20with-GitHub%20Copilot-blue)](https://github.com/features/copilot)
[![Works with: Claude](https://img.shields.io/badge/Works%20with-Claude-orange)](https://claude.ai)
[![Works with: Cursor](https://img.shields.io/badge/Works%20with-Cursor-purple)](https://cursor.sh)

Keep your AI coding assistant aligned with your specifications. Never let implementations drift from requirements again.

**What's New in v2.0:** AI-assisted initialization that understands your codebase semantically — no more rigid patterns, just intelligent analysis.

---

## Quick Start

### 1. Install

Choose your preferred method:

**Option A: Multi-Agent Installer (Recommended)**  
Detects and installs to all your AI assistants with interactive selection:

```powershell
# PowerShell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.ps1 | iex

# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.sh | bash
```

**Option B: Simple One-Liner**  
Install to current project only:

```powershell
# PowerShell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex

# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash
```

**Option C: Specific Agents**  
Install to specific agents only:

```powershell
# PowerShell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex -Agents "copilot,claude"

# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash -s -- --agents copilot,claude
```

### 2. Initialize (AI-Assisted)

Ask your AI assistant:

```
"Initialize contracts for this project"
```

The AI will:
1. **Analyze** your codebase semantically (project type, structure, exports)
2. **Recommend** modules that need contracts with reasoning
3. **Generate** context-aware drafts from your actual code
4. **Present** options for your review and approval
5. **Create** files after you confirm

Or use the CLI directly:

```bash
# Analyze and see recommendations
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --analyze

# Preview what would be created
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --dry-run

# Apply after review
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --apply --yes
```

### 3. Validate

```powershell
pwsh .agent/skills/contracts/scripts/validate-contracts.ps1 -Path .
```

Or ask: **"Check contracts"**

---

## What's New in v2.0

### AI-Assisted Initialization 🧠

The initialization is now **intelligent** instead of pattern-based:

| Before v2.0 | v2.0 |
|-------------|------|
| Fixed patterns (`src/features/*`) | Semantic code analysis |
| Simple templates | Context-aware drafts from exports |
| Manual module specification | AI recommends based on complexity |
| One-size-fits-all | Project-type aware (Node.js, Python, Go, Rust) |

The AI now understands:
- **Project type** from configs (package.json, pyproject.toml, etc.)
- **Module boundaries** by analyzing imports and exports
- **Complexity** from code metrics
- **Public APIs** by parsing source files

### Multi-Agent Selection 🎯

All installers now support:
- **Interactive selection** - Choose which agents to install to
- **Auto mode** - Install to all detected agents
- **Specific agents** - Target only the agents you want

---

## Installation Options

### Multi-Agent Installer (setup.ps1 / setup.sh)

Automatically detects and installs to all AI coding assistants:

```powershell
# PowerShell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.ps1 | iex

# With auto-select
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.ps1 | iex -Auto
```

```bash
# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.sh | bash

# With auto-select
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.sh | bash -s -- --auto
```

**Features:**
- Detects GitHub Copilot, Claude, Cursor, Windsurf, Cline, Aider
- Interactive agent selection
- Shows already installed agents
- Adds instruction hooks to project files

### Simple Installer (install.ps1 / install.sh)

Install to current project with optional agent selection:

```powershell
# Interactive (default)
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex

# Auto-install to all detected
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex -Auto

# Specific agents only
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex -Agents "copilot,claude"

# With initialization
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex -Init
```

```bash
# Interactive (default)
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash

# Auto-install to all detected
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash -s -- --auto

# Specific agents only
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash -s -- --agents copilot,claude

# With initialization
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash -s -- --init
```

### Manual Installation

```bash
# Clone to your project
git clone https://github.com/KombiverseLabs/contracts-skill.git .contracts-skill-temp
cp -r .contracts-skill-temp/skill/ .agent/skills/contracts/
rm -rf .contracts-skill-temp
```

```powershell
# Windows PowerShell
git clone https://github.com/KombiverseLabs/contracts-skill.git .contracts-skill-temp
Copy-Item -Path ".\.contracts-skill-temp\skill\*" -Destination ".agent\skills\contracts" -Recurse -Force
Remove-Item -Path ".\.contracts-skill-temp" -Recurse -Force
```

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

## AI-Assisted Initialization

### What the AI Analyzes

```
Project Analysis:
├── package.json → Node.js detected
├── README.md → Project description
├── src/ → Source directory found
│   ├── core/auth/ → 5 files, 340 lines
│   │   └── Exports: login, logout, validateSession...
│   ├── features/dashboard/ → 8 files, 520 lines
│   │   └── Exports: Dashboard, Widget...
│   └── lib/api-client/ → Integration module
└── Scoring:
    ├── auth: 82.5 (core functionality, tests)
    ├── dashboard: 78.0 (significant codebase)
    └── api-client: 65.5 (integration)
```

### Example Output

```
🔍 AI-Assisted Project Analysis
================================

Project: my-app (nodejs)
Type: Node.js/Express application

📊 Found 8 potential modules

📋 Top Recommendations for Contracts:
=====================================

1. auth
   Reason: core functionality, public API surface, test coverage exists
   Suggested tier: core
   Path: src/core/auth

2. dashboard
   Reason: significant codebase, complex structure
   Suggested tier: standard
   Path: src/features/dashboard

3. api-client
   Reason: integration module, external dependencies
   Suggested tier: complex
   Path: src/lib/api-client
```

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
| `init contracts` | AI-assisted analysis and contract creation |
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

### Install local git hooks (recommended)

```bash
sh ./scripts/install-git-hooks.sh
```

```powershell
.\scripts\install-git-hooks.ps1
```

---

## License

MIT © KombiverseLabs

---

## Acknowledgments

Inspired by:
- [Architecture Decision Records](https://github.com/joelparkerhenderson/architecture-decision-record)
- [Rulebook AI](https://github.com/botingw/rulebook-ai)
- [Universal Rule Format](https://github.com/ydeng11/rulesify)
