# [Core Module Name]

## Purpose
<!-- What foundational problem does this solve? Not: what functions does it have. -->
[1-2 sentences: the responsibility this module owns]

## Core Features
- [ ] Feature 1: [Essential capability] → Test: [file or "TODO"]
- [ ] Feature 2: [Essential capability] → Test: [file or "TODO"]

## Constraints
- MUST: [Critical requirement]
- MUST NOT: [What this module should never do]

## Success Criteria
<!-- GOOD: "Hashing completes in <10ms for inputs up to 1MB" -->
<!-- GOOD: "Failed login attempts are logged with timestamp and IP" -->
<!-- BAD: "Module functions correctly" (untestable) -->
<!-- BAD: "Handles errors gracefully" (undefined) -->
- [ ] [Specific, measurable criterion]

## Verification Tests
<!--
  1 test that proves the core module fulfills its primary responsibility.
  Core modules are foundational — the test must verify that the ONE thing
  this module is responsible for actually produces correct output.

  PRINCIPLE: Test the output, not the mechanism.
  Don't test "bcrypt is called" — test "password hash is valid and verifiable."
  Don't test "token is returned" — test "token contains correct user ID and expiry."

  EXAMPLE — Auth Core Module:
    Scenario: Full auth round-trip with credential verification
    Action:   Create user with known password → login → extract token → validate token
    Verify:   Decoded token contains correct user ID AND password hash verifies against original
    Proves:   Hashing, storage, login, token generation, token validation — all in one chain

  HOW TO CHOOSE:
  - What would break if this module silently returned wrong values?
  - The assertion must verify CORRECTNESS of output, not just presence
-->
- [ ] **VT-1: [Round-trip verification name]**
  - Scenario: [Input → full processing chain → verified output]
  - Action: [Feed known input, capture final output]
  - Verify: [Output matches expected value — proves correctness, not just execution]
  - Proves: [All internal steps that must work for the output to be correct]
