# Assistant Hook: Contract Preflight (Before Work)

**Trigger phrases (recommended):**
- "contract preflight"
- "before you start"
- "implement"
- "fix"
- "refactor"
- "add feature"

---

## Purpose

Ensure every implementation stays aligned with the relevant module contracts.
The assistant must perform a short preflight **before** planning or editing code.

---

## Mandatory Preflight Behavior (Assistant)

1. **Identify impacted scope**
   - From the user request, infer which folders/files/modules will be changed.
   - If unclear, ask **one** clarifying question to narrow the target module(s).

2. **Locate contracts for each impacted module**
   - For each target path, walk up parent directories until you find `CONTRACT.md`.
   - If no contract exists for a target module, say so and offer to create one.

3. **Read + validate**
   - Read `CONTRACT.md` (spec) and `CONTRACT.yaml` (mapping).
   - Check drift: compare `CONTRACT.yaml.meta.source_hash` to the current SHA256 of `CONTRACT.md`.
   - If drift exists, **stop** and sync YAML first (don’t implement features yet).

4. **Return a user-facing “Contract Notes” summary (max 5 sentences)**
   - Summarize the **MUST** and **MUST NOT** constraints that affect the requested change.
   - If multiple modules are involved, prioritize the ones you will edit first.
   - Keep it short: **≤ 5 sentences total**.

---

## Recommended Helper Command

If the contracts skill is installed in a project, use the helper to gather relevant contracts:

PowerShell:
```powershell
pwsh .github/skills/contracts/scripts/contract-preflight.ps1 -Path . -Changed -OutputFormat json
```

Then present a short summary to the user (≤ 5 sentences), and proceed with implementation.
