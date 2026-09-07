# Executive (ผู้บริหาร / Director) — backend capability survey

**Ticket 3.0 of `docs/handoff/MASTER_PLAN_2026-09-06.md`. Analysis only — no code was changed.**
Date: 2026-09-06.

Purpose: before anyone writes UI code for the 11 unfinished Executive pages, establish
*per piece of data* whether the backend can already serve it. Every RPC named below was
confirmed to exist in `supabase/migrations/*.sql`, and its role gate was read from the
**latest** migration that defines it (per DATA_CONNECTION_METHODOLOGY §3.1). Nothing here
is a guessed function name.

## Verdict legend

| code | meaning | who does the work |
|---|---|---|
| **A** | RPC exists **and** already allows `executive` → wire the page, no backend work | Flutter only |
| **B** | RPC exists, correct shape, but its role gate excludes `executive` → one-line widening migration | small migration + Flutter |
| **C** | Data is in real tables, but **no RPC exposes it** → write a new SECURITY DEFINER RPC | migration + service + Flutter |
| **D** | **Nothing in the schema models this.** Not a coding task — a product decision | product owner first |

Effort classes: `reuse-only` · `needs-role-widening` · `needs-new-RPC` · `needs-new-schema`.

## Baseline facts confirmed during this survey

- 270 distinct `create or replace function` names across the migrations (the "207" in the
  master plan comes from a lowercase-only grep; a case-insensitive grep finds 270,
  including ~15 internal `_helpers`). Full list regenerated with:
  `grep -rhoiE "create or replace function (public\.)?[a-z_]+" supabase/migrations/*.sql`
- `'executive'` appears in role gates in 36 migration files.
- Tables that **do not exist anywhere in the schema** (checked against every `## ` heading
  in `DATABASE_SCHEMA.md`): meetings/agenda/minutes/attendees, departments (ฝ่าย),
  subject groups (กลุ่มสาระ), staff attendance / staff check-in, staff leave
  (`leave_requests` is **student** leave: `student_id` + `parent_id`), report/document
  submissions, equipment lending (ยืม-คืน), home visits (เยี่ยมบ้าน), per-user
  notification or dashboard preferences, CCTV live-stream/recording metadata.
- `users` has **no** `phone`, `position`, `department`, or `avatar` column
  (id, school_id, email, student_code, password_hash, must_change_password,
  first_name, last_name, status, created_by, created_at, building).

---

# Part 1 — the six fully-disconnected pages

## 3.5 `director_learning_page.dart` (2,815 lines) — ภาพรวมนักเรียน

| what it must show (real director need) | verdict | exact RPC / table | notes |
|---|---|---|---|
| นักเรียนทั้งหมด / จำนวนห้องเรียน | **A** | `get_classrooms_overview(p_token)` → `room_count, course_count, active_student_count, assignments_due_this_week`; gate `('executive','school_admin')` | already wrapped: `ExecutiveService.getClassroomsOverview()` |
| Head-count by role (ครู/นักเรียน/ผู้ปกครอง) | **A** | `count_school_users_by_role(p_token)`, gate `('school_admin','super_admin','executive')` (`20260816000000_executive_school_stats.sql`) | `UserAdminService.countUsersByRole()` |
| สายการเรียน (programs) + จำนวนนักเรียน + เกรดเฉลี่ยต่อสาย | **A** | `get_learning_track_overview(p_token)` → `track_id, name, color, sort_order, student_count, room_count, avg_grade_percent`; gate `('school_admin','executive','super_admin')` | `LearningTrackService.getOverview()` — this is a **direct replacement** for the hardcoded `programs` list (3 entries). `avg_grade_percent` replaces the fake `averageGpa`. |
| แยกตามระดับชั้น ม.1–ม.6 (`gradeData`, 85 lines): นักเรียน/ห้อง per grade | **A (partial)** | `list_learning_track_rooms(p_token)` → `grade_level, room, student_count, track_id, track_name`; gate = `_assert_school_admin` **BUT** grep shows `20260829030000_learning_tracks.sql:324` widened it to `('school_admin','executive','super_admin')` — verify the live definition before relying on it | gives students/rooms per grade. Attendance/behaviour/environment columns of `gradeData` are **C/D**, see below. |
| มาเรียนวันนี้ % (school-wide), ขาด, มาสาย | **C** | tables `homeroom_attendance_records` (student_id, grade_level, room, class_date, status) and `attendance_records` (course-scoped). Only `list_homeroom_attendance(p_token, p_grade_level, p_room, p_class_date)` exists — **one room at a time**, no school-wide aggregate | need `get_school_attendance_summary(p_token, p_date)` returning `(total, present, absent, late, leave)` and `list_attendance_by_grade(p_token, p_date)` returning per-grade rows. Gate helper `_assert_homeroom_access` already accepts `executive`. |
| เคสดูแลช่วยเหลือ (`urgentStudents`, 37 lines) | **B** | `list_student_support_cases(p_token, p_course_id, p_status)` → case_id, student_name, category, risk_level, status, title, notes, intervention_count. Gate: `if v_actor.role <> 'teacher' and v_actor.role <> 'school_admin'` — **executive rejected** | widen in a new migration. Service exists: `StudentSupportService.listCases()`. This is the single highest-value widening on the whole Executive surface. |
| นักเรียนกลุ่มเสี่ยงอัตโนมัติ (งานค้าง/ขาดเรียน/เกรดต่ำ) | **B** | `list_students_needing_attention(p_token)` → student_id, student_name, reason, detail, action_label, severity. Gate: `IF v_actor.role != 'teacher'` — **executive rejected**, and its body is scoped to *the calling teacher's own courses* | widening alone is not enough: needs a school-wide variant (`p_scope`/school branch) since the CTEs join `course_teachers.teacher_id = v_actor.user_id`. Treat as **B + body change**. Service: `StudentSupportService.listAutoFlaggedStudents()`. |
| การลาของนักเรียน | **A** | `list_leave_requests_for_review(p_token, p_status)`, gate `('teacher','school_admin','executive')` | `LeaveService.listPendingLeaveRequests()` |
| `followUps` (4 director action cards) | **D** | no table for director follow-up items / มติสั่งการ | these are narrative summaries; either compute them from the above real numbers in Dart, or drop them. Do **not** invent a table for prose. |
| โครงการเยี่ยมบ้าน 93.8% | **D** | no home-visit table | drop or product decision |

