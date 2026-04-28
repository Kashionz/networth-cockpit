drop policy if exists "insights_insert_own" on public.insights;
create policy "insights_insert_own"
on public.insights
for insert
with check (auth.uid() = user_id);

drop policy if exists "insights_update_own" on public.insights;
create policy "insights_update_own"
on public.insights
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
