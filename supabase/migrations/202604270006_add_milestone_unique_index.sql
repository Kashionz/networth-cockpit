create unique index if not exists idx_insights_milestone_once
  on public.insights (user_id, insight_type, ((payload ->> 'milestone_code')))
  where insight_type = 'milestone'
    and coalesce(payload ->> 'milestone_code', '') <> '';
