# Assistant Hook: Initialize Contracts (AI-Assisted)

**Trigger phrases:**
- "Initialize contracts for this project"
- "Init contracts"
- "Set up contracts"
- "Analyze my project for contracts"
- "AI-assisted contract initialization"

---

## Purpose

This hook guides AI assistants through the AI-assisted contract initialization process. Unlike the old pattern-based approach, the new system uses semantic analysis of the codebase to intelligently recommend contracts.

**Key Principle:** The AI must analyze first, then recommend, then wait for approval before creating any files.

---

## Workflow for AI Assistants

### Step 1: Verify Skill Installation

Before proceeding, ensure the contracts skill is available:

```
Check if .github/skills/contracts/ (or equivalent skill path) exists
Look for SKILL.md in the skill directory
```

If not found:
> "The contracts skill doesn't appear to be installed. Would you like me to guide you through installation first?"

### Step 2: Run Semantic Analysis

Use the analyzer to understand the project:

```bash
node .github/skills/contracts/ai/init-agent/index.js --path . --analyze
```

Or programmatically:
```javascript
const { analyzeProject } = require('./analyzer');
const analysis = analyzeProject(rootPath);
```

This will:
- Detect project type (Node.js, Python, Go, Rust, etc.)
- Analyze source directory structure
- Calculate complexity metrics for each module
- Identify public APIs and exports
- Score modules by importance

### Step 3: Present Recommendations

Show the user the AI's findings:

```markdown
## Project Analysis Results

**Project:** [name] ([type])
**Description:** [if available]

I analyzed your codebase and found [N] potential modules. Here are my top recommendations for contracts:

| # | Module | Type | Tier | Reason |
|---|--------|------|------|--------|
| 1 | auth | core | core | Public API with 5 exports, test coverage exists |
| 2 | dashboard | feature | standard | Significant codebase (450 lines), complex structure |
| 3 | api-client | integration | complex | Handles external communication, many dependencies |

**Explanation of terms:**
- **Type:** core (foundational), feature (user-facing), integration (external), utility (helpers)
- **Tier:** core (30 lines), standard (50 lines), complex (80 lines) - affects CONTRACT.md max length
```

**Ask for user input:**
> "Would you like me to generate contract drafts for all recommended modules, or would you prefer to select specific ones?"

Options to present:
- "Generate all [N] contracts"
- "Select specific modules"
- "Add a module not listed"
- "Skip initialization"

### Step 4: Generate Drafts (Optional Preview)

If the user wants to see drafts before creating files:

```bash
node .github/skills/contracts/ai/init-agent/index.js --path . --recommend
```

Present the first draft as an example:

```markdown
## Draft Contract: src/core/auth/CONTRACT.md

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
- MUST NOT: Introduce circular dependencies

## Success Criteria
Module functions as expected and integrates with the rest of the application.
```

**Ask for approval:**
> "This draft was generated based on the exports found in your code. Does this look accurate? Any changes you'd like before I create the files?"

### Step 5: Create Files (After Explicit Approval)

**CRITICAL:** Never create files without explicit user consent.

Once approved, run:

```bash
node .github/skills/contracts/ai/init-agent/index.js --path . --apply --yes
```

Or for specific modules only:
```bash
node .github/skills/contracts/ai/init-agent/index.js --module ./src/auth --yes
node .github/skills/contracts/ai/init-agent/index.js --module ./src/dashboard --yes
```

### Step 6: Present Summary

After creation, show:

```markdown
## ✅ Contracts Initialized

**Created files:**
- `src/core/auth/CONTRACT.md` (DRAFT)
- `src/core/auth/CONTRACT.yaml`
- `src/features/dashboard/CONTRACT.md` (DRAFT)
- `src/features/dashboard/CONTRACT.yaml`
- `.contracts/registry.yaml`

**Next steps:**
1. Review each CONTRACT.md file
2. Remove the `<!-- DRAFT -->` comment when satisfied
3. Adjust features, constraints, and success criteria as needed
4. Ask me to help implement any features

**Commands you can use:**
- "Check contracts" - Verify all contracts are in sync
- "Sync contract for auth" - Update YAML after editing MD
- "Help me implement the auth contract"
```

---

## Analysis Details for AI Understanding

### How the Analyzer Works

The `analyzer.js` module performs:

1. **Project Type Detection**
   - Looks for package.json, pyproject.toml, go.mod, Cargo.toml
   - Falls back to generic analysis if no specific type detected

2. **Directory Scanning**
   - Scans standard source directories (src/, lib/, app/, etc.)
   - Respects ignore patterns (node_modules, .git, etc.)
   - Recursively analyzes subdirectories

3. **Module Scoring Algorithm**
   ```javascript
   score = (lineCount / 10) + 
           (subDirCount * 5) + 
           (hasEntryPoint ? 10 : 0) + 
           (hasTests ? 10 : 0) + 
           (exportCount * 2) + 
           (isCoreType ? 20 : 0)
   ```

4. **Export Extraction**
   - JavaScript/TypeScript: ES6 exports, module.exports
   - Python: `__all__`, `from X import Y`
   - Go: Package declarations
   - Rust: pub mod, pub use

