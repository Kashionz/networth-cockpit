create extension if not exists pgcrypto with schema extensions;

create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  symbol text not null,
  name text not null,
  asset_type text not null,
  market text not null default 'GLOBAL',
  currency_code text not null default 'USD',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint assets_symbol_market_asset_type_currency_code_key unique (user_id, symbol, market, asset_type, currency_code)
);

create table if not exists public.prices_daily (
  asset_id uuid not null references public.assets (id) on delete cascade,
  price_date date not null,
  open numeric(20, 8),
  high numeric(20, 8),
  low numeric(20, 8),
  close numeric(20, 8) not null,
  adjusted_close numeric(20, 8),
  volume bigint,
  source text,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (asset_id, price_date),
  constraint prices_daily_non_negative_check check (
    (open is null or open >= 0)
    and (high is null or high >= 0)
    and (low is null or low >= 0)
    and close >= 0
    and (adjusted_close is null or adjusted_close >= 0)
    and (volume is null or volume >= 0)
  )
);

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  account_type text not null,
  institution text,
  currency_code text not null default 'USD',
  is_active boolean not null default true,
  opened_on date,
  closed_on date,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint accounts_open_close_date_check check (closed_on is null or opened_on is null or closed_on >= opened_on),
  constraint accounts_id_user_id_key unique (id, user_id)
);

create table if not exists public.credit_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid,
  issuer text,
  card_name text not null,
  last4 text,
  billing_day smallint,
  due_day smallint,
  credit_limit numeric(14, 2),
  currency_code text not null default 'USD',
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint credit_cards_account_owner_fkey
    foreign key (account_id, user_id)
    references public.accounts (id, user_id)
    on delete restrict,
  constraint credit_cards_last4_check check (last4 is null or char_length(last4) = 4),
  constraint credit_cards_billing_day_check check (billing_day is null or billing_day between 1 and 31),
  constraint credit_cards_due_day_check check (due_day is null or due_day between 1 and 31),
  constraint credit_cards_credit_limit_check check (credit_limit is null or credit_limit >= 0),
  constraint credit_cards_id_user_id_key unique (id, user_id)
);

create table if not exists public.card_statements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  credit_card_id uuid not null,
  statement_period_start date not null,
  statement_period_end date not null,
  due_date date,
  statement_balance numeric(14, 2) not null default 0,
  minimum_due numeric(14, 2),
  paid_amount numeric(14, 2) not null default 0,
  status text not null default 'open',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint card_statements_credit_card_owner_fkey
    foreign key (credit_card_id, user_id)
    references public.credit_cards (id, user_id)
    on delete cascade,
  constraint card_statements_period_check check (statement_period_end >= statement_period_start),
  constraint card_statements_amounts_check check (
    statement_balance >= 0
    and paid_amount >= 0
    and (minimum_due is null or minimum_due >= 0)
  ),
  constraint card_statements_unique_period unique (credit_card_id, statement_period_start, statement_period_end),
  constraint card_statements_id_user_id_key unique (id, user_id)
);

