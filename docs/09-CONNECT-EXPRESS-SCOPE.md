# Stripe Connect Express — Scope & Plan

Status: **Built and confirmed working end-to-end on staging, 2026-09-10** — build order steps 1-3 below are done; step 4 (port to production) is still open. Scoped 2026-09-10, prompted by the new marketing site needing honest copy about how a new performer actually gets paid — today's answer is "they reach out and Travis sets it up by hand," and this doc is the plan for replacing that with real self-serve onboarding. See `04-DECISIONS-AND-OPEN-QUESTIONS.md` item 23/36 for the monetization numbers this scope builds toward (10% platform fee taken off the top, perpetual affiliate commission by default — both "working numbers, not a permanent commitment," Travis's own words) and the full build/test narrative.

## Why this exists

Travis wants a 10% cut of tips once other performers are really using the app, plus an affiliate program (already partly built — see `05-SIGNUP-SCOPE.md`) and a way to waive the cut entirely for specific accounts (his own band, beta testers, influencers). None of that is possible today because **there is exactly one Stripe integration in this whole app: Travis's own account**, wired in directly via env vars on the Vercel project. A new signup has no way to receive their own tips — not a limited version of self-serve, an absent one. This doc scopes the fix: **Stripe Connect Express**, the same model already chosen back on 2026-08-27 over a pooled/custodial alternative (real money-transmitter-license and 1099-reporting risk with pooling — see that session's entry in `04-DECISIONS-AND-OPEN-QUESTIONS.md`).

## Current state (verified against the real code, not assumed)

- `api/create-payment-intent.js` creates a plain `paymentIntents.create()` call — no `transfer_data`, no `application_fee_amount`. It looks up `gig_sessions` by id to re-verify the gig is active and re-check the cap/cooldown, but never joins to `performers` at all — it has no notion of *which performer* is receiving the money.
- `api/stripe-webhook.js` writes the `requests` row on `payment_intent.succeeded`, keyed only by `gig_session_id`/`stripe_payment_intent_id`.
- `request.html` mounts Stripe Elements client-side using one hardcoded platform-wide `STRIPE_PUBLISHABLE_KEY` — there's no per-performer key or account reference anywhere in the client either.
- Nothing in the schema (`performers`, `promo_codes`, or any migration file present in the repo) has a Stripe account reference, an onboarding-status field, or a fee-percentage field. Confirmed by grep, not memory — `stripe_account`, `connect`, `onboarding`, `charges_enabled`, `payouts_enabled` appear nowhere in the codebase.

## Data model changes — additive only

