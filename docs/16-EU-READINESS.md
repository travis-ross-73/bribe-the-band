# EU / UK Expansion Readiness

**Rewritten 2026-09-14** after actually researching the VAT position. The earlier version of this document was written from general principles and got the emphasis wrong in two places — it treated VAT on tips as the central problem (it probably isn't a problem at all) and treated the tax cost as the main expense (it's the compliance overhead that bites). This version replaces it.

**Not legal or tax advice.** Every substantive item here needs confirming with a tax advisor who handles cross-border digital services, and the structural questions need an attorney. What this document is for is walking into those conversations knowing what to ask.

---

## The four findings that matter

1. **Tips themselves are probably outside the scope of VAT entirely**, on 30-year-old ECJ authority that is almost exactly on point.
2. **The taxable transaction is BTB's platform fee**, not the tips — a much smaller number and a much simpler question.
3. **"Under the radar" is not available.** EU payment reporting infrastructure surfaces exactly this pattern automatically, and Stripe has no discretion about it.
4. **Requiring a VAT number before Stripe connection eliminates the VAT obligation completely**, rather than reducing it. This is the recommended structure and it's cheap to build.

---

## 1. Tips are probably not a taxable supply

**Tolsma (ECJ C-16/93, 1994)** concerned a man playing a barrel organ on the public highway in the Netherlands, offering passers-by a collecting tin. The Dutch tax authority assessed VAT on his donations.

The Court held that a service is supplied "for consideration," and therefore taxable, only where there is a legal relationship between provider and recipient involving reciprocal performance — and that those conditions are **not** met by playing music in public where no remuneration is stipulated, even where the musician solicits money and receives donations, because the amounts are neither quantified nor quantifiable.

Still cited as good law in 2026 commentary. The fact pattern is a musician receiving voluntary audience payments, which is literally the product.

### The edge, and how the Terms protect it

A German fiscal court has noted that even consciously voluntary payments such as tips **do** constitute consideration where they are intrinsically linked to a service provided by the recipient. BTB tips aren't anonymous coins in a hat — a specific song is chosen and paid for. **Boost is the sharpest version**: paying extra to move a song up the queue looks like paying for a distinct, identifiable benefit.

What holds the position together is language already drafted for an unrelated reason. The Terms and Refund Policy say a tip is a gift rather than a purchase of a performance, the performer may decline any request for any reason, and no enforceable agreement exists. **That is Tolsma's test almost verbatim** — no legal relationship, no reciprocal performance.

**Implication for drafting:** never soften that language for marketing reasons. It's doing double duty as chargeback defense and as the VAT position. If a future copy revision makes requests sound guaranteed, it weakens both at once.

---

## 2. The platform fee is the taxable supply

BTB supplying software to a performer is unambiguously a service, and it's electronically supplied. The whole EU VAT question reduces to one variable:

- **Performer is VAT-registered** → B2B, place of supply is the customer's member state, **reverse charge** applies, the performer accounts for it. Non-EU supplier has no registration requirement.
- **Performer is not VAT-registered** → B2C digital service, **non-Union OSS registration**, no threshold for non-EU suppliers, quarterly filings, VAT at each customer's local rate.

So the question is never "are tips taxable." It's **"are the EU performers VAT-registered."**

### A fee charged without adding VAT is treated as VAT-inclusive

A $1.00 fee to an unregistered Irish performer is $1.00 *including* VAT at 23%, so $1.00 × 23/123 = **$0.187 remitted**, $0.813 kept. The rate varies by member state — roughly 17% in Luxembourg to 27% in Hungary — so **the same headline 10% yields an effective 16–21% depending on where the performer lives.**

Grossing up ("10% + VAT") runs into EU consumer price display rules, which generally require consumer-facing prices to be VAT-inclusive. An unregistered solo musician is a consumer. The honest headline would become "12.3% in Ireland, 11.9% in Germany, 12.7% in Hungary" — unacceptable on a pricing page whose entire purpose is stating one true number simply.

**Also: OSS is remit-only.** Input VAT can't be deducted through it; any EU VAT incurred needs a separate refund claim. Minor given US-based costs, but it means OSS is pure outflow.

---

## 3. The cost structure — the correction that reframes everything

The earlier version of this document implied VAT was the expensive part. It isn't.

VAT is a **variable** cost of roughly 1.9 points on the fee. Non-Union OSS registration, quarterly filings, and an accountant competent in cross-border digital services is a **fixed** cost in the region of $1,500–2,500/year — **identical whether there are three EU performers or three hundred.**

**The variable cost is small. The fixed cost is the whole problem, and it's worst at low volume.**

