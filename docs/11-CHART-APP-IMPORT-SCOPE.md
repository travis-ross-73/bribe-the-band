# Chart-App Import & Onboarding Scope (Ultimate Guitar / Songbook Pro)

Status: **research complete, nothing built.** Written 2026-09-11. Covers what a performer can actually get out of Ultimate Guitar and Songbook Pro on an iPad and on an Android tablet, what Bribe The Band has to build to ingest it, and what the tutorials have to say. Companion to `05-SIGNUP-SCOPE.md` (this is the step immediately after account creation) and `08-PERFORMER-FAQ-TUTORIAL-NOTES.md` (where the customer-facing copy will eventually live).

---

## 0. The headline, before anything else

The two apps are not comparable problems, and treating them as a matched pair — "write a tutorial for each" — will waste effort on the wrong one.

- **Songbook Pro is a solved problem.** Its backup file is a ZIP containing one JSON document, verified by direct inspection of a real file. It yields title, artist, key, capo, tempo, duration, tags, folders, **and complete setlists with running order** — everything BTB's `songs` and `setlists` tables need, from a single tap the performer already knows how to do. This is a genuine, buildable, high-quality importer.
- **Ultimate Guitar is close to a dead end, and the tutorial's honest job is damage control.** There is no library export. The only bulk path covers tabs the performer personally *edited*, is desktop-browser-only, is unreliable on Macs, and carries nothing but artist and title. Favorites and playlists — which is what most UG users actually have — have **no export path whatsoever**. UG never stores a key field at all, so the one piece of metadata BTB's viewer most needs can never come from UG under any circumstances.

**The disagreement I'd raise once and then leave with you:** the premise that these are two tutorials of roughly equal shape doesn't hold, and building a "UG import" feature would be building on sand — UG's terms restrict content to *"personal, non-commercial use only"* and forbid providing files "to any other party," their third-party access is visibly degrading (Songbook Pro's own UG integration has broken repeatedly, and at least one UG-derived site was taken down), and the private mobile API that scrapers use is undocumented and unstable. My recommendation is to build the Songbook Pro importer properly, and give UG users a *manual* path plus a warning, not an integration. Your call — but I'd rather say it plainly now than have it surface halfway through a build.

---

## 1. Reframing what this project actually is

It's worth being precise about the direction of travel, because the research initially pointed both ways and only one is real.

BTB's viewer renders chart PDFs itself, from Wasabi, via `pdf.js`. The performer does **not** need their chart app on stage — `viewer.html` is the stage surface. So this is **not** an integration project (pushing songs into UG or Songbook Pro mid-gig). It's an **onboarding/migration project**: a new performer signs up with 200 songs already living in a chart app, and the gap between "signed up" and "can run a gig" is getting those 200 charts into BTB's song library.

That reframe matters, because a finding that would otherwise be bad news is actually irrelevant to you:

