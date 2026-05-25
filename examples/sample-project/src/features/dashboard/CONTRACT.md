# Dashboard

## Purpose
Main user interface displayed after successful login. Shows personalized content and navigation.

## Core Features
- [ ] [F-001] User profile summary widget -> Test: TODO -> Verifies: [REQ-001]
- [ ] [F-002] Recent activity feed -> Test: TODO -> Verifies: [REQ-002]
- [ ] [F-003] Quick action buttons -> Test: TODO -> Verifies: [REQ-003]
- [ ] [F-004] Notification center -> Test: TODO -> Verifies: [REQ-004]

## Constraints
- MUST [REQ-001]: Load within 2 seconds on 3G connection
- MUST [REQ-002]: Be fully responsive (mobile, tablet, desktop)
- MUST [REQ-003]: Gracefully handle missing data
- MUST NOT [REQ-004]: Make more than 3 API calls on initial load

## Success Criteria
- [AC-001] Given authenticated user, when dashboard loads, then displays personalized content within 2 seconds -> Verifies: [REQ-001]
- [AC-002] Given 3G connection, when dashboard loads, then all widgets render within 2 seconds -> Verifies: [REQ-001, REQ-002]

## Acceptance Tests
- [ ] [AT-001] All verification tests pass -> Verifies: [REQ-001, REQ-003]
- [ ] [AT-002] Build succeeds

## Verification Tests
- [ ] **VT-001: Dashboard shows correct user identity after login**
  - Do: Login "test@example.com" → navigate /dashboard → read profile widget
  - Assert: Profile widget displays "test@example.com" AND user's actual name
  - Verifies: [REQ-001]

- [ ] **VT-002: Dashboard handles missing data gracefully**
  - Do: Login with fresh account (no history) → navigate /dashboard
  - Assert: Activity feed shows "No recent activity" (not error/spinner/blank)
  - Verifies: [REQ-003]
