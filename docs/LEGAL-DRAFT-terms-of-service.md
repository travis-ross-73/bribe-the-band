# Terms of Service — DRAFT

> **⚠️ DRAFT FOR ATTORNEY REVIEW — DO NOT PUBLISH AS-IS.**
> This was written by an AI assistant, not a lawyer. It is a structured starting point designed to save billable hours, not a substitute for review by a Colorado business attorney with payments-platform experience. Sections 6, 8, 9, 11 and 19–21 in particular carry real financial and liability consequences and must be reviewed.
>
> **Placeholders to fill before review:** `[ENTITY]`, `[ENTITY SHORT]`, `[MAILING ADDRESS]`, `[SUPPORT EMAIL]`, `[LEGAL EMAIL]`, `[DMCA AGENT NAME + EMAIL]`, `[EFFECTIVE DATE]`, `[STATEMENT DESCRIPTOR]`.
>
> **Decisions this draft assumes** (confirm each): platform fee is 10% of the gross tip; Stripe's processing fees come out of the performer's share; tips are non-refundable by default; performers bear chargeback liability as between them and the platform; Bandmate accounts are free; governing law is Colorado.

---

**Bribe The Band — Terms of Service**

Effective [EFFECTIVE DATE]

Bribe The Band is operated by [ENTITY], a [STATE] limited liability company ("we," "us," "Bribe The Band"). These Terms are a contract between you and us. By creating an account, connecting a payment account, sending a tip, or otherwise using the service, you agree to them. If you don't agree, don't use the service.

## 1. Plain-language summary

This summary is for orientation only and is not part of the contract. The sections below control.

- Bribe The Band is a tool that lets an audience request songs and send tips to a performer, and lets a performer read their own chord charts on a tablet.
- Tips are paid to the performer, not to us. We take a percentage as our fee. Stripe takes its own processing fee separately, out of the performer's share.
- A request is not a guarantee that a song will be played. Tips are not refundable.
- Performers own their charts and their song lists. We host them so the performer and their bandmates can read them. We never show charts to the audience.
- We're a small company. The service can go down. Have a backup plan for your gig.

## 2. Definitions

- **Performer** — a person or act with a Bribe The Band account who runs gigs, builds setlists, and receives tips.
- **Bandmate** — a person who joins a Performer's live gig using a gig code, to view the same charts and set order on their own device. A Bandmate does not receive tips through the service.
- **Audience Member** — anyone who opens a Performer's Crowd Page. No account is required.
- **Crowd Page** — the public page at `bribetheband.live/[handle]` where Audience Members browse a Performer's songs, send tips, and request songs.
- **Request** — an Audience Member's submission asking the Performer to play a particular song, optionally accompanied by a Tip and a note.
- **Boost** — an additional Tip applied to a song already in the queue.
- **Tip** — a payment from an Audience Member intended for the Performer.
- **Chart** — a PDF or other file a Performer uploads for their own performance use.
- **Platform Fee** — our fee, described in Section 6.
- **Connected Account** — the Performer's own Stripe account, created through Stripe Connect.

## 3. Eligibility

You must be at least 18 years old to create an account, to connect a payment account, or to send a Tip. The service is not directed to children and we do not knowingly collect information from anyone under 13. If you believe a child has used the service, contact [SUPPORT EMAIL] and we will delete the information.

You must have the legal authority to enter this agreement, including on behalf of a band or business if you are signing up for one.

## 4. Accounts

**Creating one.** You provide a display name, a handle, an email address, and a password. You are responsible for the accuracy of what you provide and for everything that happens under your account.

**Handles.** Your handle becomes part of your public URL. You may not choose a handle that impersonates another act, infringes a trademark, or is reserved for our own use (including `signup`, `console`, `viewer`, `request`, `demo`, `admin`, and similar). We may reclaim a handle that violates this section, and we will make a reasonable effort to contact you first.

**Security.** Keep your password confidential. Tell us promptly at [SUPPORT EMAIL] if you believe your account has been accessed without your permission. We are not liable for losses caused by someone else using your credentials, except to the extent the loss was caused by our own failure.

**One account per act.** Don't create multiple accounts to evade fees, limits, or a suspension.

## 5. What the service is, and what it is not

Bribe The Band is a software tool. We are not a booking agent, a promoter, a venue, an employer, a record label, a performing-rights organization, or a party to any arrangement between a Performer and a venue or an audience.

We do not choose what gets played. Every Request is a suggestion; the Performer decides whether to play it, in what order, and whether to play it at all.

We do not verify, provide, or arrange public-performance licenses. Section 11 covers this.

We do not guarantee any level of Tips, audience participation, or income.

## 6. Fees, payments, and payouts

**This is the section to read closely.**

### 6.1 How money moves

