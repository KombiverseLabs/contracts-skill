# Contracts Initialization Workflow (AI-Assisted)

This document describes the AI-assisted initialization process for setting up the contracts system in a project.

> **What's New in v2.0**: The initialization is now AI-assisted rather than script-based. The AI analyzes your codebase semantically to understand its structure and purpose, then recommends appropriate contracts rather than following fixed patterns.

---

## Overview

The AI-assisted initialization process:

1. **Analyzes** your project structure semantically (not just pattern matching)
2. **Understands** the codebase by reading configs, READMEs, and source files
3. **Identifies** modules that would benefit from contracts
4. **Generates** intelligent contract drafts with context-aware content
5. **Presents** recommendations for your review and approval

---

## Prerequisites

- Access to the project root directory
- The `contracts` skill installed in your AI assistant
- Permission to create new files and directories

---

## Initialization Methods

### Method 1: AI Assistant Command (Recommended)

Ask your AI assistant:

```
"Initialize contracts for this project"
"Analyze my project and suggest contracts"
"Set up contracts using AI-assisted initialization"
```

The AI will:
1. Run semantic analysis on your project
2. Present recommended modules with reasoning
3. Generate draft contracts for your review
4. Create files after your approval

### Method 2: Direct Tool Usage

```bash
# Analyze project and show recommendations
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --analyze

# Generate contract drafts for recommended modules
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --recommend

# Preview what would be created (dry-run)
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --dry-run

# Apply and create files (with confirmation)
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --apply --yes

# Create contract for specific module
node .agent/skills/contracts/skill/ai/init-agent/index.js --module ./src/auth --yes
```

---

## How AI Analysis Works

### Phase 1: Project Discovery

The AI analyzes:

```
Configuration Files:
├── package.json (Node.js projects)
├── pyproject.toml / setup.py (Python projects)
├── go.mod (Go projects)
├── Cargo.toml (Rust projects)
└── README.md (All projects)

Source Structure:
├── Detects project type from configs
├── Identifies source directories (src/, lib/, app/, etc.)
├── Maps module boundaries
└── Finds entry points and public APIs
```

### Phase 2: Semantic Module Analysis

For each potential module, the AI evaluates:

| Factor | What it measures | Impact |
|--------|------------------|--------|
| **Code Volume** | Lines of code, file count | Module importance |
| **Complexity** | Subdirectory depth, structure | Tier assignment (core/standard/complex) |
| **Public API** | Exports, entry points | Feature extraction |
| **Test Coverage** | Presence of test files | Module maturity |
| **Relationships** | Import patterns | Dependency mapping |

### Phase 3: Intelligent Recommendations

Based on the analysis, the AI:

1. **Scores** each module by relevance
2. **Ranks** modules by importance
3. **Suggests** appropriate tiers (core/standard/complex)
4. **Generates** context-aware contract content
5. **Explains** why each contract is recommended

---

## Understanding Recommendations

When the AI presents recommendations, you'll see:

```
📋 Top Recommendations for Contracts:
=====================================

1. Authentication
   Reason: core functionality, public API surface, test coverage exists
   Suggested tier: core
   Path: src/core/auth

2. Dashboard
   Reason: significant codebase, complex structure
   Suggested tier: standard
   Path: src/features/dashboard
```

### Recommendation Reasons

| Reason | Meaning |
|--------|---------|
| "core functionality" | Foundational module with many dependents |
| "public API surface" | Exports functions/classes used by other modules |
| "significant codebase" | Large amount of code (>200 lines) |
| "complex structure" | Multiple subdirectories or intricate organization |
| "test coverage exists" | Already has tests, indicating mature code |

---

## Contract Draft Generation

The AI generates contract drafts with:

### From Code Analysis:
- **Purpose**: Inferred from exports and module name
- **Features**: Extracted from public API exports
- **Constraints**: Based on error handling patterns found
- **Success Criteria**: Derived from existing tests

### From Project Context:
- **Module Type**: Determined by location (core/, features/, etc.)
- **Tier**: Based on complexity metrics
- **Relationships**: From import analysis

Example AI-generated draft:

```markdown
<!-- DRAFT: Please review and modify, then remove this line -->
# Authentication

## Purpose
Provides login, logout, validateSession, refreshToken functions.

## Core Features
- [ ] login: Implementation pending
- [ ] logout: Implementation pending
- [ ] validateSession: Implementation pending
- [ ] refreshToken: Implementation pending

## Constraints
- MUST: Maintain backward compatibility for public API
- MUST: Have comprehensive test coverage
- MUST: Follow project coding standards
- MUST NOT: Introduce circular dependencies

## Success Criteria
Module functions as expected and integrates with the rest of the application.
```

