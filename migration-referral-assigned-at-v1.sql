-- Adds performers.referral_assigned_at: when this performer's CURRENT
-- referral_code took effect, whether set at signup or via the Owner
-- Console's retroactive-assignment flow. Needed to start the
-- affiliate_commission_months clock for a non-perpetual affiliate code —
-- performers.created_at (signup date) isn't a safe stand-in, since a
-- retroactively-assigned code takes effect well after signup.
--
-- Purely additive: a new nullable column, a new trigger function, a new
-- trigger. Does NOT touch handle_new_performer_signup() or any other
-- existing function — this environment has no way to read that function's
-- current body to safely replace it, so the timestamp is stamped
-- independently, by watching for any write that sets/changes
-- referral_code, regardless of which code path did the writing.

alter table performers
  add column if not exists referral_assigned_at timestamptz;

create or replace function set_referral_assigned_at()
returns trigger
language plpgsql
as $$
begin
  -- Only stamp when a code is being SET or CHANGED to a non-null value —
  -- never when referral_code is being cleared, and never touched by an
  -- unrelated column update that leaves referral_code as it was.
  if new.referral_code is not null
     and (TG_OP = 'INSERT' or new.referral_code is distinct from old.referral_code) then
    new.referral_assigned_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_referral_assigned_at on performers;
create trigger trg_set_referral_assigned_at
  before insert or update on performers
  for each row
  execute function set_referral_assigned_at();

-- Backfill for anyone who already carries a referral_code today: their
-- signup date is the correct assignment time for genuine signup-time
-- attribution, and the best available approximation for any pre-console
-- manual assignment done directly in the SQL editor.
update performers
  set referral_assigned_at = created_at
  where referral_code is not null
    and referral_assigned_at is null;
