-- Bribe The Band — fix: songs.chart_url still NOT NULL on production
--
-- "Make chart PDFs optional when adding a song" (2026-09-10) removed the
-- client-side validation requiring a chart PDF/URL in console.html, on the
-- stated assumption that chart_url was already a nullable column in the
-- database — true on staging, but apparently never true on production.
-- Discovered 2026-09-11 while bulk-seeding the new "demo" performer's song
-- library directly via the REST API: a null chart_url was rejected with
-- `23502 null value in column "chart_url" ... violates not-null constraint`.
--
-- Real-world impact: any actual performer on production who used "Add a
-- Song" without attaching a PDF or pasting a URL has likely been hitting a
-- silent insert failure since that feature shipped — never caught at the
-- time since the feature wasn't independently tested hands-on on production.
--
-- PRODUCTION ONLY. Staging's chart_url is already nullable; this migration
-- is a no-op there (IF EXISTS/already-nullable guards make it safe to run
-- anywhere regardless, but it isn't needed on staging).

alter table public.songs
  alter column chart_url drop not null;
