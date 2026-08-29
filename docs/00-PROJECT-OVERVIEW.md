# Ten Cent Prophet — Song Request & Tipping App

## What this is
A custom web app for Travis's solo/duo gigs (performing as **Ten Cent Prophet**). Audience members browse a preset song list, request a song, and optionally tip (Venmo / card / Apple Pay). Requests join a tip-weighted queue that Travis sees live on his iPad while performing. Long-term goal: package this so other solo artists and bands can use it too.

## Core workflow being replaced
Travis currently makes his own PDF chord charts and compiles them into a songbook he reads from an iPad while playing live. This app needs to plug into that workflow, not replace it — charts/keys still matter, the iPad is still the performer's device.

## Two audiences, two views, one app
- **Audience view** — mobile-friendly page the crowd uses. Shows song title + artist only (no keys, no chart links — that's performer-only info). Tap a song → note (optional) + tip → request joins the queue.
- **Stage/iPad view** — what Travis sees while performing. Shows the live queue ranked by tip amount, song key, any note left by the requester, a link to the chart if one's attached, and setlist management (add/remove songs, set a per-song request cap for the night).

## Current status (as of this conversation)
- A working single-file HTML/JS prototype exists (built as a Claude artifact) with the full interaction flow: song browsing, tipping (simulated — no real payment processor wired up yet), tip-weighted queue, request caps with scarcity messaging, notes, artist/key/link fields, live sync between audience and stage views via shared storage.
- A **Google Sheet song database** ("Solo Gig Song Database") has been created from Travis's existing chart library in Google Drive — see `02-SONG-DATABASE.md`.
- Real payment processing (Stripe), real hosting for the audience page, and full PDF-chart integration with the iPad are **not built yet** — see `03-V2-BACKLOG.md` and `04-DECISIONS-AND-OPEN-QUESTIONS.md`.

## Productization goal
Everything is being built with Travis's personal use as the immediate target, but with an eye toward eventually supporting multiple artists (separate song libraries, separate Stripe accounts via Stripe Connect, separate gig codes/URLs per artist). Decisions should favor "works for Travis now, doesn't paint us into a corner for multi-tenant later" when there's a choice.

## Files in this project
- `00-PROJECT-OVERVIEW.md` — this file
- `01-ARCHITECTURE-AND-DATA-MODEL.md` — how the prototype works technically
- `02-SONG-DATABASE.md` — Drive folder, the song sheet, and the female-lead exclusion list
- `03-V2-BACKLOG.md` — features discussed but deliberately deferred
- `04-DECISIONS-AND-OPEN-QUESTIONS.md` — key calls made so far, and things still unresolved

## What else to add to this Project
1. **Upload the current prototype HTML file** into the project's knowledge base (ask Claude to regenerate it if it's not still in your downloads — it's called `gig-request-prototype.html`). Markdown files describe the app; the actual file is the working reference.
2. **Paste the Google Sheet link** into project knowledge or a custom instruction, since Claude can't "see" live Drive contents inside a Project the way it can via the Google Drive connector in a normal chat — the sheet itself (link in `02-SONG-DATABASE.md`) is your source of truth, and connector access still works if Drive stays connected on your account.
3. Consider a short **custom instruction** for the project, e.g.: *"This project is for the Ten Cent Prophet gig request/tipping app. Read the markdown files in knowledge before making changes. Track new decisions and deferred features in the relevant file rather than only in chat."*

## Docs live in two places, on purpose (added 2026-08-29)
These numbered docs exist both here, in Claude Project Knowledge, and at `bribe-the-band/docs/` in the GitHub repo (`travis-ross-73/bribe-the-band`). They're not automatically kept in sync — each side requires a manual step, for different reasons:

- **GitHub `docs/` is the canonical, edited copy.** Both a Claude project chat and Claude Code can read/write it directly via `git`, using a scoped personal access token Travis provides each time (not stored anywhere, by design — see the security reasoning in this project's chat history if it ever needs re-explaining). This is where real editing happens.
- **Project Knowledge is a fast local read cache for chat sessions.** Claude has no tool that can write here — only Travis can upload/replace a file through the project's UI. Reading from here is instant and free (no token needed), which is why it stays the default source for ordinary project-chat conversations rather than fetching from GitHub every time (GitHub is a private repo, so *any* read from it needs the same token a write would).
- **Practical result**: Project Knowledge can drift slightly stale if GitHub changes and the files here aren't refreshed. That's expected, not a bug — refresh it periodically (e.g., after a chunk of work in Claude Code), or ask Claude at the start of a session to `git pull` and diff against what's here if you want a guaranteed-fresh check before something important.
