# NetWorth Cockpit

Flutter + Supabase personal finance cockpit for dashboarding, budget tracking,
portfolio allocation, and monthly AI insights.

## Getting Started

1. Install Flutter SDK and project dependencies.
2. Configure required runtime env vars (Supabase / market / AI endpoint).
3. Run:

```bash
flutter pub get
flutter run
```

## Database Schema Notes (v0.1)

Core schema and RLS policies are defined in `supabase/migrations/`.

- `202604270002_create_core_financial_tables.sql`
- `202604270003_add_future_tables_indexes_and_triggers.sql`
- `202604270004_enable_rls_and_policies.sql`

`income_streams` table is included via:

- `202604270008_create_income_streams.sql`

`income_streams` columns:

- `id uuid primary key`
- `user_id uuid references auth.users (id) on delete cascade`
- `name text`
- `amount numeric(14,2)`
- `frequency text check in ('monthly', 'yearly', 'one_time')`
- `next_date date`
- `active boolean default true`
- `created_at timestamptz`
- `updated_at timestamptz`

RLS is enabled with owner-only `select/insert/update/delete` policies
(`auth.uid() = user_id`) and index `(user_id, next_date)`.
