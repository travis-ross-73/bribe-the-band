# Execution Plan — Compliance, Copy & Conversion

Companion to `13-SITE-AUDIT-AND-COMPLIANCE.md`. That doc says *what's wrong*; this one says *in what order to fix it and what blocks what*.

**The organizing principle:** two things have calendar lead time you can't compress — **forming the LLC** and **attorney review**. Everything in the legal track waits on them. So they start on day one even though they finish late, and the fast independent work runs alongside rather than behind.

**The second principle:** don't publish a claim before the thing it claims is true. Several items below are sequenced purely so the privacy policy and FAQ don't have to describe a system that hasn't shipped yet.

---

## Stage 0 — Decisions and verification

**Everything downstream is gated on this.** Roughly one sitting, plus a few minutes of checking things in Supabase/Wasabi/Stripe.

Use `BTB-Decision-Questionnaire.html`. It covers 20 decisions across entity, money, legal drafting, chart storage, naming, and sequencing, plus seven verification checks where the answer is a fact rather than a preference. It outputs a single pasteable brief.

**The seven verification checks**, because they need real answers and I can't get them from outside:

| Check | How |
|---|---|
| Is the Wasabi bucket enumerable? | `curl https://s3.us-east-1.wasabisys.com/songchart` — XML listing means fix the bucket policy today |
| Does `viewer.html` render usably on a phone? | Open it on your phone |
| Chart PDF limits — pages, file size, multi-page behavior | Upload a 3-page chart and a 20MB file |
| Any analytics or error-monitoring tool running? | Check Vercel project + `index.html` head |
| Does deleting a song remove the chart file from Wasabi? | Delete a test song, check the bucket |
| Do audience notes appear on the public queue, verbatim? | Submit a test request with a note, look at the crowd page on a second device |
| Is the manual "stop taking requests" button still how intermissions work? | Console |

---

## Stage 1 — Clock-starters (day one, then they run themselves)

These have external turnaround. Start all four the same day and stop thinking about them.

1. **File the LLC.** Colorado SOS online filing. Needs: name, registered agent, principal address. Same-day to a few days.
2. **Engage an attorney.** Send the three drafts plus the audit doc. What you're buying is review and the two decisions I deliberately left open (arbitration vs. courts, GDPR posture), not drafting from scratch — which is why the drafts exist. A Colorado business attorney with payments-platform experience; a general small-business attorney will miss the merchant-of-record and chargeback-allocation issues.
3. **Set up the email addresses.** You already have the M365 tenant and alias infrastructure for `bribetheband.live`. Needs `support@`, and either `legal@`/`privacy@` or a decision to route everything to one box.
4. **Set the Stripe statement descriptor.** Five minutes, no dependencies, and it's referenced three times in the refund policy. Do it before anything references it.

**Blocked until the LLC exists:** DMCA agent registration (needs the entity and its address), moving the Stripe platform account to the entity, and the entity name in the footer and all three legal docs.

---

## Stage 2 — Ship this week (no dependencies at all)

Everything here is independent of Stage 0 and Stage 1. It's also, per dollar of effort, the highest-value work on the list.

1. **Crowd-page payment disclosure.** Microcopy strings A, B, D, E from the refund policy draft. **This is the single most protective thing on this entire plan** — card-network dispute rules turn on disclosure at the point of purchase, not on a policy page nobody read. It protects you even before the policy page exists.
2. **Fix the note-field placeholder.** Current copy invites people to write personal dedications onto a screen the whole room can see. One string.
3. **Fix `/demo`.** Seed it so it always renders a populated crowd page — real setlist, two or three queued songs with amounts, Last Call banner. Your main proof link currently demonstrates an empty app.
4. **Randomize chart object keys.** Add `chart_object_key`, generate a random token per chart, rotate lazily on next upload. Turns "one leaked URL exposes a catalog" into "one leaked URL exposes one chart." ~1 hour.
5. **Act on whatever the bucket check turned up.** If it's enumerable, this jumps to first.

---

## Stage 3 — Legal publish

**Gated on:** Stage 0 decisions (fee number, dispute clause, GDPR posture, entity name, emails, descriptor) + Stage 1 (LLC, attorney).

Order within the stage matters:

1. Fold the Stage 0 decisions into all three drafts. Mechanical — every placeholder becomes a real value.
2. Attorney review, revise, finalize.
3. **Schema first:** add `terms_accepted_at` and `terms_version` to `performers`. Must precede the signup change or the first acceptances aren't recorded.
4. Publish `/terms`, `/privacy`, `/refunds`.
5. Footer links on every page, including the crowd page and the console.
6. Signup checkbox, unchecked by default, writing to the new columns.
7. DMCA agent registration and the agent notice on the site.

