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
5. **Verification Tests**: 1-3 high-coverage tests per contract that prove the module actually works (see Templates).
6. **Contract Commitment**: Contracts are binding across sessions — attestations track fulfillment.
7. **Enforced Preflight**: Beads blocks feature work until contract checks pass.
8. **Minimal Overhead**: Contracts are brief — clarity over completeness.

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
   f. Check attestation status (current / stale / missing)
   g. Check verification test status (passing / failing / not implemented)
6. Close preflight task with summary: bd close <id> --design "Checked: [modules]. Constraints: [summary]. Attestation: [status]. VTs: [status]."
7. Feature work tasks can now proceed (Beads dependency unblocked).
```

### When User Modifies CONTRACT.md

1. Acknowledge the change
2. Update `CONTRACT.yaml`: hash, timestamp, features, constraints, changelog
3. Reset attestation confidence to `low` (contract evolved past implementation)
4. Summarize: "Contract synced. Here's what changed..."

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
## Verification Tests → 1-3 golden-path tests with content assertions (see Templates)
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
verification_tests:
  - id: "VT-1"
    name: "descriptive name"
    status: defined|implemented|passing|failing
    test_file: "./path.test.ts"
    last_run: "ISO timestamp"
    last_result: pass|fail
attestation:
  contract_version: "1.0"
  last_verified: "ISO timestamp"
  verification_tests_pass: true|false
  features_implemented: ["id1","id2"]
  confidence: high|medium|low
  next_review: "ISO timestamp"
changelog:  → history of changes
```

Feature status values: `planned` | `in-progress` | `implemented` | `deprecated`

---

## Contract Commitment (Long-Term Binding)

Contracts are not session-scoped suggestions — they are **persistent commitments**.
The attestation mechanism ensures contracts remain binding across sessions.

### How Attestation Works

1. **After Implementation**: When features are implemented against a contract, record an attestation in `CONTRACT.yaml` with the contract version, passing VTs, and implemented features.
2. **On Every Preflight**: Check the attestation. If `contract_version` differs from current CONTRACT.md version → the contract has evolved past the implementation. Flag as **stale attestation** and require re-verification.
3. **Verification Test Status**: Track whether VTs are `defined`, `implemented`, `passing`, or `failing`. A contract with `defined` but not `implemented` VTs is incomplete — the AI must flag this.
4. **Re-Verification Cadence**: Attestations include `next_review`. When current date exceeds this, the preflight flags re-verification as needed. Default: 30 days after last verification.
5. **Confidence Score**: Derived from VT coverage:
   - `high` — All VTs implemented and passing, attestation current
   - `medium` — VTs exist but some failing, or attestation older than 30 days
   - `low` — VTs only defined (not implemented), or attestation stale

### Binding Rules

- A feature cannot be marked `implemented` unless at least VT-1 exists and passes
- Contract changes (new MUST/MUST NOT, new features) reset attestation confidence to `low`
- Stale attestations (past `next_review`) trigger a warning during preflight
- The AI MUST NOT silently skip attestation checks — always report status

---

## Verification Tests (Contract-Level TDD)

Each contract defines 1-3 Verification Tests (VTs) — high-leverage tests that prove the module actually works, not just that it compiles.

### Philosophy

One smart test beats ten shallow tests. A VT tests the **golden path** through the module — the scenario a real user performs first. By asserting on **actual output content** (not just status codes or "no error"), a single VT implicitly validates every component in the chain.

### What Makes a Good VT

| Good VT | Bad VT |
|---------|--------|
| Checks actual response text/value | Checks "response is not null" |
| Tests the full user journey through the module | Tests one isolated function |
| Fails if ANY core feature breaks | Only fails if one specific thing breaks |
| Uses realistic input data | Uses trivial/empty test data |
| Assertion proves correctness | Assertion proves execution |

### VT Count by Tier

| Tier | VTs | Focus |
|------|-----|-------|
| core | 1 | Round-trip correctness of primary responsibility |
| standard | 1-2 | Golden path + most important edge case |
| complex | 2-3 | Golden path + error resilience + secondary flow |

### VT in Templates

All templates (core, feature, integration, utility) include a `## Verification Tests` section with tier-appropriate guidance and concrete examples. See `../skill/references/templates/`.

---

## Constraints

### NEVER
- Edit CONTRACT.md after initialization (unless user requests a draft)
- Proceed with changes that violate CONTRACT.md constraints
- Create code in a module without checking for contracts first
- Ignore hash mismatches — always sync first
- Delete or overwrite changelog entries
- Start feature work without closing the Beads preflight task
- Mark a feature as `implemented` without at least VT-1 existing and passing
- Skip attestation checks during preflight — always report status
- Ignore stale attestations (past `next_review` date)

### ALWAYS
- Read CONTRACT.md before any module changes
- Update CONTRACT.yaml when CONTRACT.md changes
- Add changelog entry for every YAML update
- Verify feature status matches actual implementation
- Flag when implementation deviates from contract
- Suggest contract updates when user requests features not in spec
- Check if tests exist for features marked as implemented
- Create and close Beads preflight tasks for every implementation cycle
- Check verification test status during preflight (defined/implemented/passing/failing)
- Update attestation after implementing features or fixing VTs
- Flag contracts with `confidence: low` — prompt user to implement VTs
- Suggest VTs when creating new contracts (use template guidance)

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

**User adds feature to CONTRACT.md**: AI syncs YAML (new feature entry, updated hash, changelog), resets attestation confidence to `low`, then offers to implement.

**New module**: AI generates draft CONTRACT.md from template (including VTs), user reviews, AI creates matching YAML and registry entry.

**Beads enforcement**: Feature task created → depends on PREFLIGHT task → agent runs preflight (incl. attestation + VT check), closes with summary → feature task unblocks → implementation begins.

**Stale attestation**: Preflight detects `next_review` past due → warns user, suggests running VTs to re-verify module health.
