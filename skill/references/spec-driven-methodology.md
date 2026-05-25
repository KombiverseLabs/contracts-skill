# Spec-Driven Methodology

Use this reference when creating, reviewing, or changing contracts under the Spec-Kit-inspired workflow. Do not require GitHub Spec Kit, `specify`, or `.specify/` files. The contracts system owns the durable artifacts.

## Artifact Mapping

| Spec-Kit idea | Contracts system artifact |
|---------------|---------------------------|
| Constitution | `.contracts/CONSTITUTION.md` plus `.contracts/CONTRACTS-GUIDE.md` |
| Specify | Create or revise `CONTRACT.md` |
| Clarify | Resolve ambiguity, placeholders, untestable language, and scope gaps |
| Plan / Tasks | Sync `CONTRACT.yaml`, TDD plan, and optional Beads tasks |
| Implement | Red/Green/Refactor against the approved contract |
| Verify | Run VTs and acceptance tests |
| Attest | Update YAML status only from real command output |

## Lifecycle Gate

Every new or migrated contract follows:

1. Specify: write user intent, features, requirements, acceptance criteria, and VTs in `CONTRACT.md`.
2. Clarify: remove placeholders, ambiguous terms, and untestable constraints.
3. Plan: sync `CONTRACT.yaml` with IDs and traceability links.
4. Test First: write tests, run them, and confirm the expected red failure.
5. Implement: write the minimal code that makes the red tests green.
6. Verify: run VTs and acceptance tests with content assertions.
7. Attest: record real results in `CONTRACT.yaml`.

Do not implement code for a contracted module until the contract is at least specified, clarified, and planned.

## Traceability IDs

Use stable IDs in new or migrated contracts:

- Feature: `[F-001]`
- Requirement or constraint: `MUST [REQ-001]: ...` or `MUST NOT [REQ-002]: ...`
- Acceptance criterion: `[AC-001] Given ... when ... then ...`
- Acceptance test (gate): `[AT-001] All VTs pass`
- Verification test: `VT-001`

Every `REQ-*` must be covered by at least one `VT-*`, `AC-*`, or `AT-*` in `CONTRACT.yaml` through `verifies` or `covered_by`.

## TDD Evidence

`CONTRACT.yaml` tracks TDD evidence. Set `tdd.red_verified` only after the expected failing test has been observed. Set `tdd.green_verified` only after the same behavior passes. A feature cannot be `implemented` without a passing VT and test-first evidence.
