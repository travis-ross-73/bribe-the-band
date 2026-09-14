# Marketing Site Audit & Compliance Gaps

Status: **Audit complete 2026-09-13. Nothing in Tier 0 has been actioned yet.** Written from a cold outside read of the live production site (`bribetheband.live` homepage, `/how-it-works`, `/features`, `/get-started`, `/demo`, `/signup.html`) with no assumptions carried in from the rest of this project's docs, then reconciled against them. Prompted by Travis asking for an objective outside assessment ahead of opening the platform to performers beyond himself.

**Not legal advice.** Section 1 is a checklist to bring to a Colorado business attorney, not a substitute for one. The accompanying drafts (`LEGAL-DRAFT-terms-of-service.md`, `LEGAL-DRAFT-privacy-policy.md`, `LEGAL-DRAFT-refund-and-request-policy.md`) are starting points for that same review.

---

## The headline finding

The copy is genuinely good — specific, credible, written in a real voice, a clear cut above the category. The problems are almost entirely **gaps rather than prose**, and they cluster in three places:

1. **There is no legal layer at all.** No Terms, no Privacy Policy, no refund policy, no contact information, no named legal entity. The footer is `© 2026 · Built by a working musician`. For a platform that is merchant of record on other people's money, this is the most urgent item in this document and it grows more urgent with every performer who signs up.
2. **The fee disclosure is technically true and practically misleading.** "We take 10% of tips — no monthly fee, nothing else" does not mention that Stripe's ~2.9% + 30¢ comes out of the performer's 90%. A performer reads that line as "I get $4.50 of a $5 tip." They actually get about $4.05. That gap gets discovered on the first payout report, which is the worst possible moment.
3. **Nothing proves the software is real.** Every screenshot is a CSS recreation, there are no testimonials, no video, no named human, and the one "see it live" link is broken in effect (see below).

---

## Confirmed bug: the `/demo` link

The homepage's primary proof CTA — **"See a live crowd page →"** — lands on `/demo`, which currently renders:

> Offstage — For Now · Loading songs… · Nothing's been requested yet — request a song below!

This is the single highest-intent link on the site and it currently demonstrates an empty, apparently-loading app. Every prospect who clicks "see it live" gets the opposite of proof.

**Fix:** `/demo` should always render a populated, live-looking crowd page — a real setlist, two or three songs already in the queue with dollar amounts, a Last Call banner, the Recently Played list expanded. Static seed data is fine; it does not need to be a real gig. This is probably a one-evening fix and is the highest ROI item outside Tier 0.

---

## 1. Legal & compliance gaps

### Required or near-required before a second performer signs up

| Item | Why | Notes |
|---|---|---|
| **Terms of Service** | Stripe Connect platform requirement; allocates chargeback liability; no contractual basis for the fee without it | Footer-linked *and* an explicit checkbox at signup, not implied acceptance. Must reference the Stripe Connected Account Agreement. |
| **Privacy Policy** | CalOPPA applies to any site collecting PII from CA residents regardless of size; Stripe and Apple Pay domain verification both expect one | Must distinguish performer data from anonymous audience data, and name sub-processors. |
| **Refund / request policy** | Biggest consumer-protection exposure. Architecture treats a tip as collected at submission with no refund flow, including on decline | Card network rules treat a clearly disclosed policy shown *at the time of purchase* as a dispute defense. Without one the issuer generally sides with the cardholder. |
| **Chargeback recoupment language** | With `transfer_data.destination` + `application_fee_amount`, BTB is merchant of record and carries dispute liability — exactly what Stripe made Travis acknowledge during platform enrollment (item 37) | Terms must give BTB the right to recover a lost dispute from the performer's future tips. Otherwise Travis personally eats every one. |
| **Legal entity (LLC)** | Sole-proprietor operation means personal liability for disputes, performer claims, and copyright complaints | Colorado LLC is cheap to form and maintain. Stripe platform account should sit under it. Name it in the footer. |
| **Statement descriptor** | Unrecognized descriptors are the top cause of friendly-fraud chargebacks in tipping products | Set explicitly in Stripe, then disclose it on the crowd page at checkout ("appears as BRIBETHEBAND"). |
| **DMCA designated agent** | BTB hosts user-uploaded copyrighted chord charts | Registration with the Copyright Office is ~$6. Difference between "removed on notice" and being a direct defendant. Needs an agent notice on the site and a takedown procedure in the Terms. |
| **Chart storage exposure** | Chart storage confirmed public-read on Wasabi, with guessable filenames | See the dedicated section below — this one has a real staging decision in it rather than a single action. |
| **Performance-licensing disclaimer** | The product exists to generate cover-song requests | ASCAP/BMI/SESAC is the venue's obligation in nearly all cases, but Terms should state BTB neither provides nor verifies it. |
| **Age gate (18+)** | Anyone with a phone can tip; COPPA under 13 | One clause in the Terms plus a line on the crowd page. |
| **Tax disclosure** | Performers receive taxable income; Stripe generally files 1099-Ks on Express accounts | **Confirm the current 1099-K threshold rather than publishing a number** — it has changed repeatedly. Confirm in the Connect dashboard who is filing, and tell performers where to find their forms. |

