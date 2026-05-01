# Auth Core

## Purpose
Manages user identity and session state across the application. Handles credential verification, token issuance, session persistence, and token refresh — so that every other module can trust the identity it receives.

## Core Features
- [x] Credential verification (email + password) → Test: `tests/auth/login.test.ts`
- [x] Password hashing and comparison → Test: `tests/auth/hash.test.ts`
- [x] Session token issuance (JWT, 15 min expiry) → Test: `tests/auth/token.test.ts`
- [ ] Refresh token rotation (7 day window) → Test: `tests/auth/refresh.test.ts`
- [ ] Token revocation (logout, password change) → Test: `tests/auth/revoke.test.ts`

## Constraints
- MUST: Hash passwords with bcrypt, minimum 12 rounds
- MUST: Sign JWTs with RS256 (not HS256) using the key at `AUTH_PRIVATE_KEY`
- MUST: Include `sub` (user ID), `iat`, `exp`, `roles` in every token payload
- MUST NOT: Log plaintext passwords or tokens at any log level
- MUST NOT: Return different error messages for "user not found" vs "wrong password" (timing-safe)
- MUST NOT: Store session state server-side — tokens are self-contained

## Success Criteria
- Given valid credentials, when `login()` is called, then returns a signed JWT within 200ms
- Given an expired token, when `validateSession()` is called, then returns `{ valid: false, reason: "expired" }`
- Given a valid refresh token, when `refresh()` is called, then issues a new access token and rotates the refresh token in a single atomic operation

## Out of Scope
- OAuth / SSO flows (handled by `auth-providers` module)
- Role-based access control enforcement (handled by `permissions` middleware)
- Multi-factor authentication
- Account registration / email verification

## Acceptance Tests
- [ ] All verification tests pass with current credentials fixture
- [ ] Build succeeds with zero TypeScript errors
- [ ] No plaintext secrets appear in test output or logs
- [ ] Token round-trip (issue → validate → decode) produces matching user ID

## Verification Tests

- [x] **VT-1: Login round-trip produces verifiable token**
  - Do: Call `login({ email: "fixture@test.com", password: "correct-password" })` → decode returned JWT
  - Assert: Decoded payload contains `sub === "user-fixture-001"` AND `roles` includes `"user"` AND `exp - iat === 900`
  - Proves: credential lookup, bcrypt comparison, JWT signing, payload structure all work end-to-end

- [ ] **VT-2: Expired token is rejected with correct reason**
  - Do: Forge a JWT with `exp` set to `Date.now() - 1000`, call `validateSession(token)`
  - Assert: Returns `{ valid: false, reason: "expired" }` — NOT a thrown exception, NOT `{ valid: false }` without reason
  - Proves: expiry check, structured error response, no crash on invalid token
