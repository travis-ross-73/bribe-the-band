-- Bribe The Band — fix a real bug in join_gig_by_code(), found 2026-09-02
-- while hands-on testing the Follower account-growth model on staging.
-- Run on STAGING (Supabase SQL Editor) — no other changes needed alongside
-- this one.
--
-- Bug: calling join_gig_by_code() failed with
--   ERROR 42702: column reference "gig_session_id" is ambiguous
-- Root cause: this function's RETURNS TABLE(...) declares columns named
-- gig_session_id and performer_id. In PL/pgSQL, RETURNS TABLE columns
-- become implicit variables in scope for the whole function body — so the
-- `on conflict (gig_session_id, performer_id)` target list inside the
-- insert below became ambiguous between "the gig_followers table's real
-- columns" and "this function's own out-parameters," even though every
-- other reference in the function is already correctly table-qualified.
--
-- Fix: `#variable_conflict use_column`, the standard PL/pgSQL pragma for
-- exactly this situation — tells Postgres that a bare identifier inside
-- embedded SQL should resolve to the table column, not the plpgsql
-- variable/out-parameter, whenever both exist. No other line changes;
-- the function's signature, logic, and callers are all unaffected.
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
#variable_conflict use_column
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
