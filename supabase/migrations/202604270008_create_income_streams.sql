create table if not exists public.income_streams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  amount numeric(14,2) not null,
  frequency text not null,
  next_date date not null,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint income_streams_frequency_check check (
    frequency in ('monthly', 'yearly', 'one_time')
  )
);

create index if not exists idx_income_streams_user_id_next_date
  on public.income_streams (user_id, next_date);

alter table public.income_streams enable row level security;

drop policy if exists "income_streams_select_own" on public.income_streams;
create policy "income_streams_select_own"
on public.income_streams
for select
using (auth.uid() = user_id);

drop policy if exists "income_streams_insert_own" on public.income_streams;
create policy "income_streams_insert_own"
on public.income_streams
for insert
with check (auth.uid() = user_id);

drop policy if exists "income_streams_update_own" on public.income_streams;
create policy "income_streams_update_own"
on public.income_streams
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "income_streams_delete_own" on public.income_streams;
create policy "income_streams_delete_own"
on public.income_streams
for delete
using (auth.uid() = user_id);

drop trigger if exists trg_income_streams_updated_at on public.income_streams;
create trigger trg_income_streams_updated_at
before update on public.income_streams
for each row
execute function public.set_updated_at();
