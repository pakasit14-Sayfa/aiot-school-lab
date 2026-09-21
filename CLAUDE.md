# AIoT School Lab — Project Instructions

> ## เริ่มทุกเซสชันด้วยคำสั่งนี้
>
> ```bash
> ./scripts/state.sh
> ```
>
> พ่นสถานะจริงจาก git / โค้ด / ฐานข้อมูล ~40 บรรทัด — งานไหนยังไม่ push · เลนอื่น
> ทำอะไรอยู่ · build เขียวไหม · หน้าไหนต่อ backend แล้ว · RPC ตัวไหนเป็นกับดัก
> (`--test` เพิ่มผลรัน test · `--log` ประวัติงานที่สร้างจาก git)
>
> **อย่าเริ่มจากการอ่านเอกสารแล้วเชื่อ** — 2026-09-06 เอกสารในโฟลเดอร์นี้ผิดพร้อมกัน
> 3 จุด: baseline test (เขียน 16 ของจริง 17), `school_admin_energy_page` ที่เขียนว่า
> "ต่อครบแล้ว เหลือแค่งาน DoD" ทั้งที่มี fallback ปลอม 10 ตัว, และ `school_alerts_page`
> ที่เขียนว่าผ่าน DoD ทั้งที่ filter 4 ตัวกรองอะไรไม่ได้เลย
>
> **`grep` พิสูจน์ได้แค่ "ไม่ต่อ backend แน่ ๆ" ไม่เคยพิสูจน์ว่า "ต่อครบแล้ว"**
> ต้องอ่านทั้งไฟล์ก่อนสรุปว่าหน้าไหนเสร็จ · ตรวจ role gate กับฐานข้อมูลที่รันอยู่
> ไม่ใช่ไฟล์ migration
>
> กติกาการทำงานร่วมกันหลาย AI (commit / push / จองเลนด้วย branch): **`AGENTS.md`**

School management app (Thai-language UI): classes, assignments, grading,
quizzes, lesson content, incident/emergency reporting, parent-student
binding, and IoT sensor data from physical classroom devices.

**Roles (6, as of 2026-08-25): `super_admin`, `school_admin`, `teacher`,
`executive`, `student`, `parent`.** There is no `facility_manager` or
`technician` role anymore — both were merged (`facility_manager` →
`school_admin`, `technician` → `super_admin`) on 2026-08-25; see
`docs/handoff/HANDOFF.md` for the migration details. **All 6 roles route
through their redesigned UI and are fully wired to real backend data** —
`role_router.dart` sends `student`/`teacher`/`executive`/`parent` to their
`*_redesign_prototype/` shell, `school_admin` to `school_admin/school_admin_dashboard_page.dart`
(new-design hub, 20 real menu items — swapped from the old `dashboard/school_admin_dashboard.dart`
shell on 2026-08-25, live-verified), `super_admin` to `super_admin/super_admin_hub_page.dart`
(new-design hub, 8 real menu items — swapped from the old `dashboard/super_admin_dashboard.dart`
shell on 2026-08-26, live-verified).
**A single account can hold more than one role** — see "Multi-role login"
in HANDOFF.md.

Full architecture writeup, "how to run," current status, and known issues:
**[docs/handoff/HANDOFF.md](docs/handoff/HANDOFF.md)**. Full live database
schema (every table, every RPC function signature): **[docs/handoff/DATABASE_SCHEMA.md](docs/handoff/DATABASE_SCHEMA.md)**
— regenerate this from the running local DB rather than hand-editing it (see
"Keeping this current" below).

**Start here for what to do next: [docs/handoff/MASTER_PLAN_2026-09-06.md](docs/handoff/MASTER_PLAN_2026-09-06.md)**
— the single plan (41 trackable tickets), and
**[docs/handoff/STATUS_VERIFIED_2026-09-06.md](docs/handoff/STATUS_VERIFIED_2026-09-06.md)**
— what is actually done vs not, each claim checked against real code/DB/git
rather than trusted from the docs. These two replace the ~37 per-task brief
and per-agent plan files that used to live in `docs/handoff/` (deleted
2026-09-06 after verifying every one of them was closed — recoverable from
git history if ever needed). Having six overlapping "what to do next"
documents was itself a documented cause of a session reading the project's
status completely wrong; keep it to these two.
[docs/handoff/WORK_LOG.md](docs/handoff/WORK_LOG.md) is now **history only**
— a dated record of what happened, not a plan.

