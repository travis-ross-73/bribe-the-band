# Patent Review: US 2023/0297898 A1 vs. Bribe the Band

**Patent:** "System for Digitally Interacting with Live Musicians to Facilitate Tipping, Requests, and Request Boosting" — US Patent Application Publication No. 2023/0297898 A1, published Sept. 21, 2023. Assignee: Live Music Network, LLC (Starkville, MS). Inventors: Samuel James Miller, Logan Rex Martin. Application No. 18/200,448, filed May 22, 2023 — a continuation of application 16/674,981 (filed Nov. 5, 2019, and per the patent's own text, **abandoned**), claiming priority back to a provisional filed April 3, 2019.

**Important note up front: I'm not a lawyer, and this isn't legal advice.** Patent infringement is a legal determination that turns on formal claim construction, prosecution history, and (often) expert analysis — it's not something I can definitively settle. What follows is a plain-English comparison of what this document claims versus what the `01-ARCHITECTURE-AND-DATA-MODEL.md` project doc says you've built, so you can walk into a conversation with a patent attorney already knowing where the real questions are. Given how closely your build tracks this document's described method, I'd treat a short consult with a patent attorney as worth the cost here rather than optional.

---

## The bottom line

This is a *published patent application*, not a granted patent — and the public status signals on it are actually conflicting (more below). That matters enormously: in the U.S., you infringe an issued, enforceable patent claim. You generally cannot infringe a mere pending application. So strictly speaking, there is currently no confirmed live patent right here to be infringing.

That said, two things keep this from being a non-issue:

1. **Nobody outside a formal USPTO status check can be fully sure whether this is abandoned, still pending, or was later refiled/granted under a different number.** The sources I could check gave me contradictory answers (Justia says "pending"; Google Patents' automated legal-status flag says "abandoned"). That needs a definitive answer from USPTO Patent Center, not from patent-aggregator sites.
2. **If it's still alive and eventually grants** (or if this family gets refiled in a way that preserves the 2019 priority date), the single claim in this document maps unusually closely — limitation by limitation — onto the tip-ranked request/boost/accept system you've built. That's the part worth taking seriously regardless of what the current USPTO status turns out to be.

## What the patent actually claims

Published applications can include many claims, but this one has exactly **one** — Claim 1, a method claim, and nothing else follows it in the document. In plain terms, it describes:

A listener's phone sends a server a song request plus a dollar amount they'll pay to hear it, at a specific live performance. The listener's phone shows a payment-method screen; the server processes the payment. Once payment clears, the server tells the requesting listener's phone the request went through, and *also* broadcasts the song + dollar amount to other listeners' phones who are at the same show. The server then works out where this request ranks in the list of everyone's pending requests, based on how much money is attached to each one, and updates that ranked list. Finally, the server sends the ranked list to the artist/band's device, and the artist's device displays it so a human at the show can pick which requested song to actually play.

That's it — one claim, no dependent claims narrowing it further, which is unusual (most patents have a family of narrower dependent claims that give you room to design around the broad one; here there's nothing to fall back on except however this one claim eventually gets construed).

## Side-by-side: claim limitations vs. what you've built

| Claim 1 element (paraphrased) | What `01-ARCHITECTURE-AND-DATA-MODEL.md` describes | Read on your build? |
|---|---|---|
| Listener device sends server a request: song + live-performance ID + $ amount | Crowd page (`request.html`) submits a song request with a tip amount, tied to the active `gig_session` | Yes — functionally identical |
| Listener device automatically displays a payment-method GUI | Stripe Payment Element mounts inline on `request.html` when a paid tip is selected | Yes |
| Server receives payment-method data and processes the charge | `api/create-payment-intent.js` + Stripe webhook write the request row only after Stripe confirms `payment_intent.succeeded` | Yes |
| After payment confirms, server tells the requesting listener the request + amount went through | Success screen / countdown after submission | Yes |
| Server broadcasts the song + amount to *other* listeners' devices | The crowd page's "🔥 Requested Songs In Queue" strip, sorted by tip total, visible to every listener at the gig | Likely yes — even if the UI only shows relative order rather than a raw dollar figure, the underlying data (tip totals per song) is transmitted to other listeners' devices to build that view |
| Server determines the request's placement in a ranked list, based on $ amount vs. other requests' amounts | Tip-ranked ordering is explicit and repeated throughout: the console's request queue, the viewer's request drawer, and the crowd page's boost strip are all described as tip-amount-ordered; "boosting" a pending request is literally paying more to move it up | Yes — this is close to a direct match, including the "boosting" concept the patent names in its own title |
| Server transmits the ranked list to the artist/band's device | The Master viewer's request drawer shows pending requests, tip-ranked | Yes |
| Artist/band device displays the list for a human to select which song to actually play | Accept/Decline buttons in the drawer; accepted songs get spliced into the live set | Yes |

I'm not seeing a limitation in this claim that your build clearly *doesn't* do. That's the reason I'm flagging this rather than waving it off — most of the time a competitor's patent turns out to cover something adjacent to what you actually built; here the overlap is real.

## What actually reduces the risk right now

- **No confirmed granted patent.** Everything above only matters legally once (if) a claim like this one issues. A published application, on its own, gives its owner essentially no enforcement right against you today — no injunction, no damages claim, nothing to send a cease-and-desist over with real teeth, *unless* it's granted.
- **The parent application was abandoned once already** (stated in the document itself), and the continuation shown here may also be abandoned — Google Patents' automated status flag says "Abandoned," though I'd treat that as a signal to verify, not a confirmed fact (it's explicitly labeled an algorithmic guess, not a legal conclusion, and Justia's listing for the same application says "pending"). Two aggregator sites disagreeing is a sign the real answer needs to come from USPTO directly.
- **Only one claim, no dependent claims** is actually somewhat favorable to you if this ever gets litigated or licensed: a single broad independent claim with no narrower fallback claims is often more vulnerable to invalidity challenges (indefiniteness, obviousness, lack of written description) than a well-drafted claim family, and prior art from *before* the April 2019 priority date (busking apps, tip jars, "pay to jump the setlist queue" tools that may have predated this filing) could matter a lot here if it's ever asserted.
- **Small, obscure assignee.** "Live Music Network, LLC" doesn't show up as an active litigant or a patent-assertion entity in what I could find, and I didn't find evidence they have their own live product actively competing with you today. That doesn't eliminate risk (small entities do sell or license patents to more aggressive parties), but it's a data point.

## Recommendations

1. **Get the actual USPTO status before doing anything else.** A patent attorney (or you, directly, via USPTO Patent Center at patentcenter.uspto.gov, searching application number 18/200,448) can tell you definitively whether this is abandoned, still pending, or has since issued under a new patent number. This single fact changes everything else here — "abandoned with no live continuation" is a very different situation from "still pending and about to be examined."
2. **If it's pending or unclear, get a short freedom-to-operate opinion from a patent attorney**, using the claim comparison above as a starting point. Given how directly the single claim maps to your tip-ranked request/boost/accept flow, I wouldn't rely on my own read here as the final word — this is exactly the kind of claim-construction judgment call that benefits from someone who does this professionally, and a narrow opinion on one claim of one application is not an expensive engagement.
3. **Ask that attorney to also look at prior art from before April 3, 2019** (the priority date). If tip-to-request or pay-to-boost live music apps existed before then, that's a real avenue to invalidate this claim if it's ever asserted — independent of whether you infringe it.
4. **Don't panic-rebuild.** Even in the worst case (claim survives, patent issues, and reads on your product), the standard next step is a licensing conversation or a targeted design-around, not scrapping the app. Design-around ideas worth having your attorney evaluate (I'm listing these as discussion points for counsel, not as confirmed safe harbors): not exposing per-song aggregate tip totals to other listeners at all (rank order without amounts), or not sending the artist device an algorithmically pre-ranked list at all and instead just letting the performer sort the (unranked) pending-request list by tip themselves client-side. Whether either of those actually avoids the claim depends on how "transmitting data indicative of the amount" and "automatically determining placement" get construed, which is a legal question, not one I can settle here.
5. **Keep building.** There's no indication of an actual live product from this assignee competing with you, no evidence of a granted patent, and no cease-and-desist in hand. This is a "get a professional opinion soon, but not a reason to stop" situation as things stand.

---

### Sources
- [US20230297898A1 — Google Patents](https://patents.google.com/patent/US20230297898A1/en)
- [Application 20230297898 — Justia Patents](https://patents.justia.com/patent/20230297898)
