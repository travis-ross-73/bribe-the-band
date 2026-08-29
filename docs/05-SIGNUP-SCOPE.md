# Self-Service Signup — Scope & Status

Status: **Phase 1 built** (free signup + unified promo-code mechanism). Not yet deployed — the three files below still need to be uploaded/run by Travis. Real billing, the affiliate payout ledger, and device-count enforcement remain later phases, not built.

Originally written 2026-08-19 as a narrower "free signup only" scope. Updated the same day after Travis expanded the ask: "I'd like to be able to integrate payments but also have the ability to give a free account, as well as have an affiliate program (can be basic...just a percentage either in perpetuity for all linked sign-ups or a predetermined timeframe for that payout.)" Phase 1 below is what actually got built in response to that; it does not include real payments yet, by Travis's own direction ("Don't worry about the waiting performer... Just let[']s start the flow").

## Context that shaped this scope
- No one is being manually onboarded to unblock right now — Travis explicitly waved off the "waiting performer" urgency ("Doubtful we'll be able to use it this time anyway"), so Phase 1 was built as the real thing from the start rather than a stopgap.
- Stripe subscription billing (for the app itself — separate from tip payments, which are still simulated too) is still not built. Free signup ships now; real billing is a later phase.
- Signup/pricing direction already agreed in `01-ARCHITECTURE-AND-DATA-MODEL.md`: no "Solo" vs "Band" account type — Master/Follower is a per-device, per-gig toggle, not an account setting. Pricing should scale with device count, not a plan label.
- Affiliate payouts: Travis's answer was "Start with simple ledger. Perhaps migrate to automated via Stripe" — so Phase 1 only captures the *data* an affiliate arrangement needs (who referred whom, what commission terms were promised); it does not compute or track dollars owed yet, since there's no real billing to compute a share of.
- Becoming an affiliate: Travis's answer was "I will manually set them up, but will need to be able to give them a link and/or code. Perhaps a discount code feature could be used in conjunction with an affiliate. Can also use the discount code to give a free account when I need to." — this is why Phase 1 uses ONE `promo_codes` mechanism for three purposes (discount, free-account grant, affiliate attribution) instead of three separate systems.

## What Phase 1 actually built

**`signup.html`** — a new static page (same dark visual style as console.html), with fields for display name, handle (live-validated: format, reserved words, and live availability check against `performers.handle`), email, password (min 8 characters), and an optional promo/referral code. The promo field auto-fills and auto-validates if the page is loaded with `?ref=CODE` or `?code=CODE` in the URL — so a shareable affiliate link and a manually-typed code behave identically. On submit, calls `supabase.auth.signUp()` with the handle/display name/promo code passed as user metadata (not as a direct table insert — see below for why). Handles both outcomes of Supabase's email-confirmation setting (immediate session → redirect to console; no session yet → "check your email" message), since which one happens depends on a Supabase project setting Travis hasn't decided yet (see Still Open).

**`migration-signup-v1.sql`** — the data model and server-side logic, to run once in the Supabase SQL editor:
- New `performers` columns: `plan_status` (default `'free_beta'`; a promo code with `grants_free_account` sets it to `'comp_free'` instead), `referral_code` (which promo code this performer signed up with, if any — the affiliate-attribution link), `discount_percent`/`discount_months` (a discount to apply whenever real billing exists; null months = perpetual, a number = only their first N billed months).
- New `promo_codes` table — the unified mechanism: `grants_free_account`, `discount_percent`/`discount_months` (what the *customer* gets), `affiliate_commission_percent`/`affiliate_commission_months` (what the code's *owner* earns — same perpetual-vs-timed convention, entirely independent of the customer's own discount), plus simple `max_redemptions`/`redemption_count`/`active` usage controls. RLS is enabled with no anon/authenticated read policies — affiliate commission terms are Travis's own business arrangement, not something a person redeeming a code should be able to query directly.
- `validate_promo_code()` — a SECURITY DEFINER function the signup page calls to live-check a code and show what it gives the person signing up, without ever exposing affiliate commission terms.
- `handle_new_performer_signup()` — a trigger on `auth.users` (not a client-side insert) that creates the `performers` row itself, reading handle/display name/promo code out of the signup's metadata. Built this way specifically because a brand-new signup may have no active session yet if Supabase's "confirm email" setting is on, so a client-side insert right after `signUp()` could hit an RLS wall depending on timing — the trigger sidesteps that entirely, the same reasoning as the existing `get_song_request_status` SECURITY DEFINER function.

**`vercel.json`** — added a `/signup` → `signup.html` rewrite, placed *before* the existing generic `/:handle` → `request.html` rule (first-match-wins), so `bribetheband.live/signup` resolves correctly instead of falling through to the handle-lookup rewrite. The reserved-handle list (enforced client-side in `signup.html`) now includes `signup` and `signup.html` alongside `console`, `viewer`, `request`, etc.

## Explicitly NOT built in Phase 1
- **No real payments.** Signup creates a free account, full stop, regardless of promo code. `plan_status` exists purely so today's free signups are distinguishable later once real billing exists.
- **No affiliate payout ledger.** The data to support one is captured (`referral_code` on `performers`, commission fields on `promo_codes`), but nothing computes "$ owed to affiliate X" — that depends on real Stripe charges existing to compute a share of, per Travis's own "simple ledger... migrate to automated via Stripe" answer.
- **No self-serve affiliate application flow.** Affiliates are Travis-managed only, per his own answer — he creates `promo_codes` rows directly via the Supabase SQL editor (examples are commented at the bottom of the migration file) and hands out the resulting code or a `signup.html?ref=CODE` link.
- **No device-count enforcement.** Nothing currently caps how many `viewer.html?role=follower` tabs can open — still an open design question for whenever pricing/billing is finalized.

## Pricing — a starting proposal to react to, not researched benchmarks
Unchanged from the original scoping conversation — still just an anchor to react to, not implemented anywhere in code:

- **Tier A — 1-2 devices**: covers a solo performer, or a duo. Suggested anchor: **$9/month or $79/year**.
- **Tier B — 3-6 devices**: covers a small-to-full band. Suggested anchor: **$19/month or $169/year**.
- **Tier C — 7+ devices**: larger ensembles — suggested as **contact/custom** rather than a fixed price.

## Still open, deliberately not decided here
- Whether Supabase's email-confirmation-required setting should be on or off — affects whether a brand-new performer can log into the console immediately after signing up, or has to click a confirmation link first. This is a real setting in Travis's own Supabase project dashboard, not something set in code.
- Actual `promo_codes` rows for real affiliates/comps — Travis creates these himself when ready; example `insert` statements are included as comments in `migration-signup-v1.sql`.
- Reaction to the pricing tiers above.
- The device-count enforcement mechanism.
- Real Stripe subscription billing, and the affiliate payout ledger that depends on it — both later phases.