create table if not exists public.holdings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid,
  asset_id uuid not null references public.assets (id) on delete restrict,
  quantity numeric(24, 8) not null default 0,
  average_cost numeric(20, 8),
  cost_basis_total numeric(20, 2),
  market_value numeric(20, 2),
  unrealized_pnl numeric(20, 2),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint holdings_account_owner_fkey
    foreign key (account_id, user_id)
    references public.accounts (id, user_id)
    on delete set null,
  constraint holdings_quantity_check check (quantity >= 0),
  constraint holdings_average_cost_check check (average_cost is null or average_cost >= 0),
  constraint holdings_cost_basis_total_check check (cost_basis_total is null or cost_basis_total >= 0),
  constraint holdings_market_value_check check (market_value is null or market_value >= 0),
  constraint holdings_unique_position unique (user_id, asset_id)
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid,
  credit_card_id uuid,
  card_statement_id uuid,
  asset_id uuid references public.assets (id) on delete restrict,
  transaction_type text not null,
  direction text,
  amount numeric(14, 2) not null,
  quantity numeric(24, 8),
  unit_price numeric(20, 8),
  currency_code text not null default 'USD',
  occurred_at timestamptz not null,
  merchant text,
  category text,
  note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint transactions_account_owner_fkey
    foreign key (account_id, user_id)
    references public.accounts (id, user_id)
    on delete restrict,
  constraint transactions_credit_card_owner_fkey
    foreign key (credit_card_id, user_id)
    references public.credit_cards (id, user_id)
    on delete restrict,
  constraint transactions_card_statement_owner_fkey
    foreign key (card_statement_id, user_id)
    references public.card_statements (id, user_id)
    on delete restrict,
  constraint transactions_amount_check check (amount <> 0),
  constraint transactions_quantity_check check (quantity is null or quantity >= 0),
  constraint transactions_unit_price_check check (unit_price is null or unit_price >= 0)
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  category text,
  amount numeric(12, 2) not null,
  currency_code text not null default 'USD',
  billing_cycle text not null default 'monthly',
  next_billing_date date not null,
  account_id uuid,
  credit_card_id uuid,
  is_active boolean not null default true,
  started_on date,
  ended_on date,
  reminder_days_before integer not null default 3,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint subscriptions_account_owner_fkey
    foreign key (account_id, user_id)
    references public.accounts (id, user_id)
    on delete restrict,
  constraint subscriptions_credit_card_owner_fkey
    foreign key (credit_card_id, user_id)
    references public.credit_cards (id, user_id)
    on delete restrict,
  constraint subscriptions_amount_check check (amount >= 0),
  constraint subscriptions_reminder_days_before_check check (reminder_days_before >= 0),
  constraint subscriptions_started_ended_check check (ended_on is null or started_on is null or ended_on >= started_on)
);

create table if not exists public.monthly_budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  budget_month date not null,
  category text not null,
  amount_limit numeric(14, 2) not null,
  spent_amount numeric(14, 2) not null default 0,
  rollover_enabled boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint monthly_budgets_amount_limit_check check (amount_limit >= 0),
  constraint monthly_budgets_spent_amount_check check (spent_amount >= 0),
  constraint monthly_budgets_month_start_check check (
    budget_month = date_trunc('month', budget_month::timestamp)::date
  ),
  constraint monthly_budgets_unique_user_month_category unique (user_id, budget_month, category)
);

create table if not exists public.target_allocations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  asset_id uuid not null references public.assets (id) on delete cascade,
  target_percentage numeric(7, 4) not null,
  rebalance_threshold numeric(7, 4) not null default 5,
  effective_from date not null default current_date,
  effective_to date,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint target_allocations_percentage_check check (target_percentage >= 0 and target_percentage <= 100),
  constraint target_allocations_rebalance_threshold_check check (rebalance_threshold >= 0 and rebalance_threshold <= 100),
  constraint target_allocations_effective_range_check check (effective_to is null or effective_to >= effective_from),
  constraint target_allocations_unique_user_asset_start unique (user_id, asset_id, effective_from)
);

create table if not exists public.portfolio_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  snapshot_date date not null,
  total_value numeric(20, 2) not null,
  total_cost numeric(20, 2),
  total_gain_loss numeric(20, 2),
  total_gain_loss_pct numeric(9, 4),
  cash_value numeric(20, 2),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint portfolio_snapshots_total_value_check check (total_value >= 0),
  constraint portfolio_snapshots_total_cost_check check (total_cost is null or total_cost >= 0),
  constraint portfolio_snapshots_cash_value_check check (cash_value is null or cash_value >= 0),
  constraint portfolio_snapshots_unique_user_snapshot_date unique (user_id, snapshot_date)
);

create table if not exists public.insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  snapshot_date date not null,
  insight_type text not null,
  title text not null,
  summary text,
  severity text not null default 'info',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  constraint insights_severity_check check (severity in ('info', 'warning', 'critical'))
);
