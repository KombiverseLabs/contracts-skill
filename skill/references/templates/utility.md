# [Utility Name]

## Purpose
[1-2 sentences: What common operations does this utility provide?]

Example: "Collection of string manipulation helpers used across the application."

## Core Functions/Methods
- [ ] [F-001] `function1(param)` - Brief description -> Test: [file or "TODO"] -> Verifies: [REQ-001]
- [ ] [F-002] `function2(param)` - Brief description -> Test: [file or "TODO"] -> Verifies: [REQ-002]
- [ ] [F-003] `function3(param)` - Brief description -> Test: [file or "TODO"] -> Verifies: [REQ-003]

## Constraints
- MUST [REQ-001]: Be pure functions (no side effects)
- MUST [REQ-002]: Handle null/undefined inputs gracefully
- MUST [REQ-003]: Include JSDoc/type annotations
- MUST NOT [REQ-004]: Depend on external state
- MUST NOT [REQ-005]: Throw unexpected exceptions (return Results/Options instead)

## API

### function1(param: Type): ReturnType
Description of what it does.

**Parameters:**
- `param` (Type): Description

**Returns:**
- (ReturnType): Description

**Example:**
```javascript
const result = function1(input);
```

## Success Criteria
- [ ] [AC-001] All functions have unit tests -> Verifies: [REQ-001, REQ-002]
- [ ] [AC-002] 100% code coverage -> Verifies: [REQ-001]
- [ ] [AC-003] Documentation complete for all exports -> Verifies: [REQ-003]
- [ ] [AC-004] No dependencies on other project modules -> Verifies: [REQ-004]

## Out of Scope
<!-- What this utility does NOT handle. -->
- [Responsibility that belongs elsewhere]

## Acceptance Tests
<!-- REQUIRED. At least one measurable done-criterion. -->
- [ ] [AT-001] All verification tests pass
- [ ] [AT-002] Build succeeds
- [ ] [AT-003] [Additional measurable done-criterion]

## Verification Tests
<!--
  1 test that proves the utility produces CORRECT RESULTS, not just "runs."
  Utilities are pure functions — test with known input/output pairs
  that exercise the core logic, including edge cases.

  PRINCIPLE: Use a composite input that forces multiple code paths.
  Don't test formatDate("2024-01-01") — test formatDate with timezone edge case,
  null input, and locale-specific formatting in one parameterized assertion.

  EXAMPLE — String Utility Module:
    Do:     slugify("  Héllo Wörld! @#$ 你好  ")
    Assert: Returns exactly "hello-world-ni-hao"

  HOW TO CHOOSE:
  - Pick the messiest realistic input your utility should handle
  - The expected output must be exact (not "looks right" but "equals X")
  - Ask: "If the core algorithm was broken, would this test catch it?" → Yes = good test
-->
- [ ] **VT-001: [Composite correctness check name]**
  - Do: [call with input that exercises multiple code paths]
  - Assert: [exact expected output — literal value comparison]
  - Verifies: [REQ-001, REQ-002]

## Notes
- Keep this module dependency-free when possible
- Consider publishing as standalone package if widely useful