Which changes the question from "can we afford the VAT" to "**is there enough EU volume to amortize the compliance.**"

### Break-even, at real numbers

Working assumptions, confirmed 2026-09-14: **$50 average tips per gig**, **10% platform fee**, **10% affiliate commission on the fee**, **90% of the target demographic not VAT-registered**.

Per EU gig: $5.00 fee − $0.94 VAT (IE 23%, inclusive) − $0.50 commission = **$3.57 to BTB.** Effective take ≈ **7.1%** against 9% domestically with an affiliate.

| Annual compliance cost | Gigs/year to break even | Performers, at 15 gigs each |
|---|---|---|
| $1,000 | 281 | ~19 |
| $2,000 | 561 | ~37 |
| $3,000 | 842 | ~56 |

**Roughly 20–55 actively gigging EU performers covers the cost.** More achievable than earlier drafts implied. But break-even nets zero — for the EU to be worth the operational drag, compliance should sit around a quarter of EU margin, which means **on the order of 150 active performers.**

**Verdict: viable, not close, correctly sequenced behind US traction.**

**Two numbers that would move this materially:**
- **A real OSS compliance quote.** The $1,500–2,500 range is an estimate and several providers automate EU VAT filing for small sellers. At $800 the break-even drops by two-thirds. An email to two providers costs nothing and is the single highest-value action in this document.
- **Average tips per gig.** $50 comes from a small sample of Travis's own gigs, largely predating Boost and the $5/$10/$20 preset change. It's a floor. At $80/gig, the 150-performer bar falls to roughly 95.

---

## 4. There is no under-the-radar option

**CESOP**, live since 1 January 2024, requires payment service providers facilitating cross-border transactions to report quarterly transaction data, triggered where the payer is in an EU member state and the payee receives **more than 25 cross-border payments in a calendar quarter** — explicitly aimed at merchants established outside the EU. The threshold counts per payee across all payers, and once crossed, every transaction to that payee that quarter is reportable.

Applied here: **BTB is the payee.** Merchant of record, US entity, taking card payments from EU patrons. Twenty-five cross-border payments in three months is roughly three decent gigs. The threshold would be crossed almost immediately, and the data lands in a centralised system accessible to tax authorities across member states via Eurofisc.

Stripe files this. Not BTB. There is no discretion in it.

**DAC7** is the second net and genuinely needs analysis rather than assumption. Non-EU platform operators are in scope where they facilitate relevant activities by EU-resident sellers, and US platforms must register in a single member state, since the US has no equivalent-arrangement status. "Personal services" is defined broadly, and platforms that hold consideration or pay the seller are the ones pulled in.

Two arguments for being out of scope: the performance happens in a venue rather than through the platform, and if Tolsma means tips aren't consideration, it's arguable the performer isn't a "seller" receiving consideration. Sellers under 30 transactions and €2,000 in a period are excluded regardless, which covers casual performers.

**DAC7 and CESOP are unaffected by the VAT structure below.** Requiring VAT numbers solves VAT. It does not solve platform reporting. Separate workstreams.

---

## 5. Recommended structure — VAT number required before Stripe connection

> **❌ REJECTED 2026-09-14.** The affiliate's target demographic is approximately **90% not VAT-registered**. The gate only works if it captures essentially everyone — because a handful of unregistered performers still forces OSS registration, and once that fixed cost is paid the gate buys nothing but a smaller market. At 90% unregistered it is strictly worse than doing nothing.
>
> **Resulting structure: one global 10%, take everyone, register for OSS when EU volume justifies it.** The section below is retained because the mechanism is sound and would become the right answer if the demographic ever shifts — or if a future market (a professional-band segment, a different affiliate) turns out to be mostly registered.
>
> **The alternative that survives 90% unregistered is the reseller model** — the affiliate, if VAT-registered, becomes the contracting party with the musicians. The supply is then B2B to a single UK business: reverse charge, no OSS, no threshold, one customer instead of hundreds. The catch is that it's a business negotiation rather than a paperwork change. Someone taking 10% as a referral fee will not take on contracting, support and tax compliance for the same 10%; a reseller wants materially more margin and would own the customer relationship. Worth a conversation, not a default.

**In the EU, a performer must supply a valid VAT number before they can connect Stripe and take tips.**

This was the recommended approach before the demographic data came in, and it remains structurally sound for a registered population.

### Why it works

**It eliminates the obligation rather than shrinking it.** If every EU performer receiving money is VAT-registered, there are zero B2C supplies and therefore **no OSS registration requirement at all.** The fixed compliance cost — the part that actually hurts — goes to zero rather than to "smaller."