---

## Review and Approval Process

### Step 1: Review Recommendations

The AI presents a list of recommended modules. You can:
- ✅ **Approve** - Accept all recommendations
- 📝 **Modify** - Select specific modules
- ➕ **Add** - Suggest additional modules
- ➖ **Skip** - Exclude specific modules

### Step 2: Review Drafts

For each contract, review:
- Is the **purpose** accurate?
- Are the **features** complete?
- Are the **constraints** appropriate?
- Is the **tier** correct?

### Step 3: Apply Changes

After your approval, the AI:
1. Creates CONTRACT.md files (marked as DRAFT)
2. Creates CONTRACT.yaml files with proper hashes
3. Updates/creates `.contracts/registry.yaml`
4. Presents a summary

---

## Post-Initialization

### Files Created

```
your-project/
├── .contracts/
│   └── registry.yaml          # Central contract index
├── src/
│   ├── core/
│   │   └── auth/
│   │       ├── CONTRACT.md    # User-owned specification (DRAFT)
│   │       └── CONTRACT.yaml  # Technical mapping
│   └── features/
│       └── dashboard/
│           ├── CONTRACT.md    # User-owned specification (DRAFT)
│           └── CONTRACT.yaml  # Technical mapping
```

### Next Steps

1. **Review CONTRACT.md files**
   - Remove the `<!-- DRAFT -->` comment when ready
   - Adjust purpose, features, and constraints as needed

2. **Ask AI to help implement**
   ```
   "Help me implement the authentication contract"
   "Check what's missing from the dashboard contract"
   ```

3. **Monitor sync status**
   ```
   "Check contracts"
   "Are my contracts in sync?"
   ```

---

## Supported Project Types

The AI-assisted initialization recognizes:

| Type | Detection | Analysis Features |
|------|-----------|-------------------|
| **Node.js** | package.json | ES6/CJS exports, test patterns |
| **Python** | pyproject.toml, setup.py | `__init__.py`, `__all__` exports |
| **Go** | go.mod | Package structure, main packages |
| **Rust** | Cargo.toml | Module hierarchy |
| **Generic** | README.md | Directory structure heuristics |

---

## Customization

### For Specific Modules

If the AI misses a module:

```bash
# Create contract for specific path
node .agent/skills/contracts/skill/ai/init-agent/index.js --module ./src/my-module --yes
```

### For Custom Project Structures

Projects with non-standard layouts can still be analyzed. The AI will:
1. Scan all directories (respecting ignore patterns)
2. Identify modules by code complexity
3. Suggest appropriate contracts

---

## Troubleshooting

### "No modules detected"

**Cause**: Project structure doesn't match common patterns.

**Solutions**:
- Ensure you have source files (not just configs)
- Check that files aren't in ignored directories
- Use `--module` to create contracts manually

### "All recommendations already have contracts"

**Cause**: Contracts already exist for the main modules.

**Solutions**:
- Use `--force` to regenerate drafts
- Review existing contracts with "check contracts"
- Add contracts for smaller modules manually

### "Generated drafts don't match my project well"

**Cause**: AI analysis didn't fully capture project semantics.

**Solutions**:
- Review and edit the DRAFT comments
- Provide feedback to your AI assistant
- The AI will learn from your edits for future contracts

---

## Re-Initialization

To regenerate contracts:

```bash
# Backup existing contracts and re-analyze
node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --apply --force --yes
```

Or ask your AI:
```
"Re-initialize contracts for this project, backing up existing ones"
```

---

## Migration from v1.0

If you have contracts created with the old pattern-based initialization:

1. Your existing contracts remain valid
2. The new AI analysis may suggest additional modules
3. Old and new contracts work together seamlessly
4. Consider running analysis to discover any missing contracts

---

## Best Practices

### For AI Assistants

1. **Always analyze first** - Run `--analyze` before recommending contracts
2. **Explain reasoning** - Tell the user why each module was selected
3. **Present drafts** - Show the generated content before creating files
4. **Respect existing** - Don't overwrite without `--force`
5. **Wait for approval** - Never create files without explicit user consent

### For Users

1. **Review DRAFT comments** - They're there for your attention
2. **Adjust tiers** - If the AI suggests 'standard' but it's core, change it
3. **Add missing features** - The AI extracts exports, but may miss some
4. **Refine constraints** - Add project-specific rules the AI couldn't know
5. **Iterate** - Contracts evolve with your project

---

## Related Documentation

- [`SKILL.md`](../SKILL.md) - Main skill documentation
- [`cheatsheet.md`](cheatsheet.md) - Quick reference
- [`assistant-hooks/init-contracts.md`](assistant-hooks/init-contracts.md) - Implementation guide for AI assistants
