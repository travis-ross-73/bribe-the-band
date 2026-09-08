# Handoff Summary — Bribe The Band → Claude Code

Written 2026-08-25, at the point Travis switched this project from Cowork/chat into Claude Code so Claude could get direct GitHub repo access. **Updated 2026-08-27 — production (`bribetheband.live`) is now the live, real-world app**: real Stripe payments, queue boosting, post-play cooldown, and a per-gig performer display-name override are all live and have been used at a real gig with real tips and requests. **Updated again 2026-09-07/08 — see "Staging vs. production" below**: several features are now built and confirmed working on staging that haven't been ported to production yet, so "what's live" and "what's confirmed working somewhere" are no longer the same list. Also worth knowing: this doc and its siblings can go stale relative to the actual repo, and did — see the 2026-09-08 session entry in `04-DECISIONS-AND-OPEN-QUESTIONS.md` for two things that had been wrong here for weeks (SMTP, self-service signup) until directly re-verified. Read this first, then `01-ARCHITECTURE-AND-DATA-MODEL.md` and `04-DECISIONS-AND-OPEN-QUESTIONS.md` for full depth.

## What this project is
"Bribe The Band" (bribetheband.live) — a song-request-and-tip web app. Audience members browse a performer's song catalog, request songs with an optional tip, and the performer runs a live "console + chart viewer" during the show to accept requests and splice them into the live set. Multi-tenant: any performer can sign up and get their own hosted page. Travis Ross performs as "Ten Cent Prophet"; his own account (`travis-ross`) is the real, live account, used as the de facto testing ground throughout the build.

Stack: **Supabase** (Postgres + Auth + RLS) for the backend, **Vercel** (static hosting + serverless functions) for the app, **Wasabi** (S3-compatible) for chart PDF storage. GitHub repo: `travis-ross-73/bribe-the-band`.

Full architecture, data model, and feature history are in `docs/01-ARCHITECTURE-AND-DATA-MODEL.md` and `docs/04-DECISIONS-AND-OPEN-QUESTIONS.md` — those two are the most important files in this folder if you need deep context on how anything works or why a decision was made.

## Repo access — confirmed working
Every prior session (running in Cowork/chat, not Claude Code) hit a sandbox restriction: `git push origin main` always failed with a 403 ("not in this session's authorized repository set"). Every deliverable had to be committed locally, then handed to Travis as a downloadable file for him to manually upload via GitHub's web UI. **Confirmed 2026-08-25: Claude Code has direct push access** to `travis-ross-73/bribe-the-band` (Travis provided a GitHub fine-grained PAT scoped to this repo; verified with a real test push/delete before doing anything real). Clone the repo locally (e.g. `/Users/Rossomeness/Claude/bribe-the-band`) and work from there — don't assume a clone already exists at session start, since this is a fresh Claude Code environment each time.

## Exactly where things stand right now — production is live and in real use
`bribetheband.live` is the real, live app, confirmed working at a real Travis gig on 2026-08-27 with real crowd tips and requests. Staging (a second, fully isolated copy of the whole stack) still exists and is the standing pattern for building/testing anything new before it reaches production — see `01-ARCHITECTURE-AND-DATA-MODEL.md` and `04-DECISIONS-AND-OPEN-QUESTIONS.md` for full feature-by-feature detail; `07-STAGING-ENVIRONMENT-SETUP.md` covers the staging build itself (now historical — treat it as "how staging was built," not "what's newest").

**Environments (current):**
| | Production | Staging |
|---|---|---|
| Supabase URL | `ykvpjeiakvgihpxektcf.supabase.co` | `orwxehvthwflgoqnbafp.supabase.co` |
| Wasabi bucket | `songchart` | `songchart-staging` |
| GitHub branch | `main` | `staging` |
| Vercel project | `bribe-the-band` (`bribetheband.live`) | `bribe-the-band-staging` (`bribe-the-band-staging-three.vercel.app`) |
| Stripe | **live-mode**, verified in real use | test-mode, verified end-to-end |

