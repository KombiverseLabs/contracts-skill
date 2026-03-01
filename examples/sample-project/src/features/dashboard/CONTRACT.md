# Dashboard

## Purpose
Main user interface displayed after successful login. Shows personalized content and navigation.

## Core Features
- [ ] User profile summary widget
- [ ] Recent activity feed
- [ ] Quick action buttons
- [ ] Notification center

## Constraints
- MUST: Load within 2 seconds on 3G connection
- MUST: Be fully responsive (mobile, tablet, desktop)
- MUST: Gracefully handle missing data
- MUST NOT: Make more than 3 API calls on initial load

## Success Criteria
- Given authenticated user, when dashboard loads, then displays personalized content within 2 seconds
- Given 3G connection, when dashboard loads, then all widgets render within 2 seconds

## Verification Tests
- [ ] **VT-1: Dashboard shows correct user identity after login**
  - Do: Login "test@example.com" → navigate /dashboard → read profile widget
  - Assert: Profile widget displays "test@example.com" AND user's actual name

- [ ] **VT-2: Dashboard handles missing data gracefully**
  - Do: Login with fresh account (no history) → navigate /dashboard
  - Assert: Activity feed shows "No recent activity" (not error/spinner/blank)
