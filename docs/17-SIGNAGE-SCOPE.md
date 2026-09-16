# Signage — Printable QR Displays

Status: **Built and live on both environments, 2026-09-15.** Staging commits `4f82e72`, `66c2db1`, `0685e87`, `03e3fcc`, `0fbd169`, `3760bd0`; ported to production as `ef6b943`. A sixth tab in `console.html` ("Signage", between Reporting and Settings) that turns a performer's permanent crowd-page URL into printable pieces — posters, postcards, table tents — whose only job is getting a phone pointed at `bribetheband.live/{handle}`. Travis's ask, in his own framing: "the purpose of these displays is for the audience to be able to scan and go directly to the crowd page in order to request and tip the band — that function should inform your design and text choices." See `04-DECISIONS-AND-OPEN-QUESTIONS.md` item 53 for the build narrative, including three real bugs that only appeared under real conditions.

## Why this exists

Every performer-facing surface up to this point assumed the crowd already knew the page existed. Nothing in the app ever produced the physical object that gets someone to scan in the first place — the console showed the URL and had a Copy Link button (for shouting it from stage), and that was the whole story. A performer who wanted a table tent had to go build one in Canva by hand, re-making it from scratch for every paper size, and generate a QR code from some third-party site that may or may not still resolve in a year.

## What it produces