### Already handled correctly

- **Money transmission avoided** by using Connect destination charges rather than pooling — the decision made 2026-08-27 and held to since. The one place this could drift is the manual affiliate ledger; it stays clean only as long as commissions are paid out of platform revenue rather than routed from tip money.
- **Stripe hosted Express onboarding** presents the Connected Account Agreement, so acceptance of Stripe's own terms is covered. BTB's terms still need to reference it.
- **PCI scope** is minimal — card data never touches BTB servers (Elements client-side, webhook server-side).

---

## 1a. Chart storage — analysis and staged recommendation

**Confirmed 2026-09-13:** the `songchart` Wasabi bucket is public-read. A live chart URL looks like:

```
https://s3.us-east-1.wasabisys.com/songchart/charts/{performer-uuid}/{song-slug}.pdf
                                                    ↑ unguessable        ↑ guessable
```

### What's actually wrong with it

This is a **capability URL** model — the same thing Dropbox share links and "anyone with the link" Google Docs use. The performer folder is a UUID with ~122 bits of entropy, which is genuinely unguessable. That part is fine.

The weakness is the filename. Song slugs are derived from titles, so **one leaked URL exposes an entire catalog** — a holder of the Closing Time link can try `wagon-wheel.pdf`, `landslide.pdf`, and walk the whole setlist. Leak vectors are ordinary: a bandmate who leaves the band, a borrowed tablet's history, a screenshot, browser sync, right-click → copy link.

**Unverified and worth ruling out today:** whether the bucket is enumerable. Run `curl https://s3.us-east-1.wasabisys.com/songchart`. If it returns an XML object listing, everything above is moot and the whole library is already walkable — fix the bucket policy immediately.

### Risk

- **Copyright discoverability.** Public access doesn't break DMCA safe harbor (YouTube is public), so registering an agent still protects you. What it changes is whether a rights-holder's crawler ever finds you. Publishers have a long history of pursuing chord/tab hosting; a world-readable bucket is discoverable in a way a private one isn't. Not a doctrine problem — a "do you ever get the letter" problem.
- **Inducing performers into a worse position.** `11-CHART-APP-IMPORT-SCOPE.md` actively tutorializes the UG → BTB path. UG §6.2 permits printing for personal use but grants "no right to provide any files obtained through the Service to any other party." A performer uploading a UG PDF into a world-readable bucket is in clearer violation than one uploading into a private one, and the product is what routed them there.
- **Misrepresentation, which is the sharp one.** The marketing copy promises charts stay performer-side in four places. A privacy policy asserting charts are never publicly accessible, while they're world-readable, is independently actionable (FTC §5, state UDAP) in a way the storage choice itself is not.

### Reward of leaving it alone

Real, and not to be dismissed: simplicity, no expiry logic, fast page turns, nothing to break mid-gig. Mid-set chart failure is the single worst thing this product can do to a performer.

### The staged recommendation

