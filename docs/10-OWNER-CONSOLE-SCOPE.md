# Owner Console — Scope & Plan

Status: **Not built. Scoped 2026-09-11**, prompted by Travis wanting a real tool for the things he's currently doing by hand in the Supabase SQL Editor and Table Editor (creating promo codes, editing a performer's plan/discount/referral fields, computing what's owed to an affiliate) — plus reporting that's been on the wishlist since item 25 in `04-DECISIONS-AND-OPEN-QUESTIONS.md` ("Owner reporting — internal/admin-only analytics view," 2026-08-29, never built). This also folds in most of what `06-OWNERS-GUIDE-NOTES.md` was going to have to explain manually — a real console replaces the need to document "how to hand-edit this in Supabase," in Travis's own words.

## Why this exists

Three things converged:
1. **Real money now flows through per-performer fee percentages** (Stripe Connect Express, `04-DECISIONS-AND-OPEN-QUESTIONS.md` items 36-39) — Travis needs to be able to waive or adjust a performer's cut without hand-editing rows in Supabase's Table Editor every time.
2. **The affiliate mechanism has existed since Phase 1 signup** (`05-SIGNUP-SCOPE.md`) but was always explicitly scoped as "Travis creates `promo_codes` rows via the SQL editor" — fine for a handful of codes, not a real tool.
3. **The affiliate commission report was explicitly deferred** ("needs real billing data to compute against," `04-DECISIONS-AND-OPEN-QUESTIONS.md`/`05-SIGNUP-SCOPE.md`) back when the only imagined revenue was subscription billing, which never got built — monetization pivoted to the Stripe Connect 10% tip cut instead (item 23). **That real billing data exists now** (`requests.platform_fee_amount`), so the report that was blocked on "real billing data" can actually be built.

## Current state (verified against the real code, not assumed)

- **No admin UI exists anywhere in this app.** Every owner-side action today is a direct Supabase Table Editor edit or a hand-written SQL statement — creating a `promo_codes` row, changing a performer's `fee_percentage`, everything.
- **`performers` has zero `authenticated`-role grants for `UPDATE` or `INSERT`** — confirmed by direct test 2026-09-11 (three attack attempts: PATCH by handle, PATCH by id, raw INSERT — all rejected with `42501 permission denied`, not merely blocked by a row policy). This is good news for security, but it also means **there is no client-side code path, even a privileged one, that this app's normal anon-key architecture could use to build owner tooling** — the owner console needs a fundamentally different credential than every other page in this app.
- **`promo_codes` has RLS enabled with no anon/authenticated read policies at all** — not even Travis's own performer login can query it today. Same problem: needs a different credential.
- **`performers.referral_code`** is set exactly once, by `handle_new_performer_signup()`, at signup time, from whatever code was passed in. There is no existing path to set or change it after a performer's row already exists.
- **`performers.fee_percentage`** defaults to `10` for every new signup (confirmed live 2026-09-11 on the `demo` account) and is never written to by any existing code path — Connect onboarding only ever reads it. Changing it today means a direct Table Editor edit.
- **The Reporting tab (`console.html`) is scoped to one performer's own data** — by design (RLS), it has no way to become a cross-performer view no matter how it's extended; a real owner view needs a different access path entirely, not a bigger version of that tab.

## Architecture: local-only, a separate credential, a separate codebase