**The gate already exists.** Stripe connection is already the wall between "can take money" and "can't," and bandmates already don't need Stripe. This adds a field to standing architecture rather than building new architecture.

**Pricing stays global and simple.** 10% everywhere, for everyone. No two-tier explanation, no country-by-country VAT-inclusive headline, nothing awkward for the affiliate to explain.

**No bait-and-switch.** An earlier idea — launch free in the EU, introduce the fee later — was rejected, correctly. The Terms commit to a 30-day fee-change notice, which means that plan ends in an email reading exactly like a bait-and-switch to the people you most need on your side.

**It's self-enforcing.** Under an optional-field version, an unregistered performer pays the same either way and has no reason to fill anything in. A mandatory gate has no incentive problem.

**It can't be faked.** The EU operates VIES, a free VAT number validation service. Validate at the point of connection; a verified-valid number generally protects the supplier.

**It extends to the UK unchanged.** UK B2B services follow the same place-of-supply logic, so the same mechanism covers the affiliate's home market.

### What it costs

**Addressable market, and possibly a lot of it.** Many working musicians in the EU sit below their national VAT registration threshold, and those thresholds vary widely — many stay under the small-business schemes deliberately, because it's simpler. **This is the real risk and it is not small.** A gate excluding 80% of the affiliate's network is a different proposition from one excluding 20%.

### What still needs building

- **VIES validation** at Stripe connection time for EU-country accounts. One API call.
- **Gate on Stripe account country, not IP.** The authoritative signal is the country on the connected account, available during Connect onboarding. Someone in Dublin operating a US Stripe account is a US supply; a US performer touring Europe is not an EU supply. IP geolocation gets both wrong.
- **Reverse-charge invoicing.** B2B reverse charge requires a document showing both parties' details, the customer's VAT number, the fee amount, and explicit "VAT reverse charged" wording. A monthly fee statement. Small build, but it must exist.
- **Periodic revalidation**, since a VAT number can lapse.
- **Copy explaining reverse charge**, because the mechanism is widely misunderstood: *"If you're VAT registered, enter your number. Reverse charge applies, which means you declare and reclaim it on the same return — it costs you nothing."*

### One caveat to check

Some member states exempt certain cultural and artistic services under the VAT Directive. A performer whose own output is exempt may be VAT-registered but unable to fully reclaim input VAT — which breaks the neutrality of reverse charge and makes it a genuine cost to them (small in absolute terms, roughly $0.23 on a $1.00 fee, but real). Varies by country. Worth asking the advisor, because it's the kind of detail that surprises people.

### A softer variant worth considering

The gate could apply to **tipping only**, leaving the chart viewer and setlist sync free for unregistered EU performers and bandmates. That gets the app into EU bands' hands, builds usage and feedback, and monetises only the professional entities. Whether a chart-viewer-without-tipping is a coherent product or a hollowed-out one is a product judgement, not a tax one.

---

## 6. Sequencing — launch behind US traction

**Do not launch EU alongside the US.** With one live performer and no US social proof, building EU compliance is premature optimisation of the expensive kind.

**A waitlist has no backlash**, because nobody was ever charged nothing. "We're opening to EU performers in [quarter] — here's the list" is an ordinary thing for a young platform to say. The affiliate builds a network of interested musicians in the meantime, which is what they'd be doing during any onboarding period anyway.

Suggested order:

1. **Ask the affiliate the sizing question** (§9). Costs nothing, and the answer determines everything else.
2. Get the US product to real traction — founding cohort, testimonials, the video.
3. Confirm the structure with a tax advisor and an attorney.
4. Build the VAT gate, VIES validation, and reverse-charge invoicing.
5. Open the waitlist.

---

## 7. The commission rate is a bigger lever than the VAT rate

An earlier draft of this analysis used a **50% affiliate commission** as a hypothetical, and it did a lot of work in making the EU look unviable. That number was invented, not chosen.

On a Dublin $10 tip:

| Commission | VAT treatment | BTB keeps |
|---|---|---|
| 50% | B2C, 23% VAT | $0.31 |
| 20% | B2C, 23% VAT | $0.61 |
| 20% | **B2B reverse charge (the gate)** | **$0.80** |

Affiliate commissions in this space commonly run 20–30% of platform revenue, often limited to the first 12 months of a referred account rather than perpetual. **Decide this deliberately** — it moves EU viability more than the VAT rate does.

**VAT and commission are separate supplies running in opposite directions.** BTB's VAT base is the full fee charged, before commission. The affiliate's commission is their revenue, invoiced to BTB, reducing profit rather than the VAT base. A UK business supplying services to a US business puts place of supply at the customer — outside UK VAT — so they invoice flat with no VAT. Get an invoice for the records regardless.

