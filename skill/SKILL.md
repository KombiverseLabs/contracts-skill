---
name: contracts
description: 'Spec-driven development with living contracts. Use when creating modules, features, or components. Consult before any code changes to verify alignment with CONTRACT.md. Triggers on: contract, spec, requirements, module contract, feature spec, drift check, init contracts, contract preflight, check contracts, sync contracts.'
---

# Contracts Skill

Maintain alignment between user intent and implementation through **living contracts**. Every module gets:
- `CONTRACT.md` — User-owned specification (NEVER edit as AI)
- `CONTRACT.yaml` — Technical mapping (AI-editable, synced with .md)

## Quick Reference

| Tier | MD Lines | YAML Lines | VTs | Difficulty |
|------|----------|------------|-----|------------|
| `core` | 30 | 60 | 1 | easy |
| `standard` | 50 | 100 | 1-2 | medium |
| `complex` | 80 | 150 | 2-3 | hard |

| Command | Action | Reference |
|---------|--------|-----------|
| "init contracts" | AI-assisted initialization | [init-contracts.md](./references/assistant-hooks/init-contracts.md) |
| "contract preflight" | Read contracts, check drift | [contract-preflight.md](./references/assistant-hooks/contract-preflight.md) |
| "contract review" | Evaluate if contract needs update | [contract-review.md](./references/assistant-hooks/contract-review.md) |
| "check contracts" | Scan all, report drift/sync status | Run: `validate-contracts.ps1` |
| "sync contracts" | Update all YAMLs from changed MDs | Manual |

## Principles

1. **User Authority** — `CONTRACT.md` is sacred. Only the user modifies it.
2. **Sync Obligation** — When `.md` changes, `.yaml` MUST be updated same session.
3. **Drift Detection** — Hash-based verification catches silent divergence.
4. **Test-Driven** — Every feature maps to tests. Every contract has VTs AND Acceptance Tests.
5. **Minimal Overhead** — Contracts are brief. Clarity over completeness.

## Workflow

### Before ANY Code Changes (Mandatory Preflight)

1. Locate `CONTRACT.md` in target directory (walk up parents if needed)
2. If found: read `.md` + `.yaml`, compare `source_hash`, check attestation + VT status
3. If hashes differ → **STOP**: sync YAML first
4. Verify planned changes align with MUST/MUST NOT constraints
5. If not found → offer to create contracts for new modules
6. Summarize constraints + status (max 5 sentences) and proceed

Details: [contract-preflight.md](./references/assistant-hooks/contract-preflight.md)

### When Work Exceeds Contract Scope

If planned changes introduce features NOT listed in `CONTRACT.md`:
1. **STOP**: "This adds [X] which isn't in the contract."
2. Propose: "Update CONTRACT.md to include [X]? Or mark as out-of-scope?"
3. If update → present diff to user, sync YAML on approval, reset attestation to `low`

### When User Modifies CONTRACT.md

1. Acknowledge the change
2. Update `CONTRACT.yaml`: hash, timestamp, features, constraints, changelog
3. Reset attestation confidence to `low`
4. Summarize: "Contract synced. Changed: [diff]"

### When Creating New Modules

1. Ask: "Should I create a contract for this module?"
2. Generate draft from [template](./references/templates/), present for approval
3. Generate matching YAML, register in `.contracts/registry.yaml`

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

### CONTRACT.yaml (AI-Editable)

```yaml
meta:       → source_hash, last_sync, tier, version
module:     → name, type, path
features:   → [{id, description, status, entry_point, tests}]
constraints: → must[], must_not[]
relationships: → depends_on[], consumed_by[]
validation: → exports[], test_pattern
verification_tests: → [{id, name, status, test_file, last_run, last_result}]
acceptance_tests:   → [{name, type, target, passed}]
attestation: → contract_version, last_verified, confidence, next_review
changelog:  → [{date, version, change, author}]
```

Feature status: `planned` | `in-progress` | `implemented` | `deprecated`
VT status: `defined` | `implemented` | `passing` | `failing`
Confidence: `high` (all VTs pass) | `medium` (some failing) | `low` (VTs not implemented)

## Integrity Rules

Contracts are binding commitments, not suggestions. These rules prevent gaming:

1. **Honesty First** — Report actual results. Never fabricate VT outcomes, feature counts, or test results. If a VT fails, report it as failing.
2. **Content Assertions** — VTs must check actual output values, not just "no error" or "status 200". A passing VT must prove correctness.
3. **No Post-Commit Drift** — Once `CONTRACT.md` is committed for evaluation, it cannot be silently modified. Hash integrity is verified.
4. **Feature Status = VT Status** — A feature cannot be `implemented` unless VT-1 exists and passes.
5. **Acceptance Tests Required** — Every contract must define at least one measurable AT.
6. **Tier = Difficulty** — The tier (core/standard/complex) signals task complexity for evaluation.

## Constraints

### NEVER
- Edit CONTRACT.md (unless user requests a draft)
- Proceed with changes violating CONTRACT.md constraints
- Skip preflight before module changes
- Ignore hash mismatches
- Mark a feature `implemented` without VT-1 passing
- Fabricate VT results or feature counts

### ALWAYS
- Read CONTRACT.md before any module changes
- Update CONTRACT.yaml when CONTRACT.md changes
- Flag when work exceeds contract scope
- Check VT + attestation status during preflight
- Update attestation after implementing features
- Include Acceptance Tests in every new contract

## References (Load When Needed)

- **Initializing?** → [init-contracts.md](./references/assistant-hooks/init-contracts.md)
- **Before coding?** → [contract-preflight.md](./references/assistant-hooks/contract-preflight.md)
- **Scope change?** → [contract-review.md](./references/assistant-hooks/contract-review.md)
- **New contract?** → [templates/](./references/templates/)
- **Scripts** → [scripts/](./scripts/) (validate, compute-hash, run-vts)

Do NOT pre-load all references. Load only what the current task requires.
