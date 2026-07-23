-- Redesigns shared_notes from one-row-per-recipient to one-row-per-published-note,
-- with a new shared_note_recipients join table, so likes/comments aggregate across
-- all recipients instead of being fragmented per recipient copy, and the author can
-- see engagement on their own published notes (the feed query previously only ever
-- looked up rows where the current user was the recipient, never the author).
-- Run after 002_social_friends_and_shared_notes.sql and 003_friendships_delete_policy.sql
--
-- WARNING: destructive. Drops and recreates shared_notes, shared_note_likes, and
-- shared_note_comments together - any existing published notes, likes, and comments
-- are lost. (All three must be dropped together, not just shared_notes: dropping only
-- the parent table would leave the other two referencing a table that no longer
-- exists in its old shape, orphaning their rows and losing the foreign key entirely
-- once shared_notes is recreated.) notes, profiles, friend_requests, and friendships
-- are untouched.

drop table if exists public.shared_note_comments cascade;
drop table if exists public.shared_note_likes cascade;
drop table if exists public.shared_note_recipients cascade;
drop table if exists public.shared_notes cascade;

create table public.shared_notes (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.notes(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  published_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (note_id, author_id)
);

create table public.shared_note_recipients (
  shared_note_id uuid not null references public.shared_notes(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (shared_note_id, recipient_id)
);

create table public.shared_note_likes (
  shared_note_id uuid not null references public.shared_notes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (shared_note_id, user_id)
);

create table public.shared_note_comments (
  id uuid primary key default gen_random_uuid(),
  shared_note_id uuid not null references public.shared_notes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  created_at timestamptz not null default now()
);

create index shared_notes_author_published_idx
  on public.shared_notes (author_id, published_at desc);

create index shared_note_recipients_recipient_idx
  on public.shared_note_recipients (recipient_id);

create index shared_note_comments_shared_note_created_idx
  on public.shared_note_comments (shared_note_id, created_at asc);

drop trigger if exists trg_shared_notes_set_updated_at on public.shared_notes;
create trigger trg_shared_notes_set_updated_at
before update on public.shared_notes
for each row execute function public.set_updated_at();

alter table public.shared_notes enable row level security;
alter table public.shared_note_recipients enable row level security;
alter table public.shared_note_likes enable row level security;
alter table public.shared_note_comments enable row level security;

create policy "shared_notes_select_member"
on public.shared_notes
for select
using (
  auth.uid() = author_id
  or exists (
    select 1
    from public.shared_note_recipients r
    where r.shared_note_id = shared_notes.id
      and r.recipient_id = auth.uid()
  )
);

create policy "shared_notes_insert_author"
on public.shared_notes
for insert
with check (auth.uid() = author_id);

create policy "shared_notes_update_author"
on public.shared_notes
for update
using (auth.uid() = author_id)
with check (auth.uid() = author_id);

create policy "shared_notes_delete_author"
on public.shared_notes
for delete
using (auth.uid() = author_id);

-- SECURITY DEFINER helper so the SELECT policy below can check "is this user
-- the author of this shared_note" without querying shared_notes directly -
-- doing that inline would make this policy subquery shared_notes, whose own
-- policy subqueries this table right back, the textbook trigger for
-- Postgres's "infinite recursion detected in policy" error. A
-- SECURITY DEFINER function runs with its owner's privileges (the migration
-- author, e.g. via the SQL editor), which bypasses shared_notes' RLS for this
-- one internal lookup, sidestepping the cycle rather than working around it.
create or replace function public.is_shared_note_author(
  p_shared_note_id uuid,
  p_user_id uuid
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.shared_notes sn
    where sn.id = p_shared_note_id and sn.author_id = p_user_id
  );
$$;

-- Recipients can see their own row. Authors can also see recipient rows for
-- notes they authored - this isn't just a UI convenience, it's required for
-- publishing to work at all: Postgres checks a row's SELECT visibility when
-- an INSERT/upsert needs to return or resolve conflicts on it, so without
-- this branch the author's own insert of *someone else's* recipient row
-- would satisfy the INSERT policy's WITH CHECK but still be rejected with
-- "new row violates row-level security policy", because the inserting user
-- couldn't see the row back. Confirmed by direct REST reproduction: inserting
-- a recipient row naming the current user succeeded, but naming anyone else
-- failed identically regardless of who they were (a real friend or a garbage
-- id) or whether a representation was even requested back - proving the
-- INSERT check itself was never the problem.
create policy "shared_note_recipients_select_recipient"
on public.shared_note_recipients
for select
using (
  auth.uid() = recipient_id
  or public.is_shared_note_author(shared_note_id, auth.uid())
);

-- Only the note's author can add recipients. (An earlier version of this
-- policy also tried to check the recipient is an actual current friend of
-- the author, as defense in depth against a client bypassing the app's own
-- fetchFriends()-driven recipient list. Removed after diagnosis showed the
-- real bug was the missing SELECT-visibility branch above, not this check -
-- it's still a reasonable hardening to reintroduce later, just not while
-- still isolating the actual bug.)
create policy "shared_note_recipients_insert_author"
on public.shared_note_recipients
for insert
with check (
  exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_recipients.shared_note_id
      and sn.author_id = auth.uid()
  )
);

-- Both correlation conditions below (matching shared_note_id AND recipient_id)
-- are required - dropping the shared_note_id match would degrade this into "any
-- recipient of any note can see/like/comment on every note," not a subtle bug.
create policy "shared_note_likes_select_visible"
on public.shared_note_likes
for select
using (
  exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_likes.shared_note_id
      and (
        sn.author_id = auth.uid()
        or exists (
          select 1
          from public.shared_note_recipients r
          where r.shared_note_id = sn.id
            and r.recipient_id = auth.uid()
        )
      )
  )
);

create policy "shared_note_likes_insert_self"
on public.shared_note_likes
for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_likes.shared_note_id
      and (
        sn.author_id = auth.uid()
        or exists (
          select 1
          from public.shared_note_recipients r
          where r.shared_note_id = sn.id
            and r.recipient_id = auth.uid()
        )
      )
  )
);

create policy "shared_note_likes_delete_self"
on public.shared_note_likes
for delete
using (auth.uid() = user_id);

create policy "shared_note_comments_select_visible"
on public.shared_note_comments
for select
using (
  exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_comments.shared_note_id
      and (
        sn.author_id = auth.uid()
        or exists (
          select 1
          from public.shared_note_recipients r
          where r.shared_note_id = sn.id
            and r.recipient_id = auth.uid()
        )
      )
  )
);

create policy "shared_note_comments_insert_self"
on public.shared_note_comments
for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_comments.shared_note_id
      and (
        sn.author_id = auth.uid()
        or exists (
          select 1
          from public.shared_note_recipients r
          where r.shared_note_id = sn.id
            and r.recipient_id = auth.uid()
        )
      )
  )
);

create policy "shared_note_comments_update_self"
on public.shared_note_comments
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "shared_note_comments_delete_self"
on public.shared_note_comments
for delete
using (auth.uid() = user_id);
