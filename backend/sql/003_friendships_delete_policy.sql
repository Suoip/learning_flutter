-- Allow unfriending: either member of a friendship may delete it.
-- Run after 002_social_friends_and_shared_notes.sql

drop policy if exists "friendships_delete_member" on public.friendships;
create policy "friendships_delete_member"
on public.friendships
for delete
using (auth.uid() = user_low_id or auth.uid() = user_high_id);
