# Privacy Policy — DRAFT

> **⚠️ DRAFT FOR ATTORNEY REVIEW — DO NOT PUBLISH AS-IS.**
> Written by an AI assistant, not a lawyer. A privacy policy that describes practices you don't actually follow is worse than no policy, so **every factual claim below must be verified against the real system before publishing.** Items flagged **[VERIFY]** are ones I could not confirm from the outside.
>
> **Placeholders:** `[ENTITY]`, `[MAILING ADDRESS]`, `[PRIVACY EMAIL]`, `[EFFECTIVE DATE]`.

---

**Bribe The Band — Privacy Policy**

Effective [EFFECTIVE DATE]

Bribe The Band is operated by [ENTITY] ("we," "us"). This policy explains what we collect, why, who we share it with, and what you can do about it.

Two very different groups of people use this service, and we treat them differently:

- **Performers** — musicians with accounts. We hold real account information about them.
- **Audience members** — people who scan a QR code at a show, pick a song, and maybe leave a tip. **They don't have accounts and we deliberately hold as little about them as possible.**

## 1. The short version

- We never see or store your card number. Payments are handled entirely by Stripe.
- Audience members don't need an account, and we don't ask for a name, phone number, or address to send a tip.
- Performers' chord charts are private to them and their invited bandmates. We never show charts to an audience.
- We don't sell personal information, and we don't run advertising.

## 2. Information we collect from Performers

**You give us:**

- Display name or band name
- Handle (this becomes part of your public URL and is intended to be public)
- Email address
- Password (stored only as a cryptographic hash by our authentication provider — we cannot read it)
- Optional promotional or referral code
- Your song catalog, setlists, chord chart PDFs, keys, and capo notes
- Gig settings — display name overrides, request caps, cooldowns, set end times

**Stripe gives us:** whether your payout account is connected and in good standing, and your connected-account identifier. **We do not receive or store your bank account number, tax identification number, or the identity documents you give Stripe.** Those go directly to Stripe.

**We generate:** records of your gigs, requests received, tip amounts, platform fees, and reporting totals.

**Collected automatically:** IP address, browser and device type, and log data when you use the console.

## 3. Information we collect from Audience Members

This is intentionally minimal. When someone uses a Crowd Page we collect:

- The song requested and the tip amount
- An optional note, if they write one
- A payment identifier from Stripe, so we can match a successful payment to a request
- Technical data — IP address, browser and device type, and timestamps — used for security, abuse prevention, and basic reliability

**We do not ask for, and do not store, an audience member's name, email address, phone number, or postal address.** If someone types identifying information into the optional note field, it's stored with the request as they wrote it.

**We never see card numbers.** Card and wallet details are entered directly into Stripe's payment form and transmitted to Stripe. They do not pass through our servers.

**Notes are not private.** A note you write is shown to the Performer on their own device, and may also appear alongside the song on the public request queue that everyone in the room can see on their phone. Don't put anything in a note you wouldn't want the room to read.

## 4. What's public

A Performer's Crowd Page publicly shows: the Performer's display name and handle, the song titles and artist names in tonight's set, which songs are currently in the queue, the total tip amount attached to a queued song, any note submitted with a request, and a recently-played list.

It does **not** show: chord charts, keys, capo notes, who requested what, or individual tip amounts tied to an individual person.

**How chord charts are stored.** Charts are for the Performer and any bandmates they've invited to a live gig. They are never displayed on a Crowd Page and never shown to an audience. Chart files themselves are held with our storage provider at long, randomly generated addresses that are not linked from, listed on, or discoverable through any public page — but anyone who obtains a file's exact address could open it directly. We're moving chart storage behind signed links that expire. Until that's done, treat a chart's file address the way you'd treat a share link: don't pass it around.

## 5. How we use information

- To run the service — show the right songs, route the right tip, load the right chart
- To process payments through Stripe and calculate our fee
- To send transactional email (account confirmation, password reset, and service notices)
- To provide reporting to Performers about their own gigs
- To detect and prevent fraud, abuse, and payment disputes
- To provide support when someone asks for it
- To comply with legal obligations

**We do not sell personal information. We do not share it with advertisers. We do not use it to train machine-learning models.**

## 6. Who we share it with

We use service providers who process data on our behalf:

| Provider | What it does | What it touches |
|---|---|---|
| **Stripe** | Payments, payouts, identity verification for payout accounts | Payment data, performer payout identity |
| **Supabase** | Database and authentication | Performer accounts, songs, gigs, requests |
| **Vercel** | Website and API hosting | Request logs, IP addresses |
| **Wasabi** | Chord chart file storage | Uploaded chart PDFs |
| **Resend** | Transactional email delivery | Performer email addresses |

**[VERIFY]** this list is complete and current before publishing — add any analytics, error-monitoring, or CDN provider in use, and remove anything that isn't.

