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
    Scenario: User sends a factual question and receives a correct answer
    Action:   Login with test credentials → open chat → send "What is 2+2?"
    Verify:   Response text contains "4"
    Proves:   Auth works, session is valid, chat UI renders, message is sent,
              LLM processes request, response is received and displayed,
              app returns real answers (not error/default page)
  → 1 test, but implicitly validates: login, routing, UI, API, LLM, rendering

  HOW TO CHOOSE:
  - Pick the scenario a real user would do FIRST after opening the app
  - The assertion must check actual output content (text, value, state)
  - Ask: "If this test passes, can I be confident the module works?" → Yes = good test
-->
- [ ] **VT-1: [Golden-path scenario name]**
  - Scenario: [What the user does — the realistic end-to-end flow]
  - Action: [Concrete steps: setup → trigger → observe]
  - Verify: [Content-level assertion — exact text, value, or state to check]
  - Proves: [Features that MUST work for this test to pass, comma-separated]

- [ ] **VT-2: [Critical-edge scenario name]** *(if standard/complex tier)*
  - Scenario: [The most important failure mode or secondary path]
  - Action: [Steps to trigger the edge case]
  - Verify: [What correct handling looks like — specific output]
  - Proves: [Error handling, fallback, or secondary features validated]
