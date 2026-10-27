-- Bagi Fair — initial schema, RLS, realtime, storage and RPCs.
-- Apply with: supabase db push   (or paste into the Supabase SQL editor)

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Safe path -> group id parsing for storage policies.
create or replace function public.storage_path_group(p_name text)
returns uuid
language sql
immutable
as $$
  select case
    when split_part(p_name, '/', 1) ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      then split_path.uuid
    else null
  end
  from (select split_part(p_name, '/', 1)::uuid as uuid) as split_path;
$$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key default auth.uid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  display_name text not null default 'Pengguna',
  email text not null default '',
  avatar_url text,
  default_currency text not null default 'IDR',
  locale text not null default 'id',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id)
);

create table if not exists public.groups (
  id uuid primary key,
  name text not null,
  description text not null default '',
  emoji text not null default '🍕',
  type text not null default 'other' check (type in ('trip', 'kos', 'hangout', 'other')),
  currency text not null default 'IDR',
  owner_id uuid not null references auth.users(id) on delete cascade,
  archived boolean not null default false,
  member_count integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.group_members (
  id uuid primary key,
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default 'Teman',
  email text not null default '',
  avatar_url text,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (group_id, user_id)
);

create table if not exists public.group_invites (
  code text primary key,
  group_id uuid not null references public.groups(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days')
);

create table if not exists public.receipts (
  id uuid primary key,
  group_id uuid not null references public.groups(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  merchant text not null default '',
  currency text not null default 'IDR',
  items jsonb not null default '[]'::jsonb,
  subtotal_minor bigint not null default 0,
  tax_minor bigint not null default 0,
  service_minor bigint not null default 0,
  total_minor bigint not null default 0,
  raw_text text not null default '',
  image_url text,
  occurred_at timestamptz not null default now(),
  status text not null default 'draft' check (status in ('draft', 'reviewed', 'saved')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.expenses (
  id uuid primary key,
  group_id uuid not null references public.groups(id) on delete cascade,
  title text not null,
  category text not null default 'other',
  amount_minor bigint not null default 0,
  amount_base_minor bigint not null default 0,
  currency text not null default 'IDR',
  fx_rate numeric(18, 8) not null default 1,
  paid_by uuid not null references auth.users(id),
  split_mode text not null default 'equal' check (split_mode in ('equal', 'percentage', 'exact', 'itemized')),
  note text not null default '',
  occurred_at timestamptz not null default now(),
  items jsonb not null default '[]'::jsonb,
  shares jsonb not null default '[]'::jsonb,
  tax_minor bigint not null default 0,
  service_minor bigint not null default 0,
  discount_minor bigint not null default 0,
  receipt_id uuid references public.receipts(id) on delete set null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.settlements (
  id uuid primary key,
  group_id uuid not null references public.groups(id) on delete cascade,
  from_user_id uuid not null references auth.users(id),
  to_user_id uuid not null references auth.users(id),
  amount_minor bigint not null default 0,
  currency text not null default 'IDR',
  note text not null default '',
  settled_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.activities (
  id uuid primary key,
  group_id uuid not null references public.groups(id) on delete cascade,
  actor_id uuid not null references auth.users(id),
  actor_name text not null default 'Teman',
  kind text not null default 'group_updated',
  summary text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.notifications (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  group_id uuid references public.groups(id) on delete cascade,
  actor_id uuid references auth.users(id),
  actor_name text not null default '',
  kind text not null default 'reminder',
  title text not null default '',
  body text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- AI quota ledger: only service_role touches this table.
create table if not exists public.ai_usage (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Membership helpers
-- Defined after the tables because SQL function bodies are validated at
-- creation time, so they cannot reference group_members/groups before those
-- relations exist.
-- ---------------------------------------------------------------------------

-- Security definer so RLS policies on group_members can be evaluated without
-- recursing into the same table's policies.
create or replace function public.is_group_member(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id = auth.uid()
      and gm.deleted_at is null
  );
$$;

create or replace function public.is_group_owner(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.groups g
    where g.id = p_group_id
      and g.owner_id = auth.uid()
      and g.deleted_at is null
  );
$$;

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index if not exists groups_updated_idx on public.groups (updated_at);
create index if not exists group_members_group_idx on public.group_members (group_id, joined_at);
create index if not exists group_members_user_idx on public.group_members (user_id);
create index if not exists group_members_updated_idx on public.group_members (updated_at);
create index if not exists group_invites_group_idx on public.group_invites (group_id);
create index if not exists expenses_group_idx on public.expenses (group_id, occurred_at desc);
create index if not exists expenses_updated_idx on public.expenses (updated_at);
create index if not exists settlements_group_idx on public.settlements (group_id, settled_at desc);
create index if not exists settlements_updated_idx on public.settlements (updated_at);
create index if not exists activities_group_idx on public.activities (group_id, created_at desc);
create index if not exists activities_updated_idx on public.activities (updated_at);
create index if not exists receipts_group_idx on public.receipts (group_id, occurred_at desc);
create index if not exists receipts_updated_idx on public.receipts (updated_at);
create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications (user_id) where read_at is null;
create index if not exists notifications_updated_idx on public.notifications (updated_at);
create index if not exists ai_usage_user_idx on public.ai_usage (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists groups_set_updated_at on public.groups;
create trigger groups_set_updated_at before update on public.groups
for each row execute function public.set_updated_at();

drop trigger if exists group_members_set_updated_at on public.group_members;
create trigger group_members_set_updated_at before update on public.group_members
for each row execute function public.set_updated_at();

drop trigger if exists receipts_set_updated_at on public.receipts;
create trigger receipts_set_updated_at before update on public.receipts
for each row execute function public.set_updated_at();

drop trigger if exists expenses_set_updated_at on public.expenses;
create trigger expenses_set_updated_at before update on public.expenses
for each row execute function public.set_updated_at();

drop trigger if exists settlements_set_updated_at on public.settlements;
create trigger settlements_set_updated_at before update on public.settlements
for each row execute function public.set_updated_at();

drop trigger if exists activities_set_updated_at on public.activities;
create trigger activities_set_updated_at before update on public.activities
for each row execute function public.set_updated_at();

drop trigger if exists notifications_set_updated_at on public.notifications;
create trigger notifications_set_updated_at before update on public.notifications
for each row execute function public.set_updated_at();

-- Keep groups.member_count in sync with active membership.
create or replace function public.sync_member_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_group uuid;
begin
  target_group := coalesce(new.group_id, old.group_id);
  update public.groups g
  set member_count = (
    select count(*)::int
    from public.group_members m
    where m.group_id = target_group
      and m.deleted_at is null
  )
  where g.id = target_group;
  return coalesce(new, old);
end;
$$;

drop trigger if exists group_members_sync_count on public.group_members;
create trigger group_members_sync_count
after insert or update of deleted_at or delete on public.group_members
for each row execute function public.sync_member_count();

-- New auth users get a profile row (also works for Google sign-in).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, user_id, display_name, email, avatar_url)
  values (
    new.id,
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      split_part(coalesce(new.email, 'Pengguna'), '@', 1)
    ),
    coalesce(new.email, ''),
    nullif(new.raw_user_meta_data ->> 'avatar_url', '')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_invites enable row level security;
alter table public.expenses enable row level security;
alter table public.settlements enable row level security;
alter table public.activities enable row level security;
alter table public.receipts enable row level security;
alter table public.notifications enable row level security;
alter table public.ai_usage enable row level security;

-- profiles ------------------------------------------------------------------
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select to authenticated using (user_id = auth.uid());

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
for insert to authenticated with check (user_id = auth.uid() and id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- groups --------------------------------------------------------------------
drop policy if exists groups_select_member on public.groups;
create policy groups_select_member on public.groups
for select to authenticated using (public.is_group_member(id));

drop policy if exists groups_insert_owner on public.groups;
create policy groups_insert_owner on public.groups
for insert to authenticated with check (owner_id = auth.uid());

drop policy if exists groups_update_member on public.groups;
create policy groups_update_member on public.groups
for update to authenticated
using (public.is_group_member(id))
with check (public.is_group_member(id));

drop policy if exists groups_delete_owner on public.groups;
create policy groups_delete_owner on public.groups
for delete to authenticated using (owner_id = auth.uid());

-- group_members -------------------------------------------------------------
drop policy if exists group_members_select_member on public.group_members;
create policy group_members_select_member on public.group_members
for select to authenticated using (public.is_group_member(group_id));

drop policy if exists group_members_insert_self on public.group_members;
create policy group_members_insert_self on public.group_members
for insert to authenticated
with check (user_id = auth.uid() and public.is_group_owner(group_id));

drop policy if exists group_members_update_self_or_owner on public.group_members;
create policy group_members_update_self_or_owner on public.group_members
for update to authenticated
using (user_id = auth.uid() or public.is_group_owner(group_id))
with check (user_id = auth.uid() or public.is_group_owner(group_id));

drop policy if exists group_members_delete_self_or_owner on public.group_members;
create policy group_members_delete_self_or_owner on public.group_members
for delete to authenticated
using (user_id = auth.uid() or public.is_group_owner(group_id));

-- group_invites -------------------------------------------------------------
drop policy if exists group_invites_select_member on public.group_invites;
create policy group_invites_select_member on public.group_invites
for select to authenticated using (public.is_group_member(group_id));

drop policy if exists group_invites_insert_member on public.group_invites;
create policy group_invites_insert_member on public.group_invites
for insert to authenticated
with check (created_by = auth.uid() and public.is_group_member(group_id));

-- receipts ------------------------------------------------------------------
drop policy if exists receipts_select_member on public.receipts;
create policy receipts_select_member on public.receipts
for select to authenticated using (public.is_group_member(group_id));

drop policy if exists receipts_insert_member on public.receipts;
create policy receipts_insert_member on public.receipts
for insert to authenticated
with check (created_by = auth.uid() and public.is_group_member(group_id));

drop policy if exists receipts_update_member on public.receipts;
create policy receipts_update_member on public.receipts
for update to authenticated
using (public.is_group_member(group_id))
with check (public.is_group_member(group_id));

drop policy if exists receipts_delete_member on public.receipts;
create policy receipts_delete_member on public.receipts
for delete to authenticated using (public.is_group_member(group_id));

-- expenses ------------------------------------------------------------------
drop policy if exists expenses_select_member on public.expenses;
create policy expenses_select_member on public.expenses
for select to authenticated using (public.is_group_member(group_id));

drop policy if exists expenses_insert_member on public.expenses;
create policy expenses_insert_member on public.expenses
for insert to authenticated
with check (created_by = auth.uid() and public.is_group_member(group_id));

drop policy if exists expenses_update_member on public.expenses;
create policy expenses_update_member on public.expenses
for update to authenticated
using (public.is_group_member(group_id))
with check (public.is_group_member(group_id));

drop policy if exists expenses_delete_member on public.expenses;
create policy expenses_delete_member on public.expenses
for delete to authenticated using (public.is_group_member(group_id));

-- settlements ---------------------------------------------------------------
drop policy if exists settlements_select_member on public.settlements;
create policy settlements_select_member on public.settlements
for select to authenticated using (public.is_group_member(group_id));

drop policy if exists settlements_insert_member on public.settlements;
create policy settlements_insert_member on public.settlements
for insert to authenticated
with check (created_by = auth.uid() and public.is_group_member(group_id));

drop policy if exists settlements_update_member on public.settlements;
create policy settlements_update_member on public.settlements
for update to authenticated
using (public.is_group_member(group_id))
with check (public.is_group_member(group_id));

drop policy if exists settlements_delete_member on public.settlements;
create policy settlements_delete_member on public.settlements
for delete to authenticated using (public.is_group_member(group_id));

-- activities ----------------------------------------------------------------
drop policy if exists activities_select_member on public.activities;
create policy activities_select_member on public.activities
for select to authenticated using (public.is_group_member(group_id));

drop policy if exists activities_insert_member on public.activities;
create policy activities_insert_member on public.activities
for insert to authenticated
with check (actor_id = auth.uid() and public.is_group_member(group_id));

-- notifications -------------------------------------------------------------
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
for select to authenticated using (user_id = auth.uid());

drop policy if exists notifications_insert_member on public.notifications;
create policy notifications_insert_member on public.notifications
for insert to authenticated
with check (
  actor_id = auth.uid()
  and public.is_group_member(group_id)
  and exists (
    select 1
    from public.group_members gm
    where gm.group_id = notifications.group_id
      and gm.user_id = notifications.user_id
      and gm.deleted_at is null
  )
);

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists notifications_delete_own on public.notifications;
create policy notifications_delete_own on public.notifications
for delete to authenticated using (user_id = auth.uid());

-- ai_usage has RLS enabled and no policies: clients cannot read or write it.

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------

create or replace function public.create_group_invite(p_group_id uuid, p_days integer default 7)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  new_code text;
  attempt integer := 0;
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
begin
  if auth.uid() is null then
    raise exception 'not_signed_in';
  end if;
  if not public.is_group_member(p_group_id) then
    raise exception 'not_a_member';
  end if;

  loop
    attempt := attempt + 1;
    select string_agg(substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1), '')
      into new_code
      from generate_series(1, 7);
    begin
      insert into public.group_invites (code, group_id, created_by, expires_at)
      values (
        new_code,
        p_group_id,
        auth.uid(),
        now() + make_interval(days => greatest(1, least(p_days, 30)))
      );
      return new_code;
    exception when unique_violation then
      if attempt > 8 then
        raise exception 'invite_generation_failed';
      end if;
    end;
  end loop;
end;
$$;

create or replace function public.join_group_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  invite public.group_invites%rowtype;
  existing public.group_members%rowtype;
  existing_found boolean := false;
  profile public.profiles%rowtype;
  display text;
begin
  if auth.uid() is null then
    raise exception 'not_signed_in';
  end if;

  select * into invite
  from public.group_invites
  where upper(code) = upper(trim(p_code));

  if not found then
    raise exception 'invite_not_found';
  end if;
  if invite.expires_at < now() then
    raise exception 'invite_expired';
  end if;

  select * into existing
  from public.group_members
  where group_id = invite.group_id and user_id = auth.uid();
  -- Capture this before the profile lookup below reuses `found`.
  existing_found := found;

  if existing_found and existing.deleted_at is null then
    return invite.group_id;
  end if;

  select * into profile from public.profiles where user_id = auth.uid();
  display := coalesce(
    nullif(profile.display_name, ''),
    split_part(coalesce(auth.jwt() ->> 'email', 'Teman'), '@', 1)
  );

  if existing_found then
    update public.group_members
    set deleted_at = null, display_name = display, updated_at = now()
    where id = existing.id;
  else
    insert into public.group_members (id, group_id, user_id, display_name, email, avatar_url, role)
    values (
      gen_random_uuid(),
      invite.group_id,
      auth.uid(),
      display,
      coalesce(profile.email, auth.jwt() ->> 'email', ''),
      profile.avatar_url,
      'member'
    );
  end if;

  insert into public.activities (id, group_id, actor_id, actor_name, kind, summary)
  values (gen_random_uuid(), invite.group_id, auth.uid(), display, 'member_joined', 'bergabung ke grup');

  return invite.group_id;
end;
$$;

-- Called only by the scan-receipt Edge Function with the service role key.
create or replace function public.claim_ai_scan(p_user_id uuid, p_limit integer default 10)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  used integer;
  retry integer;
begin
  if p_user_id is null then
    return jsonb_build_object('allowed', false, 'retry_after_seconds', 3600);
  end if;

  -- Serialise claims per user so two parallel scans cannot both slip under the
  -- limit just before the insert.
  perform pg_advisory_xact_lock(hashtext(p_user_id::text));

  delete from public.ai_usage where created_at < now() - interval '2 days';

  select count(*)::int into used
  from public.ai_usage
  where user_id = p_user_id and created_at > now() - interval '1 hour';

  if used >= p_limit then
    select greatest(
      1,
      ceil(extract(epoch from (min(created_at) + interval '1 hour' - now())))
    )::int
    into retry
    from public.ai_usage
    where user_id = p_user_id and created_at > now() - interval '1 hour';

    return jsonb_build_object(
      'allowed', false,
      'used', used,
      'retry_after_seconds', coalesce(retry, 3600)
    );
  end if;

  insert into public.ai_usage (user_id) values (p_user_id);

  return jsonb_build_object('allowed', true, 'used', used + 1, 'limit', p_limit);
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

grant usage on schema public to anon, authenticated, service_role;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant all on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;
grant execute on function public.is_group_member(uuid) to authenticated;
grant execute on function public.is_group_owner(uuid) to authenticated;
grant execute on function public.storage_path_group(text) to authenticated;
grant execute on function public.create_group_invite(uuid, integer) to authenticated;
grant execute on function public.join_group_by_code(text) to authenticated;
revoke all on function public.claim_ai_scan(uuid, integer) from public, anon, authenticated;
grant execute on function public.claim_ai_scan(uuid, integer) to service_role;

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'groups',
    'group_members',
    'expenses',
    'settlements',
    'activities',
    'receipts',
    'notifications'
  ] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    exception
      when duplicate_object then null;
      when undefined_object then null;
    end;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Storage: private receipts bucket
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipts',
  'receipts',
  false,
  6291456,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update
set public = false,
    file_size_limit = 6291456,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

drop policy if exists receipts_storage_read on storage.objects;
create policy receipts_storage_read on storage.objects
for select to authenticated
using (
  bucket_id = 'receipts'
  and public.is_group_member(public.storage_path_group(name))
);

drop policy if exists receipts_storage_insert on storage.objects;
create policy receipts_storage_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'receipts'
  and split_part(name, '/', 2) = auth.uid()::text
  and public.is_group_member(public.storage_path_group(name))
);

drop policy if exists receipts_storage_update on storage.objects;
create policy receipts_storage_update on storage.objects
for update to authenticated
using (
  bucket_id = 'receipts'
  and public.is_group_member(public.storage_path_group(name))
)
with check (
  bucket_id = 'receipts'
  and split_part(name, '/', 2) = auth.uid()::text
  and public.is_group_member(public.storage_path_group(name))
);

drop policy if exists receipts_storage_delete on storage.objects;
create policy receipts_storage_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'receipts'
  and public.is_group_member(public.storage_path_group(name))
);
