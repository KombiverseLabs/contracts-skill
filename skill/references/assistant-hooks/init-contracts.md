# Contract Initialization

Use this reference for requests like "init contracts", "initialize contracts", "create a contract for this module", or "set up contracts".

Initialization is agent-led. Scripts may assist analysis, but the agent owns discovery, user review, and approval before writing files.

## Flow

1. Read `.contracts/CONTRACTS-GUIDE.md` if it exists and reuse existing project name, stack, owner, conventions, and module table.
2. Inspect project context:
   - manifests such as `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`
   - source directories such as `src/`, `lib/`, `app/`, `packages/`, `cmd/`, `internal/`
   - public exports, entry points, tests, and existing `CONTRACT.md` files
3. Ask only for missing project intent that cannot be inferred.
4. Present a module recommendation table with path, type, tier, and reason.
5. Draft contract files for approved modules:
   - `CONTRACT.md` from `references/templates/`
   - `CONTRACT.yaml` with normalized SHA256 of the draft `CONTRACT.md`
   - `.contracts/registry.yaml`
   - `.contracts/CONTRACTS-GUIDE.md` from `references/project-guide.md`
6. Show the draft or diff to the user.
7. Write files only after explicit approval.
8. If the project uses contract locking, lock approved `CONTRACT.md` files after writing and YAML sync.

## Optional CLI Helper

The deterministic helper under `ai/init-agent/` can inspect project structure and draft contracts:

```bash
node <skill-dir>/ai/init-agent/index.js --path . --analyze
node <skill-dir>/ai/init-agent/index.js --path . --dry-run
node <skill-dir>/ai/init-agent/index.js --path . --apply --yes
```

Never run apply mode without both `--apply` and `--yes`, and never treat helper output as final without user review.

## Draft Quality

Good contracts:

- describe the user or system responsibility in `Purpose`
- map features to real or planned tests
- express constraints as testable MUST/MUST NOT statements
- include out-of-scope boundaries
- include at least one measurable acceptance test
- define VTs with content/value/state assertions, not only "no error" or "status 200"

Use `references/examples/` to match the expected quality level.

## Special Cases

- Monorepos: recommend package-level contracts first, then module contracts inside high-risk packages.
- Existing contracts: report coverage gaps, do not overwrite unless the user approves.
- Locked contracts: propose diffs first, then unlock only after explicit approval.
- Non-standard structures: rank likely modules by source volume, entry points, tests, and public APIs.
- Beads projects: read `references/beads-enforcement.md` before creating preflight tasks.
- Locking projects: read `references/contract-locking.md` before changing approved contracts.

## After Writing

Tell the user to review each `CONTRACT.md`, remove draft markers when satisfied, and commit `.contracts/` plus contract files. Recommend implementing VT-1 for each new contract before broad feature work. If contract locking is enabled, run the lock script after human approval.
