# Beads Enforcement

Use this reference when a project has both the Contracts skill and Beads (`bd` CLI plus `.beads/`).

Beads makes contract preflight auditable and blocking. The main `contracts` skill still owns contract format, drift detection, templates, validation, and VT rules.

## Preflight Lifecycle

1. Check for an open contracts preflight task:

   ```bash
   bd list --status open --tag contracts
   ```

2. If no suitable preflight exists, create one:

   ```bash
   bd create "PREFLIGHT: Check contracts for <scope>" -p 0 --tag contracts
   ```

3. Make feature or fix tasks depend on the preflight task when using Beads task planning.
4. Run normal contract preflight:
   - locate nearest `CONTRACT.md`
   - read `CONTRACT.md` and `CONTRACT.yaml`
   - compare `meta.source_hash`
   - check constraints, out-of-scope items, acceptance tests, VT status, attestation, and dependents
5. If drift exists, stop and sync YAML before feature work.
6. Close the preflight task with a concise result:

   ```bash
   bd close <id> --design "Checked <modules>. Drift: <status>. Constraints: <summary>. VTs: <status>. ATs: <status>."
   ```

## Scope Changes

If requested work exceeds `CONTRACT.md`, create or update a Beads task for the contract decision before implementation:

```bash
bd create "CONTRACT UPDATE: <module> <change>" -p 0 --tag contracts
```

Ask whether the user wants the new behavior added to `CONTRACT.md` or explicitly marked out of scope. Sync `CONTRACT.yaml` only after the contract decision is approved.

## Initialization

During `init contracts` in a Beads project:

1. Verify `bd status` works.
2. Use the normal agent-led initialization workflow.
3. After approved contracts are created, add a standing preflight task if the project wants one:

   ```bash
   bd create "PREFLIGHT: Check CONTRACT.md before code changes" -p 0 --tag contracts --design "Before implementation: identify affected modules, read CONTRACT.md and CONTRACT.yaml, verify source_hash, summarize constraints, and sync YAML before work if drift exists."
   ```

## Hook Selection

Installer `--hooks auto` should use the Beads hook when `.beads/` exists in the project root; otherwise it should use the base hook.
