# ใบสั่งงาน D6 — แอดมินจัดตารางเรียน → นักเรียนเห็นวิชาตามห้องอัตโนมัติ

> เขียน 2026-09-18 โดยเซสชัน Claude ที่ทดสอบแอปมือถือ · ยืนยันกับโค้ด/DB ที่ commit `3e42722` ทุกข้อ
> ผู้ทำ: agy (หรือเซสชันใดก็ได้) · ผู้ตรวจ: เซสชันที่เขียนใบนี้ จะตรวจทุกเฟสก่อน tick
>
> **อ่านก่อนเริ่ม:** `AGENTS.md` (กติกา commit/branch) · `./scripts/state.sh` ·
> `docs/handoff/DECISIONS_2026-09-18_enrollment_by_timetable.md` (คำสั่งของเจ้าของ — ห้ามตีความใหม่)
> · `docs/handoff/DATA_CONNECTION_METHODOLOGY.md` (กันทำ fallback ปลอม)
>
> baseline ตอนรับงาน: `cd apps/user_app && flutter test` ต้องไม่เพิ่มจำนวน fail ·
> `flutter analyze` ทั้ง `packages/shared_core` `packages/shared_ui` `apps/user_app` ไม่มี error ใหม่ ·
> pgTAP เดิมทุกไฟล์ต้องยังผ่าน
>
> **ห้ามเขียน production** — ทุกอย่างทำบน local (`npx supabase start`) แล้วส่งมอบเป็น
> `scripts/prod_apply_2026-09-19.sh` ให้เจ้าของรันเอง (ดูตัวอย่าง `scripts/prod_apply_2026-09-18b.sh`)

---

## 0. สิ่งที่เจ้าของต้องการ (สรุปจากเอกสารการตัดสินใจ — อ่านฉบับเต็มด้วย)

1. แอดมินโรงเรียนเพิ่มนักเรียน + ระบุชั้น/ห้อง · เพิ่มครู + ระบุวิชาที่สอน/สังกัด
2. แอดมินจัด**ตารางเรียน**: ห้อง × วิชา × ครู × วัน/คาบ ทั้งสัปดาห์
3. ระบบต่อให้เอง: นักเรียนทุกคนในห้องเห็นวิชาของห้อง · ครูเห็นทั้งห้องในวิชาตัวเอง ·
   **ไม่มีใครกด "เพิ่มนักเรียนเข้าคอร์ส" ทีละคน** · ครูไม่สร้างคอร์สเอง
4. ครูมีหน้าที่แค่ สอน/สั่งงาน/ตรวจงาน/เช็กชื่อ/ครูประจำชั้น

ค่าที่เจ้าของยังไม่ได้ตอบ → **ใช้ค่านี้** (เจ้าของเห็นแล้วไม่ค้าน):
- เรียนข้ามห้อง (วิชาเลือก): แอดมินจัดในตารางได้ (วิชาเดียวผูกหลายห้องได้) ไม่ใช่เพิ่มรายคน
- คอร์สเดิมบน prod (คณิตศาสตร์ ม.1/1, `fcf029bf-…`, มีใบงาน 2 ชิ้น): ย้ายเข้าโมเดลใหม่อัตโนมัติด้วย backfill ใน migration
- หน้าจัดตาราง: เลือกห้อง → กริด จันทร์–ศุกร์ × คาบ → แตะช่องเลือกวิชา+ครู · คาบเวลาตั้งครั้งเดียวทั้งโรงเรียน

## 1. ข้อเท็จจริงของระบบตอนนี้ (ตรวจแล้ว อย่าเชื่อเอกสารอื่นที่ขัดกับนี่)

