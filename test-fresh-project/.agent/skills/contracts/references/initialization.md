# Contracts Initialization Workflow

This document describes the one-time initialization process for setting up the contracts system in a project.

## Prerequisites

- Access to the project root directory
- Ability to read existing documentation (README, SPEC, ARCHITECTURE files)
- Permission to create new files and directories

## Initialization Steps

### Phase 1: Discovery

1. **Scan for Existing Specifications**
   
   Search for files that contain project requirements:
   ```
   - README.md (project overview)
   - SPEC.md, SPECIFICATION.md
   - ARCHITECTURE.md, DESIGN.md
   - docs/architecture/*.md
   - docs/specs/*.md
   - .adr/, docs/adr/ (Architecture Decision Records)
   - requirements.txt, requirements/*.md
   ```

2. **Identify Module Structure**
   
   Detect the project's organizational pattern:
   ```
   - src/features/* → Feature modules
   - src/core/* → Core modules
   - src/lib/* → Utility modules
   - src/components/* → UI components (may group by feature)
   - packages/* → Monorepo packages
   - apps/* → Multi-app structure
   ```

3. **Evaluate Existing Docs**
   
   For each spec document found:
   - Extract core requirements
   - Identify module boundaries
   - Note constraints and success criteria
   - Map to discovered module structure

### Phase 2: Planning

1. **Propose Contract Locations**
   
   Present a list to the user:
   ```markdown
   ## Proposed Contracts
   
   Based on project analysis, I recommend contracts for:
   
   | Location | Type | Reason |
   |----------|------|--------|
   | src/core/auth | core | Handles authentication, critical path |
   | src/core/database | core | Data layer, many dependencies |
   | src/features/dashboard | standard | Main user interface |
   | src/features/settings | standard | User configuration |
   | src/lib/utils | core | Shared utilities |
   
   Approve this list? Or modify? [approve/modify/add/remove]
   ```

2. **Determine Tiers**
   
   For each proposed contract:
   - `core` (30 lines) — Single responsibility, foundational
   - `standard` (50 lines) — Typical feature scope
   - `complex` (80 lines) — Integration or orchestration layer

3. **Map Dependencies**
   
   Identify relationships:
   ```yaml
   # Example dependency map
   src/features/dashboard:
     depends_on: [src/core/auth, src/core/database]
   src/features/settings:
     depends_on: [src/core/auth]
   ```

### Phase 3: Generation

1. **Create .contracts Directory**
   
   ```
   .contracts/
   ├── registry.yaml        # Central index
   └── templates/           # (Optional) Custom templates
   ```

2. **Generate CONTRACT.md Drafts**
   
   For each approved location:
   - Use appropriate template (feature/core/integration)
   - Pre-fill from discovered specifications
   - Mark as DRAFT for user review
   
   ```markdown
   <!-- DRAFT: Please review and modify, then remove this line -->
   # Authentication
   
   ## Purpose
   [Extracted from existing docs or inferred]
   
   ## Core Features
   - [ ] Feature 1
   - [ ] Feature 2
   
   ## Constraints
   - MUST: [From existing specs]
   
   ## Success Criteria
   [Inferred or placeholder]
   ```

3. **Present Drafts for Approval**
   
   Show each draft to user:
   ```
   ## Draft Contract: src/core/auth/CONTRACT.md
   
   [content]
   
   ---
   Actions:
   - [a]pprove as-is
   - [e]dit inline
   - [s]kip this module
   - [r]egenerate with different focus
   ```

4. **Generate CONTRACT.yaml Files**
   
   After user approves each .md:
   - Compute source_hash
   - Set initial metadata
   - Map features to technical structure
   - Detect existing files as entry points
   - Set all features to appropriate status

5. **Create Registry**
   
   Compile all contracts into `.contracts/registry.yaml`:
   ```yaml
   project:
     name: "project-name"
     initialized: "2026-01-29T10:00:00Z"
     initialized_by: "contracts-skill v1.0"
     
   contracts:
     - path: "src/core/auth"
       name: "Authentication"
       tier: core
       summary: "User authentication and session management"
       features_count: 4
       status: initialized
   ```

### Phase 4: Integration

1. **Add Instruction Hooks**
   
   Append to IDE instruction files:
   
   **`.github/copilot-instructions.md`:**
   ```markdown
   ## Contracts
   
   This project uses the contracts system for spec-driven development.
   Before modifying any module, consult `contracts` skill and check for CONTRACT.md files.
   ```
   
   **`CLAUDE.md` / `.claude/instructions.md`:**
   ```markdown
   ## Contracts System
   
   Before any code changes, check for CONTRACT.md in the target directory.
   See `.agent/skills/contracts/SKILL.md` for full workflow.
   ```
   
   **`.cursorrules`:**
   ```markdown
   # Contracts
   Always check for CONTRACT.md before modifying code. Never edit CONTRACT.md files.
   ```

2. **Optionally Add Git Hooks**
   
   If user approves, create pre-commit hook:
   ```bash
   # .git/hooks/pre-commit
   .agent/skills/contracts/scripts/validate-contracts.ps1
   ```

### Phase 5: Completion

1. **Summary Report**
   
   ```markdown
   ## Initialization Complete
   
   Created:
   - 5 CONTRACT.md files
   - 5 CONTRACT.yaml files
   - 1 registry.yaml
   - Instruction hooks in 2 files
   
   Contracts Index:
   | Module | Tier | Features | Status |
   |--------|------|----------|--------|
   | auth | core | 4 | ready |
   | database | core | 3 | ready |
   | dashboard | standard | 6 | ready |
   | settings | standard | 4 | ready |
   | utils | core | 2 | ready |
   
   Next Steps:
   1. Review each CONTRACT.md and adjust as needed
   2. Run "check contracts" to verify sync
   3. Start development with contract-aware workflow
   ```

2. **Self-Update Skill**
   
   After initialization, the main SKILL.md no longer needs the initialization section.
   The skill now operates in "maintenance mode" with focus on:
   - Drift detection
   - Sync on changes
   - Validation
   - New module contract creation

---

## Re-Initialization

If contracts need to be reset:

```
contracts --reinit
```

This will:
1. Backup existing contracts to `.contracts/backup/[timestamp]/`
2. Run discovery again
3. Merge or replace as user chooses

---

## Troubleshooting

### "No modules detected"

The project structure doesn't match common patterns. Manually specify:
```
init contracts for: src/services/auth, src/services/api, src/ui/components
```

### "Existing CONTRACT.md found"

Skip or merge:
- Skip: Preserve existing contract, just ensure YAML exists
- Merge: Combine discovered specs with existing contract

### "Can't determine project type"

Provide hints:
```
init contracts --type=nextjs
init contracts --type=python
init contracts --type=monorepo
```
