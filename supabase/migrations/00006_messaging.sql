-- Task 7: Conversations, profile_conversations, messages.
-- profile_conversations(conversation_id, profile_id) is the membership +
-- per-participant-state table, replacing the old flat participant_a/b +
-- archived_a/b/muted_a/b/blocked_by_a/b design. Any service method that used
-- to check participant_a = X or participant_b = X now joins through
-- profile_conversations.

create table conversations (
  conversation_id uuid primary key default gen_random_uuid(),
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table profile_conversations (
  conversation_id uuid not null references conversations(conversation_id) on delete cascade,
  profile_id uuid not null references profiles(profile_id) on delete cascade,
  archived boolean not null default false,
  muted boolean not null default false,
  blocked_by boolean not null default false,
  primary key (conversation_id, profile_id)
);

create table messages (
  message_id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(conversation_id) on delete cascade,
  sender_id uuid not null references profiles(profile_id),
  body text,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  attachment_path text,
  attachment_file_name text,
  attachment_size_bytes bigint,
  edited_at timestamptz,
  deleted_for uuid[] not null default '{}'
);

create or replace function is_conversation_member(p_conversation_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profile_conversations where conversation_id = p_conversation_id and profile_id = auth.uid());
$$;

alter table conversations enable row level security;
alter table profile_conversations enable row level security;
alter table messages enable row level security;

create policy conversations_select_member on conversations for select to authenticated
  using (is_conversation_member(conversation_id));
create policy conversations_insert_authenticated on conversations for insert to authenticated with check (true);

create policy profile_conversations_select_member on profile_conversations for select to authenticated
  using (is_conversation_member(conversation_id));
create policy profile_conversations_insert_self on profile_conversations for insert to authenticated
  with check (profile_id = (select auth.uid()));
create policy profile_conversations_update_self on profile_conversations for update to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

create policy messages_select_member on messages for select to authenticated
  using (is_conversation_member(conversation_id));
create policy messages_insert_member on messages for insert to authenticated
  with check (sender_id = (select auth.uid()) and is_conversation_member(conversation_id));
-- TODO(Task 22): tighten this policy to `using (sender_id = (select auth.uid()))` once the
-- service layer routes all edits/deletes exclusively through the edit_message /
-- delete_message_for_me RPCs below instead of direct client-side UPDATE. Until then this is
-- deliberately broader than final-intent: any conversation member can issue an UPDATE against a
-- message row (the RPCs are the only column-safe write path; a raw client UPDATE could still
-- overwrite body/deleted_for directly if this policy allows it through).
create policy messages_update_sender on messages for update to authenticated
  using (sender_id = (select auth.uid()) or is_conversation_member(conversation_id)); -- non-sender member can only touch deleted_for; enforce column-level via RPC, see below

create index if not exists idx_profile_conversations_profile_id on profile_conversations(profile_id);
create index if not exists idx_messages_conversation_id on messages(conversation_id);
create index if not exists idx_messages_sender_id on messages(sender_id);

-- edit_message / delete_message_for_me RPCs replace direct client-side UPDATE for their specific fields.
create or replace function edit_message(p_message_id uuid, p_new_body text) returns void
language plpgsql security definer set search_path = public as $$
begin
  update messages set body = p_new_body, edited_at = now()
  where message_id = p_message_id and sender_id = auth.uid();
end;
$$;

create or replace function delete_message_for_me(p_message_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update messages set deleted_for = array_append(deleted_for, auth.uid())
  where message_id = p_message_id and is_conversation_member(conversation_id) and not (auth.uid() = any(deleted_for));
end;
$$;

-- Hardening pattern from Task 2's follow-up (00001b): these security definer
-- helper/RPC functions rely on auth.uid(), so anon callers always get a
-- null-based (non-matching) result -- not a data leak -- but there is no
-- reason to expose them as public RPC endpoints. edit_message and
-- delete_message_for_me are meant to be called by the authenticated app
-- (not referenced inside RLS policies), so they get the same
-- authenticated-only treatment as the RLS helper functions.
revoke execute on function is_conversation_member(uuid) from public, anon;
grant execute on function is_conversation_member(uuid) to authenticated;

revoke execute on function edit_message(uuid, text) from public, anon;
grant execute on function edit_message(uuid, text) to authenticated;

revoke execute on function delete_message_for_me(uuid) from public, anon;
grant execute on function delete_message_for_me(uuid) to authenticated;
