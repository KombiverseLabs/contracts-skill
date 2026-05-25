# Authentication

## Purpose
Handles user authentication including login, logout, and session management for the application.

## Core Features
- [x] [F-001] Email/password login -> Test: `login.test.ts` -> Verifies: [REQ-001]
- [x] [F-002] Session tokens with automatic refresh -> Test: `session.test.ts` -> Verifies: [REQ-002]
- [ ] [F-003] OAuth2 integration (Google, GitHub) -> Test: TODO -> Verifies: [REQ-003]
- [ ] [F-004] Password reset via email -> Test: TODO -> Verifies: [REQ-004]

## Constraints
- MUST [REQ-001]: Use bcrypt with cost factor 12 for password hashing
- MUST [REQ-002]: Expire sessions after 24 hours of inactivity
- MUST [REQ-003]: Use HTTP-only cookies for session tokens
- MUST NOT [REQ-004]: Store passwords in plain text
- MUST NOT [REQ-005]: Log sensitive authentication data

## Success Criteria
- [AC-001] Given valid credentials, when login() is called, then returns session token within 200ms -> Verifies: [REQ-001]
- [AC-002] Given expired session, when validateSession() is called, then returns false and triggers refresh -> Verifies: [REQ-002]

## Acceptance Tests
- [ ] [AT-001] All verification tests pass -> Verifies: [REQ-001, REQ-002]
- [ ] [AT-002] Build succeeds

## Verification Tests
- [x] **VT-001: Full auth round-trip with credential verification**
  - Do: Register "test@example.com" → login → extract token → call /api/me
  - Assert: Response contains "test@example.com" AND token expiry is in the future
  - Verifies: [REQ-001, REQ-002, REQ-003]
