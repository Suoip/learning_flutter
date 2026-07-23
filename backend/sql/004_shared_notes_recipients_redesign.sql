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

-- Deliberately recipient-only, with no "author can also read recipients" branch:
-- adding one would make this policy subquery shared_notes, whose own policy above
-- subqueries this table right back - the textbook trigger for Postgres's
-- "infinite recursion detected in policy" error. No current feature needs the
-- author to list who a note was shared with, so this sidesteps the cycle rather
-- than working around it after the fact.
create policy "shared_note_recipients_select_recipient"
on public.shared_note_recipients
for select
using (auth.uid() = recipient_id);

-- Beyond "only the note's author can add recipients", this also checks the
-- recipient is an actual current friend of the author - defense in depth against
-- a client bypassing the app's own fetchFriends()-driven recipient list and
-- naming an arbitrary user id directly.
create policy "shared_note_recipients_insert_author"
on public.shared_note_recipients
for insert
with check (
  exists (
    select 1
    from public.shared_notes sn
    where sn.id = shared_note_recipients.shared_note_id
      and sn.author_id = auth.uid()
      and exists (
        select 1
        from public.friendships f
        where f.user_low_id = least(sn.author_id, shared_note_recipients.recipient_id)
          and f.user_high_id = greatest(sn.author_id, shared_note_recipients.recipient_id)
      )
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
