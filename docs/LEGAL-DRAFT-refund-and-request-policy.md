# Refund & Request Policy — DRAFT

> **⚠️ DRAFT FOR ATTORNEY REVIEW — DO NOT PUBLISH AS-IS.**
> Written by an AI assistant, not a lawyer.
>
> **This is the single most load-bearing document of the three.** A published, plainly-worded refund policy shown *at the moment of payment* is the standard defense when a cardholder disputes a charge. Absent one, the issuer generally sides with the cardholder — and under the current Connect setup, Bribe The Band is merchant of record and eats the loss plus a dispute fee.
>
> **Placeholders:** `[ENTITY]`, `[SUPPORT EMAIL]`, `[EFFECTIVE DATE]`, `[STATEMENT DESCRIPTOR]`.
>
> **Note:** the policy below is written for a **no-refunds-by-default** posture with narrow discretionary exceptions. `09-CONNECT-EXPRESS-SCOPE.md` deliberately deferred building refund mechanics. If a refund button gets built, Section 4 gets easier and stronger, not harder — see the implementation notes.

---

**Bribe The Band — Refund & Request Policy**

Effective [EFFECTIVE DATE]

This policy is part of our Terms of Service. It explains what a tip buys, what it doesn't, and when money comes back.

## 1. What a tip is

**A tip is a gift to the performer. It is not a purchase of a performance.**

When you pick a song and add a tip, you're telling the performer what you'd like to hear and thanking them for the night. You're not buying a guaranteed slot in the set, and the performer isn't entering a contract with you.

The same is true of a Boost. Adding money to a song already in the queue moves it up the list the crowd sees. It doesn't make playing it mandatory.

## 2. Requests are not guaranteed

**The performer decides what to play.** They may decline any request, play it later, play it differently than you expected, or not get to it at all. Common and entirely ordinary reasons include:

- The set filled up before they reached your song
- The song was just played and is on a cooldown
- The night ended, or the venue called time
- The room isn't right for it
- A bandmate isn't set up for it
- They simply chose something else

None of these is a failure of the service, and none of them entitles you to money back.

## 3. Tips are non-refundable

**Tips submitted through Bribe The Band are final and non-refundable**, including where your song is declined, isn't reached, or is played in a way you didn't expect.

This is shown to you on the payment screen before you pay. By completing a tip you're confirming you understand it.

## 4. When we will look at it anyway

We're a small company run by working musicians, and we'd rather fix a genuine problem than win an argument. Contact us at [SUPPORT EMAIL] and we'll review a refund request in these circumstances:

- **A duplicate charge** — you were charged twice for the same request
- **A technical failure on our end** — you were charged but no request was ever created, or the amount charged doesn't match the amount you chose
- **A charge you didn't authorize** — someone used your card without permission
- **A clear mistake** — you meant to tip $5 and sent $500, and you tell us promptly

Outside these, refunds are at our discretion and at the performer's, and are not something you should expect.

Because tips route directly to the performer's own account, a refund in most cases requires the performer's cooperation. We'll ask. We can't always compel it.

## 5. How to ask

Email [SUPPORT EMAIL] within **30 days** of the charge with:

- The date and approximate time
- The venue or the performer's name
- The song you requested
- The amount charged
- The last four digits of the card, or the confirmation screen if you still have it

We don't collect your name or email when you tip, so these details are how we find the record. We'll respond within **5 business days**.

## 6. Please talk to us before disputing a charge

If you don't recognize a charge, it will appear on your statement as **[STATEMENT DESCRIPTOR]**.

Filing a dispute with your bank costs the performer their tip *and* a separate fee charged by the payment processor — so a $10 dispute can take $25 out of a working musician's pocket. If something went wrong, email us first. We're faster than a bank dispute and we'd like the chance to make it right.

## 7. Performers: what this means for you

- **You are not obligated to play any request.** Declining is normal and this policy backs you up.
- **You are responsible for chargebacks on tips paid to you**, including the processor's dispute fee, as set out in Section 8 of the Terms. We may recover those amounts from future tips or by invoicing you.
- **If you want to refund a tip** — someone's card got used by their kid, you couldn't play a song someone clearly cared about — contact us at [SUPPORT EMAIL] and we'll work out the mechanics. Be aware that the payment processor's fee on the original charge is generally not returned.
- **The best defense against disputes is the room.** Announce that requests aren't guaranteed, thank people by name where you can, and if you genuinely can't get to a song, say so from the stage.

