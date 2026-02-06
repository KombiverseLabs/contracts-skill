# Assistant Hook: Contract Preflight (Before Work)

**Trigger phrases:** "contract preflight", "before you start", "implement", "fix", "refactor", "add feature"

---

## Purpose

Ensure every implementation stays aligned with module contracts.
The assistant MUST perform this preflight **before** planning or editing code.

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

### 4. Test Coverage Check
- Do features being changed have corresponding test files?
- If a feature status is `implemented` but no tests exist → **warn the user**
- If adding a new feature → ask where tests should go

### 5. Dependency Impact Check
- Check `registry.yaml` for modules that depend on the one being changed
- If dependents exist → note which contracts may be affected
- If changes could break dependent contracts → warn before proceeding

### 6. Return Contract Notes (max 5 sentences)
Summarize:
- MUST and MUST NOT constraints affecting the requested change
- Test coverage status for impacted features
- Dependent modules that may be affected

---

## Helper Command

```powershell
pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -Path . -OutputFormat json
```

Then present a short summary (max 5 sentences) and proceed with implementation.
