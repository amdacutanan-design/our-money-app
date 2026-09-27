-- Malama Journey V3 add-on: synced budgets
create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  category text not null,
  monthly_limit numeric(14,2) not null default 0 check (monthly_limit >= 0),
  owner_name text not null default 'Shared',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_budgets_updated on public.budgets;
create trigger trg_budgets_updated
before update on public.budgets
for each row execute function public.set_updated_at();

alter table public.budgets enable row level security;

drop policy if exists "Members manage budgets" on public.budgets;
create policy "Members manage budgets"
on public.budgets
for all
to authenticated
using (public.is_household_member(household_id))
with check (
  public.is_household_member(household_id)
  and created_by = auth.uid()
);

-- Enable realtime for shared household changes.
do $$
declare t text;
begin
  foreach t in array array['transactions','savings_goals','savings_movements','properties','investments','debts','budgets','household_members']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname='supabase_realtime' and schemaname='public' and tablename=t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
