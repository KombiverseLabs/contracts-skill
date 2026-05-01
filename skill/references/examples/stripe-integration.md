# Stripe Payments Integration

## Purpose
Handles all money movement between users and the platform — one-time charges, subscription lifecycle, refunds, and webhook processing — so that no other module needs to know how Stripe works internally. Acts as the single integration point; the rest of the application only calls this module's typed interface.

## Core Features
- [x] One-time charge (create PaymentIntent, confirm, return receipt) → Test: `tests/payments/charge.test.ts`
- [x] Subscription creation and plan assignment → Test: `tests/payments/subscription.test.ts`
- [x] Webhook signature verification and event dispatch → Test: `tests/payments/webhooks.test.ts`
- [ ] Refund issuance (full and partial) → Test: `tests/payments/refund.test.ts`
- [ ] Subscription upgrade / downgrade (proration) → Test: `tests/payments/plan-change.test.ts`
- [ ] Failed payment retry logic (Smart Retries via Stripe) → Test: `tests/payments/retry.test.ts`

## Constraints
- MUST: Verify Stripe webhook signatures using `stripe.webhooks.constructEvent()` before processing any webhook payload
- MUST: Use Stripe test mode (`sk_test_*`) in all non-production environments — enforced via `STRIPE_SECRET_KEY` prefix check at startup
- MUST: Persist all Stripe event IDs to the database before acting on them (idempotency guard)
- MUST: Return typed `PaymentResult` objects — never expose raw Stripe objects to callers
- MUST NOT: Store card numbers, CVVs, or full PANs — use Stripe-hosted payment elements only
- MUST NOT: Silently swallow webhook errors — failed events must be logged and re-queued for retry
- MUST NOT: Process `payment_intent.succeeded` more than once for the same `payment_intent_id`

## Success Criteria
- Given a valid test card (`4242 4242 4242 4242`), when `charge({ amount: 100, currency: "usd", customerId })` is called, then returns a `PaymentResult` with a non-empty `transactionId` matching `/^pi_[a-zA-Z0-9]+$/`
- Given a Stripe `customer.subscription.updated` webhook with a valid signature, when the webhook endpoint receives it, then the user's `plan` field in the database is updated within the same HTTP response cycle
- Given a webhook event ID that was already processed, when the same event arrives again, then the handler returns `{ status: "already_processed" }` and performs no further writes

## Out of Scope
- Invoicing and PDF generation (handled by `billing` module)
- Tax calculation (delegated to Stripe Tax)
- Currency conversion for display (handled by `i18n` module)
- Dispute / chargeback management (manual ops workflow)
- Free trial logic (handled by `subscription` domain module, which calls this one)

## Acceptance Tests
- [ ] All verification tests pass in Stripe test mode
- [ ] Build succeeds with zero TypeScript errors
- [ ] No live Stripe keys (`sk_live_*`) present in test environment variables
- [ ] Idempotency: running the full charge test suite twice produces no duplicate records in the test database
- [ ] Webhook replay: re-sending the 10 most recent test webhook events produces zero new database writes

## Verification Tests

- [x] **VT-1: Sandbox charge returns valid Stripe transaction ID**
  - Do: Call `charge({ amount: 100, currency: "usd", customerId: "cus_test_fixture" })` using Stripe test keys
  - Assert: Returned `PaymentResult.transactionId` matches regex `/^pi_[a-zA-Z0-9_]+$/` AND `PaymentResult.status === "succeeded"`
  - Proves: Stripe API connectivity, request construction, response parsing, and typed output mapping all work

- [x] **VT-2: Webhook updates subscription state correctly**
  - Do: POST a synthetically signed `customer.subscription.updated` event (tier: `"pro"`) to `/api/webhooks/stripe`
  - Assert: HTTP response is `200` AND `db.users.findById(fixture.userId).plan === "pro"`
  - Proves: signature verification, event routing, database write, and idempotency key storage

- [ ] **VT-3: Duplicate webhook event is rejected without side effects**
  - Do: Send the same webhook event ID twice (simulate Stripe retry)
  - Assert: Second response body contains `{ "status": "already_processed" }` AND database write count for that event remains exactly 1
  - Proves: idempotency guard, no double-charge, correct response to Stripe to stop retries
