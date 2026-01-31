---
name: contracts
description: Spec-driven development with living contracts. Use when creating modules, features, or components. Consult before any code changes to verify alignment with CONTRACT.md specifications. Triggers on "contract", "spec", "requirements", "module contract", "feature spec", "drift check".
---

# Contracts Skill

## Goal

Maintain alignment between user intent and implementation through **living contracts**. Every significant module gets two files:

- `CONTRACT.md` — User-owned specification (NEVER edit as AI)
- `CONTRACT.yaml` — Technical mapping (AI-editable, synced with .md)

This prevents spec drift during long development cycles by keeping requirements visible and validated.

## Core Principles

1. **User Authority**: `CONTRACT.md` is sacred. Only the user modifies it.
2. **Sync Obligation**: When `.md` changes, `.yaml` MUST be updated in the same session.
3. **Drift Detection**: Hash-based verification catches silent divergence.
4. **AI Assistance**: Initialization and analysis are AI-assisted, not script-based.
5. **Minimal Overhead**: Contracts are brief (50/100 lines max) — clarity over completeness.

---

## Workflow

### On Every Invocation (Mandatory Check)

Before making ANY code changes, run this check:

```
1. Locate CONTRACT.md in the current working directory (or nearest parent)
2. If found:
   a. Read CONTRACT.md — understand the user's intent
   b. Read CONTRACT.yaml — check meta.source_hash
   c. Compute current hash of CONTRACT.md
   d. If hashes differ → STOP and alert: "Contract changed. Syncing YAML first."
   e. Verify planned changes align with CONTRACT.md constraints
3. If not found:
   - For new modules: Offer to create contracts
   - For existing code: Note absence, proceed with caution
```

### When User Modifies CONTRACT.md

1. Acknowledge the change explicitly
2. Identify what changed (diff if possible)
3. Update `CONTRACT.yaml`:
   - Update `meta.source_hash` with new hash
   - Update `meta.last_sync` timestamp
   - Reflect feature/constraint changes in relevant sections
   - Add changelog entry
4. Present summary: "Contract synced. Here's what changed in the technical spec..."

### When Creating New Modules

1. Ask: "Should I create a contract for this module?"
2. If yes:
   - Generate `CONTRACT.md` draft from user description (one-time AI edit)
   - Present for user approval/modification
   - Generate matching `CONTRACT.yaml`
   - Register in `.contracts/registry.yaml`

---

## File Specifications

### CONTRACT.md (User-Owned)

**Location**: Root of module/feature directory  
**Max Lines**: 50 (use tiers for exceptions)  
**Edited By**: User ONLY (except during initialization)

```markdown
# [Module Name]

## Purpose
[1-3 sentences: Why does this exist? What problem does it solve?]

## Core Features
- [ ] Feature 1: Brief description
- [ ] Feature 2: Brief description
- [ ] Feature 3: Brief description

## Constraints
- MUST: [Non-negotiable requirement]
- MUST: [Another requirement]
- MUST NOT: [Explicit prohibition]

## Success Criteria
[How do we know this module is working correctly?]

## Notes
[Optional: Context, decisions, links to related docs]
```

### CONTRACT.yaml (AI-Editable)

**Location**: Same directory as CONTRACT.md  
**Max Lines**: 100  
**Edited By**: AI assistant (synced with .md) or User

```yaml
# CONTRACT.yaml - Technical specification derived from CONTRACT.md
# This file is auto-synced. Manual edits to 'module' and 'features' sections are preserved.

meta:
  source_hash: "sha256:..."      # Hash of CONTRACT.md for drift detection
  last_sync: "2026-01-29T10:00:00Z"
  tier: standard                  # core|standard|complex
  version: "1.0"

module:
  name: "module-name"
  type: "feature"                 # core|feature|integration|utility
  path: "./relative/path"

features:
  - id: "feature-slug"
    description: "From CONTRACT.md"
    status: planned               # planned|in-progress|implemented|deprecated
    entry_point: "./file.ts"
    tests: "./file.test.ts"
    
constraints:
  must:
    - "requirement from CONTRACT.md"
  must_not:
    - "prohibition from CONTRACT.md"

relationships:
  depends_on: []                  # Paths to other CONTRACT.yaml files
  consumed_by: []                 # Modules that depend on this one

validation:
  exports: []                     # Required public API
  test_pattern: "*.test.ts"
  custom_script: null             # Optional: "scripts/validate.ps1"

changelog:
  - date: "2026-01-29"
    version: "1.0"
    change: "Initial contract"
    author: "system"
```

---

## Tier System

| Tier | CONTRACT.md Max | CONTRACT.yaml Max | Use Case |
|------|-----------------|-------------------|----------|
| `core` | 30 lines | 60 lines | Single-responsibility utilities |
| `standard` | 50 lines | 100 lines | Typical feature modules |
| `complex` | 80 lines | 150 lines | Integration layers, orchestration |

Declare tier in YAML `meta.tier`. Default is `standard`.

---

## Registry (.contracts/registry.yaml)

Central index of all contracts in the project:

```yaml
# .contracts/registry.yaml
project:
  name: "project-name"
  initialized: "2026-01-29"
  initialized_by: "contracts-skill v2.0 (AI-assisted)"
  
contracts:
  - path: "src/core/auth"
    name: "Authentication"
    tier: core
    type: core
    summary: "User login, logout, session management"
    
  - path: "src/features/dashboard"
    name: "Dashboard"
    tier: standard
    type: feature
    summary: "Main user interface after login"
    depends_on: ["src/core/auth"]
```

---

## Initialization Mode (AI-Assisted)

