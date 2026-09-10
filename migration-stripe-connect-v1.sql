-- Bribe The Band — Stripe Connect Express (item 23 / 09-CONNECT-EXPRESS-SCOPE.md)
--
-- Schema + RPC functions for self-serve per-performer Stripe payouts. Purely
-- additive: three new `performers` columns, no changes to existing ones.
--
-- Follows this project's established doctrine (see Wade's-review items):
-- `performers` has NO RLS UPDATE policy at all, so a raw client-side
-- `.update()` from a serverless function would silently affect zero rows
-- even when authenticated as the right user (the same class of bug found
-- and fixed for `default_song_minutes` back on 2026-09-07). Every write
-- here goes through a narrow SECURITY DEFINER function instead, scoped by
-- auth.uid() internally. Same reasoning for reads: rather than grant raw
-- column SELECT (which — for `stripe_account_id` especially — would either
-- need to stay authenticated-only, exposing every performer's account id to
-- every other logged-in performer, or need a real RLS policy this table has
-- never had), a SECURITY DEFINER function scopes each read to exactly the
-- caller's own row or the one gig it's asked about.

-- ============================================================
-- 1. Schema
-- ============================================================
alter table public.performers
  add column if not exists stripe_account_id text,
  add column if not exists stripe_onboarding_status text not null default 'not_started',
  add column if not exists fee_percentage numeric not null default 10;

-- 'not_started' | 'pending' | 'complete' | 'restricted' — enforced in
-- application code (create-connect-account-link.js / check-connect-status.js),
-- not a DB constraint, so a future status doesn't need a migration to add.

-- ============================================================
-- 2. Performer's own read of their Connect status (Settings tab)
-- ============================================================
create or replace function public.get_my_stripe_connect_status()
returns table (
  stripe_account_id text,
  stripe_onboarding_status text,
  fee_percentage numeric
)
language plpgsql
security definer
as $$
begin
  return query
    select p.stripe_account_id, p.stripe_onboarding_status, p.fee_percentage
    from performers p
    where p.auth_user_id = auth.uid();
end;
$$;

grant execute on function public.get_my_stripe_connect_status() to authenticated;

-- ============================================================
-- 3. Performer's own write of their Connect status — called by
--    create-connect-account-link.js right after creating (or reusing) the
--    Express account, and by check-connect-status.js after re-checking
--    charges_enabled/payouts_enabled against Stripe's own account object.
-- ============================================================
create or replace function public.set_my_stripe_connect_status(
  p_stripe_account_id text,
  p_status text
)
returns void
language plpgsql
security definer
as $$
begin
  update performers
  set stripe_account_id = p_stripe_account_id,
      stripe_onboarding_status = p_status
  where auth_user_id = auth.uid();
end;
$$;

grant execute on function public.set_my_stripe_connect_status(text, text) to authenticated;

-- ============================================================
-- 4. Anon-callable lookup for create-payment-intent.js: given a gig, find
--    the owning performer's payout info. Deliberately the only cross-
--    performer read here, and deliberately narrow (two columns, one gig) —
--    same trust level as get_song_request_status(), no ownership check
--    needed since nothing here is private (a connected account id isn't a
--    secret; it's meaningless without the platform's own Stripe secret key).
-- ============================================================
create or replace function public.get_performer_payout_info(p_gig_session_id uuid)
returns table (
  stripe_account_id text,
  fee_percentage numeric
)
language plpgsql
security definer
as $$
begin
  return query
    select p.stripe_account_id, p.fee_percentage
    from gig_sessions gs
    join performers p on p.id = gs.performer_id
    where gs.id = p_gig_session_id;
end;
$$;

grant execute on function public.get_performer_payout_info(uuid) to anon;