**Effort class: needs-role-widening + needs-new-RPC.** ~60% of this page is reachable today
(programs, tracks, head counts, leave, classroom overview). The at-risk/support sections need
two role widenings; the daily attendance strip needs one new aggregate RPC.

## 3.7 `director_meetings_page.dart` (2,216 lines) — ประชุมและนัดหมาย

| what it must show | verdict | exact RPC / table | notes |
|---|---|---|---|
| รายการประชุม (127 lines): หัวข้อ, วัน+**เวลา**, ห้อง, ผู้เข้าร่วม, สถานะ, วาระ, มติ | **D** | **no table**. `school_events` is the closest thing and it has only `id, school_id, title, location, start_date, end_date, event_type, description` — **no time-of-day, no attendees, no agenda, no minutes, no organiser**, and `event_type` is constrained to `('holiday','public_holiday','exam','activity','study')` — there is no `'meeting'` value (`20260903010000_school_events_calendar_types_and_rpc.sql:22`) | |
| คำขอเข้าพบ / นัดหมายผู้อำนวยการ (37 lines) | **D** | no table, no RPC, no notification type for it | |
| สรุปการ์ด (ประชุมสัปดาห์นี้ / รอตอบรับ / …) | **D** | derived from the above | |

**Effort class: needs-new-schema.** This is the page master-plan 3.7 already flags as a
decision. Two honest options, and only these two:
1. **Disable / hide the tab** (0.3 session) — remove it from `director_navigation_shell.dart`.
2. **Build it for real** — new tables `meetings`, `meeting_attendees`, `meeting_requests`
   (+ minutes), ~6 RPCs, a `MeetingService`. That is a feature, not a wiring task.

A tempting middle path — reuse `school_events` with a new `'meeting'` event_type — is
**not sufficient**: no start/end time, no attendee list, no accept/decline. Recommend not
half-building it on `school_events`.

## 3.2 `director_teachers_page.dart` (1,927 lines) — ครูและบุคลากร

> **✅ เชื่อมแล้ว (2026-09-07)** — 1,927 → 1,243 บรรทัด · `list_staff_directory` +
> `list_departments` จาก migration `20260907000000_staff_org_structure.sql`
> (ตาราง `departments` / `department_members` / `staff_profiles` · pgTAP 18/18)
> ทีมโรงเรียนยืนยันว่าใช้ทั้งฝ่ายและกลุ่มสาระจริง จึงสร้างสคีมาแทนที่จะลบการ์ดทิ้ง
> ของที่สคีมายังไม่รองรับ **ถูกลบ ไม่ได้แสดงเป็น 0**: การมาปฏิบัติงาน/มาสาย/ลา
> ของบุคลากร · เข้าสอนตามตาราง % · ภาระงาน % — แสดงเป็นช่องว่างที่บอกเหตุผลแทน
> test: `test/executive/director_teachers_honesty_test.dart` (5 ตัว)

| what it must show | verdict | exact RPC / table | notes |
|---|---|---|---|
| รายชื่อครู/บุคลากร: ชื่อ, อีเมล, บทบาท, สถานะบัญชี (`personnel`, 151 lines) | **B** | `list_school_users(p_token)` → `user_id, first_name, last_name, email, active_role, all_roles[], active_school_id, status`. Gate: `('school_admin','super_admin')` — **executive rejected** (`20260826130000_list_school_users_all_roles.sql`) | wrapper exists: `UserAdminService.getAllUsers()`. Widening this one RPC turns the entire personnel directory real. Master plan 3.2's guess ("น่าจะ reuse getAllUsers ได้") is **correct**, with the caveat that it is a role widening, not a straight reuse. |
| จำนวนครู/บุคลากรทั้งหมด, แยกบทบาท | **A** | `count_school_users_by_role(p_token)` — executive allowed | |
| ตำแหน่ง (ครูชำนาญการ…), เบอร์โทร, ฝ่าย, กลุ่มสาระ | **D** | `users` has no `position`/`phone`/`department` column; there is no `departments` or `subject_groups` table | `departmentData` (67 lines) and `subjectGroups` (9 entries) are pure invention. Needs schema (`staff_profiles` + `departments`) or drop those sections. |
| มาปฏิบัติงานวันนี้ / ลา / มาสาย ของครู | **D** | there is **no staff attendance table**. `homeroom_attendance_records` and `attendance_records` are both student-scoped; `leave_requests` is student leave (`student_id` + `parent_id` NOT NULL) | the entire `_todayStatusCard()` is unbackable today |
| ครูประจำชั้น (homeroom) ต่อห้อง | **A** | `list_homeroom_assignments(p_token)` → `assignment_id, grade_level, room, teacher_id, teacher_name, student_count`; gate `('school_admin','super_admin','executive')` | `HomeroomService.listHomeroomAssignments()` — real, executive-allowed, unused by this page today |
| ตารางสอนของครู / เข้าสอนตามตาราง 96% | **A for the schedule, D for the compliance %** | `list_all_school_schedules(p_token)` → schedule_id, course_id, subject_name, day_of_week, start_time, end_time, room; gate `('executive','school_admin')`. `list_teacher_schedules` is `('teacher','school_admin')` = **B** but redundant | nothing records whether a teacher actually started a period on time → the 96% is **D** |
| ภาระงาน (workload %) | **C** | derivable: `course_teachers` × `class_schedules` × `courses` | a `get_teacher_workload(p_token)` RPC could count periods/courses per teacher honestly |

**Effort class: needs-role-widening** for the directory (the valuable half), **needs-new-schema**
for departments / staff attendance / staff leave (recommend deleting those cards rather than
inventing tables).