We may also disclose information when required by law, to respond to a valid legal request, to enforce our Terms, to investigate fraud, or in connection with a merger or sale of assets (in which case we'll notify Performers).

## 7. Cookies and local storage

We use only what the service needs to function:

- A session token so a logged-in Performer stays logged in
- Local device storage for preferences like Stage Mode and, where applicable, cached setlist data
- A short-lived cookie to attribute a referral code when someone arrives through an affiliate link

**We do not use advertising cookies or third-party tracking pixels.** Stripe sets its own cookies as part of its payment form and fraud prevention; those are governed by Stripe's privacy policy.

**[VERIFY]** whether any analytics tool is in use. If one is added later, this section and Section 6 must be updated, and a cookie banner may become necessary depending on the tool and the audience.

## 8. How long we keep things

- **Performer account data** — for as long as the account is open, and for a reasonable period afterward for legal, tax, and accounting purposes.
- **Chord charts** — until you delete them or close your account. Deleting a song removes its chart from storage.
- **Request and tip records** — retained as financial records for at least the period required by tax and card-network rules (typically several years), because they document money that actually moved.
- **Technical logs** — a short retention window, typically under 90 days. **[VERIFY against Vercel/Supabase actual settings]**
- **Backups** — deleted data may persist in backups for a limited period before being overwritten.

## 9. Your choices and rights

**Performers** can view and edit most account information in the console, delete songs and charts, and close the account at any time. You can request an export of your data or its deletion by emailing [PRIVACY EMAIL].

**Audience members** who want a request or note removed can email [PRIVACY EMAIL] with the approximate date, venue, and song. Because we don't collect identifying information, we may need details from you to find the record — and in some cases we may not be able to locate it at all.

**Depending on where you live**, you may have the right to access, correct, delete, or port your personal information, to opt out of its sale or sharing (we do neither), and to be free from discrimination for exercising these rights. This includes residents of California under the CCPA/CPRA, Colorado under the CPA, and other U.S. states with comparable laws. To exercise a right, email [PRIVACY EMAIL]. We'll verify the request in a way proportionate to what's being asked and respond within the timeframe the applicable law requires. You may use an authorized agent.

**If you are in the EEA or UK**, you may also have rights of access, rectification, erasure, restriction, portability, and objection, and the right to complain to your supervisory authority. Where we process your information, we do so to perform our contract with you, to comply with law, or on the basis of our legitimate interest in operating and securing the service.

**[ATTORNEY DECISION POINT]:** whether to hold this policy out as GDPR-compliant at all. The service is aimed at U.S. live venues, but a Crowd Page is publicly reachable from anywhere. Options are (a) include the paragraph above as written, (b) expand into a full GDPR section with a lawful-basis table and a representative, or (c) state that the service is not directed to EEA/UK users. Option (a) is the pragmatic middle and is what's drafted.

## 10. Children

The service is not directed to children. You must be 18 or older to create an account or send a tip. We do not knowingly collect personal information from anyone under 13. If you believe we have, email [PRIVACY EMAIL] and we'll delete it.

## 11. Security

We take reasonable measures to protect information, including encryption in transit, database-level access controls that scope each Performer's data to their own account, hashed passwords, and keeping payment card data entirely out of our systems by using Stripe.

No system is perfectly secure. If we become aware of a breach affecting your personal information, we'll notify you and any regulator as required by law.

## 12. Changes to this policy

We may update this policy. The effective date at the top always reflects the current version. For material changes we'll notify Performers by email and post a notice on the site before the change takes effect.

## 13. Contact

[ENTITY]
[MAILING ADDRESS]
[PRIVACY EMAIL]

---

## Implementation notes (delete before publishing)

**Before this can be published truthfully, confirm each of these against the live system:**

1. ~~Are optional notes public?~~ **Resolved 2026-09-13** — notes are shown to the Performer *and* may appear on the public queue. Sections 3 and 4 updated. `request.html`'s note-field placeholder must be updated to match (see the Refund & Request Policy draft, microcopy C).
2. **Chart storage is public-read on Wasabi (confirmed 2026-09-13).** Section 4 is now written to describe this honestly rather than claim privacy the storage doesn't provide. Two things still need doing before it's fully accurate:
   - **Verify the bucket is not enumerable.** Run `curl https://s3.us-east-1.wasabisys.com/songchart`. If that returns an XML object listing, Section 4's "not listed on any public page" claim is false and the bucket policy must be fixed immediately.
   - **Filenames are currently guessable** (`charts/{performer-uuid}/{song-slug}.pdf`). The folder UUID is unguessable, but the slug isn't, so one leaked URL exposes a whole catalog. Section 4 says "randomly generated addresses," which is only true of the folder. Either randomize the object key (add a `chart_object_key` column) or soften that sentence.
   - Once signed URLs ship, replace the last two sentences of that paragraph with a plain statement that charts are served over expiring links.
3. **Is any analytics or error-monitoring tool running?** If yes it goes in Sections 6 and 7.
4. **Actual log retention windows** for Vercel and Supabase on the current plans.
5. **Does deleting a song actually delete the chart file from Wasabi?** The architecture doc says yes. Confirm it still does before Section 8 asserts it.

**Deployment:**

- Publish at `/privacy`, link from every page footer, and link from the signup checkbox alongside the Terms.
- Keep dated prior versions accessible.
- A CCPA "Do Not Sell or Share My Personal Information" link is not required as long as you genuinely neither sell nor share. If any advertising or analytics tool that constitutes "sharing" is added later, that link becomes mandatory.