**Now (~1 hour, no architectural change):**
1. Verify the bucket isn't enumerable.
2. Decouple the storage key from the song slug — add a `chart_object_key` column holding a random token, so one leaked URL leaks one chart rather than a catalog. Existing charts can rotate lazily on next upload rather than needing a bulk migration.
3. **Fix the copy rather than overclaim.** Don't publish "never publicly accessible." Publish what's true and sells the same benefit: *"your audience never sees your charts — the crowd page shows title and artist only."* Accurate today, accurate after signed URLs, never needs retracting.

**Soon — and bundle it with offline caching:**

Private bucket plus presigned URLs. Flip the bucket private, add an authenticated endpoint that verifies the caller is the owning performer or a currently-joined Bandmate on a live gig, return a time-limited signed URL. **The authorization pattern already exists** — `get_spliced_requests_for_gig` is a SECURITY DEFINER function authorized for exactly "the gig's Master or a currently-joined Follower."

The real risk is expiry mid-set. Signature V4 presigned URLs support up to 7 days, so a 12-hour TTL minted at Start the Set covers any gig with enormous margin.

**The convergence worth planning around:** signed URLs and offline chart caching want the *same* architecture — resolve and pull every chart in tonight's setlist at Start the Set. Built together, the expiry risk largely disappears because the PDFs are already on the device before the first song, and Tier 3 item 14 (offline caching, which kills the #1 signup objection) ships in the same project. **Recommend treating these as one build, not two.**

A streaming proxy through Vercel (`api/chart/{id}`) is the alternative. Simpler auth, no expiry, but it puts PDF bytes through serverless functions — bandwidth cost, cold starts, response-size limits, slower page turns. Presigned URLs are the better fit here.

---

## 2. Signup blockers, as a cold prospect would rank them

1. **Venue wifi.** Setlist and charts live in a web app; bar internet is famously bad. The site says nothing about degraded-network behavior. For a working musician this is close to disqualifying on its own and it is the first question any peer will ask.
2. **User number two.** "Built by one performer," "since the summer of 2026," no other names, no testimonials, no logos. Reads as a project, not a service to route income through.
3. **The real cost isn't 10%.** See the math table below.
4. **Unpriced migration cost.** "Bulk Import" is one bullet. `11-CHART-APP-IMPORT-SCOPE.md` internally estimates ~1 min/song for the UG path. Nobody signs up for an unpriced evening.
5. **Hardware ambiguity.** Everything shows a tablet. Phone? iPad specifically? Second device needed?
6. **Bandmate cost.** "Every bandmate follows from their own account" implies four signups and possibly four somethings. Never addressed.
7. **No dress rehearsal.** Can browse the crowd page, can't run a realistic full-flow test with fake tips before betting a paying gig on it.
8. **Lock-in.** No export mentioned. If BTB goes away, does the chart library?
9. **Venue politics.** Some rooms have opinions about digital tip funnels. No guidance.
10. **No human.** No name, no face, no company, no contact — on the far side of entering bank details.

### The fee math, as a performer will eventually compute it

Platform fee is computed on the gross tip; Stripe's ~2.9% + 30¢ comes out of the performer's share.

| Tip | Platform fee (10%) | Stripe (approx) | Performer receives | Total taken |
|---|---|---|---|---|
| $2 | $0.20 | $0.36 | **$1.44** | **~28%** |
| $5 | $0.50 | $0.45 | **$4.05** | **~19%** |
| $10 | $1.00 | $0.59 | **$8.41** | **~16%** |
| $20 | $2.00 | $0.88 | **$17.12** | **~14%** |

Two observations:

- The **$2 preset is the worst-value option on the crowd page** and sits in the leftmost, most-tapped position. The fixed 30¢ dominates at that size. Moving the lowest preset to $5 is the cheapest of the available levers and likely raises average tip size anyway.
- Project notes carry a **6–8% recommendation anchored at 7%**; production ships 10%. Three levers exist: lower the headline, absorb Stripe's fee into the 10%, or raise the minimum tip. This is a business decision, not an audit finding — but the disclosure problem must be fixed regardless of which lever gets pulled.

---

## 3. Copy issues