## 3.3 `director_reports_page.dart` (1,705 lines) — รายงาน

| what it must show | verdict | exact RPC / table | notes |
|---|---|---|---|
| คลังไฟล์รายงานที่ฝ่ายต่างๆ ส่งขึ้นมา (`reports`, 191 lines): ชื่อไฟล์, ประเภทไฟล์/ขนาด/จำนวนหน้า, ผู้ส่ง+ตำแหน่ง, ฝ่าย, ช่วงเวลา, สถานะ (ส่งแล้ว/รอตรวจ/อนุมัติ/ต้องแก้ไข/เกินกำหนด) | **D** | **no table.** `course_files` is the only document table and it is course-scoped (teacher/student coursework), not a school report register | |
| `pendingReports` (31 lines) — รายงานที่รอผู้อำนวยการตรวจ | **D** | no approval workflow table | |
| ฝ่ายผู้ส่ง (ฝ่ายวิชาการ / ฝ่ายบุคคล …) | **D** | no departments table (same gap as 3.2) | |

**Effort class: needs-new-schema.** Requires a `school_reports` table + upload pipeline
(Edge Function + signed URL, copying `course-file-upload`/`-download` per CLAUDE.md hard
rule 3) + a review/approve state machine. This is a genuine feature.

**However** — there is a much cheaper, *honest* version of this page worth proposing to the
product owner: an **on-demand generated report** view built entirely from data that already
exists and is already executive-readable — attendance, incidents (`get_incident_summary`),
utilities (`get_energy_usage_summary`/`get_water_usage_summary`/trends/efficiency),
learning tracks. That is `reuse-only` and needs zero backend. It is a different page from
the "inbox of PDFs sent by departments" that is currently mocked.

## 3.4 `director_scan_page.dart` (1,082 lines) — สแกน QR

| what it must show | verdict | exact RPC / table | notes |
|---|---|---|---|
| สแกนบัตรครู → แสดงชื่อ/รหัส/กลุ่มสาระ/ตำแหน่ง (`teachers`, 25 lines) | **D** | no staff ID-card/QR identity, no `position`/`subject group` columns | |
| "เข้างานแล้ว 07:52 น." — staff check-in by scan | **D** | no staff attendance table (confirmed above) | this is the core of the page and it is entirely unmodelled |
| สแกนชุดฝึก/อุปกรณ์ → ชื่อ, รหัส, หมวด, สถานะ (`kits`, 25 lines) | **A (identity only)** | `devices` has `kit_code`, `device_code`, `name`, `type`, `status`, `location`, `building`, `room`. `list_school_devices(p_token)` gate is `('school_admin','super_admin','teacher','executive')` (`20260826080000_allow_executive_list_school_devices.sql`) — **executive explicitly allowed**; also `list_teaching_kit_devices(p_token)` = **B** (`('teacher','school_admin')`) | scanning a `kit_code` and resolving it to a real device is doable **today** with `LessonService.listSchoolDevices()` / `RealtimeService`; a nicer `get_device_by_code(p_token, p_code)` would be **C** |
| "กำลังถูกยืม / ยืมโดย ม.6/1 / กำหนดคืน 25 ส.ค." | **D** | no lending/loan table anywhere | |
| `recent` scan history (7 entries) | **D** | no scan-event table (`audit_logs` could host it, but nothing writes scan events) | |

Note: the existing `create_terminal_pairing_session` / `claim_terminal_pairing_session` /
`peek_terminal_pairing_session` / `check_terminal_pairing_status` RPCs are a **QR pairing
flow for classroom terminals** — unrelated to this page's purpose. Do not repurpose them.

**Effort class: needs-new-schema** (staff check-in + equipment lending), with one
`reuse-only` slice (resolve a scanned kit/device code against `devices`).

## 3.6 `director_settings_page.dart` (1,790 lines) — ตั้งค่า

| what it must show | verdict | exact RPC / table | notes |
|---|---|---|---|
| ชื่อที่แสดง (แก้ได้) | **A** | `update_user_profile(p_token, p_target_user_id, p_first_name, p_last_name)` — allows self-edit for **any** role (`v_actor.user_id = p_target_user_id` branch), `20260716000000_user_admin_rpc.sql` | |
| อีเมล / ชื่อโรงเรียน (read-only display) | **A** | already in the session actor / `get_session_actor`; schools name via existing school context | |
| เบอร์โทรศัพท์ | **D** | `users` has no `phone` column | either add a column + widen `update_user_profile`, or remove the field |
| รูปโปรไฟล์ | **D** | no avatar column, no avatar storage bucket flow | |
| เปลี่ยนรหัสผ่าน | **A (via OTP path)** | `request_password_reset_otp` + `confirm_password_reset` (`20260716010000_password_reset_rpc.sql`). There is **no** in-session `change_password(p_token, old, new)` RPC — that would be **C** | today's dialog collects current+new password with no backend at all; wire it to the OTP pair, or add the in-session RPC |
| ออกจากระบบทุกอุปกรณ์ | **A** | `auth_sign_out_all` | |
| 2FA / แจ้งเตือนเมื่อ login จากอุปกรณ์ใหม่ | **A (partly)** | trusted-device system exists (`20260829000000_trusted_devices_remember_login.sql`, `20260829010000_trusted_devices_account_wide.sql`, `trusted_devices` table); `executive` is already in the 2FA-required list in `auth_sign_in` | 2FA for executive is **already mandatory** — the toggle is misleading UI. There is no "list/revoke my trusted devices" RPC → **C** if you want that panel. |
| การแจ้งเตือนที่ต้องการรับ (6 toggles), ระดับความสำคัญ, ช่องทาง | **D** | **no per-user preferences table.** `school_settings` has `email_notify`/`line_notify` but is school-wide and school_admin-scoped | |
| Dashboard preferences (หน้าเริ่มต้น, ช่วงข้อมูล, ความหนาแน่น) | **D** | no table | could be stored client-side (`shared_preferences`) with **zero backend** — recommended |
| รายงาน/สรุปรายวัน-รายสัปดาห์ ส่งเข้าอีเมล | **D** | no digest scheduler, no email sender in-app | |

