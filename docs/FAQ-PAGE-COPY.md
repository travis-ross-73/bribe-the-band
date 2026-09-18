# FAQ Page — Copy

> **Status: ready to publish.** All six original **[CONFIRM]** flags were verified against the code and closed 2026-09-16/17. One answer is now flagged **[BLOCKED ON TASK 1]** instead — the chart-storage paragraph, which must not claim "unguessable addresses" until the object keys are actually randomised.
>
> **Corrected along the way:** the multi-set answer described a "stop taking requests" button that does not exist in the console. Requests staying open through breaks is the deliberate design — `set_ends_at` is *when tonight's final set ends*, so Last Call is anchored to the end of the night, not to each set.
>
> **Placeholders:** `[SUPPORT EMAIL]`, `[PRICING URL]`, `[SIGNUP URL]`, `[TERMS URL]`, `[REFUNDS URL]`.
>
> **Design note:** ship this as an accordion with the question text visible and the answer collapsed, grouped under the headings below. Don't hide the questions themselves — half the value is that a skeptical performer can scan the list and see their own objection written down.

---

## Page: `/faq`

**Meta title:** Questions — Bribe The Band
**Meta description:** Wifi, hardware, fees, bandmates, charts, and what happens when a request gets declined. The things performers actually ask.

---

### Questions

# The stuff you'd want to know before betting a gig on this.

We'd rather answer the hard ones up front than have you find out at 9:40 on a Friday.

---

## At the gig

### What happens if the venue's wifi dies mid-set?

**The honest answer: right now, you need a working connection.** If it drops, you may not be able to load the next chart, and requests stop coming through until it's back. We're not going to dress that up.

What we recommend, and what we do ourselves: **run your tablet off your phone's hotspot, not the venue's wifi.** It's more reliable than almost any bar network, it's under your control, and it's what the app was built and tested on at real gigs.

**What's coming:** we're building offline chart caching — your whole setlist downloaded to the tablet when you start the set, so page turns keep working whether or not the connection does. It's the feature we want most too.

**Until then, the rule we'd give any performer: don't make this the only way you can read your charts at a paid gig.** Keep a backup. We'd rather tell you that than have you learn it the hard way.

### What device do I need?

A tablet is what this was built for — the chart viewer needs the screen size, and one iPad running charts, setlist, and the request drawer is the whole setup. That's it. No second device, no laptop, no dedicated hardware.

It runs in a browser, so it opens on a phone or a laptop too. A tablet is easier to read from mid-song, but a phone works.

### Do I need to download an app?

No, and neither does your audience. It runs in the browser. You can add it to your tablet's home screen so it opens like an app, but there's nothing to install and nothing to update.

### What about multi-set nights?

Requests stay open through your breaks — which is when people are actually on their phones — you just tell it what time the gig ends, and Last Call handles the rest.

### Can I add a song mid-show?

Yes. Search your whole catalog and drop anything into tonight's set on the fly, which is mostly what encores turn out to be.

---

## Money

### What does it actually cost?

Free to sign up, free to run, and we take 10% of tips. Card processing through Stripe is separate — roughly 2.9% plus 30¢ per tip — and comes out of your side.

On a $10 tip you receive about $8.41. The full table is on our [pricing page]([PRICING URL]), including why small tips lose proportionally more.

### When does the money hit my bank?

Stripe pays out to your bank on its normal schedule, usually a couple of business days. Your very first payout takes longer while Stripe verifies you — that's Stripe's process, not ours, and we can't speed it up.

Tips are never pooled with anyone else's and never sit in an account of ours. Each one routes to your own Stripe account the moment the card is charged.

### Do I have to set up Stripe?

To take real money, yes. It's free, takes a few minutes from your Settings tab, and needs the same things any bank asks for — legal name, address, bank account, last four of your SSN.

You can sign up, build your catalog, and look at your crowd page without it. The gate is only on receiving money.

### Do my bandmates need Stripe accounts?

No. Tips from your gig go to you. Your bandmates need free accounts to follow your set on their own tablets, and that's all — no bank details, no verification, nothing.

If a bandmate wants to collect tips at *their* own gigs, they connect their own Stripe account and run their own. Every account can do both.

### Is there a charge per band member?

No. Every account is free and identical. A five-piece costs the same as a solo act, which is zero.

### What about taxes?

Tips are income. We don't withhold anything. Stripe handles tax forms and you'll find yours in your Stripe dashboard when they're issued. We're not tax advisors — talk to someone who is.

### What if someone disputes a charge?

