# Owner's Operations Guide — Notes & Outline (to write later)

Status: **not started — running list of what to include.** This is not the customer-facing FAQ/help doc; it's the "how Travis runs the business" manual: how to operate bribetheband.live day to day, administer accounts, run promotions, and handle the recurring maintenance tasks that only the owner (not a performer-customer) would ever need to do. Build this once the app itself settles down — noted here as items come up so nothing gets forgotten.

## Confirmed topics to include (added as they came up in conversation)

**Promo codes & affiliate links**
- How to create a promo code via the Supabase SQL editor (`insert into promo_codes ...`), with worked examples for each combination: pure comp/free account, percentage discount (perpetual vs. time-limited), affiliate code with its own commission terms.
- How affiliate links work (`signup.html?ref=CODE`) vs. a typed code — same underlying mechanism.
- Current limitation to document: `promo_codes` only supports percentage-based discounts (`discount_percent`), not a flat dollar amount off. If a `discount_amount_cents`-style column gets added later, document that path too.
- How to deactivate a code (`active = false`) or cap its uses (`max_redemptions`).
- Where affiliate commission terms live and why they're not publicly queryable (RLS with no anon/authenticated read policy on `promo_codes`) — i.e., don't be alarmed that you can't see it from the signup page.

**Account administration**
- How to manually create a performer account without going through signup.html (the process used for the `travis-ross-test` account) — useful for white-glove onboarding, comps, or troubleshooting.
- How to look up / edit a performer's `plan_status`, `discount_percent`, `discount_months`, `referral_code` directly.
- How the `travis-ross-test` standing test account works and why it's safe to use for testing without polluting real reporting data.
- Supabase's "confirm email" setting — what it does, where to find it, and the tradeoff (instant login vs. requiring email confirmation). **Decided 2026-08-20: turning this ON**, motivated in part by wanting real, verified addresses toward an eventual email list. Document exactly where the toggle lives (Authentication → Providers/Settings → Email) and that customizing the confirmation email's subject/body lives in Authentication → Email Templates.
- Building an actual marketing email list is a separate, later piece of work — confirming an email only verifies it's real/reachable, it doesn't capture marketing opt-in consent or give a bulk-export/send mechanism. Document the eventual approach once decided (an opt-in checkbox at signup + manual export, vs. syncing `performers.email` into a dedicated tool like Mailchimp).

**Song Library — bulk-adding charts**
- The bulk-add tool in Song Library is one PDF per song — each uploaded file becomes exactly one `songs` row with that file as its chart. A single PDF containing an entire binder of charts (e.g. Ten Cent Prophet's "current charts as of xx" book) will NOT get parsed into individual songs; it'll just upload as one giant "song."
- If a new performer (or Travis himself, updating his own binder) has one big multi-song PDF, it needs to be split into individual per-song PDFs first, then run through bulk-add normally (one file per song, title/artist/key filled in for each).
- How this got solved 2026-08-20 for Ten Cent Prophet's 74-page/60-song binder: Claude read the PDF page-by-page to find where each song started (each song in that file started on a fresh page, sometimes running 2 pages), then used a Python script (pypdf) to split it into 60 individual PDFs plus a manifest CSV (filename, title, artist, key, source pages) to reference while filling out the bulk uploader. The script (`split_charts.py`) is a one-off, not part of the site — it's not saved in the git repo, just delivered as a file. If this comes up again, re-run the same process: upload the big PDF to a session, have Claude read it, hand-build a page-range list per song (song boundaries usually aren't detectable automatically since formatting varies — some charts have title+artist, some just a key, some neither), then split and hand back a zip + manifest.
- A real in-app "split one big PDF into a setlist" feature (client-side, no new backend needed) is still just an idea on the V2 backlog, not built — today's process above is a manual one-off Claude does on request, not a self-serve tool in the console.
- Watch for stray fragments in a multi-song binder that aren't full charts (e.g. a "HEY JUDE" header with only an intro chord line and no lyrics was found in the Ten Cent Prophet binder) — these should be called out and left out of the split rather than silently created as an empty/broken song entry.

**Deployment / "how do I actually update the site"**
- The GitHub → Vercel deploy flow (push to `main`, Vercel auto-deploys).
- Reminder that a Cowork/chat session cannot push to GitHub directly (sandbox git-proxy restriction) — so any code delivered there comes as files to manually upload via the GitHub web UI. Document the manual upload steps concretely (which repo, which branch, drag-and-drop vs. commit-file-by-file) since this was the actual recurring workflow before the switch to Claude Code (which DOES have direct repo push access) — see `HANDOFF-SUMMARY.md`.
- How to run a `.sql` migration file in the Supabase SQL editor safely (copy/paste, run, check for errors, verify with a `select`).
- Where `vercel.json` rewrites live and how routing works (first-match-wins), so a future new page/route doesn't break existing ones.

**Reporting & business data**
- How to use the Reporting tab in console.html (date ranges, what's included/excluded — e.g. manual song-adds are excluded from tallies).
- How to pull/export data for taxes or bookkeeping (currently would require a direct Supabase query — no built-in export yet; flag as a possible future feature if needed).

**Affiliate payouts (once built)**
- Once a real ledger/automation exists: how to see what's owed to each affiliate and how to actually pay them.

**Billing (once built)**
- Once real Stripe billing exists: how to view/manage a performer's subscription, handle refunds, change their plan/tier, etc.

**Device-count enforcement (once built)**
- Once enforcement exists: how to see how many devices/followers a performer has connected, and how to adjust their limit manually if needed (e.g. a one-off exception).

## Not yet decided
- Format: likely a single long-form doc (Markdown or a Word doc), possibly split into sections by task ("Money," "Accounts," "Deploying Changes," "Troubleshooting").
- Whether to include screenshots of the Supabase dashboard / SQL editor for less-technical steps.

## Process note
Add to this list any time a "how do I..." owner-operations question comes up in conversation, rather than only answering it in the moment — so nothing has to be re-explained from scratch when the real guide gets written.