### ✅ เสร็จแล้ว 2026-09-07 — ไฟล์ลดจาก 1,789 เหลือ ~1,100 บรรทัด

หน้านี้ **ไม่ได้ import `shared_core` เลย** แต่มีปุ่มบันทึกครบ `_saveSettings()`
แค่ตั้ง `hasChanges = false` แล้วขึ้น "บันทึกการตั้งค่าของผู้อำนวยการแล้ว" โดยไม่เรียกอะไร
— ตั้งค่าทุกอย่างย้อนกลับทันทีที่เปิดหน้าใหม่

| ที่พบ | แก้เป็น |
|---|---|
| บัญชี seed ด้วย `ผู้อำนวยการโรงเรียน` / `director@school.ac.th` / `โรงเรียนตัวอย่าง` | **ผู้อำนวยการทุกคนเห็นบัญชีสมมติเดียวกัน** → อ่านจาก `currentUserModel` |
| ปุ่มบันทึกที่ไม่บันทึกอะไร | ต่อ `update_user_profile` จริง · `hasChanges` เทียบกับชื่อที่ backend ยืนยันแล้ว ไม่ใช่ bool ที่พลิกทุกครั้งที่พิมพ์ |
| **dialog เปลี่ยนรหัสผ่าน** เก็บรหัสเก่า/ใหม่/ยืนยัน แล้วขึ้น "เปลี่ยนรหัสผ่านเรียบร้อยแล้ว" | **รหัสไม่เคยเปลี่ยน — คนที่เชื่อจะใช้รหัสเก่าต่อโดยคิดว่าเลิกใช้แล้ว** → บอกตรงว่าต้องใช้ OTP ทางหน้าลืมรหัสผ่าน (ไม่มี RPC เปลี่ยนรหัสในเซสชัน) |
| **"ออกจากระบบทุกอุปกรณ์"** ขึ้นว่าสำเร็จโดยไม่เรียกอะไร | **คนที่สงสัยว่าบัญชีถูกเปิดบนเครื่องคนอื่นถูกบอกว่าปิดแล้ว ทั้งที่ทุก session ยังอยู่** → ต่อ `auth_sign_out_all` จริง + dialog ยืนยัน |
| สวิตช์ 2FA แสดง "ปิด" และกดเปลี่ยนได้ | `auth_sign_in` **บังคับ MFA กับ `executive` ทุกครั้งอยู่แล้ว** — แสดงผิดในทางที่ทำให้บัญชีดูปลอดภัยน้อยกว่าจริง → เปลี่ยนเป็นข้อความสถานะอ่านอย่างเดียว |
| เบอร์โทร / รูปโปรไฟล์ | `users` ไม่มีคอลัมน์ → ลบช่องกรอก บอกว่ายังไม่รองรับ |
| การแจ้งเตือน 6 หัวข้อ · ช่องทาง · ระดับความสำคัญ · หน้าเริ่มต้น · ความหนาแน่น · รูปแบบไฟล์ · digest รายวัน/สัปดาห์ | **ไม่มีตาราง preference รายบุคคลในสคีมาเลย** (`school_settings` เป็นระดับโรงเรียนและ school_admin เท่านั้น) → รวมเป็นการ์ด "ยังไม่เปิดใช้งาน" 3 ใบพร้อมเหตุผล ไม่มีสวิตช์เหลือสักตัว |

test: `test/executive/director_settings_honesty_test.dart` (7 ชุด)

**Effort class: needs-new-schema for the preference sections, reuse-only for the account
sections.** Cheapest honest outcome: wire profile name + sign-out-all + password change to
real RPCs, keep the display/dashboard preferences purely local, and delete the notification
channels/digest cards (or mark them clearly as ยังไม่เปิดใช้งาน) until a
`user_preferences` table is a product decision.

---

# Part 2 — the five partially-connected pages (master-plan 3.1)

These are more dangerous than the disconnected ones: they look verified because one real
call succeeds, while a large hardcoded table renders beneath it.

## `director_classrooms_page.dart` (3,157 lines)

Real today: `ExecutiveService.getClassroomsOverview()` → 3 numbers, and even those have
**fake fallbacks** (`director_classrooms_page.dart:736-738`:
`_overview?.roomCount.toString() ?? '36'`, `?? '1,248'`, `?? '64'` — a silent fake default,
exactly the anti-pattern in DATA_CONNECTION_METHODOLOGY §2).

| what it must show | verdict | exact RPC / table |
|---|---|---|
| จำนวนห้อง / นักเรียน / งานครบกำหนดสัปดาห์นี้ | **A** | `get_classrooms_overview` (already wired; **remove the `?? '36'` fallbacks**) |
| รายห้อง ม.x/y: ห้องเลขที่, ครูประจำชั้น, จำนวนนักเรียน (`classrooms`, 205 lines) | **A** | `list_homeroom_assignments(p_token)` gives `grade_level, room, teacher_name, student_count` for every homeroom, executive-allowed. Room number/floor/capacity: `list_school_rooms(p_token, p_building_id)` = **B** (gate `('school_admin','super_admin')`) |
| สายการเรียนของแต่ละห้อง | **A** | `list_learning_track_rooms(p_token)` → `grade_level, room, track_id, track_name` |
| attendance / learning / behavior / environment score per room | **C / D** | attendance per room: **C** (new aggregate over `homeroom_attendance_records`). learning score: **C** (aggregate over `grades`). behavior & environment score: **D** — nothing in the schema computes them |
| งานสัปดาห์นี้ / งานค้าง ต่อห้อง | **C** | `assignments` + `submissions` + `course_students` exist; no room-scoped RPC |
| คาบถัดไป (`nextClass`) | **A** | `list_all_school_schedules(p_token)` (executive-allowed) — has room, day, start/end time |
| Green score ต่อห้อง | **D** | no such metric in schema |