**Don't publish the privacy policy's chart-storage paragraph in its stronger form until signed URLs actually ship** — the drafted version is honest about the current state and can go live as-is.

---

## Stage 4 — Marketing pages

**Gated on:** the fee decision (pricing) and the Stage 0 verification answers (FAQ).

1. **Pricing page.** Publish at whatever fee model you picked. If Model C, the code change ships first — see the note below.
2. **FAQ.** Resolve the six `[CONFIRM]` flags from the verification results, delete the practice-gig paragraph if it doesn't exist yet, publish. Link it from the nav.
3. **About page** with your name, face, and the band.
4. **Copy fixes**, all mechanical: rename "Followers," realign the homepage hook with what the product actually does, clean URLs for `console.html`/`signup.html`, collapse the duplicate signup form on `/get-started`.
5. **Trust footer** — entity, legal links, contact, "Payments by Stripe."

**If you picked Model C (15% all-in):** the fee change is a real code change, not a number swap. Absorbing Stripe's fee on a destination charge alters who bears processing costs, plus the presets move, plus `performers.fee_percentage` default changes, plus the Reporting net-payout popover text becomes wrong. Do it on staging first, same as every other money change on this project. **Pricing page publishes after, not before.**

---

## Stage 5 — Proof

**Gated on:** having a gig, which sets the calendar.

1. **Shoot the video at your next gig.** QR on the stand, a phone requesting, the tablet lighting up, the song getting played. 45 seconds. This is the highest-conversion asset available to this product and it costs one gig.
2. **Real screenshots** to replace the CSS recreations.
3. **Founding cohort.** Fee waived for a year via `performers.fee_percentage = 0` — the mechanism already exists. In exchange: feedback after three gigs and permission to quote.

---

## Stage 6 — Product

Ordered by which objection each kills.

1. **Signed URLs + offline chart caching, as one build.** Both want the same architecture — resolve and pull every chart at Start the Set. Together they close the copyright exposure *and* kill the #1 signup objection, and the shared prefetch largely removes the mid-set expiry risk. The authorization pattern already exists in `get_spliced_requests_for_gig`.
2. **Practice-gig mode** with simulated tips. Also resolves the open "when do we nudge toward Stripe" question in `09-CONNECT-EXPRESS-SCOPE.md` by making the nudge unnecessary.
3. **Refund button.** Lets the refund policy promise something concrete, and gives the Terms' recoupment right a mechanism.
4. **Printable QR assets** per handle — table tent, mic-stand card, sign.
5. **Self-serve data export.** Terms §18 already commits to this; until it exists you're honoring it by hand.
6. **Crowd-page branding + fan email capture.**
7. **Multi-set support.**

---

## Dependency map

```
LLC ──────────────┬──> DMCA registration
                  ├──> Stripe account → entity
                  └──> entity name in all 3 legal docs ──┐
                                                          │
Attorney ─────────────────────────────────────────────────┤
                                                          ├──> PUBLISH LEGAL ──> signup checkbox
Fee decision ──┬──> Terms §6.2/6.3 ───────────────────────┘         ↑
               └──> Pricing page                            terms_accepted_at column
                        ↑
               [Model C only: code change first]

Chart decision ──> privacy §4 wording ──> PUBLISH LEGAL
               └──> FAQ chart answer ──> FAQ publish

Verification ──> FAQ [CONFIRM] flags ──> FAQ publish

(independent, no blockers) ──> crowd-page disclosure
                           ──> note placeholder
                           ──> /demo fix
                           ──> chart key randomization
                           ──> statement descriptor

Next gig ──> video ──> homepage + About
```

---

## What I'd actually do first, if you only did three things

1. **Crowd-page payment disclosure.** Protects real money, today, costs an afternoon, depends on nothing.
2. **File the LLC and send the drafts to an attorney.** Starts both clocks.
3. **Fix `/demo`.** Every person you send to that link right now sees an empty app.

Everything else can queue behind those.

---

## Related docs

- `13-SITE-AUDIT-AND-COMPLIANCE.md` — the findings this plan executes against
- `LEGAL-DRAFT-terms-of-service.md`, `LEGAL-DRAFT-privacy-policy.md`, `LEGAL-DRAFT-refund-and-request-policy.md`
- `PRICING-PAGE-COPY.md` — includes the fee-model comparison that Stage 0 decides
- `FAQ-PAGE-COPY.md` — includes the six verification flags
- `BTB-Decision-Questionnaire.html` — the Stage 0 tool
