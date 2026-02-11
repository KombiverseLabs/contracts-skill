# Assistant Hook: Contract Preflight (Before Work) — Beads-Enforced

**Trigger phrases:** "contract preflight", "before you start", "implement", "fix", "refactor", "add feature"

---

## Purpose

Ensure every implementation stays aligned with module contracts.
The assistant MUST perform this preflight **before** planning or editing code.
Beads enforces this: feature tasks are blocked until the preflight task is closed.

---

## Mandatory Preflight Steps

### 1. Beads Preflight Task

Create or locate the preflight task in Beads:
```bash
# Check for existing open preflight
bd list --status open --tag contracts

# If none exists, create one
bd create "PREFLIGHT: Check contracts for [module/scope]" -p 0 --tag contracts
```

All feature work tasks MUST depend on this preflight task. The agent cannot proceed until the preflight task is closed with a summary.

### 2. Identify Impacted Scope

From the user request, infer which modules will be changed.
If unclear, ask **one** clarifying question.

### 3. Locate Contracts

For each target path, walk up parent directories until `CONTRACT.md` is found.
If no contract exists, say so and offer to create one.

### 4. Read and Validate

- Read `CONTRACT.md` (spec) and `CONTRACT.yaml` (mapping)
- Compare `meta.source_hash` to current SHA256 of CONTRACT.md
- If drift → **STOP** and sync YAML first
- If hash is corrupted/empty → run recovery (see SKILL.md "Hash Recovery")

### 5. Test Coverage Check

- Do features being changed have corresponding test files?
- If a feature status is `implemented` but no tests exist → **warn the user**
- If adding a new feature → ask where tests should go

### 6. Dependency Impact Check

- Check `registry.yaml` for modules that depend on the one being changed
- If dependents exist → note which contracts may be affected
- If changes could break dependent contracts → warn before proceeding

### 7. Close Preflight Task

Summarize (max 5 sentences) and close the Beads task:
```bash
bd close <preflight-task-id> --design "Checked [modules]. MUST: [constraints]. Tests: [status]. Dependents: [list]."
```

This unblocks all feature tasks that depend on the preflight.

---

## Helper Command

```powershell
pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -Path . -OutputFormat json
```

Then present a short summary (max 5 sentences) and proceed with implementation.
