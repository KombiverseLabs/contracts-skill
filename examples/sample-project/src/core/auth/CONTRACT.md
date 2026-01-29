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
Users can register, log in, maintain sessions across page reloads, and log out securely.