- `performers.stripe_account_id` (nullable text) — the Connect account id once onboarding completes.
- `performers.stripe_onboarding_status` (text: `not_started` / `pending` / `complete` / `restricted`) — drives what the console shows and whether tipping is allowed.
- `performers.fee_percentage` (numeric, default 10) — **a new, dedicated column**, not a repurposing of the existing `discount_percent`/`discount_months` (those were built for a future subscription discount — see `05-SIGNUP-SCOPE.md` — and reusing a column for a meaning it wasn't named for is exactly the kind of thing that causes a confusing bug later). A 0 here is a full fee waiver — covers Travis's own band's account, a beta tester, an influencer, all through the same mechanism a promo code could set at signup.
- `promo_codes` needs no changes — `affiliate_commission_percent`/`affiliate_commission_months` already exist from the original signup-scope work and already default to the perpetual convention Travis just confirmed he wants (`*_months: null`).

## New API endpoints

- **`api/create-connect-account-link.js`** — authenticated (not anonymous like the tip endpoints — this one has to know which performer is calling). Creates a Stripe Express connected account for the calling performer if they don't have one yet (`stripe.accounts.create({ type: 'express', ... })`), stores the returned account id on `performers.stripe_account_id`, then creates and returns an `accountLinks.create()` onboarding URL for the client to redirect to.
- **`api/check-connect-status.js`** — called when the performer lands back on a `return_url` after Stripe's hosted onboarding, to re-check `charges_enabled`/`payouts_enabled` on their account and update `performers.stripe_onboarding_status` accordingly. Also needs to handle Stripe's onboarding-link expiry — if someone abandons the flow and comes back later to a dead link, this same button has to generate a fresh one rather than erroring.

## Console UI changes

A new "Payouts" section in the Settings tab (the same tab this session's UI cleanup just built): shows current status (not connected / pending / connected), a "Connect with Stripe" button wired to `create-connect-account-link.js`, and a plain-language explanation of what happens next. No new tab needed — Settings already exists and already holds account-level, rarely-touched configuration, which is exactly what this is.

## Payment flow — the one real logic change, and it's small

`create-payment-intent.js` needs one more join before creating the charge: `gig_sessions.performer_id` → `performers.stripe_account_id`/`fee_percentage`. Then the `paymentIntents.create()` call gets two new fields:

```js
transfer_data: { destination: performer.stripe_account_id },
application_fee_amount: Math.round(tipAmount * 100 * (performer.fee_percentage / 100)),
```

`application_fee_amount` is computed on the gross tip — Stripe's own ~2.9%+30¢ processing fee comes out of the performer's 90%, not the platform's 10% (the explicit choice Travis made when locking in the numbers). If `stripe_account_id` is null (performer hasn't onboarded yet), the safe default is a hard block — "This performer hasn't set up payouts yet" — rather than falling back to an unsplit charge into the platform account, which would recreate the exact pooled-money problem Connect exists to avoid.

Client-side (`request.html`), this needs **no changes** — destination charges don't require the connected account's own publishable key on the client, only the server-side fields above. Worth calling out since it's the one part of this whole scope that's genuinely low-risk.

## Webhook changes

Minimal. `payment_intent.succeeded` fires the same way for a destination charge. The one addition worth making: record `application_fee_amount` on the `requests` row (or a separate ledger table) so platform revenue can be totaled directly instead of recomputed from percentages after the fact — useful the moment there's more than one performer taking real tips.

## Travis's own account

Stays on the current direct integration, permanently, as the house account at 0% — does **not** go through Connect onboarding himself. Less to migrate, and "the house account is exempt from onboarding" is a normal, explicit rule rather than a workaround. His `performers` row simply never gets a `stripe_account_id`; `create-payment-intent.js`'s join needs to treat his existing direct-charge path as a first-class case, not a bug.

## Explicitly out of scope for v1

- **Automated affiliate payouts** — already decided as a manual ledger (`05-SIGNUP-SCOPE.md`), not being revisited here.
- **Graceful handling of a restricted/disabled Connect account** — Stripe can flag an account for more info or shut it down; worth a "your account needs attention" banner eventually, not a blocker for shipping v1.
- **Refunds through Connect** — different mechanics than a direct charge (reversing a transfer, not just the charge); punt until someone actually asks for one.

## Build order

1. Schema (three new `performers` columns) + `create-connect-account-link.js`/`check-connect-status.js` + the Settings-tab "Payouts" UI. Fully testable in isolation — no money moves yet.
2. `create-payment-intent.js`'s fee-split logic — the one change that touches real charges.
3. End-to-end test on staging with a real Stripe **test-mode** Express account (Stripe's test mode supports full Connect onboarding with fake identity/bank info, no real accounts needed).
4. Port to production the same wholesale-copy way everything else has, with extra scrutiny before flipping it live — first time real money splits between two parties instead of landing in one account outright.

## Open decisions before writing any code

- ~~What exactly does a crowd member see if they try to tip a performer who hasn't connected Stripe yet — a hard block with a message, or something softer?~~ **Resolved, built**: a hard block ("This performer hasn't set up payouts yet — tips can't be sent right now"), per this doc's own recommendation above — no unsplit fallback charge into the platform account.
- Does a brand-new signup get nudged toward connecting Stripe right at signup, or only when they're about to run a real gig? Affects whether the "Payouts" prompt is front-and-center on first login or something they find in Settings when they need it. **Still open** — not blocking, since Settings already surfaces it for the one real performer (Travis's own `travis-ross-test`) using this today.

## Built and tested on staging — 2026-09-10

Built exactly as scoped above, with one addition beyond this doc's original spec:

- **`is_house_account` (boolean, default `false`) added to `performers`**, rather than inferring "exempt from Connect" from a null `stripe_account_id` — needed once it came time to actually write `create-payment-intent.js`'s branch, since a real performer who hasn't onboarded yet also has a null `stripe_account_id` and has to be blocked, not treated as exempt. Set `true` for the `travis-ross` handle only. `get_performer_payout_info()` returns it alongside `stripe_account_id`/`fee_percentage`.
- **`requests.platform_fee_amount` (numeric, nullable) added**, recording the actual `application_fee_amount` Stripe charged per request (in dollars, matching `tip_amount`'s convention) — the "useful the moment there's more than one performer taking real tips" addition this doc's Webhook section already called for, done now rather than deferred.
- Migrations: `migration-stripe-connect-v1.sql` (schema + the three RPC functions) and `migration-stripe-connect-v2.sql` (`is_house_account` + the `get_performer_payout_info()` reshape + `platform_fee_amount`). Both run on staging, no errors.

**Onboarding tested hands-on**, real Stripe-hosted Express flow, `travis-ross-test`'s own account: Connect had to be enabled on the correct Stripe sandbox account first (Stripe's newer "sandboxes" are separate from classic Test mode, each with their own API keys — confirmed the sandbox already wired into staging's `STRIPE_SECRET_KEY` was the right one before touching anything), business model classified as "Marketplace," and "Accounts v1 support" enabled via Stripe's own dashboard toggle (freshly-Connect-enabled accounts default to blocking the older `stripe.accounts.create()` v1 call this app uses). Test identity data (test SSN, test bank account) taken through Stripe's hosted onboarding UI; the account briefly showed "restricted" after submission because the **full** SSN/ITIN field (not just the last-4 shown earlier in the flow) still needed re-entry to clear identity verification — resolved, account reached "Verified"/"Connected" status.

**Fee-split payment flow tested hands-on**, two real test-mode tips against the now-connected `travis-ross-test` account ($10 and $5, test card `4242 4242 4242 4242`) through the actual crowd page: both created a destination-charge PaymentIntent (`transfer_data.destination` + `application_fee_amount`, not the house-account direct-charge path, since `travis-ross-test` is a real performer, not the house account), both confirmed successfully client-side, and both were correctly recorded by the existing webhook (visible as pending requests in the console's Request Activity list with the right dollar amounts). Confirms the whole pipeline — onboarding → connected account → split charge → webhook record — works end to end on staging.

**Apparent Reporting-total discrepancy, investigated and resolved as a false alarm**: right after the two test tips, "Total tips" looked like it had only counted one of them. Direct queries against the underlying `requests` rows (via the authenticated session's own REST access, same read the Reporting tab itself uses) confirmed both rows were correct all along (`$10`/`$1.00` fee and `$5`/`$0.50` fee, summing exactly to the displayed $26/$1.50) — the mismatch was a wrong assumption about what the pre-test baseline actually was, not a real bug. **Reporting now shows the fee breakdown directly** — see `04-DECISIONS-AND-OPEN-QUESTIONS.md` item 36's follow-up entry and `01-ARCHITECTURE-AND-DATA-MODEL.md`'s Reporting section.

## Related docs
- `04-DECISIONS-AND-OPEN-QUESTIONS.md` items 23/36 — the monetization numbers, affiliate-mechanism decisions, and full build/test session entry.
- `05-SIGNUP-SCOPE.md` — the existing `promo_codes`/affiliate-attribution mechanism this reuses without modification.
