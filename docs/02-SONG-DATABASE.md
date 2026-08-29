# Song Database

## Where the source material lives
Travis's chart library is in his **personal** Google Drive (owner `rossomemarketing@gmail.com`), in a folder called **"Ten Cent Prophet"**. He shared that folder with `travis@thelookout.church` (the Google account connected to Claude) so it's readable through the Drive connector without needing a second connected account.

- Folder: https://drive.google.com/drive/folders/1-PHjOxfhrGUFmxCS7xj7xJ0OUIZGnjIZ
- Contains individual chord chart documents (mostly Google Docs, some .docx), an older partial spreadsheet used as cross-reference, and a couple of subfolders (Solo, Word docs, Set Lists) that are mostly duplicates, old multi-song gig-recap PDFs, or empty.

## The song database sheet
**Solo Gig Song Database** — https://docs.google.com/spreadsheets/d/1SJ1PaDKcqHAwTvVMciMSxeGvxNJTh6HwVdVUGPmWp2c/edit

Columns: `Song Title | Artist | Key | Key with Capo`

This is now the live, reconciled 50-song sheet (the earlier "FINAL 50" staged copy was swapped in and the stale drafts deleted — see `04-DECISIONS-AND-OPEN-QUESTIONS.md`).

## Current approved list: 50 songs
This is now fully reconciled — the list below reflects every change made across recent sessions, all applied together:

- **10 songs removed** (deprioritized, not a quality/eligibility call — just not being carried forward for now, could be re-added later): Act Naturally, Run Away From It All, Can't Stop the Feeling!, Alive, Change the World, Sunday Morning, Take It Easy, Excuse Me While I Break My Own Heart Tonight, Hello Trouble, Black Eyes
- **Piano Man (Billy Joel) removed** — excluded per Travis, now actually applied to the live sheet (this had been logged as a decision in a prior session but never applied until now).
- **Jack & Diane (John Mellencamp, key A) added** — now actually applied to the live sheet (also previously logged but not applied until now).

Net: 60 approved (as of two sessions ago) → –10 deprioritized → –1 (Piano Man) → +1 (Jack & Diane) = **50 approved songs**, all reconciled in one pass.

## Songs excluded — traditionally female-lead / AJ's material
Unchanged standing rule — see prior list (Breathe, Someone Like You, Raise Your Glass, Wrecking Ball, One Hand In My Pocket, Shallow, Rich, Million Reasons, Killing Me Softly, Say Something, The First Cut Is the Deepest, Landslide, Steve McQueen, Bad Blood). Confirmed still excluded, no changes.

## Chart migration to real PDF storage — COMPLETE
**Status: all 50 approved songs have real PDFs uploaded to Wasabi (`songchart` bucket, key prefix `charts/travis-ross/`).** Travis uploaded 48 himself from local files; the last 2 — `the-scientist.pdf` (The Scientist, Coldplay) and `creep.pdf` (Creep, Radiohead) — were confirmed missing via a bucket-listing diff against the approved Song ID list, retrieved fresh from Travis's Drive (where they still existed as the original PDF chart documents, not just Google Docs), renamed to match the Song ID convention, and handed back to Travis to upload. All 50 confirmed present.

**Naming convention:** every chart's target filename is its Song ID (e.g. `wonderwall.pdf`, `jack-and-diane.pdf`) — lowercase, hyphenated. This is the same key used in Wasabi storage, at `charts/travis-ross/{song-id}.pdf` inside the **`songchart` bucket** (singular — confirmed directly by Travis). See `01-ARCHITECTURE-AND-DATA-MODEL.md` for the full storage-path rationale, INCLUDING the note that this handle-based path was later fully migrated to a performer-ID-based path — see that doc's Chart storage section.

**Note on Song ID naming — not always a literal slug of the title.** When the actual bucket listing was cross-checked against titles, 4 of the 50 filenames were shorter than a literal title-to-slug conversion would produce:
- Say (Say What You Need to Say) → `say.pdf` (not `say-say-what-you-need-to-say`)
- Good Riddance (Time of Your Life) → `good-riddance.pdf`
- I Still Haven't Found What I'm Looking For → `i-still-havent-found.pdf`
- (You Gotta) Fight for Your Right (To Party) → `fight-for-your-right.pdf`

All other 46 Song IDs are a straightforward lowercase-hyphenated version of the title. The full, verified Song ID list now lives in the Supabase `songs` table (see below) — that's the source of truth going forward, not a re-derivation from the title.

## Skipped — ideas without charts yet
Unchanged: Careless Whisper, Don't You (Forget About Me), Lithium — no chart document exists yet for these.

## This session: song data migrated into Supabase
- **All 50 songs inserted into the `songs` table** in the new Supabase project (`ykvpjeiakvgihpxektcf`, region `us-west-2`), each linked to the seeded `travis-ross` row in the `performers` table, with `chart_url` built from the verified real Wasabi filenames (see naming-convention note above).
- **Song data now has two representations**: the Google Sheet (human-editable reference/planning copy) and the Supabase `songs` table (what the actual app reads from). Future song additions/removals need to be applied to both — there's no sync between them yet.
- Full schema and setup details are in `01-ARCHITECTURE-AND-DATA-MODEL.md`.

## Next phase
Database is seeded and confirmed (50 rows in `songs`, verified against real chart URLs). Next up is building the actual crowd-facing request page against this schema — see `04-DECISIONS-AND-OPEN-QUESTIONS.md` for current status.
