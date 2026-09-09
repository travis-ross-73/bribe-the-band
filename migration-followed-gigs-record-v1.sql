-- Bribe The Band — Follower-facing "gigs I've followed" record (item 24,
-- the second half — the Master-side tag/split was already built
-- 2026-08-29; this is the Follower's own view, deliberately left as its
-- own follow-up at the time).
--
-- Design (04-DECISIONS-AND-OPEN-QUESTIONS.md, 2026-08-29): "a separate,
-- clearly-labeled section — informational only, explicitly not the
-- follower's own money — showing gigs they've followed, most-requested
-- songs during those gigs, and tip totals per followed gig/song. Kept
-- visually distinct... so a followed-gig tip total can never read as
-- belonging to the follower."
--
-- Purely additive: two new functions, no schema changes. Both scoped by
-- auth.uid() internally (no parameters), matching get_follower_counts_for_
-- my_gigs()'s existing shape for the Master-side equivalent.

-- ============================================================
-- 1. Which gigs has the calling performer followed, and whose gigs were
--    they (for display: "Gig with Ten Cent Prophet, Sept 5")
-- ============================================================
create or replace function public.get_gigs_i_followed()
returns table (
  gig_session_id uuid,
  joined_at timestamptz,
  left_at timestamptz,
  gig_created_at timestamptz,
  gig_status text,
  master_display_name text,
  master_handle text
)
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
    select gf.gig_session_id, gf.joined_at, gf.left_at,
           gs.created_at, gs.status,
           p.display_name, p.handle
    from gig_followers gf
    join gig_sessions gs on gs.id = gf.gig_session_id
    join performers p on p.id = gs.performer_id
    where gf.performer_id = v_my_performer_id
    order by gf.joined_at desc;
end;
$$;

grant execute on function public.get_gigs_i_followed() to authenticated;

-- ============================================================
-- 2. Song/tip data for those same gigs, scoped to real crowd requests only
--    (excludes is_manual, same convention as the Master's own Reporting
--    query) and deliberately NOT including `note` -- a dedication note
--    wasn't written for a third-party Follower to read, only the
--    performer who received it.
-- ============================================================
create or replace function public.get_requests_for_gigs_i_followed()
returns table (
  gig_session_id uuid,
  song_id text,
  song_title text,
  song_artist text,
  tip_amount numeric
)
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
    select r.gig_session_id, r.song_id, r.song_title, r.song_artist, r.tip_amount
    from requests r
    where r.is_manual = false
      and r.gig_session_id in (
        select gf.gig_session_id from gig_followers gf where gf.performer_id = v_my_performer_id
      );
end;
$$;

grant execute on function public.get_requests_for_gigs_i_followed() to authenticated;
