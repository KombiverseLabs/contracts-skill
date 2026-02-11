---
name: contracts-beads
description: Spec-driven development with living contracts, enforced via Beads. Use when creating modules, features, or components. Consult before any code changes to verify alignment with CONTRACT.md specifications. Triggers on "contract", "spec", "requirements", "module contract", "feature spec", "drift check".
---

# Contracts Skill (Beads-Enforced)

This is the Beads-enforced variant of the Contracts skill. It extends the base contracts system with dependency-blocking enforcement via [Beads](https://github.com/steveyegge/beads).

For the base contracts system (without Beads), see `../skill/SKILL.md`.

## Prerequisites

- **Beads** must be initialized in the project (`.beads/` directory present, `bd` CLI available)
- Beads provides dependency-blocking enforcement: the AI cannot proceed with feature work until the preflight task is closed

## Quick Reference

| File | Location | Owner | Max Lines |
|------|----------|-------|-----------|
| `CONTRACT.md` | Module root | User only | Tier-dependent |
| `CONTRACT.yaml` | Module root | AI + User | Tier-dependent |
| `registry.yaml` | `.contracts/` | AI | No limit |

| Tier | MD | YAML | Use Case |
|------|----|------|----------|
| `core` | 30 | 60 | Single-responsibility utilities |
| `standard` | 50 | 100 | Typical features |
| `complex` | 80 | 150 | Integrations, orchestration |

| Command | Action |
|---------|--------|
| "init contracts" | AI-assisted initialization (see `references/assistant-hooks/init-contracts.md`) |
| "contract preflight" | Read contracts, summarize constraints (see `references/assistant-hooks/contract-preflight.md`) |
| "check contracts" | Scan all, report drift/sync status |
| "sync contracts" | Update all YAMLs from changed MDs |
| "validate contracts" | Run validation scripts |

---

## Goal

Maintain alignment between user intent and implementation through **living contracts**:
- `CONTRACT.md` — User-owned specification (NEVER edit as AI)
- `CONTRACT.yaml` — Technical mapping (AI-editable, synced with .md)
- **Beads** — Enforcement layer (preflight task blocks work until contracts are checked)

## Core Principles

1. **User Authority**: `CONTRACT.md` is sacred. Only the user modifies it.
2. **Sync Obligation**: When `.md` changes, `.yaml` MUST be updated in the same session.
3. **Drift Detection**: Hash-based verification catches silent divergence.
4. **Test Anchoring**: Every feature maps to tests. Success criteria must be testable.
5. **Enforced Preflight**: Beads blocks feature work until contract checks pass.
6. **Minimal Overhead**: Contracts are brief — clarity over completeness.

---

## Workflow

### Before ANY Code Changes (Mandatory Preflight via Beads)

```
1. Check Beads for open preflight task: bd list --status open --tag contracts
2. If no preflight task exists → create one: bd create "PREFLIGHT: Check contracts" -p 0 --tag contracts
3. Locate CONTRACT.md in target directory (walk up parents if needed)
4. If found:
   a. Read CONTRACT.md — understand constraints
   b. Read CONTRACT.yaml — check meta.source_hash
   c. If hashes differ → STOP: "Contract changed. Syncing YAML first."
   d. Verify planned changes align with MUST/MUST NOT constraints
   e. Check: do test files exist for features being changed?
5. If not found:
   - New modules: offer to create contracts
   - Existing code: note absence, proceed with caution
6. Close preflight task with summary: bd close <id> --design "Checked: [modules]. Constraints: [summary]."
7. Feature work tasks can now proceed (Beads dependency unblocked).
```

### When User Modifies CONTRACT.md

1. Acknowledge the change
2. Update `CONTRACT.yaml`: hash, timestamp, features, constraints, changelog
3. Summarize: "Contract synced. Here's what changed..."

### When Creating New Modules

1. Ask: "Should I create a contract for this module?"
2. Generate draft from template (one-time AI edit), present for approval
3. Generate matching YAML, register in `.contracts/registry.yaml`

---

## File Specifications

### CONTRACT.md (User-Owned)

Max lines: tier-dependent. Edited by user ONLY (except during initialization).

```markdown
# [Module Name]
## Purpose           → 1-3 sentences: what user problem does this solve?
## Core Features     → Checkbox list, each mapped to a test file
## Constraints       → MUST / MUST NOT (testable, measurable)
## Success Criteria  → Given/When/Then format or specific metrics
```

See `../skill/references/templates/` for tier-specific templates.

### CONTRACT.yaml (AI-Editable)

```yaml
meta:       → source_hash, last_sync, tier, version
module:     → name, type, path
features:   → list with id, description, status, entry_point, tests
constraints: → must[], must_not[]
relationships: → depends_on[], consumed_by[]
validation: → exports[], test_pattern, custom_script
changelog:  → history of changes
```

Feature status values: `planned` | `in-progress` | `implemented` | `deprecated`

---

## Constraints

### NEVER
- Edit CONTRACT.md after initialization (unless user requests a draft)
- Proceed with changes that violate CONTRACT.md constraints
- Create code in a module without checking for contracts first
- Ignore hash mismatches — always sync first
- Delete or overwrite changelog entries
- Start feature work without closing the Beads preflight task

### ALWAYS
- Read CONTRACT.md before any module changes
- Update CONTRACT.yaml when CONTRACT.md changes
- Add changelog entry for every YAML update
- Verify feature status matches actual implementation
- Flag when implementation deviates from contract
- Suggest contract updates when user requests features not in spec
- Check if tests exist for features marked as implemented
- Create and close Beads preflight tasks for every implementation cycle

---

## Hash Recovery

If `meta.source_hash` is corrupted or out of sync and you cannot determine the cause:

```
1. Recompute hash: pwsh ../skill/scripts/compute-hash.ps1 -FilePath CONTRACT.md
2. Update CONTRACT.yaml meta.source_hash with the new value
3. Update meta.last_sync to current timestamp
4. Add changelog entry: "Hash recovery - manual resync"
```

This is a repair operation, not a normal workflow. Always investigate why drift occurred.

---

## References (Load When Needed)

- **Initializing?** → Read `references/assistant-hooks/init-contracts.md`
- **Before coding?** → Read `references/assistant-hooks/contract-preflight.md`
- **New contract?** → Read template from `../skill/references/templates/`
- **Validation scripts** → `../skill/scripts/validate-contracts.ps1`, `../skill/scripts/compute-hash.ps1`

Do NOT pre-load all references. Load only what the current task requires.

---

## Examples

**Drift detected**: Hash mismatch → stop, show diff, sync YAML before proceeding.

**User adds feature to CONTRACT.md**: AI syncs YAML (new feature entry, updated hash, changelog), then offers to implement.

**New module**: AI generates draft CONTRACT.md from template, user reviews, AI creates matching YAML and registry entry.

**Beads enforcement**: Feature task created → depends on PREFLIGHT task → agent runs preflight, closes with summary → feature task unblocks → implementation begins.