- **Five templates** — Marquee (Bodoni, theatrical), Ticket (stub with a dashed edge), Minimal (big code, few words), Set List (ruled, like a taped-up set list), Tip Jar (leads with the tip). Template identity lives in CSS (`.sg-tpl-*`), not in the markup, so the portrait pieces and the landscape tent panels share one slot structure and still read as the same five designs.
- **Five headline faces** — House (each template's own), Condensed (Oswald), Slab (Alfa Slab One), Marker (Permanent Marker), Grotesk (Space Grotesk). Loaded on demand, not at page load.
- **Five colour themes** — Bone, Press, Stage, Neon, Kraft. Themes are plain `rgba()`, never `color-mix()`: the PDF rasteriser doesn't understand `color-mix` and silently drops those fills.
- **Eleven sizes** — US Letter, half sheet, quarter sheet, postcard (4×6), tabloid; A3/A4/A5/A6; plus two table tents that print flat with fold lines and a tape flap and read from both sides.
- **Two live sliders** — QR size (70–165%) and text size (75–130%), independent of each other, with the code's real millimetre size reported on the slider as it moves. Re-renders land in well under a millisecond.
- **Four outputs** — a true-to-size PDF, direct browser print with a matching `@page` rule, and the bare QR as a 2000px transparent PNG or a JPG on white.

## Design decisions that aren't arbitrary

- **The QR stays dark-on-light with its own quiet zone, whatever the theme is doing.** A themed or inverted code scans fine on a desk and fails in a dark room, which is exactly where these get used. The theme colours the frame, background, accent and type; the code sits in a protected light card.
- **The QR's size drives the layout, not the reverse.** Its size decides how far away the piece works, so it's a fixed proportion of the page and everything else flows around it. The preview reports the physical size and a conservative dim-room scan distance (the 10:1 rule — the pessimistic end, which is what holds up in a bar with an older phone).
- **Every piece leads with the ask, not the band name.** The audience is holding a phone, not reading a bio. Travis's own copy — "SEE OUR ENTIRE SONG LIST!" — is better than the original "Request a Song" for the same reason: it offers something before it asks for anything, which matters on a table tent someone reads before they've decided to engage.
- **Error correction level M, not H.** Higher correction packs in more (and therefore smaller) modules, which costs more scan distance than the redundancy buys back on a clean printed sheet with no logo over it.
- **Margins are proportional but floored** at 9mm (12mm on a tent panel, so nothing sits on the fold). Purely proportional margins put A6 text about 5mm from the paper edge, inside the strip most home printers can't reach.
- **Type and QR scale independently.** They originally shared a font-size, which meant nudging the headline up quietly shrank the code and cost scan distance without saying so.

## Architecture

One idea holds it together: a "page" sized in real millimetres whose base font-size is derived from its own dimensions. Everything inside is sized in `em`, so a single piece of markup lays out correctly at A6 and at Tabloid without a second template. Portrait pieces are drawn against a 34-unit width; the landscape tent panels against a 22-unit height. Screen preview `transform: scale()`s that page down to fit the column; printing sets the scale back to 1 and the millimetres are already right.

Text slots are fixed boxes whose type shrinks to fit them, so a long band name simply sets smaller rather than overflowing. Because the sliders are free-range, the layout also defends itself: anything that would overflow gives back **type scale first**, and the QR last and never below 35mm.

**No database, no migration, no API endpoint, no schema change.** Everything renders client-side from `performer.handle`. Dependencies: `qrcode@1.5.4` and `html2canvas@1.4.1`, both imported lazily on first use via esm.sh; `pdf-lib` was already imported in `console.html` for setlist chart merging, so the PDF path added no new dependency at all.

**The PDF is a 300 DPI raster**, not vector text — the artboard is rasterised by html2canvas and embedded into a pdf-lib page of exact millimetre dimensions. DPI backs off toward 200 for the largest sheets, where the canvas would otherwise exceed roughly 12 million pixels. This was a deliberate trade: vector text would mean re-implementing every template as pdf-lib draw calls and maintaining two layout engines that drift apart. At 300 DPI, on flat colour and a QR, the difference isn't visible in print.

## Why PDF export at all, when the browser can print

Browser print *can* hit exact dimensions, but it depends on the performer setting margins to "None" and enabling background graphics every single time — miss either and the piece comes out shrunken with the colour stripped. The PDF bakes the page size into the file, which matters most at a print shop, where "fit to page" would otherwise quietly rescale the work. Both paths render from the same artboard, so they can't disagree.

## The non-production origin guard

The printed QR encodes whatever origin the console was loaded from. That's harmless for the existing Copy Link button — a wrong link is a two-second fix — but a stack of postcards pointing at `bribe-the-band-staging-three.vercel.app` can't be fixed at all. Step 1 of the tab therefore shows a red warning on any host that isn't `bribetheband.live` or `www.bribetheband.live`. It warns rather than blocks, since staging still has to be usable for design work.

**`www.bribetheband.live` is in that allow-list deliberately, and it matters**: production 308-redirects the bare domain to `www`, so `window.location.hostname` is `www.bribetheband.live` in real use. An allow-list with only the bare domain would have shown every performer a scary warning on every piece.

## Explicitly out of scope

- **Logo or photo upload.** Travis's call, directly: "no to uploading anything — they can go use their own Canva account if they want to do that." An image slot would also have meant a different set of templates, not a variation on these.
- **Vector text in the PDF** — see the raster trade-off above.
- **Any crowd-facing or database-backed behaviour.** Nothing here writes a row or tracks a scan. If "which piece did this scan come from" is ever wanted, that's a different feature (per-piece URL params and a counter), not an extension of this one.
- **A standalone print-shop ordering flow.** The performer takes the PDF wherever they like.

## Still open

- **Nothing has been printed on real hardware and tested in a real room.** Every claim about scan distance in this doc comes from geometry and the conservative 10:1 rule, not from a phone pointed at a printed sheet across a bar. The 9mm margin floor is likewise a conservative guess at consumer printer hardware, not a measurement of Travis's own. A set of ten proof PDFs was generated for exactly this purpose (see item 53); as of this writing they have not been printed.
- **Whether the five templates are the right five**, once real performers other than Travis see them.

## Related docs

- `04-DECISIONS-AND-OPEN-QUESTIONS.md` item 53 — the build narrative, the three bugs, and the verification actually performed.
- `01-ARCHITECTURE-AND-DATA-MODEL.md` — the `performers.handle` / `vercel.json` `/:handle` rewrite this whole feature hangs off; unchanged by it.
- `08-PERFORMER-FAQ-TUTORIAL-NOTES.md` — the natural home for a "how do I get people to scan" tutorial now that there's a real answer to point at.