Rare, but it happens, usually because someone didn't recognize the charge on their statement rather than because anything went wrong.

If it does, the tip comes back out and there's a dispute fee on top, and that lands on you. The best prevention is making sure people know what they paid for: we show the statement descriptor on the payment screen, and saying "thanks" from the stage does more than you'd think. More in our [refund policy]([REFUNDS URL]).

---

## Requests and your audience

### Do I have to play what people request?

No. Never. Accept or decline anything, for any reason — the set's full, you just played it, the room's not right, you'd rather not. Declining is normal and the app is built around you deciding.

Your audience is told this before they pay: a tip is a thank-you, not a purchase, and requests aren't guaranteed.

### What if I decline a request someone tipped for?

The tip stands. That's stated plainly on the payment screen so nobody's surprised, and it's the same thing that happens when someone hands cash to a piano player who doesn't know the song.

That said — if you *want* to make something right, email us and we'll work out the mechanics.

### Can people request songs I don't know?

No, and that's the point. Your crowd page shows only the songs on tonight's setlist. Nobody can request Free Bird unless you put Free Bird on the list.

### Can people tip without requesting anything?

Yes. There's a tip-only option for someone who just wants to say thanks.

### What stops one person requesting the same song ten times?

Two things, both yours to set. A **nightly cap** limits how many times a single song can pile up. A **cooldown** stops a song being re-requested for a few minutes after you've played it. Both carry over from your last gig automatically.

When a song hits its cap, the crowd sees a friendly message rather than an error.

### Can my audience see the notes people write?

No. Notes come to you on your own device. They don't appear on the public request list, so a dedication meant for you stays between you and whoever wrote it.

### Will my crowd actually use it?

Some nights yes, some nights no. There's no app to download and no login, which removes the two biggest barriers — but a QR code on a mic stand in a loud room still needs you to point at it and say something.

What we've found: it works best when you mention it once early, once mid-set, and treat it as part of the show rather than a payment request.

### Do venues mind?

Most don't, and many don't notice. But some rooms have opinions about performers running their own tip funnel, especially if there's a house arrangement. **Ask before your first night rather than after.** Nothing about the app touches the venue's POS or requires anything from them.

---

## Songs and charts

### How long does it take to get my songs in?

Depends where they're coming from.

- **Already have PDFs** — bulk upload a whole folder at once, plus an optional CSV of titles, artists, and keys. A 50-song library is an evening at most, usually much less.
- **Coming from Ultimate Guitar** — figure about a minute per song to download each chart as a PDF, then bulk upload. A 40-song set is a real evening's work. We'd rather say that than have you discover it at song twelve.
- **Coming from OnSong or SongbookPro** — those apps keep files locally and don't offer a live export, so it's a per-song export then a bulk upload.
- **Starting from nothing** — you can add a song with just a title and artist and upload the chart whenever. Songs work fine without charts; you just don't get the swipeable viewer for them.

### Can I add a song without a chart?

Yes. Title and artist is enough. It'll show on your crowd page, be requestable, and take tips. Add the chart later or never.

### Who can see my charts?

Your audience never sees them. The crowd page shows song titles and artist names only — no keys, no capo notes, no charts.

Charts are visible to you and to any bandmates you've invited to a live gig.

Being straight with you about how they're stored: chart files sit at web addresses that aren't linked from anywhere public and aren't listed anywhere, but they're not behind a login either — anyone who gets hold of a specific file's address could open it. We're moving to expiring links. Until then, treat a chart's address the way you'd treat a "anyone with the link" share link: don't pass it around.

**[BLOCKED ON TASK 1]** *Do not publish this paragraph as "long unguessable addresses" — the performer folder is a UUID, but the filename is the song's title slug, so one leaked URL plus the public setlist yields the catalog. The wording above is accurate today. Once Task 1 randomises the object keys, "unguessable" becomes true and this can be simplified; once signed URLs ship it can be cut to one sentence.*

### What format do charts need to be?

PDF, and that's the only real rule. Multi-page charts work fine — pages flow in order within the song, and the song flows into the next one in your set order, so the whole night is one continuous stream you swipe through.

There's no page limit. File size is capped at 10MB per chart, which is generous by roughly an order of magnitude — a normal chord chart is well under 1MB. The cap exists because a huge scan is a slow scan on venue wifi, and that's a problem you'd discover mid-song.

### Can I use this for original songs?

Yes, and nothing about it is cover-specific. Your catalog is whatever you put in it.

### Does this cover my performance licensing?

No. Public performance licensing — ASCAP, BMI, SESAC — is almost always the venue's responsibility, and we neither provide nor verify it. We're a tool for requests and charts, not a licensing service.