**Before touching anything visual (สี · ระยะ · ฟอนต์ · เพิ่มหน้าใหม่), read
[docs/handoff/DESIGN_SYSTEM.md](docs/handoff/DESIGN_SYSTEM.md)** — the project
had *no* written design spec until 2026-09-10, so every session invented its own
colors; that file records what actually exists (6 per-role palettes, deliberately
different) plus the rules that stop the drift from growing.

**เจออาการแปลก ๆ ที่ "ไม่น่าเป็นไปได้" — เปิด
[docs/handoff/PITFALLS.md](docs/handoff/PITFALLS.md) ก่อนเดา** — บันทึกกับดักที่
เคยกินเวลาไปแล้วอย่างน้อยหนึ่งรอบ (ธีมทับสไตล์ที่ตั้งเอง · แคช build ค้างจน
ฟ้องว่าไม่รู้จักคลาสที่มีอยู่จริง · บิลด์ลงคนละเครื่องกับที่กำลังดู ฯลฯ) พร้อม
"วินิจฉัยผิดที่เคยทำ" ของแต่ละเรื่อง เจอปัญหาใหม่ที่หลอกเราได้ ให้เขียนเพิ่มใน
ไฟล์นี้ตามฟอร์แมตด้านบนของมัน

**Before
auditing a page for fake data, wiring something new to the backend, or
verifying a "done" claim, read [docs/handoff/DATA_CONNECTION_METHODOLOGY.md](docs/handoff/DATA_CONNECTION_METHODOLOGY.md)**
— process/methodology (not architecture), with concrete anti-pattern
checklists and worked examples from real bugs found this way.

There is also a separate Obsidian vault at `~/Documents/AIoT-School-Lab-Vault/`
covering product design, decisions, and the 173 use-case specs — that's
design/product knowledge, not code. This file and `docs/handoff/` cover the
codebase itself.

## Hard rules — read before touching the backend

1. **Not Supabase Auth.** No `auth.users`, no `auth.uid()`. Custom
   `sessions` table + opaque `session_token` string, validated via
   `get_session_actor(p_token)` inside every RPC. Client passes `p_token`
   as the first arg to nearly every `supabase.rpc(...)` call.
2. **RLS is deny-all on every table, zero policies.** Never write client
   code that calls `.from('table').select()` — it will silently return
   nothing. All reads/writes go through `SECURITY DEFINER` RPC functions.
   Adding a feature means adding an RPC, not exposing a table.
3. **File uploads go through signed URLs minted by Edge Functions**, never
   direct client Storage calls. Pattern: client → Edge Function (checks an
   `assert_*_access` RPC) → signed upload/download URL → client uses it
   directly. Copy the `lesson-material-upload`/`-download` or
   `course-file-upload`/`-download` functions as the template for any new
   upload feature. **Gotcha (bit both existing pairs, fixed in `26d0343`/
   `908707e`): any RPC called from the service-role client needs
   `grant execute ... to service_role` explicitly — it is not a member of
   `anon`/`authenticated` and gets no execute privilege from a grant to
   those roles alone.**
4. **One service class per domain** in `packages/shared_core/lib/services/`.
   Pages call the service; the service calls the RPC. Don't call
   `supabase.rpc(...)` directly from a page widget.
5. **No global `supabase` CLI** — always `npx supabase ...`.
6. **`NOTES.md` files inside `teacher_redesign_prototype/` and
   `student_redesign_prototype/` are stale** (describe an early UI-only
   mock phase). Trust `git log` and the actual code over those files for
   current status. **This applies doubly to this CLAUDE.md and to
   HANDOFF.md themselves** — both drifted badly behind real progress
   earlier in the project (see the 2026-08-25 note in HANDOFF.md's
   "Current status"). If a claim here contradicts what `role_router.dart`
   or a live login actually shows, trust the live system.

## Running locally

```bash
open -a Docker              # Docker Desktop must be running first
npx supabase start          # local Postgres/Storage/Edge Functions/Studio
cd apps/user_app
flutter run -d chrome --dart-define-from-file=../../env.json
```

Test accounts (seeded, password `Test1234!` for all): `teacher@aiot-school-lab.local`,
`student@aiot-school-lab.local`, `parent@aiot-school-lab.local`,
`schooladmin@aiot-school-lab.local`, `admin@aiot-school-lab.local`, `executive@aiot-school-lab.local`.

