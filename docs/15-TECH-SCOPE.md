# Technical Scope — Work Package for Claude Code

Written to be handed to a Claude Code session with access to the git repo, Vercel, and Supabase. Each task is self-contained: what to change, why, what to watch out for, and how to verify.

**Context this session should read first:** `01-ARCHITECTURE-AND-DATA-MODEL.md` (storage, auth, RLS patterns), `13-SITE-AUDIT-AND-COMPLIANCE.md` (why these changes exist), `14-EXECUTION-PLAN.md` (sequencing).

**Standing constraints for every task here:**

- **Staging first.** `songchart-staging` bucket and the `bribe-the-band-staging` Vercel project both exist with a full copy of production data. Nothing in Task 1 touches production until it's been run end-to-end on staging.
- **Never write to Supabase from a serverless function with a bare anon-key client.** A previous chart migration lost ~46 rows of updates to this exact bug: `auth.getUser(token)` validates a token but does not attach it to the client's outgoing requests, so RLS silently allowed the write against zero rows and no error surfaced. Database writes belong either client-side under the real session, or in the SQL Editor as an admin.
- **Prefer additive schema changes.** New nullable columns, backfilled, then cut over.

**Priority:** Tasks 1–5 are marked **PRE-GIG** — there's a live band gig in six days and bandmates creating accounts this week. Everything else can follow.

---

## Task 1 — Randomize chart object keys

**PRE-GIG if time allows, otherwise first thing after.**

### The problem

Charts live at `charts/{performer_id}/{song_id}.pdf` where `song_id` is a slugified title (`wonderwall.pdf`). The bucket is public-read by policy and **confirmed not enumerable** (a bucket-root request returns AccessDenied), but filenames are deterministic: the crowd page publishes every song title publicly, so one leaked chart URL plus the public setlist yields the entire catalog with no guessing. Confirmed live on 2026-09-14.

This task makes object keys random so a leaked URL exposes exactly one chart. It does **not** make the bucket private — that's the separate signed-URL project, deliberately deferred.

### Schema

Add a nullable column to `songs`:

```sql
alter table songs add column if not exists chart_key text;
create index if not exists songs_chart_key_idx on songs (chart_key);
```

`chart_key` holds only the random token — no path, no extension. Format: 32 lowercase hex characters (`randomBytes(16).toString('hex')` or `crypto.randomUUID().replace(/-/g,'')`).

Full object key is always `charts/{performer_id}/{chart_key}.pdf`. `chart_url` continues to hold the full public URL and remains the field the viewer and exports read.

### Two gotchas that will break a naive migration

**1. Chart files are shared across performers.** Production has ~120 unique chart files backing ~171 song rows. The `travis-ross-test` account's songs point at `travis-ross`'s actual files rather than duplicates. **Generate one new key per distinct `chart_url`, not per row**, and update every row referencing that URL together. Keying per-row will orphan the test account.

**2. Two known orphaned objects** exist in production with no matching song row:
- `charts/6601ef4b-c3d0-4fb8-bdc9-0e27ab7b6404/the-rescue-song-a.pdf`
- `charts/6601ef4b-c3d0-4fb8-bdc9-0e27ab7b6404/-good-plans.pdf`

Skip them during migration and delete them at the end as cleanup.

### Migration sequence

Non-destructive until the final step. Run on staging first, verify, then production.

1. **Read** distinct non-null `chart_url` values from `songs`, with the set of song ids referencing each.
2. **Generate** one random key per distinct URL.
3. **Copy** in Wasabi (S3 `CopyObject`, same bucket) from old key to `charts/{performer_id}/{new_key}.pdf`. Derive `performer_id` from the existing path, not from a fresh lookup — some rows reference another performer's folder, and that's intentional.
4. **Verify** every new object returns HTTP 200 before touching the database. Abort on any failure.
5. **Emit SQL** — a file of `update songs set chart_url = '...', chart_key = '...' where id in (...);` statements.
6. **Run that SQL in the Supabase SQL Editor.** Not from a function. Not from the script. See the standing constraint above.
7. **Verify in the app**: open the console's chart links, run the viewer on a real setlist, run a setlist PDF export and a ZIP export. The export path fetches `chart_url` client-side with `pdf-lib`, so it's the best single smoke test.
8. **Delete old objects** only after 7 passes. Then delete the two orphans.

Credentials: the existing dedicated Wasabi sub-user (`WASABI_ACCESS_KEY_ID` / `WASABI_SECRET_ACCESS_KEY`), scoped to the `songchart` bucket. Run the script locally against those, not through Vercel.

### Code changes