**What's live in production, as of 2026-08-27**:
- Real Stripe payments (Payment Element, live keys, Apple Pay on both `bribetheband.live` and `www.bribetheband.live`) — built/verified on staging 2026-08-26, rolled out 2026-08-27.
- Queue boosting (add a tip to an already-requested song to move it up) and post-play cooldown (a song can't be re-requested for N minutes after the performer taps "Got it — play the song") — built/verified on staging, rolled out to production the same day.
- A per-gig performer display-name override, settable in the console, shown on the crowd page — defaults to the performer's account name if left blank.
- Console usability pass: clearer labeling on the two main gig-control buttons ("Step 1 — Go Live" / "Step 2 — Perform").

**Reusable pattern for porting staging → production, worth knowing before touching either branch**: never `git merge staging` into `main` — it would pull staging's Supabase project and Stripe test-mode key into production. Diff `staging` against its own pre-change state, apply that as a standalone patch onto a branch off `main`, and grep the result to confirm every environment-specific line (Supabase URL/key, Stripe publishable key) is untouched before pushing. Run any new migration against production *before* pushing the matching code.

**Staging vs. production, as of 2026-09-08** — confirmed working on staging, not yet on production (front-end code, that is — see the schema note below):
- **Server-side cap + cooldown enforcement.** Cap was already fine (`enforce_request_cap()` predates this); cooldown had no server-side check at all until now — `enforce_request_limits()`. Confirmed on staging; **migration handed to Travis to run on production 2026-09-08, not yet confirmed done.**
- **Follower account-growth model** — join a gig via link/code with your own account (distinct from the older shared-login band-sync path), visible roster + remove, auto-leave on gig end. A real bug (`join_gig_by_code()`'s ambiguous-column error) meant this silently never worked at all between shipping and being caught — fixed and confirmed with two genuinely separate accounts. Staging only.
- **12-hour gig auto-end** — confirmed correct (backdated-timestamp test, not a real 12-hour wait). Staging only. Worth knowing: it's poll-triggered (crowd page/console loading), not a background sweep — a gig nobody ever revisits again just sits `active` indefinitely rather than being cleaned up.
- **Last Call / dynamic request cutoff** — a new feature, not previously listed here: automatically slows/closes new song requests as a set runs low on time to play them, without ever blocking a boost on an already-queued song or auto-declining a late arrival. Confirmed working end-to-end on staging. **Schema (only) has been ported to production** — new columns/functions exist there and are dormant, but no production code references them yet, so nothing is user-facing. Full detail: `01-ARCHITECTURE-AND-DATA-MODEL.md`'s dedicated section.
- **Custom SMTP** (Resend) and **self-service signup** are both actually done and confirmed working on **both** environments — these aren't a staging/production gap at all; the docs had just been wrong about signup's deployment status for weeks. See the 2026-09-08 session entry in `04-DECISIONS-AND-OPEN-QUESTIONS.md`.
- Full narrative and every bug found along the way: `04-DECISIONS-AND-OPEN-QUESTIONS.md`, sessions dated 2026-09-02, 2026-09-07, and 2026-09-08.

**What's left**: nothing urgent blocking real use — see `03-V2-BACKLOG.md` for deferred ideas and `04-DECISIONS-AND-OPEN-QUESTIONS.md`'s "Open questions" section for anything still undecided. **Travis's own standing direction as of 2026-09-08**: don't wait on Wade to test staging before continuing — he isn't available and further building shouldn't be gated on that for anything that isn't a payments/security-review item.

## One thread from last time — now resolved
Travis had mentioned waiting on "admin to re-enable access," which was never clarified in the moment. **Resolved**: this referred to Travis's own Claude subscription access, not anything in this project — a billing/credit-card issue that the org's admin fixed. Not staging-related; no longer worth tracking here.

## Docs in this folder
All 10 original project docs (from the claude.ai Project "Song Request and Tip App," which Claude Code cannot see directly — see note below) plus this summary:
- `00-PROJECT-OVERVIEW.md` — original prototype-era overview (superseded in substance by `01-...`, kept for history)
- `01-ARCHITECTURE-AND-DATA-MODEL.md` — **the most important file**: full current architecture, data model, every feature built and why, Wade's security doctrine
- `02-SONG-DATABASE.md` — where Travis's chart library lives, the 50-song approved list
- `03-V2-BACKLOG.md` — deferred features, not yet prioritized
- `04-DECISIONS-AND-OPEN-QUESTIONS.md` — **second most important file**: full session-by-session history of every decision, bug found, and fix, in chronological order
- `05-SIGNUP-SCOPE.md` — self-service signup Phase 1 (built, not yet deployed)
- `06-OWNERS-GUIDE-NOTES.md` — outline for an eventual "how Travis runs the business" ops manual (not written yet)
- `07-STAGING-ENVIRONMENT-SETUP.md` — the staging build currently in progress (see above)
- `08-PERFORMER-FAQ-TUTORIAL-NOTES.md` — running list of customer-facing FAQ/tutorial topics to write later (not started)
- `2-hour-setlist.md` — a sample setlist built from the approved song database
- `gig-request-prototype.html` — the very first single-file prototype, superseded, kept only as a UX reference

## Important: these docs live in a claude.ai Project, not in this repo
Claude Code has no automatic access to the claude.ai "Song Request and Tip App" Project these came from — that's a separate system tied to chat/Cowork sessions. These files were originally a point-in-time export, living locally at `/Users/Rossomeness/Dropbox/Mac/Downloads/`.

**Decided 2026-08-26**: Travis asked Claude Code to keep updating these local files directly going forward (not paste updates back into the claude.ai Project chat) — these Dropbox files are now the source of truth for this project's history and should be referenced and kept current in every session. They are not committed into the git repo itself (no `/docs` folder there) — they stay in Dropbox, referenced by their absolute path.
