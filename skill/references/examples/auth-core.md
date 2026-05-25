# Auth Core

## Purpose
Manages user identity and session state across the application. Handles credential verification, token issuance, session persistence, and token refresh — so that every other module can trust the identity it receives.

## Core Features
- [x] [F-001] Credential verification (email + password) -> Test: `tests/auth/login.test.ts` -> Verifies: [REQ-001]
- [x] [F-002] Password hashing and comparison -> Test: `tests/auth/hash.test.ts` -> Verifies: [REQ-001]
- [x] [F-003] Session token issuance (JWT, 15 min expiry) -> Test: `tests/auth/token.test.ts` -> Verifies: [REQ-002, REQ-003]
- [ ] [F-004] Refresh token rotation (7 day window) -> Test: `tests/auth/refresh.test.ts` -> Verifies: [REQ-004]
- [ ] [F-005] Token revocation (logout, password change) -> Test: `tests/auth/revoke.test.ts` -> Verifies: [REQ-005]

## Constraints
- MUST [REQ-001]: Hash passwords with bcrypt, minimum 12 rounds
- MUST [REQ-002]: Sign JWTs with RS256 (not HS256) using the key at `AUTH_PRIVATE_KEY`
- MUST [REQ-003]: Include `sub` (user ID), `iat`, `exp`, `roles` in every token payload
- MUST NOT [REQ-004]: Log plaintext passwords or tokens at any log level
- MUST NOT [REQ-005]: Return different error messages for "user not found" vs "wrong password" (timing-safe)
- MUST NOT [REQ-006]: Store session state server-side — tokens are self-contained

## Success Criteria
- [AC-001] Given valid credentials, when `login()` is called, then returns a signed JWT within 200ms -> Verifies: [REQ-001, REQ-002]
- [AC-002] Given an expired token, when `validateSession()` is called, then returns `{ valid: false, reason: "expired" }` -> Verifies: [REQ-003]
- [AC-003] Given a valid refresh token, when `refresh()` is called, then issues a new access token and rotates the refresh token in a single atomic operation -> Verifies: [REQ-004]

## Out of Scope
- OAuth / SSO flows (handled by `auth-providers` module)
- Role-based access control enforcement (handled by `permissions` middleware)
- Multi-factor authentication
- Account registration / email verification

## Acceptance Tests
- [ ] [AT-001] All verification tests pass with current credentials fixture
- [ ] [AT-002] Build succeeds with zero TypeScript errors
- [ ] [AT-003] No plaintext secrets appear in test output or logs -> Verifies: [REQ-004]
- [ ] [AT-004] Token round-trip (issue → validate → decode) produces matching user ID -> Verifies: [REQ-003]

## Verification Tests

- [x] **VT-001: Login round-trip produces verifiable token**
  - Do: Call `login({ email: "fixture@test.com", password: "correct-password" })` → decode returned JWT
  - Assert: Decoded payload contains `sub === "user-fixture-001"` AND `roles` includes `"user"` AND `exp - iat === 900`
  - Verifies: [REQ-001, REQ-002, REQ-003]
  - Proves: credential lookup, bcrypt comparison, JWT signing, payload structure all work end-to-end

- [ ] **VT-002: Expired token is rejected with correct reason**
  - Do: Forge a JWT with `exp` set to `Date.now() - 1000`, call `validateSession(token)`
  - Assert: Returns `{ valid: false, reason: "expired" }` — NOT a thrown exception, NOT `{ valid: false }` without reason
  - Verifies: [REQ-003]
  - Proves: expiry check, structured error response, no crash on invalid token