**Effort class: needs-role-widening + needs-new-RPC.** A large majority of the fake
per-room table can be replaced today by joining three executive-allowed RPCs in Dart.

### ✅ เสร็จแล้ว 2026-09-07 — ไฟล์ลดจาก 3,201 เหลือ 2,015 บรรทัด

survey ประเมินว่าเป็น "ตารางห้อง 205 บรรทัด" — พออ่านเต็มพบว่าเป็น**โรงเรียนทั้งโรงเรียน
ที่แต่งขึ้น** และมีการ์ดที่แปลงมันเป็นคำแนะนำให้ผู้อำนวยการลงมือทำ

| ที่พบ | แก้เป็น |
|---|---|
| `classrooms` 205 บรรทัด — ทุกห้องมีชื่อครูประจำชั้น จำนวนนักเรียน และคะแนน 5 ตัว | สร้างจาก `list_homeroom_assignments` + `list_learning_track_rooms` + `list_all_school_schedules` (executive เรียกได้ทั้งสาม) |
| **การ์ด "สิ่งที่ผู้อำนวยการควรติดตาม"** — 4 ประเด็นต่อห้อง พร้อมจำนวนคนและคำสั่งการ | ลบ — ทุกตัวเลขมาจากคะแนนที่แต่งขึ้น คือ**คำแนะนำที่สร้างจากความว่างเปล่า ส่งถึงคนที่มีแนวโน้มจะลงมือทำที่สุด** |
| Green Score จัดอันดับห้อง 12 ห้อง | ลบ — ไม่มี metric ชื่อนี้ในสคีมา ไม่มีสูตรเขียนไว้ที่ไหน |
| ใบงานรายห้อง 5 รายการ ชื่อครู "ครูพรทิพย์ รักษ์ดี" คะแนนเฉลี่ย | ลบ — `assignments`/`submissions` มีจริงแต่ไม่มี RPC รวมยอดต่อห้อง |
| คะแนนรายวิชา 8 วิชา คำนวณจาก `base + (learningScore - 92)` | ลบ — ตัวเลขแต่งปรับด้วยตัวเลขแต่งอีกที |
| ตารางสอน 6 คาบ ชื่อครู "ครูจิราพร ตั้งใจ" สถานะ "สอนแล้ว/กำลังสอน" | ใช้ `list_all_school_schedules` จริง · **ไม่อ้างสถานะ** เพราะไม่มีอะไรบันทึกว่าครูเข้าสอนจริงไหม |
| กลุ่มนักเรียนที่ต้องดูแล 4 หมวด | บอกว่ายังไม่เปิดให้ผู้บริหารดู — `list_student_support_cases` มีจริงแต่ gate ปฏิเสธ `executive` (ต้อง widening) |

**ฟิลด์ที่ตัดออกจาก `_ClassroomData`:** `attendance` `learningScore` `behaviorScore`
`environmentScore` `assignmentsThisWeek` `overdueStudents` `followUpStudents` —
สองกลุ่มแรกคำนวณได้ถ้าเขียน RPC ใหม่ · **behaviour/environment/green ไม่มีทั้งแหล่งข้อมูลและนิยาม**

test: `test/executive/director_classrooms_honesty_test.dart` (5 ชุด)

## `director_cctv_page.dart` (1,822 lines)

Real today: `ExecutiveService.listCameraAccessGrants()` / `grantCameraAccess` /
`revokeCameraAccess` — the *access-governance* half is genuinely wired.

| what it must show | verdict | exact RPC / table |
|---|---|---|
| รายการกล้อง: ชื่อ, อาคาร, ตำแหน่ง, สถานะ online/offline (`cameras`, 105 lines) | **A** | `devices` where `type = 'camera'` (enum value exists, `20260715000000_initial_schema.sql:62`), fields `name, location, building, room, status, last_seen_at`. `list_school_devices(p_token)` allows `executive`. Filter client-side, or add a typed RPC (**C**, optional) |
| สิทธิ์เข้าดูกล้อง (ใคร ดูได้ถึงเมื่อไหร่ เหตุผล) | **A** | `list_camera_access_grants` / `grant_camera_access` / `revoke_camera_access`, all `('executive','school_admin','super_admin')` |
| การแจ้งเตือนจากกล้อง / AI detection (`alerts`) | **C** | table `security_events` exists (`camera_device_id, event_type, detected_at, metadata, clip_object_key, status, reviewed_by, review_note, retention_expires_at`) but **no RPC reads it** — grep found zero `from security_events` in any RPC. Needs `list_security_events(p_token, p_status)` + a signed-URL download for `clip_object_key` |
| ภาพสด / บันทึกวิดีโอ / toggle AI ต่อกล้อง | **D** | no stream URL, no recording-state, no per-camera AI config in schema |

**Effort class: needs-new-RPC** (`security_events`), with the camera inventory being
`reuse-only` today.

## `director_emergency_page.dart` (4,480 lines)

The **best-wired** Executive page: `EmergencyService.listEmergencyEvents` +
`streamEmergencyEvents`, `IncidentService.getIncidentSummary`,
`listTeacherIncidentReports`, `acknowledgeIncidentReport`, `closeIncidentReport`,
`acknowledgeEmergencyEvent`, `closeEmergencyEvent` — all real, all executive-allowed
(`list_emergency_events` `('school_admin','teacher','executive')`;
`list_incident_reports` `('teacher','school_admin','executive')`;
`get_incident_summary` `('teacher','school_admin','executive','super_admin')`).

| leftover fake | verdict | notes |
|---|---|---|
| `events` const list (86 lines) | **A** — delete it | the real stream already supplies this; the const list is a leftover mock |
| response teams / เวรฉุกเฉิน (29 lines) | **D** | no `emergency_teams`/duty-roster table |
| incident action trail | **A** | `list_incident_actions(p_token, …)` gate `('teacher','school_admin','executive')` (`20260905030000_list_incident_actions.sql`); also `get_incident_report_for_staff` (`20260904010000`) — both executive-allowed and unused here |

**Effort class: reuse-only** (delete the mock; optionally add the action trail). Do this first.

