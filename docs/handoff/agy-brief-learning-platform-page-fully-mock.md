# Brief for agy: `learning_platform_page.dart` is 100% mock — correcting an earlier wrong claim first

**Correction before anything else**: earlier reports (including one I
relayed without re-checking myself) described this page as "simulator/
relay commands real, only lesson content mock." That's wrong. Verified
directly: the file has **zero** `.from()`/`.rpc()` calls, zero
`Supabase.`/`client.` references, and **doesn't even import the Supabase
package**:

```bash
grep -n "client\.\|Supabase\.\|\.rpc('\|\.from('" lib/pages/learning_platform_page.dart
# → no output
head -8 lib/pages/learning_platform_page.dart | grep import
# → dart:async, flutter/material, flutter/services, package:http/http.dart,
#   package:url_launcher/url_launcher.dart, ../theme/app_palette.dart
# no supabase_flutter anywhere
```

The `http`/`url_launcher` imports are for checking whether an external
simulator URL responds (`http.head(uri)`) and opening links in a browser —
unrelated to any database. Everything else (`_items`, `_schools`,
`_LearningLog` entries) is local state, gone on reload. No table for any
of this exists in the schema either — checked, nothing matching
`learning`/`simulator`/`training` in `information_schema.tables`.

## What this page actually is (so the schema fits the real feature)

Not a device-control page — it's a **lesson-content library manager**,
per-school publishable:

- `_LearningItem`: a lesson/video/activity — title, description, difficulty,
  duration, points, an external link, and **per-school publish control**
  (`publishToAllSchools` bool, or a specific `publishedSchoolIds` set).
  This is the main CRUD surface (add/edit/delete/publish/unpublish).
- `_SimulatorItem`: a named external simulator/tool URL to health-check
  (`http.head`) — the health check itself can stay purely client-side
  (no reason to store live status), but the *list* of simulators
  (name/url/description per training kit) should persist so it's shared
  across admin sessions instead of reset every reload.
- `_SchoolOption` (id/code/name, used for the per-school publish picker) —
  should come from `public.schools`, not be hardcoded.

## Proposed schema

```sql
create table public.learning_items (
  id uuid primary key default gen_random_uuid(),
  training_set text not null,
  type text not null check (type in ('lesson', 'video', 'activity')),
  title text not null,
  description text,
  difficulty text,
  duration_minutes int,
  points int default 0,
  link text,
  published boolean not null default false,
  publish_to_all_schools boolean not null default true,
  published_school_ids uuid[] default '{}',
  created_by uuid not null references public.users(id),
  updated_at timestamptz default now()
);

create table public.learning_simulators (
  id uuid primary key default gen_random_uuid(),
  training_set text not null,
  name text not null,
  url text not null,
  description text,
  auto_check boolean not null default false,
  created_by uuid not null references public.users(id),
  updated_at timestamptz default now()
);
```

Both are global content (not school-owned rows — a super_admin authors
lesson content that gets *published to* schools, it doesn't belong to one).
RLS: SELECT open to any `authenticated` (every school needs to read
published content); INSERT/UPDATE/DELETE restricted to
`is_super_admin()` only — same dual-check convention as everything else
today, just without the school-membership half since there's no owning
school. If a school_admin should also be able to author content scoped to
just their own school, that's a different, additional policy — flag if
that's actually wanted before adding it.

```sql
alter table public.learning_items enable row level security;
alter table public.learning_simulators enable row level security;

create policy read_learning_items on public.learning_items
  for select to authenticated using (true);
create policy super_admin_write_learning_items on public.learning_items
  for all to authenticated
  using (is_super_admin()) with check (is_super_admin());

create policy read_learning_simulators on public.learning_simulators
  for select to authenticated using (true);
create policy super_admin_write_learning_simulators on public.learning_simulators
  for all to authenticated
  using (is_super_admin()) with check (is_super_admin());
```

## Flutter side

Replace `_items`/`_schools`/`_simulators` (whatever the simulator list
variable is) with real loads in `initState`:
`client.from('learning_items').select()`,
`client.from('learning_simulators').select()`, `client.from('schools').select('id, school_code, name')`
for the publish picker. Wire the add/edit/delete/publish dialogs (the ones
already producing `_LearningDialogResult`/`_SimulatorDialogResult`) to
`.insert()`/`.update()`/`.delete()` instead of mutating the local lists.

## Verify

Don't trust `flutter analyze`/`flutter test` for this one either — same
lesson as every other item today. Add a real lesson through the UI,
reload the page, confirm it's still there. Publish it to a specific
school (not all), log in as a student/teacher at a *different* school,
confirm they don't see it — that's the actual point of the per-school
publish control, and it's meaningless if it's not backed by a real query.