| สิ่งที่มี | ที่อยู่ | หมายเหตุ |
|---|---|---|
| `courses` มี `grade_level`, `room`, `term_id`, `school_id`, `join_code` | `20260724000000_classroom_core.sql` | คอร์ส = วิชา×ห้อง×เทอม ได้เลย ไม่ต้องเพิ่มคอลัมน์ |
| `create_course(p_token, p_term_id, p_subject_name, p_grade_level, p_room, p_description, p_teacher_id)` | เดียวกัน บรรทัด ~110 | ตอนนี้ `teacher` และ `school_admin` เรียกได้ · แอดมินส่ง `p_teacher_id` ได้อยู่แล้ว |
| `course_students(course_id, student_id, enrolled_by, enrolled_at)` | เดียวกัน | **มี RPC พึ่งพา 49 ตัว** (grades, attendance, submissions, groups, …) — **ห้ามลบ/เปลี่ยนความหมาย** |
| `enroll_student(p_token, p_course_id, p_student_id)` | เดียวกัน บรรทัด ~350 | ครูประจำคอร์สหรือแอดมิน · ปุ่มมีเฉพาะฝั่งครู (`teacher_courses_page.dart` ~4179) |
| `list_my_courses(p_token)` | เดียวกัน บรรทัด ~210 | นักเรียน: join `course_students` · ครู: join `course_teachers` · **ไม่ต้องแก้** ถ้า `course_students` ถูกเติมให้ |
| `student_profiles(student_id, academic_year_id, grade_level, room)` + `set_student_profile(p_token, p_student_id, p_grade_level, p_room)` | `20260917010000` | ห้องของนักเรียน · แอดมินตั้งจาก `school_students_page.dart` |
| `homeroom_assignments(grade_level, room, teacher_id, academic_year_id)` + `set_homeroom_teacher` | มีแล้ว | ครูประจำชั้น — ไม่ต้องแตะ |
| `class_schedules(course_id, day_of_week, start_time, end_time, room, period_type)` + `set_class_schedule(p_token, p_course_id, p_day_of_week, p_start_time, p_end_time, p_room, p_period_type)` / `remove_class_schedule` / `list_all_school_schedules` / `list_my_schedule` / `list_my_student_schedule` / `list_teacher_schedules` | `20260818010000_calendar.sql` | แอดมินเรียก `set_class_schedule` ได้อยู่แล้ว · ผู้อ่านตาราง 6 หน้า (teacher_class_schedule_page, student_calendar_page, parent_schedule_page, parent_dashboard_page, director_classrooms_page, director_calendar_controller) **ไม่ต้องแก้** |
| `terms(academic_year_id, name, …)` · `academic_years(school_id, …)` · `list_terms` | มีแล้ว | เทอม ↔ ปีการศึกษา ↔ โรงเรียน |
| `departments` / `department_members` | มีแล้ว | สังกัดครู — มีอยู่แล้วใน `school_teachers_page.dart` |
| `search_school_students` | `20260822000000` | ใช้ในปุ่มเพิ่มนักเรียนของครู — จะเลิกใช้ฝั่งครู |
| `get_or_create_course_join_code` / `regenerate_course_join_code` | `course_service.dart:186,199` | รหัสเข้าร่วม **ไม่มี RPC ฝั่งนักเรียนใช้** — ฟีเจอร์ครึ่งเดียว ให้ถอดปุ่มฝั่งครูออก |
| ครูสร้างคอร์ส: ปุ่ม "เพิ่มรายวิชาใหม่" | `teacher_courses_page.dart` | จะซ่อน |
| เมนูแอดมิน 20 รายการ | `school_admin/school_admin_dashboard_page.dart` | เพิ่มเมนูที่ 21 |
| รูปแบบ controller ของ School Admin | `school_admin/controllers/*.dart` | ทำหน้าใหม่ให้เหมือนหน้าอื่นในโฟลเดอร์นี้ |

**สิ่งที่ยังไม่มี:** ตารางวิชาที่ครูสอน · ตารางคาบเวลาของโรงเรียน · ตัวเชื่อม "ห้อง → course_students" · หน้าจัดตารางเรียนของแอดมิน

## 2. การตัดสินใจทางเทคนิค (ตัดสินแล้ว — ถ้าจะทำต่างจากนี้ต้องบอกผู้ตรวจก่อน)

**เก็บ `course_students` ไว้เป็นตารางจริง แต่ให้ระบบเป็นคนเติม** ("derived membership, materialized")
เหตุผล: 49 RPC พึ่งพา ถ้าเปลี่ยนเป็น view/derive ตอนอ่าน ต้องแก้ 49 ตัว + เทสต์ทั้งหมด เสี่ยงเกินไป
ทางนี้ RPC 49 ตัวทำงานเหมือนเดิมทุกประการ เปลี่ยนแค่ "ใครใส่แถวลง `course_students`"