Tips are processed by Stripe. Performers must create and connect their own Stripe account through Stripe Connect before they can receive Tips. Until a Performer has a Connected Account in good standing, the service will refuse Tips to that Performer rather than holding funds on their behalf. **We never hold, pool, or take custody of Tip money.** Each Tip is routed to the Performer's own Connected Account at the time of the charge.

By connecting a Stripe account you also agree to the **Stripe Connected Account Agreement** (including the Stripe Services Agreement incorporated into it), which is presented to you during Stripe's onboarding. That agreement is between you and Stripe. If it conflicts with these Terms with respect to Stripe's services, the Stripe agreement controls as to Stripe.

### 6.2 Our fee

We charge a **Platform Fee of 10% of the gross Tip amount**, deducted at the time of the charge. There is no subscription fee, no per-gig fee, and no charge for Bandmate accounts.

We may waive or reduce the Platform Fee for specific accounts (for example, beta users, founding performers, or accounts using a promotional code). A waiver is discretionary and may be time-limited.

### 6.3 Stripe's fees are separate, and come out of your share

**Stripe charges its own processing fee on every transaction — currently around 2.9% plus 30¢ per successful charge, set by Stripe and subject to change by Stripe.** That fee is deducted from the Performer's share, not from our Platform Fee.

Worked example, at current rates, on a $10 Tip:

| | |
|---|---|
| Gross Tip | $10.00 |
| Platform Fee (10% of gross) | −$1.00 |
| Stripe processing fee (approx.) | −$0.59 |
| **Amount reaching the Performer** | **≈ $8.41** |

Smaller Tips are proportionally more affected by Stripe's fixed 30¢ component. Current fee examples across Tip sizes are published at [PRICING PAGE URL].

### 6.4 Payout timing

Payouts are made by Stripe to the Performer's own bank account on Stripe's payout schedule — typically a small number of business days, with a longer delay on a first payout while Stripe completes verification. **We do not control payout timing and cannot expedite it.** Questions about a delayed payout belong with Stripe.

### 6.5 Fee changes

We may change the Platform Fee. We will give Performers at least **30 days' notice** by email and on the site before a change takes effect. A change applies only to Tips processed after the effective date. If you don't accept the new fee, your remedy is to stop using the service and, if you wish, export your data under Section 18.

### 6.6 Statement descriptor

Charges appear on an Audience Member's card statement as **[STATEMENT DESCRIPTOR]**.

## 7. Tips, Requests, and refunds

**A Tip is not a purchase of a performance.** Submitting a Request, or Boosting one, does not obligate a Performer to play that song, to play it in any particular order, or to play it at all. Performers decline requests for ordinary reasons — the set is full, the song was just played, the room isn't right, the night ended.

**Tips are non-refundable**, including where a Request is declined, not reached before the end of the set, or played differently than the Audience Member expected. This is disclosed on the Crowd Page at the point of payment. The full policy, including the narrow circumstances in which we or a Performer may issue a refund anyway, is in our **Refund & Request Policy**, which forms part of these Terms.

Nothing in this section limits any right an Audience Member has that cannot be waived under applicable consumer-protection law.

## 8. Chargebacks and disputes

If an Audience Member disputes a charge with their card issuer, Stripe will typically reverse the transaction and assess a dispute fee.

**As between the Performer and us, the Performer is responsible for chargebacks, reversals, and associated fees arising from Tips paid to that Performer.** We may recover those amounts by deducting them from the Performer's future Tips or by invoicing the Performer directly. We will notify the Performer of any dispute we become aware of and will pass along the information needed to respond.

We may suspend a Performer's ability to receive Tips if their dispute rate materially exceeds normal levels, until the cause is resolved.

## 9. Taxes

Tips received through the service are income to the Performer. **You are solely responsible for determining, reporting, and paying any taxes owed on them.** We do not withhold taxes.

Stripe may be required to issue tax forms (such as a Form 1099-K) to Performers who meet applicable reporting thresholds. Those forms and thresholds are governed by Stripe and by tax law, not by us. Performers can access their tax documents through their Stripe dashboard.

We are not tax advisors and nothing in these Terms is tax advice.

## 10. Your content

**You keep ownership.** Charts, song lists, setlists, notes, images, and anything else you upload remain yours. We claim no ownership.

**The license you give us.** You grant us a non-exclusive, worldwide, royalty-free license to host, store, copy, reformat, and display your content **solely to operate the service for you** — which means displaying it to you, to Bandmates you have invited to a live gig, and to no one else. This license exists so we can run servers; it ends when you delete the content or close your account, subject to reasonable backup retention.

**What the audience sees.** The Crowd Page displays only song titles, artist names, the Performer's display name, and the queue. **Charts, keys, capo notes, and the notes people submit with a request are never displayed to Audience Members.** How chart files themselves are stored and who could reach one directly is described in our Privacy Policy.