---

## Your band

### How do bandmates join?

You share a gig code. They open it on their own tablet, log into their own free account, and they're following tonight's set. When you accept a request, it splices into their charts at the same moment it splices into yours.

### What can a bandmate see?

Tonight's setlist and the charts, on their own device. They can't see your request queue, your reporting, your catalog, or anything about your payouts.

### How long does that access last?

The gig. It ends when the gig ends, and you can remove anyone at any time from the live roster.

### Can we share one account instead?

You could, but don't — you'd be passing one tablet around or logging in on several devices at once, which is exactly the problem the sync feature exists to solve. Separate free accounts is the design.

---

## Your account

### Can I try it before committing?

Yes. Sign up free, build a setlist, and look at your own crowd page. The only thing you can't do without connecting Stripe is take real money.

### Can I get my songs and charts back out?

Yes. Email [SUPPORT EMAIL] and we'll get you your song list, setlists, request history, and every chart PDF you've uploaded. It's a manual process on our end today — you email, a person does it — so allow a couple of days.

They're your charts. We're hosting them, not holding them.

### What happens to my crowd page between gigs?

It stays live, so people can browse your catalog even when you're not playing. It shows an "offstage" state until you start a gig.

### What if you go out of business?

Your Stripe account is yours and the money in it is yours — it never routes through us. For your charts and catalog, we commit to at least 30 days to get your data out. Written into our [terms]([TERMS URL]), not just a promise on a page.

### Who's behind this?

One working musician who got tired of shouting song titles across a stage, and built this for his own gigs first. It's been running at real shows since the summer of 2026. If something's broken, you're emailing the person who wrote it.

---

## Still stuck?

Email [SUPPORT EMAIL]. A real person reads it.

**[Create your gig page →]** ([SIGNUP URL])

---
---

# Implementation notes (delete before publishing)

**The six [CONFIRM] flags — all resolved 2026-09-16/17:**

1. **Chart privacy** — ✅ answered, ⚠️ **still gated.** The bucket is public-read and confirmed *not* enumerable, but filenames are the song's title slug, so the folder UUID is unguessable and the filename isn't. The answer is reworded to say exactly that. **Do not restore the "long unguessable web addresses" phrasing until Task 1 randomises the object keys** — until then it's a stronger privacy claim than the storage supports, which is independently actionable (FTC §5 / state UDAP) in a way the storage choice itself is not.
2. **Phone/laptop support** — ✅ verified usable on a phone; now a plain statement.
3. **Chart file constraints** — ✅ resolved by building the limit: PDF, 10MB per file, unlimited pages.
4. **Data export** — ✅ manual, and now said plainly in the answer ("allow a couple of days") rather than implied.
5. **Practice-gig mode** — ✅ paragraph deleted; the feature does not exist and shouldn't be promised.
6. **Multi-set handling** — ✅ **and the drafted answer was wrong.** It described a "stop taking requests" button; there is no such control in the console. Gig controls are Start New Gig / End Gig plus Last Call, and `set_ends_at` is documented as *when tonight's final set ends* — so Last Call is anchored to the end of the night, not to each set. Requests staying open through breaks is the design, not a gap, and Travis confirmed it as the intended behaviour 2026-09-17: a pause toggle's real failure mode is forgetting to switch it back **off**, which fails silently.

**Still outstanding before this page can publish:** every `[SUPPORT EMAIL]` on it (11 across the legal drafts, item 57) and the `[PRICING URL]` / `[TERMS URL]` / `[REFUNDS URL]` cross-links, which need both the pages and the routes registered above `vercel.json`'s `/:handle` catch-all.

**Two answers that do real work and should not be softened in editing:**

- **The wifi answer.** Telling a performer to keep a backup is the single most credibility-building sentence on this page. Every working musician has been burned by a venue network, and an app that pretends otherwise reads as written by someone who's never loaded in. Leave the honesty in.
- **The Ultimate Guitar migration estimate.** "A 40-song set is a real evening's work" loses you some signups and saves you the ones who'd have churned at song twelve anyway. Your own internal scoping doc reached the same conclusion.

**Cross-links to wire up:** pricing, terms, refunds, and the demo crowd page. Fix `/demo` before linking to it from here — an FAQ that sends people to a page reading "Loading songs…" undoes the whole thing.

**SEO:** mark up as `FAQPage` structured data. These questions are close to verbatim what people search for ("song request app venue wifi," "how do musicians take tips at gigs"), and the rich result is worth having.
