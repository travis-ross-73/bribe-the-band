-- Bribe The Band — server-side enforcement of the nightly request cap and
-- post-play cooldown for the $0 "no tip" request path.
-- Run on STAGING first (Supabase SQL Editor), verify, then port to
-- production the same way every other migration has been ported (see
-- docs/04-DECISIONS-AND-OPEN-QUESTIONS.md's "Porting method" note).
--
-- Purely additive: one new function, one new trigger. Does not touch or
-- replace any existing function, so it's safe to run without needing to
-- see the current body of anything else first (matches CLAUDE.md's
-- "don't guess at replacing something you haven't verified" doctrine).
--
-- Background: the crowd page's $0/no-tip path is a direct anon-key insert
-- into `requests` with only a client-side cap/cooldown check — bypassable
-- via devtools. Confirmed empirically on staging 2026-09-02: a raw anon-key
-- insert for a song already at its request_cap succeeded three times in a
-- row with no server-side rejection at all. The paid path already has a
-- server-side re-check (api/create-payment-intent.js re-runs
-- get_song_request_status() right before charging), so this migration
-- targets the direct-insert path specifically, without touching Stripe's
-- webhook insert — see the `stripe_payment_intent_id is not null` skip
-- below.
create or replace function public.enforce_request_limits()
returns trigger
language plpgsql
security definer
as $$
declare
  v_status record;
begin
  -- Never subject to crowd limits: the Master's own manual "add a song"
  -- tool (is_manual), a tip-only request with no song attached, or a row
  -- the Stripe webhook is inserting after its own pre-charge re-check
  -- already ran (stripe_payment_intent_id is only ever set there). Skipping
  -- the paid path here avoids a new failure mode where a legitimately
  -- completed, already-charged Stripe payment could hit a rejected insert
  -- in a rare race — that path already re-checks status before money moves.
  if new.is_manual or new.song_id is null or new.stripe_payment_intent_id is not null then
    return new;
  end if;

  select * into v_status
  from get_song_request_status(new.gig_session_id) s
  where s.song_id = new.song_id;

  if v_status.in_cooldown then
    raise exception 'This song was just played and is on cooldown for a bit.';
  end if;

  if v_status.is_capped then
    raise exception 'This song has already been requested plenty tonight.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_request_limits on requests;
create trigger trg_enforce_request_limits
  before insert on requests
  for each row execute function public.enforce_request_limits();
