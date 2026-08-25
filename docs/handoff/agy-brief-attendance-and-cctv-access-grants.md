# Brief for agy: 2 of the 4 Tier-3 items are now scoped — attendance (new) + CCTV (access-grant half only)

Followed up on the open product questions from the last Tier-3 list.
User decided on all 4:

- **Attendance** → build it. Source of truth: teacher marks attendance
  per class period ("ครูกดเช็คชื่อในคาบ").
- **Messages** (parent↔teacher chat) → **not now**. Leave
  `parent_messages_page.dart` exactly as-is, mock. Don't touch it.
- **Meetings** (director scheduling/ขอพบ) → **not now**. Leave
  `director_meetings_page.dart` exactly as-is, mock. Don't touch it.
- **CCTV** → wire the access-grant management half only (real table
  already exists). Live video feed stays out of scope — don't fake a
  video player, leave that part of the UI as an explicit "ไม่รองรับ" /
  placeholder state rather than mock footage.

This brief only covers attendance + CCTV. Nothing to do for the other two.

## Checked the vault first (per this project's convention)

`api-spec-mvp-v1.md` explicitly lists `attendance | นอก MVP` — confirmed
out of original MVP scope, no UC anywhere in the vault names it. This is
genuinely new scope, same situation as the calendar feature earlier this
session — proceeding because the user explicitly authorized it just now,
not inventing it from what a mock page happened to show.

## 1. Attendance — new table + 3 RPCs

No existing table for this at all (checked `information_schema.tables`,
nothing named `attendance*`). New migration:

```sql
create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id),
  student_id uuid not null references public.users(id),
  class_date date not null,
  status text not null check (status in ('present', 'late', 'absent', 'excused')),
  marked_by uuid not null references public.users(id),
  marked_at timestamptz not null default now(),
  note text,
  unique (course_id, student_id, class_date)
);

alter table public.attendance_records enable row level security;
-- deny-all, RPC-only — same as every other table in this schema (hard rule 2 in CLAUDE.md)
```

RPCs, same conventions as everything else (`get_session_actor`, dual
tenant+role check, `revoke`/`grant` at the end):

- **`mark_attendance(p_token, p_course_id, p_class_date, p_records jsonb)`**
  — teacher only, must be in `course_teachers` for that course. `p_records`
  is `[{"student_id": "...", "status": "present"}, ...]` — bulk upsert
  (`on conflict (course_id, student_id, class_date) do update`) so a
  teacher submits the whole roster for that period in one call, matching
  how attendance-taking actually works (mark the whole class, not one
  RPC call per student). Validate every `student_id` is actually in
  `course_students` for that course before upserting — don't trust the
  client-supplied list blindly.
- **`list_course_attendance(p_token, p_course_id, p_class_date)`** —
  teacher only (same course-membership check), returns the current
  roster with today's status for the marking UI to load.
- **`list_my_student_attendance(p_token, p_student_id, p_date_from, p_date_to)`**
  — parent only, same `parent_links` approved-ownership check as
  `list_my_student_grades`/`list_my_student_schedule` (copy that exact
  pattern, don't reinvent it). Returns rows for `parent_attendance_page.dart`
  to render.

## Important: this does NOT give you a "เข้าโรงเรียน 07:41 น." arrival time

The current `parent_attendance_page.dart` / `parent_dashboard_page.dart`
mock shows a specific clock-in time. This design only gives per-period
present/late/absent — there's no check-in-timestamp concept here (that
would be a kiosk/badge-scan feature, not what was authorized). Don't
fabricate an arrival time from `class_schedules.start_time` or
`marked_at` and present it as if it were real — those aren't the same
thing. Adjust the UI copy to show attendance **rate** and per-period
**status** (which this backend genuinely provides), and drop or clearly
placeholder the specific arrival-clock-time element instead of quietly
backfilling it with something that looks real but isn't.

**Where does the teacher-side marking UI live?** Checked — there's no
existing "take attendance" screen anywhere in `teacher_redesign_prototype/`.
`mark_attendance`/`list_course_attendance` will have no UI caller yet.
That's fine for this pass (parent side is what was asked for), but flag
it back rather than leaving it silently uncallable — a teacher-side
attendance-taking page is a separate follow-up, not assumed part of this
brief.

## 2. CCTV — access-grant management only, 3 new RPCs (table already exists, no RPCs do yet)

`camera_access_grants` table exists (`school_id`, `user_id`,
`camera_device_id` → `devices.id` where `type = 'camera'`, `granted_by`,
`reason`, `valid_from`, `valid_until`, `granted_at`, `revoked_at`) but
**zero RPCs reference it** — checked `information_schema.routines`, none
match `%camera%`. This needs the RPC layer built from scratch, it's not
just a wiring task.

- **`list_camera_access_grants(p_token)`** — `executive`/`school_admin`
  only. Returns active grants (join `devices` for camera name/location,
  `users` for grantee name) for the school.
- **`grant_camera_access(p_token, p_user_id, p_camera_device_id, p_reason, p_valid_until)`**
  — same role gate; verify `p_camera_device_id` is `type = 'camera'` and
  belongs to the caller's school before inserting; `granted_by` = caller.
- **`revoke_camera_access(p_token, p_grant_id)`** — same role gate,
  school-scoped, sets `revoked_at = now()`.

Wire `director_cctv_page.dart`'s grant-management UI to these. For the
live-feed section of that page: don't remove it silently and don't mock
footage — show a clear "ไม่รองรับวิดีโอสดในระบบนี้" state (or however the
existing UI's empty-state pattern looks) so it's honest about what's
real vs not, same principle as the `ComingSoonCard`s already used in
`school_admin_dashboard.dart`.

## Verify

Same discipline as every RPC this session — real login, real data, not
`flutter analyze`/`flutter test` alone:

- Teacher marks attendance for a real course/date via `mark_attendance`,
  confirm the row lands in `attendance_records` via `psql`.
- Parent of that student sees the real status via
  `list_my_student_attendance` — and a parent of an *unrelated* student
  gets `forbidden` (same IDOR probe pattern as the grades/schedule RPCs
  — try a real cross-student request, not just a code read).
- A student not in the course, included in `p_records`, gets rejected
  by `mark_attendance` (the course_students membership check actually
  holds, not just present in the SQL).
- CCTV: `school_admin`/`executive` can grant/revoke, a `teacher`/`student`
  token gets `forbidden` on all 3 RPCs.
