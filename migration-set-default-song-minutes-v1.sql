-- Bribe The Band — safe self-service update path for
-- performers.default_song_minutes, found necessary 2026-09-07 while
-- hands-on testing the Last Call panel's Save button on staging.
--
-- What was actually wrong: not a grant gap (already fixed by the two
-- prior migrations) -- a raw `update performers set ... where id = ...`
-- from the authenticated client affects ZERO rows, silently, no error,
-- even for an already-granted, pre-existing column like display_name.
-- Confirmed directly. This means `performers` has no RLS UPDATE policy
-- allowing a performer to touch their own row at all -- nobody has ever
-- self-edited a performers column via the client before; every existing
-- Owner's-Guide-documented profile edit (plan_status, discount_percent,
-- etc.) has always been done by Travis directly in the SQL editor.
--
-- Rather than add a general RLS UPDATE policy on `performers` itself --
-- a table Wade's review specifically hardened against broad access,
-- since it carries PII/billing-adjacent columns -- this adds one narrow
-- SECURITY DEFINER function, scoped to the calling performer's own row
-- and this one column only, matching the same pattern already used
-- everywhere else in this app for a self-service write that shouldn't
-- need to open up broader table access (join_gig_by_code,
-- remove_gig_follower, etc.).
create or replace function public.set_my_default_song_minutes(p_minutes numeric)
returns void
language plpgsql
security definer
as $$
begin
  update performers
    set default_song_minutes = p_minutes
    where auth_user_id = auth.uid();
end;
$$;

grant execute on function public.set_my_default_song_minutes(numeric) to authenticated;
