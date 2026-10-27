-- Account deletion support.
--
-- activities.actor_id, expenses.paid_by/created_by, notifications.actor_id and
-- settlements.from_user_id/to_user_id/created_by referenced auth.users(id)
-- without an ON DELETE action. Deleting an auth user (admin API or dashboard)
-- therefore failed with a foreign key violation as soon as that user had
-- authored anything, which also made test cleanup impossible.
--
-- These now cascade. Trade-off, recorded in DECISIONS.md: removing an account
-- also removes the rows it authored, so shared balances change for the
-- remaining members. A production app that must keep history should archive a
-- tombstone profile instead of deleting the auth user.

alter table public.activities
  drop constraint if exists activities_actor_id_fkey,
  add constraint activities_actor_id_fkey
    foreign key (actor_id) references auth.users(id) on delete cascade;

alter table public.expenses
  drop constraint if exists expenses_created_by_fkey,
  add constraint expenses_created_by_fkey
    foreign key (created_by) references auth.users(id) on delete cascade;

alter table public.expenses
  drop constraint if exists expenses_paid_by_fkey,
  add constraint expenses_paid_by_fkey
    foreign key (paid_by) references auth.users(id) on delete cascade;

alter table public.notifications
  drop constraint if exists notifications_actor_id_fkey,
  add constraint notifications_actor_id_fkey
    foreign key (actor_id) references auth.users(id) on delete cascade;

alter table public.settlements
  drop constraint if exists settlements_created_by_fkey,
  add constraint settlements_created_by_fkey
    foreign key (created_by) references auth.users(id) on delete cascade;

alter table public.settlements
  drop constraint if exists settlements_from_user_id_fkey,
  add constraint settlements_from_user_id_fkey
    foreign key (from_user_id) references auth.users(id) on delete cascade;

alter table public.settlements
  drop constraint if exists settlements_to_user_id_fkey,
  add constraint settlements_to_user_id_fkey
    foreign key (to_user_id) references auth.users(id) on delete cascade;
