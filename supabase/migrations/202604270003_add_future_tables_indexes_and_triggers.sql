create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  reason text,
  status text not null default 'pending',
  requested_at timestamptz not null default timezone('utc', now()),
  processed_at timestamptz,
  processed_by uuid references auth.users (id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint account_deletion_requests_status_check check (
    status in ('pending', 'approved', 'rejected', 'completed', 'cancelled')
  ),
  constraint account_deletion_requests_processed_time_check check (
    processed_at is null or processed_at >= requested_at
  )
);

create table if not exists public.job_definitions (
  id uuid primary key default gen_random_uuid(),
  job_name text not null unique,
  job_type text not null,
  schedule text,
  handler text not null,
  is_active boolean not null default true,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.job_runs (
  id uuid primary key default gen_random_uuid(),
  job_definition_id uuid not null references public.job_definitions (id) on delete cascade,
  initiated_by_user_id uuid references auth.users (id) on delete set null,
  requested_by text not null default 'system',
  status text not null default 'queued',
  started_at timestamptz,
  finished_at timestamptz,
  error_message text,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint job_runs_status_check check (
    status in ('queued', 'running', 'succeeded', 'failed', 'cancelled')
  ),
  constraint job_runs_time_range_check check (
    finished_at is null or started_at is null or finished_at >= started_at
  )
);

create index if not exists idx_prices_daily_price_date
  on public.prices_daily (price_date desc);

create index if not exists idx_assets_user_id
  on public.assets (user_id);

create index if not exists idx_assets_user_id_symbol
  on public.assets (user_id, symbol);

create index if not exists idx_accounts_user_id
  on public.accounts (user_id);

create index if not exists idx_accounts_user_id_is_active
  on public.accounts (user_id, is_active);

create index if not exists idx_holdings_user_id
  on public.holdings (user_id);

create index if not exists idx_holdings_asset_id
  on public.holdings (asset_id);

create index if not exists idx_credit_cards_user_id
  on public.credit_cards (user_id);

create index if not exists idx_credit_cards_account_id
  on public.credit_cards (account_id);

create index if not exists idx_card_statements_user_id_due_date
  on public.card_statements (user_id, due_date);

create index if not exists idx_transactions_user_id_occurred_at
  on public.transactions (user_id, occurred_at desc);

create index if not exists idx_transactions_account_id_occurred_at
  on public.transactions (account_id, occurred_at desc);

create index if not exists idx_transactions_credit_card_id_occurred_at
  on public.transactions (credit_card_id, occurred_at desc);

create index if not exists idx_transactions_card_statement_id
  on public.transactions (card_statement_id);

create index if not exists idx_transactions_asset_id
  on public.transactions (asset_id);

create index if not exists idx_subscriptions_user_id
  on public.subscriptions (user_id);

create index if not exists idx_subscriptions_active_next_billing
  on public.subscriptions (user_id, next_billing_date)
  where is_active = true;

create index if not exists idx_monthly_budgets_user_id_budget_month
  on public.monthly_budgets (user_id, budget_month desc);

create index if not exists idx_target_allocations_user_id_effective_from
  on public.target_allocations (user_id, effective_from desc);

create index if not exists idx_portfolio_snapshots_user_id_snapshot_date
  on public.portfolio_snapshots (user_id, snapshot_date desc);

create index if not exists idx_insights_user_id_snapshot_date
  on public.insights (user_id, snapshot_date desc);

create index if not exists idx_insights_user_id_insight_type
  on public.insights (user_id, insight_type);

create index if not exists idx_account_deletion_requests_user_id_requested_at
  on public.account_deletion_requests (user_id, requested_at desc);

create unique index if not exists idx_account_deletion_requests_pending_unique
  on public.account_deletion_requests (user_id)
  where status = 'pending';

create index if not exists idx_job_definitions_is_active
  on public.job_definitions (is_active);

create index if not exists idx_job_runs_job_definition_id_created_at
  on public.job_runs (job_definition_id, created_at desc);

create index if not exists idx_job_runs_status_created_at
  on public.job_runs (status, created_at desc);

create index if not exists idx_job_runs_initiated_by_user_id
  on public.job_runs (initiated_by_user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_assets_updated_at on public.assets;
create trigger trg_assets_updated_at
before update on public.assets
for each row
execute function public.set_updated_at();

drop trigger if exists trg_accounts_updated_at on public.accounts;
create trigger trg_accounts_updated_at
before update on public.accounts
for each row
execute function public.set_updated_at();

drop trigger if exists trg_holdings_updated_at on public.holdings;
create trigger trg_holdings_updated_at
before update on public.holdings
for each row
execute function public.set_updated_at();

drop trigger if exists trg_credit_cards_updated_at on public.credit_cards;
create trigger trg_credit_cards_updated_at
before update on public.credit_cards
for each row
execute function public.set_updated_at();

drop trigger if exists trg_card_statements_updated_at on public.card_statements;
create trigger trg_card_statements_updated_at
before update on public.card_statements
for each row
execute function public.set_updated_at();

drop trigger if exists trg_transactions_updated_at on public.transactions;
create trigger trg_transactions_updated_at
before update on public.transactions
for each row
execute function public.set_updated_at();

drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at
before update on public.subscriptions
for each row
execute function public.set_updated_at();

drop trigger if exists trg_monthly_budgets_updated_at on public.monthly_budgets;
create trigger trg_monthly_budgets_updated_at
before update on public.monthly_budgets
for each row
execute function public.set_updated_at();

drop trigger if exists trg_target_allocations_updated_at on public.target_allocations;
create trigger trg_target_allocations_updated_at
before update on public.target_allocations
for each row
execute function public.set_updated_at();

drop trigger if exists trg_portfolio_snapshots_updated_at on public.portfolio_snapshots;
create trigger trg_portfolio_snapshots_updated_at
before update on public.portfolio_snapshots
for each row
execute function public.set_updated_at();

drop trigger if exists trg_account_deletion_requests_updated_at on public.account_deletion_requests;
create trigger trg_account_deletion_requests_updated_at
before update on public.account_deletion_requests
for each row
execute function public.set_updated_at();

drop trigger if exists trg_job_definitions_updated_at on public.job_definitions;
create trigger trg_job_definitions_updated_at
before update on public.job_definitions
for each row
execute function public.set_updated_at();

drop trigger if exists trg_job_runs_updated_at on public.job_runs;
create trigger trg_job_runs_updated_at
before update on public.job_runs
for each row
execute function public.set_updated_at();
