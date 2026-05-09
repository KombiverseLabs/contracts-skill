# Assistant Hook: Contract Preflight (Before Work)

## Purpose

Ensure every implementation stays aligned with module contracts.
Perform this before planning or editing code in a contracted module.

---

## Mandatory Preflight Steps

### 1. Identify Impacted Scope
From the user request, infer which modules will be changed.
If unclear, ask **one** clarifying question.

### 2. Locate Contracts
For each target path, walk up parent directories until `CONTRACT.md` is found.
If no contract exists, say so and offer to create one.

### 3. Read and Validate
- Read `CONTRACT.md` (spec) and `CONTRACT.yaml` (mapping)
- Compare `meta.source_hash` to current SHA256 of CONTRACT.md
- If drift → **STOP** and sync YAML first
- If hash is corrupted or empty, compute the normalized SHA256 and ask before replacing it
- If `CONTRACT.md` is locked/read-only, treat contract text as human-owned: do not unlock or edit it without explicit approval

### 4. Attestation Check
- Read `attestation` section from `CONTRACT.yaml`
- **Version mismatch**: If `attestation.contract_version` differs from `meta.version` → contract has evolved past implementation. Flag: "Contract updated since last verification — re-verification needed."
- **Stale attestation**: If `attestation.next_review` is past current date → Flag: "Contract re-verification overdue. Recommend running VTs."
- **Low confidence**: If `attestation.confidence` is `low` → Flag: "Contract has low confidence — VTs not yet implemented or failing."
- If no attestation exists yet → note this as a gap, proceed but flag at end

### 5. Verification Test Status
- Check `verification_tests` in `CONTRACT.yaml`
- Report status of each VT: `defined` | `implemented` | `passing` | `failing`
- If any VT is `failing` → **warn**: "VT-X is failing — this may indicate broken functionality"
- If VTs are only `defined` (no test file exists) → **warn**: "VTs are defined but not yet implemented — contract is not fully verified"
- If features are marked `implemented` but VT-1 is not `passing` → **STOP**: "Feature marked as implemented but VT-1 is not passing. Verify or fix before proceeding."

### 6. Acceptance Test Check
- Check `acceptance_tests` section in `CONTRACT.yaml`
- If empty or missing → **warn**: "Contract has no acceptance tests. Every contract must define at least one measurable AT."
- If acceptance tests exist → confirm count and types (vt_pass, command, http, arena_score)

### 7. Out of Scope Check
- Read `## Out of Scope` section from `CONTRACT.md` (if it exists)
- Compare planned changes against out-of-scope items
- If a planned change matches an out-of-scope item → **STOP**: "[X] is listed as Out of Scope in the contract."

### 8. Test Coverage Check
- Do features being changed have corresponding test files?
- If a feature status is `implemented` but no tests exist → **warn the user**
- If adding a new feature → ask where tests should go and suggest a VT update

### 9. Dependency Impact Check
- Check `registry.yaml` for modules that depend on the one being changed
- If dependents exist → note which contracts may be affected
- If changes could break dependent contracts → warn before proceeding

### 10. Return Contract Notes (max 7 sentences)
Summarize:
- MUST and MUST NOT constraints affecting the requested change
- Attestation status (current / stale / missing)
- Verification test status (all passing / some failing / not implemented)
- Acceptance test status (defined / missing)
- Out of scope boundaries relevant to planned changes
- Test coverage status for impacted features
- Dependent modules that may be affected

---

## Post-Implementation: Update Attestation

After completing work on a contract-covered module:

1. Run verification tests (if implemented)
2. Update `CONTRACT.yaml` attestation:
   - `contract_version` → current version
   - `last_verified` → now
   - `verification_tests_pass` → true/false
   - `features_implemented` → list of implemented feature IDs
   - `confidence` → derive from VT status
   - `next_review` → current date + 30 days
3. Update `verification_tests[].last_run` and `last_result`
4. Add changelog entry

---

## Helper Command

```powershell
pwsh <skill-dir>/scripts/validate-contracts.ps1 -Path . -OutputFormat json
```

Then present a short summary (max 7 sentences) and proceed with implementation.