### Understanding Tiers

The AI assigns tiers based on complexity:

| Tier | Criteria | CONTRACT.md Limit |
|------|----------|-------------------|
| **core** | < 100 lines, ≤ 1 subdirectory | 30 lines |
| **standard** | 100-500 lines, 2-3 subdirectories | 50 lines |
| **complex** | > 500 lines, > 3 subdirectories | 80 lines |

### Understanding Module Types

Types are assigned based on path patterns:

| Type | Path Patterns | Description |
|------|---------------|-------------|
| **core** | core/, lib/, pkg/ | Foundational modules |
| **feature** | features/, components/, pages/ | User-facing functionality |
| **integration** | integration/, adapter/, api/ | External service connectors |
| **utility** | util/, helper/, common/ | Shared helper functions |

---

## Handling Special Cases

### Monorepos

For projects with multiple packages:

1. Analyze from the root first
2. Present packages as top-level modules
3. Offer to drill down into specific packages

```
"I see this is a monorepo with packages/app, packages/api, and packages/shared. 
Would you like me to analyze each package separately for more granular contracts?"
```

### Existing Contracts

If contracts already exist:

```
"I found [N] existing contracts in your project:
- src/core/auth (✓)
- src/features/dashboard (✓)

The AI analysis suggests [M] additional modules that might benefit from contracts:
- src/lib/api-client
- src/utils/validation

Would you like me to create contracts for these additional modules?"
```

### Non-Standard Project Structures

If the project doesn't match common patterns:

```
"Your project structure is unique. I found [N] directories with source code.
Let me show you the top candidates by complexity:"

[List top 5 by line count]

"Would you like me to create contracts for these, or would you prefer to specify 
which directories should have contracts?"
```

---

## Error Handling

### "No modules detected"

**Response:**
> "I wasn't able to automatically identify modules in your project. This might be because:
> - The source files are in an unusual location
> - The project is very small or configuration-only
> - Files are in directories I couldn't access
>
> Would you like to:
> 1. Specify directories that should have contracts
> 2. Create a single contract for the entire project
> 3. Skip initialization for now"

### "analyzer.js not found"

**Response:**
> "It looks like the AI-assisted initialization tools aren't available. Let me check your installation..."

[Verify skill installation, guide user to reinstall if needed]

### Permission Errors

**Response:**
> "I encountered permission issues accessing some directories. I'll proceed with the files I can access."

[Continue with partial analysis, note which directories were skipped]

---

## Best Practices

### DO:
- ✅ Always run analysis before recommending
- ✅ Explain your reasoning for each recommendation
- ✅ Show drafts before creating files
- ✅ Wait for explicit user approval
- ✅ Handle edge cases gracefully
- ✅ Respect existing contracts

### DON'T:
- ❌ Use pattern-based assumptions (old method)
- ❌ Create files without approval
- ❌ Overwrite existing contracts without warning
- ❌ Ignore the DRAFT marker in generated contracts
- ❌ Skip the analysis phase

---

## Example Conversations

### Example 1: Standard Flow

**User:** "Initialize contracts for this project"

**AI:** "I'll analyze your project structure to identify modules that would benefit from contracts. This uses AI-assisted semantic analysis of your codebase."

[Runs analysis]

**AI:** "I found 8 potential modules. Based on code complexity, public API surface, and test coverage, I recommend starting with contracts for these 4:

1. **auth** (core) - Handles authentication, 5 public exports, has tests
2. **api** (integration) - External API client, 450 lines of code
3. **dashboard** (feature) - Main UI, complex component structure
4. **validation** (utility) - Form validation, used by 3 other modules

Would you like me to generate contract drafts for all 4, or would you prefer to select specific ones?"

**User:** "All 4 sounds good"

**AI:** "I'll generate the drafts and show you a preview of the first one..."

[Shows auth contract draft]

"The content is generated from your actual code exports and structure. Does this look accurate?"

**User:** "Yes, looks good"

**AI:** "Creating contracts now..."

[Creates files]

"✅ Done! I've created 4 CONTRACT.md files (marked as DRAFT) and their corresponding CONTRACT.yaml files. The registry at `.contracts/registry.yaml` tracks all your contracts. Review each CONTRACT.md, remove the DRAFT comment when ready, and let me know if you'd like help implementing any features."

### Example 2: Existing Contracts

**User:** "Init contracts"

**AI:** "I scanned your project and found you already have contracts for:
- src/core/auth
- src/features/dashboard

The analysis suggests 2 additional modules that might benefit from contracts:
- src/lib/cache (utility, 200 lines, 4 exports)
- src/integrations/payment (integration, handles external API)

Would you like me to create contracts for these additional modules?"

**User:** "Just the payment one"

**AI:** "I'll create a contract for the payment integration module..."

[Proceeds with single module creation]

---

## File Locations

When referring to this hook, use:

- **In skill:** `skill/references/assistant-hooks/init-contracts.md`
- **Installed:** `.github/skills/contracts/references/assistant-hooks/init-contracts.md`

The analyzer module is at:
- **In skill:** `skill/ai/init-agent/analyzer.js`
- **Installed:** `.github/skills/contracts/ai/init-agent/analyzer.js`
