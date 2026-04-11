---
name: contracts-beads
description: 'Spec-driven development with living contracts, enforced via Beads task management. Use when creating modules, features, or components. Consult before any code changes. Triggers on: contract, spec, requirements, module contract, feature spec, drift check, init contracts, contract preflight, contract review.'
---

# Contracts Skill (Beads-Enforced)

Extends the base Contracts skill with **Beads dependency-blocking**. The AI cannot proceed with feature work until the preflight task is closed.

**Prerequisites:** Beads CLI (`bd`) + `.beads/` directory initialized.

For base concepts see `../skill/SKILL.md`. This variant adds enforcement — all shared references, templates, and scripts live in `../skill/`.

## Quick Reference

| Tier | MD Lines | YAML Lines | VTs | Difficulty |
|------|----------|------------|-----|------------|
| `core` | 30 | 60 | 1 | easy |
| `standard` | 50 | 100 | 1-2 | medium |
| `complex` | 80 | 150 | 2-3 | hard |

| Command | Action | Reference |
|---------|--------|-----------|
| "init contracts" | AI-assisted initialization | [init-contracts.md](../skill/references/assistant-hooks/init-contracts.md) |
| "contract preflight" | Beads-enforced preflight | [contract-preflight.md](../skill/references/assistant-hooks/contract-preflight.md) |
| "contract review" | Evaluate if contract needs update | [contract-review.md](../skill/references/assistant-hooks/contract-review.md) |
| "check contracts" | Scan all, report drift/sync | Run: `validate-contracts.ps1` |

## Principles

1. **User Authority** — `CONTRACT.md` is sacred. Only the user modifies it.
2. **Sync Obligation** — When `.md` changes, `.yaml` MUST be updated same session.
3. **Drift Detection** — Hash-based verification catches silent divergence.
4. **Test-Driven** — Every feature maps to tests. Every contract has VTs AND Acceptance Tests.
5. **Enforced Preflight** — Beads blocks feature work until contract checks pass.
6. **Minimal Overhead** — Contracts are brief. Clarity over completeness.

## Workflow

### Before ANY Code Changes (Mandatory Preflight via Beads)

1. Check Beads for open preflight task: `bd list --status open --tag contracts`
2. If none → create: `bd create "PREFLIGHT: Check contracts" -p 0 --tag contracts`
3. Locate `CONTRACT.md` in target directory (walk up parents)
4. Read `.md` + `.yaml`, compare `source_hash`, check attestation + VT status
5. If hashes differ → **STOP**: sync YAML first
6. Verify planned changes align with MUST/MUST NOT constraints
7. Close preflight with summary: `bd close <id> --design "Checked: [modules]. Status: [summary]."`
8. Feature work tasks now unblocked

Details: [contract-preflight.md](../skill/references/assistant-hooks/contract-preflight.md)

### When Work Exceeds Contract Scope

If planned changes introduce features NOT in `CONTRACT.md`:
1. **STOP**: "This adds [X] which isn't in the contract."
2. Create Beads task: `bd create "CONTRACT UPDATE: Add [X]" -p 0 --tag contracts`
3. Propose diff to user → on approval, sync YAML, reset attestation to `low`
4. Close update task → feature work continues

### When User Modifies CONTRACT.md

1. Acknowledge → identify diff
2. Update YAML: hash, timestamp, features, constraints, changelog
3. Reset attestation to `low`
4. If Beads → create task tracking the sync

### When Creating New Modules

1. Ask: "Create a contract?" → draft from [template](../skill/references/templates/)
2. Generate YAML + register in `.contracts/registry.yaml`
3. Create Beads task: `bd create "CONTRACT: [module]" --tag contracts`

## File Specifications

### CONTRACT.md (User-Owned)

```markdown
# [Module Name]
## Purpose           → 1-3 sentences
## Core Features     → Checkbox list mapped to test files
## Constraints       → MUST / MUST NOT (testable)
## Success Criteria  → Given/When/Then or metrics
## Out of Scope      → What this module does NOT do
## Acceptance Tests  → Measurable "done" criteria (REQUIRED)
## Verification Tests → 1-3 golden-path tests with content assertions
```

### CONTRACT.yaml — See `../skill/SKILL.md` for schema reference.

## Integrity Rules

1. **Honesty First** — Report actual results. Never fabricate VT outcomes or feature counts.
2. **Content Assertions** — VTs must check actual output values, not "no error".
3. **No Post-Commit Drift** — Committed `CONTRACT.md` cannot be silently modified.
4. **Feature Status = VT Status** — `implemented` requires VT-1 passing.
5. **Acceptance Tests Required** — Every contract must define at least one measurable AT.
6. **Tier = Difficulty** — Tier signals complexity for evaluation.

## Constraints

### NEVER
- Edit CONTRACT.md (unless user requests a draft)
- Proceed with changes violating CONTRACT.md constraints
- Skip preflight (Beads blocks this)
- Ignore hash mismatches
- Start feature work without closing the Beads preflight task
- Mark a feature `implemented` without VT-1 passing
- Fabricate VT results or feature counts

### ALWAYS
- Read CONTRACT.md before any module changes
- Update CONTRACT.yaml when CONTRACT.md changes
- Create and close Beads preflight tasks for every implementation cycle
- Flag when work exceeds contract scope (create Beads update task)
- Check VT + attestation status during preflight
- Update attestation after implementing features
- Include Acceptance Tests in every new contract

## References (Load When Needed)

- **Initializing?** → [init-contracts.md](../skill/references/assistant-hooks/init-contracts.md)
- **Before coding?** → [contract-preflight.md](../skill/references/assistant-hooks/contract-preflight.md)
- **Scope change?** → [contract-review.md](../skill/references/assistant-hooks/contract-review.md)
- **New contract?** → [templates/](../skill/references/templates/)
- **Scripts** → [scripts/](../skill/scripts/)

Do NOT pre-load all references. Load only what the current task requires.
