-- Bribe The Band — Follower account-growth model + 12-hour gig auto-end
-- Run on STAGING first (Supabase SQL Editor), verify, then port to production
-- later the same way every other migration has been ported (see
-- 04-DECISIONS-AND-OPEN-QUESTIONS.md's "Porting method" note).
--
-- Everything here is purely additive: new table, new functions, new grants.
-- Nothing here alters or drops any existing table/column/function, so it's
-- safe to run without needing to see the current body of any existing
-- function (e.g. get_song_request_status) first.
--
-- Covers two decided-but-unbuilt items from 04-DECISIONS-AND-OPEN-QUESTIONS.md:
--   Item 20 (2026-08-27): auto-end a gig after 12 hours of zero activity.
--   Item 22 (2026-08-29): Follower account-growth model — join via link/gig
--     code into your OWN account, visible roster + remove, auto-leave on end.

-- ============================================================
-- 1. Follower roster table
-- ============================================================
-- One row per (gig, follower account) join event. Never hard-deleted — a
-- "leave" (explicit remove, gig end, or auto-end) just stamps left_at, so
-- the join event itself survives for the "Followed gig — N joined" reporting
-- tag and any future owner-reporting/growth analytics (Travis's standing
-- "always track data useful for valuation" principle, 2026-08-29).
create table if not exists gig_followers (
  id uuid primary key default gen_random_uuid(),
  gig_session_id uuid not null references gig_sessions(id) on delete cascade,
  performer_id uuid not null references performers(id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  unique (gig_session_id, performer_id)
);

alter table gig_followers enable row level security;
-- Deliberately zero RLS policies here — same doctrine as `requests`
-- (see request.html's own comment on this pattern): nothing reads or writes
-- this table directly over REST. All access goes through the SECURITY
-- DEFINER functions below, each of which does its own authorization check.

-- ============================================================
-- 2. Join a gig as a Follower, using your own logged-in account
-- ============================================================
-- Called by viewer.html when opened as ?join=<gig_code>. Looks the gig up
-- by its existing gig_code (already shown in the console today), records
-- the join, and hands back exactly what the Follower's viewer needs to
-- render the same set — without ever granting broad SELECT on gig_sessions
-- to arbitrary authenticated users.
create or replace function public.join_gig_by_code(p_gig_code text)
returns table (
  gig_session_id uuid,
  performer_id uuid,
  active_setlist_id uuid,
  runtime_order text[],
  display_name_override text
)
language plpgsql
security definer
as $$
declare
  v_gig record;
  v_follower_performer_id uuid;
begin
  select gs.id, gs.performer_id, gs.active_setlist_id, gs.runtime_order, gs.display_name_override
    into v_gig
  from gig_sessions gs
  where gs.gig_code = p_gig_code and gs.status = 'active';

  if v_gig.id is null then
    raise exception 'No active gig found for that code';
  end if;

  select p.id into v_follower_performer_id
  from performers p
  where p.auth_user_id = auth.uid();

  if v_follower_performer_id is null then
    raise exception 'Could not find your performer account';
  end if;

  insert into gig_followers (gig_session_id, performer_id)
  values (v_gig.id, v_follower_performer_id)
  on conflict (gig_session_id, performer_id)
    do update set left_at = null, joined_at = now();

  return query
    select v_gig.id, v_gig.performer_id, v_gig.active_setlist_id, v_gig.runtime_order, v_gig.display_name_override;
end;
$$;

grant execute on function public.join_gig_by_code(text) to authenticated;

-- ============================================================
-- 3. Master's roster view + remove
-- ============================================================
-- Only returns rows if the caller is the gig's own Master (owns the
-- performer row behind gig_sessions.performer_id) — never exposes another
-- performer's follower roster.
create or replace function public.get_gig_followers(p_gig_session_id uuid)
returns table (
  gig_follower_id uuid,
  follower_performer_id uuid,
  display_name text,
  handle text,
  joined_at timestamptz
)
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from gig_sessions gs
    join performers p on p.id = gs.performer_id
    where gs.id = p_gig_session_id and p.auth_user_id = auth.uid()
  ) then
    return; -- not this gig's Master — empty result, not an error (avoids leaking existence)
  end if;

  return query
    select gf.id, gf.performer_id, p.display_name, p.handle, gf.joined_at
    from gig_followers gf
    join performers p on p.id = gf.performer_id
    where gf.gig_session_id = p_gig_session_id and gf.left_at is null
    order by gf.joined_at;
end;
$$;

grant execute on function public.get_gig_followers(uuid) to authenticated;

create or replace function public.remove_gig_follower(p_gig_follower_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update gig_followers gf
    set left_at = now()
  from gig_sessions gs
  join performers p on p.id = gs.performer_id
  where gf.id = p_gig_follower_id
    and gf.gig_session_id = gs.id
    and p.auth_user_id = auth.uid()
    and gf.left_at is null;
end;
$$;

grant execute on function public.remove_gig_follower(uuid) to authenticated;

-- Stamps left_at on every current Follower of a gig — called by the
-- console's "End Gig" button (explicit end) and by check_and_end_stale_gig
-- below (12-hour auto-end). Scoped to the calling Master's own gig only.
create or replace function public.release_gig_followers(p_gig_session_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update gig_followers gf
    set left_at = now()
  from gig_sessions gs
  join performers p on p.id = gs.performer_id
  where gf.gig_session_id = p_gig_session_id
    and gf.gig_session_id = gs.id
    and p.auth_user_id = auth.uid()
    and gf.left_at is null;
end;
$$;

grant execute on function public.release_gig_followers(uuid) to authenticated;

-- Per-gig join counts for the calling Master's own gigs — powers the
-- Reporting tab's "Followed gig — N joined" tag and the solo-vs-followed
-- tip split (item 24). Counts every join event ever (not just currently-
-- present Followers), matching "how many accounts have joined a gig" from
-- the 2026-08-29 owner-reporting principle.
create or replace function public.get_follower_counts_for_my_gigs()
returns table (gig_session_id uuid, joined_count integer)
language plpgsql
security definer
as $$
declare
  v_my_performer_id uuid;
begin
  select id into v_my_performer_id from performers where auth_user_id = auth.uid();
  if v_my_performer_id is null then
    return;
  end if;

  return query
    select gf.gig_session_id, count(*)::int
    from gig_followers gf
    join gig_sessions gs on gs.id = gf.gig_session_id
    where gs.performer_id = v_my_performer_id
    group by gf.gig_session_id;
end;
$$;

grant execute on function public.get_follower_counts_for_my_gigs() to authenticated;

-- ============================================================
-- 4. Live splice-sync for a genuinely-distinct-account Follower
-- ============================================================
-- viewer.html's checkForFollowerSplices() previously read `requests`
-- directly, which only worked because the legacy ?role=follower path
-- shares the Master's own login (so existing RLS on `requests`, scoped to
-- the owning performer, already passed). A real distinct-account Follower
-- has no such ownership relationship, so this wraps the same read in a
-- SECURITY DEFINER function authorized for either the gig's own Master OR
-- a currently-joined (not yet left) Follower of that exact gig. Safe for
-- both callers — the legacy shared-login Master-as-"Follower" case still
-- passes the first branch, unchanged.
--
-- Known limitation, not fixed here: Supabase Realtime's postgres_changes
-- push still respects the underlying table's RLS, so a distinct-account
-- Follower's realtime subscription on `requests` will likely never fire —
-- they'll rely on the existing 15s poll fallback instead of near-instant
-- push. Enabling Realtime RLS for `requests` (a Supabase dashboard setting)
-- would close this gap; not done here since it wasn't part of what was
-- decided, and touches the same table the crowd-tip privacy design
-- deliberately locks down.
create or replace function public.get_spliced_requests_for_gig(p_gig_session_id uuid)
returns table (
  id uuid,
  song_id text,
  spliced_at timestamptz,
  splice_after_song_id text,
  splice_after_page_num integer,
  tip_amount numeric,
  note text,
  is_manual boolean
)
language plpgsql
security definer
as $$
declare
  v_authorized boolean;
begin
  select
    exists (
      select 1 from gig_sessions gs
      join performers p on p.id = gs.performer_id
      where gs.id = p_gig_session_id and p.auth_user_id = auth.uid()
    )
    or exists (
      select 1 from gig_followers gf
      join performers p on p.id = gf.performer_id
      where gf.gig_session_id = p_gig_session_id and gf.left_at is null and p.auth_user_id = auth.uid()
    )
  into v_authorized;

  if not v_authorized then
    return;
  end if;

  return query
    select r.id, r.song_id, r.spliced_at, r.splice_after_song_id, r.splice_after_page_num,
           r.tip_amount, r.note, r.is_manual
    from requests r
    where r.gig_session_id = p_gig_session_id
      and r.spliced_at is not null
    order by r.spliced_at asc;
end;
$$;

grant execute on function public.get_spliced_requests_for_gig(uuid) to authenticated;

-- ============================================================
-- 5. Auto-end a gig after 12 hours of zero activity (item 20)
-- ============================================================
-- "Zero activity" = no new `requests` row since the gig started. Piggybacks
-- onto existing poll cadences (the crowd page's refreshCapStatus() and the
-- console's loadActiveGig()) rather than adding a cron job — consistent
-- with how every other check-cadence in this app already works.
create or replace function public.check_and_end_stale_gig(p_gig_session_id uuid)
returns boolean
language plpgsql
security definer
as $$
declare
  v_last_activity timestamptz;
  v_ended boolean := false;
begin
  select greatest(gs.created_at, coalesce(max(r.created_at), gs.created_at))
    into v_last_activity
  from gig_sessions gs
  left join requests r on r.gig_session_id = gs.id
  where gs.id = p_gig_session_id and gs.status = 'active'
  group by gs.created_at;

  if v_last_activity is not null and v_last_activity < now() - interval '12 hours' then
    update gig_sessions set status = 'ended' where id = p_gig_session_id and status = 'active';
    update gig_followers set left_at = now() where gig_session_id = p_gig_session_id and left_at is null;
    v_ended := true;
  end if;

  return v_ended;
end;
$$;

grant execute on function public.check_and_end_stale_gig(uuid) to anon, authenticated;
