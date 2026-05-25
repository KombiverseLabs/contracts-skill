# [Core Module Name]

## Purpose
<!-- What foundational problem does this solve? Not: what functions does it have. -->
[1-2 sentences: the responsibility this module owns]

## Core Features
- [ ] [F-001] [Essential capability] -> Test: [file or "TODO"] -> Verifies: [REQ-001]
- [ ] [F-002] [Essential capability] -> Test: [file or "TODO"] -> Verifies: [REQ-002]

## Constraints
- MUST [REQ-001]: [Critical requirement]
- MUST NOT [REQ-002]: [What this module should never do]

## Success Criteria
<!-- GOOD: "Hashing completes in <10ms for inputs up to 1MB" -->
<!-- BAD: "Module functions correctly" (untestable) -->
- [ ] [AC-001] [Specific, measurable criterion] -> Verifies: [REQ-001]

## Out of Scope
<!-- What this module does NOT do. Prevents scope creep. -->
- [Responsibility that belongs elsewhere]

## Acceptance Tests
<!-- REQUIRED. Define what "done" means — at least one measurable criterion. -->
- [ ] [AT-001] All verification tests pass -> Verifies: [REQ-001]
- [ ] [AT-002] Build succeeds
- [ ] [AT-003] [Additional measurable done-criterion]

## Verification Tests
<!--
  1 test that proves the core module fulfills its primary responsibility.
  Core modules are foundational — the test must verify that the ONE thing
  this module is responsible for actually produces correct output.

  PRINCIPLE: Test the output, not the mechanism.
  Don't test "bcrypt is called" — test "password hash is valid and verifiable."
  Don't test "token is returned" — test "token contains correct user ID and expiry."

  EXAMPLE — Auth Core Module:
    Do:     Create user → login → extract token → validate token
    Assert: Decoded token contains correct user ID AND password hash verifies

  HOW TO CHOOSE:
  - What would break if this module silently returned wrong values?
  - The assertion must verify CORRECTNESS of output, not just presence
-->
- [ ] **VT-001: [Round-trip verification name]**
  - Do: [feed known input → capture final output]
  - Assert: [exact expected value — proves correctness, not just execution]
  - Verifies: [REQ-001]