**`api/wasabi-upload-url.js`** — currently signs a PUT scoped to `charts/{caller's performer_id}/{slug}.pdf`. Change it to accept a client-supplied `chart_key` and sign `charts/{caller's performer_id}/{chart_key}.pdf`.

**Validate the key server-side before signing:** reject anything not matching `/^[a-f0-9]{32}$/`. This is the whole path-traversal defense — without it a client can write anywhere in the bucket. Keep the existing behavior of looking up the caller's own performer row rather than trusting a client-supplied id.

**`api/wasabi-delete-chart.js`** — same change. Accept `chart_key`, apply the same regex, issue `DeleteObjectCommand` for `charts/{caller's performer_id}/{chart_key}.pdf`.

**Console (`console.html`)** — everywhere a chart is uploaded (Add a Song, Bulk Add from PDFs, Manage Songs → replace):
- Generate a fresh key client-side with `crypto.randomUUID().replace(/-/g,'')`.
- Request the presigned URL for that key, PUT the file, then write both `chart_url` and `chart_key` in the same authenticated save that already happens client-side.
- **On replace, generate a NEW key rather than reusing the old one, and delete the old object after the new one is confirmed uploaded.** Two benefits: a previously leaked URL dies the moment a chart is updated, and the `?v=<timestamp>` cache-buster becomes unnecessary because the URL genuinely changes. Leave the cache-buster in place for now; remove it in a later cleanup once every chart has a random key.
- On delete, pass `chart_key` instead of the slug.

### Verify

- Upload a new chart → lands at a random key, `chart_key` populated, viewer renders it.
- Replace a chart → new key, new URL, old object gone from the bucket.
- Delete a song → object removed, setlist references stripped (existing behavior, confirm unbroken).
- Old-style URL for a migrated chart → 404.
- Guessing `charts/{performer_id}/landslide.pdf` → 404.
- Bucket root → still AccessDenied.
- A song with no chart → `chart_key` null, everything still works.

---

## Task 2 — Dynamic statement descriptor

**PRE-GIG. Highest chargeback-reduction per hour of work on this list.**

In the Stripe dashboard, set **Shortened descriptor** to `BTB-TIP` and the full statement descriptor to `BRIBETHEBAND.LIVE`. (If Stripe rejects the two as dissimilar, use `BRIBETHEBAND` as the root for both.)

In `api/create-payment-intent.js`, pass `statement_descriptor_suffix` on the PaymentIntent, derived from the performer's display name:

- Uppercase, strip everything outside `A–Z 0–9 space`, collapse whitespace, trim to **13 characters**.
- Combined limit is 22 including the `PREFIX* ` join, so `BTB-TIP` (7) plus separator leaves 13.
- If the sanitized result is empty, omit the parameter entirely so the default descriptor applies. Don't pass an empty string.

Result on a statement: `BTB-TIP* TEN CENT PRO`.

The tipper remembers the band, not the platform. This is the single most common cause of "I don't recognize this charge" disputes in tipping products.

**Note for later:** suffix support and rendering vary by card network and issuing bank; some truncate further. Worth a live test with a real card after deploy — check what actually appears in a banking app, not just the Stripe dashboard.

---

## Task 3 — Tip presets and minimum

**PRE-GIG.**

Change crowd page presets from `$2 / $5 / $10 / Custom` to **`$5 / $10 / $20 / Custom`**.

Enforce a **$3 minimum** on Custom, client-side and server-side. At 10% plus Stripe's 2.9% + 30¢, a $1 tip nets the performer about $0.57 — 43% gone. Nobody is served by that.

**Make the minimum visible rather than a validation error.** Helper text under the Custom field before anyone types:

> Minimum $3 — card fees eat most of anything smaller.

That sentence does double duty: it sets the rule and it explains it, which is the same honesty posture as the pricing page. A bare "minimum $3" reads as a money grab; the explanation reads as advice.

Server-side, reject amounts under $3 in `create-payment-intent.js` — client validation is a convenience, not a control.

---

## Task 4 — Crowd page payment disclosure

**PRE-GIG. This is the most legally protective change in the entire package.**

Card network dispute rules turn on whether the refund policy was disclosed *at the point of purchase*. A policy page nobody read does very little; this text does the work. Ship it before the policy pages exist.

Full strings are in `LEGAL-DRAFT-refund-and-request-policy.md` under "Required UI microcopy." Four placements:

- **A** — above the pay button on the payment screen. Must be visible without scrolling or expanding anything. Small type is fine; behind a disclosure triangle is not.
- **B** — Boost confirmation.
- **D** — tip-only flow.
- **E** — one added line on the success screen.

