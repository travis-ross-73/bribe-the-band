-- migration-queue-cooldown-v1.sql
-- Adds: played_at (cooldown trigger), gig_sessions.cooldown_minutes,
-- and extends get_song_request_status() to v5 with queue/cooldown info.
--
-- Run once in the STAGING Supabase SQL editor (orwxehvthwflgoqnbafp) first.
-- Verified against the live staging schema before running:
--   - requests.tip_amount, requests.spliced_at, requests.is_manual,
--     gig_sessions.request_cap, gig_sessions.cap_reset_at all confirmed
--     to exist with these exact names.
--   - requests.song_id and songs.id are both `text`, NOT uuid — fixed
--     below (the original draft of this migration assumed uuid).
-- Once verified working on staging, re-run this same file (unmodified)
-- against production.

-- 1. New columns
alter table requests
  add column if not exists played_at timestamptz;

alter table gig_sessions
  add column if not exists cooldown_minutes integer;

-- 2. Replace get_song_request_status() — same signature family as before,
--    now returning four additional aggregate columns. Postgres does not
--    allow CREATE OR REPLACE to change a function's return columns, so the
--    old version has to be dropped first (this also drops its grants,
--    which are re-applied at the bottom). Still SECURITY DEFINER so the
--    crowd page never gets raw request rows (tips/notes stay private;
--    only these aggregates are exposed).
drop function if exists get_song_request_status(uuid);

create function get_song_request_status(p_gig_session_id uuid)
returns table (
  song_id text,
  requests_used integer,
  max_requests_per_gig integer,
  is_capped boolean,
  queue_tip_total numeric,
  in_queue boolean,
  in_cooldown boolean,
  cooldown_seconds_remaining integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cap integer;
  v_reset_at timestamptz;
  v_cooldown_minutes integer;
begin
  select request_cap, cap_reset_at, cooldown_minutes
    into v_cap, v_reset_at, v_cooldown_minutes
    from gig_sessions
    where id = p_gig_session_id;

  return query
  with occasions as (
    -- one row per "occasion" toward the cap: a spliced batch (grouped by
    -- spliced_at) counts once, an open pending/accepted-unspliced request
    -- counts once each — same dedup rule as before, unchanged.
    select r.song_id, count(distinct coalesce(r.spliced_at::text, r.id::text)) as used
    from requests r
    where r.gig_session_id = p_gig_session_id
      and r.status <> 'declined'
      and r.is_manual is not true
      and (v_reset_at is null or r.created_at >= v_reset_at)
    group by r.song_id
  ),
  active_queue as (
    -- "in queue" = anything not yet played and not declined — covers both
    -- still-pending requests AND accepted-but-not-yet-played spliced songs,
    -- per Travis's confirmation these both stay tippable until "Got it - play".
    select r.song_id, sum(r.tip_amount) as tip_total
    from requests r
    where r.gig_session_id = p_gig_session_id
      and r.status <> 'declined'
      and r.played_at is null
      and r.is_manual is not true
    group by r.song_id
  ),
  cooldown as (
    -- most recent play per song, only relevant while still within the window
    select r.song_id, max(r.played_at) as last_played_at
    from requests r
    where r.gig_session_id = p_gig_session_id
      and r.played_at is not null
    group by r.song_id
  )
  select
    s.id as song_id,
    coalesce(o.used, 0)::integer as requests_used,
    v_cap as max_requests_per_gig,
    -- capped only applies to starting a brand-new occasion; a song currently
    -- in_queue is never "capped" against further boosting (see note above).
    (v_cap is not null
       and coalesce(o.used, 0) >= v_cap
       and aq.song_id is null
    ) as is_capped,
    coalesce(aq.tip_total, 0) as queue_tip_total,
    (aq.song_id is not null) as in_queue,
    (
      cd.last_played_at is not null
      and v_cooldown_minutes is not null
      and now() < cd.last_played_at + make_interval(mins => v_cooldown_minutes)
    ) as in_cooldown,
    case
      when cd.last_played_at is not null and v_cooldown_minutes is not null
        and now() < cd.last_played_at + make_interval(mins => v_cooldown_minutes)
      then extract(epoch from (cd.last_played_at + make_interval(mins => v_cooldown_minutes) - now()))::integer
      else null
    end as cooldown_seconds_remaining
  from songs s
  left join occasions o on o.song_id = s.id
  left join active_queue aq on aq.song_id = s.id
  left join cooldown cd on cd.song_id = s.id
  where s.performer_id = (
    select performer_id from gig_sessions where id = p_gig_session_id
  );
end;
$$;

grant execute on function get_song_request_status(uuid) to anon, authenticated;

-- 3. Cooldown check at submit-time: request.html's own client-side gray-out
--    can be bypassed via devtools, same pre-existing gap the cap check has
--    today (the $0 "no tip" path inserts directly into `requests` with the
--    anon key, with no server-side re-check at all). Not closed by this
--    migration — tracked as a known gap, not a blocker for this feature.
--    api/create-payment-intent.js DOES get a server-side in_cooldown guard,
--    added alongside its existing is_capped guard, since it already calls
--    this same RPC before creating a charge.