**Your warranties about content.** By uploading content you represent that you have the right to do so, and that hosting and displaying it as described will not infringe anyone's copyright or other rights. You may not:

- upload charts you obtained in violation of another service's terms, including charts you are licensed to print for personal use but not to redistribute;
- use the service to build a shared or pooled chart library that other Performers draw from;
- distribute charts to Audience Members or to anyone who is not a Bandmate on a live gig with you.

**We may remove content** that we reasonably believe violates these Terms or the law. Where practical we'll tell you why.

## 11. Copyright, DMCA, and performance licensing

### 11.1 Takedown

We respect copyright and we terminate the accounts of repeat infringers.

To report infringing material, send a notice with the elements required by 17 U.S.C. §512(c)(3) to our designated agent:

**[DMCA AGENT NAME]**
[MAILING ADDRESS]
[DMCA EMAIL]

We will remove or disable access to the material and notify the Performer, who may submit a counter-notice.

### 11.2 Performance licensing is not ours and is not yours to assume

Public performance of copyrighted songs generally requires a license from a performing-rights organization (ASCAP, BMI, SESAC, GMR, or their equivalents outside the U.S.). In most live-music settings that license is held by the venue.

**We neither provide, verify, nor arrange any performance license.** The Performer is solely responsible for ensuring that their performance — including any song played in response to a Request — is lawful, licensed where required, and permitted by the venue.

## 12. Acceptable use

Don't:

- use the service for anything illegal, or to facilitate a transaction that isn't a genuine Tip;
- launder money, test stolen cards, or self-tip to manipulate metrics or affiliate commissions;
- harass anyone, or submit notes intended to threaten, defame, or abuse;
- attempt to access another Performer's account, charts, gigs, or reporting;
- scrape, probe, load-test, or reverse-engineer the service, or circumvent rate limits, access controls, or fee logic;
- resell or white-label the service without a written agreement with us.

Performers are responsible for moderating notes shown on their own devices and may decline any Request for any reason.

## 13. Bandmates

**There is one kind of account, and it's free.** "Bandmate" describes a role someone is playing at a particular gig, not a lesser tier of account. Every account can run its own gigs, keep its own catalog, and connect its own payout account — and any account can also join someone else's gig as a Bandmate.

A Performer may invite Bandmates to a live gig with a gig code. A Bandmate sees the same setlist and charts on their own device, and cannot access the inviting Performer's request queue, reporting, catalog, or payouts.

Bandmate access is per-gig and ends when the gig ends. A Performer may remove a Bandmate at any time.

**Tips for a gig go to the Performer who created it.** A Bandmate joining a gig receives nothing through the service for that gig, and does not need a payout account in order to join. Whatever a Bandmate is owed for playing the show is between them and the Performer, and we're not part of it. A Bandmate who wants to collect tips at their own gigs connects their own payout account and runs their own.

A Performer is responsible for who they invite, and by inviting a Bandmate confirms they have the right to let that person view the charts in question.

## 14. Promotional and referral codes

We may issue codes that waive or reduce the Platform Fee, or that credit a referring party with a commission. Codes are ours to issue, modify, deactivate, and expire. A code may be limited in number of uses and in duration.

Referral commissions are calculated as a share of **our Platform Fee**, not of the Performer's Tips, and apply only to activity occurring after the referral is attributed. We do not backdate attribution.

We may withhold or claw back a commission we reasonably believe arises from self-referral, fake accounts, or other abuse.

## 15. Third-party services

The service depends on third parties including Stripe (payments), and our hosting, database, storage, and email providers. Their outages are our outages. We are not responsible for the acts or omissions of third-party services, and your use of Stripe is governed by your agreement with Stripe.

## 16. Availability, and the gig-night reality

We aim to keep the service running and we use it at our own gigs. But:

**We do not guarantee uptime.** The service depends on your internet connection, the venue's network, your device, and our providers. It can be unavailable at exactly the wrong moment.

**Have a backup.** Don't make Bribe The Band the only way you can read your charts at a gig you're being paid to play. We recommend keeping an offline or printed copy of anything you can't perform without.

We may change, suspend, or discontinue features. For a change that materially reduces functionality Performers rely on, we'll give reasonable notice where we can.

## 17. Beta and early-stage features

Some features are new and may be labeled beta, preview, or early access. They may change or disappear. Use your judgment before relying on one during a paid performance.

## 18. Suspension, termination, and getting your data out

**You may close your account at any time** from your console or by emailing [SUPPORT EMAIL].

**We may suspend or terminate an account** that violates these Terms, that creates legal or financial risk for us, or that Stripe has restricted. Except where immediate action is needed, we'll give notice and an opportunity to fix the problem.

