# [Integration Name]

## Purpose
<!-- What external system? What capability does it provide to the application? -->
[1-3 sentences: the external system and the value of integrating with it]

## Core Features
- [ ] Connection management (establish, maintain, retry) → Test: [file or "TODO"]
- [ ] Authentication/authorization handling → Test: [file or "TODO"]
- [ ] Request formatting and validation → Test: [file or "TODO"]
- [ ] Response parsing and error handling → Test: [file or "TODO"]
- [ ] Rate limiting compliance → Test: [file or "TODO"]

## Constraints
- MUST: Handle all API error codes gracefully
- MUST: Implement exponential backoff for retries
- MUST: Validate all inputs before sending to external system
- MUST NOT: Expose API keys in logs or error messages
- MUST NOT: Block the main thread during network operations

## Configuration
| Setting | Description | Required |
|---------|-------------|----------|
| API_KEY | Authentication key | Yes |
| BASE_URL | API endpoint | Yes |
| TIMEOUT | Request timeout (ms) | No (default: 30000) |

## Success Criteria
<!-- Each criterion should reference a test -->
- [ ] Given valid credentials, when connecting, then auth succeeds → Test: [file]
- [ ] Given API timeout, when requesting, then retries with backoff → Test: [file]
- [ ] Given rate limit hit, when requesting, then queues and retries → Test: [file]
- [ ] Given service unavailable, when requesting, then degrades gracefully → Test: [file]

## Verification Tests
<!--
  1-3 tests that prove the integration ACTUALLY CONNECTS and RETURNS REAL DATA.
  Integration tests are worthless if they only test mocks. At least VT-1 must
  hit the real external system (or a faithful staging environment).

  PRINCIPLE: Verify the CONTENT of the response, not just the HTTP status.
  "200 OK" proves the network works. Checking that the response body contains
  expected domain-specific data proves the integration works.

  EXAMPLE — Payment Gateway Integration:
    Do:     Send $1.00 charge to sandbox → await response
    Assert: transaction_id matches "txn_[a-z0-9]+" AND status "succeeded" AND amount 100

  EXAMPLE — Email Service Integration:
    Do:     Send email to test inbox → poll inbox API for arrival
    Assert: Received subject matches sent subject AND body contains expected text

  HOW TO CHOOSE:
  - Use the simplest possible real request that returns verifiable domain data
  - The assertion must check response CONTENT, not just shape/status
  - Ask: "Could a misconfigured integration pass this test?" → No = good test
-->
- [ ] **VT-1: [Real round-trip name]**
  - Do: [send minimal valid request → capture response]
  - Assert: [domain-specific content in response — not just status/shape]

- [ ] **VT-2: [Failure resilience name]** *(if standard/complex tier)*
  - Do: [trigger timeout/error condition]
  - Assert: [specific fallback output — not generic error]

## Notes
- [Link to API documentation]
- [Testing environment details]
