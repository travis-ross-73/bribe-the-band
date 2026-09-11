-- Bribe The Band — Stripe Connect Express, follow-up: house-account exemption
--
-- Travis's own real account (`travis-ross`, same performer_id on both
-- environments) never goes through Connect onboarding itself — see
-- 09-CONNECT-EXPRESS-SCOPE.md's "Travis's own account" section. Without an
-- explicit flag, create-payment-intent.js can't tell "a real performer who
-- hasn't onboarded yet" (should be blocked from taking tips) apart from
-- "the house account, deliberately exempt" (should keep working exactly as
-- it does today, direct to the platform's own Stripe account) — both have
-- a null stripe_account_id.

alter table public.performers
  add column if not exists is_house_account boolean not null default false;

update public.performers set is_house_account = true where handle = 'travis-ross';

-- get_performer_payout_info() must be dropped before recreating with a
-- different return shape — Postgres rejects a bare CREATE OR REPLACE across
-- a changed RETURNS TABLE column list (same gotcha already documented for
-- get_song_request_status() earlier in this project).
drop function if exists public.get_performer_payout_info(uuid);

create or replace function public.get_performer_payout_info(p_gig_session_id uuid)
returns table (
  stripe_account_id text,
  fee_percentage numeric,
  is_house_account boolean
)
language plpgsql
security definer
as $$
begin
  return query
    select p.stripe_account_id, p.fee_percentage, p.is_house_account
    from gig_sessions gs
    join performers p on p.id = gs.performer_id
    where gs.id = p_gig_session_id;
end;
$$;

grant execute on function public.get_performer_payout_info(uuid) to anon;

-- ============================================================
-- Records the platform's actual cut per paid request (dollars, matching
-- the existing tip_amount convention — not cents), so total platform
-- revenue can be read directly off `requests` instead of recomputed from
-- fee_percentage after the fact (a performer's rate could change later).
-- Null for the house account and for any pre-Connect historical row.
-- ============================================================
alter table public.requests
  add column if not exists platform_fee_amount numeric;

