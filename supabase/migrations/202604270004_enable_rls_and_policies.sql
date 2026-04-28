alter table public.assets enable row level security;
alter table public.prices_daily enable row level security;
alter table public.accounts enable row level security;
alter table public.holdings enable row level security;
alter table public.credit_cards enable row level security;
alter table public.card_statements enable row level security;
alter table public.transactions enable row level security;
alter table public.subscriptions enable row level security;
alter table public.monthly_budgets enable row level security;
alter table public.target_allocations enable row level security;
alter table public.portfolio_snapshots enable row level security;
alter table public.insights enable row level security;
alter table public.account_deletion_requests enable row level security;
alter table public.job_definitions enable row level security;
alter table public.job_runs enable row level security;

drop policy if exists "assets_select_own" on public.assets;
create policy "assets_select_own"
on public.assets
for select
using (auth.uid() = user_id);

drop policy if exists "assets_insert_own" on public.assets;
create policy "assets_insert_own"
on public.assets
for insert
with check (auth.uid() = user_id);

drop policy if exists "assets_update_own" on public.assets;
create policy "assets_update_own"
on public.assets
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "assets_delete_own" on public.assets;
create policy "assets_delete_own"
on public.assets
for delete
using (auth.uid() = user_id);

drop policy if exists "prices_daily_select_own_assets" on public.prices_daily;
create policy "prices_daily_select_own_assets"
on public.prices_daily
for select
using (
  exists (
    select 1
    from public.assets a
    where a.id = prices_daily.asset_id
      and a.user_id = auth.uid()
  )
);

drop policy if exists "accounts_select_own" on public.accounts;
create policy "accounts_select_own"
on public.accounts
for select
using (auth.uid() = user_id);

drop policy if exists "accounts_insert_own" on public.accounts;
create policy "accounts_insert_own"
on public.accounts
for insert
with check (auth.uid() = user_id);

drop policy if exists "accounts_update_own" on public.accounts;
create policy "accounts_update_own"
on public.accounts
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "accounts_delete_own" on public.accounts;
create policy "accounts_delete_own"
on public.accounts
for delete
using (auth.uid() = user_id);

drop policy if exists "holdings_select_own" on public.holdings;
create policy "holdings_select_own"
on public.holdings
for select
using (auth.uid() = user_id);

drop policy if exists "holdings_insert_own" on public.holdings;
create policy "holdings_insert_own"
on public.holdings
for insert
with check (auth.uid() = user_id);

drop policy if exists "holdings_update_own" on public.holdings;
create policy "holdings_update_own"
on public.holdings
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "holdings_delete_own" on public.holdings;
create policy "holdings_delete_own"
on public.holdings
for delete
using (auth.uid() = user_id);

drop policy if exists "credit_cards_select_own" on public.credit_cards;
create policy "credit_cards_select_own"
on public.credit_cards
for select
using (auth.uid() = user_id);

drop policy if exists "credit_cards_insert_own" on public.credit_cards;
create policy "credit_cards_insert_own"
on public.credit_cards
for insert
with check (auth.uid() = user_id);

drop policy if exists "credit_cards_update_own" on public.credit_cards;
create policy "credit_cards_update_own"
on public.credit_cards
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "credit_cards_delete_own" on public.credit_cards;
create policy "credit_cards_delete_own"
on public.credit_cards
for delete
using (auth.uid() = user_id);

drop policy if exists "card_statements_select_own" on public.card_statements;
create policy "card_statements_select_own"
on public.card_statements
for select
using (auth.uid() = user_id);

drop policy if exists "card_statements_insert_own" on public.card_statements;
create policy "card_statements_insert_own"
on public.card_statements
for insert
with check (auth.uid() = user_id);

drop policy if exists "card_statements_update_own" on public.card_statements;
create policy "card_statements_update_own"
on public.card_statements
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "card_statements_delete_own" on public.card_statements;
create policy "card_statements_delete_own"
on public.card_statements
for delete
using (auth.uid() = user_id);

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own"
on public.transactions
for select
using (auth.uid() = user_id);

drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own"
on public.transactions
for insert
with check (auth.uid() = user_id);

drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own"
on public.transactions
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own"
on public.transactions
for delete
using (auth.uid() = user_id);

drop policy if exists "subscriptions_select_own" on public.subscriptions;
create policy "subscriptions_select_own"
on public.subscriptions
for select
using (auth.uid() = user_id);

drop policy if exists "subscriptions_insert_own" on public.subscriptions;
create policy "subscriptions_insert_own"
on public.subscriptions
for insert
with check (auth.uid() = user_id);