กติกาของตัว sync (ต้องเป็นจริงทุกกรณี — เขียน pgTAP ให้ครบ):
- นักเรียน S อยู่ห้อง (G, R) ในปีการศึกษา Y (จาก `student_profiles`) ⇒ S เป็นสมาชิกของ**ทุก**คอร์สที่ `courses.grade_level = G and room = R` และ `term_id` อยู่ในปี Y
- นักเรียนที่ถูกใส่โดย sync ให้ `enrolled_by = null` (แยกจากที่แอดมินเพิ่มรายคนเป็นข้อยกเว้น ซึ่งมี `enrolled_by`)
- ย้ายห้อง: ลบแถวที่ `enrolled_by is null` ของห้องเก่า · เพิ่มของห้องใหม่ · **ห้ามลบ** แถวที่แอดมินเพิ่มเองรายคน
- ห้ามลบ `submissions`/`grades` ของนักเรียนที่หลุดออกจากคอร์ส (ข้อมูลประวัติคงอยู่)
- sync ต้อง idempotent (เรียกซ้ำผลเท่าเดิม) ใช้ `on conflict do nothing` บน `(course_id, student_id)` — ตรวจก่อนว่ามี unique constraint ไหม ถ้าไม่มีให้เพิ่มใน migration นี้

## 3. เฟส 1 — ฐานข้อมูล (1 เซสชัน) · branch `agent/d6-phase1-db`

ไฟล์: `supabase/migrations/20260919000000_admin_timetable_enrollment.sql` ·
`supabase/tests/database/68_admin_timetable_enrollment.test.sql`

1. **`teacher_subjects`**: `(id, school_id, teacher_id → users, subject_name varchar, created_by, created_at)` unique `(teacher_id, subject_name)` · RLS enable, ไม่มี policy (เหมือนทุกตาราง)
   - `set_teacher_subjects(p_token, p_teacher_id, p_subjects text[])` — แอดมินเท่านั้น · แทนที่ทั้งชุด
   - `list_teacher_subjects(p_token, p_teacher_id default null)` — แอดมิน (ทุกคน) / ครู (ของตัวเอง)
2. **`school_periods`**: `(id, school_id, period_no smallint, start_time, end_time, label)` unique `(school_id, period_no)`
   - `set_school_periods(p_token, p_periods jsonb)` — แอดมิน · แทนที่ทั้งชุด · ตรวจ end > start, ไม่ทับกัน
   - `list_school_periods(p_token)` — ทุก role ในโรงเรียน
3. **`sync_course_students_for_room(p_school_id, p_academic_year_id, p_grade_level, p_room)`** — `security definer`, **ไม่ grant ให้ client** (internal only, `revoke all from public`)
   - อัลกอริทึมตามข้อ 2
