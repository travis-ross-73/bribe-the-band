# Staging / Testing Environment — Setup Progress

**This file documents how staging was built and its Stripe integration — it is not the current status doc for the project overall.** Staging remains the standing place to build/verify anything new before it reaches production; for what's actually live right now, see `HANDOFF-SUMMARY.md` and `01-ARCHITECTURE-AND-DATA-MODEL.md`'s dedicated feature sections (queue boosting, cooldown, and the performer display-name override were all built here 2026-08-27 and have since shipped to production too).

Status: **Core environment built and live (2026-08-25), real Stripe payment integration built and verified end-to-end (2026-08-26).** This is the direct implementation of the payments-integration-testing requirement from Wade's security review (see the "Security posture & Wade's review" section in `01-ARCHITECTURE-AND-DATA-MODEL.md`): a real, isolated environment for Wade to test payment flows against, separate from production. Travis chose this ("option 2") over a production payment-bypass mode.

Both build sessions were done via **Claude Code**, which has direct push access to `travis-ross-73/bribe-the-band` (confirmed working — see `HANDOFF-SUMMARY.md`) and direct API access to Vercel, Supabase, Wasabi, and Stripe (via tokens/keys Travis provided in-session). All work described below is on the `staging` git branch and the `bribe-the-band-staging` Vercel project only — `main`/production was never touched.

## What staging is

A second, fully isolated copy of the whole stack — its own Supabase project, its own Wasabi bucket, and its own Vercel deployment — so Wade can exercise real Stripe test-mode payment flows and multi-account interactions without touching production data or production money. **This is now fully live and testable**, including a real (test-mode) Stripe payment flow.

## Decisions made

- **Hosting**: a second Vercel project on the free `*.vercel.app` domain. Confirmed safe: same Supabase-Auth login wall as production, no indexing/discoverability risk beyond an unguessable-ish random URL, doesn't expire on Vercel's free tier, and can be upgraded to a real subdomain (e.g. `staging.bribetheband.live`) later without a rebuild.
- **Database**: a brand-new Supabase project, not a shared schema/prefix inside the production project. Full isolation.
- **File storage**: a brand-new, dedicated Wasabi bucket (`songchart-staging`), not a shared prefix inside the production `songchart` bucket. Its own least-privilege sub-user credentials, scoped only to this bucket — same pattern as production.
- **Seed data**: ALL 5 existing performer accounts get copied into staging with their full song catalogs — Travis Ross (real account), `travis-ross-test`, Ten Cent Prophet, and Wade's 2 own testing accounts — specifically so Wade can test how multiple accounts behave with/against each other (shared gig sessions, etc).
- **Wasabi chart-URL history**: confirmed via code search that there is no live "try new path, fall back to old path" logic anywhere in `console.html`/`viewer.html` — the historical handle-vs-performer-ID folder inconsistency was already resolved once, in production, by a one-time migration script that rewrote every `chart_url` to the current consistent format. As long as staging seeding reuses the *same* `performer.id` / `song.id` values from production, the Wasabi file paths carry over byte-for-byte with no dual-path logic needed.

## Environments

| | Production | Staging |
|---|---|---|
| Supabase URL | `ykvpjeiakvgihpxektcf.supabase.co` | `orwxehvthwflgoqnbafp.supabase.co` |
| Wasabi bucket | `songchart` | `songchart-staging` |
| Wasabi region | us-east-1 | us-east-1 |
| Vercel project | `bribe-the-band` (prj_BOxqUDKiR3KLCbyGGzXqND15KAQ5), Production Branch `main` | `bribe-the-band-staging` (prj_FfQEVfx2JJzZLVIoM9oJwuTUZaMM), Production Branch `staging` — live at **`bribe-the-band-staging-three.vercel.app`** |
| Vercel team | `bribe-my-band` (team_oYzNtUcg1ZhGyU4bWuxNjLEa) — both projects live under this same team | |
| Stripe | not integrated | test-mode keys wired up (see "Real Stripe payment integration" below) |

Credentials for both environments live only as environment variables in their respective Vercel projects — never committed to git. See `api/wasabi-upload-url.js` / `api/wasabi-delete-chart.js` header comments for the existing pattern this follows. As of this build, `SUPABASE_URL`/`SUPABASE_ANON_KEY` are also read from env vars in those two functions (with the original production values as the fallback default) rather than hardcoded — see step 6 below for why.

**Finding the "Production Branch" setting in the current Vercel UI**: this moved out of the old Project Settings → Git tab entirely. It now lives at **Project Settings → Environments → click the "Production" row → "Branch Tracking" section** (a plain text field, not a dropdown). There is no Vercel API field to change this at all (confirmed against their full OpenAPI spec) — it's dashboard-only, so this has to be set by hand in the UI, by whoever has Vercel dashboard access.

### Staging login credentials

