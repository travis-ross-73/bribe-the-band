-- Lets a promo code temporarily discount the PLATFORM'S fee_percentage for
-- whichever performers redeem it during a limited window (a redemption-count
-- cap, a date cap, or both — whichever is hit first closes the window to
-- NEW redemptions). A performer who gets in during the window keeps the
-- discounted rate permanently — this does not decay or revert later.
--
-- Once the window closes, discount_fee_ends_code decides what happens to
-- the code itself for anyone who tries it afterward:
--   false (default, "stay open"): the code keeps working normally — new
--     redeemers still get referral_code attached and the affiliate still
--     earns commission, just at the performer's normal (non-discounted)
--     fee_percentage.
--   true ("end the code"): the code stops working entirely for anyone who
--     tries it after the window closes — no referral_code gets attached at
--     all, so no attribution/commission happens for them. Never touches
--     anyone already attributed before the window closed. Also flips
--     promo_codes.active to false at that point, best-effort, purely so it
--     reads correctly in this console's own list — nothing in the live app
--     currently gates on that column at signup time as far as this
--     environment can verify, so this is a visibility aid, not the actual
--     enforcement (the enforcement is the referral_code-nulling above).
--
-- Deliberately does NOT touch handle_new_performer_signup() or the Owner
-- Console's own retroactive-assignment code — same reasoning as
-- migration-referral-assigned-at-v1.sql and
-- migration-stripe-connect-completed-at-v1.sql: this environment has no
-- safe way to read/replace an existing function it didn't write. Instead,
-- a new, fully additive trigger watches for referral_code being set/changed
-- to a non-null value on `performers`, regardless of which code path did
-- the writing — signup or the Owner Console's bulk/individual assignment
-- both go through the exact same check.
--
-- No change needed anywhere in the live payment path (create-payment-intent.js
-- already reads performers.fee_percentage directly at charge time) — setting
-- it once here is picked up on every future charge automatically.

alter table promo_codes
  add column if not exists discounted_fee_percentage numeric,
  add column if not exists discount_fee_max_redemptions integer,
  add column if not exists discount_fee_valid_until timestamptz,
  add column if not exists discount_fee_redemptions_used integer not null default 0,
  add column if not exists discount_fee_ends_code boolean not null default false;

create or replace function apply_promo_fee_discount()
returns trigger
language plpgsql
as $$
declare
  v_code record;
  v_window_open boolean;
  v_original_code text;
begin
  -- Only act on a genuine new/changed non-null referral_code — never on
  -- an unrelated column update, and never when referral_code is cleared.
  if new.referral_code is null
     or (TG_OP = 'UPDATE' and new.referral_code is not distinct from old.referral_code) then
    return new;
  end if;

  v_original_code := new.referral_code;

  -- Lock the promo_codes row for the duration of this check+increment so
  -- two near-simultaneous redemptions of the same code can't both slip in
  -- past the cap.
  select discounted_fee_percentage, discount_fee_max_redemptions, discount_fee_valid_until,
         discount_fee_redemptions_used, discount_fee_ends_code
    into v_code
    from promo_codes
    where code = v_original_code
    for update;

  if not found or v_code.discounted_fee_percentage is null then
    return new; -- no such code, or this code doesn't offer a fee discount at all
  end if;

  v_window_open := true;
  if v_code.discount_fee_valid_until is not null and now() >= v_code.discount_fee_valid_until then
    v_window_open := false;
  end if;
  if v_window_open and v_code.discount_fee_max_redemptions is not null
     and v_code.discount_fee_redemptions_used >= v_code.discount_fee_max_redemptions then
    v_window_open := false;
  end if;

  if v_window_open then
    new.fee_percentage := v_code.discounted_fee_percentage;
    update promo_codes
      set discount_fee_redemptions_used = discount_fee_redemptions_used + 1
      where code = v_original_code;
  elsif v_code.discount_fee_ends_code then
    new.referral_code := null;
    update promo_codes set active = false where code = v_original_code;
  end if;
  -- else ("stay open", the default): window closed, no discount applied,
  -- but referral_code — and therefore affiliate attribution/commission —
  -- is left completely untouched.

  return new;
end;
$$;

drop trigger if exists trg_apply_promo_fee_discount on performers;
create trigger trg_apply_promo_fee_discount
  before insert or update on performers
  for each row
  execute function apply_promo_fee_discount();
