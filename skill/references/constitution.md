# Contract Constitution

> Copy this file to `.contracts/CONSTITUTION.md` in your project.

This project uses contracts as the durable source of truth for AI-assisted development.

## Principles

1. `CONTRACT.md` is human-owned intent. Agents may draft changes, but humans approve them.
2. `CONTRACT.yaml` is the machine-readable mapping for status, traceability, tests, and attestation.
3. Specifications drive implementation. Code changes that exceed the contract require a contract update first.
4. TDD is required for contracted behavior: red test first, minimal implementation, green verification.
5. Verification tests assert content, values, or state, not only successful execution.
6. Attestation records only real command results.

## Required Lifecycle

Specify -> Clarify -> Plan -> Test First -> Implement -> Verify -> Attest

## Required Traceability

New or migrated contracts use `F-*`, `REQ-*`, `AC-*`, `AT-*`, and `VT-*` IDs. Every requirement must be covered by at least one verification or acceptance path.