| Location | Issue | Direction |
|---|---|---|
| Homepage, /features, /get-started | **"10% of tips, nothing else"** | Name both fees. Link to a pricing page with the table above. |
| Homepage | **"Money lands straight in your own account — nothing pools, nothing waits"** | "Nothing waits" implies instant. Stripe Express payouts are typically a couple of business days, first one longer. Replace with "on Stripe's normal payout schedule, straight to your own bank." |
| Homepage hook | **"Someone asks for a song you don't know. Or worse — you do."** | The product *sidesteps* the first case (crowd only sees songs you're ready to play) rather than solving it. A performer will notice. Lead with the second half — you do know it, and the chart is already there. |
| /features, /how-it-works | **"Followers"** for bandmates | On a music platform "followers" means fans. Every use reads wrong for a beat. Already flagged internally as a naming collision; this confirms it from outside. Bandmates / Sidemen / On Stage. |
| Crowd copy vs. performer copy | **Who controls the set?** Crowd side says tips decide what's played next; performer side says Accept/Decline | Both audiences are told they're in charge. The fan-side version is the risky one — "I paid to move this up" plus a decline is precisely the expectation gap that becomes a chargeback. |
| Crowd page | **Boost with no stated outcome** | A fan can stack money on a song that never gets played. Nothing anywhere says what that means. |
| /features | **"real card and Apple Pay payments (Safari)"** | The parenthetical reads as half-finished. Broaden wallet support or drop the caveat from marketing copy. |
| Homepage, footer | **"Live at real gigs since the summer of 2026"** | As of today that's ~3 months. Phrased as longevity, lands as newness. Own the newness deliberately or drop the date. |
| Nav, CTAs | **`console.html`, `signup.html`** in URLs | Raw filenames signal hobby project. `/login` and `/signup` rewrites already exist for signup — extend the pattern. |
| /get-started → /signup.html | **Two different signup forms** | /get-started renders a full form, the button ships to a second one. Make the first real or make it a plain CTA. |
| /features | **No chart file constraints stated** | Page limits, size, the one-page-per-song assumption. |
| Everywhere | **Nothing about what happens to a declined request's money** | In either direction. |

---

## 4. Marketing pages still missing

- **Pricing page** with the worked table above. Transparency converts *better* here, because everyone assumes they're being shorted.
- **A 45-second video from an actual gig.** QR on a mic stand, a phone requesting, the tablet lighting up, the song getting played. Shootable at one gig. Worth more than every other item on this list combined for this product.
- **Real screenshots.** The CSS recreations are well-made, which is part of the problem — a skeptic reads "mockup."
- **FAQ** taking section 2 head-on: wifi/offline, hardware, bandmate cost, payout timing, declined requests, data export, taxes, venue etiquette, originals-only sets.
- **About page with a name and a face.** "Built by a working musician" is the strongest asset on the site and it's currently an anonymous paragraph.
- **Trust footer**: entity name, Terms, Privacy, Refunds, Contact, DMCA, "Payments secured by Stripe."
- **Founding-performer proof.** Don't fake testimonials — run a founding cohort at 0% fee for a year in exchange for a quote and a photo. The fee-waiver mechanism (`performers.fee_percentage = 0`) already exists.
- **A venues page.** Venues are both gatekeeper and distribution channel. One page for booking managers opens a door performer-by-performer marketing can't.
- **Comparison pages**: vs. Tiply, vs. a Venmo QR code, "song request app for live musicians." Low competition, high intent.
- **Email capture for the not-yet-ready.** Only conversion today is full signup; most interested performers have their next gig three weeks out.

---

## 5. Features that would move signups

Ordered by which objection each one kills:

1. **Offline chart caching** — cache tonight's setlist PDFs on device at set start. Kills objection #1 and converts a liability into a marketing line.
2. **Practice/sandbox gig** with fake tips — full dress rehearsal before connecting a bank account. Also resolves the still-open "when do we nudge toward Stripe" question in `09-CONNECT-EXPRESS-SCOPE.md` by making the nudge unnecessary until the performer is ready.
3. **Explicitly free bandmate accounts**, stated on the pricing page.
4. **A refund button** — required for the legal posture, and "I can make it right" is a feature performers value.
5. **Printable QR assets** generated per handle: table tent, mic-stand card, a sign. This is the real-world step that silently kills first gigs.
6. **In-app payout clarity**: "$47.30 arriving Thursday."
7. **Data export** for songs, charts, request history.
8. **Phone fallback** for the performer's own view.
9. **Crowd-page branding + fan email capture** — the crowd page is the most valuable marketing surface a local performer has. Letting them build a mailing list off it is a reason to choose BTB over a Venmo QR that has nothing to do with charts.
10. **Multi-set support.** Most bar gigs are three sets. Currently deferred with a manual stop button — fine internally, a visible gap to a stranger reading /features.

---

## 6. Ranked action order

### Tier 0 — before a second performer signs up
Everything here is exposure that compounds with each new user.

1. Rewrite the fee disclosure; add the worked math. (One afternoon.)
2. Publish Terms, Privacy, and Refund policy. Footer-linked, signup checkbox, plus the non-refundable / not-a-guarantee line at the crowd-page payment step.
3. Form the LLC, move the Stripe platform account under it, name it in the footer, set the statement descriptor.
4. Chargeback recoupment language in the Terms.
5. DMCA agent registration + switch chart storage to signed URLs.

### Tier 1 — conversion leaks, cheap to plug
6. Fix `/demo`.
7. Pricing page with math.
8. FAQ.
9. About page with name and face.
10. Copy fixes: rename "Followers," realign the homepage story with the product, drop `.html` URLs, collapse the duplicate signup form.

### Tier 2 — proof
11. Gig video.
12. Real screenshots.
13. Founding-performer cohort at 0%.

### Tier 3 — product, in objection order
14. Offline chart caching.
15. Practice/sandbox gig.
16. Refund button.
17. Printable QR assets.
18. Crowd-page branding + fan email capture.
19. Multi-set support.

---

## Open decisions this audit surfaces

- **Fee level.** 10% shipped vs. 7% recommended internally, against a real total cost of 14–28% depending on tip size. Lower the headline, absorb Stripe's fee, or raise the minimum preset — pick one before publishing a pricing page, because the pricing page is what locks it in publicly.
- **Refund mechanics.** `09-CONNECT-EXPRESS-SCOPE.md` explicitly punted "refunds through Connect" until someone asked. Publishing a refund policy forces the question: either the policy is genuinely "no refunds, ever" (defensible if disclosed at the payment step) or a refund button gets built. The draft policy is written for the first, with the second flagged as the intended follow-up.
- ~~**Are audience notes public?**~~ **Resolved 2026-09-13** — shown to the performer *and* may appear on the public queue. Privacy policy and Terms updated. **Action item:** the current note-field placeholder ("dedicate it to someone, request an occasion, whatever you'd like") invites people to write things they may not realize the room can read. Replace with the string in the Refund policy draft, microcopy C.
- ~~**What a Bandmate account costs**~~ **Resolved 2026-09-13** — all accounts are free, and "Bandmate" is a per-gig role rather than an account type, matching the Master/Follower design in `01-ARCHITECTURE-AND-DATA-MODEL.md`. A Bandmate needs no payout account to join someone's gig; they connect one only if they want to run their own gigs. **Action item:** `05-SIGNUP-SCOPE.md`'s device-count pricing tiers (Tier A/B/C, $9–$19/month) are stale and should be struck from that doc so a future session doesn't resurrect them. Monetization is the tip percentage, full stop.
- ~~**Chart storage exposure**~~ — staged recommendation now written up in §1a above. The one thing that can't wait: don't publish a privacy claim of "never publicly accessible" while the bucket is public.

## Related docs

- `04-DECISIONS-AND-OPEN-QUESTIONS.md` items 23, 36–39 — monetization numbers and the Connect build.
- `09-CONNECT-EXPRESS-SCOPE.md` — merchant-of-record posture, the deferred refund mechanics, the open new-signup nudge question.
- `11-CHART-APP-IMPORT-SCOPE.md` — the migration-cost estimates that belong in the FAQ, and the existing copyright guardrails.
- `12-PATENT-RISK-ASSESSMENT.md` — separate legal thread, not folded in here.
- `LEGAL-DRAFT-terms-of-service.md`, `LEGAL-DRAFT-privacy-policy.md`, `LEGAL-DRAFT-refund-and-request-policy.md` — the Tier 0 item 2 drafts.