drop policy if exists "subscriptions_update_own" on public.subscriptions;
create policy "subscriptions_update_own"
on public.subscriptions
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "subscriptions_delete_own" on public.subscriptions;
create policy "subscriptions_delete_own"
on public.subscriptions
for delete
using (auth.uid() = user_id);

drop policy if exists "monthly_budgets_select_own" on public.monthly_budgets;
create policy "monthly_budgets_select_own"
on public.monthly_budgets
for select
using (auth.uid() = user_id);

drop policy if exists "monthly_budgets_insert_own" on public.monthly_budgets;
create policy "monthly_budgets_insert_own"
on public.monthly_budgets
for insert
with check (auth.uid() = user_id);

drop policy if exists "monthly_budgets_update_own" on public.monthly_budgets;
create policy "monthly_budgets_update_own"
on public.monthly_budgets
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "monthly_budgets_delete_own" on public.monthly_budgets;
create policy "monthly_budgets_delete_own"
on public.monthly_budgets
for delete
using (auth.uid() = user_id);

drop policy if exists "target_allocations_select_own" on public.target_allocations;
create policy "target_allocations_select_own"
on public.target_allocations
for select
using (auth.uid() = user_id);

drop policy if exists "target_allocations_insert_own" on public.target_allocations;
create policy "target_allocations_insert_own"
on public.target_allocations
for insert
with check (auth.uid() = user_id);

drop policy if exists "target_allocations_update_own" on public.target_allocations;
create policy "target_allocations_update_own"
on public.target_allocations
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "target_allocations_delete_own" on public.target_allocations;
create policy "target_allocations_delete_own"
on public.target_allocations
for delete
using (auth.uid() = user_id);

drop policy if exists "portfolio_snapshots_select_own" on public.portfolio_snapshots;
create policy "portfolio_snapshots_select_own"
on public.portfolio_snapshots
for select
using (auth.uid() = user_id);

drop policy if exists "portfolio_snapshots_insert_own" on public.portfolio_snapshots;
create policy "portfolio_snapshots_insert_own"
on public.portfolio_snapshots
for insert
with check (auth.uid() = user_id);

drop policy if exists "portfolio_snapshots_update_own" on public.portfolio_snapshots;
create policy "portfolio_snapshots_update_own"
on public.portfolio_snapshots
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "portfolio_snapshots_delete_own" on public.portfolio_snapshots;
create policy "portfolio_snapshots_delete_own"
on public.portfolio_snapshots
for delete
using (auth.uid() = user_id);

drop policy if exists "insights_select_own" on public.insights;
create policy "insights_select_own"
on public.insights
for select
using (auth.uid() = user_id);

drop policy if exists "account_deletion_requests_select_own" on public.account_deletion_requests;
create policy "account_deletion_requests_select_own"
on public.account_deletion_requests
for select
using (auth.uid() = user_id);

drop policy if exists "account_deletion_requests_insert_own" on public.account_deletion_requests;
create policy "account_deletion_requests_insert_own"
on public.account_deletion_requests
for insert
with check (auth.uid() = user_id);

drop policy if exists "account_deletion_requests_update_own" on public.account_deletion_requests;
create policy "account_deletion_requests_update_own"
on public.account_deletion_requests
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "account_deletion_requests_delete_own" on public.account_deletion_requests;
create policy "account_deletion_requests_delete_own"
on public.account_deletion_requests
for delete
using (auth.uid() = user_id);

drop policy if exists "job_definitions_select_all" on public.job_definitions;
create policy "job_definitions_select_all"
on public.job_definitions
for select
using (true);

drop policy if exists "job_definitions_insert_authenticated" on public.job_definitions;
create policy "job_definitions_insert_authenticated"
on public.job_definitions
for insert
with check (auth.role() = 'authenticated');

drop policy if exists "job_definitions_update_authenticated" on public.job_definitions;
create policy "job_definitions_update_authenticated"
on public.job_definitions
for update
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

drop policy if exists "job_runs_select_own" on public.job_runs;
create policy "job_runs_select_own"
on public.job_runs
for select
using (initiated_by_user_id = auth.uid());

drop policy if exists "job_runs_insert_own" on public.job_runs;
create policy "job_runs_insert_own"
on public.job_runs
for insert
with check (initiated_by_user_id = auth.uid());

drop policy if exists "job_runs_update_own" on public.job_runs;
create policy "job_runs_update_own"
on public.job_runs
for update
using (initiated_by_user_id = auth.uid())
with check (initiated_by_user_id = auth.uid());
