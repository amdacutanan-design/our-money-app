-- Malama Journey V4.1 stability migration
-- Safe to run more than once.

-- 1) Columns the current app expects.
alter table public.properties
  add column if not exists payment_due_day integer,
  add column if not exists payment_cutoff_time time,
  add column if not exists payment_timezone text default 'Asia/Manila';

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='properties' and column_name='due_day'
  ) then
    execute 'update public.properties set payment_due_day = due_day where payment_due_day is null and due_day is not null';
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_constraint where conname='properties_payment_due_day_check') then
    alter table public.properties add constraint properties_payment_due_day_check
      check (payment_due_day is null or payment_due_day between 1 and 31);
  end if;
end $$;

alter table public.debts
  add column if not exists payment_cutoff_time time,
  add column if not exists payment_timezone text default 'Asia/Manila',
  add column if not exists reminder_enabled boolean not null default true,
  add column if not exists reminder_days_before integer not null default 3;

do $$
begin
  if not exists (select 1 from pg_constraint where conname='debts_reminder_days_check') then
    alter table public.debts add constraint debts_reminder_days_check
      check (reminder_days_before between 0 and 30);
  end if;
end $$;

alter table public.transactions
  add column if not exists updated_by uuid references auth.users(id) on delete set null;

-- 2) Make sure authenticated app users have table privileges.
grant select, insert, update, delete on table
  public.transactions,
  public.savings_goals,
  public.savings_movements,
  public.properties,
  public.investments,
  public.debts,
  public.budgets
  to authenticated;

-- 3) Household-scoped RLS policies. These remain the actual data boundary.
alter table public.transactions enable row level security;
alter table public.savings_goals enable row level security;
alter table public.savings_movements enable row level security;
alter table public.properties enable row level security;
alter table public.investments enable row level security;
alter table public.debts enable row level security;
alter table public.budgets enable row level security;

drop policy if exists "Members manage transactions" on public.transactions;
drop policy if exists "Household members can view transactions" on public.transactions;
drop policy if exists "Household members can add transactions" on public.transactions;
drop policy if exists "Household members can update transactions" on public.transactions;
drop policy if exists "Household members can delete transactions" on public.transactions;
create policy "Household members can view transactions" on public.transactions for select to authenticated using (public.is_household_member(household_id));
create policy "Household members can add transactions" on public.transactions for insert to authenticated with check (public.is_household_member(household_id) and created_by=auth.uid());
create policy "Household members can update transactions" on public.transactions for update to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));
create policy "Household members can delete transactions" on public.transactions for delete to authenticated using (public.is_household_member(household_id));

-- Generic household policies for the other shared tables.
drop policy if exists "Members manage savings goals" on public.savings_goals;
drop policy if exists "Household members manage savings goals" on public.savings_goals;
create policy "Household members manage savings goals" on public.savings_goals for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

drop policy if exists "Members manage savings movements" on public.savings_movements;
drop policy if exists "Household members manage savings movements" on public.savings_movements;
create policy "Household members manage savings movements" on public.savings_movements for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

drop policy if exists "Members manage properties" on public.properties;
drop policy if exists "Household members manage properties" on public.properties;
create policy "Household members manage properties" on public.properties for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

drop policy if exists "Members manage investments" on public.investments;
drop policy if exists "Household members manage investments" on public.investments;
create policy "Household members manage investments" on public.investments for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

drop policy if exists "Members manage debts" on public.debts;
drop policy if exists "Household members manage debts" on public.debts;
create policy "Household members manage debts" on public.debts for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

drop policy if exists "Members manage budgets" on public.budgets;
drop policy if exists "Household members manage budgets" on public.budgets;
create policy "Household members manage budgets" on public.budgets for all to authenticated using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

-- 4) Reliable household lookup used by the app.
create or replace function public.get_my_household()
returns table (
  household_id uuid,
  household_name text,
  invite_code text,
  display_name text,
  role text
)
language sql
security definer
stable
set search_path=public
as $$
  select h.id,h.name,h.invite_code,hm.display_name,hm.role
  from public.household_members hm
  join public.households h on h.id=hm.household_id
  where hm.user_id=auth.uid()
  order by h.created_at desc
  limit 1;
$$;
revoke all on function public.get_my_household() from public;
grant execute on function public.get_my_household() to authenticated;

-- Refresh PostgREST's schema cache so new columns are usable immediately.
notify pgrst, 'reload schema';
