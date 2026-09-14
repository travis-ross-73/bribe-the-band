# Founding Performer Program

Specifics for the cohort, since the questionnaire was vague about scale and duration. Structured around Travis's revision: six months rather than a year, five performers, and a clear statement of what's being asked in return.

---

## The offer

**Five performers. Zero platform fee for six months.**

What they get:
- **0% BTB platform fee** for six months from their first live gig, not from signup — so someone who signs up in October and doesn't gig until November gets six months from November.
- Direct line to you for bugs and questions, rather than a support queue.
- Their feedback actually shaping what gets built, with the understanding that it's a two-way conversation and not a guarantee.

What they still pay:
- **Stripe's processing fee, roughly 2.9% + 30¢ per tip.** State this in the same breath as "zero fee," every single time. A founding performer who thinks "free" means "$10 tip, $10 in my account" and then sees $9.41 has had exactly the trust failure this entire program exists to prevent.

After six months they move to standard terms at 10%, with 30 days' notice before it takes effect — the same notice the Terms commit to for everyone.

---

## What you're asking for

Be specific, ask up front, and put it in writing. Vague asks produce vague testimonials.

**1. Actually gig with it — at least three real shows.** This is the real requirement. A performer who signs up, pokes around, and never runs a gig gives you nothing and consumes a slot.

**2. A structured debrief after the third gig.** Twenty minutes on a call, or a written form if they'd rather. Six questions:
- What broke, or nearly did?
- What did you do on the night that the app should have done for you?
- What did your audience get confused by?
- What almost made you not sign up?
- What would make you stop using it?
- What did it actually change about the gig?

**3. A usable quote, plus name, act name, city, and a photo.** Ask for this *after* the third gig, once they have something real to say. Get explicit written permission to use it on the site and in marketing. "Great app!" is worthless — what converts is specific: *"I made $180 in tips at a Tuesday night I'd normally clear $40 at."*

**4. Bugs reported as they happen**, not saved up for the debrief. Text or email, whatever's easiest for them.

**5. Permission to name them as a founding performer.** Some will want the visibility; if anyone doesn't, honor it and count them out of the testimonial ask rather than pushing.

---

## Who to pick

**Not the first five who sign up. The first five who already have gigs booked.**

The whole value of this program is real gigs producing real evidence. A performer with four dates on the calendar is worth ten who are "planning to get back out there."

Bias toward variety, because five identical testimonials read as one:
- At least one who is not you and not in your band — a bandmate's endorsement isn't independent and readers will discount it
- A solo act and a full band
- Somebody playing a room type you don't play
- Ideally somebody who found you cold rather than through a friend

---

## Mechanics

- `performers.fee_percentage = 0` on their row. The mechanism already exists.
- **Track the end date somewhere durable.** A `fee_waiver_ends_at` column beats a calendar reminder, and it lets the console show them their own status honestly — "founding rate through March 14" is a better experience than a surprise.
- Set a reminder at five months to send the 30-day notice.
- Have them accept the same Terms as everyone else. The waiver is a pricing exception, not a different agreement.

---

## How to pitch it

Don't lead with free. Lead with early.

> I built this for my own gigs and it's been running at real shows since the summer. I'm looking for five performers to be the first people using it who aren't me. No platform fee for six months — you'd still pay Stripe's processing, around 2.9% plus 30¢, same as anyone taking cards. What I want back is that you actually gig with it three times and then tell me honestly what broke and what almost made you walk away. If you end up liking it, I'd ask to quote you.

That framing does three things: it's honest about the fee, it's specific about the ask, and it signals that you want criticism rather than praise — which is the thing that gets thoughtful people to say yes.

---

## One caution

**Don't publish testimonials before you have real ones.** The founding cohort exists precisely because fabricated or thin social proof is worse than an honest "we're new." Leave the space empty until somebody has genuinely played three gigs on it and has something specific to say.

If nobody bites in a month, that's data too — it means the pitch or the product isn't ready, and finding that out from five conversations is far cheaper than finding it out from a marketing spend.
