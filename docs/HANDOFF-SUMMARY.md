# Handoff Summary — Bribe The Band → Claude Code

Written 2026-08-25, at the point Travis switched this project from Cowork/chat into Claude Code so Claude could get direct GitHub repo access. **Updated 2026-08-27 — production (`bribetheband.live`) is now the live, real-world app**: real Stripe payments, queue boosting, post-play cooldown, and a per-gig performer display-name override are all live and have been used at a real gig with real tips and requests. **Updated 2026-09-09/10 — see "Staging vs. production" below**: a full parity port closed a sync gap that had opened up since 2026-08-27 (discovered via `git log`, not assumed), and a console UI cleanup built right after it was ported the following day — production and staging are now fully in sync, no known gaps. Also worth knowing: this doc and its siblings can go stale relative to the actual repo, and did — see the 2026-09-08 session entry in `04-DECISIONS-AND-OPEN-QUESTIONS.md` for two things that had been wrong here for weeks (SMTP, self-service signup) until directly re-verified. Read this first, then `01-ARCHITECTURE-AND-DATA-MODEL.md` and `04-DECISIONS-AND-OPEN-QUESTIONS.md` for full depth.

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

**Staging vs. production, as of 2026-09-11** — code/pages fully in sync: the **4 marketing pages** and a **favicon** (Home, How It Works, The Product, Get Started, plus the new `demo`/"Best Band Ever" performer account seeded on both environments for the "See a live crowd page" link — items 38/39) are now live on both. **One real outstanding gap, unrelated to any of today's work**: production's `songs.chart_url` column still has a `NOT NULL` constraint that "chart PDFs optional" (2026-09-10) assumed was already gone — `migration-chart-url-nullable-v1.sql` fixes it, still needs to be run on production. **Stripe Connect Express** (per-performer payouts, items 36/37) was built and confirmed on staging 2026-09-10, ported to production 2026-09-11, and Travis's real live-mode Stripe account is now fully enrolled as a Connect platform (a Stripe support ticket was needed to clear one requirement the dashboard didn't surface) — a real live-mode test confirmed the whole thing works end to end, no code changes needed. See `09-CONNECT-EXPRESS-SCOPE.md` and `04-DECISIONS-AND-OPEN-QUESTIONS.md` items 36/37. A full parity port, the console UI cleanup port that followed it, chart PDFs becoming optional when adding a song, and forgot-password/change-password (see `04-DECISIONS-AND-OPEN-QUESTIONS.md`'s 2026-09-09/10 sessions) closed out every gap this section used to track: server-side cooldown enforcement, the Follower account-growth model (since simplified to one identity mechanism), 12-hour gig auto-end, Last Call's front-end, the Follower-facing "gigs I've followed" record, custom SMTP, self-service signup, the console's info-icon/Settings-tab/CSV-export cleanup, optional chart PDFs, and password recovery/change are all live on both environments. The Redirect URLs allow-list is now configured on both Supabase projects, and a real end-to-end password reset was confirmed working on production. **Also new**: a real production login (`travis-ross-test`) now exists for Claude Code to test auth-gated actions hands-on going forward, not just via code/deployment parity — see that same session entry. Full detail across all of these: `01-ARCHITECTURE-AND-DATA-MODEL.md` and `04-DECISIONS-AND-OPEN-QUESTIONS.md`.

**What's left**: nothing urgent blocking real use — see `03-V2-BACKLOG.md` for deferred ideas and `04-DECISIONS-AND-OPEN-QUESTIONS.md`'s "Open questions" section for anything still undecided. **Travis's own standing direction as of 2026-09-08**: don't wait on Wade to test staging before continuing — he isn't available and further building shouldn't be gated on that for anything that isn't a payments/security-review item.

## One thread from last time — now resolved
Travis had mentioned waiting on "admin to re-enable access," which was never clarified in the moment. **Resolved**: this referred to Travis's own Claude subscription access, not anything in this project — a billing/credit-card issue that the org's admin fixed. Not staging-related; no longer worth tracking here.

## Docs in this folder
Originally exported from the claude.ai Project "Song Request and Tip App," then kept locally in Dropbox, then **moved into this git repo's `docs/` folder 2026-08-29** — see the note below. All 10 numbered docs plus this summary:
- `00-PROJECT-OVERVIEW.md` — original prototype-era overview (superseded in substance by `01-...`, kept for history)
- `01-ARCHITECTURE-AND-DATA-MODEL.md` — **the most important file**: full current architecture, data model, every feature built and why, Wade's security doctrine
- `02-SONG-DATABASE.md` — where Travis's chart library lives, the 50-song approved list
- `03-V2-BACKLOG.md` — deferred features, not yet prioritized
- `04-DECISIONS-AND-OPEN-QUESTIONS.md` — **second most important file**: full session-by-session history of every decision, bug found, and fix, in chronological order
- `05-SIGNUP-SCOPE.md` — self-service signup: Phase 1 (free signup) **confirmed deployed and working on both environments 2026-09-08**; billing/affiliate payouts/device enforcement still not built (see that doc for phase detail)
- `06-OWNERS-GUIDE-NOTES.md` — outline for an eventual "how Travis runs the business" ops manual (not written yet)
- `07-STAGING-ENVIRONMENT-SETUP.md` — the staging build currently in progress (see above)
- `08-PERFORMER-FAQ-TUTORIAL-NOTES.md` — running list of customer-facing FAQ/tutorial topics to write later (not started)
- `09-CONNECT-EXPRESS-SCOPE.md` — Stripe Connect Express plan (self-serve per-performer payouts, the 10% platform fee) — **built, tested, and ported to production 2026-09-11**
- `2-hour-setlist.md` — a sample setlist built from the approved song database
- `gig-request-prototype.html` — the very first single-file prototype, superseded, kept only as a UX reference

## Where these docs actually live now
**Decided 2026-08-29**: `docs/` moved into this git repo — it's the shared source of truth now, committed alongside the code, not a separate manually-synced copy in Dropbox or a claude.ai Project. `docs/` exists only on `main` (and branches cut from it) — it was never merged onto `staging`; read it via `git show main:docs/<file>` while working there. See `CLAUDE.md` for the full working rules (pull-before-editing, commit-message conventions, etc.).

**The claude.ai Project's own Knowledge tab is a separate, second copy** — what Cowork sessions read from, manually re-uploaded by Travis after a round of edits here. It only stays current when he remembers to refresh it; Claude Code has no way to write to it directly. `04-DECISIONS-AND-OPEN-QUESTIONS.md`'s 2026-08-29 entry ("Docs live in two places, on purpose") has the full reasoning for why this split is intentional rather than a bug.
