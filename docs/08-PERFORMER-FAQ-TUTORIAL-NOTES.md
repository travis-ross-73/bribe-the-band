# Performer-Facing FAQ & Tutorial Notes (to write later)

Status: **not started — running list of what to include.** This is the customer-facing help content a performer using Bribe The Band would read — FAQ entries, in-app tutorial copy, tooltips — as distinct from `06-OWNERS-GUIDE-NOTES.md`, which is Travis's own internal "how to run the business" manual. Build this once the relevant feature actually ships; noted here as items come up so nothing gets forgotten in the meantime.

## Confirmed topics to include (added as they came up in conversation)

**Multi-set nights and the Last Call / request cutoff**
- Context: the not-yet-built "Last Call" feature (see `04-DECISIONS-AND-OPEN-QUESTIONS.md`, item 29) automatically closes new requests near the true end of the night, based on how much time is left versus how many songs are already queued up.
- Decided 2026-09-02: an optional "how many sets are you playing tonight?" input. When set to more than one, request-taking never pauses between sets — the crowd can keep requesting and tipping straight through a set break — and the hard cutoff calculation only ever fires approaching the end of the *final* set, using everything queued or requested across the whole night, not just the current set.
- Why this needs explaining to a performer: without it, someone might reasonably expect the request board to "close" at the end of set 1 and reopen for set 2, the way the cutoff would behave on a single-set night. The FAQ/tutorial needs to make clear that entering the number of sets is what tells the app "there's more time coming," so it doesn't cut requests off early.
- Likely home in the UI: a settings page (once the console's settings/UI gets a broader pass — see the standing idea of a Settings tab already noted for social links etc.), not buried in the per-gig Step-1 launch flow.

## Not yet decided
- Format: FAQ page on the marketing/landing side vs. inline tooltips in the console vs. both.
- Whether this lives as its own doc, gets folded into onboarding/signup copy, or both.

## Process note
Add to this list any time a "how do we explain this to a performer" question comes up in conversation, rather than only answering it in the moment — so nothing has to be re-explained from scratch when the real FAQ/tutorial content gets written.