4. **`sync_course_students_for_student(p_student_id)`** — internal · ใช้ตอนย้ายห้อง (ล้างของเก่าที่ `enrolled_by is null` แล้วเติมใหม่)
5. **แก้ `set_student_profile`**: หลัง upsert → เรียกข้อ 4
6. **แก้ `create_course`**: `if v_actor.role <> 'school_admin' then raise exception 'forbidden'` (ครูสร้างไม่ได้แล้ว) · `p_grade_level`/`p_room` **บังคับ** (raise `room_required`) · `p_teacher_id` บังคับ (raise `teacher_required`) และต้องเป็นครูโรงเรียนเดียวกัน · หลัง insert `course_teachers` → เรียกข้อ 3
7. **แก้ `enroll_student`**: เหลือ `school_admin` เท่านั้น (ข้อยกเว้นเรียนข้ามห้อง) · ใส่ `enrolled_by = v_actor.user_id`
8. **แก้ `set_class_schedule`**: เพิ่ม `p_period_no smallint default null` — ถ้าส่งมา ให้เติม `start_time/end_time` จาก `school_periods` (ราise `period_not_found` ถ้าไม่มี) · เพิ่มคอลัมน์ `class_schedules.period_no smallint null`
9. **ใหม่ `admin_set_room_timetable_slot(p_token, p_term_id, p_grade_level, p_room, p_day_of_week, p_period_no, p_subject_name, p_teacher_id)`** → คืน `(course_id, schedule_id)`
   - หา `courses` ที่ตรง (term, grade, room, subject) — ถ้าไม่มีให้สร้างผ่านตรรกะเดียวกับ `create_course` (รวม sync) · ถ้ามีแต่ครูต่างคน → อัปเดต `course_teachers` owner
   - แล้ว upsert `class_schedules` ช่องนั้น (unique `(course_id, day_of_week, period_no)`; ถ้าช่องเดิมของห้องนั้นวัน/คาบนั้นเป็นวิชาอื่น ให้ลบช่องเก่าก่อน — ห้องเดียวกันคาบเดียวกันมีได้วิชาเดียว)
   - `admin_clear_room_timetable_slot(p_token, p_term_id, p_grade_level, p_room, p_day_of_week, p_period_no)`
   - `list_room_timetable(p_token, p_term_id, p_grade_level, p_room)` → ทุกช่อง + subject + teacher name
   - `list_school_rooms(p_token, p_academic_year_id)` → distinct (grade_level, room) จาก `student_profiles` + จำนวนนักเรียน (ให้หน้าแอดมินเลือกห้อง)
10. **backfill** ท้าย migration: ทุก `courses` ที่ `grade_level`/`room` ไม่ null → เรียก sync (คลุมคอร์สคณิต ม.1/1 บน prod)
11. **grant/revoke** ตามแบบไฟล์อื่น (`grant execute … to anon, authenticated`; internal 2 ตัว revoke ทั้งหมด)
12. **pgTAP ≥ 14 เคส**: ตั้งห้องให้นักเรียน→อยู่ในคอร์สของห้อง · สร้างคอร์สห้อง→นักเรียนทั้งห้องเข้า · ย้ายห้อง→หลุดคอร์สเก่า เข้าคอร์สใหม่ · แถวที่แอดมินเพิ่มรายคนไม่หลุดตอนย้ายห้อง · ครูเรียก `create_course`→`forbidden` · ครูเรียก `enroll_student`→`forbidden` · `set_class_schedule` ด้วย `p_period_no` ได้เวลาจาก `school_periods` · timetable slot ทับวิชาเดิม→วิชาเดิมหาย · sync idempotent · backfill ไม่สร้างแถวซ้ำ · `list_my_courses` ของนักเรียนเห็นคอร์สหลัง sync โดยไม่มีใครเรียก `enroll_student`
13. `bash scripts/dump_schema.sh` → commit `DATABASE_SCHEMA.md` ที่ regenerate แล้ว
14. `scripts/prod_apply_2026-09-19.sh` (ยังไม่รัน) + บันทึกขั้น 4.8 ใน `PRODUCTION_FIX_0.2-0.4.md` สถานะ "รอเจ้าของรัน"

**เกณฑ์ผ่านเฟส 1:** pgTAP 68 ผ่านหมด + ไฟล์ 01–67 ยังผ่าน · `npx supabase db reset` สะอาด · ผู้ตรวจจะรัน reset + pgTAP เองอีกรอบ

## 4. เฟส 2 — หน้าแอดมิน (1–2 เซสชัน) · branch `agent/d6-phase2-admin-ui`

