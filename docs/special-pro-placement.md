# Special Pro Placement

Special Pro is a paid visibility product for contractors. It is an additive
catalogue placement, not a trust badge and not a substitute for verification,
ratings, reviews, or completed work.

## User experience

- Contractors see the product from the Pro screen and the contractor account
  card.
- The price is `199 EGP` for `7 days`.
- A contractor uploads transfer proof through the existing manual review flow.
- The client shows a pending state until an admin approves the request.
- Active placement is shown with its expiry date. A new purchase extends from
  the later of the current expiry or approval time.
- Homeowners see a separate shelf labelled `Paid placement` / `إعلان مدفوع`.
- Sponsored profiles are never merged into Top Rated, earned tiers, or factual
  ranking copy.

## Server contract

- `submit_payment_request` owns the purpose, term, amount, authentication, proof
  requirement, and idempotency check.
- `get_my_billing_state` exposes `sponsored_until` alongside the subscription
  state without treating it as a subscription.
- `list_sponsored_contractors` returns a public-safe projection and an explicit
  `is_sponsored: true` marker.
- `admin_review_payment` is the only activation path. Approval writes the
  existing `contractor_profiles.sponsored_until` field and the audit trail.

## Fairness and operations

Daily rotation prevents one active campaign from permanently occupying the same
first slot. Specialty and city filters are applied before rotation, so paid
placement remains relevant to the homeowner's intent.

The admin console already labels `sponsored` payment requests. Before a public
launch, operators should define a review SLA, refund policy, campaign pause
policy, and a report/appeal path for misleading profile content.

## Store compliance

The current implementation uses InstaPay manual review because that is the
existing payment abstraction. For native App Store or Google Play distribution,
the team must confirm the final payment path with the store rules: paid boosts
or placement that affect in-app visibility may require Apple In-App Purchase or
Google Play Billing. Do not ship the manual transfer path in a store build
without that review.

