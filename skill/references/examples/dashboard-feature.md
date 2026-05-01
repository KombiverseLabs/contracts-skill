# Analytics Dashboard

## Purpose
Gives logged-in users a single-page overview of their account activity — recent events, key metrics, and quick-action shortcuts — so they can assess status without navigating to individual sub-pages.

## Core Features
- [x] Activity feed (last 20 events, reverse chronological) → Test: `tests/dashboard/activity-feed.test.tsx`
- [x] Metric cards (configurable, fetched from `/api/metrics`) → Test: `tests/dashboard/metric-cards.test.tsx`
- [ ] Quick-action panel (context-sensitive, based on user role) → Test: `tests/dashboard/quick-actions.test.tsx`
- [ ] Empty state (no activity in last 30 days) → Test: `tests/dashboard/empty-state.test.tsx`
- [ ] Error boundary with retry (API failure) → Test: `tests/dashboard/error-handling.test.tsx`

## Constraints
- MUST: Render the activity feed server-side (SSR) — not client-fetched on mount
- MUST: Display the authenticated user's display name in the page header
- MUST: Show a loading skeleton during metric card fetch (max 300ms before skeleton appears)
- MUST: Refresh metric cards every 60 seconds without full page reload
- MUST NOT: Show another user's data under any circumstance (verify `userId` server-side)
- MUST NOT: Render the dashboard before authentication is confirmed — redirect to `/login` if session is absent

## Success Criteria
- Given a logged-in user with at least one event, when navigating to `/dashboard`, then the activity feed shows the correct user display name in the header and at least one event within 1 second
- Given a user with no events in 30 days, when navigating to `/dashboard`, then the empty state component is rendered with the correct illustration and call-to-action text
- Given an API timeout on `/api/metrics`, when on the dashboard, then metric cards show an error state with a "Retry" button — page does not crash

## Out of Scope
- Detailed event pages (each event links out to its own route)
- Customizable dashboard layout / widget reordering
- Exporting activity data
- Notification bell / unread count (handled by `notifications` module)

## Acceptance Tests
- [ ] All verification tests pass
- [ ] Build succeeds with no TypeScript errors and no a11y violations (axe)
- [ ] Lighthouse performance score ≥ 85 on dashboard route
- [ ] No user data leaks between test accounts in E2E run

## Verification Tests

- [x] **VT-1: Dashboard renders correct user data after login**
  - Do: Log in as `fixture-user-alice` → navigate to `/dashboard` → inspect rendered HTML
  - Assert: Page `<h1>` or header element contains the text `"Alice"` AND activity feed contains at least one item with a timestamp from the fixtures
  - Proves: SSR session validation, user data fetch, component rendering, and routing all work together

- [ ] **VT-2: Metric cards auto-refresh without page reload**
  - Do: Load dashboard → wait for initial metric render → mock `/api/metrics` to return different values → wait 65 seconds
  - Assert: Metric card values update to match the new mock response — without any `window.location` change occurring
  - Proves: polling logic, response parsing, and component update path
