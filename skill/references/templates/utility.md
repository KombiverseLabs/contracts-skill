# [Utility Name]

## Purpose
[1-2 sentences: What common operations does this utility provide?]

Example: "Collection of string manipulation helpers used across the application."

## Core Functions/Methods
- [ ] `function1(param)` - Brief description
- [ ] `function2(param)` - Brief description
- [ ] `function3(param)` - Brief description

## Constraints
- MUST: Be pure functions (no side effects)
- MUST: Handle null/undefined inputs gracefully
- MUST: Include JSDoc/type annotations
- MUST NOT: Depend on external state
- MUST NOT: Throw unexpected exceptions (return Results/Options instead)

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
- [ ] All functions have unit tests
- [ ] 100% code coverage
- [ ] Documentation complete for all exports
- [ ] No dependencies on other project modules

## Verification Tests
<!--
  1 test that proves the utility produces CORRECT RESULTS, not just "runs."
  Utilities are pure functions — test with known input/output pairs
  that exercise the core logic, including edge cases.

  PRINCIPLE: Use a composite input that forces multiple code paths.
  Don't test formatDate("2024-01-01") — test formatDate with timezone edge case,
  null input, and locale-specific formatting in one parameterized assertion.

  EXAMPLE — String Utility Module:
    Scenario: Slug generation handles real-world messy input
    Action:   slugify("  Héllo Wörld! @#$ 你好  ")
    Verify:   Returns exactly "hello-world-ni-hao" (trimmed, lowered, transliterated, special chars removed)
    Proves:   Trimming, lowercasing, unicode transliteration, special char removal, space-to-dash — one call

  HOW TO CHOOSE:
  - Pick the messiest realistic input your utility should handle
  - The expected output must be exact (not "looks right" but "equals X")
  - Ask: "If the core algorithm was broken, would this test catch it?" → Yes = good test
-->
- [ ] **VT-1: [Composite correctness check name]**
  - Scenario: [Most complex realistic input this utility handles]
  - Action: [Call with carefully chosen input that exercises core logic]
  - Verify: [Exact expected output — literal value comparison]
  - Proves: [All transformations/steps the utility performs internally]

## Notes
- Keep this module dependency-free when possible
- Consider publishing as standalone package if widely useful
