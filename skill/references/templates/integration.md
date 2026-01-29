# [Integration Name]

## Purpose
[1-3 sentences: What external system does this integrate with? What capability does it provide?]

Example: "Connects to the Payment Gateway API to process transactions. Handles authentication, request formatting, error handling, and response parsing."

## Core Features
- [ ] Connection management (establish, maintain, retry)
- [ ] Authentication/authorization handling
- [ ] Request formatting and validation
- [ ] Response parsing and error handling
- [ ] Rate limiting compliance
- [ ] Logging and monitoring hooks

## Constraints
- MUST: Handle all API error codes gracefully
- MUST: Implement exponential backoff for retries
- MUST: Validate all inputs before sending to external system
- MUST: Log all requests for audit purposes
- MUST NOT: Expose API keys in logs or error messages
- MUST NOT: Block the main thread during network operations

## Configuration
| Setting | Description | Required |
|---------|-------------|----------|
| API_KEY | Authentication key | Yes |
| BASE_URL | API endpoint | Yes |
| TIMEOUT | Request timeout (ms) | No (default: 30000) |
| RETRY_COUNT | Max retry attempts | No (default: 3) |

## Success Criteria
- [ ] Successfully authenticates with external system
- [ ] Handles all documented error scenarios
- [ ] Response time < 500ms for 95% of requests
- [ ] Zero data loss for successful transactions
- [ ] Graceful degradation when service is unavailable

## Notes
- [Link to API documentation]
- [Contact info for API support]
- [Testing environment details]