This tool needs the **Supabase `service_role` key** (bypasses RLS/grants entirely) and the **Stripe secret key** (already exists in Vercel's env vars, but this tool needs its own local copy) for both environments. That's a fundamentally different trust level than the anon key every other page in this app uses — anon-key exposure is a scoped, already-defended-against risk (see the security test above); **service_role exposure is total compromise of every row in the database**, for anyone who ever views the page source or opens dev tools.

That means, non-negotiably:
- **Not deployed anywhere public.** Not a hidden route on the existing Vercel project, not a password-gated page on the same domain — a page like that would ship the service_role key to the browser the instant Travis loaded it himself, and from then on it's sitting in that page's JS for anyone who ever gets a look at it.
- **A genuinely local tool**: a small Node server (holding both secret keys server-side, never sent to the browser) plus a plain HTML/JS frontend that only ever talks to `localhost`, run via `npm run dev`/similar, only on Travis's own machine. Matches his own instinct exactly.
- **A separate codebase from `bribe-the-band`**, not a folder inside it. Even sitting unused in the same repo, a service_role key is one accidental `git push` or Vercel misconfiguration away from disaster — a completely separate local folder (its own git history, likely its own **private** GitHub repo for backup, never the public `bribe-the-band` remote) removes that risk structurally rather than relying on `.gitignore` discipline alone.
- **Secrets in a local `.env`, gitignored**, same pattern as everything else in this project (memory system for account passwords, env vars for API keys, nothing sensitive ever in a commit). The `.env` itself is Travis's own responsibility to keep backed up (however he already backs up his machine) — the *code* gets its durability from git, same as always.

## What it needs to do

### Performers / users
- List and search all performers (by handle, email, plan_status, Connect status) across **both environments** — a real "which environment am I looking at" switch, since staging and production are separate Supabase projects with separate service_role keys.
- Per-performer detail view: plan_status, fee_percentage, Stripe Connect status (pulled live from Stripe by `stripe_account_id`, not just the cached `stripe_onboarding_status` — a connected account can get flagged by Stripe *after* onboarding, which nothing in this app currently surfaces anywhere, per the Connect Express scope doc's own "out of scope for v1" list), referral_code/affiliate attribution, signup date, recent activity (gigs run, tips collected).
- Edit `fee_percentage` directly, in place of the current "hand-edit in Table Editor" workflow.
- A "needs attention" view: performers with `stripe_onboarding_status != 'complete'` (a follow-up-outreach list) and any connected account Stripe itself has flagged (`requirements.disabled_reason` set).

### Affiliates
- Its own tab: list existing `promo_codes` rows (today invisible to any UI at all), create new ones (all the existing fields — `grants_free_account`, `discount_percent`/`discount_months`, `affiliate_commission_percent`/`affiliate_commission_months`, `max_redemptions`, `active`), deactivate/edit existing ones.
- **Assign an affiliate code to an existing performer, individually or in bulk** — Travis's own scenario: an affiliate hands him a list of performers they referred but forgot to distribute the code to before signup. Search/select multiple performers (by handle or email), pick a promo code, apply it to all of them at once. This writes `performers.referral_code` directly (something no existing code path does today) and should increment `promo_codes.redemption_count` by the number assigned, so `max_redemptions` and future reporting stay meaningful regardless of whether attribution happened at signup or after the fact.
- Signup-time assignment already works today (`validate_promo_code()` + `handle_new_performer_signup()`) and needs no change — this is purely adding the missing *retroactive* path alongside it.

### Reports
- **Revenue report, any date range**: total tips, total platform fee collected, house-account vs. real-performer split — the cross-performer version of the existing per-performer Reporting tab, reading `requests.tip_amount`/`platform_fee_amount` joined through `gig_sessions`/`performers`.
- **Affiliate commission report, any date range**: per affiliate code, which performers carry that `referral_code`, what those performers' referred activity generated in that window, and the commission owed (percentage, perpetual-vs-timed per that code's own `affiliate_commission_months` convention). Exportable (CSV at minimum) so it can be handed to an affiliate directly or fed to the scheduled-email idea below.
- Both reports should be simple enough to run ad hoc *and* structured enough to be called the same way on a schedule (see below).

### Folding in the owner's-guide need
Several sections of `06-OWNERS-GUIDE-NOTES.md` are exactly the manual processes this console replaces (creating promo codes, editing a performer's plan fields) — once built, that doc shrinks to "how to use the owner console" plus whatever genuinely has no UI yet (e.g., Wasabi/chart administration), rather than raw-SQL instructions.

## The Cowork/scheduled-email idea — a real architecture wrinkle

Travis's idea: have Claude auto-run the affiliate report on a schedule and draft emails per affiliate, as a scheduled Cowork event. **This can't call into the local console tool directly** — Cowork runs in Anthropic's cloud; it has no network path to a server running on Travis's own laptop, on-demand-only. Two ways to actually bridge this, worth deciding once the console itself exists:
1. **A narrow, read-only path Cowork *can* reach**: a new `SECURITY DEFINER` RPC on Supabase itself (like every other cross-cutting read in this app), callable only by Travis's own authenticated performer login, returning exactly the affiliate-report shape and nothing else. Cowork already has Travis's own Supabase-adjacent context in this project; this keeps the automation fully server-side without ever touching a service_role key from the cloud.
2. **The local console exports to somewhere Cowork already reads** — Travis's Google Workspace/Sheets connector is already active in Cowork for other things (the song database sheet). The local tool could drop a report into a Sheet on a schedule (run manually or via a Mac scheduled task, not by Claude), and a separate Cowork-scheduled skill reads *that* Sheet and drafts the emails.

Option 1 is more work up front but keeps the automation genuinely hands-off; option 2 reuses infrastructure that already exists but needs a human (or `cron`) step to actually run the export. Not deciding this now — flagging it so "the console" and "the Cowork automation" aren't accidentally assumed to be the same connected system when they can't be.

## Explicitly out of scope for v1
- **Automated affiliate payouts** — still a manually-paid ledger per the original decision (`05-SIGNUP-SCOPE.md`); this console computes what's owed, it doesn't move money.
- **A performer-facing "your Connect account needs attention" banner** — the owner console surfaces this to Travis; building the performer-facing version is separate, already noted as deferred in the Connect Express scope doc.
- **Building the Cowork scheduling piece itself** — see above; this doc scopes the console, not the automation that might eventually read from it.
- **An audit log of admin actions** — worth having given this tool can move real numbers around, but additive and can land after the core console works; noted as a fast-follow, not a blocker.

## Open decisions before writing any code
- **What does an affiliate's commission actually apply to, now that real revenue means Stripe Connect tips, not subscriptions?** The `affiliate_commission_percent` field was designed years-of-conversation ago around "a share of subscription billing." The sensible mapping now: a percentage of the **platform's own cut** (`platform_fee_amount`) generated by their referred performers, not a percentage of the performers' gross tips (that's the performer's own money, not the platform's to share). Needs Travis's explicit confirmation before the report does real math.
- **Does retroactively assigning an affiliate to an existing performer apply going forward only, or backdate to their signup?** I.e., if a performer has been live for a month before the affiliate code gets attached, does that month's already-collected revenue count toward the affiliate's commission? Leaning toward **going-forward only** (avoids a surprise lump-sum obligation appearing the moment an assignment happens), but this is Travis's call, not a technical one.
- **Cowork automation bridge** — which of the two options above (or something else), once the console itself is working and this becomes concrete rather than hypothetical.

## Build order
1. Local project scaffolding: a new, separate local folder/repo, `.env` with both environments' service_role keys and Stripe secret keys, a minimal Node server that proxies to Supabase/Stripe server-side.
2. Performers list/search/detail + fee_percentage edit — the highest-value, lowest-complexity piece, and the one Travis is currently doing by hand most often.
3. Affiliates tab: `promo_codes` CRUD + the new retroactive-assignment flow (individual and bulk).
4. Revenue + affiliate commission reports, date-range based.
5. Stripe-pulled Connect status ("needs attention" view) — layered on top of the performers view once the basics work.

## What's needed to start
- **Service_role key for both Supabase projects** (staging `orwxehvthwflgoqnbafp`, production `ykvpjeiakvgihpxektcf`) — from each project's own API settings page, for the local `.env` only, never committed anywhere.
- **A decision on where the code lives** — recommend a fresh local folder, e.g. `bribe-the-band-owner-console/`, as its own private repo.
- **Confirmation on the two open decisions above** (affiliate commission basis, retroactive-attribution timing) before the reporting math gets built, so it isn't built twice.

## Related docs
- `04-DECISIONS-AND-OPEN-QUESTIONS.md` item 25 (original "Owner reporting" idea) and items 36-39 (Stripe Connect Express, the revenue this console reports on).
- `05-SIGNUP-SCOPE.md` — the existing `promo_codes`/`referral_code` mechanism this console builds a real UI on top of, unmodified.
- `06-OWNERS-GUIDE-NOTES.md` — the manual-process documentation this console is expected to shrink, not duplicate.
- `09-CONNECT-EXPRESS-SCOPE.md` — the Stripe Connect Express build whose per-performer `fee_percentage` this console needs to edit, and whose "restricted account" handling was explicitly deferred to a future owner-facing view (this one).
