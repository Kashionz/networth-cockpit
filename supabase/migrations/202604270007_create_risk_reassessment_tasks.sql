create table if not exists public.risk_reassessment_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  trigger_type text not null,
  status text not null default 'pending',
  note text,
  due_at timestamptz not null,
  completed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint risk_reassessment_tasks_trigger_type_check check (
    trigger_type in ('annual', 'major_event')
  ),
  constraint risk_reassessment_tasks_status_check check (
    status in ('pending', 'overdue', 'completed')
  ),
  constraint risk_reassessment_tasks_completed_time_check check (
    completed_at is null or completed_at >= created_at
  )
);

create index if not exists idx_risk_reassessment_tasks_user_id_due_at
  on public.risk_reassessment_tasks (user_id, due_at);

create index if not exists idx_risk_reassessment_tasks_user_id_status
  on public.risk_reassessment_tasks (user_id, status);

alter table public.risk_reassessment_tasks enable row level security;

drop policy if exists "risk_reassessment_tasks_select_own" on public.risk_reassessment_tasks;
create policy "risk_reassessment_tasks_select_own"
on public.risk_reassessment_tasks
for select
using (auth.uid() = user_id);

drop policy if exists "risk_reassessment_tasks_insert_own" on public.risk_reassessment_tasks;
create policy "risk_reassessment_tasks_insert_own"
on public.risk_reassessment_tasks
for insert
with check (auth.uid() = user_id);

drop policy if exists "risk_reassessment_tasks_update_own" on public.risk_reassessment_tasks;
create policy "risk_reassessment_tasks_update_own"
on public.risk_reassessment_tasks
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "risk_reassessment_tasks_delete_own" on public.risk_reassessment_tasks;
create policy "risk_reassessment_tasks_delete_own"
on public.risk_reassessment_tasks
for delete
using (auth.uid() = user_id);

drop trigger if exists trg_risk_reassessment_tasks_updated_at on public.risk_reassessment_tasks;
create trigger trg_risk_reassessment_tasks_updated_at
before update on public.risk_reassessment_tasks
for each row
execute function public.set_updated_at();
