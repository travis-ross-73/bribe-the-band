-- Bribe The Band — "Last Call" / dynamic request cutoff (V2-BACKLOG /
-- 04-DECISIONS-AND-OPEN-QUESTIONS.md item 29). Run on STAGING first
-- (Supabase SQL Editor), verify, then port to production the same way
-- every other migration has been ported.
--
-- Purely additive: new nullable columns, one new table-reading function,
-- one new state-stamping function. Nothing existing is altered. Every new
-- column defaults to inert (feature off) for any gig that doesn't set
-- set_ends_at, so existing continuous-set/no-cutoff gigs are completely
-- unaffected.
--
-- Design (confirmed by Travis 2026-09-02, recovered from the 2026-08-29
-- backlog compilation — see docs/04-DECISIONS-AND-OPEN-QUESTIONS.md for
-- the full write-up):
--   - Dynamic cutoff: close new requests once time remaining in the set
--     <= (songs currently in the live queue) x avg minutes/song + buffer.
--   - A song already in the queue stays boostable past cutoff — this is
--     not a new fulfillment promise, so it's explicitly exempt.
--   - A request that arrives after cutoff is NOT auto-declined — it's
--     accepted normally and flagged for the Master to triage by hand
--     (see viewer.html's drawer). No DB-level insert rejection here.
--   - Multi-set nights (resolved 2026-09-02): total_sets is informational/
--     UI-copy-driving only in this v1 — set_ends_at always means the end
--     of the *last* set of the night, so the cutoff never fires early at
--     a set break. No separate per-set math.

-- ============================================================
-- 1. Schema
-- ============================================================
alter table songs add column if not exists estimated_minutes numeric;
comment on column songs.estimated_minutes is 'Per-song override for average runtime, minutes. Null = use the performer default.';

alter table performers add column if not exists default_song_minutes numeric default 4;
comment on column performers.default_song_minutes is 'Fallback average song length (minutes) used by the Last Call cutoff estimate when a song has no estimated_minutes override.';

alter table gig_sessions add column if not exists set_ends_at timestamptz;
comment on column gig_sessions.set_ends_at is 'When tonight''s final set ends. Null = Last Call feature is off for this gig.';

alter table gig_sessions add column if not exists request_buffer_minutes numeric default 10;
comment on column gig_sessions.request_buffer_minutes is 'Safety margin for the cutoff formula; the same value also sizes the soft Last Call pre-warning window.';

alter table gig_sessions add column if not exists total_sets integer default 1;
comment on column gig_sessions.total_sets is 'How many sets tonight. Informational/UI-copy only in v1 -- set_ends_at always represents the end of the final set regardless of this number, so requests never pause at a set break.';

alter table gig_sessions add column if not exists cutoff_reached_at timestamptz;
comment on column gig_sessions.cutoff_reached_at is 'Stamped once, the first time the dynamic cutoff formula evaluates true. Used to flag any request whose created_at is later than this as "arrived after cutoff" for the Master to triage -- never used to reject an insert.';

-- ============================================================
-- 2. Cutoff status (read-only, mirrors get_song_request_status's shape
--    and trust level -- callable by anon, no ownership check needed since
--    it exposes nothing private, same as the existing cap/cooldown RPC)
-- ============================================================
create or replace function public.get_request_cutoff_status(p_gig_session_id uuid)
returns table (
  cutoff_enabled boolean,
  set_ends_at timestamptz,
  seconds_remaining integer,
  songs_remaining_estimate integer,
  is_last_call boolean,
  is_cutoff_reached boolean,
  cutoff_reached_at timestamptz,
  total_sets integer
)
language plpgsql
security definer
as $$
declare
  v_gig record;
  v_queue_count integer;
  v_avg_minutes numeric;
  v_seconds_remaining numeric;
  v_buffer_seconds numeric;
  v_needed_seconds numeric;
  v_is_cutoff boolean;
  v_is_last_call boolean;
  v_estimate integer;
begin
  select gs.set_ends_at, gs.request_buffer_minutes, gs.total_sets, gs.cutoff_reached_at,
         gs.performer_id, gs.runtime_order
    into v_gig
  from gig_sessions gs
  where gs.id = p_gig_session_id;

  if v_gig.set_ends_at is null then
    return query select false, null::timestamptz, null::integer, null::integer, false, false, null::timestamptz, coalesce(v_gig.total_sets, 1);
    return;
  end if;

  -- Same "one occasion per song" collapsing rule the request cap already
  -- uses: multiple simultaneous requests for the same song are one slot
  -- in the queue, not several.
  select count(distinct r.song_id) into v_queue_count
  from requests r
  where r.gig_session_id = p_gig_session_id
    and r.song_id is not null
    and r.status in ('pending', 'accepted')
    and r.spliced_at is null;

  select avg(coalesce(s.estimated_minutes, p.default_song_minutes, 4))
    into v_avg_minutes
  from songs s
  join performers p on p.id = v_gig.performer_id
  where s.id = any(v_gig.runtime_order);

  v_avg_minutes := coalesce(v_avg_minutes, 4);
  v_buffer_seconds := coalesce(v_gig.request_buffer_minutes, 10) * 60;
  v_seconds_remaining := extract(epoch from (v_gig.set_ends_at - now()));
  v_needed_seconds := coalesce(v_queue_count, 0) * v_avg_minutes * 60;

  v_is_cutoff := v_seconds_remaining <= (v_needed_seconds + v_buffer_seconds);
  -- Soft warning window: one more buffer-length of lead time before the
  -- hard cutoff above actually fires.
  v_is_last_call := (not v_is_cutoff) and (v_seconds_remaining <= (v_needed_seconds + 2 * v_buffer_seconds));

  -- Headroom in "songs", not just seconds: how many more average-length
  -- songs could still realistically be requested and played, on top of
  -- what's already queued. Reaches zero exactly when the cutoff condition
  -- above is first met -- same formula, different unit.
  v_estimate := greatest(0, floor((v_seconds_remaining - v_buffer_seconds) / nullif(v_avg_minutes * 60, 0))::integer - coalesce(v_queue_count, 0));

  return query select
    true,
    v_gig.set_ends_at,
    greatest(0, v_seconds_remaining)::integer,
    v_estimate,
    v_is_last_call,
    v_is_cutoff,
    v_gig.cutoff_reached_at,
    coalesce(v_gig.total_sets, 1);
end;
$$;

grant execute on function public.get_request_cutoff_status(uuid) to anon, authenticated;

-- ============================================================
-- 3. Stamp cutoff_reached_at the first time it's true (piggybacked onto
--    an existing poll cadence -- the crowd page's refreshCapStatus(),
--    already running every 8s -- rather than a cron job, matching every
--    other check-cadence in this app)
-- ============================================================
create or replace function public.mark_cutoff_reached_if_needed(p_gig_session_id uuid)
returns boolean
language plpgsql
security definer
as $$
declare
  v_already timestamptz;
  v_status record;
begin
  select cutoff_reached_at into v_already from gig_sessions where id = p_gig_session_id;
  if v_already is not null then
    return true;
  end if;

  select * into v_status from get_request_cutoff_status(p_gig_session_id);
  if v_status.is_cutoff_reached then
    update gig_sessions set cutoff_reached_at = now() where id = p_gig_session_id and cutoff_reached_at is null;
    return true;
  end if;
  return false;
end;
$$;

grant execute on function public.mark_cutoff_reached_if_needed(uuid) to anon, authenticated;