| ไฟล์ | ทำอะไร |
|---|---|
| `packages/shared_core/lib/services/course_service.dart` | เพิ่ม `setTeacherSubjects`, `listTeacherSubjects`, `setSchoolPeriods`, `listSchoolPeriods`, `listSchoolRooms`, `listRoomTimetable`, `setRoomTimetableSlot`, `clearRoomTimetableSlot` — pattern เดียวกับเมธอดเดิม (p_token ตัวแรก, throw ต่อ ไม่ swallow) · ถ้ามี model ใหม่ใส่ `packages/shared_core/lib/models/` + export ใน `shared_core.dart` |
| `school_admin/school_teachers_page.dart` | กล่องเพิ่ม/แก้ไขครู: เพิ่มช่อง **"วิชาที่สอน"** (chips หลายค่า, พิมพ์เพิ่มได้) → `set_teacher_subjects` หลังบันทึกครู · แสดงในการ์ดครู |
| `school_admin/school_settings_page.dart` | ส่วนใหม่ **"คาบเวลา"**: รายการคาบ 1..N เวลาเริ่ม/จบ · ค่าเริ่มต้นถ้ายังไม่เคยตั้ง: 8 คาบ 08:30 เริ่ม คาบละ 50 นาที (แสดงเป็น "ยังไม่ได้บันทึก" จนกว่าจะกดบันทึก — ห้ามแสดงค่าเริ่มต้นเหมือนเป็นของจริง) |
| **ใหม่** `school_admin/school_timetable_page.dart` + `school_admin/controllers/school_timetable_controller.dart` | เลือกเทอม (จาก `list_terms`) + ห้อง (จาก `list_school_rooms`) → กริด แถว = คาบ (จาก `list_school_periods`), คอลัมน์ = จันทร์–ศุกร์ · แตะช่อง → sheet เลือกวิชา (พิมพ์ได้ + แนะนำจากวิชาที่มีครูสอน) + ครู (กรองจาก `teacher_subjects` ของวิชานั้น; ถ้ายังไม่มีใครลงวิชานั้นให้เลือกครูทุกคนได้พร้อมคำเตือน) → `admin_set_room_timetable_slot` · ปุ่มล้างช่อง · ถ้ายังไม่ตั้งคาบเวลา → บอกให้ไปตั้งที่ตั้งค่าก่อน (ลิงก์) ไม่ใช่กริดว่างเงียบ ๆ · ทุก error ขึ้นข้อความไทยที่บอกสาเหตุ ไม่ leak exception ดิบ |
| `school_admin/school_admin_dashboard_page.dart` | เมนูที่ 21 "จัดตารางเรียน" |
| `school_admin/theme/*` | ใช้ palette เดิมของ School Admin ตาม `DESIGN_SYSTEM.md` ห้ามคิดสีใหม่ |
| test `apps/user_app/test/school_timetable_page_connection_test.dart` | ตามแบบ `*_connection_test.dart` อื่น: ทุกปุ่มเรียก seam ที่ต่อ RPC จริง · ไม่มี fallback ปลอม · error path แสดงข้อความ |
| test layout | เพิ่ม case ใน `test/iphone_layout_test.dart` สำหรับหน้าจัดตารางที่ 360/375/390 (กริดต้อง scroll แนวนอนได้ ไม่ล้น) |

## 5. เฟส 3 — ฝั่งครู/นักเรียน (0.5 เซสชัน) · branch `agent/d6-phase3-teacher-student`

| ไฟล์ | ทำอะไร |
|---|---|
| `teacher_redesign_prototype/teacher_courses_page.dart` | ซ่อนปุ่ม "เพิ่มรายวิชาใหม่" (hero + ปุ่ม + ในการ์ด) · แท็บนักเรียน: ถอดปุ่ม "เพิ่มนักเรียน"/`searchSchoolStudents`/`enrollStudent` ออก ใส่ข้อความ "รายชื่อมาจากห้อง X ที่แอดมินจัด" · ถอดปุ่ม "รหัสเข้าร่วม" และเมธอด join code ใน `course_service.dart` (ถ้าไม่มีที่อื่นใช้) · ตัวกรองห้อง "ม.4/1 ม.4/2 ม.5/2" ที่ hardcode → ใช้ห้องจริงจาก `list_my_courses` |
| `teacher_redesign_prototype/teacher_class_schedule_page.dart` | อ่านอย่างเดียว — ถอดปุ่มเพิ่ม/ลบคาบ (ถ้ามี) |
| `teacher/course_detail_page.dart` (หน้าเก่า) | ถ้ายังถูก route ถึง ให้ถอดปุ่ม enroll ด้วย · ถ้าไม่ถูก route แล้ว จดไว้ใน WORK_LOG ว่าเป็น dead code |
| ฝั่งนักเรียน | **ไม่แก้** — ตรวจด้วยเทสต์ว่า `list_my_courses` คืนคอร์สหลัง sync |
| เทสต์เดิม | ที่คาดว่าครูสร้างคอร์ส/เพิ่มนักเรียนได้ → ปรับ (คาดว่า 3–6 ไฟล์ ใช้ `grep -rl "createCourse\|enrollStudent" apps/user_app/test`) |

