# [Feature Name]

## Purpose
<!-- What user problem does this solve? Not: what does it export. -->
[1-3 sentences: the user-facing value this module provides]

## Core Features
<!-- Each feature should map to a test -->
- [ ] Feature 1: [Description] → Test: [file or "TODO"]
- [ ] Feature 2: [Description] → Test: [file or "TODO"]

## Constraints
- MUST: [Testable requirement with measurable criterion]
- MUST NOT: [Anti-pattern that would cause test failure]

## Success Criteria
<!-- Each criterion = a test scenario. Be specific. -->
<!-- GOOD: "Given invalid token, when accessing /api, then returns 401 within 50ms" -->
<!-- BAD: "Module works correctly" (untestable) -->
- [ ] Given [context], when [action], then [expected outcome]
- [ ] [Metric]: [target value]

## Verification Tests
<!--
  1-3 tests that prove the module ACTUALLY WORKS through its golden path.
  Each test maximizes implicit coverage: one action that can only succeed
  if multiple core features are functioning correctly together.

  PRINCIPLE: Verify CONTENT, not just status codes.
  A test that checks "response is not empty" proves nothing.
  A test that checks "response contains the expected calculated value" proves everything.

  EXAMPLE — Chat Agent Module:
    Do:     Login → open chat → send "What is 2+2?"
    Assert: Response text contains "4"
  → 1 test, but implicitly validates: login, routing, UI, API, LLM, rendering

  HOW TO CHOOSE:
  - Pick the scenario a real user would do FIRST after opening the app
  - The assertion must check actual output content (text, value, state)
  - Ask: "If this test passes, can I be confident the module works?" → Yes = good test
-->
- [ ] **VT-1: [Golden-path scenario name]**
  - Do: [setup → trigger primary action → observe result]
  - Assert: [exact output content — text, value, or state to check]

- [ ] **VT-2: [Critical-edge scenario name]** *(if standard/complex tier)*
  - Do: [trigger most important failure mode]
  - Assert: [specific expected output for this edge case]
