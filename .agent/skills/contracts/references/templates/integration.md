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

## Notes
- [Link to API documentation]
- [Testing environment details]
