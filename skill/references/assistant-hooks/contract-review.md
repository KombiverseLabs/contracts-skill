# Assistant Hook: Contract Review

**Trigger phrases:** "contract review", "review contracts", "should I update the contract", "scope change"

---

## Purpose

Detect when implementation has drifted from the contract specification and propose updates. This hook triggers when:
- Work introduces features NOT in `CONTRACT.md`
- Attestation `next_review` date has passed
- A dependency consumed by other contracts changes
- User explicitly asks for a contract review

---

## Review Steps

### 1. Scope Check

Compare planned or completed work against `CONTRACT.md`:
- List all functions/classes/exports created or modified
- Check each against `CONTRACT.yaml` → `features[]` and `validation.exports[]`
- **New export not in contract?** → Flag: "Created `[name]` which isn't in the contract."

### 2. Attestation Freshness

Read `CONTRACT.yaml` → `attestation`:
- If `next_review` < today → "Contract re-verification overdue since [date]."
- If `contract_version` differs from `meta.version` → "Contract evolved since last verification."
- If `confidence: low` → "VTs not implemented or failing."

### 3. Dependency Impact

Check `registry.yaml` for contracts that `consumed_by` or `depends_on` the changed module:
- If any dependent contract exists → "Changes may affect: [list]."
- If a dependent module's contract has MUST constraints on the changed interface → warn specifically.

### 4. Feature Coverage

Count features in `CONTRACT.md` vs actual implementation:
- More features implemented than specified → suggest adding to contract
- Specified features not implemented → note gap with current status

### 5. Present Review Summary

Output structured review (max 7 sentences):
```
CONTRACT REVIEW: [module name]
- Scope: [in-scope / exceeded by N items]
- Attestation: [current / stale / missing]
- VTs: [all passing / N failing / not implemented]
- Dependencies: [none affected / N contracts may need update]
- Recommendation: [no action / update CONTRACT.md / run VTs / sync YAML]
```

### 6. Propose Contract Update

If scope was exceeded or contract is stale:
1. Generate a diff showing proposed additions to `CONTRACT.md`
2. Present to user: "Add these to the contract? Or mark as out-of-scope?"
3. On approval → update or draft `CONTRACT.md` changes, sync `CONTRACT.yaml`, reset attestation, and validate hashes
4. On rejection → add to `## Out of Scope` only if the user approves that contract edit

---

## Integration with Beads

If Beads is available (`bd` CLI + `.beads/` directory):
1. Create a review task: `bd create "CONTRACT REVIEW: [module]" -p 0 --tag contracts`
2. Include the review summary in the task design or close note
3. If update needed → create subtask for the contract update
4. Close review task with findings

This ensures contract reviews are tracked in the same task graph as implementation work.

---

## When NOT to Trigger

- Minor refactoring that doesn't change public API or behavior
- Test-only changes (adding tests doesn't change the contract)
- Documentation-only changes
- Changes to files outside any contract scope