Five staging-only Supabase Auth accounts exist, one per performer, each linked to the exact same `performers.id` values as production (so staging data lines up 1:1 with what's described elsewhere in these docs). The emails are placeholders — not real, not deliverable — since this identity system is fully separate from production and doesn't need to match real addresses:

| Account | Staging login email | Password |
|---|---|---|
| Travis Ross | `travis-ross@staging.bribetheband.test` | `9kXcOg1wMk8zlB7B` |
| Travis Ross (Test) | `travis-ross-test@staging.bribetheband.test` | `m8zOtm3lMqMm3JNf` |
| Ten Cent Prophet | `tencentprophet@staging.bribetheband.test` | `aoEXhATvK2eNZPTY` |
| The Rescue (Wade) | `the-rescue@staging.bribetheband.test` | `PdUfOWj5P3KPni0Z` |
| Kaple (Wade) | `kaple@staging.bribetheband.test` | `pTumey3oCBXZvulQ` |

If you'd rather log in with real/memorable emails instead of the `@staging.bribetheband.test` placeholders, these can be changed — you'd get new passwords again since nobody can know or copy the original production ones.

## Steps completed

1. Reconstructed the full production schema from scratch for the first time — production's tables/policies/functions/triggers were built up ad hoc through the Supabase dashboard over the life of the project and had never existed as one tracked file. Synthesized from ~10 incremental migration files into `staging-schema-baseline-v1.sql`.
2. While reconstructing it, found and fixed a real live production bug: `migration-security-hardening-v1.sql` had over-broadened one INSERT policy on `requests` to cover both `anon` and `authenticated`, which silently broke the Master-only "manually add a song" tool in `viewer.html` (it inserts with `status='accepted'`, which the strict policy rejects). Fixed via `migration-fix-requests-insert-v1.sql` — delivered separately and urgently, since it's a production fix, not staging-only.
3. Travis created the new staging Supabase project (`orwxehvthwflgoqnbafp.supabase.co`).
4. First run of `staging-schema-baseline-v1.sql` failed with `ERROR: 42P07: relation "performers" already exists` (not safely re-runnable from a partial state). Fixed: every `create table` now uses `if not exists`, and every `create policy` is preceded by a matching `drop policy if exists` (Postgres has no `create policy if not exists`). Re-verified and re-delivered.
5. Travis created the staging Wasabi bucket (`songchart-staging`, us-east-1) with its own sub-user access key. Bucket public-read policy JSON delivered (`wasabi-staging-bucket-policy.json`) — same `PublicReadCharts` shape as production's bucket policy.

6. Applied the bucket policy JSON to `songchart-staging` in the Wasabi console; verified read/write access with the sub-user credentials (initial credentials from step 5 turned out not to have working permissions — Travis fixed the permissions in the Wasabi console mid-session, confirmed working after).
7. Created the `bribe-the-band-staging` Vercel project (via the Vercel API, using a token Travis provided), linked to the same GitHub repo, on the `staging` branch. Set its Wasabi env vars (`WASABI_ACCESS_KEY_ID`, `WASABI_SECRET_ACCESS_KEY`, `WASABI_BUCKET=songchart-staging`, `WASABI_REGION=us-east-1`).
8. Fixed the Production Branch setting (see note above) — Travis made the change himself in the dashboard; verified working via a live test push, which correctly auto-deployed with `target: production` and updated the stable `bribe-the-band-staging-three.vercel.app` alias with no manual intervention.
9. Created the 5 staging Auth users and linked `performers` rows (reusing the exact production `id` values) via the Supabase Admin API, using a staging-project service_role key Travis provided. See "Staging login credentials" above.
10. Seeded all 171 `songs` rows from production into staging (via the production project's public anon key, read-only), rewriting each `chart_url` to point at the staging bucket. 120 unique chart files, not 171 — `travis-ross-test`'s 51 songs intentionally reuse `travis-ross`'s own chart files rather than duplicating storage, confirmed as the existing production pattern by cross-checking both performers' `chart_url` values, not a copy error.
11. Copied all 120 unique chart PDFs from production's `songchart` bucket into `songchart-staging` at identical relative paths, using the Wasabi sub-user credentials directly (boto3/S3 API) — reading from production's public-read bucket, writing to staging.
12. **Found and left alone (Travis's call)**: two orphaned chart PDFs exist in production's `songchart` bucket (`charts/6601ef4b-c3d0-4fb8-bdc9-0e27ab7b6404/the-rescue-song-a.pdf` and `-good-plans.pdf`) with no matching `songs` row — confirmed real files (HTTP 200) with zero matching database rows. Likely cause: `wasabi-delete-chart.js`'s "best-effort" delete design means a song's catalog row can be removed even if the matching Wasabi file-delete call fails. Doesn't affect the app (nothing reads the bucket directly) or staging's correctness. Revisit only if Travis asks.
13. Built and verified a real Stripe test-mode payment integration on staging — see the dedicated section below.

## Steps remaining

- **Apple Pay domain registration** (optional): the Payment Element won't show an Apple Pay button until the staging domain is registered with Apple Pay in the Stripe Dashboard — a one-time step, since (unlike Stripe's hosted Checkout) a self-hosted Payment Element needs this. Card entry and Google Pay already work without it. Deliberately not attempted blind — worth doing whenever Travis specifically wants to test Apple Pay.
- Point Wade at the staging URL (`bribe-the-band-staging-three.vercel.app`) with the login credentials above, once Travis is ready for him to start testing.
- Real Stripe integration for **production** is still a separate, not-yet-started piece of work — everything below is staging-only.

## Real Stripe payment integration (staging only) — built and verified 2026-08-26

Travis provided real Stripe test-mode keys (`pk_test_.../sk_test_...`) mid-session specifically to unblock this. When asked to choose between Stripe's hosted Checkout page (simpler, but redirects the customer away) or an inline Payment Element (stays on the same page), **Travis chose Payment Element** — the lower-friction choice for a live-show audience tipping from their phone.

**Architecture**: nothing is ever written to the `requests` table at PaymentIntent-creation time — only a webhook, firing on `payment_intent.succeeded`, writes the row. An abandoned or failed payment simply never produces a row; no cleanup logic needed. The existing $0 "no tip" path is completely unchanged.

- **`api/create-payment-intent.js`** (new): re-verifies the gig session is real/active and re-runs the same `get_song_request_status` cap-check RPC server-side, right before creating a charge — closing a gap where a stale client-side-only check could let someone pay for a request that's about to be rejected as over-cap. Enforces Stripe's real $0.50 minimum (the old client-side check only required `>0`). Uses explicit `payment_method_types: ['card']` rather than Stripe's "automatic" methods, so every payment confirms synchronously (Apple Pay/Google Pay still show up automatically in the Payment Element regardless — they ride card rails).
- **`api/stripe-webhook.js`** (new): verifies the Stripe signature, then inserts the request using the plain anon key — the same privilege level the crowd's own browser already has, deliberately not the more powerful service_role key. **Idempotent**: a new `requests.stripe_payment_intent_id text unique` column (added via `migration-stripe-v1.sql`, run by Travis in the staging SQL editor) means a Stripe webhook retry (their delivery is at-least-once) is detected via a Postgres unique-violation and acknowledged without creating a duplicate row — confirmed working via an explicit replay test.
- **`request.html`**: now loads Stripe.js and the publishable key, mounts a Payment Element inline as soon as a paid tip amount is selected, and confirms via `stripe.confirmPayment({redirect:'if_required'})` — the customer never leaves the page for a normal card payment (only a rare forced 3D-Secure challenge would redirect, handled as a fallback).
- **Real bug found and fixed along the way**: `wasabi-upload-url.js` and `wasabi-delete-chart.js` were hardcoding the **production** Supabase URL/key even on the `staging` branch (unlike the four HTML files, which were correctly swapped) — meaning any chart upload/delete from the staging console was silently hitting production's `performers`/`songs` tables. Fixed by reading `SUPABASE_URL`/`SUPABASE_ANON_KEY` from env vars (now set on the staging Vercel project) with the original production values kept as the fallback default, so production's own behavior is completely unchanged. Also **deleted `api/migrate-legacy-charts.js` entirely** — it had the exact same bug, its console button had already been removed (fully dead code), and it was the one function with Wasabi *delete* permissions, so it was a live, armed, cross-environment delete endpoint sitting on staging for no remaining purpose.
- **End-to-end verified working**: a real Stripe test-card payment (`4242 4242 4242 4242`), both through the actual rendered Payment Element in a live browser and via a direct Stripe API confirmation against the final deployed code, correctly produced a `requests` row with the right tip amount, note, and `stripe_payment_intent_id`. Idempotency confirmed by replaying the same webhook event and verifying no duplicate row appeared.
- **Verification gotcha worth remembering for next time**: the `requests` table is deliberately unreadable by the anon key (by design — the crowd should never read back tip amounts or notes; the app itself only ever reads `requests` through the `get_song_request_status` SECURITY DEFINER RPC, never a direct select — this is already commented in `request.html`'s own source). Checking "did the payment actually get recorded" by querying `requests` with the anon key always comes back empty, success or not — always use the project's **service_role key** to verify `requests` table state directly.
- **Vercel env vars added** to the staging project as part of this: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, plus `SUPABASE_URL`/`SUPABASE_ANON_KEY` (see the Wasabi-functions bug fix above). The Stripe webhook endpoint itself was created via the Stripe API directly (not the dashboard), pointed at `https://bribe-the-band-staging-three.vercel.app/api/stripe-webhook`, subscribed to `payment_intent.succeeded`.
