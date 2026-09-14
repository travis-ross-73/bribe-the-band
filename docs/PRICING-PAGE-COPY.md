# Pricing Page — Copy

> **Status:** ready to publish as written, at the **10% fee currently shipping in production**. If the fee changes, change it here first — see the appendix, which does the math for the alternatives so the decision is a pick rather than a project.
>
> **Placeholders:** `[SUPPORT EMAIL]`, `[TERMS URL]`, `[SIGNUP URL]`.
>
> **One constraint worth knowing:** Terms §6.5 commits to 30 days' notice before a fee change. Publishing this page sets the baseline. Pick the number before it goes live, not after.

---

## Page: `/pricing`

**Meta title:** Pricing — Bribe The Band
**Meta description:** Free to sign up, free to run. We take 10% of tips, and we show you exactly what lands in your bank account.

---

### Pricing

# No plans. No monthly bill. We get paid when you do.

Every account is free and every account is the same. There's no tier that unlocks the chart viewer, no seat charge for your bass player, no per-gig fee. We take a cut of the tips that actually come in, and that's it.

---

## What it costs

**10% of each tip.** That's our whole business model.

Card processing is separate, and we'd rather you hear it from us than find it on a statement. **Stripe — the company that actually moves the money — charges about 2.9% plus 30¢ per tip, and that comes out of your side.** We don't mark it up and we never touch it. It goes straight from the tipper to Stripe.

So here's the honest arithmetic:

| Tip | Our fee | Stripe | **You get** |
|---|---|---|---|
| $2 | $0.20 | $0.36 | **$1.44** |
| $5 | $0.50 | $0.45 | **$4.06** |
| $10 | $1.00 | $0.59 | **$8.41** |
| $20 | $2.00 | $0.88 | **$17.12** |
| $50 | $5.00 | $1.75 | **$43.25** |
| $100 | $10.00 | $3.20 | **$86.80** |

