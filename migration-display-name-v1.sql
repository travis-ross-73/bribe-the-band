-- migration-display-name-v1.sql
-- Adds a per-gig display-name override so the crowd page can show something
-- other than the performer's account name for a given night (e.g. a band
-- name instead of the account holder's own name).
--
-- Run once in the STAGING Supabase SQL editor (orwxehvthwflgoqnbafp) first.
-- Once verified working, re-run this same file (unmodified) against production.

alter table gig_sessions
  add column if not exists display_name_override text;