## 8. Your legal rights

Nothing in this policy limits any right you have under applicable consumer-protection law that cannot be waived, or your rights under your card issuer's own rules.

## 9. Changes

We may update this policy. The version in effect when you tipped is the one that applies to that tip.

## 10. Contact

[ENTITY] — [SUPPORT EMAIL]

---

# Required UI microcopy

**The policy page alone is not enough.** Card-network dispute rules turn on whether the policy was disclosed *at the point of purchase*. The following strings need to ship into the product for this policy to actually protect anyone.

## A. Crowd page — on the payment screen, above the pay button

Must be visible without scrolling or tapping anything. Small text is fine; hidden behind a link is not.

> **Requests aren't guaranteed.** Your tip is a thank-you to the performer — they decide what to play and may not get to every song. Tips are final and non-refundable. Appears on your statement as [STATEMENT DESCRIPTOR]. [Full policy](/refunds)

## B. Crowd page — the Boost button confirmation

> Boosting moves this song up the list the crowd sees. It doesn't guarantee it gets played, and boosts are non-refundable.

## C. Crowd page — the optional note field placeholder

Notes are shown to the performer *and* may appear on the public request queue, so the current placeholder ("dedicate it to someone, request an occasion, whatever you'd like") invites people to write things they may not realize the room can see. Replace with:

> Add a note (optional) — the band sees this, and it may show up on the request list, so keep it friendly.

## D. Crowd page — the tip-only flow

> A tip with no song attached is just a thank-you. Non-refundable, and there's nothing to play.

## E. Crowd page — the success screen

Currently reads *"Request sent! 🎶 The band has your request — thanks for the tip!"* Add one line:

> They'll play what they can get to tonight. Questions about a charge? [SUPPORT EMAIL]

## F. Performer console — Settings → Payouts

> Tips go straight to your own Stripe account. You're responsible for chargebacks on tips paid to you, including the processor's dispute fee. See the [Refund & Request Policy](/refunds).

## G. Signup checkbox

> ☐ I agree to the [Terms of Service](/terms), [Privacy Policy](/privacy), and [Refund & Request Policy](/refunds).

Unchecked by default. Store the timestamp and version on the performer row.

---

## Implementation notes (delete before publishing)

**Sequencing.** Ship string A before publishing the policy page. A policy nobody saw at checkout does very little in a dispute; the checkout line does most of the work.

**Statement descriptor.** Set this in Stripe first, then fill it into strings A and E and Section 6. An unrecognized descriptor is the leading cause of friendly-fraud chargebacks in tipping products, and this policy references it three times.

**The refund button.** This draft is written for a world where no refund mechanism exists, which is the current state per `09-CONNECT-EXPRESS-SCOPE.md`. That's defensible, but it means every Section 4 case is handled by hand in the Stripe dashboard. Building even a minimal refund path — performer-initiated, from the Request Activity list, reversing the transfer along with the charge — would let Section 4 promise something concrete and would meaningfully reduce dispute risk. Recommend it as a fast follow, not a blocker.

**Declined requests are the real exposure.** Today a declined request keeps the tip and the tipper is told nothing. Even without a refund feature, a small product change would help a lot: when a performer declines, the crowd page could show that song as "not tonight — thanks anyway" rather than leaving it silently in limbo. Expectation management prevents more disputes than policy language does.

**The $2 preset.** At $2, roughly 28% of the tip disappears to fees, and it's the leftmost button. Separate from this policy, but it's the tip size most likely to produce a "what did I even pay for" reaction.

**Open question to resolve before publishing:** whether a performer can be *required* to cooperate with a refund. Section 4 currently says "we'll ask, we can't always compel." If the Terms' chargeback-recoupment right (Section 8) is exercisable, the practical answer is that you can make the performer whole-or-not either way — worth having the attorney align these two sections so they don't read as contradictory.
