# Authentication

## Purpose
Handles user authentication including login, logout, and session management for the application.

## Core Features
- [x] Email/password login
- [x] Session tokens with automatic refresh
- [ ] OAuth2 integration (Google, GitHub)
- [ ] Password reset via email

## Constraints
- MUST: Use bcrypt with cost factor 12 for password hashing
- MUST: Expire sessions after 24 hours of inactivity
- MUST: Use HTTP-only cookies for session tokens
- MUST NOT: Store passwords in plain text
- MUST NOT: Log sensitive authentication data

## Success Criteria
- Given valid credentials, when login() is called, then returns session token within 200ms
- Given expired session, when validateSession() is called, then returns false and triggers refresh

## Verification Tests
- [x] **VT-1: Full auth round-trip with credential verification**
  - Scenario: Create user with known password, login, use token to access protected resource
  - Action: Register "test@example.com" with password → login → extract token → call /api/me with token
  - Verify: Response contains "test@example.com" as email AND token expiry is in the future
  - Proves: Password hashing (bcrypt), user storage, login flow, token generation, token validation, session handling
