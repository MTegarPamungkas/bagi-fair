-- Owner/member visibility that does not depend on a membership row existing yet.
--
-- The initial policies made `groups` readable only through is_group_member().
-- That meant a freshly inserted group was invisible to its own owner until the
-- matching group_members row was written, so `insert ... returning` (PostgREST
-- `Prefer: return=representation`) failed the select policy with 42501 and the
-- creator's group could vanish if the membership write was still queued
-- offline.
--
-- Reading your own group_members row does not widen visibility beyond rows that
-- already belong to you, so it is safe to add alongside is_group_member().

drop policy if exists groups_select_member on public.groups;
create policy groups_select_member on public.groups
for select to authenticated
using (owner_id = auth.uid() or public.is_group_member(id));

drop policy if exists group_members_select_member on public.group_members;
create policy group_members_select_member on public.group_members
for select to authenticated
using (user_id = auth.uid() or public.is_group_member(group_id));