### ✅ เสร็จแล้ว 2026-09-07 — และเจอมากกว่าที่สำรวจไว้

survey เดิมเขียนว่าเหลือแค่ "ลบ `events` const 86 บรรทัด + response teams"
พออ่านเต็ม 4,480 บรรทัดพบว่าหนักกว่านั้น เพราะ **ทุกจุดที่อ่านของปลอมถูกกั้นด้วย
`_hasRealData ? จริง : ปลอม` และ `_hasRealData` เป็น false พอดีตอนที่โรงเรียน
"ไม่มีเหตุอะไรเลย"** — สถานะที่ปลอดภัยที่สุดจึงถูกวาดเป็นสถานะที่แย่ที่สุด

| ที่พบ | แก้เป็น |
|---|---|
| hero card แต่ง SOS ขึ้นมาทั้งใบ: "SOS จากนักเรียน ห้อง ม.3/2" · "อาคาร 3 ชั้น 2" · "แจ้งมา 28 วิ" · **ผู้แจ้ง "ครูสมหญิง ใจดี"** | ไม่มีเหตุจริง = ไม่วาดการ์ด · แสดง "ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่" |
| **เวรฉุกเฉิน 4 ทีม ชื่อครูที่ไม่มีอยู่จริง** (ครูสมชาย ครูพิมพ์ใจ ครูสุพรรณี อ.วินัย) พร้อมสถานะ "กำลังไปจุดเกิดเหตุ" | ลบทั้งบล็อก — ไม่มีตารางเวรในสคีมา · แทนด้วย empty state ที่บอกให้ประสานทางช่องทางอื่น |
| `events` const 86 บรรทัด + counter ที่นับจากมัน (`sosPendingCount` fallback เป็นเลข `1`) | ลบ · นับจาก DB อย่างเดียว |
| `catchError` กลืน error ของทั้ง 3 read เป็น list ว่าง | **แยก "โหลดไม่สำเร็จ" ออกจาก "ไม่มีเหตุ"** — บนหน้านี้สองอย่างนี้หมายตรงข้ามกัน |
| หน้าเรียก stream ตรงใน `initState` → assert ตายก่อน build ใน test | เพิ่ม seam + `watchUpdates: false` — **ก่อนหน้านี้หน้านี้ไม่มี test ที่รันได้เลย** |
| 🐛 `if (active.isEmpty) Expanded(...)` ในคอลัมน์ที่ความสูงไม่จำกัด | บั๊ก layout ที่ทำให้ `infinite_height_layout_audit` fail มานาน — **ข้อมูลปลอมกลบไว้เพราะ `active` ไม่เคยว่าง** พอลบของปลอม สาขานี้กลายเป็นสถานะปกติและ assert ทุกครั้ง · แก้แล้ว layout audit เหลือ 2 จาก 3 |

test: `test/executive/director_emergency_page_honesty_test.dart` (5 ชุด)

**ยังเหลือ:** ยังไม่คลิกจริงในเบราว์เซอร์ · `director_emergency_page_test.dart`
เดิมยัง fail (หาข้อความที่ไม่มีในหน้ามานานแล้ว — ticket 1.3)

**เจอระหว่างทาง ยังไม่แก้:** `director_environment_page` ประกาศฟิลด์
`_energySummary` `_waterSummary` `_energyTrend` `_waterTrend` `_energyScore`
`_waterScore` แล้ว**ไม่ได้ใช้เลยสักตัว** (analyze แจ้ง unused_field 6 จุด) —
รูปแบบเดียวกับ `director_academic_calendar_page` ที่ดึงข้อมูลมาแล้วทิ้ง

## `director_environment_page.dart` (2,177 lines)

Real today: all six `UtilityService` calls + `AiotLabService.getLatestSensorReadings()`.
All the underlying utility RPCs allow `executive`
(`get_energy_usage_summary`, `get_water_usage_summary`, `get_energy_usage_trend`,
`get_water_usage_trend`, `get_energy_efficiency_score`, `get_water_efficiency_score`,
`get_school_utility_rates` — role list `('school_admin','teacher','executive','student','super_admin')`).

| leftover fake | verdict | notes |
|---|---|---|
| `electricityRates` / `waterRates` reference cards | **A** — delete the const | `get_school_utility_rates(p_token)` returns the real rate **and** `is_electricity_default`/`is_water_default` so you can honestly label a default vs a configured rate |
| `electricityBreakdown` / `waterBreakdown` (per-building usage split) | **C** | `sensor_readings` + `devices.building` support it; no RPC aggregates by building. Sketch: `get_utility_usage_by_building(p_token, p_metric text, p_days int)` → `(building text, value numeric, share numeric)` |
| `zones` (per-zone PM2.5 / CO₂ / temp) | **A** | `sensor_latest` allows executive (`20260903000000_fix_sensor_latest_school_scope_leak.sql`, roles include `'executive'`); the page already calls `getLatestSensorReadings()` — group by `devices.building`/`room` in Dart. ⚠️ per CLAUDE.md/methodology, check `metricUpdatedAt.containsKey(metric)` before trusting a 0 reading |
| `recommendations` (advice text) | **D** | no recommendation engine; either compute in Dart from thresholds or drop |
| threshold breach alerts | **B** | `list_school_alerts(p_token, p_status)` exists with a full shape (device_name, metric, value, triggered_at, status, acknowledged_by_name) but gate is `('teacher','school_admin','super_admin')` — **executive rejected** (`20260826160000_teacher_aiot_thresholds.sql`). Same for `acknowledge_sensor_alert` / `resolve_sensor_alert`. `list_thresholds` likewise. |

**Effort class: needs-role-widening (alerts) + needs-new-RPC (per-building breakdown).**

### ✅ เสร็จแล้ว 2026-09-07 — หน้านี้ดึงข้อมูลจริงมา 7 ชุดแล้วไม่ใช้เลยสักชุด

