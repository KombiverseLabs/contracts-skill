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

### 5. Attestation Check

- Read `attestation` section from `CONTRACT.yaml`
- **Version mismatch**: If `attestation.contract_version` differs from `meta.version` → Flag: "Contract updated since last verification — re-verification needed."
- **Stale attestation**: If `attestation.next_review` is past current date → Flag: "Contract re-verification overdue."
- **Low confidence**: If `attestation.confidence` is `low` → Flag: "VTs not yet implemented or failing."
- If no attestation exists → note gap, proceed but flag at end

### 6. Verification Test Status

- Check `verification_tests` in `CONTRACT.yaml`
- Report each VT: `defined` | `implemented` | `passing` | `failing`
- If any VT is `failing` → **warn**: broken functionality detected
- If VTs only `defined` → **warn**: contract not fully verified
- If features `implemented` but VT-1 not `passing` → **STOP**: verify first

### 7. Test Coverage Check

- Do features being changed have corresponding test files?
- If a feature status is `implemented` but no tests exist → **warn the user**
- If adding a new feature → ask where tests should go and suggest VT update

### 8. Dependency Impact Check

- Check `registry.yaml` for modules that depend on the one being changed
- If dependents exist → note which contracts may be affected
- If changes could break dependent contracts → warn before proceeding

### 9. Close Preflight Task

Summarize (max 7 sentences) and close the Beads task:
```bash
bd close <preflight-task-id> --design "Checked [modules]. MUST: [constraints]. Attestation: [status]. VTs: [status]. Dependents: [list]."
```

This unblocks all feature tasks that depend on the preflight.

---

## Post-Implementation: Update Attestation

After completing work on a contract-covered module:

1. Run verification tests (if implemented)
2. Update `CONTRACT.yaml` attestation (version, timestamp, confidence, next_review)
3. Update `verification_tests[].last_run` and `last_result`
4. Add changelog entry

---

## Helper Command

```powershell
pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -Path . -OutputFormat json
```

Then present a short summary (max 7 sentences) and proceed with implementation.
