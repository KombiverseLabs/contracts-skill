# Contracts System — Project Guide

> **Permanent project artifact.** Commit this file to version control.
> This guide tells every developer and AI agent how the Contracts system is set up in *this* project.

---

## Project

**Name:** {{PROJECT_NAME}}
**Stack:** {{STACK}}
**Owner:** {{OWNER}}
**Initialized:** {{INIT_DATE}}

---

## Where to Find Things

| What you need | Location |
|---------------|----------|
| All contracts (registry) | `.contracts/registry.yaml` |
| A module's specification | `<module-dir>/CONTRACT.md` |
| A module's technical mapping | `<module-dir>/CONTRACT.yaml` |
| Contract templates | Skill: `references/templates/` |
| Init workflow (AI hook) | Skill: `references/assistant-hooks/init-contracts.md` |
| Preflight workflow (AI hook) | Skill: `references/assistant-hooks/contract-preflight.md` |
| Review workflow (AI hook) | Skill: `references/assistant-hooks/contract-review.md` |
| Validation script (Windows) | Skill: `scripts/validate-contracts.ps1` |

Skill is installed at:

{{SKILL_PATHS}}

---

## Registered Modules

{{MODULE_TABLE}}

*(Run `"init contracts"` or `"check contracts"` to populate this table after discovery.)*

---

## How Contracts Are Applied

### Before any code change

The AI runs a **contract preflight** automatically before touching any module:

1. Locate `CONTRACT.md` in or above the target directory.
2. Read spec + YAML, compare `source_hash`. Hash mismatch → sync YAML first, then continue.
3. Check attestation freshness and VT status.
4. Summarize MUST / MUST NOT constraints (max 5 sentences).

Say **`"contract preflight"`** to trigger manually at any time.

### When you change a module spec

1. Edit `CONTRACT.md` yourself — AI never modifies the spec.
2. Tell the AI: `"I've updated the contract for [module]"`.
3. AI syncs `CONTRACT.yaml`, resets attestation to `low`, adds changelog entry.

### When you add a new module

Say **`"init contracts for [module-path]"`** or **`"create a contract for [module]"`**.
AI analyzes the module, picks the right tier (core / standard / complex), drafts from the matching template, and presents it for your review. You approve, remove the `<!-- DRAFT -->` marker, and commit.

### When work is out of scope

If the AI says "this isn't in the contract" — that is **intended behavior**, not an error.
You have two options:
- Update `CONTRACT.md` to include the feature, then AI syncs YAML.
- Tell the AI to proceed and add the item to `## Out of Scope` in the contract.

---

## Quick Commands

| Intent | Say to your AI |
|--------|----------------|
| Initialize contracts for this project | `"init contracts"` |
| Check before implementing a feature | `"contract preflight"` |
| Review scope after completing work | `"contract review"` |
| Scan all contracts for drift | `"check contracts"` |
| Sync all YAMLs from changed MDs | `"sync contracts"` |

---

## Project Conventions

<!-- Fill in project-specific conventions once established, e.g.:
- Feature modules live in src/features/ — use the feature.md template
- Core infrastructure lives in src/core/ — use the core.md template
- Tests are co-located in __tests__/ next to source
- Contracts are per-module (not centralized in .contracts/)
- Hash re-verification happens on every PR review
-->

{{CONVENTIONS}}

---

## Contract Tiers

| Tier | MD line limit | Typical complexity | Verification tests |
|------|--------------|--------------------|--------------------|
| `core` | 30 lines | < 100 LOC, foundational module | 1 |
| `standard` | 50 lines | 100-500 LOC, feature module | 1-2 |
| `complex` | 80 lines | > 500 LOC, multi-concern module | 2-3 |

---

*Contracts Skill — https://github.com/kombifyio/contracts-skill*