> **Note**: This section is only used during first-time setup. See `references/initialization.md` for the full initialization workflow.

The initialization is **AI-assisted** — not script-based. The AI analyzes your codebase semantically to understand:
- Project type and structure
- Module boundaries and complexity
- Public APIs and exports
- Test coverage and maturity

### Quick Reference:

**Ask your AI assistant:**
```
"Initialize contracts for this project"
"Analyze my project and suggest contracts"
```

**Or use the CLI directly:**
```bash
# Analyze project and show recommendations
node .github/skills/contracts/ai/init-agent/index.js --path . --analyze

# Preview contract drafts
node .github/skills/contracts/ai/init-agent/index.js --path . --dry-run

# Apply after review
node .github/skills/contracts/ai/init-agent/index.js --path . --apply --yes
```

### How It Works

1. **AI Analysis**: Scans project structure, reads configs (package.json, pyproject.toml, etc.), analyzes source code
2. **Module Detection**: Identifies modules by complexity, not just directory patterns
3. **Intelligent Scoring**: Ranks modules by importance (exports, test coverage, dependencies)
4. **Contextual Drafts**: Generates CONTRACT.md content based on actual code exports
5. **Interactive Approval**: Presents recommendations for your review before creating files

### What Gets Analyzed

- Configuration files (detects project type)
- Source directory structure
- Export patterns (functions, classes, components)
- Test file presence
- Import relationships
- Code complexity metrics

See `references/initialization.md` for complete details.

---

## Constraints

### NEVER Do

- ❌ Edit `CONTRACT.md` after initialization (unless user explicitly asks for a draft)
- ❌ Proceed with changes that violate CONTRACT.md constraints
- ❌ Create code in a module without checking for contracts first
- ❌ Ignore hash mismatches — always sync first
- ❌ Delete or overwrite changelog entries
- ❌ Create contract files without explicit user approval during initialization

### ALWAYS Do

- ✅ Read CONTRACT.md before any module changes
- ✅ Update CONTRACT.yaml when CONTRACT.md changes
- ✅ Add changelog entry for every YAML update
- ✅ Verify feature status matches actual implementation
- ✅ Flag when implementation deviates from contract
- ✅ Suggest contract updates when user requests features not in spec
- ✅ Use AI-assisted analysis for initialization (not pattern matching)

---

## Integration Commands

These phrases trigger specific behaviors:

| Command | Action |
|---------|--------|
| "init contracts" | Run AI-assisted initialization workflow (see `references/assistant-hooks/init-contracts.md`) |
| "contract preflight" | Read relevant CONTRACT.md/yaml for the target scope and summarize constraints (≤ 5 sentences) |
| "check contracts" | Scan all contracts, report drift/sync status |
| "sync contracts" | Update all YAML files from changed MDs |
| "contract for [module]" | Show or create contract for specific module |
| "validate contracts" | Run validation scripts, check exports |

> Assistant implementers: read `references/assistant-hooks/init-contracts.md` to discover how to perform initialization safely and interactively.

---

## Drift Detection Script

For automated CI/CD integration, use the validation script:

```powershell
# .github/skills/contracts/scripts/validate-contracts.ps1
# Checks all contracts for drift and validation errors
```

---

## References

- `references/initialization.md` — AI-assisted initialization workflow
- `references/assistant-hooks/init-contracts.md` — Implementation guide for AI assistants
- `references/assistant-hooks/contract-preflight.md` — Preflight guide: read relevant contracts before work
- `references/cheatsheet.md` — Quick reference
- `references/templates/` — Templates for different module types
- `ai/init-agent/analyzer.js` — Semantic analysis engine
- `scripts/validate-contracts.ps1` — CI/CD validation script
- `scripts/compute-hash.ps1` — Hash computation utility

---

## Examples

### Example: User Updates CONTRACT.md

**User edits** `src/auth/CONTRACT.md`:
```diff
 ## Core Features
 - [x] Login with email/password
 - [x] Session management
 +- [ ] OAuth2 integration (Google, GitHub)
```

**AI Response:**
```
I see CONTRACT.md was updated. Syncing CONTRACT.yaml...

Added to features:
  - id: "oauth2-integration"
    description: "OAuth2 integration (Google, GitHub)"
    status: planned

Changelog entry added:
  - date: "2026-01-29"
    change: "Added OAuth2 integration requirement"
    author: "user"

Contract synced. Ready to implement OAuth2?
```

### Example: Drift Detection

```
⚠️ Contract Drift Detected

File: src/features/dashboard/CONTRACT.md
Expected hash: sha256:abc123...
Current hash:  sha256:def456...

The CONTRACT.md has changed since last sync.
Please review changes before I update the YAML.

Show diff? [y/n]
```

### Example: AI-Assisted Initialization

```
🔍 AI-Assisted Project Analysis
================================

Project: my-app (nodejs)
Type: Node.js/Express application

📊 Found 8 potential modules

1. ○ auth (core, core)
   Path: src/core/auth
   Files: 5, Lines: ~340, Score: 82.5
   Exports: login, logout, validateSession, refreshToken, hashPassword

2. ○ dashboard (feature, standard)
   Path: src/features/dashboard
   Files: 8, Lines: ~520, Score: 78.0
   Exports: Dashboard, Widget, Chart

📋 Top Recommendations for Contracts:
=====================================

1. auth
   Reason: core functionality, public API surface, test coverage exists
   Suggested tier: core

2. dashboard
   Reason: significant codebase, complex structure
   Suggested tier: standard

💡 Run with --recommend to generate contract drafts for these modules
```
