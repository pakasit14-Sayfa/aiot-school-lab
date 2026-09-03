-- Fresh-install repair for a table that previously existed only through
-- undocumented production-side SQL. Keep the later calendar migration intact.

set search_path = public, extensions;

create table if not exists school_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  title varchar not null,
  location varchar,
  start_date date not null,
  end_date date not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_school_events_school_start_date
  on school_events (school_id, start_date);

alter table school_events enable row level security;
revoke all on table school_events from public, anon, authenticated;