`_loadUtilityData()` เรียก `UtilityService` ครบ 6 ตัว + `getLatestSensorReadings`
เก็บลงฟิลด์ แล้ว**ไม่มีที่ไหนอ่านฟิลด์เหล่านั้นเลย** — analyze แจ้ง `unused_field`
6 จุดมาตลอดโดยไม่มีใครสังเกต ที่แสดงจริงคือบล็อกที่ในไฟล์เขียนกำกับเองว่า `// MOCK DATA`

| ที่พบ | แก้เป็น |
|---|---|
| การ์ดสรุป 6 ใบเป็นเลขนิ่ง (`฿82,150` `18,450 kWh` `640 ลบ.ม.` `PM2.5 38` `CO₂ 720`) | ใช้ค่าจาก summary จริง + เฉลี่ยจาก `sensor_latest` · ใช้ `deviceCount` แยก "วัดแล้วได้ศูนย์" จาก "ไม่มีอะไรวัด" |
| **"AI คาดการณ์ค่าใช้จ่ายสิ้นเดือน ฿137,000 · ความมั่นใจ 92% · ประเมินจากประวัติ 12 เดือน"** | ไม่มี AI ไม่มีประวัติ 12 เดือน ไม่มีฐานของตัวเลขความมั่นใจ → เปลี่ยนเป็นประมาณการเชิงเส้นจากยอดถึงวันนี้ พร้อมบอกวิธีคิดตรง ๆ |
| คำแนะนำ "AI" 3 ข้อ อ้างว่า **"AI พบว่าอาคาร 2 เปิดแอร์ก่อนเข้าเรียน 40 นาที"** | ลบ — ไม่มีการติดตามอุปกรณ์รายตัวในระบบ |
| โซนคุณภาพอากาศ 5 โซนพร้อมค่า PM2.5/CO₂/อุณหภูมิ | สร้างจาก `sensor_latest` ที่โหลดมาอยู่แล้ว จัดกลุ่มตาม `location` · โซนที่ไม่เคยรายงานไม่ตัดสินว่า "ดี" |
| แยกการใช้ไฟรายอาคาร 6 อาคาร + น้ำ 4 หมวด | ลบ — ไม่มี RPC รวมยอดรายอาคาร และ `devices.building` เป็น null ทุกแถว |
| กราฟ 7 วัน + กราฟรายชั่วโมง เป็นค่าคงที่ | 7 วันใช้ `get_*_usage_trend` จริง · รายชั่วโมงลบทิ้ง ไม่มีข้อมูลรายชั่วโมงในสคีมา |
| ตารางอัตราค่าไฟ 5 แถว (`4.1839 บาท/หน่วย` · ค่า Ft · ค่าบริการ · VAT) | `school_settings` มีแค่อัตราเดียว → แสดงอัตราจริง + `isRateDefault` ว่าเป็นอัตรากลางหรือของโรงเรียน |
| หัวข้อ "เดือนนี้ (1 - 21 ส.ค. 2569)" ตรึงไว้ | คำนวณจากวันจริง |
| `catch (_) {}` | แยก loading / error + ปุ่มลองใหม่ |

test: `test/executive/director_environment_honesty_test.dart` (6 ชุด)

## `director_academic_calendar_page.dart` (1,399 lines)

⚠️ **This page is effectively 100% fake despite appearing wired.** Its only backend call is:

```dart
Future<void> _loadSchoolSchedules() async {
  try {
    await ExecutiveService.listAllSchoolSchedules();   // result discarded
  } catch (_) {}
}
```

The return value is never assigned or rendered; every event comes from `_initCalendarEvents()`,
hardcoded to August 2026.

| what it must show | verdict | exact RPC / table |
|---|---|---|
| ปฏิทินกิจกรรม/สอบ/วันหยุดของโรงเรียน | **A** | `list_calendar_events(p_token)` → `event_id, title, description, location, start_date, end_date, event_type` — **has no role gate at all** (only `invalid_session` + school resolution), so `executive` can call it today. RPC is currently only wrapped in `parent_portal_service.dart:123`; add a method to `calendar_service.dart` (or reuse) |
| ตารางเรียน/ตารางสอนทั้งโรงเรียน | **A** | `list_all_school_schedules(p_token)`, gate `('executive','school_admin')` — already in `ExecutiveService`, just **use the result** |
| ภาคเรียน / ปีการศึกษา | **B** | `list_terms(p_token)` gate `('teacher','school_admin')` — executive rejected |
| เวลาเริ่ม-สิ้นสุดของกิจกรรม (09:00-10:30) | **D** | `school_events` stores dates only, no time-of-day columns |
| หมวด "ประชุม" | **D** | `event_type` check constraint is `('holiday','public_holiday','exam','activity','study')` — no meeting type |
| ผู้อำนวยการสร้าง/แก้กิจกรรมเอง | **B** | `create_school_event(p_token, …)` gate `('school_admin','super_admin')` — executive rejected. (Note: no `update_school_event`/`delete_school_event` exists at all → **C** if editing is needed) |
| `alerts` (33 lines hardcoded) | **A/D** | reminders can be derived from real events; the mock list should go |

**Effort class: reuse-only for read**, needs-role-widening if the director should create
events, needs-new-schema for meeting-type events with times.

---

# Part 3 — consolidated answers

## (a) Every RPC that needs role-widening for `executive`

Ordered by value. Each is a `create or replace` in one new migration adding `'executive'`
to an existing `IN (...)` list — except where noted.

