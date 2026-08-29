# CLAUDE.md — Bribe The Band

Working-memory instructions for Claude Code sessions on this repo. Read `docs/HANDOFF-SUMMARY.md` first for full project context, then `docs/01-ARCHITECTURE-AND-DATA-MODEL.md` and `docs/04-DECISIONS-AND-OPEN-QUESTIONS.md` for depth.

## Docs live in this repo now

`docs/` is the shared source of truth (moved here from Claude Project Knowledge 2026-08-29) — **`git pull` before touching anything in `docs/`**, since Travis may have updated it from a separate Claude project chat. Commit doc changes with clear, specific messages (not "update docs") so the two sides — this repo and any other Claude session — never silently overwrite each other's work.

Note: `docs/` currently only exists on `main` (and any branch cut from it, e.g. `prod-port`) — it was never merged onto `staging`. Read it via `git show main:docs/<file>` while working on `staging`, rather than switching branches back and forth.

## Branches

- `main` — production (`bribetheband.live`), live Stripe, real users.
- `staging` — isolated copy of the whole stack (separate Supabase project, Wasabi bucket, Vercel project), for building/testing anything new before it reaches production. See `docs/07-STAGING-ENVIRONMENT-SETUP.md` and `docs/HANDOFF-SUMMARY.md` for credentials and current environment details.

**Never `git merge staging` into `main`** — it would pull staging's Supabase project URL/keys and Stripe test-mode key into production. Instead: diff `staging` against its own pre-session state, apply that diff as a standalone patch onto a fresh branch off `main`, and grep the result for the environment-specific lines (Supabase URL/anon key, Stripe publishable key) before pushing.

## Migrations

Every schema change ships as a `migration-*.sql` file in the repo root, delivered for Travis to run himself in the Supabase SQL Editor (no direct SQL execution access from Claude Code — only the REST API via the anon key, which can't run DDL). When asked to "build and deploy," always end with an explicit, ordered list of which SQL files need to be run and where (staging vs. production), since code and schema changes ship separately.

Run any new migration against the target environment **before** pushing the matching code — existing deployed code should only read a subset of any new RPC's return columns, so it stays forward-compatible with a migrated schema. Confirm that's true for a given change before relying on it.

## Verifying `requests` table state

`requests` is deliberately unreadable by the `anon` key (by design — crowd tip amounts/notes stay private). Querying it with the anon key always returns empty regardless of success. Use the project's `service_role` key to verify `requests` rows directly, or add a scoped SECURITY DEFINER RPC if a client-facing read is actually needed.

## General

- Claude Code has direct GitHub push access (a fine-grained PAT, provided per-session — not persisted in git config or the remote URL).
- Prefer additive schema changes (new tables/functions, `create or replace` on functions *you wrote*) over altering existing functions you can't read the current body of — there's no live SQL introspection access from this environment without a service_role key, so don't guess at replacing something you haven't verified.