**On termination:** your Crowd Page goes offline, pending Stripe payouts continue on Stripe's schedule, and you may request an export of your song catalog, setlists, request history, and uploaded Charts. **We will keep your data available for export for at least 30 days after termination**, unless we're required to delete it sooner. After that we may delete it.

Sections 6.3, 8, 9, 10 (warranties), 19, 20, 21, and 23 survive termination.

## 19. Disclaimers

THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE." TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT.

We do not warrant that the service will be uninterrupted, error-free, or secure; that Charts will load at any given moment; that Tips will reach any particular level; or that data will never be lost.

Some jurisdictions don't allow certain disclaimers, in which case they apply to you only to the extent permitted.

## 20. Limitation of liability

TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE WILL NOT BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES, OR FOR LOST PROFITS, LOST TIPS, LOST GIGS, LOST DATA, OR REPUTATIONAL HARM, EVEN IF ADVISED OF THE POSSIBILITY.

**OUR TOTAL LIABILITY** ARISING OUT OF OR RELATING TO THE SERVICE WILL NOT EXCEED THE GREATER OF (A) THE TOTAL PLATFORM FEES WE ACTUALLY COLLECTED FROM YOU IN THE **SIX MONTHS** BEFORE THE EVENT GIVING RISE TO THE CLAIM, OR (B) **$100**.

These limits apply regardless of the theory of liability and even if a limited remedy fails of its essential purpose.

## 21. Indemnification

You will defend, indemnify, and hold us harmless from any claim, loss, liability, or expense (including reasonable attorneys' fees) arising out of: your content; your performances; your relationship with a venue, a band, or an audience; your breach of these Terms; your violation of any law or third-party right; taxes you owe; and chargebacks on Tips paid to you.

## 22. Changes to these Terms

We may update these Terms. For material changes affecting Performers we'll give at least **30 days' notice** by email and on the site. Continuing to use the service after the effective date means you accept the change. The current version is always at [TERMS URL], with the effective date at the top.

## 23. Governing law and disputes

These Terms are governed by the laws of the State of Colorado, without regard to conflict-of-laws rules.

**First, talk to us.** Before filing anything, email [LEGAL EMAIL] with a description of the problem. Most things get solved this way, and we'd rather solve them.

[**ATTORNEY DECISION POINT:** choose one — (a) exclusive jurisdiction in the state and federal courts of Denver County, Colorado; or (b) binding individual arbitration with a small-claims carve-out and a class-action waiver. Option (b) is standard for consumer platforms but carries its own cost and enforceability considerations, particularly as to Audience Members who are not account holders. Do not publish without deciding.]

## 24. General

**Entire agreement.** These Terms, the Privacy Policy, and the Refund & Request Policy are the whole agreement between us on this subject.

**Severability.** If a provision is unenforceable, the rest stays in force.

**No waiver.** Not enforcing something once doesn't waive it.

**Assignment.** You may not assign these Terms without our consent. We may assign them in connection with a merger, acquisition, or sale of assets.

**No agency.** Nothing here creates a partnership, employment, or agency relationship between us and any Performer, Bandmate, or Audience Member.

## 25. Contact

[ENTITY]
[MAILING ADDRESS]
[SUPPORT EMAIL]

---

## Implementation notes (delete before publishing)

- **Acceptance must be affirmative at signup.** Add an unchecked checkbox to `signup.html`: *"I agree to the Terms of Service and Privacy Policy"* with both linked. Store the acceptance timestamp and the version accepted on the `performers` row — a `terms_accepted_at` and `terms_version` column. Implied acceptance via a footer link is weak evidence.
- **Publish at a stable URL** (`/terms`) and keep dated prior versions accessible.
- **Cross-check Section 6.2 against `performers.fee_percentage`** if the shipped default ever changes from 10.
- **Section 8's recoupment right needs a mechanism to match it** — today there is no code path that deducts a chargeback from future tips. Until there is, the clause is a right you'd have to exercise manually by invoice.
- **Section 18's 30-day export window needs an export feature.** It's listed in the audit doc as Tier 3 item 17; until it exists, honoring this clause means a manual database dump.
- ~~Confirm Bandmate accounts are and will stay free~~ — **Resolved 2026-09-13.** All accounts are free; "Bandmate" is a per-gig role, not an account type, matching `01-ARCHITECTURE-AND-DATA-MODEL.md`'s Master/Follower design. Section 13 rewritten accordingly. **`05-SIGNUP-SCOPE.md`'s device-count pricing tiers (Tier A/B/C, $9–$19/month) are stale and should be struck from that doc** so a future session doesn't resurrect them — monetization is the tip percentage, full stop.
- **Section 6.5's 30-day fee-change notice is the binding constraint on ever changing the 10%.** If the fee number is still genuinely unsettled (project notes carry a 6–8% recommendation), settle it *before* publishing, because publishing starts the clock on every subsequent change.