| # | RPC | current gate | defining migration (latest) | unlocks |
|---|---|---|---|---|
| 1 | `list_school_users` | `('school_admin','super_admin')` | `20260826130000_list_school_users_all_roles.sql` | the whole `director_teachers` personnel directory |
| 2 | `list_student_support_cases` | `'teacher'` or `'school_admin'` only | `20260823040000_terminal_pairing_and_student_support.sql` | `director_learning` care/at-risk section |
| 3 | `list_student_support_interventions` | `'teacher'` or `'school_admin'` only (verified) | `20260823040000` | case detail drill-down |
| 4 | `list_school_alerts` | `('teacher','school_admin','super_admin')` | `20260826160000_teacher_aiot_thresholds.sql` | `director_environment` threshold alerts |
| 5 | `list_thresholds` | `('teacher','school_admin','super_admin')` (verified) | `20260826160000` | showing what the alert limits are |
| 6 | `list_school_rooms` | `('school_admin','super_admin')` | `20260826110000_school_admin_redesign_phase2_batch2.sql` | room number/floor/capacity on `director_classrooms` |
| 7 | `list_school_buildings` | `('school_admin','super_admin')` | `20260826110000` | building filter on CCTV / environment |
| 8 | `list_terms` | `('teacher','school_admin')` | `20260724000000_classroom_core.sql` | term selector on calendar/learning |
| 9 | `create_school_event` | `('school_admin','super_admin')` | `20260903030000_parent_portal_rpc_hardening.sql` | director creating calendar entries (**only if** product wants write access) |
| 10 | `list_teaching_kit_devices` | `('teacher','school_admin')` | `20260821000000_aiot_lab_teaching_kit_rpcs.sql` | kit lookup on `director_scan` (partly redundant with `list_school_devices`) |
| 11 | `list_teacher_schedules` | `('teacher','school_admin')` | `20260826040000_list_teacher_schedules.sql` | per-teacher schedule (redundant with `list_all_school_schedules` — likely skip) |
| 12 | `list_students_needing_attention` | `'teacher'` only **and body is scoped to the caller's own courses** | `20260828000000_students_needing_attention.sql` | ⚠️ **not a pure widening** — needs a school-wide branch in the body, not just a role added |

Before writing the migration, confirm each gate against the *live* database, not just the
file (methodology §3.1/§4) — and remember hard rule 3: any of these also called from the
service-role client needs an explicit `grant execute ... to service_role`.

## (b) Genuinely missing capabilities (verdict D — product decisions, not coding tasks)

1. **Meetings** — meetings, attendees, agendas, minutes, meet-requests. Blocks all of
   `director_meetings` (2,216 lines). `school_events` cannot stand in (no time, no attendees,
   no `'meeting'` event_type).
2. **Report register** — a school-level document submission/review pipeline. Blocks all of
   `director_reports` (1,705 lines). `course_files` is course-scoped only.
3. **Staff attendance / check-in** — no table. Blocks `director_scan`'s primary function and
   `director_teachers`'s "มาปฏิบัติงานวันนี้" cards.
4. **Staff leave** — `leave_requests` is student leave (`student_id` + `parent_id` NOT NULL).
   There is no teacher leave anywhere.
5. **Organisational structure** — no `departments` (ฝ่าย) and no `subject_groups` (กลุ่มสาระ)
   table; `users` has no `position`/`department`/`phone`/`avatar`. Blocks the department and
   subject-group sections of `director_teachers` and the "ฝ่ายผู้ส่ง" filter of `director_reports`.
6. **Equipment lending (ยืม-คืน)** — no loan table; `devices` tracks inventory only.
7. **Per-user preferences** — no notification-preference, digest, or dashboard-default table.
   Blocks most of `director_settings`. (Dashboard defaults could live client-side instead.)
8. **CCTV live stream / recording / per-camera AI config** — `devices` (`type='camera'`) and
   `security_events` cover *inventory* and *detected events*, nothing about streaming.
9. **Behaviour score, environment score, green score, home-visit progress, on-time-teaching %** —
   composite metrics with no defining formula or source table anywhere. These fabricated
   numbers appear on `director_learning`, `director_classrooms`, and `director_teachers`.
10. **Scan-event history** — nothing writes scan events (`audit_logs` could host them, but no
    producer exists).

## (c) Pages finishable with ZERO new backend — do these first

Ranked by value-per-session. All data below was verified executive-allowed.

| order | page | what to do | why it's free |
|---|---|---|---|
| 1 | `director_emergency_page` | delete the `events` const (86 lines) and the response-teams block; optionally add `list_incident_actions` + `get_incident_report_for_staff` | already fully wired to executive-allowed RPCs; the mock is dead weight sitting *next to* real data — the most dangerous kind |
| 2 | `director_academic_calendar_page` | wire `list_calendar_events` (no role gate at all) + actually **use** the discarded `listAllSchoolSchedules()` result; delete `_initCalendarEvents()` and the 33 mock alerts | currently 100% fake while appearing connected |
| 3 | `director_environment_page` | delete the hardcoded rate cards (use `get_school_utility_rates` incl. `is_*_default`); build the zone table from the `sensor_latest` data it already fetches | executive already allowed on every utility + sensor RPC |
| 4 | `director_classrooms_page` | remove the `?? '36' / '1,248' / '64'` fake fallbacks; rebuild the 205-line room table from `list_homeroom_assignments` + `list_learning_track_rooms` + `list_all_school_schedules` | three executive-allowed RPCs cover room, homeroom teacher, student count, track, next period |
| 5 | `director_cctv_page` | replace the 105-line camera mock with `list_school_devices` filtered to `type='camera'` | `20260826080000` explicitly added `executive` to that RPC |
| 6 | `director_learning_page` (partial) | replace the 3-entry `programs` mock with `LearningTrackService.getOverview()`; replace grade rows with `list_learning_track_rooms`; head-counts from `count_school_users_by_role` + `get_classrooms_overview`; student leave from `list_leave_requests_for_review` | leaves only the attendance strip and at-risk list waiting on (a)/(C) |
| 7 | `director_settings_page` (partial) | wire display name (`update_user_profile`), sign-out-all (`auth_sign_out_all`), password change (`request_password_reset_otp` + `confirm_password_reset`); keep dashboard defaults client-side; remove or clearly disable the preference toggles | |

**Sequencing recommendation:** rows 1–5 (`reuse-only`, master-plan ticket 3.1) → one small
migration covering widenings 1–8 from list (a) → rows 6–7 → then the new-RPC work
(school-wide attendance aggregate, `security_events` reader, per-building utility breakdown)
→ and only then a product decision on the six D-items behind `director_meetings`,
`director_reports`, and `director_scan`.