*Pin down one thing: if the promo-code design reduces the performer's fee to 5% rather than paying the affiliate out of the 10%, then the supply is 5% and the VAT base is 5%. Different model, different answer. Confirm which is actually being built.*

---

## 8. Practical blockers unrelated to tax

**Does Stripe Connect even support this?** The platform account is US. Destination charges to an EU-country connected account are a cross-border arrangement with real constraints on supported countries and payout currencies. **Confirm with Stripe before any of the tax planning matters** — an expensive thing to discover at step nine.

**International card costs.** On a Dublin $10 tip, Stripe takes roughly 2.9% + $0.30, plus about 1.5% international card fee, plus about 1% if converting currency — around $0.84 total, against $0.59 domestically. **The performer nets about $8.16 versus $8.41.** Roughly 25¢ per tip more than a US performer pays. **This belongs on the EU version of the pricing page** — same honesty standard as everywhere else. Verify current surcharges against Stripe's rate card.

**Consumer refund rights** are stronger in the EU and UK, and the non-refundable posture may not survive contact unchanged. Whether a tip is a gratuity outside distance-selling rules or a purchase inside them is an attorney question, and it interacts with the Tolsma position — the same "not a purchase" framing helps in both places.

**Payout experience differs.** Onboarding, currencies, and timing vary by country. The FAQ's payout answer is written for US Stripe behaviour.

**GDPR.** Recruiting EU performers brings Art. 3(2) into play. The prerequisites — DPAs executed with all sub-processors, a transfer mechanism for EU data reaching US infrastructure, an Art. 27 EU representative plus a separate UK one, an Art. 30 record of processing, a documented DSR workflow, 72-hour breach procedure, and a position on whether the referral-attribution cookie requires consent — are gates on launch, not things to write about in advance. **Publish the short rights paragraph now; write the full section when the machinery exists.** Same principle as the chart storage claim: don't publish a claim before the thing it claims is true.

**The affiliate's own role.** Referral-by-promo-code keeps them outside the data chain. If they handle signups, hold lists, or see performer information, they become a processor or joint controller and need their own agreement. Settle before the relationship starts.

---

## 9. Questions to take into each conversation

### To the affiliate — ask first, it sizes everything

> **What proportion of your network is VAT-registered?**

If most are, the gate is a minor filter and EU launch could come sooner than this document implies. If almost none are, the fixed compliance cost is the entire story and waiting is obviously right. Nothing else can be decided without this number.

Also: what commission rate do they expect, and is it perpetual or time-limited?

### To the tax advisor

- Does Tolsma hold for tips attached to a specific song request, and does Boost change the analysis?
- Under a mandatory VAT-number gate with 100% B2B supplies, do we have **any** EU VAT registration or filing obligation?
- What invoicing is required from a US supplier for reverse-charge B2B services, and does it vary by member state?
- Do cultural-services exemptions break reverse-charge neutrality for performers in target markets?
- Does DAC7 apply to us, and if so what does compliance cost annually?
- What would non-Union OSS registration and quarterly filing cost to maintain, if ever needed?

### To the attorney

- Does the affiliate relationship put us in GDPR scope, and does UK GDPR apply separately?
- Do EU/UK consumer protection rules affect a non-refundable tip policy?
- Is the affiliate a processor, joint controller, or neither under a referral-code-only model?
- Minimum viable Art. 27 representative arrangement for both regimes?

---

## Superseded

Two ideas considered and rejected, recorded so they don't get re-proposed:

**An EU partner or EU-registered entity to access the €10,000 threshold.** Citizenship is irrelevant to VAT — establishment is what matters, and a letterbox arrangement managed from Colorado wouldn't create it. More importantly, a US person owning a foreign corporation triggers CFC status with Form 5471 obligations and penalties starting at $10,000 per form, plus current taxation of the income. The compliance cost exceeds the VAT it would avoid, permanently.

**Launching free in the EU and introducing the fee later.** Creates an unavoidable bait-and-switch email, and produces two-tier pricing that's unmarketable and guts the affiliate's incentive. The waitlist achieves the same sequencing with none of the damage.

---

## Related

- `13-SITE-AUDIT-AND-COMPLIANCE.md`, `14-EXECUTION-PLAN.md`
- `LEGAL-DRAFT-terms-of-service.md` — §6 fees, and the "tip is not a purchase" language carrying the Tolsma position
- `LEGAL-DRAFT-refund-and-request-policy.md` — same, plus the EU consumer-rights question
- `PRICING-PAGE-COPY.md` — needs an EU variant with international card costs
