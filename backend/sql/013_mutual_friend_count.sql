-- Returns how many friends auth.uid() has in common with p_other_user_id,
-- without exposing either party's friend list or identities to the caller.
-- SECURITY DEFINER is required because friendships RLS (see
-- 002_social_friends_and_shared_notes.sql's friendships_select_member) only
-- lets a user see rows where they themselves are a party - this function
-- must read p_other_user_id's friendship rows too, which normal RLS would
-- block. Called directly via RPC from client code (never from inside
-- another table's own policy), so this is not at risk of the
-- is_shared_note_author-style "infinite recursion detected in policy" trap -
-- just don't ever reference this function from within a friendships policy.
--
-- Single-argument, called once per non-friend row in the "liked by" list -
-- not batched. At this app's scale a liked-by list has a handful of rows, so
-- N small round-trips is a non-issue, and a scalar function is far simpler
-- to review/reuse than an array+unnest batched version would be.

create or replace function public.mutual_friend_count(p_other_user_id uuid)
returns integer
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::integer
  from (
    select case when f1.user_low_id = auth.uid()
                then f1.user_high_id else f1.user_low_id end as friend_id
    from public.friendships f1
    where f1.user_low_id = auth.uid() or f1.user_high_id = auth.uid()
  ) mine
  join (
    select case when f2.user_low_id = p_other_user_id
                then f2.user_high_id else f2.user_low_id end as friend_id
    from public.friendships f2
    where f2.user_low_id = p_other_user_id or f2.user_high_id = p_other_user_id
  ) theirs
  using (friend_id);
$$;

grant execute on function public.mutual_friend_count(uuid) to authenticated;
-- Deliberately no grant to anon: mutual-friend counts about a logged-in
-- user's social graph shouldn't be computable by unauthenticated callers.