Use `BTB-TIP` in the "appears on your statement as" line, matching Task 2.

**Do not ship microcopy C.** Notes were verified on 2026-09-14 as performer-device only, so the existing placeholder is accurate. Optional improvement only: *"Add a note (optional) — only the band sees this."*

Where the strings reference `/refunds`, link them even though the page doesn't exist yet — wire the href now, publish the page in Stage 3.

---

## Task 5 — "Followers" → "Bandmates"

**PRE-GIG. Bandmates are creating accounts this week — this is the week the word matters.**

Rename throughout: UI copy, marketing pages, button labels, help text. `viewer.html?join=<code>`, the "Follow Someone Else's Gig" settings control, and every string describing the role.

**Rename the user-facing vocabulary only.** Leave database columns, internal variables, and the Master/Follower device-role terminology alone unless it's trivially safe — a display-layer rename is a one-hour job, a schema rename is a migration with no user benefit. If internal naming gets confusing later, that's a separate cleanup.

Suggested replacements: "Follow Someone Else's Gig" → **"Join a Bandmate's Gig"**; "Followers" in any roster or count → **"Bandmates"**.

---

## Task 6 — Retire signup.html

`/get-started` already carries a full signup form. `signup.html` is a second, different form behind a button — so a visitor types their details, clicks, and gets asked again.

Make `/get-started` the single signup surface with a working form. Redirect `signup.html` → `/get-started` (301) rather than deleting it, since the URL may be in existing links or emails.

---

## Task 7 — Clean URLs

Route `/login` → `console.html` and keep the existing `/signup` rewrite pattern. Update every nav link, CTA, and internal reference so no raw `.html` filename appears in the UI. Keep the old paths working as redirects.

---

## Task 8 — Chart upload size cap

There's currently no file size limit and no page limit on chart uploads. One 400MB scan costs storage indefinitely and produces a chart that won't load on bar wifi.

Add a **10MB per-file cap**, enforced client-side in the console before requesting the presigned URL, in all three upload paths (Add a Song, Bulk Add, Replace). Generous for a chord chart by roughly an order of magnitude.

Error copy should say what to do, not just what failed:

> That file's over 10MB. Chord charts are usually well under 1MB — if this is a scan, try exporting it again at a lower resolution.

Multi-page charts work correctly and should stay unlimited in page count. No change there.

---

## Task 9 — Fix `/demo`

`/demo` is the destination of the homepage's "See a live crowd page" link and currently renders "Offstage — For Now," "Loading songs…," and "Nothing's been requested yet." Your highest-intent link demonstrates an empty app.

Seed it so it always renders a populated, live-looking crowd page: a real setlist, two or three songs already queued with dollar amounts, a Last Call banner, an expanded Recently Played list. Static seed data is fine — it doesn't need to be a real gig, it needs to look like one.

Make the tip buttons non-functional or clearly demo-only so nobody is charged.

---

## Task 10 — Terms acceptance at signup

**Gated on the legal pages being published (Stage 3).** Schema first.

```sql
alter table performers add column if not exists terms_accepted_at timestamptz;
alter table performers add column if not exists terms_version text;
```

Then on `/get-started`: an **unchecked** checkbox reading *"I agree to the Terms of Service, Privacy Policy, and Refund & Request Policy"* with all three linked, blocking submit until checked, writing both columns on account creation.

Implied acceptance via a footer link is weak evidence. An explicit timestamp and version string is the point.

Add the three links to the site-wide footer at the same time, including on the crowd page and in the console.

---

## Task 11 — Homepage hook

Copy change, but it needs implementing.

Current hook promises to solve "someone asks for a song you don't know. Or worse — you do." The product sidesteps the first case entirely: the crowd only ever sees songs you've put on the list. A performer notices that gap, and it's on the strongest page on the site.

Rewrite around the half that's true — **you do know it, and the chart is already in front of you before the tip clears.** Final copy to come with the marketing page revisions; flagged here so it's in the same batch.

---

## Suggested order

**This week, before the gig:** 5 (bandmates see it), 2, 3, 4. Then 1 if there's room — it's the biggest and shouldn't be rushed the day before a show.

**Next:** 1 (if not done), 9, 8, 6, 7.

**After the legal pages exist:** 10, 11.

**Separate project, not in this package:** private bucket with signed URLs, bundled with offline chart caching. Both want the same architecture — resolve and pull every chart at Start the Set. Note that signed URLs will break the client-side setlist PDF/ZIP export, which fetches public URLs directly with `pdf-lib` and `jszip`. Scope that before starting.