These same 8 accounts also exist in real `auth.users` (seeded by
`20260823070000_seed_auth_users_for_local_dev.sql`) with the same
`Test1234!` password, for `aiot_dev_dashboard` — the separate admin app in
this repo that uses actual Supabase Auth instead of `my_first_app`'s custom
session system (see hard rule 1). **Gotcha, found via real login testing:**
this password only lives in the migration file — if anyone changes it
directly in the DB (`docker exec`/Studio) while testing, it silently drifts
from what a fresh `db reset` reproduces. Verify with:
`select encrypted_password = crypt('Test1234!', encrypted_password) from auth.users;`
— should be all `t`.

**Second test student, for multi-child Parent testing — `student2@aiot-school-lab.local`.
Was runtime-only from 2026-09-04 and did NOT survive `supabase db reset`; it was in fact
silently lost to a reset on 2026-09-08, leaving `parent@` with one child and the
student-switcher untested. Since 2026-09-09 it lives in `supabase/seed.sql`, so a reset
recreates it. Verified: `list_my_linked_students` returns 2 children:** `student2@aiot-school-lab.local` /
`Test1234!` (student_code `STU002`), linked to `parent@aiot-school-lab.local`
as an approved second child (`relationship: มารดา`). The seed writes the `parent_links` row directly, the same way the first child is
seeded — it is not the supported parent-signup flow and does not validate it; the
app uses `request_parent_binding_otp` followed by `confirm_parent_binding`. (The
original runtime fixture went through the legacy `redeem_parent_binding_code`
endpoint, which the 20260904000000 hardening migration has since revoked.)
Has no `student_profiles` row and no grades/attendance/course data, so
every student-scoped Parent page correctly shows `ยังไม่มีข้อมูล` for this child — that
is expected, it exists only to give the Parent test account 2 linked children
for testing the shared student-switcher.
## If you received this codebase as a zip file

This repo is normally shared as a full folder copy (zip), not a GitLab
invite. If that's how you got this:

1. **Check `.git/` is present**: run `git status` in the project root. If it
   shows a branch and commit history, git tracking survived the transfer —
   keep using it normally.
2. **Work on your own branch**, don't commit straight to whatever branch you
   received: `git checkout -b <your-name>-work`.
3. **Commit as you go**, even though there's nowhere to push:
   `git add -A && git commit -m "..."`. This is what makes it possible for
   the original owner to merge your changes back cleanly later, instead of
   diffing two folder snapshots by hand.
4. **When sending work back**, zip the whole project folder again — make
   sure `.git/` is included (don't use a "skip hidden files" zip option, and
   don't add `.git` to an exclude list). Losing `.git/` loses all commit
   history you made in step 3, and the owner is back to a blind file diff.
5. The owner will merge your branch back with
   `git remote add <you> <path-to-your-copy> && git fetch <you> && git merge <you>/<your-branch>`
   — so a clean, real commit history from you is what makes that painless.

## Keeping this current — mandatory, not optional, part of finishing any task

**This is not a "nice to have" — it caused a real problem 2026-08-25**: a
Claude session read this file and `HANDOFF.md` mid-project and got the
project's status completely wrong (thought `facility_manager` still
existed, thought the redesigned UI pages were still unwired mockups)
because whoever did that work never updated these docs. The project
owner had to notice and point it out. Don't repeat this — if you (agy,
or any Claude session) finish a task that changes what's true about this
project, updating the docs below is part of *finishing the task*, not a
separate follow-up someone else does later.

- `docs/handoff/HANDOFF.md` — update the "Current status" / "Known issues"
  sections when they materially change; don't let it rot into another stale
  NOTES.md.
- `docs/handoff/MASTER_PLAN_2026-09-06.md` — tick a ticket `[x]` **with the
  commit hash** the moment it's genuinely done. **Never tick from an agent's
  report or a commit message alone — verify it yourself** (on 2026-09-06 a
  subagent reported 2 of 4 regression findings wrongly).
- `docs/handoff/STATUS_VERIFIED_2026-09-06.md` — move items between
  ✅ done / ⚠️ partial / ❌ not started as reality changes, and record the
  evidence that justified the move.
- `docs/handoff/WORK_LOG.md` — append-only history of what happened, with
  commit hashes. Not a plan; don't put "next steps" here.
- `docs/handoff/DATABASE_SCHEMA.md` — regenerate, don't hand-edit, after any
  migration. It was generated with:
  ```bash
  docker exec -i supabase_db_aiot-school-lab psql -U postgres -d postgres -A -F"|" -c "..."
  ```
  (queries against `information_schema.columns`, `information_schema
  .table_constraints`/`key_column_usage`/`constraint_column_usage` for FKs,
  and `pg_proc`/`pg_namespace` for RPC signatures — see git history of that
  file for the exact SQL.)