> **No mainstream chart app can display a PDF from a remote URL.** forScore, OnSong, MobileSheets, BandHelper and SetList Helper all copy the file into a local library on import. ([forScore KB](https://forscore.co/kb/category/08-working-with-scores/), [MobileSheets](https://www.zubersoft.com/mobilesheets/features/files/), [OnSong](https://onsongapp.com/docs/features/output/file-formats/))

If BTB were trying to push a requested song's chart into their app mid-set, that would be fatal. Since BTB owns the viewer, it doesn't matter. Worth noting in case the "let performers keep using their own chart app on stage" idea ever comes back — it would mean a per-song import step during a live set, which is not viable.

There is a secondary consequence of the multitasking research worth recording here: **do not design around iPad split-screen.** forScore has supported Split View since iOS 9, but no forum evidence exists of anyone performing that way, the community's own stage guidance is airplane mode + Do Not Disturb + nothing in the background ([Sweetwater's iPad optimization guide for live musicians](https://www.sweetwater.com/sweetcare/articles/ipad-optimization-guide-for-live-musicians/)), and a 12.9" screen is sized to hold exactly one chart page. The attested pattern is a second device, not a split screen — which is what BTB's Master/Follower model already assumes.

---

## 2. Ultimate Guitar — capability matrix

Sources are UG's own Intercom help center unless noted. Confidence is labelled per row.

| Capability | Verdict | Detail |
|---|---|---|
| Setlists | **Does not exist** | Only Favorites, Personal tabs, Artists, Playlists. Playlists are the nearest thing; drag-reorder works in the app. Multi-year forum requests for a setlist feature, never shipped. |
| Export whole library | **Does not exist** | No CSV, no ChordPro, no batch PDF, no ZIP. Confirmed by absence across the entire help center. |
| Export a playlist | **Does not exist** | A playlist can be *shared* as a view-only link, and UG states plainly: *"You can't add the shared playlist to your Playlists or to your account."* Five separate forum threads request print/export of playlists. |
| Bulk export of your own tabs | **Exists, narrow** | My Tabs → Edit → My Contributions → Personal tabs → **"Download all tabs."** |
| — what you get | **Confirmed, first-hand** | A ZIP named `mytabs-YYYY-MMD.zip`, containing one `.txt` per song, filename `Artist — Title.txt`. First line is `Artist — Title`. **Separator is an em dash (U+2014), not a hyphen.** No ChordPro tags, no key, no capo. (Andrew Tuline, *Converting UG to SBP*, tuline.com, 2024-06-22) |
| — scope | **Confirmed** | Tabs the performer **authored or edited only**. Favorites get you nothing. This is the single most important sentence in the whole UG tutorial. |
| — platform | **Desktop browser only; Mac unreliable** | Not present in the mobile apps. Tuline reports an associate on a Mac whose *"songs never did download."* |
| Per-song PDF, in the app | **Works, one at a time** | Open tab → More Options → **Download PDF**. Covers text/chord (community) tabs. Pro and Official tabs are website-only. Parallel help articles exist for [iOS](https://help.ultimate-guitar.com/en/articles/6744276-ios-want-to-print-your-tabs-online-what-you-need-to-know) and [Android](https://help.ultimate-guitar.com/en/articles/6744592-android-how-do-i-print-tabs-in-the-android-app). |
| — PDF layout controls | **Good, actually** | Paper size, meta info on/off, chord diagrams on/off, strumming patterns on/off, font size, one- or two-column. Two-column + font size is what makes a one-page chart feasible. |
| — **transposition is silently lost** | **Confirmed, high confidence** | Ten distinct forum threads reporting the same defect, plus two third-party PDF tools advertising "works even after transposing" as their differentiator. **A performer who transposes in UG and then downloads a PDF gets the original key.** |
| Per-song `.txt` via share sheet | **Works, one at a time** | More (⋯) → Share → Open With. OnSong documents this path and warns of a UG bug that *"strip[s] the name in the metadata section"*, causing each import to overwrite the previous one. |
| Key metadata | **Never existed** | UG's tab payload carries `artist_name`, `song_name`, `type`, `difficulty`, **`capo`**, **`tuning`** — and no key field. Transposition is a client-side offset. (Confirmed from [freetar's `ug.py`](https://github.com/kmille/freetar/blob/main/freetar/ug.py)) |
| Personal-data (GDPR) export | **Exists, not useful** | App-only, 72 hours to 30 days, and the help article never states that tabs, favorites or playlists are included. Not a migration tool. |
| Public API | **Does not exist** | Private mobile API only, signed with an MD5 of device ID + date + the literal string `"createLog()"`. Trivially reverse-engineered, and beside the point — see §6. |

**Third-party extraction tools that do work** (performer-run, in their own browser, on their own account — not something BTB operates):

- [`tanouvelle/Export-Ultimate-Guitar-Favourites`](https://github.com/tanouvelle/Export-Ultimate-Guitar-Favourites) — Tampermonkey userscript, last release April 2026, runs on the My Tabs page. Exports JSON with `artist_name`, `song`, `type`, `tab_url` **and `chord_text`** — the actual chart body — for the whole favorites library. This is the best UG extraction tool found. Favorites only; does not read playlists.
- [`ugpdfs`](https://chromewebstore.google.com/detail/ugpdfs/mijneekdgfcfdledaobadahlmiejkiaf) — Chrome extension, ~2,000 users, updated April 2026. Clean printable PDF per tab, **and it preserves transposition**, which UG's own export does not.

Both are desktop-browser-only, which sharpens the tablet-only problem below.

**Unresolved, needs ten minutes on real hardware:** whether `ultimate-guitar.com` in iPad Safari / Android Chrome serves the full desktop UI (with Download PDF and My Contributions) or a cut-down mobile site that hides them. Four research routes failed to settle it. Forum thread titles — *"Download as PDF on an iPad?"*, *"Site Unusable With Mobile Phones"* — hint at real problems. **This must be tested before the tutorial ships**, because the answer determines whether a tablet-only UG user has any path at all beyond one-song-at-a-time.

---

## 3. Songbook Pro — capability matrix

Vendor is Songbook Systems Limited, at **songbook-pro.com** (hyphenated — several unrelated apps share the name). Current versions: iOS 26.0.1, Android updated 2026-09-07, plus Windows, macOS, visionOS, Amazon Fire. One-time purchase around $6–7, **per platform** — an iPad licence does not cover an Android tablet. A separate "SongbookPro Groups" subscription (21-day trial, Band/Ensemble/Orchestra tiers, +$40/yr per 10 users) makes the app free for all group members and is the cheaper route for a mixed-device band.

Counter to the usual expectation: **Android is the better import platform, not the worse one.** Multi-file select at import is documented for Android only; camera-roll import is Android only. Windows is the odd one out.

### The finding that matters: `.sbpbackup` is a ZIP of JSON

Verified by downloading and unpacking a real backup file ([joeycortez42/worship](https://github.com/joeycortez42/worship/blob/master/SongbookPro%20Backup.sbpbackup), 98,563 bytes, 104 songs, 17 sets). Contents:

```
settings.hive       Flutter/Hive key-value store (app settings)
dataFile.hash       32 hex chars — MD5 of dataFile.txt
dataFile.txt        version line "1.0" + CRLF, then ONE line of JSON
```

Corroborated independently by [FWieP's dissection](https://www.fwiep.nl/blog/songbook-pro-backup-ontleed) and [stig's Python parser gist](https://gist.github.com/stig/302cb0e9c87dcad29f0b5e5e54f16719). Top-level keys: `songs`, `sets`, `folders`.

**Song fields relevant to BTB:** `Id`, `name` (title), `author` (artist), `subTitle`, `content` (ChordPro body with inline `[D]` chords), `key`, `KeyShift`, `Capo`, `TempoInt`, `Duration`, `_tags`, `_folders`, `type`, `SyncId`, `ModifiedDateTime`, `Deleted`.

**Key encoding — verified empirically** against the actual chords in each song's body, integers chromatic from A:

```
0=A  1=Bb  2=B  3=C  4=C#  5=D  6=Eb  7=E  8=F  9=F#  10=G  11=Ab
```

**Transposition is a render-time offset, not a rewrite.** `key` holds the original; `KeyShift` holds the offset; `content` holds the original chord spellings. Sounding key is `(key + KeyShift) mod 12`. This matters twice over: it is how BTB gets the *correct* key, and it is why a ChordPro export would hand you the pre-transposition key instead — there is no ChordPro directive for key shift. **The backup route is strictly better than the ChordPro export route for metadata fidelity.**

**Setlists come out clean.** Each set has `details` (name, date, `SyncId`) plus `contents`, where every item carries `Order` (zero-indexed running order), `SongId` (FK into `songs[].Id`), `keyOfset` *(sic)*, `Capo`, and `ItemType`. Two consequences: BTB can import a performer's saved setlists directly into the `setlists` table with correct ordering, and **a set item can override the song's library key** — so the same song can legitimately need two different keys depending on the set. That has no representation in BTB's current schema (`setlists.song_ids` is a flat text array) and would need a decision.

**Two traps to code around from day one:**

1. `Deleted` is a **tombstone flag, not a removal** — on songs, on sets, and on set items. Filter it or you will resurrect songs the performer deleted months ago.
2. `dataFile.hash` is an MD5 of the uncompressed JSON. Irrelevant for reading; **fatal if BTB ever writes a backup file** (it won't, per §6 — never write into a performer's sync folder).

### The one genuinely open question

**Are the original PDFs inside the backup?** Unresolved. The only public sample library is 100% text songs (`type: 1`), so there was nothing to observe; FWieP hit the same wall. Evidence leans toward yes — the official doc says the backup *"includes all songs, setlists and your settings"*, and the format demonstrably carries opt-in binaries (backing tracks are gated behind an explicit size toggle, with no equivalent toggle for PDFs, which is consistent with PDFs being included unconditionally). But it is inference, not evidence.

One ambiguous real-world datapoint: Tuline mentions exporting his database as *"zipped .CHO and .PDF files"*, which could mean a mixed-library export yields both — or two separate operations. His library is described elsewhere as all-ChordPro, which weakens the reading you'd want.

**This is the single highest-value thing to test, and it's a ten-minute test — see §7.** The answer forks the whole feature: if PDFs are embedded, BTB gets a complete one-file import. If not, BTB gets metadata and setlists but has to source the charts another way.

### Other Songbook Pro paths, ranked

| Path | Assessment |
|---|---|
| **`.sbpbackup`** | **Build against this.** One action (Settings → Backup & Sync → Backup Library → share/save), identical on iPad and Android, whole library including setlists. |
| **Cloud sync file** | Same format, auto-refreshed. SBP syncs to **OneDrive, Dropbox, or WebDAV** (not Google Drive — a 2020 review says otherwise; current docs don't list it). Third-party evidence names the synced artifact `sbp.sync`, also a ZIP of `dataFile.txt` + `dataFile.hash`. **Potentially the best ongoing pipeline** — performer points sync at a folder BTB can read, and BTB re-parses on a schedule with no per-export interaction. Undocumented officially; an undocumented `oneWaySync` setting exists in the app's own settings store and would be worth asking the developer about. |
| **Multi-select → ChordPro zip** | Works, and multi-song export does produce a zip. But **no "Select All" is documented** — assume 150–300 individual taps for a real library. Wrong tool. |
| **Print → Save as PDF** | Exists (Android: choose "Save as PDF" printer; iOS: pinch-zoom the preview, then share). **Treat as lossy.** The app's settings store contains `pdfQuality`, `autoCrop` and `invertPdf` keys, so this is a re-render, not a copy, and it will carry freehand annotations. |
| **SongbookPro Manager** | A local web server on the tablet (`http://192.168.x.x:8080`, in-app approval popup, not on Windows). Documents an **Upload** button and nothing in the reverse direction. LAN-only, so a hosted web app cannot reach it regardless. Do not build on it. |
| **URL scheme / API / Shortcuts** | **None found**, across official docs, three store listings, six blog posts, and all 2025–26 release notes. No developer portal. |

---

## 4. What BTB has to build

Phased, cheapest-first. Each phase is independently shippable.

### Phase 1 — Manual entry, made less painful (build regardless)

This is the floor every performer falls back to, and some of it exists already. `console.html`'s **Bulk Add from PDFs** — select many PDFs, guess title/artist from filename, editable review table, then upload — is already the right primitive and already does most of the work.

Additions worth making:

- **Accept a CSV/paste of `Title, Artist, Key`** to create catalog rows without charts. The `songs` table already permits chart-less rows as of 2026-09-10, and requesting/tipping a chart-less song already works — so a performer can be gig-ready on the crowd-facing side before a single PDF is uploaded, and fill charts in later. This is a small change with a large effect on time-to-first-gig.
- **A "missing charts" view** in Manage Songs, so the backlog is visible rather than discovered mid-set.
- **Filename-parsing improvement:** handle the `Artist — Title` em-dash convention, since that is exactly what UG's bulk export emits.

### Phase 2 — Songbook Pro backup importer (the real feature)

Accept a `.sbpbackup` upload in the console. Unzip, read `dataFile.txt` past the version line, parse the JSON, and:

- Filter every `Deleted` tombstone, at all three levels.
- Map `name` → title, `author` → artist, `(key + KeyShift) mod 12` → `song_key`, `Capo` → feed `key_with_capo`.
- Show an editable review table before committing — same pattern as Bulk Add from PDFs, same reason.
- Import `sets` → `setlists` with `Order` preserved.
- If PDFs turn out to be embedded (§7 test 1), extract and upload them to Wasabi under the existing `charts/{performer-id}/{song-id}.pdf` convention.
- If not, ingest metadata and setlists, then route the performer into Phase 1's chart-upload flow with the catalog already populated — which is a dramatically better experience than starting from nothing.

**Per-set key override (`keyOfset`) is an open schema question.** BTB's `setlists.song_ids` is a flat text array with no per-item data. Options: ignore it and take the song's library key (simplest, and probably right for v1); or extend the array to objects. Flagging, not deciding.

### Phase 3 — ChordPro → PDF rendering (the sleeper requirement)

This one didn't come from the brief and is easy to miss: **a Songbook Pro library is often entirely ChordPro text, with no PDFs in it at all.** If so, there is nothing to extract even in the best case — the performer's charts exist only as `content` strings. BTB's viewer renders PDFs, so BTB would have to **generate** the charts.

You already own most of this. The chord-chart generator (`chord_chart_lib.py`, custom ReportLab layout engine, packaged as a skill) already solves the hard part — chord-to-lyric alignment, section integrity, repeat-collapsing — and already handles UG-style input. Pointing it at ChordPro `content` strings and writing straight to Wasabi turns a dead end into the best onboarding experience in the category: *upload one backup file, get a complete BTB library with real charts.*

Layout target: US Letter or A4 portrait, margins ~0.35–0.5in, chord names 12–14pt, **one page per song wherever possible**. Current iPads are ~4:3, close to the 9×12in music-paper ratio, but [Scoring Notes advises against device-exact sizing](https://www.scoringnotes.com/opinion/preparing-music-scores-for-screens) because of fragmentation — prepare as if for print and let the reader adapt.

Two free wins while generating:

- **Embed forScore's PDF metadata standard** ([documented publicly](https://forscore.co/developers-pdf-metadata/)): `Title`, `Author` → composers, `Subject` → genres, `Keywords` → tags plus specialty keys `keysf:N` / `keymi:N` / `duration:N`. Costs nothing, and means a BTB-generated chart imported into forScore arrives fully populated. Useful the day a performer wants their charts *out* of BTB — which is a trust argument as much as a feature.
- **Emit a `.cho` alongside every `.pdf`.** ChordPro is the only text chart format multiple independent vendors read and write; it reflows and transposes where a PDF cannot. Safe interoperable directive subset: `{title}`, `{subtitle}`, `{artist}`, `{composer}`, `{copyright}`, `{key}`, `{capo}`, `{time}`, `{tempo}`, `{duration}`, `{c}`, `{soc}/{eoc}`, `{sov}/{eov}`, `{sot}/{eot}`. Avoid font/colour directives, `{define}`, `{image}`, `{columns}`.

Server-side tooling if you'd rather not extend your own: [ChordSheetJS](https://github.com/martijnversluis/ChordSheetJS) parses ChordPro **and Ultimate Guitar-format text** and transposes — but it is **GPL-2.0**, which needs checking against your licensing plans before it goes into a closed-source server. The [Perl `chordpro` reference implementation](https://github.com/ChordPro/chordpro) (Artistic 2.0, actively maintained, v6.101.0 April 2026) renders ChordPro → PDF natively via `--generate=PDF`. Your own generator is probably still the better answer, since it already handles the alignment problem these tools get wrong.

### Phase 4 — Cloud-folder sync (only if demand appears)

Performer points Songbook Pro's sync at a Dropbox/OneDrive folder, grants BTB read access, BTB re-parses `sbp.sync` on a schedule and keeps the catalog current. Genuinely attractive, and the cleanest ongoing pipeline available — but it's an OAuth integration per provider plus a scheduled job, for a problem most performers have exactly once. Defer until someone asks.

**Hard rule if it's ever built: read only, never write.** The MD5 hash, `SyncId`s, `ModifiedDateTime` and tombstone machinery mean a careless write could corrupt or resurrect records across every one of that performer's devices.

### Explicitly not building

- **Any UG integration.** No scraping, no private-API client, no hosted converter that ingests UG content. See §6.
- **Pushing charts into a chart app** during a gig. Nothing streams a PDF from a URL, so this would mean a per-song import mid-set.
- **Split-screen support.**

---

## 5. Tutorial plan

Four tutorials, not two — the platform split is real for UG and mostly irrelevant for Songbook Pro.

### A. Songbook Pro → BTB (iPad and Android, near-identical)

The good tutorial. Roughly six taps.

1. In Songbook Pro: **Settings → Backup & Sync → Backup Library.**
2. iPad: share sheet → **Save to Files.** Android: SAF picker → save (Android also offers automatic weekly local backup, so one may already exist; the docs suggest an SD card as the location).
3. In BTB console → Song Library → **Import from Songbook Pro** → upload the `.sbpbackup`.
4. Review the table — fix any titles/artists/keys that came through oddly — then commit.
5. Note what did and didn't come across (charts, depending on §7's answer; setlists; per-set key overrides).

Copy needs to say plainly: **the app is licensed per platform**, and **transposed songs import at their sounding key** (because BTB reads `KeyShift`, which a ChordPro export would silently drop).

### B. Ultimate Guitar → BTB, desktop available

Lead with the disqualifier: **this only works for tabs you personally edited and saved as Personal tabs. Favorites and playlists cannot be exported at all.**

1. Desktop browser, logged in: My Tabs → open an edited song → Edit → **My Contributions** → **Personal tabs** → **Download all tabs.**
2. You get `mytabs-YYYY-MMD.zip`, one `.txt` per song, named `Artist — Title.txt`. **Split on the em dash, not a hyphen**, or every artist with a hyphen in the name breaks.
3. **Do not transpose in UG first.** Transposition is silently discarded on export and on PDF download. Transpose afterward.
4. There is no key in the export. Expect to enter keys by hand.
5. Mac users: the download is reported to fail on at least some Macs. Try another browser; if it won't come, fall back to tutorial C.

Optional advanced section, clearly marked as third-party and performer-operated: `tanouvelle/Export-Ultimate-Guitar-Favourites` for favorites (JSON with chart text), `ugpdfs` for transposition-preserving PDFs. Framed as tools the performer runs on their own account with their own material — never as something BTB does for them.

### C. Ultimate Guitar → BTB, tablet only

The honest tutorial. Per-song, in the app: open tab → More Options → **Download PDF** (works for community text/chord tabs; Pro and Official tabs are website-only). Then upload to BTB, or batch a folder's worth through Bulk Add from PDFs.

Realistic framing: *"About a minute per song. For a 40-song set, plan an evening — or use the desktop route if you can borrow a computer."* Better to say that than let someone discover it at song twelve.

**Blocked until tested:** whether UG's mobile website exposes the desktop controls (§7, test 5). If it does, tablet users get the Phase-B path via "request desktop site" and this tutorial shrinks considerably.

### D. Starting fresh / neither app

Bulk Add from PDFs, plus the CSV/paste path from Phase 1. Worth writing because a meaningful share of gigging musicians read from plain PDFs in Files, Dropbox or GoodNotes rather than any chart app at all.

**Cross-cutting copy, in every tutorial:** one page per song; charts are private to the performer and never shown to the audience (the crowd page shows title and artist only); a song can exist in BTB without a chart and still be requested and tipped.

---

## 6. Legal and ToS guardrails

These belong in the tutorial-writing brief, because the natural thing to write is the thing not to write.

**UG's terms** ([ultimate-guitar.com/about/tos.htm](https://www.ultimate-guitar.com/about/tos.htm)), §6.2: users may *"print out text-based Tablature and/or Lyrics for your personal, non-commercial use"* but *"have no right to provide any files obtained through the Service to any other party."* §6.3 limits content to *"personal, non-commercial use only."* UG holds licences with Sony, EMI, Peermusic, Alfred, Hal Leonard, Faber and Music Sales plus a Harry Fox arrangement — those licences cover display and print *within UG* and are not transferable. UG runs an active DMCA program including account termination.

Notably, the ToS contains no explicit anti-scraping clause — which is a finding about the text, not a permission. The use restrictions bite regardless of how content was obtained.

**Underlying copyright** is also unfavourable to redistribution: tabs copied from published books infringe straightforwardly, and ear-transcribed tabs are arguably derivative works (Caldwell, *Analyzing Copyright Infringement Claims Against Guitar Tablature Websites*, Oklahoma Journal of Law & Technology).

**Tutorials must not tell people to:** scrape UG or use scrapers; bulk-export charts they didn't author into a shared library; redistribute charts to audience members (BTB's design already prevents this — the crowd page shows title and artist only); or re-host chart content as a pooled library other performers draw from.

**Safe ground:** the performer's own account and their own contributions (UG's "Download all tabs" is a first-party export of the user's own material); charts they authored, purchased or licensed; **per-performer private libraries** — which BTB's storage model already enforces via `charts/{performer-id}/`; and format conversion of content the performer already lawfully holds, which is materially different from acquiring it.

Worth noting for the tutorial's tone: musician forums show essentially no ethical hand-wringing about copying charts out of UG — the community treats it as a technical problem. So BTB would be introducing a norm its users don't currently hold, which argues for making the compliant path the easy path rather than lecturing.

**Separate and more urgent:** a published patent application, **US 2023/0297898 A1**, "System for digitally interacting with live musicians to facilitate tipping, requests, and request boosting" (Live Music Network LLC, filed May 2023, published Sept 2023), claims audience tipping plus requests from a prepopulated list where **paying more moves a request up the queue**. That reads directly onto BTB's core mechanic including boosting. Whether it granted, was abandoned, or was narrowed is unknown and is not a web-search question. **This belongs in front of counsel, and it is not related to this doc's subject — it surfaced during the competitive scan and is recorded here so it isn't lost.** ([Justia](https://patents.justia.com/patent/20230297898) · [Google Patents](https://patents.google.com/patent/US20230297898A1/en))

---

## 7. Hands-on tests still needed

None of these are answerable from the public record. Every one is short, and the first blocks the Phase 2 build.

1. **Do PDFs live inside a `.sbpbackup`?** (~10 min, blocks Phase 2 design.) On a tablet with Songbook Pro: import one PDF song into an otherwise-empty library, run Backup Library, rename the file to `.zip`, unpack. Is there a new entry beyond `settings.hive` / `dataFile.hash` / `dataFile.txt`? If not, check that song's record: what is its `type` (text songs are `1`), and does `content` now start with `JVBER` (which is `%PDF` in base64)? File size alone is diagnostic — ~500KB for one PDF proves embedding; ~5KB proves the PDF is not in the backup, which would itself be a backup-fidelity problem worth warning performers about.
2. **Does multi-select ChordPro export include PDFs?** (~5 min.) Select one PDF song and one text song, export as ChordPro, unzip. A real `.pdf` alongside the `.cho` settles the Tuline ambiguity outright.
3. **Is there a Select All in multi-select?** (~2 min.) Determines whether the per-song export route is viable at all.
4. **Is UG's "Download all tabs" Pro-gated?** (~5 min, needs a free account.) No source states either way, and the tutorial can't be written honestly without knowing.
5. **UG mobile web parity.** (~10 min, iPad + Android.) Does `ultimate-guitar.com` in a tablet browser expose Download PDF and My Contributions, or a cut-down site? Does "request desktop site" recover them? This determines whether tutorial C exists in its current miserable form or collapses into tutorial B.
6. **UG PDF content check.** (~2 min.) Does the downloaded PDF include tuning/capo when meta info is enabled, and what is the filename convention?

Tests 1–3 need a Songbook Pro licence on a tablet (~$7). Tests 4–6 need a UG account. All of it is an evening's work and it de-risks the entire scope.

---

## 8. Recommended sequencing

1. **Run tests 1–3** (Songbook Pro). Cheap, and test 1 forks the Phase 2 design.
2. **Ship Phase 1** (CSV/paste catalog import, missing-charts view, em-dash filename handling). Small, useful to every performer regardless of which app they came from, and it doesn't depend on any test outcome.
3. **Build Phase 2** (`.sbpbackup` importer), with the PDF-extraction branch written to degrade gracefully either way.
4. **Run tests 4–6** (UG) and write tutorials B and C to whatever the answers turn out to be.
5. **Phase 3** (ChordPro → PDF via the existing generator) — promote this if test 1 shows PDFs aren't in the backup, or if the first few real Songbook Pro users turn out to have text-only libraries. That single finding would make it the highest-value item on this list.
6. **Phase 4** (cloud sync) stays parked until a performer asks for it.

One small outreach item worth doing in parallel: Songbook Pro's developer takes tickets at [songbook-pro.com/helpdesk](https://songbook-pro.com/helpdesk/) (no public email, no roadmap, no bug tracker; responsiveness reports are mixed, though the ship record is good — quarterly releases and a fix for "file imports via other apps" landing within days of 26.0.0). A small, concrete ask lands far better than "please build an API." The two worth asking: *does `.sbpbackup` embed original PDF bytes, and where?* and *would you document the `type` and `ItemType` enums?*

---

## Sources

**Ultimate Guitar** — [Tab printing guide](https://help.ultimate-guitar.com/en/articles/6735529-website-tab-printing-guide-how-to-print-text-tabs-and-managing-pro-and-official-tab-printing) · [Export all personal tabs](https://help.ultimate-guitar.com/en/articles/6749152-how-can-i-export-all-my-personal-tabs-on-ultimate-guitar) · [iOS printing](https://help.ultimate-guitar.com/en/articles/6744276-ios-want-to-print-your-tabs-online-what-you-need-to-know) · [Android printing](https://help.ultimate-guitar.com/en/articles/6744592-android-how-do-i-print-tabs-in-the-android-app) · [My Tabs](https://help.ultimate-guitar.com/en/articles/6741372-mobile-how-to-work-with-my-tabs-folder-of-ultimate-guitar) · [Playlist sharing](https://help.ultimate-guitar.com/en/articles/7936952-mobile-sharing-your-musical-collection-playlist-sharing-on-the-website-and-tab-sharing-on-the-app) · [Personal data download](https://help.ultimate-guitar.com/en/articles/9357645-how-to-download-your-personal-data) · [Terms of Service](https://www.ultimate-guitar.com/about/tos.htm)

**Songbook Pro** — [Backup & Sync](https://songbook-pro.com/docs/manual/settings/backup-sync/) · [Online Sync](https://songbook-pro.com/docs/manual/online-sync/) · [Importing Songs](https://songbook-pro.com/docs/getting-started/importing-songs/) · [Adding Songs](https://songbook-pro.com/docs/manual/adding-songs/) · [Deleting and Sharing](https://songbook-pro.com/docs/getting-started/deleting-and-sharing/) · [ChordPro Syntax](https://songbook-pro.com/docs/manual/chordpro/) · [Sharing Sets](https://songbook-pro.com/docs/manual/setlists/sharing-sets/) · [Manager](https://songbook-pro.com/docs/manager/) · [Pricing](https://songbook-pro.com/pricing) · [Helpdesk](https://songbook-pro.com/helpdesk/)

**Format work** — [Real `.sbpbackup` sample](https://github.com/joeycortez42/worship/blob/master/SongbookPro%20Backup.sbpbackup) · [stig — Python parser gist](https://gist.github.com/stig/302cb0e9c87dcad29f0b5e5e54f16719) · [FWieP — Songbook Pro backup ontleed](https://www.fwiep.nl/blog/songbook-pro-backup-ontleed) · [Steve's Music Tools — SBP Database Examiner](https://stevesmusictools.com/sbp/)

**Migration accounts** — Andrew Tuline: [Converting UG to SBP](https://tuline.com/converting-ug-to-sbp/) · [Ultimate Guitar to ChordPro](https://tuline.com/ultimate-guitar-to-chordpro/) · [Backup/Restore the SBP Database](https://tuline.com/testing-backup-restore-on-sbp/) · [OnSong — Importing Ultimate Guitar content](https://onsongapp.zendesk.com/hc/en-us/articles/360051469774-Importing-Ultimate-Guitar-content-into-OnSong-from-UG-s-app)

**Tools** — [tanouvelle/Export-Ultimate-Guitar-Favourites](https://github.com/tanouvelle/Export-Ultimate-Guitar-Favourites) · [ugpdfs](https://chromewebstore.google.com/detail/ugpdfs/mijneekdgfcfdledaobadahlmiejkiaf) · [ChordSheetJS](https://github.com/martijnversluis/ChordSheetJS) · [ChordPro reference implementation](https://github.com/ChordPro/chordpro) · [freetar](https://github.com/kmille/freetar)

**Standards & practice** — [ChordPro file format spec](https://www.chordpro.org/chordpro/chordpro-file-format-specification/) · [ChordPro directives](https://www.chordpro.org/chordpro/chordpro-directives/) · [forScore PDF metadata standard](https://forscore.co/developers-pdf-metadata/) · [forScore file types](https://forscore.co/developers-file-types/) · [Scoring Notes — Preparing music scores for screens](https://www.scoringnotes.com/opinion/preparing-music-scores-for-screens) · [Sweetwater — iPad optimization for live musicians](https://www.sweetwater.com/sweetcare/articles/ipad-optimization-guide-for-live-musicians/) · [MobileSheets file support](https://www.zubersoft.com/mobilesheets/features/files/)

**Legal** — [US 2023/0297898 A1 (Justia)](https://patents.justia.com/patent/20230297898) · [Google Patents](https://patents.google.com/patent/US20230297898A1/en) · [Caldwell, OJOLT — copyright claims against tablature sites](https://digitalcommons.law.ou.edu/cgi/viewcontent.cgi?article=1045&context=okjolt)

---

## Research caveat

Reddit was inaccessible throughout this research — the domain is blocked at the fetch layer and search results were filtered — so the community-sentiment side rests on TalkBass, Gearspace, Basschat, Fractal, Loopy Pro, jazzguitar.be, app-store reviews and working-musician blogs instead. UG's own forum threads return 404 to automated fetches, so where UG forum threads are cited it is by **title only**, treated as weak corroboration of a pattern rather than as evidence. The Songbook Pro Facebook group — which is where format questions like "How to unpack SongBookPro .sbp file" actually get answered — is blocked by robots.txt and is the most likely place to find someone who has already answered test 1.