## 6. เฟส 4 — เอกสาร + ส่งมอบ (ผู้ทำทำ · ผู้ตรวจยืนยัน)

1. `HANDOFF.md` — "Current status": อธิบายโมเดลใหม่ 5 บรรทัด + ชี้ไปเอกสารการตัดสินใจ
2. `MASTER_PLAN_2026-09-06.md` — ปิด D6 · เพิ่ม ticket 6.1–6.3 (เฟส 1–3) tick พร้อม hash
3. `STATUS_VERIFIED_2026-09-06.md` — ย้าย "ครูเพิ่มนักเรียนเข้าคอร์ส" ไป ❌ ถอดแล้ว · เพิ่ม ✅ ตารางเรียนแอดมิน
4. `WORK_LOG.md` — 3 แถว (เฟสละแถว) พร้อม hash
5. `PRODUCTION_FIX_0.2-0.4.md` — ขั้น 4.8 สคริปต์ + วิธี verify (`select count(*) from course_students where enrolled_by is null` ต้อง > 0 หลังรัน)
6. ห้ามแตะ `NOTES.md` ในโฟลเดอร์ prototype (stale อยู่แล้ว)

## 7. กติกาส่งงาน (จาก AGENTS.md — ย้ำเพราะเคยชนกัน)

- ทำใน worktree ของตัวเอง: `git worktree add -b agent/d6-phase1-db <dir> gitlab/main` · **ห้ามใช้ checkout หลัก** `/Users/sayfa/my_first_app` (มีงานค้างของอีกบัญชีบน `agent/fix-6-audit-bugs`)
- แต่ละเฟส: commit → push branch ไป gitlab+origin → push `HEAD:main` ทั้งสอง remote → ลบ worktree · ก่อน push ต้อง `git fetch` แล้ว rebase ถ้า main ขยับ
- commit message ภาษาอังกฤษ บอก what/why · ลงท้าย `Co-Authored-By:` ตามที่เซสชันนั้นถูกตั้งไว้
- **ห้าม** `dart format` ทั้งโฟลเดอร์ (เคยเปลี่ยน 19 ไฟล์ที่ไม่เกี่ยว) — format เฉพาะไฟล์ที่แตะ
- ห้าม tick ticket จากรายงานตัวเอง — ผู้ตรวจ tick หลังรันเทสต์เองแล้ว
- เจอสิ่งที่ใบนี้เขียนผิด (เช่น ชื่อคอลัมน์ไม่ตรง) → แก้ตามของจริง แล้วจดใน WORK_LOG ว่าใบสั่งงานผิดตรงไหน

## 8. สิ่งที่ผู้ตรวจจะทำหลังแต่ละเฟส

- เฟส 1: `npx supabase db reset` สะอาด · รัน pgTAP 01–68 ทั้งหมด · อ่าน migration ทั้งไฟล์ (ไม่ใช่ grep) เทียบกติกาข้อ 2 ทุกข้อ · ลอง sync ซ้ำ 2 ครั้งแล้ว count เท่าเดิม
- เฟส 2: เปิดหน้าจัดตารางบน iPhone จำลอง (402×874) จัดตารางห้อง ม.1/1 จริงบน local · ล็อกอินนักเรียน local (`student@aiot-school-lab.local`) ต้องเห็นวิชาโดยไม่มีใครกดเพิ่ม · เทสต์ layout 360/375/390
- เฟส 3: ครู local ต้องไม่มีปุ่มสร้างคอร์ส/เพิ่มนักเรียน/รหัสเข้าร่วม · `flutter test` ทั้ง suite ไม่มี fail ใหม่
- เฟส 4: อ่านเอกสาร 5 ไฟล์ว่าตรงกับโค้ด · ส่งสคริปต์ให้เจ้าของรัน prod · หลังรันแล้วกลับไปทำ "ทดสอบหน้านักเรียนด้วยข้อมูลจริงบน iPhone" ที่ค้างอยู่