*Stripe's rates are Stripe's to set and can change. Current rates at [stripe.com/pricing](https://stripe.com/pricing).*

**The pattern to notice:** that flat 30¢ hurts most on small tips. A $2 tip loses about a quarter of itself to processing before anyone's cut gets taken. A $10 tip loses about 6%. It's one of the reasons our presets start where they do.

---

## What's free

Everything else. Specifically:

- **Your account.** No trial, no expiry.
- **Every feature.** The chart viewer, Stage Mode, setlist builder, bulk import, request caps, cooldowns, Last Call, reporting. Nothing is held back behind a plan.
- **Your bandmates.** Every person on stage with you needs their own account to follow your set on their own tablet, and every one of those accounts is free. They don't need to connect a bank account, because tips from your gig go to you.
- **Unlimited songs, setlists, gigs, and charts.**
- **Your crowd page**, live between gigs so people can browse your catalog any time.

---

## What you need

**A Stripe account, before you can take real tips.** It's free, it's a few minutes of guided setup from your Settings tab, and it's how the money reaches your bank without ever sitting in ours. You'll need the same things any bank asks for: your legal name, an address, a bank account, and the last four of your SSN.

You don't need it to sign up, build your catalog, or try the crowd page. Only to take money.

---

## Where the money actually goes

Tips are not pooled. There's no balance page, no weekly settlement, no waiting on us to cut you a check. Each tip is routed to **your own Stripe account** at the moment the card is charged, and Stripe pays it out to your bank on its normal schedule — usually a couple of business days, a bit longer on your very first payout while Stripe verifies you.

If Bribe The Band disappeared tomorrow, your Stripe account and the money in it would still be yours.

---

## How we compare

We're not the cheapest and we're not pretending to be. There are tip-jar apps that take 1%, and if all you need is a QR code pointed at a payment link, one of those is a better deal than us and you should use it.

What you're paying the extra for is the part that isn't a tip jar: your charts on your tablet, the request queue and the chart viewer being the same screen, and every bandmate's device staying in sync when you accept a song. If that isn't worth 10% to you, we'd honestly rather you saved the money.

---

## Fine print, said plainly

- **A tip is a tip, not a purchase.** Your audience can request anything; you decide what to play. Requests aren't guaranteed and tips aren't refundable. We say this on the payment screen so nobody's surprised. [Full policy →]
- **Chargebacks are yours.** If someone disputes a tip with their bank, that tip comes back out — plus a dispute fee. It's rare, and it's mostly avoidable by making sure people recognize the charge. [More →]
- **Tips are income.** We don't withhold taxes. Stripe handles the tax forms and you'll find yours in your Stripe dashboard.
- **If we ever change the 10%,** you get 30 days' notice by email before it takes effect.

---

## Founding performers

We're new, and we'd rather grow with people who'll tell us what's broken than with people who found us in an ad.

**If you're one of the first performers to run real gigs on this, we'll waive our fee for a year.** You keep everything except Stripe's cut. What we want in return is honest feedback after your first three gigs, and permission to quote you if you end up liking it.

Email [SUPPORT EMAIL] with where you play and we'll set it up.

---

## Ready?

**[Create your gig page →]** ([SIGNUP URL])

Free to sign up. Free to run. 10% of tips, and now you know exactly what that means.

---
---

# APPENDIX — fee model decision (delete before publishing)

The page above is written at **10%**, which is what production ships today. Project notes carry a 6–8% recommendation anchored at 7%, so this is unresolved. Here's the math on all three viable models so it's a decision rather than an open loop.

## Model A — 10% of gross, Stripe from the performer's share *(current)*

| Tip | Performer gets | Platform nets | Total taken |
|---|---|---|---|
| $2 | $1.44 | $0.20 | 28% |
| $5 | $4.06 | $0.50 | 19% |
| $10 | $8.41 | $1.00 | 16% |
| $20 | $17.12 | $2.00 | 14% |

## Model B — 7% of gross, Stripe from the performer's share

| Tip | Performer gets | Platform nets | Total taken |
|---|---|---|---|
| $2 | $1.50 | $0.14 | 25% |
| $5 | $4.21 | $0.35 | 16% |
| $10 | $8.71 | $0.70 | 13% |
| $20 | $17.72 | $1.40 | 11% |

Costs you 30% of revenue to move the total-taken number by about three points. Weak trade on its own.

## Model C — 15% all-in, platform absorbs Stripe's fee

| Tip | Performer gets | Platform nets | Total taken |
|---|---|---|---|
| $2 | $1.70 | **−$0.06** | 15% |
| $5 | $4.25 | $0.31 | 15% |
| $10 | $8.50 | $0.91 | 15% |
| $20 | $17.00 | $1.12 | 15% |

**This is the one worth a hard look, and it's counterintuitive.**

- **The performer does better than Model A on every tip under about $14.29.** On a $10 tip they keep $8.50 instead of $8.41; on $5, $4.25 instead of $4.06. Since most bar tips are $2–$10, a "worse" headline number is actually a better deal in the range that matters.
- **It's radically easier to explain.** "You keep 85%" needs no table, no asterisk, no Stripe paragraph. The entire honesty problem this page exists to solve goes away.
- **It matches Tiplor's headline** (15%) while beating it on substance, and stops the unfavorable comparison against tip.dj's 10% from being apples-to-apples in a way that flatters them.
- **You lose money below a ~$2.48 tip.** Breakeven is where `0.15T = 0.029T + 0.30`. This model requires raising the minimum preset — $3 at the absolute floor, $5 preferably.
- **Platform revenue is lower on small tips** ($0.31 vs $0.50 on a $5) and **higher on large ones** in absolute predictability. If average tip lands near $10 you net $0.91 vs $1.00 — roughly a wash, for a much cleaner story.

## Recommendation

**Model C at 15% all-in with a $5 minimum preset**, if you're willing to move the presets. It's better for the performer where the volume actually is, it eliminates the disclosure problem entirely rather than managing it, and your own audit already flagged the $2 preset as the worst value on the crowd page.

**Model A at 10%** if you want to keep the presets as they are. It's defensible, it's shipping, and the page above tells the truth about it. Just don't pair 10% with a $2 preset indefinitely — 28% is the number a performer will screenshot.

**Model B at 7%** is hard to justify. It gives away nearly a third of your revenue without fixing the thing that actually damages trust, which is the two-fee explanation rather than the fee level.

**Whichever you pick, decide before publishing.** Terms §6.5 puts a 30-day notice period on every subsequent change, and the first cohort of performers is exactly who you'd least want to send a fee-increase email to.

## If you pick C, these change too

- Crowd page presets: `$2 / $5 / $10 / Custom` → `$5 / $10 / $20 / Custom`
- `create-payment-intent.js`: `application_fee_amount` stays computed on gross, at 15 — but Stripe's fee now comes out of the application fee, which means setting `on_behalf_of` / adjusting who bears processing costs on the destination charge. **This is a real code change, not just a number swap.** Check Stripe's docs on `payment_intent.application_fee_amount` interaction with connected-account fee liability before committing.
- `performers.fee_percentage` default changes from 10 to 15.
- Reporting's "Net payout" info-popover text — currently explains that net excludes Stripe's ~2.9%+30¢. Under Model C that sentence becomes wrong.
- Terms §6.2 and §6.3, and the worked example in §6.3.
