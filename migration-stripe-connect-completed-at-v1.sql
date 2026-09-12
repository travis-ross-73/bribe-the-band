-- Adds performers.stripe_connect_completed_at: when this performer's Stripe
-- Connect onboarding first reached 'complete', for the Owner Console's
-- performers list (sortable "Connect completed" column). Same additive
-- pattern as migration-referral-assigned-at-v1.sql, and for the same
-- reason: this environment has no way to safely read/replace whatever
-- existing code path writes performers.stripe_onboarding_status (the
-- get_my_stripe_connect_status/set_my_stripe_connect_status RPCs and
-- api/check-connect-status.js), so the timestamp is stamped independently
-- by a trigger watching for the column transitioning to 'complete',
-- regardless of which code path did the writing.
--
-- Deliberately NOT backfilled. Unlike referral_assigned_at, there is no
-- honest proxy for "when did this already-complete account's onboarding
-- actually finish" — created_at is signup date, not completion date, and
-- guessing would just be a fabricated number presented as data. A
-- performer who was already 'complete' before this migration ran will
-- show a null completion date going forward; that's correct, not a bug.

alter table performers
  add column if not exists stripe_connect_completed_at timestamptz;

create or replace function set_stripe_connect_completed_at()
returns trigger
language plpgsql
as $$
begin
  if new.stripe_onboarding_status = 'complete'
     and (TG_OP = 'INSERT' or old.stripe_onboarding_status is distinct from 'complete') then
    new.stripe_connect_completed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_stripe_connect_completed_at on performers;
create trigger trg_set_stripe_connect_completed_at
  before insert or update on performers
  for each row
  execute function set_stripe_connect_completed_at();
