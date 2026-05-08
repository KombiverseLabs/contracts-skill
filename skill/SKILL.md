---
name: contracts
description: Use when creating, changing, reviewing, or initializing modules that use living CONTRACT.md/CONTRACT.yaml specs; before code changes that need contract preflight, drift checks, verification tests, acceptance tests, contract sync, or optional Beads-enforced preflight.
---

# Contracts

Keep implementation aligned with living module contracts.

Each contracted module has:
- `CONTRACT.md`: user-owned intent and constraints. Do not edit unless the user asks for a draft or approves the change.
- `CONTRACT.yaml`: AI-maintained technical mapping, status, hashes, verification tests, acceptance tests, and attestation.

## Core Workflow

Before changing code in a contracted module:

1. Look for `.contracts/CONTRACTS-GUIDE.md`; read it first if present.
2. Identify impacted files or modules from the request.
3. Find the nearest `CONTRACT.md` by walking from each target path up to the project root.
4. Read `CONTRACT.md` and `CONTRACT.yaml`.
5. Compare `CONTRACT.yaml` `meta.source_hash` with the current SHA256 of `CONTRACT.md`.
6. Stop and sync YAML first if drift exists.
7. Check MUST/MUST NOT constraints, out-of-scope items, VT status, acceptance tests, attestation, and dependent contracts.
8. Report brief contract notes, then proceed only if the planned work fits the contract.

Use `scripts/contract-preflight.ps1` or `scripts/contract-preflight.sh` when file-level input or git-diff input is available.

## Contract Rules

- Treat `CONTRACT.md` as user authority.
- Keep `CONTRACT.yaml` synced whenever `CONTRACT.md` changes.
- Never fabricate VT results, feature status, hashes, or attestation.
- A feature is not `implemented` unless its verification path is real and VT-1 is passing.
- Every contract needs at least one measurable acceptance test.
- If requested work exceeds the contract, stop and ask whether to update the contract or mark it out of scope.

## Creating Or Initializing Contracts

For `init contracts`, use an agent-led flow:

1. Read existing `.contracts/CONTRACTS-GUIDE.md` if present.
2. Inspect project manifests, source layout, public APIs, tests, and existing contracts.
3. Present recommended contract locations and reasons.
4. Draft `CONTRACT.md`, `CONTRACT.yaml`, registry, and guide changes for user review.
5. Write files only after explicit approval.

The deterministic Node helper under `ai/init-agent/` can analyze and draft from source structure, but it is optional support for the agent workflow. Any CLI apply mode must require `--apply --yes`.

## Verification

- Run `scripts/validate-contracts.ps1 -Path <project>` to check drift and contract structure.
- Run `scripts/run-vts.ps1 -Path <project>` or `scripts/run-vts.sh --path <project>` when VTs define runnable commands.
- Update attestation and VT status only from actual command results.

## Beads Enforcement

If the project has Beads (`.beads/` and `bd` CLI), use Beads as an enforcement mode of this skill, not as a separate skill. Read `references/beads-enforcement.md` before planning or editing code in that project.

## Load When Needed

- `references/assistant-hooks/contract-preflight.md`: detailed preflight checks.
- `references/assistant-hooks/init-contracts.md`: agent-led project initialization.
- `references/assistant-hooks/contract-review.md`: scope and drift review after or during work.
- `references/beads-enforcement.md`: Beads task lifecycle and hook behavior.
- `references/instruction-hooks/`: installable hook snippets for `AGENTS.md` and legacy instruction files.
- `references/templates/`: empty contract scaffolds.
- `references/examples/`: filled examples showing the quality bar.
- `references/project-guide.md`: template for `.contracts/CONTRACTS-GUIDE.md`.

Load only the references needed for the current task.
