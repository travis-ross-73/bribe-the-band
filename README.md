# Bribe The Band

The crowd-facing request page for live gigs. Audience members browse the
performer's song list and submit a request with an optional tip.

## Status: V1, no real payments yet

Tip amounts are just recorded in the database for now — no Stripe integration
is wired up. This lets requests be tested freely without charging a real card.
Real payments will be added later, deliberately, once the rest of the flow is
working.

## How it works

- Reads songs from Supabase (`songs` table), scoped to whichever gig session
  is active for the URL's `?gig=` code (e.g. `bribetheband.live/?gig=TR482`).
- Submits requests into the `requests` table — no login needed, this page is
  fully public/anonymous, matching the "no accounts for the crowd" design.
- No backend/build step: this is a single static `index.html` using the
  Supabase JS client loaded from a CDN. Deploys to Vercel as a static site,
  no framework config needed.

## Testing locally

There's a test gig session seeded with code `TEST1` (see
`test-gig-session.sql` in the project's Supabase setup docs) — visiting the
page with no `?gig=` parameter at all defaults to `TEST1` for convenience
while testing.

## Architecture

Full data model and decisions are tracked in the "Song Request and Tip App"
Claude Project, not duplicated here.
<!-- staging branch tracking verified 2026-08-25T23:34:52Z -->
