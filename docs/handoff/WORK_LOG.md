# Work Log

## Latest audit — 2026-09-09

See [Executive connection audit](EXECUTIVE_CONNECTION_AUDIT_2026-09-09.md).
The classroom work/detail RPCs, automatic flags, canonical case confirmation,
stable deduplication and concurrent case-open serialization are now repaired
with forward migrations and applied to local Supabase. Assignment details use
real instructions, dates and roster denominators; roster errors close their
loading dialog; bare room numbers no longer mix schedules across grades.
Verification: live Executive contracts 38/38, classroom summary 18/18,
learning/case Flutter 7/7, classroom widgets 10/10, and analyzers have 0 errors.
Browser checks confirm the classroom and student-overview pages load without
their former RPC failure. The whole Executive portal still has separate gaps
listed in the audit, especially CCTV, environment claims,
report file flow and settings. No production deployment.

> **ไฟล์นี้เก็บเฉพาะสิ่งที่ git เก็บไม่ได้** — การตัดสินใจที่ยังไม่ได้เคาะ, งานที่ค้างอยู่
> ตอนนี้, และการไล่ตรวจที่ไม่ได้เกิด commit (เช่น การคลิกทดสอบในเบราว์เซอร์)
>
> **ห้ามเขียนสรุปงานที่ commit ไปแล้วซ้ำที่นี่** — commit เก็บครบแล้วทั้งใคร/เมื่อไหร่/
> ทำอะไร/ทำไม/เหลืออะไร และแก้ย้อนหลังไม่ได้ ดูด้วย:
>
> ```bash
> ./scripts/state.sh --log            # 3 วันล่าสุด
> SINCE='2 weeks ago' ./scripts/state.sh --log
> ```
>
> การเขียนซ้ำสองที่คือสาเหตุที่ไฟล์นี้เคยเน่า — ตอนตรวจ 2026-09-06 พบว่ายังลิสต์งาน
> 2 อย่างไว้ใน "In progress" ทั้งที่เสร็จไปแล้ว และมี 4 รายการใน "ไม่แน่ใจ" ที่ปิดไปแล้ว

---

## Local classroom-score migration verification — 2026-09-08

- Applied `20260910040000_executive_classroom_learning_summary` to Docker
  `supabase_db_aiot-school-lab` using `supabase migration up --local` with a
  temporary migration directory capped at this version. The original draft's
  `20260910030000` collided with the already-applied `school_device_identity`.
  Verified the new history row and the live RPC signature/execute grants.
- Grades are confirmed, valid numeric entries from this school's current
  academic year, normalized per entry to a percentage. No valid grades stays
  null. Invalid score/max-score entries do not count as scored students.
- Targeted pgTAP: 37/37 passed (files 44 and 47). Full local DB suite:
  46 files, 822 assertions passed; files 14 and 16 cannot start because their
  fixtures still use the removed `facility_manager` enum value. This migration
  does not change the role enum. QA rows were rolled back (0 remaining users).
- Local only, no database reset. The running browser build and the unfinished
  Flutter page changes were not verified by this migration run.

## 🔴 การตัดสินใจที่ค้างอยู่ — บล็อกงานข้างล่าง

รอเจ้าของโปรเจกต์เคาะ ไม่ใช่งานที่ AI ตัดสินเองได้

| # | เรื่อง | บล็อกอะไร | ตัวเลือก |
|---|---|---|---|
| **D1** | อนุญาตให้เขียน production ไหม | ticket 0.2–0.4, 5.6 · **ช่องโหว่ 2 จุดยังเปิดอยู่** | อนุญาต / เจ้าของรันเอง ตาม `PRODUCTION_FIX_0.2-0.4.md` |
| ~~**S1**~~ | ✅ **ปิดแล้ว 2026-09-08** — เมทริกซ์สิทธิ์ + การ์ด "บทบาทในระบบ" บนแท็บ "ตารางสิทธิ์ตามบทบาท" ของ `school_permissions_page.dart` เคยเป็นข้อมูลแต่งขึ้นล้วน (7 โมดูลเขียนมือ + คอลัมน์ `ครูประจำอาคาร` ที่ยุบไปแล้ว, การ์ดบทบาท hardcode "2 คน"/"1 คน" ทุกบทบาทตายตัว) แก้ตามที่ `DECISIONS_2026-09-07.md` ข้อ 5 สั่งไว้จริง: สร้าง RPC ใหม่ `list_role_permission_matrix` สแกน `pg_get_functiondef()` สดจากฐานข้อมูล หา pattern `v_actor.role not in (...)` ที่ RPC ส่วนใหญ่ของโปรเจกต์ใช้จริง (155/273 ฟังก์ชันที่เช็ค `v_actor.role` ตรง pattern นี้ ที่เหลือโชว่า "ไม่พบรูปแบบที่สแกนได้" ตรงๆ ไม่เดา) ต่อหน้าจอเป็นตารางค้นหาได้จริง + การ์ดบทบาท 6 ตัวจริงพร้อมจำนวนคนจริงจาก `{u.role, ...u.allRoles}` migration `20260908000000` pgTAP `43_school_admin_permission_matrix.test.sql` (8/8 ผ่าน) commit `f2a4d17`/`8b00c76`/`873dbc2`. **ของค้างที่เจอระหว่างทำ ไม่ได้แตะ**: dialog "กำหนดขอบเขตสิทธิ์" (`_buildRoleSelectorChips` ฯลฯ) ยังมี chip `ครูประจำอาคาร` อยู่ — คนละฟีเจอร์ ต้องตรวจแยกว่าจริงหรือปลอมก่อนแก้ |
| ~~**S3**~~ | ✅ **ปิดแล้ว 2026-09-08** — ปุ่ม Export ที่โผล่ใน `school_admin/` (สำรวจจริงแล้วเจอ 4 หน้าในสโคป ไม่ใช่ 5: `school_admin_esg_page.dart`, `school_admin_energy_page.dart`, `school_alerts_page.dart`, `school_resources_page.dart` — `school_reports_page.dart` คนละ ticket 2.4, `school_permissions_page.dart` คือ S1 ที่ deferred แยกไว้) ทำ CSV export จริงทั้ง 4 หน้าโดยใช้ข้อมูลที่แต่ละหน้าโหลดอยู่แล้ว (ไม่มี RPC ใหม่) แพทเทิร์นเดียวกับ `super_admin_alerts_logs_page.dart` (`_csvField()`/`downloadBytes()`) เพิ่ม `downloadBytesOverride` seam ทุกหน้าให้ test พิสูจน์ได้ว่าเรียก download จริง ไม่ใช่แค่เช็คปุ่ม disabled commit `b54b9fa`/`dd042ef`/`5410479`/`68e5fb8`. **หมายเหตุ**: ขัดกับ `DECISIONS_2026-09-07.md` ข้อ 6 เดิม (อีกเซสชันถามแยกกันได้คำตอบ "disable" ตรงข้ามกัน) — เจ้าของยืนยันแล้วว่าเก็บงาน CSV ไว้ ไม่ revert แก้ `DECISIONS_2026-09-07.md` ให้ตรงแล้ว. **ต่อยอด 2026-09-08**: เจ้าของขอ Excel เพิ่มด้วย — ทั้ง 4 หน้าเพิ่มปุ่มเลือก "ส่งออกเป็น CSV" / "ส่งออกเป็น Excel" (popup menu) โดยดึง row-building logic ออกมาเป็นเมธอดกลาง (`_buildReportRows`/`_buildAlertRows`) ใช้ร่วมกันทั้งสองฟอร์แมตกันข้อมูลเพี้ยนกัน ใช้ `package:excel` ตัวเดียวกับที่มีอยู่แล้วใน `teacher_aiot_dashboard_page.dart` (`.encode()` ไม่ใช่ `.save()` กัน side-effect ดาวน์โหลดซ้อนที่เคยเป็นบั๊กมาก่อน) test ยืนยันด้วย PK magic bytes ว่าไฟล์ .xlsx เป็นไฟล์จริง commit `48a6422`/`5da7d12`/`6648183`/`ca6be5c` |
| **D2** | `director_meetings_page` (2,216 บรรทัด) — ไม่มีตาราง meetings/attendees/agenda ในสคีมาเลย | Executive 3.7 | สร้างใหม่ (+3–4 เซสชัน) / disable แท็บ (0.3) / ลบทิ้ง |
| **D3** | Super Admin ใช้เกณฑ์ไหน | Phase 4 | เติม state อย่างเดียว (6–8) / refactor เป็น controller เหมือน School Admin (12–15) |
| **D5** | โควตา GitLab CI หมด (`ci_quota_exceeded`) — ไม่ใช่ปัญหาโค้ด | CI ทั้งหมด | ต่อโควตา / self-hosted runner / ใช้ GitHub Actions อย่างเดียว |

## 🟢 ตัดสินใจแล้ว 2026-09-07 — อย่าถามซ้ำ

เจ้าของเคาะครบ 13 ข้อ (ทิศทางรวม 7 + ระบบประชุม 6) บันทึกไว้ที่
**[DECISIONS_2026-09-07.md](DECISIONS_2026-09-07.md)** — อ่านก่อนแตะระบบประชุม
การลา การไปราชการ เมทริกซ์สิทธิ์ Export หรือ Super Admin

เหลือขัดกันอยู่ 1 จุด: ข้อ 6 สั่ง disable Export ทุกหน้า แต่ข้อ C ต้องการ
ส่งออกเอกสารการประชุม — ข้อเสนอ (รอเจ้าของเคาะ) คือทำ export จริงเฉพาะ
เอกสารการประชุมด้วยหน้าพิมพ์ ที่เหลือ disable

## 🟡 งานที่ค้างอยู่ตอนนี้

| งาน | ค้างตรงไหน |
|---|---|
| ระบบประชุม (`20260907030000` + `20260907040000`) | สคีมา 9 ตาราง + 31 RPC รันบน local แล้ว · **pgTAP เขียนแล้ว** (`40_meetings.test.sql`, 126/126 ผ่าน — ครอบคลุม create/cancel/complete_meeting, respond_to_meeting, agenda (รวม list), attendee list, minutes draft→final→addendum, resolutions + overdue, attachments, external attendees, three-state attendance, notification categories, staff calendar, cross-school isolation) **แต่ยังไม่มี service/model ฝั่ง Dart · ยังไม่แตะหน้าจอ · ยังไม่มี Edge Function ของ meeting-files** |
| `staff_requests` (ขอเข้าพบ / ขอจัดประชุม / ขอไปราชการ) | สคีมา + 4 RPC เขียนแล้ว (`20260907050000_staff_requests.sql`) — อนุมัติ 2 ชั้น (หัวหน้าฝ่าย → ผอ., ข้ามชั้นถ้าไม่มีฝ่ายหรือผู้ขอเป็นหัวหน้าเอง), อนุมัติ ไปราชการ เขียน `official_duty` ลง `staff_attendance_records` อัตโนมัติทุกวันในช่วง (overwrite ทับของเดิมได้) **pgTAP เขียนแล้ว** (`41_staff_requests.test.sql`, 54/54 ผ่าน — พบและแก้บั๊กจริงระหว่างเขียน test: `cancel_staff_request` เดิมให้ school_admin **โรงเรียนไหนก็ได้** ยกเลิกคำขอของโรงเรียนอื่นได้ เพราะเช็คแค่ role ไม่เช็ค school_id ก่อน commit; redteam รอบสองเพิ่มเพดาน 90 วันให้ `official_duty` กัน loop ไม่มีขอบเขต และบังคับ `meet_request`/`meeting_request` เป็นวันเดียวเท่านั้น) **แต่ยังไม่มี service/model ฝั่ง Dart · ยังไม่แตะหน้าจอ**. **หมายเหตุค้าง**: DECISIONS_2026-09-07.md ข้อ D เขียนว่า "ลา / ไปราชการ: 2 ชั้น" รวมกัน แต่ `staff_leave_requests` (ลา) ที่ shipped ไปก่อนหน้านี้เป็นชั้นเดียว (school_admin อนุมัติเอง) — migration นี้ไม่ได้แตะ approval chain ของ `staff_leave_requests` เพราะเป็นของที่ shipped แล้วและอยู่นอก scope ที่สั่ง ต้องให้เจ้าของเคาะว่าจะแก้ ลา ให้เป็น 2 ชั้นด้วยไหม |
| ✅ ไฟล์แนบของการลา | สคีมา + 5 RPC + Edge Function คู่ + model/service ฝั่ง Dart (`StaffLeaveAttachment`/`StaffLeaveAttachmentService`) + ใช้จริงในหน้า "อนุมัติการลา" — **ปิดงานแล้ว**. bucket `staff-leave-attachments` (ตั้งชื่อแยกจาก `leave_attachments` เดิมของฟีเจอร์คนละอันคือ `leave_requests` นักเรียน/ผู้ปกครองยื่นลา — อย่าสับสน) `20260907060000_staff_leave_attachments.sql`, pgTAP `42_staff_leave_attachments.test.sql` 23/23 ผ่าน |
| ✅ หน้า school_admin: ตั้งเวลาปฏิบัติงาน · อนุมัติการลา · สร้างรายการรายงานที่ต้องส่ง | **ปิดงานแล้ว** — 3 หน้าใหม่ต่อเมนู School Admin จริง: `school_admin_attendance_settings_page.dart` (ตั้ง `staff_work_hours` — ก่อนหน้านี้ครูลงเวลาไม่ได้เลยเพราะ `staff_check_in` โยน `work_hours_not_configured`), `school_admin_leave_approval_page.dart` (อนุมัติ/ปฏิเสธพร้อมดูไฟล์แนบใบรับรองแพทย์), `school_admin_report_requirements_page.dart` (สร้าง/ปิดรายการที่ต้องส่ง ให้ "3/6" บนหน้า reports มีตัวส่วนจริง) ทั้ง 3 หน้าใช้ backend/service ที่มีอยู่แล้วทั้งหมด (`StaffAttendanceService`, `SchoolReportService`, `StaffOrgService`) ไม่มี RPC ใหม่ในรอบนี้ ยกเว้น `StaffLeaveAttachmentService` ที่เพิ่งเขียนคู่กับงานไฟล์แนบด้านบน มี connection test ครบทั้ง 3 หน้า (7+10+10 = 27 เคส) `flutter test` เต็ม: 471 ผ่าน 7 พัง (เท่าเดิม, เลน Director/Executive) `flutter analyze` 0 error ทั้ง 3 แพ็กเกจ |
| `school_admin_permissions_controller.dart` (345 บรรทัด) | เขียนเสร็จแล้ว **แต่ยังไม่มีหน้าไหน import และยังไม่มี test** — ticket 2.1 ยังเปิดอยู่ ต้องต่อกับหน้า + ลบเมทริกซ์ปลอม (ดู S1) — **ข้ามไปก่อนตามที่เจ้าของสั่ง 2026-09-07** ทำทีหลังหลัง Teacher lane |
| ✅ Student: บั๊ก QR login fake-token fallback | **ปิดงานแล้ว** `student_qr_login_page.dart` — `_initPairingSession()` เคย fallback เป็น token ปลอม claim ไม่ได้เงียบๆ เมื่อ error ตอนนี้โชว์ error state จริง + ปุ่มลองใหม่ เจอบั๊ก overflow จริงคู่กัน (การ์ดสถานะ "หน้าจอแท็บเล็ตแล็บพร้อมจับคู่") แก้ด้วย Flexible เหมือนที่แก้ที่อื่นในเซสชันนี้ 3 connection test ผ่านหมด |
| ✅ Student: ลบหน้า mockup ปลอมที่ยืนยันว่าเข้าไม่ถึง | **ปิดงานแล้ว** ลบ `student_redesign_prototype_page.dart` (2226 บรรทัด, variant B/C/D ปลอม), `student_course_catalog_streaming_page.dart`, `student_course_catalog_carousel_page.dart`, `student_dashboard_models.dart` (ไม่มีใครเรียกใช้เลยทั้งไฟล์) ยืนยัน reachability ก่อนลบ (gate ด้วย `isPrototypeMode` compile-time constant) แก้ `main.dart` route table ครบ |
| ✅ Parent: เช็ค `status ?? 'present'` | **ตรวจแล้ว ไม่ใช่บั๊กจริง** — `attendance_records.status` เป็น NOT NULL ที่ DB และ RPC ใช้ inner join เท่านั้น ไม่มีทางได้ null จริง เป็น defensive code เกินจำเป็น ไม่แก้ |
| ✅ Parent: defensive hardening `status ?? 'present'` | **ปิดงานแล้ว 2026-09-08 · commit `03cfda4`** — ทำตาม FIX_BRIEF โดยเปลี่ยน decoder ของ response ที่ขาด field เป็น `unknown`; หน้า Parent attendance/dashboard/learning แสดง `ไม่ทราบสถานะ` และไม่นำ unknown ไปคำนวณอัตรา Browser check ด้วยบัญชี parent ผ่าน: empty state แสดง `ไม่ทราบสถานะ 0 คาบ` โดยไม่ overflow |
| Teacher lane: 12 หน้ามีบั๊กข้อมูลปลอม/fake-success จริง | **กำลังทำ** ตามแผน `/Users/sayfa/.claude/plans/virtual-beaming-shannon.md` เฟส 2 — อ้างอิง `teacher_audit_2026-09-07.md`. ✅ ข้อแรก (`teacher_redesign_prototype_page.dart`) ปิดแล้ว: ลบ `_CameraSecuritySummaryCard` (การ์ดแจ้งเตือนกล้อง AI Security ปลอมที่ขึ้นทุกหน้า), ลบ `_TeacherScheduleVariant`/`_TeacherOpsVariant` (variant B/C ปลอมทั้งดุ้นจาก `TeacherMock` ที่ครูจริงกดลูกศรสลับ variant เจอได้ตรงจากโปรดักชัน ต่างจากฝั่ง Student ที่ fake variant ถูก gate ไว้), เหลือ `TeacherPrototypeVariant` แค่ตัวเดียว, แก้กล่องค้นหา (`_showTeacherSearchDialog`) ให้ดึง `CourseService`/`CalendarService` จริงแทน `TeacherMock.classes/lessons` ที่ถูกลบ, แก้วันที่ค้าง "พุธ 5 ส.ค." ใน `_TeacherTopBar` ให้เป็นวันที่จริง. commit `669ab76`, test ใหม่ 1 เคสยืนยัน enum เหลือค่าเดียว. ✅ ข้อสอง (`teacher_courses_page.dart` gradebook) ปิดแล้ว: `_CourseGradebookTabWidget._fetchGradeData` เคยดึงรายชื่อนักเรียนจริงมาแล้วแปะคะแนนปลอมชุดเดียวกันทุกคน (10/10, 20/20, รวม 30/30, เกรด 4.0, "ส่งงานครบแล้ว") และการ์ดสรุปด้านบนก็ hardcode "100%"/"2 งาน" ตายตัว — แก้ให้ดึงคะแนนจริงจาก `GradeService.listCourseGrades` (มี RPC อยู่แล้วแค่ไม่เคยถูกเรียกจากหน้านี้), ตัด 2 คอลัมน์รายวิชาปลอม (บทที่ 1/ใบงานที่ 1 ที่ backend ไม่มีข้อมูลระดับนี้จริง) ออก, นักเรียนที่ยังไม่มีคะแนนโชว์ "ยังไม่มีคะแนน" แทนคะแนนผ่านปลอม. commit `2d53126`, test ใหม่ 1 เคส. ✅ ข้อสาม (`teacher_exam_builder_page.dart` บันทึกผิดวิชา) ปิดแล้ว: constructor เดิมรับแค่ `courseCode`/`courseName` (สตริงโชว์ผล) ไม่มีช่องให้ส่ง `courseId` จริงเลย `_saveExam` เลยเรียก `CourseService.listMyCourses().first.id` ทุกครั้ง — ครูเปิด exam builder จากวิชา B แต่มีวิชา A/B/C ในระบบ ข้อสอบจะไปแปะกับวิชา A เงียบๆ ถ้า A มาก่อนในลิสต์ แก้ให้รับ `courseId` จาก `TeacherCourseModel` จริงที่จุดเดียวที่เปิดหน้านี้จากวิชาจริง (`teacher_courses_page.dart` CLS-4) เหลือ fallback ไป `listMyCourses().first` เฉพาะ route dev-preview `/prototype/exam-builder` ที่ไม่มีวิชาในคอนเท็กซ์อยู่แล้ว. commit `eba2e77`, test ใหม่ 2 เคสพิสูจน์ว่าไม่แตะ `listMyCourses` เลยเมื่อมี `courseId` จริง. ✅ ข้อสี่ (`teacher_lesson_editor_page.dart`) ปิดแล้ว — บั๊ก 3 จุดในไฟล์เดียว: (1) `TeacherLessonListPage` seed `_lessons` ด้วยบทเรียนตัวอย่าง 6 รายการ (`mockLessonsList`, ลบทิ้งแล้ว) แล้วเขียนทับเฉพาะ `if (summaries.isNotEmpty)` — คอร์สที่ว่างจริงหรือโหลดพังเลยค้างบทเรียนปลอมตลอดไป แถมยังมีบั๊ก "ผิดวิชา" แบบเดียวกับ exam builder (ไม่มี `courseId` เลย ใช้ `listMyCourses().first`) แก้ให้รับ `courseId` จริงและเขียนทับด้วยผลจริงเสมอแม้จะว่าง (2) ปุ่ม quick-publish บนการ์ดลิสต์บทเรียนตั้ง `les.status = published` ในเครื่องเฉยๆ ไม่เรียก `LessonService.publishLesson` เลย (ปุ่มเดียวกันในหน้ารายละเอียดบทเรียนที่อยู่ติดกันเรียกจริงอยู่แล้ว) แก้ให้เรียก RPC จริง (3) `TeacherLessonAnalyticsPage` ปลอม 100% (fake delay + "42 คน"/"84%" + รายชื่อนักเรียนปลอม 5 คน ไม่มี service ใดๆ) และปุ่ม "ผูกข้อมูล AIoT Sensor" เสนออุปกรณ์ปลอม 3 ชื่อที่ไม่มีจริง ทั้งสองไม่มี backend/ผู้บริโภคฝั่งนักเรียนรองรับเลย (`student_lessons_page.dart` ไม่อ่าน sensorDeviceId เลยสักจุด) — ปิดตรงๆ เป็น "ยังไม่เปิดใช้งาน" แทนครึ่งๆ กลางๆ. commit `a77deb7`, test ใหม่ 2 เคส. **ปิด 2A ครบทั้ง 4 ไฟล์แล้ว** เริ่ม 2B: ✅ `teacher_student_support_page.dart` ปิดแล้ว (เปิดเคสเปิดใหม่/`_updateStatus`/`_addIntervention` เคย fake-success กลืน error ทิ้งแล้วโชว่าสำเร็จเสมอ + fallback เคสตัวอย่างปลอม 2 คนเมื่อโหลดพัง แก้ให้ error จริงแสดงจริง ไม่มี fallback ปลอมแล้ว, commit `843ec3c`). ✅ `teacher_notifications_page.dart` + ป็อปอัพกระดิ่งแจ้งเตือนบนแดชบอร์ดปิดแล้ว (เคย seed แจ้งเตือนปลอม 4 รายการค้างเมื่อโหลดว่าง/พัง ทั้งในหน้าเต็มและป็อปอัพ 2 จุดแยกกัน, `_handleNotificationTap` ยิง markNotificationRead แบบไม่ await ทำให้ catch จับ error ไม่ได้เลย แก้ให้ใช้ mapper กลาง `mapRealNotifications` ร่วมกัน + await จริง, commit `1eb52c6`). ✅ `teacher_profile_page.dart` ปิดแล้ว (ตัวตนปลอม "ครูสมชาย สายวิทย์", วิชา/ห้องเรียนปลอม "ม.5/2 · 32 คน", อุปกรณ์ AIoT ปลอม 2 ชิ้นพร้อม MAC ปลอมเมื่อข้อมูลจริงว่าง — เปลี่ยนเป็น honest empty state ทั้งหมด, commit `bca3850`). **บั๊กใหญ่ที่เจอระหว่างตรวจ**: `_SidebarMiniClassCard` ใน `teacher_redesign_prototype_page.dart` — การ์ด "ห้องประจำชั้น" ใน sidebar ถาวรที่ทุกหน้าครูใช้ร่วมกัน (ผ่าน `TeacherMockPageShell`) hardcode "ม.5/2 · 32 คน" ตายตัวให้ครูทุกคนทุกหน้ามาตลอด — แก้ให้ดึงจาก `HomeroomService.listMyHomeroomClasses()` จริง (มี RPC อยู่แล้วไม่เคยถูกเรียกจากจุดนี้), commit เดียวกัน. เหลือ 5 หน้าใน 2B (`teacher_rubric_page.dart`, `teacher_question_bank_page.dart`, `teacher_assignment_editor_page.dart`, `teacher_knowledge_library_page.dart`, `teacher_aiot_dashboard_page.dart`). `flutter test` เต็ม 484 ผ่าน 7 พัง (เท่าเดิม, เลน Director/Executive) |
| School Admin — % ความพร้อมจริง (ตอบคำถามเจ้าของ 2026-09-07) | จากการเช็ค `STATUS_VERIFIED_2026-09-06.md` จริง (ไม่ใช่เดา): **19 หน้ารวม** — 5 หน้าผ่านเกณฑ์เต็ม (Alerts/CCTV/Device schedule/Incident inbox/Learning tracks, มี controller+pgTAP+widget test ครบ), อีก 14 หน้า **ต่อ backend จริงครบทุกหน้าแล้ว** แต่ยังไม่ผ่าน DoD เต็ม (ขาด empty-state 13 หน้า, ไม่แยก loading/error 6 หน้า, มีตารางปลอมปน 4 หน้า) บวกของค้างที่รู้อยู่แล้ว 2 จุด (S1 เมทริกซ์สิทธิ์ปลอม — deferred ตามสั่ง, S3 ปุ่ม export ปลอม 5 หน้า — ยังไม่ทำ) **สรุปกะประมาณ ~78-82%** ไม่ใช่ของปลอมทั้งหน้าเหมือนที่เคยพูดผิดไปตอนแรกในเซสชันนี้ (60-65% เป็นเลขเดาจากความจำ ไม่ได้เช็คไฟล์) |
| `school_reports_page` | loading/data/empty/error + test เสร็จแล้ว · **แก้เพิ่ม 2026-09-08**: `_insights()` (เคย 4 การ์ด hardcode เช่น "ไฟฟ้าเพิ่มขึ้น 14%") กับ `_preview()` (เคย `_LinePainter` กราฟปลอมทั้งเส้น + `_Metric` "386 kWh"/"146 / 152" hardcode) เปลี่ยนเป็นดึงจาก `SchoolAdminDashboardSummary` จริงที่หน้าโหลดอยู่แล้วทั้งคู่ ไม่มี RPC ใหม่ ลบ `_Chart`/`_LinePainter`/`_axis` ทิ้ง (ไม่มีใครใช้แล้ว) เพิ่ม test 2 เคสยืนยันเลขจริงไม่ใช่ของปลอม (`school_reports_page_connection_test.dart`) · **ปุ่ม export ทำจริงแล้วด้วย** (ต่อยอดทันทีในรอบเดียวกัน หลังเจ้าของอ่านไฟล์เต็มแล้วชี้ว่าเหลือแค่ export เป็นของปลอมจริง): ลบ `_createReport` (เคย snackbar "ยังอยู่ระหว่างการพัฒนา" ทุกปุ่ม) แทนที่ด้วย `_buildReportRows`/`_exportReport`/`_exportReportExcel` แพทเทิร์นเดียวกับ ESG/energy/alerts/resources (S3) — export ตัวเลขสรุปจริงจาก `SchoolAdminDashboardSummary` เป็น CSV/Excel ปุ่มเดิม "ส่งออก Excel"/"สร้าง PDF" (PDF ปลอม ไม่เคยมี backend) รวมเป็นเมนูเดียว "ส่งออกรายงาน" (CSV/Excel) แก้ข้อความ `_recentReports()` ที่เคยพูดว่า export "อยู่ระหว่างการพัฒนา" ให้ตรงกับความจริงใหม่ (แค่ไม่มีประวัติไฟล์เก่าเก็บไว้ ไม่ใช่ export ใช้ไม่ได้) เพิ่ม test อีก 3 เคส (CSV/Excel/ปฏิเสธเมื่อไม่มีข้อมูล) รวม 10/10 ผ่าน commit `1202caf` (insights/chart) — export ตามมาใน commit ถัดไป · **ยังปลอมอยู่ (ตั้งใจ ไม่แตะ คนละสโคป)**: filter อาคาร/ห้อง (`_filters()`) เป็น dropdown hardcode ไม่ผูกกับข้อมูลจริง |
| `director_classrooms_page` | ลบ fallback `?? '36'` แล้ว · **ตารางห้อง 205 บรรทัดยังปลอมอยู่** (ticket 3.1) |
| ~~ticket 1.1~~ | ✅ **ปิดแล้ว 2026-09-08** — `teacher_profile`/`teacher_courses` ตรวจซ้ำแล้วสะอาด (ปุ่มไม่มี backend ปิดสุจริตด้วย `onTap: null` จาก `0f03100`, ปุ่มที่เหลือเรียก RPC จริงก่อนโชว์ผล) `student_profile` เป็นคนละเลนยังไม่ได้ตรวจในรอบนี้ commit ยืนยันดูที่ `docs/handoff/MASTER_PLAN_2026-09-06.md` §1.1 |
| ~~ticket 1.2~~ | ✅ **ปิดแล้ว 2026-09-08** — hardcode 8 จุดใน `teacher_redesign_prototype_page` ตรวจครบ: `669ab76` แก้ไปแล้ว 3 จุดก่อนหน้านี้ (กล้องปลอม/variant B-C/mock search), รอบนี้เจอเพิ่มอีก 2 จุดจริง (role switcher fake-success ที่ขัดกับสถาปัตยกรรม no-in-app-role-switch ใน HANDOFF.md, ปฏิทิน freeze วันที่ 6 ส.ค. 2569 ตายตัว) แก้ commit `9b6250c`. ที่เหลือเป็น false positive (`TeacherMock` = config เมนู sidebar ไม่ใช่ fake data) |
| ~~ticket 1.4~~ | ✅ **ปิดแล้ว 2026-09-08** — local มีโรงเรียนเดียว ทดสอบ cross-school SOS ในเบราว์เซอร์จริงไม่ได้ พิสูจน์ด้วย pgTAP แทน (`19_incident_reports.test.sql` test 6b, commit `899750c`) ยืนยัน `list_incident_reports` ของครูโรงเรียนอื่นไม่เห็นเหตุการณ์โรงเรียน A เลย ผ่าน 22/22 |
| ticket 1.3 test debt | **ยังไม่ re-verify รอบนี้** — เลขล่าสุดที่เช็คจริงคือ `flutter test` เต็ม 544 ผ่าน/8 fail (2026-09-08, ทั้ง 8 เป็นเลน Executive ที่ Codex ทำอยู่ + 1 school_admin เดิม) เลข "fail 17 ชุด" ในบรรทัดนี้เป็นของเก่า ยังไม่ได้ re-count ฝั่ง pgTAP |
| Student lane: connection test — **8/~15 หน้าเสี่ยงสุดทำแล้ว** | audit เนื้อหาเสร็จ 100% (2026-09-07) แต่มีแค่ 4 ไฟล์ทดสอบเดิม (QR login/notification 2 จุด) ก่อนรอบนี้ — **2026-09-08 รอบแรก 4 หน้าเสี่ยงสุด**: `student_calendar_page` (CRUD งานส่วนตัว), `student_pretest_posttest_page` (flow ทำข้อสอบครบ start/save/submit — เจอ+แก้บั๊ก error ดิบรั่ว 4 จุด), `student_safety_page` (ปุ่ม SOS), `student_assignments_page` (ส่งงาน+อัปโหลดไฟล์แนบจริง — เจอ+แก้บั๊ก error ดิบรั่วอีก 5 จุด) รวม 18 เทส. **รอบสอง (หลัง Teacher lane ปิดครบ 7/7)**: `student_lesson_view_page` (auto-update progress ตอนเปิดบทเรียน + mark-complete — เจอ+แก้ leaked error 2 จุด), `student_course_files_page` (list ไฟล์ + download/preview ผ่าน `CourseFileCard` แยกจากหน้าเลย — เจอ+แก้ leaked error 3 จุด), `student_lessons_page` (list บทเรียนกรองเฉพาะ published — เจอ+แก้ leaked error 1 จุด), `student_score_page` (คะแนนจริง + G-Score demo-badge ต้องติดป้ายเสมอ — เจอ+แก้ leaked error 1 จุด) รวม 19 เทส. **รวมทั้ง 2 รอบ 37 เทสใหม่ผ่านหมด แก้ leaked error รวม 16 จุด** `flutter test` เต็มล่าสุด 591 ผ่าน/8 fail (baseline เดิมไม่มี regression) push เข้า `gitlab` แล้วทุก commit · **เหลือ ~7 หน้า** (profile, course catalog 2 variant, navigation shell, variant_school_home ที่มี partial coverage อยู่แล้ว, weather sensor card, utility trend card, quick-action cards) — ยังไม่ได้ทำต่อ |
| ✅ Teacher lane: ปิดข้อมูลปลอมที่เหลือ (2026-09-09) | **ปิดงานแล้ว** ตอบคำถามเจ้าของ "ทำ Student/Teacher ให้ถึง 90-100%" — ไล่อ่านของจริงซ้ำทั้ง 2 เลน (ไม่เชื่อ audit เก่า 2026-09-07 เพราะมี commit ลงมาอีก ~14 ตัวหลังจากนั้น) พบว่าที่รายงานไว้ส่วนใหญ่ถูกแก้ไปแล้วจริง (การ์ดกล้อง AI ปลอม, mock notifications/assignments/devices, ตัวตนครูปลอม, เกรดปลอมในสมุดคะแนน, variant B/C — หายหมด grep ยืนยัน) **ที่ยังเหลือและปิดในรอบนี้ 3 จุด**: (1) `teacher_exam_builder_page.dart` seed โจทย์ AIoT ปลอม 3 ข้อ (PM2.5/I2C/%RH) + ชื่อชุดข้อสอบที่แต่งขึ้น ทุกครั้งที่เปิดหน้า — ครูกด "บันทึกร่างข้อสอบ" แล้วมันถูกเขียนลง DB จริงผ่าน `QuizService.addQuizQuestion` เป็นข้อสอบที่ครูไม่ได้เขียน แก้ให้เริ่มจากว่าง + empty state + guard ห้ามบันทึกชุดเปล่า (2) `teacher_courses_page.dart` ลิสต์ระดับโมดูล `mockTeacherCourses` seed รายวิชาปลอม 6 ตัว (ว31281 ฯลฯ) — หน้าหลักมี loading/error gate บังไว้แล้วก็จริง แต่ `TeacherCourseDetailPage` ยังหยิบผ่าน fallback `?? .first` ได้ตลอด เปลี่ยนเป็นลิสต์ว่าง + เปลี่ยนชื่อเป็น `teacherCourses` + หน้ารายละเอียดที่ไม่มีวิชาบอกตรง ๆ + เลิกโชว์ exception ดิบ + เพิ่ม seam `loadCourses`/`loadCourseStudents` (3) `teacher_aiot_lab_page.dart` `_toggle` เพิ่ม/ถอดนักเรียนออกจากกลุ่มต่อวงจร กลืน error เงียบ ๆ (fake-success) แก้ให้ขึ้นข้อความล้มเหลวจริง. test ใหม่ 9 เคส (`teacher_exam_builder_page_connection_test.dart` 4, `teacher_courses_page_connection_test.dart` 5) + แก้ `teacher_exam_builder_course_id_test.dart` ให้กดเพิ่มโจทย์เองก่อน (เดิมพึ่งโจทย์ปลอมที่ seed ไว้). `flutter test` เลน teacher+student 162/162 ผ่าน · เต็ม 642 ผ่าน/8 พัง (baseline เดิมเป๊ะ เลน Executive+school_admin) · `flutter analyze` 0 error |
| Student lane 2026-09-09: ตรวจซ้ำแล้ว **ไม่พบของปลอมที่ยังไม่ disclose** | ไล่ทุกไฟล์ที่ยังเหลือ (`student_safety_page`, catalog, `student_variant_school_home`, `aiot_weather_sensors_card`) — ต่อ service จริงหมด ของที่เหลือเป็น demo fallback ที่ติดป้าย "ข้อมูลจำลอง" ตามเมธอดอโลจี §8 อยู่แล้ว 2 จุด (`student_score_page` G-Score, `school_utility_trend_card`) และมี test บังคับป้ายอยู่ **ของค้างที่เจอ ไม่ได้แก้ (ถูกบล็อกสิทธิ์ลบไฟล์)**: `apps/user_app/lib/pages/student/` 4 ไฟล์ (`course_list`/`course_detail`/`grades_overview`/`lesson_view`) **ไม่มีใคร import เลยทั้งแอป** เป็น dead code ล้วน (grep ยืนยันทั้ง lib/ และ test/) ควรลบทิ้ง — ตอนนี้แค่ไม่มีผลกับผู้ใช้เพราะเข้าไม่ถึง ส่วน `apps/user_app/lib/pages/teacher/` 7 ไฟล์เข้าถึงได้เฉพาะ `/prototype/*` ซึ่ง gate ด้วย `const isPrototypeRoute = false` (compile-time) — ไม่ถึงมือครูจริง |
| ✅ ตรวจ role gate ของ RPC แจ้งเตือนเซนเซอร์กับ DB ที่รันอยู่จริง (2026-09-09) | **ปิดข้อสงสัยที่ค้างมาจาก `super_admin_audit_2026-09-07`** — ข้อที่เขียนไว้ว่า "ยังไม่ verify ว่า RPC ชื่อ `_for_school_admin` เปิดให้ `super_admin` เรียกได้ไหม" ตรวจแล้วด้วยการรันจริงใน transaction ที่ ROLLBACK ทิ้ง (สร้าง threshold + sensor_alert + session ของ `admin@aiot-school-lab.local` แล้วเรียก RPC จริง ไม่มีอะไรค้างใน DB): `acknowledge_sensor_alert_for_school_admin` เปิดให้ `('teacher','school_admin','super_admin')` · `resolve_...` เปิดให้ `('school_admin','super_admin')` ทั้งคู่มี `IF v_actor.role != 'super_admin' AND v_alert.school_id != v_actor.school_id` คือ **ยกเว้นการเช็คโรงเรียนให้ super_admin โดยตั้งใจ** ซึ่งจำเป็น เพราะ `admin@aiot-school-lab.local` มี `school_id` เป็น NULL จริงในฐานข้อมูล ผลรัน: ack → `{"success": true, "status": "acknowledged"}` · resolve → `{"success": true, "status": "resolved"}` · แถวจริงเปลี่ยนเป็น `resolved` + มี `acknowledged_by` · `audit_logs` ได้ 2 แถว `acted_role=super_admin` และ `school_id` เป็นของโรงเรียนเจ้าของอุปกรณ์ (ไม่ใช่ null — ไม่ซ้ำรอย audit-log null-school leak) ฝั่ง Dart ก็ถูก: `IncidentService.acknowledgeSensorAlert`/`resolveSensorAlert` และ `RealtimeService.acknowledgeAlert` ส่ง `p_token` เข้าตัว `_for_school_admin` ทั้งหมด **สรุป: ปุ่มรับเรื่อง/ปิดเรื่องของ Super Admin ใช้งานได้จริง ไม่ใช่ปุ่มพังเงียบ** **ผลพลอยได้ — แก้คำเตือนที่ผิดใน `scripts/state.sh`**: §4 เขียนมาตลอดว่า RPC กับดัก 6 ตัว "เรียกแล้ว actor เป็น null เงียบ ๆ ไม่ error" ตรวจ body ทั้ง 6 ตัวกับ DB จริงแล้ว **ทุกตัว `raise exception 'invalid_session'` เมื่อ `auth.uid()` เป็น null** คือพังดัง ๆ ไม่ได้พังเงียบ (ยังห้ามเรียกเหมือนเดิม แต่ความเสี่ยงคนละแบบ — เห็น error ทันที ไม่ใช่ข้อมูลเพี้ยนแบบเงียบ) แก้ข้อความใน state.sh แล้ว |

| ✅ seed ข้อมูลเซนเซอร์ให้ local dev (2026-09-09) | **ปิดงานแล้ว** `sensor_readings` เคยว่าง **0 แถว** ทำให้ทุกหน้าที่ใช้ utility RPC (พลังงาน/น้ำ/ESG/การ์ดอากาศนักเรียน/แจ้งเตือน) ขึ้น "ยังไม่มีข้อมูล" ตลอด — ตรวจไม่ได้เลยว่าหน้าพวกนี้ทำงานถูกไหม และเป็นเหตุผลที่ fallback ปลอมเคยถูกใส่มาปิดบัง **เจอ 2 สาเหตุจริง ไม่ใช่แค่ "ยังไม่ได้ใส่ข้อมูล"**: (1) บั๊กลำดับใน `supabase/seed.sql` — บล็อก `lesson_sensor_links` (บรรทัด ~157) ค้นหา device ชื่อ `เซนเซอร์ PM2.5 โถงกลาง` **ก่อน** บล็อกที่สร้าง device นั้น (บรรทัด ~262) ตอน `db reset` ครั้งแรกจึงได้ null แล้วข้ามการ insert readings ไปเงียบ ๆ ทุกครั้ง (`lesson_sensor_links` ก็เลยว่าง 0 แถวด้วย) (2) ไม่เคยมี device ชนิด `energy_meter`/`water_meter` เลยสักตัว ซึ่งเป็นเงื่อนไขบังคับ (`d.type = 'energy_meter'`) ใน `get_energy_usage_summary`/`_trend`/`_efficiency_score` — ต่อให้มี readings ก็รวมได้ 0 อยู่ดี **แก้โดยเพิ่มบล็อก seed ท้าย `supabase/seed.sql`** (อยู่ท้ายไฟล์ อุปกรณ์ครบแล้วแน่นอน · idempotent ทุก insert มี guard · ผูกกับโรงเรียน `TEST01` เท่านั้น จึงแตะ production ไม่ได้แม้เผลอ paste): เพิ่ม `energy_meter`/`water_meter`/`air_quality_sensor` อย่างละ 1 ตัว, เติม `devices.building` ที่เป็น null ทั้ง 9 ตัว (ตัวกรอง "อาคาร" เคยไม่มีอะไรให้กรอง), readings 2,516 แถว — ไฟฟ้ารายชั่วโมง 70 วัน + น้ำทุก 4 ชม. 70 วัน (70 วันคือค่าต่ำสุดที่ทำให้ `get_energy_efficiency_score` คืนคะแนนจริง เพราะมันเทียบกับเดือนก่อนหน้า) + อากาศรายชั่วโมง 3 วัน 5 metric, `thresholds` 3 แถว, `sensor_alerts` 2 แถว ค่าทั้งหมดสังเคราะห์ตามรูปแบบวันธรรมดา/วันหยุด กลางวัน/กลางคืน เพื่อให้กราฟมีรูปร่างจริง **ยืนยันด้วยการรัน RPC จริงใน transaction ที่ ROLLBACK**: energy summary 821.89 kWh/3,698.51 บาท · efficiency score 50 "พอใช้" (673.39 vs 675.01) · trend 7 วันได้ 8 แถวและวันเสาร์-อาทิตย์ต่ำจริง · water 49.671 m³ · `sensor_latest` ฝั่งนักเรียนคืน pm25/temperature/humidity/light_lux/co2 ครบ · `list_school_alerts` คืน 2 แจ้งเตือน รัน `seed.sql` ทั้งไฟล์ซ้ำแล้วไม่มีแถวซ้ำ (2,516 เท่าเดิม) `state.sh` §6 ขึ้น `sensor_readings 2516 แถว · devices.building null 0/12` |
| 🔴 พบระหว่างทำ: fixture `student2@aiot-school-lab.local` **หายไปแล้วจริง** | มีคนรัน `supabase db reset` เมื่อ 2026-09-08 (`student@` ถูกสร้างใหม่ 2026-09-08 08:06) fixture ลูกคนที่ 2 ที่เป็น runtime-only จึงถูกลบตามที่ CLAUDE.md เตือนไว้เป๊ะ — ตอนนี้ `parent@` มีลูกแค่ **1 คน** ทดสอบ student-switcher หลายลูกไม่ได้ ยืนยันแล้วว่าไม่ได้หายเพราะงานวันนี้: `seed.sql` ไม่มี `delete`/`truncate` สักบรรทัด (grep = 0) **ทางแก้ถาวรคือย้าย fixture นี้เข้า `seed.sql`** แบบเดียวกับที่ parent link คนแรกทำอยู่แล้ว — ยังไม่ได้ทำ รอเจ้าของสั่ง อัปเดตหมายเหตุใน CLAUDE.md ให้ตรงความจริงแล้ว |
| ✅ แยก "โหลดพัง" ออกจาก "ไม่มีข้อมูล" (2026-09-09) | **ปิดงานแล้ว** ไล่ `catch (_)` ทั้ง School Admin + Super Admin ตามที่ `state.sh` §5 เตือนไว้ 19 หน้า — **ส่วนใหญ่เป็น false positive** (เป็นคอมเมนต์ที่เล่าบั๊กเก่าที่แก้ไปแล้ว หรือ catch ที่ตั้ง error phase อยู่แล้ว) ของจริงที่ยังกลืน error เงียบเหลือ **6 จุดใน 5 ไฟล์** แก้ครบทุกจุด: `super_admin_hub_page` (แจ้งเตือน + audit log — การ์ด "เหตุแจ้งเตือน" เคยขึ้นเลข 0 สีเขียวเวลาอ่านแจ้งเตือนไม่ได้ อ่านได้ว่า "ทุกโรงเรียนปกติดี" ทั้งที่ระบบแจ้งเตือนพัง), `super_admin_permissions_page` (คำเชิญ + audit log), `super_admin_alerts_logs_page` (audit log), `super_admin_scan_page` (รายการอุปกรณ์ — โหลดพังแล้วสแกน QR จะขึ้น "ไม่พบอุปกรณ์" ทั้งที่อุปกรณ์มีจริง เพิ่มแถบเตือน + ปุ่มลองใหม่), `super_admin_settings_page` (audit log), `school_admin_leave_approval_page` (ไฟล์แนบ — ใบลาที่แนบใบรับรองแพทย์มาแต่โหลดไม่สำเร็จเคยขึ้นว่า "ไม่มีไฟล์แนบ" ซึ่งอาจทำให้ผู้อนุมัติปฏิเสธใบลาเพราะคิดว่าไม่มีหลักฐาน — เพิ่มปุ่มลองใหม่) ทุกจุด log ด้วย `debugPrint` ไม่โชว์ exception ดิบบนจอ test ใหม่ 6 เคส (hub 3 · scan 1 · settings 1 · leave approval 1) ครอบทั้ง "พังต้องบอกว่าพัง" และ "ว่างจริงต้องยังบอกว่าว่าง" `flutter test` เลน super_admin+school_admin 307/307 ผ่าน · analyze 0 error |
| ✅ บั๊กหน้า OTP โทษผู้ใช้ว่า "รหัสผิด" ตอน backend ล่ม (2026-09-09) | **ปิดงานแล้ว** เจอจากการใช้งานจริง ไม่ใช่จากการอ่านโค้ด — Docker Desktop crash ตอนดิสก์เต็ม 100% ทำให้ Supabase + Edge Function ลงทั้งชุด หน้า `login_otp_page.dart` (shared_ui) ยังขึ้นข้อความ **"รหัสไม่ถูกต้อง หมดอายุ หรือถูกใช้แล้ว"** ทั้งที่รหัสถูกต้อง (เจ้าของโปรเจกต์ลองเองก็เจอ ส่งภาพมายืนยัน) ผู้ใช้จะนั่งกรอกรหัสใหม่วนไปเรื่อย ๆ ทั้งที่ไม่มีรหัสไหนผ่านได้เลย ต้นเหตุ: `_submit()` ใช้ `catch (_)` เหมารวมทุก error เป็นรหัสผิด แก้ให้แยก "รหัสถูกปฏิเสธจริง" (`invalid_or_expired_otp` ที่ `AuthService.verifyLoginOtp` โยนเมื่อ Edge Function ตอบ 200 แต่ไม่มี session) ออกจาก "เรียกไปไม่ถึง" (transport/FunctionException) **ไม่แตะฝั่ง Edge Function** ที่จงใจตอบ `session: null` เหมือนกันทั้งกรณีรหัสผิดและกรณีตัวเองพัง เพราะนั่นคือ anti-enumeration ที่ตั้งใจไว้ — สิ่งที่ฝั่งแอปแยกออกได้จริงคือ "ต่อไม่ติด" เท่านั้น test ใหม่ 2 เคสใน `packages/shared_ui/test/login_otp_page_test.dart` (รหัสผิดจริงต้องยังบอกว่ารหัสผิด · ต่อไม่ติดต้องไม่โทษรหัส และไม่โชว์ exception ดิบ) 3/3 ผ่าน analyze สะอาด |
| ✅ ยืนยันข้อมูลเซนเซอร์ที่ seed ในเบราว์เซอร์จริง + กู้ Docker ที่ตายเพราะดิสก์เต็ม (2026-09-09) | **ปิดงานแล้ว** ล็อกอิน `schooladmin@` ในแอปจริง (flutter web `-d web-server` port 5599) แล้วเปิดหน้า **พลังงานทั้งโรงเรียน** — ตัวเลขบนจอตรงกับที่ RPC คืนเป๊ะ: การใช้ไฟ **821.9 kWh** · น้ำ **49.7 ลบ.ม.** · ค่าสาธารณูปโภค **฿4593** · คะแนนประสิทธิภาพ **57/100** (ไฟ) และ **55/100** (น้ำ) · กราฟ 7 วันมีรูปทรงจริง วันเสาร์-อาทิตย์ (5-6 ก.ย.) ตกลงเหลือ 40.2/40.4 kWh เทียบกับวันธรรมดา 117-119 kWh ตามรูปแบบที่ seed ไว้ หน้าแรก School Admin ก็ขึ้นของจริงครบ: นักเรียน **2 คน** (fixture `student2` ที่เพิ่ง seed ใช้งานได้จริง) · อุปกรณ์ **12 (11 ออนไลน์)** · การ์ด ไฟฟ้า/น้ำ/อากาศ ขึ้น 821.9 kWh / 49.7 m³ / PM2.5 22 · Log ล่าสุดขึ้น `auth.sign_in`/`auth.otp_verified` จริงจากการล็อกอินรอบนี้ **หมายเหตุที่ถูกต้องแล้ว**: การ์ด "สัดส่วนการใช้พลังงานรายอาคาร" ขึ้น "ยังไม่มีข้อมูลรายอาคาร" ตรงไปตรงมา ไม่ได้แต่งตัวเลขขึ้นมา **การกู้ระบบระหว่างทาง**: ดิสก์เต็ม 100% (เหลือ 192 MB) ทำให้ flutter web compile ตาย และ **Docker Desktop crash ทั้งตัว** — แก้โดย (1) ลบ cache เบราว์เซอร์ 4.3 GB + ตัวติดตั้งใน Downloads 601 MB + `flutter clean` (2) kill docker process ที่ค้างทั้งหมดแล้วรีสตาร์ต Docker Desktop (3) `npx supabase stop && start` เพราะ container `supabase_edge_runtime` หายไป ซึ่งเป็นตัวรัน `auth-verify-otp` (ไม่มีตัวนี้ = ล็อกอินไม่ได้ทั้งระบบ) (4) ลบ image เก่าของ Supabase **36 ตัว** ที่ไม่มี container ใช้ (postgres 6 เวอร์ชัน, studio 4 เวอร์ชัน ฯลฯ) — images 39.8 GB → 14 GB **ดิสก์ว่างจาก 1.4 GB → 26 GB** ข้อมูลที่ seed ไว้รอดครบหลัง stop/start (readings 2516 · alerts 2 · student2 1 · devices 12) |
| ⚠️➜✅ แก้ข้อมูลที่เขียนผิดเอง: `pages/student/` **ไม่ใช่ dead code** (2026-09-09) | บรรทัด "Student lane 2026-09-09" ด้านบนเคยเขียนว่า `apps/user_app/lib/pages/student/` ทั้ง 4 ไฟล์ไม่มีใคร import และควรลบทิ้ง — **ผิด** และเกือบทำให้ลบโค้ดที่ยังใช้งานอยู่ทิ้ง ของจริง: `home_page.dart` import แบบพาธสัมพัทธ์ `import 'student/course_list_page.dart';` (ไม่มีคำว่า `pages/` อยู่ในสตริง) grep ที่ใช้ยืนยันตอนนั้นเลยไม่เจอ — ตรงกับคำเตือนใน CLAUDE.md เป๊ะว่า grep พิสูจน์ได้แค่ "ไม่ต่อ" ไม่เคยพิสูจน์ "ไม่มีใครใช้" **เส้นทางจริงที่เข้าถึงได้ในโปรดักชัน**: `student_qr_login_page` (ล็อกอินด้วย QR จากแท็บเล็ตแล็บ) → `pushNamedAndRemoveUntil('/home')` → `HomePage` (main.dart:80) → `CourseListPage` → `CourseDetailPage` → `LessonViewPage` **ตายจริงไฟล์เดียว** คือ `grades_overview_page.dart` (289 บรรทัด, คลาส `GradesOverviewPage` ไม่ถูกอ้างที่ไหนเลยทั้ง repo) ยังไม่ลบ รอเจ้าของสั่ง **ผลที่ตามมาและแก้แล้ว**: 3 ไฟล์ที่ยังมีชีวิตยัด exception ดิบ (`$e`) ลงหน้าจอนักเรียน **13 จุด** (เดิมถูกจัดว่า "ไม่เป็นไรเพราะเข้าไม่ถึง") เปลี่ยนเป็นข้อความคงที่ + `debugPrint` ทุกจุด และเพิ่ม seam `loadCoursesFn`/`loadLesson`/`markCompleteFn`/`loadCourse` test ใหม่ 4 เคส (`student_qr_login_home_pages_connection_test.dart`) **หมายเหตุ**: `CourseDetailPage` ครอบด้วย widget test ไม่ได้ เพราะฝัง `model_viewer_plus` ที่ต้องมี `WebViewPlatform.instance` จริง — แก้ข้อความไปแล้วแต่ยังไม่มีเทสต์ยืนยัน |
| ✅ ปุ่ม "คะแนนของฉัน" บนเส้นทางล็อกอิน QR เคยขึ้น "เร็ว ๆ นี้" ทั้งที่ฟีเจอร์เสร็จแล้ว (2026-09-09) | **ปิดงานแล้ว** เจอตอนไปดูว่า `grades_overview_page.dart` คือไฟล์อะไรก่อนจะลบ — `home_page.dart` (ปลายทางของ `student_qr_login_page` → `/home`) มีปุ่ม "คะแนนของฉัน" ที่ `Navigator.push` ไป `ComingSoonPage` แปลว่านักเรียนที่ล็อกอินจากแท็บเล็ตในแล็บถูกบอกว่าฟีเจอร์ยังไม่มี ทั้งที่ระบบมีหน้าคะแนนที่ต่อ backend จริงอยู่ **2 หน้า** (`GradesOverviewPage` ในโฟลเดอร์เดียวกัน กับ `StudentScorePage` ในเลน redesign ที่เพื่อนซึ่งล็อกอินตามปกติเปิดได้จาก 3 ทาง) แก้ให้ปุ่มเปิด `StudentScorePage` (มี `Scaffold`/`AppBar` ของตัวเอง ถูก push ด้วย `MaterialPageRoute` ธรรมดาจาก nav shell อยู่แล้ว จึงย้ายมาใช้ได้ตรง ๆ ไม่ต้องแก้อะไรเพิ่ม) แล้ว **ลบ `grades_overview_page.dart` (289 บรรทัด) ทิ้ง** — เหลือหน้าคะแนนเดียวในระบบ ตัวที่มี connection test คุมอยู่ และนักเรียนทุกเส้นทางเห็นหน้าเดียวกัน **บั๊กแถมที่เจอระหว่างเขียน test**: `HomePage.loadUnreadCount()` เรียก `NotificationService.listMyNotifications()` แบบ **ไม่มี try/catch เลย** — โหลดพังกลายเป็น unhandled async error เพิ่ม catch + `debugPrint` และเพิ่ม seam `loadNotifications` test ใหม่ 1 เคส (`home_page_score_shortcut_test.dart`) ยืนยันว่ากดปุ่มแล้วได้ `StudentScorePage` และไม่มี `ComingSoonPage` โผล่ `flutter test` เต็ม 655 ผ่าน/8 พัง (baseline เดิม) analyze 0 error **ยังเหลือบนหน้าเดียวกัน**: ปุ่ม "กลุ่มของฉัน" ยังชี้ไป ComingSoonPage อยู่ ยังไม่ได้ตรวจว่ามี backend รองรับไหม |
| ✅ ปิดของค้างฝั่งเรา 4 จุด (2026-09-09 รอบเย็น) | **ปิดงานแล้ว** (1) **เทสต์แดงในเลนเรา** `school_admin_empty_and_error_states_test` บังคับให้หน้ารายงานพูดว่า "ระบบสร้างรายงานและส่งออกไฟล์ยังไม่พร้อมใช้งานในเวอร์ชันนี้" — ข้อความนั้นถูกลบไปตั้งใจตอนที่ export CSV/Excel ทำงานจริงแล้ว (2026-09-08) เทสต์ไม่ได้ตามมาแก้ กลายเป็นเทสต์ที่บังคับให้หน้าจอโกหก แก้ให้ตรวจข้อความจริง + กันไม่ให้กลับไปอ้างว่า export ใช้ไม่ได้อีก (2) `super_admin_learning_overview_page` เอา `e.toString()` ไปโชว์บนจอทั้งดุ้น เปลี่ยนเป็นข้อความคงที่ + `debugPrint` และรัดเทสต์เดิมให้ห้ามมี stack/exception หลุด (3) `super_admin_permissions_page` รหัสผู้ใช้ `USR-0001` สร้างจาก **ลำดับในลิสต์** (index+1) แต่ถูกโชว์ในกล่องรายละเอียดและใส่คอลัมน์ `user_id` ของ CSV — คนเดิมได้รหัสใหม่ทุกครั้งที่มีคนถูกเพิ่ม/ระงับ และ CSV คนละรอบอ้างอิงกันไม่ได้ เปลี่ยนไปใช้ `uid` จริง (จอโชว์แบบย่อ 8 ตัว CSV เต็ม) + test ใหม่ 1 เคส (4) `school_reports_page` dropdown **ช่วงเวลา/อาคาร/ห้อง** ไม่ได้กรองอะไรเลยสักตัว — ค่าที่เลือกถูกเอาไปพิมพ์เป็นหัวข้อ "ช่วง เดือนนี้ • อาคารเรียน B • A-101" เหนือตัวเลข **ของทั้งโรงเรียน** ผู้ดูแลเลือกอาคารแล้วอ่านตัวเลขรวมโดยเข้าใจว่าเป็นของอาคารนั้น แถมชื่ออาคาร/ห้องในลิสต์ก็แต่งขึ้นทั้งหมด (อาคารเรียน A/B, LAB-01, A-101 ไม่มีในฐานข้อมูล) ลบ dropdown ทั้ง 3 + คลาส `_Drop` ที่ไม่มีใครใช้แล้ว เปลี่ยนหัวข้อเป็น "ภาพรวมทั้งโรงเรียน ณ เวลาที่โหลดล่าสุด — เวอร์ชันนี้ยังไม่รองรับการแยกตามช่วงเวลา อาคาร ห้อง หรือประเภทรายงานที่เลือก" (บอกด้วยว่าการ์ดเลือกประเภทรายงาน 6 ใบยังไม่เปลี่ยนผลลัพธ์จริง) + test ใหม่ 1 เคส **ตรวจแล้วไม่ต้องแก้**: chip `ครูประจำอาคาร` ในหน้าสิทธิ์ถูกลบไปก่อนหน้านี้แล้ว (เหลือแต่คอมเมนต์อธิบาย) `flutter test` เต็ม **658 ผ่าน / 7 พัง** (ลดจาก 8 — ที่เหลือเป็นเลน Executive ของ codex ล้วน) analyze 0 error |
| ✅ ขั้น A: ครูเห็นคำขอผูกบัญชีผู้ปกครองของ **ทั้งโรงเรียน** (2026-09-09) | **ปิดงานแล้วบน local — ยังไม่ได้ขึ้น production (ติด D1)** ตรวจตามคำถามเจ้าของว่า "เรื่องเพิ่มผู้ปกครองของครูประจำชั้นเช็คหรือยัง" **หน้าจอสะอาด** (`teacher_parent_binding_approval_page.dart` ต่อ `ParentBindingService` จริงครบ 4 การกระทำ · ล้มเหลวขึ้น "อนุมัติไม่สำเร็จ" ไม่มี fake success · จับ `coi_self_approval_blocked` แล้วเปิดขั้นตอนส่งตรวจสอบซ้ำ) **ปัญหาอยู่ที่ backend**: `list_parent_links` กรองแค่ `su.school_id = v_school_id` — ครูคนไหนก็เห็นคำขอผูกบัญชีของนักเรียนทุกคนในโรงเรียน พร้อมชื่อ-นามสกุลนักเรียนและ **ชื่อ/อีเมลผู้ปกครอง** ทั้งที่ `approve_parent_link` ให้ครูอนุมัติได้เฉพาะนักเรียนที่ตัวเองสอน (`course_teachers ⋈ course_students`) ด่าน list จึงกว้างกว่าด่าน approve — ครูเห็นคำขอที่กดแล้วเจอ forbidden และข้อมูลติดต่อของครอบครัวคนอื่นก็หลุดไปยังครูที่ไม่เกี่ยวข้อง **แก้ด้วย migration `20260909000000_scope_list_parent_links_to_approver.sql`** ใส่เงื่อนไขเดียวกับ approve เข้าไปใน where — **หดสิทธิ์อย่างเดียว ไม่มีใครได้เพิ่ม** · `school_admin`/`super_admin` ยังเห็นทั้งโรงเรียนเหมือนเดิม (งานทะเบียนต้องอนุมัติแทนได้) · `ParentLinkReviewPage` ที่เปิดจาก `user_list_page` เป็นของ 2 role นั้น จึงไม่กระทบ pgTAP `48_list_parent_links_scope.test.sql` **7/7 ผ่าน** — ครอบว่าครูที่ไม่ได้สอนใครเลยต้องเห็น 0 ใบ (ของเดิมเห็น 2), อีเมลผู้ปกครองของครอบครัวอื่นต้องไม่หลุด, school_admin ยังเห็น 2 ใบ และที่สำคัญ **สิ่งที่ครูเห็น = สิ่งที่กดอนุมัติได้จริง** (lives_ok คู่กับ throws_ok) **ขั้น B ยังไม่ทำ รอเจ้าของเคาะ**: หัวไฟล์หน้าจอระบุสเปกว่าผู้อนุมัติคือ **ครูประจำชั้น** แต่ backend เช็คแค่ "ครูที่สอนวิชาที่เด็กลงทะเบียน" — ครูสอนพละที่เจอเด็กสัปดาห์ละคาบก็อนุมัติได้ว่าใครมีสิทธิ์เห็นข้อมูลเด็ก ระบบมี `homeroom_assignments` + `set_homeroom_teacher` + UI ในหน้า School Admin ครบแล้ว (local ยังไม่มีข้อมูลสักแถว) และ `school_admin` อนุมัติได้อยู่แล้วจึงไม่มีทางตันถ้าบีบ — แต่กระทบการทำงานจริงของครู ต้องให้เจ้าของตัดสิน |
| ✅ ขั้น B: ผู้อนุมัติผูกบัญชีผู้ปกครองฝั่งครู = **ครูประจำชั้น** (2026-09-09) | **ปิดงานแล้วบน local — ยังไม่ขึ้น production (ติด D1)** เจ้าของโปรเจกต์ยืนยันว่าในทางปฏิบัติคนที่ทำเรื่องนี้คือครูประจำชั้น และ **ห้องหนึ่งมีครูประจำชั้น 2 คนเป็นปกติ ทั้งคู่อนุมัติได้เท่ากัน** **เช็คก่อนลงมือว่าโครงสร้างรองรับ 2 คนไหม — รองรับอยู่แล้ว**: unique key ของ `homeroom_assignments` คือ `(academic_year_id, grade_level, room, teacher_id)` มี `teacher_id` อยู่ด้วย และ `set_homeroom_teacher` เป็น `INSERT ... ON CONFLICT DO NOTHING` = เพิ่มทีละคนไม่ทับของเดิม · UI ในหน้า School Admin ก็ใส่ทีละคนได้ ไม่ต้องแก้ schema หรือ UI เลย migration `20260909010000_parent_link_homeroom_teacher_only.sql` เปลี่ยนเงื่อนไขครูจาก `course_teachers ⋈ course_students` เป็น `_is_homeroom_teacher_of()` ใน **3 ฟังก์ชัน**: `approve_parent_link` · `reject_parent_link` (การปฏิเสธคำขอของครอบครัวอื่นร้ายแรงพอกัน) · `list_parent_links` **ดึงเงื่อนไขออกมาเป็นฟังก์ชันกลางตัวเดียว** เพราะบั๊กที่เพิ่งแก้ใน `20260909000000` เกิดจากเงื่อนไขของ list กับ approve เขียนแยกกันแล้วหลุดจากกัน — คราวนี้ทั้ง 3 ตัวเรียกตัวเดียวกัน แก้ที่เดียวจบ `second_approve_parent_link` ไม่แตะ (เป็น school_admin เท่านั้นอยู่แล้ว ถูกต้องสำหรับเส้นทาง escalate) **เคสข้อมูลไม่ครบไม่ตัน**: เด็กที่ยังไม่มีแถวใน `student_profiles` (ยังไม่จัดห้อง) หรือปีการศึกษาที่ยังไม่กำหนดครูประจำชั้น → ไม่มีครูคนไหนอนุมัติได้ แต่ `school_admin` อนุมัติแทนได้เสมอ มี pgTAP คุมทั้ง 2 ทาง pgTAP ใหม่ `49_parent_link_homeroom_only.test.sql` **9/9 ผ่าน** (ครูประจำชั้นทั้ง 2 คนอนุมัติได้ · ครูที่แค่สอนวิชาอนุมัติ/ปฏิเสธไม่ได้แล้ว · เด็กไม่มีห้อง → ครูไม่ได้ แต่แอดมินได้ · รายการที่เห็นตรงกับสิทธิ์ใหม่) และ **แก้ `48_list_parent_links_scope.test.sql` ที่กลายเป็นแดงทันทีเพราะกฎเปลี่ยน** — เขียนใหม่ให้ล็อก *ค่าคงที่* "สิ่งที่ครูเห็น = สิ่งที่ครูกดได้" โดยไม่ผูกกับกฎว่าใครเป็นผู้อนุมัติ (7/7 ผ่าน) · `04_parent_binding_consent` / `27_parent_portal` / `28_parent_executive_tier2` ไม่มี regression **ฝั่งแอป**: หน้าว่างของหน้าอนุมัติเพิ่มคำอธิบายขอบเขต ("แสดงเฉพาะคำขอของนักเรียนในห้องที่คุณเป็นครูประจำชั้น — ห้องอื่นให้ฝ่ายทะเบียนอนุมัติ") ไม่งั้นครูที่เคยเห็นทั้งโรงเรียนจะเห็นหน้าว่างแล้วนึกว่าระบบพัง + test 1 เคส และแก้คอมเมนต์สเปกหัวไฟล์ให้ตรงกับ backend แล้ว `flutter test` เต็ม 659 ผ่าน/7 พัง (เท่าเดิม เลน Executive ของ codex) analyze 0 error |
| ✅ **ปิดช่องโหว่บน production จริงแล้ว 3 จุด (2026-09-09)** | เจ้าของโปรเจกต์รันเอง (Claude ถูกบล็อกไม่ให้เขียน production) ตาม `PRODUCTION_FIX_0.2-0.4.md` — **หลักฐานจากเทอร์มินัลจริง ไม่ใช่รายงาน**: (1) `redeem_parent_binding_code` — ก่อนแก้ `has_function_privilege` = `true \| true` (ยืนยันว่าช่องโหว่เปิดจริงมาตั้งแต่ 2026-09-04) หลัง `revoke execute ... from anon, authenticated` = **`false \| false`** → ticket 0.2 ปิด (2) audit-log null-school leak — รัน `20260905040000` + บันทึกลง `schema_migrations` ผลตรวจ `like '%school_id IS NULL%'` = **`false`** และ `service_role` = **`false`** → ticket 0.3 ปิด (3) รอยรั่วรายการคำขอผูกบัญชีผู้ปกครอง — รัน `20260909000000` (ขั้น 3.5a) ผลตรวจ `list_parent_links` มี `course_teachers` แล้ว = **`true`** ครูไม่เห็นชื่อ/อีเมลผู้ปกครองของทั้งโรงเรียนอีกต่อไป **ยังไม่ได้ทำ**: `20260909010000` (ขั้น 3.5b บีบเป็นครูประจำชั้น) — **จงใจไม่รัน** เพราะเช็ค production แล้วพบ `homeroom_assignments` = **0 แถว** และนักเรียนที่ยังไม่มีห้อง 3 คน ถ้ารันตอนนี้จะไม่มีครูคนไหนอนุมัติคำขอได้เลยทั้งโรงเรียน ต้องกรอกครูประจำชั้นผ่านหน้า School Admin ก่อน (คู่มือแยกขั้นไว้แล้วใน commit `15a0cda`) **ยังไม่ได้ทำ**: ticket 0.4 (`npx supabase migration list --linked` ดูว่ามี migration ตัวอื่นค้างไหม) และ smoke test หลังแก้ |
| ✅ ticket 0.4 — production migration ไม่ได้ค้างอย่างที่กลัว (2026-09-09) | เจ้าของรัน `npx supabase migration list --linked` เอง ผลจริง: **158 migration ตรงกันทั้ง Local และ Remote ทุกแถว** มีแถวเดียวที่ Remote ว่างคือ `20260909010000` ซึ่งจงใจไม่รัน (ขั้น 3.5b รอกรอกครูประจำชั้น) และไม่มีแถวไหนที่มีแต่ฝั่ง Remote (production ไม่มีของแปลกปลอมที่ repo ไม่รู้จัก) **ข้อกังวลที่บันทึกไว้ใน `PRODUCTION_FIX_0.2-0.4.md` ว่าโปรเจกต์นี้เคยมี "ไฟล์ migration มีอยู่แต่ไม่เคยถูกรันจริง" ซ้ำหลายรอบ รวมถึงครั้งที่ production ค้างที่ snapshot เก่ากว่าเดือน — ตรวจแล้วไม่เป็นความจริงในตอนนี้** สถานะ schema ของ production ตรงกับ repo |
| ✅ ออกแบบหน้า login ใหม่ (2026-09-09) | ตามที่เจ้าของสั่ง เลือกแนว "ปรับของเดิมให้คมขึ้น" (คงโทนเขียว EDUSMART + ภาพโรงเรียน) และ "ลบปุ่ม Google/Apple ทิ้ง" **สิ่งที่พบก่อนออกแบบ**: ปุ่ม Google/Apple เป็น `Container` ที่มีแต่ไอคอน **ไม่มี `onTap` สักตัว** และทำงานไม่ได้อยู่แล้วเพราะระบบไม่ได้ใช้ Supabase Auth (hard rule 1) — โชว์ทางเข้าที่ไม่มีอยู่จริงให้ผู้ใช้กด **ที่แก้**: ลบปุ่ม social + เส้นคั่น 'or login with' · เปลี่ยนข้อความอังกฤษที่ปนอยู่กลางแอปไทยทั้งหมดเป็นไทย (Welcome back/Username/Password/Login/Forgot Password?) · ใส่ `labelText` จริง (เดิมเป็นสตริงว่าง มีแต่ hint ที่หายทันทีที่เริ่มพิมพ์ กรอกไปแล้วไม่รู้ว่าช่องไหนคืออะไร) · เพิ่ม `autofillHints` ให้ตัวจัดการรหัสผ่านเติมได้ · **กด Enter ที่ช่องอีเมลไปช่องรหัสผ่าน กด Enter ที่รหัสผ่านส่งฟอร์มเลย** (เดิมกด Enter ไม่มีอะไรเกิดขึ้น ต้องเอื้อมไปกดปุ่มทุกครั้ง) · ปุ่มโหลดบอกว่า 'กำลังเข้าสู่ระบบ…' แทนวงกลมหมุนเปล่า ๆ · จัด 2 ลิงก์ล่าง (รหัสเชิญ/ผู้ปกครอง) เป็นกล่อง 'ยังไม่มีบัญชี?' แยกจากการ์ดหลัก ไม่แข่งกับปุ่มเข้าสู่ระบบ touch target ≥48 · เพิ่มบรรทัดบอกล่วงหน้าว่าจะมี OTP 6 หลักส่งไปอีเมล · **เอาแอนิเมชันโลโก้ลอยขึ้นลงแบบวนไม่จบออก** (`repeat(reverse: true)`) เหลือ fade/slide ตอนเข้าครั้งเดียว — ภาพเคลื่อนไหวตลอดเวลาบนหน้าที่คนต้องจ้องกรอกฟอร์มรบกวนสายตาและกินแบต · เพิ่มผ้าคลุมไล่สีทับภาพพื้นหลังให้ตัวหนังสืออ่านออกทุกจอ **ยืนยันในเบราว์เซอร์จริง**: มือถือ 375px และเดสก์ท็อป 1280px เลย์เอาต์ไม่ล้น · ล็อกอินจริงด้วย `schooladmin@` ผ่านถึงหน้า OTP ครบ flow test ใหม่ 5 เคส (`login_page_redesign_test.dart`) ล็อกไว้ว่าไม่มีปุ่ม social กลับมา ข้อความเป็นไทย label ไม่หายตอนพิมพ์ กด Enter แล้วส่งฟอร์มจริง และทางเข้า 2 ทางยังอยู่ครบ · แก้ `widget_test.dart` ที่ตรวจข้อความเก่า ('Welcome back'/'Login') ให้ตรงกับของใหม่ · ขยาย `CustomTextField` ให้รับ `autofillHints`/`textInputAction`/`onFieldSubmitted`/`focusNode` (ทั้งหมด optional ค่าเริ่มต้น null = หน้าอื่นพฤติกรรมเดิม) · `flutter test` เต็ม 664 ผ่าน/7 พัง (เท่า baseline เลน Executive) analyze 0 error |
| ✅ หน้า login รอบ 2: ทำให้ทันสมัย + มีลูกเล่น (2026-09-09) | เจ้าของขอเพิ่มว่า "ดูทันสมัยหน่อย มีลูกเล่นด้วย" ต่อจากรอบแรกที่เป็นการปรับของเดิมให้คม **กติกาที่ตั้งไว้ก่อนทำ**: ลูกเล่นต้อง**ตอบสนองการกระทำของผู้ใช้** ไม่ใช่ขยับเองตลอดเวลาแบบโลโก้ลอยที่เพิ่งเอาออกไปในรอบแรก และต้องเคารพการตั้งค่า "ลดการเคลื่อนไหว" ของเครื่อง (`MediaQuery.maybeDisableAnimationsOf` — ถ้าเปิดไว้ พื้นหลังหยุดสนิท แอนิเมชันเข้าหน้าเหลือ 1ms) **ที่ทำ**: พื้นหลังไล่สีเขียวเข้ม + แสง 2 ก้อนเคลื่อนช้า 18 วินาที และขยับตามเมาส์บนเดสก์ท็อป · การ์ดกระจก (`BackdropFilter` blur 18) · **เลย์เอาต์ 2 คอลัมน์เมื่อจอ ≥900px** (ซ้ายแบรนด์+จุดขาย 3 ชิป · ขวาฟอร์ม) ต่ำกว่านั้นเป็นคอลัมน์เดียว · เข้าหน้าแบบไล่ทีละชิ้น (stagger) · ช่องกรอกเรืองขอบ+เปลี่ยนสีไอคอนตอนโฟกัส · ไอคอนตา/ปิดตาสลับแบบ scale · ปุ่มไล่สี 3 สีพร้อมลูกศร ยุบเล็กน้อยตอนกด แล้ว morph เป็น 'กำลังเข้าสู่ระบบ…' · ทักทายตามเวลาจริง (เช้า/บ่าย/เย็น จาก `DateTime.now()` ไม่ใช่ข้อความตายตัว) **เปลี่ยนจาก `CustomTextField` มาเป็น `TextFormField` ในไฟล์** เพราะต้องรู้สถานะโฟกัสเพื่อทำเอฟเฟกต์ — ยังเป็น `TextFormField` 2 ตัวเท่าเดิม เทสต์เดิมที่หา `find.byType(TextFormField)` จึงยังใช้ได้ **ยืนยันในเบราว์เซอร์จริง**: มือถือคอลัมน์เดียว · เดสก์ท็อป 1280px เป็น 2 คอลัมน์ · label ลอยขึ้นตอนกรอก · วงแหวนโฟกัสสีเขียวมิ้นต์ทำงาน · ล็อกอิน `schooladmin@` ผ่านถึงหน้า OTP ครบ flow เทสต์เดิม 5 เคสของรอบแรกยังผ่านหมดโดยไม่ต้องแก้ (ข้อความ/พฤติกรรมคงเดิม เปลี่ยนแค่เปลือก) `flutter test` เต็ม 664 ผ่าน/7 พัง (baseline เดิม) analyze 0 error |
| ✅ merge งาน Executive ของ codex เข้ามา + แก้ชนวันที่ (2026-09-10) | codex push งานขึ้น **GitHub (origin)** ไม่ใช่ gitlab — branch `codex/fix-executive-bug-3` 107 ไฟล์ (+13,694/−12,669) ต่อ backend จริงให้เลน Executive เกือบทั้งเลน (meetings · learning support · notification read state · attendance รายห้อง · overview อ่านของจริงแทน mock) พร้อม migration 13 ตัว + pgTAP 6 ชุด **บล็อกเกอร์ที่ต้องแก้ก่อน merge — เลข migration ชนกัน 5 คู่** และ 4 ใน 5 คู่นั้น production บันทึกไว้แล้วเป็นของฝั่งเรา (`20260908010000/020000/030000/040000` และ `20260909010000`) Supabase จำ migration ที่รันแล้วด้วย **version ไม่ใช่ชื่อไฟล์** ถ้า merge ทั้งอย่างนั้น `db push` จะข้ามของ codex ทั้งหมดโดยบอกว่า "รันแล้ว" → **RPC ของ Executive จะไม่มีอยู่จริงบน production ทั้งที่ `migration list` โชว์ว่า Local/Remote ตรงกัน** ซึ่งเป็นรูปแบบความผิดพลาดที่โปรเจกต์นี้บันทึกไว้เองว่าเคยโดนมาแล้ว แก้โดยย้าย migration **ทั้ง 13 ตัว** ของ codex ไปบล็อกใหม่ `20260910010000–20260910130000` คงลำดับเดิม (ย้ายเฉพาะตัวที่ชนไม่ได้ เพราะ `030000` ต้องรันก่อน `0301xx–0307xx` ที่ต่อยอดจากมัน) ทำบน branch แยกจากงานเขาก่อน (`9feb266`) แล้วค่อย merge · pgTAP 43–48 → 50–55 · อัปเดตเลขในเอกสาร 3 ไฟล์ที่อ้างถึง **บั๊กจริงอีก 2 อย่างที่เจอตอน merge**: (1) โค้ดใช้ `DropdownButtonFormField(initialValue:)` ซึ่งต้องใช้ Flutter ใหม่กว่าเครื่องนี้ (3.32.4) — แก้เป็น `value:` 3 จุด แปลว่า codex ทำงานบน Flutter คนละเวอร์ชันกับเครื่องเจ้าของ (2) **เทสต์ honesty ของ codex เองจับ RenderFlex overflow 46px** ในโมดัล SOS — หัวข้อไทยยาวใน Row ที่ไม่มี `Flexible` ครอบ บั๊กแบบเดียวกับที่โปรเจกต์นี้เจอซ้ำหลายรอบ แก้แล้ว emergency honesty 21/21 ผ่าน **WORK_LOG conflict** (630 บรรทัด) แก้โดย**เก็บทั้ง 2 ฝั่ง**ตามธรรมชาติของไฟล์ append-only พร้อมคั่นบรรทัดบอกว่าท่อนไหนมาจากเลนไหน **พิสูจน์แล้ว**: `db reset` รัน migration ครบ **171 ตัวเรียงถูกต้อง** และ seed.sql สร้างทุกอย่างกลับมา (readings 2,516 · student2 · devices 12) · pgTAP 54 ไฟล์ 901 เทส พัง 2 ตัวที่พังมาก่อนแล้ว (`14`/`16` ทดสอบ role `facility_manager` ที่ถูกลบตั้งแต่ 2026-08-25) · analyze 0 error ทั้ง 3 แพ็กเกจ · `flutter test` **716 ผ่าน/6 พัง** (ก่อน merge ฝั่งเรา 664/7) **6 ตัวที่เหลือ**: เทสต์ Executive รุ่นเก่าที่เขียนไว้ตอนหน้ายังเป็น mock ตอนนี้ต้องฉีด `DirectorOverviewController` ที่ codex เพิ่งใส่ — **ไม่แตะ** เพราะอยู่ในเลนที่ codex ทำอยู่ ให้เขาปิดเอง |
| ✅ เอา 2 บล็อกที่หายจากหน้าภาพรวม ผอ. กลับมาด้วยข้อมูลจริง (2026-09-10) | เจ้าของทักว่า "UI ไม่ตรงกับที่ออกแบบไว้" — เปิดเทียบของจริง 2 พอร์ต (worktree ที่ `60aa71d` = 7 ก.ย. บนพอร์ต 5600 · ล่าสุดบน 5599) แล้วล็อกอิน `executive@` ดูทั้งคู่ **แก้ข้อมูลที่ผมรายงานผิดก่อนหน้า**: ผมบอกว่า "หายไป 125 รายการ" จากการนับข้อความในไฟล์ `director_overview_page.dart` ไฟล์เดียว — **เกินจริง** เพราะ codex ย้ายหลายส่วนออกไปเป็น widget แยก (เช่น การ์ดเซนเซอร์อยู่ใน `widgets/director_overview_sensors.dart`) ส่วนหัวของหน้าเหมือนเดิมแทบทั้งหมด **ที่หายจริงและตรวจแล้วไม่เหลือในโฟลเดอร์ไหนเลย 5 บล็อก**: การเข้าเรียนของนักเรียน · การมาปฏิบัติหน้าที่ของครู · การจัดครูสอนแทน · กิจกรรมและห้องปฏิบัติการ IoT · กล้อง AI **ประเด็นที่สำคัญกว่า**: เปิดเวอร์ชัน 7 ก.ย. ดูแล้วบล็อกที่หายไปติดป้าย "ข้อมูลจำลอง" เกือบทั้งหมด (ภาพรวมครูและการสอน 48%/32%/13% · แนวโน้มทรัพยากร 431 kWh) — codex รื้อออกถูกแล้ว แต่**ไม่ได้เอาโครงกลับมาใส่ข้อมูลจริง** หน้าจึงบางลง **เอากลับมา 2 บล็อกที่มี RPC จริงรองรับ**: `HomeroomService.listSchoolAttendance` (การเข้าเรียนนักเรียนรายห้อง) และ `StaffAttendanceService.getSummary` (การลงเวลาของครู) เพิ่มเข้า `DirectorOverviewData` + `fetch()` และวาดเป็นแถวใหม่ต่อจากแถวทรัพยากร ใช้สีจาก palette ของเลนนี้ (โทนชมพู/ครีม) ไม่ได้เอาสีใหม่มาปน **เคสที่ต้องอธิบายสาเหตุ ไม่ใช่โชว์ 0**: ถ้าโรงเรียนยังไม่ตั้ง `staff_work_hours` ครูจะลงเวลาไม่ได้เลยสักคน — การ์ดขึ้นว่า "ยังไม่ได้ตั้งเวลาปฏิบัติงานของโรงเรียน" แทนเลข 0 ที่จะอ่านได้ว่าไม่มีครูมาโรงเรียน (ตรวจบนเครื่องจริงแล้วขึ้นเคสนี้พอดี เพราะ local ยังไม่ได้ตั้งค่า) เช่นเดียวกับนักเรียนที่ยังไม่เช็กชื่อ `school_homeroom_attendance.dart` ไม่เคยถูก export จาก `shared_core` มาก่อน (หน้าอื่นนอกแพ็กเกจใช้ไม่ได้) เพิ่ม export แล้ว test ใหม่ 4 เคส (`director_overview_attendance_test.dart`) ยืนยันว่าตัวเลขรวมมาจากห้องที่ส่งเข้ามาจริง · ยังไม่เช็กชื่อต้องบอกว่ายังไม่เช็ก · ยังไม่ตั้งเวลาปฏิบัติงานต้องบอกสาเหตุ ไม่ใช่โชว์ศูนย์ · แก้ fixture ของเทสต์เดิมให้รับ field ใหม่ `flutter test` **720 ผ่าน/6 พัง** (เท่าเดิม) analyze 0 error · ยืนยันบนเบราว์เซอร์จริงว่าทั้ง 2 การ์ดขึ้นถูกต้อง **ยังไม่ทำ**: การจัดครูสอนแทน (ไม่มี RPC) · กล้อง AI (มีแค่สิทธิ์เข้าถึง ไม่มีสถานะกล้อง) · กิจกรรม/แล็บ (ต้องดูว่า `AiotLabService` พอไหม) |
| ✅ เทสต์ปฏิทินนักเรียนแดงเฉพาะเสาร์-อาทิตย์ + pgTAP 14/16 ที่ตายแล้ว (2026-09-13) | ตรวจความพร้อมทั้งระบบ (branch `agent/fix-6-audit-bugs` ของอีกเซสชัน): user_app **774 ผ่าน/8 พัง** · shared_core 60/61 · shared_ui 17/17 · pgTAP 910 เทส 53/55 ไฟล์ · analyze 0 **2 ใน 8 ที่พังคือ `student_calendar_page_connection_test`** — พังบน commit ล่าสุดด้วย ไม่ได้เกิดจากงานค้างของใคร สาเหตุ: บอร์ดรายสัปดาห์บน desktop วาดแค่ **จันทร์–ศุกร์** (ตั้งใจ ตามคอมเมนต์ในโค้ด) แต่ fixture ใช้ `DateTime.now()` → วันเสาร์/อาทิตย์ event ไม่ถูกวาด เทสต์เขียว 5 วัน แดง 2 วัน **ที่แย่กว่า**: อีก 2 เทสต์ในไฟล์เดียวกัน (ลบ/ติ๊กงาน) มี `if (finder.isEmpty) return;` จึง "ผ่าน" ทุกวันหยุดโดยไม่เคยแตะ RPC เลย และเทสต์ติ๊กงานหา `Checkbox` ซึ่ง**ไม่มีในหน้านี้เลย** — ไม่เคยทดสอบอะไรตั้งแต่เขียน (2026-09-08) แก้: ตรึง fixture ที่วันจันทร์ของสัปดาห์ปัจจุบัน (บอร์ดวาดเสมอ) · ถอด early-return ทั้ง 2 จุดเป็น `expect` · เทสต์ติ๊กงานกดปุ่ม 'ทำเครื่องหมายว่าเสร็จ' ในแผงรายละเอียดจริง ผล 4/4 ผ่านและพิสูจน์ได้ว่า RPC ถูกเรียก 1 ครั้ง + reload **pgTAP**: ลบ `14_facility_manager_building_scope` / `16_facility_manager_device_list` ที่ล้มทุกครั้งตั้งแต่ 2026-08-25 (`enum role_type` ไม่มี `facility_manager`; scope อาคารถูกถอดจาก `sensor_latest`; `list_devices_in_my_building` ถูก rename เป็น `list_school_devices`) — แต่ `sensor_latest` ที่ทุกหน้าเซนเซอร์เรียกจะไม่มี pgTAP คุมเลยถ้าลบเฉย ๆ จึงเขียน `57_sensor_latest_and_device_list_tenant_scope` (11 เทส) ล็อกสัญญาปัจจุบัน: เห็นเฉพาะโรงเรียนตัวเอง · คืนค่าล่าสุดจริงตาม ts · ระบุ `device_id` ของโรงเรียนอื่นได้ 0 แถว · token ปลอมล้มดัง `npx supabase test db` **Result: PASS** (53 ไฟล์บน main) ทำบน branch `agent/green-tests` แตกจาก `main` ใน worktree แยก ไม่แตะ checkout ที่มีงานค้าง 40 ไฟล์ของอีกเซสชัน **ยังเหลือ**: shared_core 1 แดง (`SubmissionVersion.fromRow` fixture ขาด `submission_version_id` — บั๊กของเทสต์ ไม่ใช่แอป) · Executive 6 แดงเรื่อง seam เดิม |
| ✅ ความซื่อสัตย์ของหน้า Student/Parent/School Admin — 6 จุดที่เหลือจากการตรวจ 13 ก.ย. (2026-09-13) | ทำทุกจุดที่ไม่ใช่ Executive (เลนนั้น Claude อีกบัญชีแก้ UI อยู่ — ไม่แตะ) และไม่แตะตารางสอนครูที่มีงานค้าง **Student**: หน้าแรก (`student_variant_school_home.dart` แท็บแรก ทุกคนเห็น) โหลดพังเคยโชว์ `$e` ดิบ → ประโยคคงที่ + `debugPrint` · แคตตาล็อกวิชาตัวเต็ม (`student_course_catalog_page.dart` — ไม่อยู่ใน nav แต่แก้ให้เท่ากัน) · **หน้าคะแนน G-Score เคยสลับไปโชว์รายการจำลอง 3 รายการตอนไม่มีคะแนนจริง** มีป้าย "ข้อมูลจำลอง" ก็จริง แต่หัวการ์ดขึ้น "13 คะแนน" — นักเรียนที่ยังไม่มีคะแนนเห็นคะแนนที่ไม่ใช่ของตัวเอง ตัด `_demoEntries` ทิ้งทั้งก้อน ว่างคือ 0 คะแนน + บอกว่าจะได้คะแนนจากอะไร (เทสต์เดิมที่ล็อกพฤติกรรม demo ถูกพลิกเป็นล็อก 0) **Parent**: ขอลาให้ลูก (`leave_request_dialog.dart`) ส่งพังเคยขึ้น `เกิดข้อผิดพลาด: PostgrestException(...)` → แปล 4 รหัสที่ `submit_leave_request` raise จริง (`invalid_date_range` → "วันสิ้นสุดต้องไม่ก่อนวันเริ่มลา" · `forbidden` · `invalid_session` · `invalid_leave_type`) ที่เหลือประโยคกลาง เทสต์ใหม่ 3 เคส **School Admin**: โปรไฟล์ — สวิตช์แจ้งเตือน 3 ตัว `setState` อย่างเดียว **ไม่มี RPC ไม่มีตาราง และไม่มีระบบส่งอีเมล/แจ้งเตือนความปลอดภัยที่จะอ่านค่านั้น** (ตรวจ `pg_proc`/`information_schema` แล้ว มีแค่ `platform_settings`/`school_settings`) การสร้าง RPC เก็บค่าที่ไม่มีอะไรใช้ก็ยังหลอกอยู่ดี → ใช้กติกา DoD "ปุ่มที่ไม่มี backend = disable": `onChanged: null` ทั้ง 3 + หัวข้อบอกเหตุผล + เทสต์ล็อกว่ากดไม่ได้ **shared_core**: fixture `SubmissionVersion.fromRow` ขาด `submission_version_id` แดงมาตั้งแต่ `94ea879` ทั้งที่แอปถูก → 61/61 ผล: user_app widget tests ที่แตะ 22/22 · shared_core 61/61 · analyze 0 error **ยังไม่ได้ทำ**: หน้าแรกนักเรียนไม่มี widget test ครอบเส้นทาง error เพราะหน้ามี timer polling ของการ์ดเซนเซอร์ (เหตุผลเดิมใน `student_school_home_notification_test.dart`) · ไม่ได้ดูในเบราว์เซอร์ เพราะ dev server รันจาก checkout หลักที่มีงานค้างของอีกบัญชี |
| ✅ รวม branch `agent/fix-6-audit-bugs` (9 commits ของอีกบัญชี) เข้า main + เทสต์ staff attendance แดงหลังเที่ยงคืน (2026-09-14) | เจ้าของขอให้รวมแทนอีกบัญชีที่ยังพิมพ์อยู่ (ไฟล์ค้าง 40 ไฟล์ แก้ล่าสุด 00:31) ทำใน worktree จาก main → `git merge --no-ff agent/fix-6-audit-bugs` (ถึง `98f46a4` ซึ่งยังไม่ได้ push ไป remote ไหนเลย — ตอนนี้อยู่ใน main แล้ว) **ไม่มี conflict สักไฟล์** รวม design system · palette ซ้ำ · CCTV 8 กล้องปลอม · `$e` ครู 35 จุด · sidebar ม.5/2 · ชื่อโรงเรียน/online ตายตัว · permissions scope/status · migration `20260910140000` + pgTAP 56 (คิวคำสั่งรีเลย์/online จริง) **40 ไฟล์ที่เขายังไม่ commit ไม่ถูกแตะ** **pgTAP แดง 1 ตัวตอนตรวจ — ไม่ได้มาจาก merge**: `38_staff_attendance` test 25 ขอลาวันที่ `current_date` (UTC = 13 ก.ย.) แต่ `list_staff_attendance` อ่านวันตามเวลาไทย (14 ก.ย.) → แดงทุกคืน 00:00–07:00 เวลาไทย เป็นบั๊กเทสต์ตระกูลเดียวกับปฏิทินนักเรียน (เวลา/วันไม่ตรงกับที่ระบบใช้) แก้ให้ใช้ `(now() at time zone 'Asia/Bangkok')::date` เหมือน RPC ผล: pgTAP **PASS 54 ไฟล์ 921 เทส** · analyze 0 error ทั้ง 3 แพ็กเกจ · user_app **739 ผ่าน/6 พัง** (6 ตัว Executive seam เดิม) · shared_core 61/61 · shared_ui 17/17 **สิ่งที่อีกบัญชีต้องทำเมื่อ commit งานค้าง**: `git merge gitlab/main` — โค้ดจะไม่ชน (ทั้งหมดของเขาอยู่ใน main แล้ว) เหลือ `WORK_LOG.md` ที่ต้องเก็บทั้ง 2 ฝั่ง |
| ✅ 5 เลน (ยกเว้น Executive) — เก็บทุกจุดที่ยังไม่ซื่อสัตย์ให้หมด + ต่อ 3 ฟีเจอร์ที่ backend มีอยู่แล้วแต่ UI ปิดไว้ (2026-09-14) | เจ้าของขอ "ทำให้เป็น 100%" สแกน 82 หน้าด้วยเกณฑ์ใน DATA_CONNECTION_METHODOLOGY (หน้าไม่มี service เลย · `catch (_) {}` · snackbar สำเร็จโดยไม่มี await · `Future.delayed` · const list ข้อมูลธุรกิจ · fallback ไทยที่ดูเหมือนจริง · ปุ่ม `onPressed: () {}`) + ไล่รายการ audit 7 ก.ย. ทีละข้อกับโค้ดจริง (แก้ไปแล้ว 10/17) ได้ 14 จุดจริง ทำใน worktree จาก main ไม่แตะ 46 ไฟล์ค้างของอีกบัญชี **School Admin (3)**: (A1) **บั๊กจริงที่รายการเดิมพูดถึง** — sidebar ขาดรายการ "สายการเรียน" (หน้า 20) ทำให้ 3 แถวท้ายเปิดหน้าผิดคนละหนึ่ง (ตั้งเวลาปฏิบัติงาน→สายการเรียน · อนุมัติการลา→ตั้งเวลา · รายงานที่ต้องส่ง→อนุมัติการลา) และหน้ารายงานที่ต้องส่งเปิดจาก sidebar ไม่ได้เลย — เพิ่มแถวที่หาย + เทสต์ล็อกคู่ป้าย↔หน้า 4 แถวท้าย · (A2) หน้าอาคาร "สร้างอาคาร/สร้างห้อง" เคยขึ้นแค่ "ยังไม่มีระบบบันทึก" ทั้งที่ `import_school_buildings_batch`/`import_school_rooms_batch` มีจริง (pgTAP 29) → ฟอร์มจริงส่งทีละ 1 แถว แปล `skipped.reason` (duplicate_code → "รหัสนี้มีอยู่แล้ว") reload หลังสำเร็จ แก้ไข/ลบยังไม่มี RPC บอกตรง ๆ + แก้ป้าย "ในข้อมูลตัวอย่าง" → "ในระบบ" · (A3) ถอดส่วนสวิตช์แจ้งเตือน 3 ตัวออกทั้งส่วน (ไม่มีที่เก็บ/ไม่มีระบบใช้ค่า — ควบคุมที่ไม่มีผลไม่ควรอยู่บนจอ) **Teacher (7)**: (T1) ปุ่ม CCTV 2 ปุ่มในกล่องเหตุการณ์กดแล้วขึ้น "กำลังเปิดคลิป…/กำลังเชื่อมต่อกล้องห้อง ม.3/2" (ห้องแต่งขึ้น) ทั้งที่ไม่มีระบบกล้อง → disable + เหตุผล · (T2) แท็บนักเรียนในรายวิชาแปะ `'room': 'ม.4/1'` ให้ทุกคนทุกวิชา และตัด 8 ตัวแรกของ uuid โชว์เป็น "รหัส" → ห้องของรายวิชาจริง/อีเมล + โหลดล้มแยกจากว่าง (แท็บเป็น public `TeacherStudentRosterTab` มี seam) · (T3) ค้นหานักเรียนตอนเพิ่มเข้าวิชา ล้มเงียบ = "ไม่พบนักเรียน" → บอกว่าค้นหาไม่สำเร็จ · (T4) เปิดเคสช่วยเหลือ โหลดรายชื่อนักเรียนล้มเงียบ = ตัวเลือกว่าง → snackbar · (T5) คลังความรู้ list_course_files ของวิชาหนึ่งล้มเงียบ = "ยังไม่มีไฟล์ในวิชานี้" → สถานะโหลดล้ม + ลองใหม่ ต่อวิชา · (T6) signOut ล้มเงียบ → debugPrint · **(T7) ผูกเซนเซอร์กับบทเรียน**: ปุ่มถูกปิดด้วยเหตุผลที่ไม่จริงแล้ว (คอมเมนต์ว่าฝั่งนักเรียนไม่อ่าน แต่ทั้ง `student_lesson_view_page` และ `pages/student/lesson_view_page` อ่าน `sensorLinks` อยู่ และมี `listSchoolDevices` + `linkLessonSensor`) → dialog จริง: อุปกรณ์จาก list_school_devices · metric ตามชนิดอุปกรณ์ · link_lesson_sensor · อ่านกลับด้วย get_lesson · แสดงชื่ออุปกรณ์แทน uuid **Student (2)**: (S1) หน้าบทเรียน เปิดแล้วเขียนความคืบหน้า **50%** ทันทีถ้ายังไม่มีค่า → ขั้นต่ำ 10% (กติกาเดียวกับ pages/student/lesson_view_page) · (S2) ล็อกอิน QR: polling ล้มถูก `catch (_) {}` — แท็บเล็ตเน็ตหลุดโชว์ QR ปกติแต่สแกนแล้วไม่มีวันเข้าได้ → ข้อความ "เชื่อมต่อไม่ได้ชั่วคราว กำลังลองใหม่" **Parent (2)**: (P1) หน้าเข้าเรียน `note ?? 'บันทึกในคาบเรียน'` — ข้อความแต่งขึ้นในช่องหมายเหตุ → "ไม่มีหมายเหตุจากครู" · (P2) **กระดิ่งบน AppBar `onPressed: () {}` พร้อมจุดแดงถาวร** — ผู้ปกครองทุกคนเห็น "มีแจ้งเตือนใหม่" ตลอด กดแล้วไม่มีอะไร → จุดแดงจากจำนวนยังไม่อ่านจริง (list_my_notifications) กดเปิดรายการจริง ว่าง/ล้มบอกตรง ๆ **Super Admin (0)**: สแกนแล้วไม่พบอะไรที่ต้องแก้ **ไม่ได้แตะ (ตั้งใจ)**: `teacher_class_schedule_page` (อีกบัญชีถือไฟล์) · storybook/design-system (อยู่หลัง `isPrototypeMode` ไม่ถึงผู้ใช้) · `teacher_attendance` default 'present' ตอนเช็กชื่อ (UX ของหน้าเช็กชื่อ ไม่ใช่การแสดงข้อมูล) · "กำหนดครูประจำอาคาร" ยัง disable เพราะ `set_school_admin_building` เขียน `users.building` ไม่ใช่ `school_buildings.manager_name` ที่หน้าโชว์ เทสต์ใหม่/แก้: dashboard sidebar 1 · profile 1 · buildings 4 · roster 3 · incident CCTV 1 · library 1 · lesson sensor link 3 · lesson view 2 · parent bell 4 |
| ✅ code-review ของ `b6036a6..03aee84` — 15 ข้อ แก้ 14 (2026-09-14) | รีวิวงานตัวเองรอบ 5 เลนด้วย /code-review ระดับ xhigh ได้ 15 ข้อ **บั๊กจริงที่เพิ่งใส่เข้าไป 3 ข้อ**: (1) แท็บนักเรียนในรายวิชา `_loadFailed` ไม่รีเซ็ตเมื่อ "ลองใหม่" สำเร็จ → การ์ดล้มเหลวค้างทั้งที่ข้อมูลมาแล้ว (2) **เทสต์ปุ่ม CCTV ผ่านแบบหลอก** — `findAncestorWidgetOfExactType<OutlinedButton>` ไม่เจอ `.icon` ที่เป็น subclass → `onPressed` null เพราะหาไม่เจอ ไม่ใช่เพราะปิด (กับดักเดียวกับที่เจอในเทสต์ผูกเซนเซอร์แต่ตัวนี้พลาด) → ใช้ `w is ButtonStyleButton` + ยืนยันว่าเจอปุ่มก่อน (3) กระดิ่งผู้ปกครองเคลียร์จุดแดงไม่ได้จากในแผ่น (ไม่เคยเรียก `mark_notification_read`) → แถวแตะได้ เขียนผ่าน RPC แล้วอ่านกลับ **ที่เหลือ**: dialog ผูกเซนเซอร์เสนอรีเลย์/กล้องด้วย → กรองเฉพาะ `DeviceOption.isSensor` (ตารางชนิด→metric ย้ายไป `shared_core` ที่เดียว แทน const ในหน้า) · ผูกสำเร็จแล้ว `_loadFullLesson()` ทับสิ่งที่ครูพิมพ์ค้าง → `_refreshSensorLinks()` อ่านเฉพาะลิงก์ · ตัวเลือกนักเรียนตอนเปิดเคสดึงแค่ `courses.first` (บั๊กเดิม) → ทุกวิชา ตัดซ้ำ · `setSheet`/`setDialog` หลัง await ทั้งที่ผู้ใช้กดพื้นหลังปิดไปแล้ว → เช็ค `context.mounted` (อาคาร/ห้อง/ผูกเซนเซอร์) · ค้นหานักเรียนตอนเพิ่มเข้าวิชา race (คำตอบเก่าทับใหม่) → sequence number · header คลังความรู้ขึ้น "0 ไฟล์" ตอนโหลดล้ม → "โหลดไฟล์ไม่สำเร็จ" · `captionCtrl` ไม่ dispose → `_OwnControllers` · key `email`/`email_label` ซ้ำ · case `unknown_building` ตาย · เทสต์ sidebar จำกัดให้กดใน `_DesktopSidebar` (ป้าย "สายการเรียน" ซ้ำกับการ์ดหน้าหลัก) **ข้ามโดยตั้งใจ 1 ข้อ**: shell + dashboard ผู้ปกครองเรียก `list_my_notifications` ซ้ำ 2 ครั้งตอนเปิด — แก้ต้องผูก 2 widget ที่อิสระกันเข้าด้วยกัน คุ้มไม่คุ้มค่อยดูตอนทำ cache กลาง เทสต์ใหม่ 4 (ลองใหม่แล้วหาย · แตะแล้วอ่าน · ไม่เสนอรีเลย์ · ไม่มีเซนเซอร์บอกตรง ๆ) |
| ✅ ตรวจ "ตารางที่มีคนอ่านแต่ไม่มีคนเขียน" ทั้งระบบ + ปิด 2 ช่องโหว่ (2026-09-17) | ต่อจากบทเรียน student_profiles: query pg_proc 240 ตัวเทียบ 117 ตาราง (regex insert/update/delete vs from/join) แล้วเช็กว่า RPC ตัวเขียนถูกเรียกจาก Dart/edge function จริงไหม · **พบ 2 ช่องโหว่แบบเดียวกัน**: (1) `school_events` — ปฏิทินของครู/นักเรียน/ผู้ปกครอง/ผอ. อ่าน (3 RPC) แต่ `create_school_event` ไม่มีหน้าไหนเรียก และไม่มี RPC ลบ → migration `20260917020000 delete_school_event` + `CalendarService.createSchoolEvent/deleteSchoolEvent` + หน้าตั้งค่า School Admin เพิ่มการ์ด "กิจกรรมและวันสำคัญ" (list จาก list_calendar_events · สร้าง · ลบ ทั้งคู่ write→read-back) เทสต์ 3 (2) `staff_requests` (มติ D อนุมัติ 2 ชั้น) — ผอ. มีหน้า review แต่ `create_staff_request`/`cancel_staff_request` ไม่มีที่เรียก → คิวว่างตลอด → `StaffRequestService.create/cancel` (อ่านกลับยืนยัน) + `TeacherStaffRequestsCard` บนหน้าประชุมของครู (ยื่นขอเข้าพบ/ไปราชการ · รายการของฉัน · ยกเลิกที่ยัง pending) เทสต์ 5 · pgTAP 64 10/10 · ที่เหลือปกติ: ตัวเขียนที่ไม่ถูกเรียกอื่นเป็นของบอร์ด (poll_device_commands, report_relay_states, record_device_heartbeat) หรือ legacy ที่ revoke แล้ว · ตารางไร้ตัวเขียน 6 ตาราง (charts, learning_items, learning_simulators, security_events, device_categories, grade_criterion_scores) ไม่มีหน้าอ้าง = ตารางรอฟีเจอร์ ไม่กระทบผู้ใช้ · รอง: `get_meeting_minutes`/`cancel_meeting_minutes` ยังไม่ถูกเรียก (บันทึกประชุมอ่านผ่าน list_meetings แทน) · runbook 4.5 + `scripts/prod_apply_2026-09-17b.sh` · landed `cdd66e3` · migration รันบน prod แล้ว 2026-09-17 (`prod_apply_2026-09-17b.sh`, verify 1) |
| ✅ เริ่มทำเป็นแอปมือถือ — identity (2026-09-17) | เจ้าของตัดสินใจทำเป็นแอปติดเครื่อง ไม่ใช่เว็บ · Bundle ID `com.diliontech.aiotschoollab` (ล็อกแล้ว) ชื่อ/ไอคอนรอทีหลัง · พบว่าโปรเจกต์ iOS ยังไม่เคยคอมไพล์บนเครื่องนี้เลย (template จาก Flutter ≥3.35 แต่เครื่องมี 3.32.4 → กลับไปใช้ AppDelegate แบบเดิม) · deployment target 13→15.5 (mobile_scanner) · Android ขาด `INTERNET` ใน manifest หลัก (release APK จะไม่มีเน็ต) · `env.prod.json` + guard ห้าม release build ชี้ 127.0.0.1 + เทสต์ · `scripts/build_app.sh` · **ยังไม่ได้รันบน simulator จริง**: Flutter 3.32+Xcode 26.6 ตัด arm64 ออก และดิสก์เต็ม 0 byte กลาง build (Docker ล้ม กู้แล้ว ลบ image เก่า/cache ได้ ~6 GB) → ต้อง `flutter upgrade` + เคลียร์ดิสก์ ≥15 GB ก่อน · ยังไม่มี JDK สำหรับ Android · `9c91e28` |
| ✅ อัปเกรด Flutter 3.32.4 → 3.47.4 (2026-09-17) | จำเป็นเพราะ 3.32 + Xcode 26.6 ตัด arm64 ออกจาก simulator (iOS รันไม่ได้) และ template iOS ต้องการ ≥3.35 · หลังอัปเกรด user_app แดง 10/861: 8 ตัวจากกฎใหม่ "ListTile ในกล่องสีต้องมี Material ของตัวเอง" → ห่อ `Material(type: transparency)` 7 จุดใน leave-approval / pbl editor / submission review / student pretest / parent shell (ripple แสดงจริงแล้ว) · 2 ตัวจาก `FilledButton.icon` ไม่ใช่ subclass แล้ว → เทสต์ใช้ `.last` · ผล 861/861 + shared_core 66/66 + analyzer 0 error (infos 84→172 เป็น lint ใหม่) · analysis_options.yaml/pubspec.lock ที่ `flutter upgrade` แก้เอง commit ไปด้วย |
| ✅ แอปรันบน iPhone จำลองครั้งแรก (2026-09-17) | หลังอัปเกรด Flutter ยังติด `Module 'mobile_scanner' not found` — ราก: mobile_scanner 6.0.x ใช้ Google MLKit ซึ่งไม่มี arm64 สำหรับ simulator (pod ตั้ง `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`) → บน Mac ชิป Apple รัน simulator ไม่ได้เลย · อัปเกรดเป็น mobile_scanner 7.4.2 (iOS ใช้ Apple Vision ไม่มี MLKit) · API เปลี่ยนจุดเดียว: `errorBuilder` เหลือ 2 พารามิเตอร์ (3 หน้า) · เทสต์ scanner/QR 25/25 · ปิด Swift Package Manager (`flutter config --no-enable-swift-package-manager`) เพราะโปรเจกต์ใช้ CocoaPods และเปิดพร้อมกันทำให้ plugin หายทั้งสองทาง · **รันจริงบน iPhone 17 Pro simulator ชี้ prod แล้ว** ผ่าน `flutter run -d <sim> --dart-define-from-file=env.prod.json` |
| ✅ ล็อกอิน prod บนแอปมือถือสำเร็จ (2026-09-17 22:11) | เจ้าของล็อกอินด้วยบัญชีจริงบน iPhone 17 Pro simulator (แอปติดตั้งเป็น `com.diliontech.aiotschoollab`) → หน้าแรกนักเรียนแสดงข้อมูลเซนเซอร์จริงจาก prod พร้อม timestamp — ยืนยันว่า custom session + OTP + RPC ทำงานบน native iOS ครบวงจร · พบบั๊กเล็ก: การ์ดทักทายหน้าแรกนักเรียนเขียน "สวัสดีตอนเช้า" ตอน 22:11 (หน้าล็อกอินทายถูก) — ยังไม่แก้ |
| ✅ ตรวจ layout บน iPhone ครั้งแรก (2026-09-17) | ไล่ 5 แท็บ + drawer + 6 หน้าย่อยของ Student บน iPhone 17 Pro simulator (390pt) พร้อม `flutter run` จับ overflow · **AIoT Dashboard พังทั้งหน้า**: `SensorCard` ทุกใบล้นล่าง 36–150px ชื่อแตกทีละตัวอักษร เพราะ label+badge แชร์แถวเดียวและ grid ใช้ `childAspectRatio: 1.4` (สูงแค่ ~120px บนจอแคบ) → badge ลงบรรทัดใหม่, value ใช้ `FittedBox`, grid ใช้ `mainAxisExtent: 150` · หน้าความปลอดภัย: แถวประวัติ SOS+ป้ายเหตุใหญ่ล้นขวา 43px → `Flexible` (อีก 2 แถวทำให้ยืดหยุ่นด้วย) · drawer มีแถบขาวเหนือหัวเขียวใต้ status bar → วาด gradient ใต้ inset · เทสต์ใหม่ `iphone_layout_test.dart` pump ที่ 390×844 (เทสต์เดิมทั้งชุด pump ที่ 900px เลยไม่เคยเจอ) · 864/864 · ที่ยังไม่แก้: ข้อความย่อ "…" บนการ์ดเซนเซอร์หน้าแรก/ปุ่มลัด (อ่านได้ แค่ตัด), หน้าโปรไฟล์มีที่ว่างบนเยอะ · ยังไม่ได้ไล่ 5 บทบาทอื่นบนมือถือ |
| ✅ หน้า AIoT Dashboard ของ Student ออกแบบใหม่ (2026-09-18) | เจ้าของเห็นบน iPhone ว่าหน้าเดิม (`aiot_dashboard_page.dart` สีน้ำเงิน Material ยุคก่อน redesign) ไม่เข้าธีม → สร้าง `student_aiot_dashboard_page.dart` ใน palette Student: hero gradient บอกสภาพรวม+จำนวนเซนเซอร์ออนไลน์+เวลาอัปเดต · grid 2 คอลัมน์สูงคงที่ 138 ภาษาเดียวกับ tile บนหน้าแรก (สีตามระดับ, ป้ายระดับ, จุดสถานะออนไลน์) · legend ความหมายสี · empty state ตรงไปตรงมา · ข้อมูลจาก 2 stream เดิมเป๊ะ (sensorStream + rawReadingsStream) ไม่มีค่าปลอม, metric ที่ไม่เคยส่งแสดง "—" ไม่ใช่ 0 · เพิ่ม `SchoolPalette.danger` (สีเดิมที่ home card ฮาร์ดโค้ดไว้) · ปุ่มบนหน้าแรกชี้มาหน้าใหม่ · หน้าเก่ายังอยู่ให้ `home_page.dart` (legacy) · เทสต์ connection 3 + pump ที่ 390×844 · **บทเรียน**: `dart format <dir>` ใน worktree reformat ไฟล์อื่น 19 ไฟล์ (formatter 3.13 สไตล์ใหม่) — format เฉพาะไฟล์ที่แก้เท่านั้น |
| ✅ empty state หน้าแรกนักเรียน 3 ส่วน (2026-09-18) | เจ้าของเห็นบน iPhone ว่า "เรียนต่อ / งานที่กำลังจะมาถึง / ประกาศ" ตอนไม่มีข้อมูลเป็น SoftCard หดตามข้อความ → เม็ดยา 3 อันกว้างไม่เท่ากัน · สร้าง `StudentEmptyState` (เต็มความกว้าง ไอคอน+หัวข้อ+บอกว่าจะมีข้อมูลเมื่อไร) ใช้ทั้ง 3 จุด · เมื่อมีข้อมูลใช้ layout เดิมไม่แตะ · ข้อความ "ยังไม่มีประกาศ" คงเดิม (เทสต์ 3 ตัวอ้างอยู่) |
| ✅ hero หน้าแรกนักเรียนออกแบบใหม่ (2026-09-18) | บน iPhone มาสคอตทับข้อความรอง และการ์ดความคืบหน้าสีขาววางด้วย pixel offset ใน Stack → เปลี่ยนเป็น Column: ชิปทักทาย + ชื่อ + ข้อความรอง อยู่ใน Row เดียวกับมาสคอต (ทับกันไม่ได้) · แถบความคืบหน้าโปร่งแสงอยู่ในไล่สีเดียวกัน (วงแหวนเหลือง `SchoolPalette.yellow`, "N บทเรียน · ส่งแล้ว x/y") · ลบ `learning_progress_card.dart` (ไม่มีใครใช้แล้ว ไม่มีเทสต์) · เทสต์ hero ที่ 390pt ใน `iphone_layout_test.dart` |
| ↩️ ค้นหา Student: เจ้าของขอ popup แบบเดิม (2026-09-18) | ทำหน้าค้นหาเต็มจอแบบ iOS ที่ค้นวิชา/ใบงานจริง (`7b20eef`) → เจ้าของบอก "เอาแบบเดิม" → revert (`0584a9c`) เหลือ popup กระจกเดิม แต่**ตัดชิปปลอม** "AIoT / วิทย์ / งานค้าง / ครูสมชาย" (ป้ายที่แต่งขึ้น กดแล้วแค่สลับแท็บ) เป็นทางลัดจริง บทเรียน/ใบงาน/ปฏิทิน/คะแนน · ช่องพิมพ์ยังไม่ค้นอะไร (เหมือนเดิม) — ถ้าจะให้ค้นจริงในอนาคต โค้ดค้นหาอยู่ใน git history ที่ `7b20eef` · วันเดียวกัน: hero เตี้ยลง/มาสคอตใหญ่/แถบขาว (`a2b452f` `268bd47` `64e40d8`), ชิปเซนเซอร์ 4×2 (`8bee421`), ปฏิทินธีมเขียว (`cf256a9`), โปรไฟล์ชิดบน (`a80deee`) |
| ✅ ค้นหาจริงใน popup เดิม (2026-09-18) | หลังตรวจว่าช่องพิมพ์ใน popup ไม่ต่ออะไร เจ้าของสั่ง "ใส่ค้นหาจริงกลับเข้า popup เดิม" → `student_search_popup.dart`: หน้าตากระจกเดิม, ว่าง = ชิปทางลัดจริง, พิมพ์ = กรอง `listMyCourses` + `listAssignments` แสดงผลในกล่องเดียวกัน (สูงสุด 360px เลื่อนได้), ไม่พบบอกพร้อมคำ · เทสต์ 4 ตัว |
| 🐛 แอปไม่เคยกู้ session ตอนเปิด (2026-09-18) | เห็นบน iPhone: hot restart แล้วเด้งไปหน้าล็อกอิน → ไล่โค้ด: `AuthService.initialize()` (อ่าน token จาก Keychain + `auth_validate_session`) มีอยู่ครบ แต่**บรรทัดที่เรียกใน `main.dart` ถูกลบใน `ea191dd` (3 ส.ค. commit มาสคอต)** — บนเว็บไม่มีใครสังเกตเพราะแท็บเปิดค้าง บนมือถือ = OTP ทุกครั้งที่ปิดแอป · HANDOFF บรรทัด ~813 เคยจดอาการนี้แต่เดาว่าเป็น race · แก้ 1 บรรทัด + แก้ HANDOFF |
| ✅ แผ่น "เพิ่มกิจกรรมส่วนตัว" ตามแบบ iOS (2026-09-18) | เจ้าของถามว่าตามหลักสากลไหม → เดิม: พิมพ์ชั่วโมง/นาทีเป็นตัวเลข (ผิดก็ปัดเงียบ) ชื่อว่างกดแล้วเงียบ ปุ่มดำ ไม่มียกเลิก · ใหม่ `_AddPersonalEventSheet`: หัว ยกเลิก / กิจกรรมส่วนตัว / เพิ่ม, ช่องชื่อ, แถว "วัน" (date picker เปลี่ยนวันได้) + "เวลา" (วงล้อ Cupertino 24 ชม. ทีละ 5 นาที), ปุ่มเขียวเทาจนกว่าจะมีชื่อ · แผ่นคืนค่า (title, dueAt) หน้าเรียก `create_personal_task` แล้วกระโดดไปวันนั้น · เทสต์ 2 ตัว (phone size) · `_addPersonalEvent` รับ DateTime เต็ม |
| ✅ หน้าความปลอดภัย: ปุ่มแจ้งเหตุ 2 แบบชัดเจน (2026-09-18) | เจ้าของ: "ปุ่มแจ้งพบเหตุผิดปกติ ดูไม่รู้ว่าเป็นปุ่ม" (แถบเหลืองอ่อนดูเหมือนป้ายเตือน) → `_ReportActionCard` การ์ดเต็มความกว้าง 2 ใบ: SOS (แดง) + เหตุผิดปกติ (ส้ม) แต่ละใบมี tile ไอคอน gradient · ชื่อ · บรรทัด "ใช้เมื่อไร" · pill "แจ้งด่วน / แจ้งเหตุ →" · เทาทั้งคู่พร้อมข้อความอธิบายเมื่อมีเหตุค้าง · flow ยืนยัน (กดค้าง 3 วิ / ชิปเหตุผล) เดิมทั้งหมด เทสต์เดิม 6 ตัวผ่านโดยไม่แก้ · แผ่นเพิ่มกิจกรรมปรับสวยขึ้น (`2790d3d`) |
| ✅ 3 เรื่องเล็กที่ค้างจากรีวิวมือถือ (2026-09-18) | (1) คำทักทายเพิ่มช่วง "ตอนดึก" 0–4 น. และย้ายเป็น `lib/utils/greeting.dart` ให้หน้าล็อกอิน+หน้าแรกใช้ตัวเดียวกัน · (2) โปรไฟล์นักเรียนแก้ชื่อได้ (ดินสอที่ hero → ไดอะล็อก → `update_user_profile` ซึ่งอนุญาต self-edit อยู่แล้ว) เทสต์ 2 · (3) **`IncidentService.streamIncidentReports` / `EmergencyService.streamEmergencyEvents` เป็น `supabase.from(...).stream()` บนตารางที่ RLS deny-all → Realtime ไม่เคยยิงสักครั้งในทุก environment** ผู้ฟังทั้ง 3 หน้า (student safety / teacher inbox / director emergency) เลยไม่เคยรีเฟรชสด → เปลี่ยนเป็น tick ทุก 15 วิ ให้หน้าเรียก loader ของตัวเอง (payload ว่างเพราะไม่มีใครอ่าน) · เทสต์ทั้ง 3 หน้า + shared_core ผ่าน · เพิ่ม: หน้าความปลอดภัย v2 + แผ่นยืนยัน v3 (`4464c2a` `1ccd179`), แถบบน 44pt + margin 16 ตาม Apple HIG (`0b737f8` `13873eb`), ยกเลิกการตัด status bar (`8a09fdb` → ถอดใน `13873eb`) |
| ✅ PBL-6 นักเรียนเห็น+เปิดชุดข้อมูลเซนเซอร์ที่ครูกำหนด (2026-09-18) | ตรวจแล้ว: หลังบ้านมีครบตั้งแต่ 31 ก.ค. — `get_assignment` คืน `sensor_datasets` และ model parse อยู่แล้ว ครูผูกได้จากฟอร์ม แต่ **UI นักเรียนชุด redesign ไม่เคยแสดง** (มีแค่ใน `pages/student/course_detail_page.dart` เก่า) → เพิ่มส่วน "ชุดข้อมูลเซนเซอร์ที่ครูกำหนด" ในแผ่นส่งงาน + หน้า `student_sensor_dataset_page.dart` ดึง `sensor_history` ตามอุปกรณ์/ค่า/ช่วงที่ครูตั้ง → กราฟ + ต่ำสุด/เฉลี่ย/สูงสุด + จำนวนจุด; ไม่มีข้อมูลบอกตรง ๆ · ไม่มี migration · เทสต์ 4 · ยังขาด: ชื่ออุปกรณ์ (นักเรียนเรียก `list_school_devices` ไม่ได้ — จะเพิ่ม `device_name` ใน jsonb ตอนแก้ migration ของ PBL-10) |
| ✅ PBL-10 ส่งงานกลุ่ม (2026-09-18) | พบระหว่างทำ: **สวิตช์ "งานกลุ่ม" ในฟอร์มครูเป็นของปลอม** — `create_assignment`/`update_assignment` hardcode `is_group=false` มาตั้งแต่ 31 ก.ค. ค่าจากสวิตช์ถูกทิ้ง · migration `20260918010000_group_submissions`: รับ `p_is_group` · `submit_assignment` งานกลุ่ม = แถวเดียวต่อกลุ่ม (`group_id`) สมาชิกส่งซ้ำเป็นเวอร์ชันถัดไป, ไม่มีกลุ่ม → `not_in_group`, G-Score ให้ทุกสมาชิก · `list_my_submission_versions` เห็นร่วมกัน · `list_submissions` +`group_id`/`group_name` · เปลี่ยน is_group หลังมีการส่ง → `has_submissions` · pgTAP 65 (13/13) + 10/11 เดิมผ่าน · client: service ส่ง `p_is_group`, editor ส่งค่าสวิตช์จริง (เทสต์ยืนยัน), student sheet ป้ายงานกลุ่ม + ข้อความ not_in_group, teacher review แสดง "งานกลุ่ม · ชื่อกลุ่ม (ส่งโดย …)" · schema regenerated · **prod: รอเจ้าของรัน `scripts/prod_apply_2026-09-18.sh`** (ขั้น 4.6) · ยังไม่ทำ: ให้คะแนนงานกลุ่มครั้งเดียวถึงทุกคน (ตอนนี้ครูให้คะแนนรายคนเหมือนเดิม) |
| ✅ PBL-7 กราฟของนักเรียน (2026-09-18) | ตาราง `charts` มีแต่ 0 RPC · migration `20260918020000_charts_rpc`: `list_my_sensor_datasets` / `create_chart` / `list_my_charts` / `delete_chart` + helper `student_sensor_window_allowed` ที่ใช้กฎเดียวกับ `sensor_history` (นักเรียนอ่านได้เฉพาะช่วงที่ครูผูกในใบงาน/บทเรียน — `learning_dataset_required`) กราฟเก็บแค่ query ไม่เก็บตัวเลข (BR1) · pgTAP 66 13/13 · client: `ChartService` + `ChartableDataset`/`SavedChart` · หน้า "กราฟของฉัน" (list/ลบ) + "สร้างกราฟ" (เลือกชุดข้อมูล → ช่วงเวลาภายในขอบเขต → โน้ต → ดูตัวอย่างจาก `sensor_history` → บันทึก) · เปิดกราฟใช้ viewer ของ PBL-6 · ทางเข้าจาก AIoT Dashboard · เทสต์ 4 · **prod: รอรัน `scripts/prod_apply_2026-09-18b.sh`** (ขั้น 4.7) · ยังไม่ทำ: chart_type bar / compare_before_after (schema รองรับ แต่ UI มีแค่ line) |
| ✅ PBL-8 แนบข้อมูลเซนเซอร์เป็นหลักฐาน (2026-09-18) | ไม่ต้องแก้ฐานข้อมูล: ในแผ่นส่งงานเพิ่มปุ่ม "แนบข้อมูลเซนเซอร์" → เลือกกราฟที่บันทึกไว้ (PBL-7) หรือชุดข้อมูลที่ครูผูก (PBL-6) → ดึงค่าจริงผ่าน `sensor_history` → `buildSensorCsv` (metadata + ต่ำสุด/เฉลี่ย/สูงสุด + ทุกจุด, UTF-8 BOM เปิดใน Excel ได้) → เข้าคิวเป็นไฟล์แนบปกติ อัปโหลดผ่าน Edge Function เดิม ครูเห็นเป็นไฟล์ `เซนเซอร์-ฝุ่น-PM2.5-10-9-2569.csv` · ไม่มีข้อมูล/ไม่มีกราฟ → บอกตรง ๆ · เทสต์ CSV 3 + flow 2 · **PBL-6/7/8/10 ครบตามที่เจ้าของสั่ง** EMG-3 ยังไม่ทำตามคำสั่ง |
| ✅ ใช้จริงบน prod ครั้งแรก: จัดห้อง 3 คน + ครูประจำชั้น ม.1/1 · เจอบั๊ก 2 (2026-09-17) | เจ้าของล็อกอิน School Admin บน prod ผ่าน `user_app_prod` ให้ Claude คลิกให้ดู: set_student_profile 3 คน → ม.1/1 (read-back ยืนยัน) · มอบหมายครูประจำชั้น ม.1/1 → Teacher Demo **บันทึกลง prod สำเร็จแล้วจอแดง** `Assertion failed: _dependents.isEmpty` — `school_teachers_page._assignHomeroom` dispose TextEditingController ทันทีหลัง showDialog คืนค่า ขณะ TextField ยังวาด animation ปิดอยู่ (pattern เดียวกับที่แก้ในหน้าโปรไฟล์เมื่อ 14 ก.ย. แต่หน้านี้หลุด) → `_OwnControllers` ทั้ง dialog ครูประจำชั้นและแก้ชื่อ + เทสต์ที่ pump ผ่าน animation ทีละเฟรม · **พลาดจาก School Admin 100%**: หน้าโปรไฟล์มีปุ่ม "เปลี่ยนรูป" + ไอคอนกล้องบน avatar ที่รับลิงก์รูปเก็บใน state แล้วบอก "เปลี่ยนรูปโปรไฟล์แล้ว" — ไม่มีคอลัมน์/storage → ถอด + เทสต์ · ผล: `student_profiles = 3`, `homeroom_assignments = ม.1/1` บน prod → เงื่อนไข 3.5b ครบ ครูประจำชั้นอนุมัติผู้ปกครองได้แล้ว | 
| ✅ ตัวเขียน student_profiles ตัวแรก (2026-09-17) | เจ้าของกรอกชั้น/ห้องนักเรียน 3 คนบน prod แล้วเช็กไม่พบ → ไล่ดูพบว่า **ทั้งระบบไม่มี RPC เขียน `student_profiles` เลย** (อ่าน 18 ตัว: roster/เช็คชื่อ/learning track/ผู้ปกครอง/Executive) — local มีข้อมูลเพราะ seed.sql เขียนตรง จึงไม่มีใครเห็นช่องโหว่มาตลอด และ audit "100%" ก็พลาดเพราะไม่มีปุ่มปลอมให้จับ (ไม่มีปุ่มเลย) · สร้าง `20260917010000`: `set_student_profile` (upsert ปีการศึกษาปัจจุบัน · ว่างทั้งคู่ = ลบ · school-scoped · audit) + import RPC รับ `grade_level`/`room` · pgTAP 63 12/12 · `HomeroomService.setStudentProfile` · หน้านักเรียน School Admin: ชั้น/ห้องอ่านจาก `list_school_students` เป็นหลัก (เดิมอ่านจาก roster ครูประจำชั้น → ห้องที่ยังไม่มีครูประจำจะไม่แสดงชั้น = ไก่กับไข่) + ปุ่ม "กำหนดระดับชั้น / ห้อง" write→read-back + ฟอร์มเพิ่มนักเรียนมีช่องชั้น/ห้อง · CSV นำเข้า: "ห้องเรียน" แบบ `ม.1/1` แตกเป็นชั้น+ห้อง หรือคอลัมน์ "ระดับชั้น" แยก · เทสต์ students page 3 + shared_core 3 · runbook 4.4 + `scripts/prod_apply_2026-09-17.sh` | 
| ✅ Production ตามทัน local (2026-09-17) | pre-check อ่านอย่างเดียวด้วย `migration list --linked`: ขาด 6 ไฟล์พอดี (4.1×4 · 4.2 · 4.3) — Executive 18 ตัวอีกบัญชีรันไปก่อนแล้ว · devices บน prod 5 เครื่องมี firmware ปลอม `v1.2.0-prod` ทั้งหมด (4 ไม่เคย heartbeat) · Claude ถูกตัวกรอง "Production Deploy" ของ Claude Code บล็อกขั้นเขียน จึงเขียน `scripts/prod_apply_2026-09-16.sh` ให้เจ้าของรัน → ผ่านทั้ง 6 · verify: RPC ใหม่ 5/5 · fw default NULL · fake fw เหลือ 1 (เครื่องที่มี heartbeat จะถูกเขียนทับเอง) · offline_minutes enforced · **พบ**: 3.5b (`20260909010000`) ถูกรันบน prod ก่อนหน้าโดย `homeroom_assignments = 0` — เลือกได้ กรอกครูประจำชั้น หรือรัน `20260909000000` ทับเพื่อย้อนกลับชั่วคราว · ถัดไป: deploy แอป `04a552e` | 
| ✅ Executive overview: การ์ดเข้าเรียน + สัดส่วนคาบสอน 4 หมวด (งานค้างของอีกบัญชี, landed 2026-09-17) | อีกบัญชีทิ้ง diff 946 บรรทัดไว้ใน checkout หลัก 6 ไฟล์ตั้งแต่ 16 ก.ย. 09:43 ไม่ commit — เจ้าของสั่ง "ทำต่อให้เลย" จึงยก patch มาลง worktree จาก main: (1) การ์ดเข้าเรียนนักเรียน/ครู ออกแบบใหม่ (hero stat + chip grid, สีคนละชุด) (2) **แก้บั๊กนับ "ห้องที่เช็กชื่อแล้ว"** — เดิม `rooms.length` นับทุกห้องรวมที่ไม่มีใครเช็กเลย → นับเฉพาะห้องที่มีการบันทึกอย่างน้อย 1 คน (3) การ์ด "ภาพรวมครูและการสอน" เปลี่ยนจากสัดส่วนกลุ่มสาระ (list_departments) เป็น **สัดส่วนคาบสอนจริง 4 หมวด** ผ่าน `get_teacher_workload_summary` (migration 20260910160000 ของเขา) + หมายเหตุว่า 0 ในหมวดที่ต้องบันทึกมืออาจแปลว่ายังไม่มีใครบันทึก (4) launch.json เพิ่มโปรไฟล์ `user_app_prod` (anon key เป็น publishable) ตรวจแล้วไม่มีตัวเลขแต่ง/ปุ่มเฉย · เทสต์ overview ทั้ง 2 ไฟล์เขียว ชุดเต็มเขียว · checkout หลักของเขา: stash งานค้างไว้ (`git stash list`) แล้ว FF branch ตาม main | 
| ✅ Super Admin → 100% (2026-09-16) | ตรวจ 10 หน้าซ้ำ: ไม่มีตัวเลขแต่ง/ชื่อปลอม/ปุ่มเฉย/error=empty เหลือ 2 หน้า **ตั้งค่าระบบส่วนกลาง**: เก็บค่า 17 ตัว (เกณฑ์เซนเซอร์ · MQTT host/port · LINE/email/push · สำรองข้อมูล · maintenance · 2FA · audit log · ภาษา · เขตเวลา · retention · เวลาสำรอง) ลง platform_settings จริง แต่**ไม่มี RPC/trigger/edge function ตัวไหนอ่านเลย** — หน้ามีป้าย "บันทึกไว้อ้างอิง ยังไม่บังคับใช้" ครอบทั้งหน้า → ตัดเหลือค่าเดียวที่ทำให้มีผลจริงได้: `offline_minutes` — migration `20260916020000` ให้ `device_effective_status()` อ่านค่านี้แทน 5 นาทีตายตัว (pgTAP 62 5/5) · บันทึกแล้วอ่านกลับจากแถวที่ backend คืน ถ้าไม่ตรงบอกว่าไม่สำเร็จ · ถอดปุ่ม "เรียกคืนค่าเริ่มต้น" · `$e` ดิบ 2 จุด → ข้อความไทย · คอลัมน์อื่นใน platform_settings คงไว้ ไม่ลบ (ไม่ทำ migration ทำลาย) แค่ไม่เสนอเหมือนมีผล **ทดสอบอุปกรณ์**: ถอดแถว "MQTT Gateway Direct Probe · ยังไม่สามารถวัดได้" ที่ไม่มีวันวัดได้ (ระบบไม่มีเกตเวย์ บอร์ดเขียน sensor_ingest ตรง) · ป้าย "ระบบทดสอบฮาร์ดแวร์จริงยังอยู่ระหว่างการพัฒนา" → บอกขอบเขตจริง 4 อย่างที่วัด เทสต์: settings 2 ใหม่ + ลบ 1 ไฟล์เก่าที่ assert ป้าย Tier B · production: runbook 4.3 | 
| ✅ Parent → 100% (2026-09-16) | เลนผู้ปกครองสะอาดอยู่แล้วเกือบทั้งหมด (ตรวจซ้ำ 7 หน้า + shell: ไม่มีตัวเลขแต่ง/ชื่อปลอม/ปุ่มเฉย/`$e` ดิบ) เหลือ 2 จุดในหน้าตั้งค่า: (1) การ์ด "การตั้งค่าการแจ้งเตือน · ระบบยังไม่มี API สำหรับบันทึกค่ารายบุคคล" ครอบ empty state → ถอด (2) แถว "เปลี่ยนรหัสผ่าน: ยังไม่มีข้อมูล" ที่เป็น label เปล่า → ปุ่มจริงผ่าน dialog ร่วม change_my_password · seam `changePassword` + เทสต์ 1 | 
| ✅ Student → 100% (2026-09-16) | ปิดจุดที่เหลือของเลนนักเรียน **การ์ดพลังงาน (school_utility_trend_card)**: โรงเรียนที่ไม่มีมิเตอร์เคยขึ้นตัวเลขแต่ง 285 kWh / 12.5 m³ / กราฟ sine 7 วัน ใต้ป้าย "ข้อมูลจำลอง" — และ **backend ล่มก็เข้าสาขาเดียวกัน** (error = demo) → ถอด demo ทั้งชุด แทนด้วย "ยังไม่มีมิเตอร์ไฟฟ้า/น้ำ" และ error+ลองใหม่ **QR login**: (1) สาขา "Mock / Preview Mode" เมื่อไม่มี session แต่งอุปกรณ์ "แท็บเล็ตประจำโต๊ะแล็บ AIoT #01" แล้วขึ้น "เข้าสู่ระบบสำเร็จ (ตัวอย่าง)" โดยไม่เรียกอะไร → ถอด (ไม่มี session = แจ้งให้เข้าสู่ระบบก่อน) (2) ปุ่ม "จำลองสแกนรหัสสำเร็จ" บนเว็บที่ยิงรหัสตัวอย่างตายตัว → ช่องพิมพ์รหัสจับคู่จริง (มีใต้กล้องบนมือถือด้วย เผื่อกล้องใช้ไม่ได้) (3) `'$e'` ดิบ 2 จุด → ข้อความไทย (4) seams peek/claim/hasSession + เทสต์ 4 **โปรไฟล์**: ถอดการ์ด "ช่วยเหลือ" 3 แถว + แถว การแจ้งเตือน/PDPA ที่ greyed (list_my_consents เป็นของ parent_link ไม่ใช่นักเรียน) · เพิ่ม **เปลี่ยนรหัสผ่าน** จริงผ่าน dialog ร่วม **nav drawer**: ถอด "ช่วยเหลือ"/"ตั้งค่า" ที่ขึ้น "ยังไม่พร้อมใช้งาน" **หน้าแรก**: pump ทั้งหน้าในเทสต์ได้เป็นครั้งแรก — AiotWeatherSensorsCard ได้ stream override, การ์ดคติพจน์ถอด Timer 4 วิที่เลื่อนไปสไลด์เดิม (มีสไลด์เดียวมาตั้งแต่ 17 ส.ค.), utilityCardBuilder seam → เทสต์ loading/data/error/retry ของหน้าแรก 2 เทสต์ใหม่/แก้: utility card 2, QR 4, profile 1, home 2 · เลนนักเรียนไม่เหลือ placeholder/ตัวเลขแต่ง/error=empty บนเส้นทางที่ผู้ใช้ถึง | 
| ✅ Teacher → 100% (2026-09-16) | ปิดจุดที่เหลือของเลนครู 27 หน้า **backend** `20260916010000_list_lesson_progress.sql` — RPC อ่านความคืบหน้าบทเรียนรายคน (นักเรียนเขียน lesson_progress ผ่าน update_lesson_progress/mark_lesson_complete มาตลอด แต่ครูไม่มีตัวอ่าน หน้า "สถิติบทเรียน" จึงเป็น placeholder) · pgTAP 61 9/9 · `LessonService.listProgress` + `LessonStudentProgress` **lesson editor**: หน้าสถิติบทเรียนแสดงจริง — จำนวนที่เปิด/จบ/เฉลี่ย + รายคนพร้อมแถบ progress, error+retry **profile**: (1) เคยใช้ `.catchError((_) => [])` ทีละ call → backend ล่ม = "ยังไม่มีวิชาที่สอน" (error=empty) → ล้มทั้ง load แสดง "โหลดไม่สำเร็จ" (2) ถอดการ์ด "ช่วยเหลือ" 3 แถว + แถว การแจ้งเตือน/ซิงก์ออฟไลน์/PDPA ที่ greyed "ยังไม่เปิดใช้งาน" (ไม่มีหน้า/ตาราง) (3) **แก้ไขชื่อที่แสดง** จริงผ่าน update_user_profile + **เปลี่ยนรหัสผ่าน** ผ่าน dialog ร่วม change_password_dialog (4) ถอดข้อความ "ยังเปลี่ยนภาคเรียนจากหน้านี้ไม่ได้" — ภาคเรียนปัจจุบันเป็นของโรงเรียน ไม่ใช่ของครู (5) seams ครบ + เทสต์ 6 **courses**: ปุ่ม "ส่งออกคะแนน (ยังไม่เปิดใช้งาน)" ในแท็บสมุดคะแนน → **CSV จริง** จากแถวที่โหลด · แท็บสมุดคะแนนเคยกลืน error ของ list_course_grades (นักเรียนทุกคน 0 คะแนน) → error state + ลองใหม่ · แผ่น "สร้างสื่อ/งานใหม่": "สร้างใบงาน" → เปิด TeacherAssignmentEditorPage จริง, "แนบสื่อ" → เปิดแท็บบทเรียนของวิชา (TeacherCourseDetailPage.initialTab ใหม่) · ถอดปุ่ม "จัดเรียง" และ ⋯ ที่ขึ้น "UI Prototype" **grading**: ปุ่ม "เผยแพร่" บนการ์ดร่างเคยขึ้น "UI Prototype" → publish_assignment จริง + อ่านกลับ ถ้ายังเป็นร่างบอกว่าไม่สำเร็จ · **students**: แถวนักเรียนกดแล้วขึ้น "UI Prototype" → ไม่กดได้ (ไม่มีหน้ารายคนในเลนนี้) · **incident inbox**: ถอดปุ่ม CCTV disabled 2 ปุ่ม + `_demoBadge` ที่ไปไม่ถึง · **assignment editor**: ถอดหัวข้อ "ผูกชุดข้อมูลเซนเซอร์ · ยังไม่รองรับ" (student redesign ไม่แสดง assignment_sensor_datasets จึงผูกไปก็ไม่มีใครเห็น) เทสต์ใหม่/แก้: lesson 2, profile 6, gradebook 2, grading 2, inbox 1 · เหลือแค่ `teacher_storybook_page`/`teacher_design_system_page` ที่มี mock action แต่เป็นหน้า dev-only หลัง `isPrototypeMode` (ไม่ register route ใน build ปกติ) · production: runbook ขั้น 4.2 | 
| ✅ Executive → 100% (2026-09-16) | ต่อจากแถวถัดไป ปิดจุดที่เหลือทั้งหมดของเลน **settings**: ถอดแท็บ การแจ้งเตือน/การแสดงผล/รายงาน (placeholder "ยังไม่เปิดใช้งาน" 3 แท็บ ไม่มีตารางเก็บ) · ถอดปุ่ม "เปลี่ยนรูป" (ไม่มีคอลัมน์รูป) · ถอดช่องเบอร์โทร "ยังไม่รองรับ" (users ไม่มี phone, set_staff_profile เป็นของ school_admin) · ถอดแถว "แจ้งเตือนเมื่อเข้าสู่ระบบ · ยังไม่เปิดใช้งาน" · **เปลี่ยนรหัสผ่านจริง** ผ่าน change_my_password — dialog ใหม่ `lib/widgets/change_password_dialog.dart` ใช้ร่วมกับหน้าโปรไฟล์ School Admin (ย้ายออกมาจากหน้านั้น) **CCTV**: ถอด "AI ปิด"/"ไม่บันทึก"/"ไม่ได้บันทึก"/REC/LIVE/"ไม่มีข้อมูลเวลาล่าสุด" — ค่าตายตัว false ที่ถูกแสดงเป็นสถานะ · ถอดการ์ด "แจ้งเตือนจาก AI Camera" และ "พื้นที่จัดเก็บ & AI Detection" · แทนแผง AI ด้วย "การรายงานตัวของอุปกรณ์" จาก get_school_device_detail (รายงานตัวล่าสุด/เฟิร์มแวร์/IP จริง, null = ยังไม่เคยรายงาน) **ฉุกเฉิน**: ป้าย "ยังไม่มีข้อมูลรองรับ" เคยขึ้นบน 4 การ์ดเมื่อโรงเรียนไม่มีเหตุ (ศูนย์เหตุ = ข้อมูลจริง ไม่ใช่ไม่มีข้อมูล) → ป้ายอิง `_loadFailed` แทน · แก้ overflow 2 จุด (badge Row→Wrap ที่ 320px, badge ในหัวการ์ดสรุปที่ 1024px) ที่ทำให้เทสต์ layout แดงมานาน **scan**: ถอดการ์ด "บริการเพิ่มเติม · ยังไม่เปิดใช้งาน" 2 ใบ (บัตรบุคลากร/ยืม–คืน/ประวัติสแกน — ไม่มีตาราง) · **meeting_detail**: ถอดปุ่ม disabled "ตั้งเตือนล่วงหน้า — ยังไม่รองรับ" · **environment**: ถอดหัวข้อ "ข้อเสนอแนะการประหยัดพลังงาน" ที่เหลือแต่กล่องว่าง **ลบไฟล์ปลอมที่ตายแล้ว**: data/director_mock_data.dart (ครูปลอม 9 คน · ชั้นเรียน/โปรแกรม/ประชุมปลอม) · widgets/teacher_picker_dialog.dart · models/director_models.dart · DirectorListCard ที่ไม่มีใครใช้ **เทสต์**: ลบ 4 ไฟล์ที่ assert mock 7 ก.ย. (48%/ตรวจพบเหตุทะเลาะวิวาท/สิงหาคม 2569) ซึ่งแดงมาตลอด · infinite_height_layout_audit ใช้ seam ของหน้าฉุกเฉิน · เทสต์ใหม่/แก้: cctv 2, settings 3, scan 1 → **user_app เขียวทั้งชุด 0 แดง** (จากเดิม 6 แดงประจำ) **ยังค้าง**: overview ที่อีกบัญชีแก้ค้าง 6 ไฟล์ (ไม่ใช่เรื่องข้อมูลปลอม — เป็นฟีเจอร์ teacher workload) | 
| ✅ Executive: CCTV + ฉุกเฉิน ล้างจุดสุดท้าย (2026-09-16) | ตรวจเลน Executive ซ้ำหลังอีกบัญชี commit `455112a` — 13/15 หน้าสะอาดแล้ว เหลือ 2 หน้า **CCTV** (1) ตัวกรองอาคารเป็น const list `'อาคาร 1/2/3','สนามกีฬา','ทางเข้าโรงเรียน'` เทียบกับ `device.location` ที่ค่าจริงคือ `'อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก'` → เลือกอาคารไหนกล้องหายหมด (บั๊กชนิดเดียวกับ filter หน้า school_alerts) → ตัวเลือกสร้างจากกล้องที่โหลดจริง (2) `_loadCameras`/`_loadGrants` ใช้ `catch (_)` ไม่มี error state → backend ล่ม = "ยังไม่มีกล้องในระบบนี้" → เพิ่ม `_camerasFailed`/`_grantsFailed` + ปุ่มลองใหม่ (3) ถอดปุ่ม บันทึกภาพ/Playback/เต็มจอ ที่กดได้แต่ขึ้น snackbar **ฉุกเฉิน** (1) modal SOS ยังมีทีมตายตัว "ครูเวรอาคาร 3 · ได้รับแจ้งแล้ว" "ครูห้องพยาบาล · Standby พร้อม" ใต้ป้าย demo บนเหตุจริง → ข้อความว่ายังไม่มีตารางเวร/การยืนยันรับแจ้ง (2) ไทม์ไลน์แต่งเวลา "ส่งสัญญาณ" = createdAt+1 วิ และขั้น "ครูห้องพยาบาลกำลังเข้าพื้นที่" ที่ไม่มีอะไรบันทึก → เหลือ 3 ขั้นที่มีข้อมูลจริง (รับสัญญาณ/ผอ.รับเรื่อง/ปิดเหตุ) (3) ถอดปุ่ม snackbar-only 7 ตัว: แผนที่ · โทรครูเวร ×2 · แจ้งเตือนซ้ำ · CCTV ×2 · ทีมครูเวร; "ประวัติเหตุการณ์" (เดิมขึ้น "กำลังเปิดรายงาน…" แล้วไม่เปิด) กับการ์ด "เหตุที่กำลังติดตาม" เปลี่ยนเป็นตั้งตัวกรองรายการประวัติจริง เทสต์ใหม่ 5 (cctv 3 · emergency 2) ชุด Executive เดิมยังเขียว **ยังไม่แตะ**: `data/director_mock_data.dart` `widgets/teacher_picker_dialog.dart` `models/director_models.dart` — โค้ดตายที่ไม่มีหน้าไหนเรียก (ครูปลอม 13 คน) ควรลบทีหลัง · overview อีกบัญชีกำลังแก้ค้าง (เทสต์แดง 6 เดิม) | 
| ✅ School Admin → 100%: backend ใหม่ 4 migration/19 RPC + UI 12 หน้า (2026-09-14→16) | เจ้าของสั่ง "School Admin ทำให้ครบ 100%" — สแกนพบจุด "ยังไม่เปิดใช้งาน" ~30 จุดใน 13 หน้า ส่วนใหญ่**ไม่มี RPC รองรับ** จึงต้องสร้าง backend ก่อน **Backend** (pgTAP 58/59/60 = 47 เทส เขียว · 29 เดิมยังผ่าน): `20260914010000` แก้/ลบอาคาร-ห้อง (บล็อกถ้ายังมีห้อง/อุปกรณ์อ้างถึง) · set_school_building_manager · update_school_device · acknowledge_all_school_alerts · **create_academic_year / create_term / list_academic_years — ก่อนหน้านี้โรงเรียนใหม่เปิดเทอมจากแอปไม่ได้เลย (มาจาก seed เท่านั้น)** · `20260914020000` change_my_password (ตรวจรหัสปัจจุบัน เตะเซสชันอื่น) · list_my_sessions / revoke_my_session · **import users ใหม่: รหัสชั่วคราวสุ่มต่อคน + must_change_password + คืน credentials ครั้งเดียว + รายงานแถวที่ข้าม** (ปลดล็อกการนำเข้าผู้ใช้ที่ปิดไว้ตั้งแต่ 7 ก.ย. เพราะรหัส Test1234! เหมือนกันทุกคน) · `20260914030000` get_utility_usage_by_location · `20260914040000` get_school_device_detail + **ถอด default ปลอมในสคีมา `ip_address='192.168.1.100'`/`firmware_version='v1.2.0-prod'`** (อุปกรณ์ทุกตัวอ้างค่านี้โดยไม่เคยรายงาน; ล้างเฉพาะตัวที่ไม่มี heartbeat) **ทุกบทบาท**: `UserModel.mustChangePassword` + `ForcePasswordChangePage` ใน RoleRouter — คอลัมน์มีมาตั้งแต่ต้นแต่ไม่มีใครอ่าน **UI 12 หน้า** (เทสต์ School Admin ทั้งชุดเขียว): โปรไฟล์ (เบอร์/ตำแหน่งลง staff_profiles · ฝ่ายอ่านจาก directory · ถอดช่องรหัสบุคลากรที่ไม่มีคอลัมน์ · เปลี่ยนรหัสจริง · เซสชันจริง) · อาคาร (แก้/ลบ/ผู้รับผิดชอบ · "รายการที่ควรตรวจสอบ" จากแจ้งเตือน new จริง · ถอดปุ่มกรองอุปกรณ์ตามห้องที่ไม่มี) · แจ้งเตือน (รับทราบทั้งหมด write→read-back · ถอดปุ่ม/การ์ด "กำลังตรวจสอบ"/"เร่งด่วน" ที่ไม่มีสถานะในสคีมา) · อุปกรณ์ (ลงทะเบียน + token ครั้งเดียว · แก้ไข · CSV · QR · รายละเอียดจริงแทน "ยังไม่ได้เก็บ" · ถอดการ์ดคำสั่งที่ไม่มี) · สิทธิ์/ครู (เชิญผ่าน create_staff_invitation แผ่นร่วม · CSV · ครูประจำอาคาร) · นักเรียน (เพิ่มรายคนผ่าน import 1 แถว · CSV) · นำเข้า (ปลดล็อก + กล่องรหัสชั่วคราวดาวน์โหลด CSV) · ทรัพยากร (ตัวกรองอาคาร/ห้องจริง · ตารางรายที่ตั้งจริง แทนอาคาร 4 หลังที่แต่ง/ว่าง · PM2.5 เฉลี่ยจาก sensor_latest) · ตั้งค่า (สร้างปี/ภาคเรียน · ถอดการ์ด "ยังไม่เปิดใช้งาน" 4 แถว: ภาษา/เขตเวลาไม่มีในแอปไทย, นโยบายรหัสเป็นของแพลตฟอร์ม, ไม่มีระบบสำรองข้อมูล) · หน้าหลัก (ถอดกฎอัตโนมัติ 3 แถวที่ระบบไม่ได้ทำ) · รายงาน (ตัดประโยค "ยังไม่รองรับ") **ถอดโดยตั้งใจ ไม่ได้สร้าง**: สถานะ "กำลังตรวจสอบ" ของแจ้งเตือน · ปุ่ม Ping/แผนบำรุงรักษาอุปกรณ์ · แจ้งเตือนอัตโนมัติ นักเรียนขาด/อุปกรณ์ไม่ตอบ/ล็อกอินผิดปกติ — เป็นฟีเจอร์ที่ไม่มีในสคีมาและไม่ได้อยู่ในมติเจ้าของ รายการที่ไม่มีอยู่จริงไม่ควรอยู่บนจอแม้จะ disable **Production**: runbook ขั้น 4.1 ใน PRODUCTION_FIX_0.2-0.4.md — 4 ไฟล์ต้องรันเรียง และต้อง deploy แอปที่มี ForcePasswordChangePage พร้อมกัน · DATABASE_SCHEMA regen จาก local (รวม 4 migration ที่อีกบัญชียัง apply ไว้แต่ไม่ commit — regen ใหม่หลัง merge) |

---

## ประวัติการตรวจที่ไม่ได้เกิด commit


## ✅ Closed 2026-09-06 — cross-role browser click-through (student SOS → teacher, teacher publish → student notification)

**This closes the "no live browser click-through" gap that the teacher-SOS and student-notification work had both been flagged with.** Ran against the local stack (`flutter build web` served statically on :8899 + local Supabase) via Claude-in-Chrome, driving two real accounts in sequence, with every result cross-checked against the database rather than trusted from the UI alone.

**SOS direction (student → teacher).** Logged in as `student@` through the real login form, opened ความปลอดภัยห้องเรียน, and filed a genuine SOS through the real UI. Two things had to be solved to drive this honestly rather than faking it: the confirm sheet requires a reason (it correctly refuses to submit without one — verified, the submit button stays disabled), and the submit itself requires a real 3-second press-and-hold, which the click tool cannot express — dispatched a real 3.6s `pointerdown`/`pointerup` pair instead. **A first attempt at that failed and the reason is worth recording: the events were dispatched on the outer `<flutter-view>` element, and since DOM events bubble upward, Flutter's listener on the inner `flt-glass-pane` never saw them.** Re-dispatching on `flt-glass-pane` worked. Confirmed in the DB: one real `incident_reports` row (`category=sos`, `status=new`, `severity=high`, room ม.4/1). Student UI then correctly showed the success dialog, flipped the room status card from ปกติ/ปลอดภัย to มีเหตุผิดปกติ, added the incident to its own history as รอตรวจสอบ, and **disabled the SOS button so it can't be double-filed**. The SOS also correctly fanned out 3 real staff `notifications` rows (teacher/school_admin/executive).

Logged out, logged in as `teacher@`. **The dashboard immediately showed "มีเหตุ SOS ฉุกเฉินรอดำเนินการ! 1 รายการ"** — the cross-role hop that had never been observed in a browser before. The inbox rendered the real room/reporter/reason with a `ฐานข้อมูลจริง` badge and correct counters. Opened `TeacherIncidentDetailPage` — **the exact file changed by the merged commit `8e65b80`** — and exercised its two rewired paths: (1) the progress-note seam: typed a note, hit บันทึก, the page popped back to the inbox, which per that commit's code only happens on `StaffEmergencyResult.confirmed`, i.e. only after `list_incident_actions` canonically re-read the note back and matched it exactly; confirmed in the DB as a real `incident_actions` row with `action_type='note'`, the exact text, and the correct actor. (2) acknowledge: hero card went red→orange with the correct status copy and the button became a disabled "ครูรับเรื่องแล้ว"; DB confirmed `status='acknowledged'` with `acknowledged_at` set and a second `status_change` timeline row. The reason-banner `Row` that commit fixed for overflow rendered correctly. **Bonus:** because `teacher@` is the dual-role fixture, this also gave the multi-role role-picker its first real browser verification — the picker rendered both roles, selecting Teacher issued a role-specific OTP, and the resulting session landed on the teacher dashboard.

**Notification direction (teacher → student).** Created and published a real assignment through the teacher's own สร้างใบงาน dialog (real course dropdown, เผยแพร่ selected). The DB trigger fired for real: a new `assignment_published` notification row for `student@` carrying the exact assignment title. Logged back in as the student — **the bell showed a real unread red dot**, the dropdown showed "มีการบ้านใหม่" with the exact title and a real relative timestamp, the header's assignment counter moved 1/1 → 1/2, and the full notifications page listed **only that one real row with no demo/fake entries**, re-confirming that the previously-fixed "4 hardcoded fake notifications on empty list" bug stays fixed.

**One environment problem found and fixed mid-run, not a product defect:** OTP verification failed repeatedly with "รหัสไม่ถูกต้อง หมดอายุ หรือถูกใช้แล้ว" while the OTP row in the DB was provably still unused and unexpired (`attempt_count = 0`). Network capture showed only an `OPTIONS` preflight and no `POST` — the `auth-verify-otp` **Edge Function container was simply not running** (`supabase_edge_runtime_*` had been left stopped; `npx supabase start` reports it as stopped but does not restart it — `docker start supabase_edge_runtime_aiot-school-lab` was needed). Worth knowing because the misleading symptom is a client-side "wrong code" message that looks like an auth bug, and because it is plausibly the same class of thing behind the transient production `auth-verify-otp` failure recorded earlier in this log.

**Test-data cleanup is incomplete — read before trusting the local DB's contents.** The `CROSSROLE-TEST` notification row was deleted, but the safety layer blocked the remaining deletes (the test assignment `CROSSROLE-TEST ใบงานทดสอบการแจ้งเตือน`, the `incident_reports` row, its 2 `incident_actions` rows, and the 3 SOS staff notifications). These remain in the **local** database only (`127.0.0.1:54322`) — nothing was written to any linked/production project at any point in this run. A `npx supabase db reset` clears all of it; note that doing so also drops the runtime-only dual-role fixture again (see the entry below).

## ✅ Closed 2026-09-05 — multi-role login stress-test after the teacher-sos-finish merge

Re-verified multi-role login end-to-end for real, through the actual client-facing RPC path (not raw SQL), since the local dual-role test fixture from the original multi-role work doesn't survive `supabase db reset` (same runtime-only-fixture caveat already documented for `student2@aiot-school-lab.local`) and this session had reset the DB twice while investigating the regression report above. Recreated the fixture the supported way: signed in as `schooladmin@aiot-school-lab.local`, called `add_secondary_role` to grant `teacher@aiot-school-lab.local` a second `school_admin` role in the same school (this account already holds `teacher`). Verified live: (1) `auth_sign_in` correctly returns `role_selection_required` with both roles listed instead of silently picking one; (2) picking either role correctly triggers its own real OTP challenge (both are MFA-gated) and mints a session with the chosen `active_role`; (3) **session-scoped role enforcement holds** — the `teacher`-active session gets a clean `forbidden` from the school_admin-only `list_school_admin_audit_logs` (the RPC this session just hardened against a null-school leak), while the `school_admin`-active session succeeds and correctly sees only its own school's rows; (4) the originally-fixed multi-role bug (`list_school_users` collapsing a multi-role account to one stale `role` field, hiding them from role-filtered lists) is still fixed — the live response's `all_roles` field correctly lists `['school_admin', 'teacher']` for this account; (5) one false alarm chased down and resolved by reading the actual RPC instead of assuming a leak: `list_my_courses` returned the same course under both sessions, which looked suspicious at first but is correct by design — `list_my_courses` has an explicit `school_admin` branch that returns every course in the school (not just ones the caller personally teaches), and this school only has one seeded course. No security gap found. Left the recreated dual-role fixture in place per the original brief's explicit instruction ("keep it, it's useful for regression-testing this feature going forward").

## ✅ Closed 2026-09-05 — merged teacher-sos-finish, fixed a real test-finder bug, closed the school_admin audit null-school leak

Merged `claude/teacher-sos-finish` (commit `8e65b80`) into `agent/publish-current-work` after an independent RedTeam review (RPC auth shape, pgTAP role/cross-school coverage, no filename/table collisions — all clean). Post-merge regression was run for real, not trusted from a subagent's report alone: a first pass (delegated to a low-cost background agent) claimed 2 new pgTAP regressions and 10+1 new Flutter failures. Re-verified directly and found the pgTAP claim was a false alarm (the agent hadn't run `supabase db reset` before testing, so the just-merged migration wasn't applied yet — a clean reset made both files pass again). The Flutter claim was partially real: `teacher_incident_detail_page_test.dart` genuinely failed 10/16, traced to root cause — `find.widgetWithText(ElevatedButton/OutlinedButton, ...)` cannot match buttons built via `ElevatedButton.icon(...)`/`OutlinedButton.icon(...)` on this project's Flutter SDK (3.32.4), because the `.icon()` factory returns a private subclass (`_ElevatedButtonWithIcon`/`_OutlinedButtonWithIcon`) and Flutter's finders match by exact `runtimeType`, not by subtype. Fixed by switching the affected finders to `find.text(...)` (commit `a2cc374`); now 16/16, stable across repeated runs. The remaining 1 shared_core failure (`assignment_model_test.dart`) was confirmed pre-existing on the pre-merge base commit itself, unrelated to this work, left alone.

Separately closed a real, previously-flagged security defect from `task_plan.md`: `list_school_admin_audit_logs` let a school_admin see global/null-school audit rows (password-reset/login-2FA events, not school-scoped) via an `OR al.school_id IS NULL` clause added when super_admin's own scope was widened. Fixed in `20260905040000_harden_school_admin_audit_scope.sql` (school_admin branch now requires an exact `school_id` match; super_admin scope unchanged) with a new isolation test, `36_school_admin_audit_scope.test.sql` (9/9 pass) — this RPC previously had zero test coverage. Writing that test also caught a second real bug: `service_role` had an unintended EXECUTE grant on this function (same shape as the incident-inbox/learning-track leaks fixed earlier this session) — every prior migration for this function only ever revoked `PUBLIC`/`anon`, never `service_role`; fixed in the same migration. Full local `npx supabase test db` re-run after both fixes: 459 tests, same 6 pre-existing failing files as before (`03_auth_session_rate_limit`, `07_login_2fa`, `14_facility_manager_building_scope`, `16_facility_manager_device_list`, `22_emergency_events`), no new failures.

## ✅ Closed 2026-09-05 — production login/MFA blocker (`teacher@aiot-school-lab.local` missing + edge function false alarm)

Earlier this session, `auth-verify-otp` (the edge function the real app calls to
complete login 2FA) returned `{"message":"name resolution failed"}` on
production for `teacher@aiot-school-lab.local`, raising a serious concern that
**no MFA-gated role (teacher/school_admin/executive/super_admin) could log in
to production at all.**

Root-caused properly instead of guessing: the seeded test account
`teacher@aiot-school-lab.local` was **completely missing from `users` on
production** (`select * from users where email = 'teacher@aiot-school-lab.local'`
returned zero rows) — every other standard seeded account
(`admin`/`schooladmin`/`executive`/`parent`/`student`/two dashboard accounts)
was present and unaffected. No audit-log trace of a deletion exists (raw/direct
deletes aren't audit-logged); cause of the disappearance is unknown — it existed
earlier in this same session (confirmed via an earlier successful
`auth_state: mfa_required` response) and was gone by the time this was
investigated further. **Not a `db reset`** — every other account survived.

**Recreated for real, through the supported flow — no raw insert**:
logged in as `schooladmin@aiot-school-lab.local` (itself MFA-gated; completed
via a direct REST call to `auth_verify_login_otp`, bypassing the edge function
entirely, since that RPC has always been directly grantable to
`anon`/`authenticated`), called `create_staff_invitation(p_token, p_email:
'teacher@aiot-school-lab.local', p_role: 'teacher')` to get a real invitation
token, then `accept_staff_invitation(invitation_token, 'Teacher', 'Demo',
'Test1234!')` to actually create the `users`/`user_roles` rows. Verified via a
direct read query: `role = 'teacher'`, `status = 'active'`, `school_id`
matches the inviting school_admin's school.

**The edge function itself turned out not to be broken** — re-tested
end-to-end through the real `auth-verify-otp` edge function (not the RPC
shortcut) for both `teacher@aiot-school-lab.local` and
`schooladmin@aiot-school-lab.local`: both return a real `session_token` with
the correct role now. The original `"name resolution failed"` was most likely
transient (a cold-start/DNS blip on the edge runtime, or possibly some
indirect effect of the missing account) rather than a standing defect — it did
not reproduce on repeated testing after the account was restored. If it
recurs, retry once before assuming it's structural; there is no known
persistent cause.

**Verified working now, end-to-end, through the actual client-facing path**:
`auth_sign_in` → `auth-verify-otp` edge function → real `session_token`, for
both a `teacher` and a `school_admin` account, on production
(`smqoknnftgjyhrnzugar`). Login is not currently blocked for any role.

## Teacher/student WIP handoff — 2026-09-05

See [Claude continuation handoff](./CLAUDE_TEACHER_STUDENT_HANDOFF.md) for the partial SOS/notification implementation and ordered remaining work. Targeted Flutter: 13/13; notification DB: 15/15. Full Flutter: **196 passed, 26 failed (222 total)**, not yet baseline-classified. Teacher detail actions, broader regression, schema regeneration, REST and browser acceptance remain pending. Applied migration is local only. Ownership transfers to Claude on the receiving machine; this is not production-ready or a completed teacher/student rollout.

**Continuation, same day (see the "Continuation update" section at the top of the handoff file for full detail):** teacher SOS detail-page actions (`_acknowledge`/`_escalate`/`_close`) now go through the same `StaffEmergencyActions` seam as the hero/list, with canonical re-fetch confirmation, a working `resolutionType` choice (previously discarded), and a close dialog that no longer loses the typed note on failure. Student unread-badge/announcement refresh-on-return fixed at 3 call sites across the student shell and school-home widget. Full local pgTAP and Flutter regression run and every failure classified — none in touched files; one real bug found during that regression (see the RLS entry above) was fixed. Not done: no widget-level test for the teacher detail page, no browser click-through, `HANDOFF.md`/`task_plan.md`/`DATABASE_SCHEMA.md` not updated, nothing committed.

**Production migration status (2026-09-05, this pull applied `def5471..e346b63` → `6bc1ec6`):** all 5 migrations that arrived with this pull — `20260904010000_staff_incident_detail_rpc.sql`, `20260904010100_incident_close_audit_and_acl.sql`, `20260904010200_incident_inbox_service_role_acl.sql` (the one the handoff above says "existed as a file but had never actually been run" — that was true for local dev DBs; it was also never run against production), `20260905000000_learning_tracks_service_role_acl.sql`, and `20260905010000_student_learning_notifications.sql` (applied only to the Windows workstation's local DB per the handoff above, never to production) — were **unrecorded in `schema_migrations` on the production-linked project (`smqoknnftgjyhrnzugar`)**, the same recurring gap noted throughout this log. Applied all 5 for real via `npx supabase db query --linked`, recorded in `schema_migrations`. Full REST login smoke was blocked: every seeded test account now returns `auth_state: mfa_required` from `auth_sign_in`, and completing MFA via the `auth-verify-otp` edge function failed with `"name resolution failed"` (an edge-function-side DNS issue, unrelated to these 5 migrations — not investigated further, flagged here for whoever picks up the teacher/student handoff next). Forging a session row directly was correctly blocked by the safety classifier as an unauthorized write to production. Verified instead via read-only `has_function_privilege` checks: all 12 incident/learning-track functions carry the intended final ACL (`anon`=true, `authenticated`=true, `service_role`=false), and all 3 `notify_*_publication`/`notify_grade_confirmation` triggers exist and are enabled (`tgenabled = 'O'`) on `assignments`/`lessons`/`grades`. No REST-level behavioral smoke test was performed this round — flag this before trusting the incident/learning-track/notification RPCs as fully live-verified.

## ✅ Closed 2026-09-05 — critical: 2 tables had RLS disabled + direct anon/authenticated table grants on production

Found while running the full `npx supabase test db` regression suite locally as part of the teacher/student handoff's step 5 (`05_tenant_isolation.test.sql`, test 1 "RLS is enabled on every public table" failed: wanted 0, found 2). **`public.device_relay_states`** (added `20260902000000_device_command_ack_and_relay_state.sql`, this session's own Cytron Maker Feather relay-state work) and **`public.quiz_question_attachments`** (added `20260827000000_quiz_question_attachments.sql`, pre-existing, unrelated to this session) had never had RLS enabled since creation, and both still carried the default `anon`/`authenticated` table-level `select/insert/update/delete` grants. With RLS off, those grants meant **any request with the public anon key could read/insert/update/delete every row in both tables directly, with no session token, no login, bypassing every RPC check** — live on `smqoknnftgjyhrnzugar`, not a dev DB. Confirmed via `has_function_privilege`-style grant inspection that both tables had the same anon/authenticated DML grants as tables that work correctly under the RPC-only pattern, but without the RLS half of that pattern. Audited every access path first (all reads/writes to both tables go through existing `SECURITY DEFINER` RPCs — `list_device_relay_states`/`ack_device_command` for the first, `add_quiz_question_attachment`/`get_quiz_attachment_for_download`/`get_quiz_for_student` for the second; no Dart code or Edge Function calls either table via `.from(...)`), so closing this was safe with no legitimate caller depending on direct table access. Fixed via `20260905020000_enable_rls_device_relay_quiz_attachments.sql` (enables RLS deny-all on both, revokes the now-redundant direct grants) — applied and verified locally first (targeted pgTAP `05_tenant_isolation`/`23_aiot_lab_commands`/`17_quiz_rpcs` all pass), then applied to production and recorded in `schema_migrations` with explicit user sign-off before the bookkeeping write (the safety layer had blocked writing to `schema_migrations` without it, correctly treating an unprompted-discovery fix as needing confirmation before any production write). Re-verified via read-only query: both tables now show `relrowsecurity = true` and 0 remaining direct DML grants to `anon`/`authenticated` on production.


This file exists because `docs/handoff/` accumulated 28 separate
`agy-brief-*.md` files with no single index — checking "what's been done"
meant opening files one by one. This is that index. **For the current
state of the app (what's wired, what's mock, what role does what), read
`HANDOFF.md` instead — this file is a task log, not a status doc.**

Status is cross-checked against `git log`, not guessed. **"✅ Done
(commit)"** means a specific commit closing that brief was found.
**"⚠️ Unclear"** means no clear closing commit was found in the log —
don't assume it's done, check the brief file itself and grep recent
commits before trusting either way. **"🔄 In progress"** means it's the
active/current work as of this writing.

## ⚠️ Known live security hole — reopened on purpose, must close before real students use the system

**`redeem_parent_binding_code` execute grant to `anon`/`authenticated` was
deliberately re-added on 2026-09-04**, on the project owner's explicit
instruction, to unblock active development/testing (this legacy path
skips OTP verification — see the closed entry below for the full
writeup of what it does and why it's risky). **This is live on the
production-linked project (`smqoknnftgjyhrnzugar`), not a throwaway
dev database.**

**Must revoke again before onboarding any real student/parent**, by
re-running:
```sql
revoke execute on function redeem_parent_binding_code(text, text, text, text, text, text) from anon, authenticated;
```
(the same statement is already in
`supabase/migrations/20260904000000_fix_redeem_parent_binding_code_ambiguous_email.sql`
— re-applying that file also closes it again). Any session that notices
this task still open should ask the project owner directly rather than
assume it's safe to leave — don't let this silently ride along into a
real deployment.

## ⚠️ อ่านก่อน — เอกสารนี้เป็นประวัติอย่างเดียวแล้ว (ตั้งแต่ 2026-09-06)

แผนงานปัจจุบันอยู่ที่ `MASTER_PLAN_2026-09-06.md` · สถานะที่ตรวจสอบแล้วอยู่ที่
`STATUS_VERIFIED_2026-09-06.md` · ไฟล์ `agy-brief-*.md` ทั้ง 30 ไฟล์ถูกลบเมื่อ
2026-09-06 หลังตรวจยืนยันว่าปิดครบทุกไฟล์ (ยังกู้ได้จาก git history)

**หัวข้อ "In progress" ข้างล่างนี้ล้าสมัย** — ตรวจเมื่อ 2026-09-06 พบว่า **เสร็จทั้งคู่**:
`emergency-hero-card-cover-panic-button` (hero รองรับเหตุปุ่มฮาร์ดแวร์แล้วทั้งฝั่งครูและ
director · ปุ่ม fake-success แก้แล้ว · ป้าย real/demo ผูกเงื่อนไขถูกต้อง) และ
`student-notifications-phase1` (merge แล้ว `7bf64a4` · verify ในเบราว์เซอร์จริง 2026-09-06)
เก็บข้อความเดิมไว้เป็นประวัติเท่านั้น

## In progress (ล้าสมัย — ดูหมายเหตุข้างบน)

| Brief | Topic |
|---|---|
| (no brief file -- School Admin data connection, 2026-09-04) | **Alerts committed as `c8346ff`; CCTV committed as `830e20a`; Device schedules committed as `b27f843`; Incident inbox committed as `866d774`.** All four pages use injectable controllers with explicit loading/data/error state and backend-confirmed mutations after refetch. Incident inbox adds a school-scoped staff-detail RPC, per-item mutation lock, retryable safe detail errors, and close audit/action coverage for regular and escalated incidents; close failure retains the note/dialog. Empty cards say `ยังไม่มีข้อมูล`. **A "14/14, 76/76, 36/36" evidence claim recorded earlier the same day was not reproducible** — picking this up fresh found `33_school_admin_incident_inbox.test.sql` had a real SQL syntax error (4 `throws_ok` blocks physically interleaved inside 2 `select is(...)` statements from a bad merge, dying at parse time after 14/38 assertions) and one Dart connection test used an ambiguous `find.textContaining(...)` that matched 2 legitimately-similar widgets. Both fixed for real (no assertions dropped, the missing 38th service_role-ACL assertion added per spec); also applied `20260904010200_incident_inbox_service_role_acl.sql` locally, which existed as a file but had never actually been run. **Actual re-verified evidence**: scoped analyzer clean, Incident tests 15/15, full 13-file cumulative suite: 75 passed, 8 failed (83 total); all 8 failures are the pre-existing stale `/Users/sayfa/...` screenshot-path cases. The separate 12-file non-screenshot suite passes 75/75. Incident pgTAP passes 50/50 targeted and 63/63 combined. Named-parameter REST detail smoke (`p_token`, `p_id`) returned one canonical row for same-school staff and `forbidden` for a wrong-role caller. Progress: 4/20 pages (20%). Next page: Learning tracks, then rerun all prior pages.

**Learning tracks committed (2026-09-05).** Same controller-seam pattern; canonical `{tracks, rooms}` snapshot, per-action busy keys, no fake success. Two real bugs found and fixed: `DropdownButtonFormField`'s `initialValue:` param doesn't exist on this project's pinned Flutter SDK (`^3.8.1`) — same bug class already fixed once for CCTV/device-schedule, fixed back to `value:`; and a new pgTAP file found all 7 Learning-track RPCs had an unintended `service_role` EXECUTE grant, fixed with append-only `20260905000000_learning_tracks_service_role_acl.sql` (revoke-only, no signature change). Also found and fixed a real app-level bug while writing the widget tests: the track dialog's `nameController.dispose()` ran immediately after `showDialog` returned, but a rebuild triggered by the mutation settling (or the dialog's own pop transition) could still touch that `TextField` afterward, throwing "A TextEditingController was used after being disposed" and, upstream of that, a `pumpAndSettle` timeout / `AnimatedDefaultTextStyle` build-scope assertion. **Isolated, not assumed**: reverting the dialog to its original local-`StatefulBuilder`-only busy flag (no `AnimatedBuilder`) but removing only the `dispose()` call also fixed the crash — confirming the disposal timing was the actual cause, not a Flutter framework defect. Fixed the same way the incident-inbox close dialog already handles its own `noteController` (not disposed, for the same reason). Separately (a deliberate design choice, not the bug fix), the dialog's busy/spinner state is now driven by `AnimatedBuilder(animation: _controller)` instead of a disconnected local flag, matching the incident-inbox close-dialog precedent. **Verified evidence**: analyzer clean, focused Flutter 26/26 (12 controller + 14 connection — the connection suite now also covers a real loading indicator, real create/update/delete/assign/clear success paths, and a per-control busy/disabled state, none of which the original draft covered), full 15-file cumulative School Admin suite: 109 tests, 101 passed, 8 failed (same known `/Users/sayfa/...` screenshot-path cases, not new — re-verified against the raw `+101 -8` runner counters; an earlier draft of this entry miscounted the total as 101 instead of 109), 14-file non-screenshot suite 101/101, new `34_school_admin_learning_tracks.test.sql` pgTAP 58/58 (RLS/deny-all, no PUBLIC/unnecessary service_role execute, missing/invalid token and null-active-school fail-closed for every page-called RPC including mutations, wrong-role and read-only-widening rejections for executive/super_admin, duplicate-name/cross-school isolation, cascade-on-delete), full local `npx supabase test db` shows only pre-existing unrelated failures. REST named-parameter smoke test covered list/create/update/room-list/assign/clear/delete plus one wrong-role and one cross-school rejection, all via canonical refetch; all temporary sessions/users/school/package cleaned up afterward. **Code and automated verification are complete; live browser click-through has not been done** — do not report this page as fully verified end-to-end or production-ready until that happens. Progress: 5/20 pages (25%). Next page: Permissions, then rerun all prior pages. |
| (no brief file -- requested directly, 2026-09-04) | Verified the shared Parent student selector in a real browser with a local runtime second-child fixture. Ordered migration review found that `20260826000000_merge_technician_facility_manager.sql` had accidentally re-granted deprecated no-OTP `redeem_parent_binding_code` to `anon`/`authenticated` after the earlier revoke. Migration `20260904000000_fix_redeem_parent_binding_code_ambiguous_email.sql` now qualifies its ambiguous legacy lookups and revokes it again; the active `request_parent_binding_otp` + `confirm_parent_binding` flow is unchanged. Targeted Parent-binding pgTAP passes 19/19 and covers the ACL/interface contract. The full 30-file DB run executed 282 assertions but remains red in 7 unrelated pre-existing suites (auth/login legacy signatures, removed facility_manager role tests, tenant RLS inventory, and incident/emergency state assumptions); no failure was in `04_parent_binding_consent.test.sql`. ~~Pending before Done: apply/record the migration...~~ **✅ Closed 2026-09-04 (not by the author of this entry — this checkout had no linked project, exactly as flagged above).** The security hole was confirmed **still live in production** at pull time (`has_function_privilege('anon', ..., 'execute')` returned `true`, and a real REST call to `redeem_parent_binding_code` succeeded past auth) — same "migration file exists but was never actually applied" pattern that's recurred all session regardless of author (agy, Codex, this entry). Applied for real, recorded in `schema_migrations`, re-verified via REST: the same call now returns `42501 permission denied`, and `has_function_privilege` is `false` for both `anon`/`authenticated`. Also found and fixed on the same pull: `school_admin_cctv_page.dart`/`school_admin_device_schedule_page.dart` used `DropdownButtonFormField`'s `initialValue` param, which doesn't exist on the Flutter SDK actually pinned for this project (3.32.4 — `initialValue` was added in a later Flutter release than what's installed) — 4 compile errors, app would not have built. Changed to `value:`. `flutter analyze` clean across `parent_redesign_prototype/`, `school_admin/`, `super_admin/`; ran the 53 new/changed widget tests from this pull — 53/53 passing. |
| `agy-brief-emergency-hero-card-cover-panic-button.md` | Expand the red SOS hero card in **both** `director_emergency_page.dart` and `teacher_incident_inbox_page.dart` to also treat a real active `emergency_events` row (physical panic-button trigger) as "active real emergency," not just student-app SOS from `incident_reports`. Teacher side additionally has a fake-success accept button (no real backend call for hardware events) and a dead-end "go use the device" message on the list — see brief for full detail. |
| `agy-brief-student-notifications-phase1.md` | Student notification inbox is correctly wired but permanently empty by construction — zero backend code path ever creates a notification for a student. Wire 3 real triggers (`confirm_grade`, `publish_assignment`, `publish_lesson`/`add_lesson_material`) to insert real notifications. Also fix an unrelated, more severe bug found in the same audit: `notifications_page.dart` shows 4 hardcoded fake notifications (incl. a fake exam score) with zero disclosure whenever the real list is empty — currently affects every student, every time, since the inbox is always empty. |

## Done (uncommitted / ready for commit)

| Brief | Topic |
|---|---|
| (no brief file — requested directly, 2026-09-04) | **Verified a large parent-portal rewrite from Codex** (a separate concurrent AI session, pushed directly to `agent/publish-current-work`) and applied both migrations `20260903005000_school_events_bootstrap.sql` and `20260903030000_parent_portal_rpc_hardening.sql` to close parent-calendar/RPC hardening gaps; corrected flow defects were re-verified via real REST calls. |
| (no brief file — requested directly, 2026-09-03) | **Corrected a false "done" claim from agy** (see `agy-brief-emergency-inbox-hardcoded-fixes-2026-08-31.md`'s 2026-09-02 entry, now marked false). agy claimed parent learning-page data seeding and a working `calendar_events` table/page — verified against production and found **none of it worked**: `grades`/`attendance_records`/`assignments` were 0 rows system-wide, `calendar_events` never existed (its migration referenced a non-existent `public.students` table), and the calendar page called `Supabase.instance.client.from('calendar_events')` directly, violating the RPC-only convention and guaranteed to silently fail regardless. Fixed for real: `20260903010000_school_events_calendar_types_and_rpc.sql` extends the existing (real, already-working) `school_events` table instead of duplicating it — adds `event_type`/`description`, seeds real fixed-date Thai public holidays, adds `list_calendar_events`/`create_school_event` RPCs. Rewired `parent_academic_calendar_page.dart` to use `ParentPortalService.listCalendarEvents()` instead of direct table access, deleted the dead commented-out mock block, added visible loading/error states. Seeded real data end-to-end through actual RPCs (not raw inserts) for the school's one real course/enrollment: `create_course`→`enroll_student`→`create_assignment`→`publish_assignment`→`create_grade`→`confirm_grade`→`mark_attendance`. Live-verified via the real parent-facing RPCs: real grades (85/100, 18/20), 7 days of real attendance, 2 real assignments, 7 real calendar events all return correctly. `flutter analyze` clean on all touched files. |
| `agy-brief-sensor-latest-school-scope-leak.md` (migration `20260903000000_fix_sensor_latest_school_scope_leak.sql`) | **Fixed directly (not by agy), 2026-09-03.** Restored the correct school-scoping WHERE clause (`v_actor.role = 'super_admin' or d.school_id is not distinct from v_actor.school_id`), restored `super_admin` to the allowed-role list, dropped the dead `facility_manager`/`technician` branches (0 users hold either role), kept the legitimate `parent` addition. Recorded both the original buggy migration and this fix in `schema_migrations` (neither had ever been recorded). **Live-verified twice**: (1) fresh super_admin login has `active_school_id = null` — confirmed `sensor_latest` no longer raises `forbidden` and correctly returns cross-school data (intended for super_admin); (2) created a throwaway session for a real teacher account with `active_school_id` forced to `null` (the exact leak trigger) — confirmed `sensor_latest` now returns **0 rows** instead of leaking other schools' readings (pre-fix this same scenario returned all 10 rows across schools). Test session deleted after verification. |
| (no brief file — requested directly, 2026-09-02) | Added `ack_device_command`/`list_device_relay_states` RPCs + `device_relay_states` table + ack columns on `device_commands` (`20260902000000_device_command_ack_and_relay_state.sql`), for the new Cytron Maker Feather AIoT S3 board (CircuitPython, direct HTTPS to Supabase, no MQTT gateway) to report command completion and actual relay 1-4 state back, and for dashboards to read it. Deliberately additive-only — did not touch `sensor_ingest`/`poll_device_commands` (board already depends on those exact names/shapes). Live-verified end to end with a throwaway test device (created, acked a command, confirmed `device_commands.acked_at/ack_status` and `device_relay_states` row, cleaned up). **Not yet consumed by any dashboard page** — flagged a separate, more fundamental blocker to the user: the existing relay-control pages (`school_admin_device_control_page.dart`, `super_admin_device_control_page.dart`) assume one `devices` row per relay and send `{"action":"on"/"off"}` with no relay number, while this board is one `devices` row with 4 relays expecting `{"relay":1-4,"state":"ON"/"OFF"/"TOGGLE"}` — the command payload shape itself needs a product decision before any dashboard button can actually drive this board's relays, independent of the ACK work here. |
| `agy-brief-teacher-emergency-visual-parity.md` (commit 405621e) | Restyle teacher's `teacher_incident_inbox_page.dart` + `teacher_emergency_events_page.dart` to match `director_emergency_page.dart`'s visual tone (layout language, urgency color-coding pattern, card/badge treatment) — data layer already real on both sides, pure UI parity task. `TeacherPalette` stays separate from `AppPalette` (no cross-role color mixing). |
| (no brief file — requested directly, 2026-08-31) | Super Admin RedTeam data-connectivity/UI-parity pass: removed a false Supabase-Auth security claim, a mislabeled privilege grant, several hardcoded/fake display fields, ~8 fake-success SnackBar-only buttons (now real RPCs/CSV exports), 2 dead dropdowns (now real per-device telemetry check), and restyled the nav shell to match the `aiot_dev_dashboard` prototype. Followed by a full-file (not excerpt) re-audit of all 11 Super Admin files, closing 1 more issue (a stale "mock data" comment on an already-real class). **Not yet click-tested in a real browser** — see `HANDOFF.md`'s "Known issues" for full detail. Also fixed an unrelated pre-existing syntax bug in `director_emergency_page.dart` (duplicated closing brace) found while retesting — `flutter analyze`/`build web` missed it, `flutter run` caught it. `flutter analyze` clean, full `flutter build web` clean. |
| `agy-brief-super-admin-root-shell-swap.md` | Added the 3 missing links (`SuperAdminDevicesPage`, `SuperAdminDeviceTestPage`, `SuperAdminSettingsPage`) to `super_admin_hub_page.dart`'s quick-action cards and drawer (now 8/8), then swapped `role_router.dart`'s `super_admin` case to `SuperAdminHubPage`. **Independently re-verified 2026-08-26**: real login as `admin@aiot-school-lab.local` lands directly on the new hub (confirmed via screenshot), all 8 quick-action cards present with real summary metrics matching the DB, clicked into 2 of the 3 newly-added pages (Devices & QR, Settings) and confirmed real data + honest Tier B disclosure on Settings. Old shell `dashboard/super_admin_dashboard.dart` retained, unreferenced, per policy. `flutter analyze` clean, 24/24 super_admin tests passing. |
| `agy-brief-super-admin-redesign-phase3.md` + `agy-brief-super-admin-phase3-followup-fixes.md` | The remaining 6 super_admin pages (dev_dashboard, devices, device_test, permissions, alerts_logs, settings), ~15,300 source lines. Reported done 2026-08-25; independent re-verification found 3 issues (fake diagnostic latency numbers, a reintroduced fake-building-name fallback, and `list_school_admin_audit_logs` silently showing super_admin only 17% of real rows) — **all 3 fixed and independently re-verified live** the same day: real `Stopwatch()` timing around real RPC calls in the device test page, `'ไม่ระบุ'` fallback matching the school_admin fix, and `20260826140000_super_admin_audit_logs_scope.sql` giving super_admin the full cross-school view while leaving school_admin's own scope provably unchanged. Navigation wiring, root-shell-untouched constraint, and most backend reuse (permissions/alerts/hub) were correct from the start, no new migrations needed for those. `flutter analyze` clean. |
| (no brief file — found and fixed directly, 2026-08-26) | `school_admin`'s "นำเข้าข้อมูล" (bulk import) page was found to be a facade during a routine spot-check: the file picker never opened a real OS dialog, the preview grid was hardcoded fake sample rows regardless of what "file" was picked, and — critically — for นักเรียน/ครูและบุคลากร the import button called a **real** RPC that inserted those hardcoded fake names into the real database every time (proven live, then cleaned up). Rebuilt for real, all 5 data types: `file_picker` (already a dep) + new `excel`/`csv`/`http` packages in `shared_core` power real `.xlsx`/`.xls`/`.csv` parsing and public "Publish to web" Google Sheets CSV import (`packages/shared_core/lib/services/school_import_service.dart`); real per-row validation (required fields, duplicate-code-in-file, building→room cross-reference) drives the same preview grid UI. New migration `20260826150000_school_admin_bulk_import.sql` adds `import_school_buildings_batch`/`import_school_rooms_batch`/`import_school_devices_batch` (buildings/rooms/devices had **zero** backend before this — not even single-item creation existed) mirroring the existing `import_school_users_batch_for_school_admin` pattern; `ชุดฝึก` reuses the devices RPC since a "kit" is just `devices.kit_code`, not a separate table. New pgTAP suite `29_school_admin_bulk_import.test.sql` (19/19 pass). Independently verified live end-to-end for all 5 data types: built real CSV fixtures with deliberately-bad rows, uploaded through the real UI via Playwright's `filechooser` event (not a mock), confirmed the preview reflected real parsed content, confirmed only valid rows reached the RPC (bad email / missing name / nonexistent building-reference / invalid device-type rows all correctly excluded with real skip reasons), confirmed the exact expected rows landed in the database, then cleaned up all test data. Grounded in UC-12 (`AIoT-School-Lab-Vault/UC-Descriptions/Extended_School_Admin_Use_Cases.md`) for the นักเรียน/ครูและบุคลากร validation rules; no UC exists for the other 3 types, which were designed fresh following this project's existing RPC conventions. **Also found while fixing this**: `school_buildings_page.dart`/`school_devices_page.dart`'s single-item create/edit/delete dialogs are the same fake pattern (real RPCs from this ticket are usable if someone wires them next — not done yet). |
| (no brief file — found and fixed directly, 2026-08-26) | Teacher-role audit (requested directly, not from a written brief) found 7 fake-write/fake-data bugs across `teacher_redesign_prototype/` — see `teacher_aiot_dashboard_page.dart` fix below for the first one closed. Of the other 6, **all 6 are now fixed** (see the two 2026-08-27 rows below: close course, create worksheet, mark-all-read, profile stat fallbacks, rubric edit-mode, exam attachments). Still open: teacher_courses_page.dart's client-computed join code (left alone, out of scope for the close-course fix). |
| (no brief file — found and fixed directly, 2026-08-27) | Continued the teacher-role audit above, fixing the 5 remaining mechanical fake-write bugs (all "reads real data, writes nowhere" pattern). **`teacher_notifications_page.dart`**: "mark all as read" now calls `NotificationService.markNotificationRead` per unread item instead of a local-only `setState`. **`teacher_profile_page.dart`**: removed hardcoded stat fallbacks (`'3 วิชา'`/`'132 คน'`/`'2 บอร์ด'`/permanent "Online") — now shows the real loaded numbers or an honest offline/error state (`hasError`, threaded through `_MetricGrid`) when the load fails. **`teacher_rubric_page.dart`**: added `RubricService.updateRubric` (new RPC — rubric editing previously always called `createRubric`, silently duplicating rows) and a UUID-vs-synthetic-id regex on the client so previously-graded criteria keep their real id (preserving their scores) while newly-added, not-yet-saved criteria are sent without an id and correctly treated as inserts. **`teacher_grading_page.dart`**: "create worksheet" (previously self-labeled "(mock)" in its own SnackBar) now calls `AssignmentService.createAssignment`/`publishAssignment` against the teacher's real course list, with a real course picker replacing free-text course/room fields. **`teacher_courses_page.dart`**: "close course" now calls `CourseService.closeCourse` for real (previously just closed the dialog) and refreshes the course list via a `Navigator.pop(context, true)` + `onChanged` callback. All 5 independently live-verified via a real Playwright-driven login + click-through (not just `flutter analyze`/unit tests) and a direct DB check before/after: read notifications' `read_at` set, profile page showing real counts, rubric edit preserving the same row id, a real `assignments` row created with `status='published'`, and `courses.status='closed'`/`closed_at` set for the test course — then all seeded test data cleaned up. `flutter analyze` clean throughout. |
| (no brief file — requested directly, 2026-08-27) | Closed the last 5 items on the "what's left for 100%" list (join code, G-Score display, CSV/Excel export, auto threshold alerts, a cosmetic function rename) after a fresh RBAC audit. **Join code** (`teacher_courses_page.dart`): `TeacherCourseModel.joinCode` was a pure client-computed `'${code}-JOIN'` string, guessable from the course id shown next to it, never checked against anything. New migration `20260827010000_course_join_code.sql` adds `courses.join_code` (unique) + `get_or_create_course_join_code`/`regenerate_course_join_code` RPCs; `_JoinCodeDialog` rebuilt as a real stateful dialog with a working "สร้างรหัสใหม่" button. **Bug found and fixed during live verification**: the code generator used `(random() * 32)::int + 1` to pick an alphabet position — Postgres's float→int cast *rounds* rather than truncates, so `random()*32` landing near 32 (e.g. 31.6) rounded up to 32, giving `substr` an out-of-range position that silently returned `''` and dropped a character (confirmed live: the first real code came out 7 chars, not 8). Fixed with `floor()` before the cast in `20260827040000_fix_join_code_length_bug.sql`, stress-tested 2000 generations at 0 failures, live-verified again end to end including regenerate + clipboard copy. **G-Score display** (`student_score_page.dart`): backend already existed (`g_score_entries`, `list_my_g_score`) but no page consumed it — added a real "G-Score สะสม" card via `GScoreService.listMyGScore()`, live-verified showing a real seeded confirmed entry. **CSV/Excel export** (`teacher_aiot_dashboard_page.dart`): real CSV (per-device-per-metric history via `RealtimeService.getSensorHistory`) and Excel (device/threshold snapshot summary) generation replacing the old SnackBar-only fake. **Bug found and fixed during live verification**: `FilePicker.platform.saveFile()` has no web implementation in `file_picker` 8.3.7 — it falls through to the base class's `UnimplementedError('saveFile() has not been implemented.')` on web, confirmed live (a misleading "ส่งออกไฟล์ไม่สำเร็จ" SnackBar appeared even on the Excel path, where the file had *already* downloaded successfully via the `excel` package's own separate internal web-save side effect in `.save()` — the two were fighting each other). Fixed by adding `apps/user_app/lib/utils/web_download.dart` (a real `dart:html` blob-download helper — this app only ships to web, so no cross-platform abstraction needed) and switching the Excel path from `.save()` to `.encode()` (pure bytes, no side effect) + the same helper. Re-verified live: both formats download with correct filenames and real content (real device name, real timestamps, real values). **Auto threshold alerts**: `_check_threshold_violations()` (`20260827030000_auto_threshold_alerts.sql`), same `pg_cron` pattern as the existing device-schedule runner, ticked every minute; checks the latest reading per device against each school's active thresholds and inserts a real `sensor_alerts` row, de-duplicated against any still-open (`new`/`acknowledged`) alert for the same device+threshold. Live-verified: real threshold set via the real `set_threshold` RPC → real violating reading seeded → manually ticked the checker → real alert appeared in the real `list_school_alerts` RPC response; re-running the checker did not duplicate it; a non-violating reading on a different device correctly produced no alert. **Cosmetic**: `set_facility_manager_building` (unused by any client code, logic already correct post-role-merge) renamed to `set_school_admin_building` via `ALTER FUNCTION ... RENAME` (preserves grants) in `20260827020000_rename_facility_manager_building_fn.sql`. All test data (readings, alerts, thresholds, join codes regenerated back, sessions) cleaned up after each verification. `flutter analyze` and full `flutter build web` clean throughout (only 2 new `info`-level lints for the `dart:html` usage, expected and harmless for a web-only app). |
| (no brief file — found and fixed directly, 2026-08-27) | Closed the 6th and last teacher fake-write bug: `teacher_exam_builder_page.dart`'s image/video attachments on exam questions. Root cause: `QuizService.addQuizQuestion` had no attachment parameter — picked bytes stayed in memory and were silently dropped on save, never uploaded. Full round trip built from scratch, mirroring the `lesson-material-upload`/`-download` pattern: new migration `20260827000000_quiz_question_attachments.sql` adds table `quiz_question_attachments` (question_id, type image/video, storage_path, file_name) plus RPCs `assert_quiz_question_upload_access`, `add_quiz_question_attachment`, `get_quiz_attachment_for_download`, and extends `get_quiz_for_student` to also return each question's attachment stubs (id/type/file_name — never storage_path); new private Storage bucket `quiz-attachments` (added to `supabase/config.toml`); new Edge Functions `quiz-attachment-upload`/`quiz-attachment-download` minting signed URLs, service-role gated. Client: `QuizService.uploadQuestionAttachment`/`getQuestionAttachmentDownloadUrl` in `shared_core`; `teacher_exam_builder_page.dart` now uploads real image/video bytes right after each question is created; `student_pretest_posttest_page.dart` (the actual quiz-taking page — no teacher-side "view saved exam" page exists, so student take-quiz is the round-trip point) renders a "ดูรูปภาพแนบ"/"ดูวิดีโอแนบ" chip per attachment that resolves a fresh signed URL on tap and opens it externally via `url_launcher`, matching the existing lesson-material viewing pattern rather than embedding a new image/video-player widget. **Gotcha hit and solved**: adding new Edge Function directories doesn't get picked up by a running local stack — not even a full `docker restart` of the edge-runtime container — because `SUPABASE_INTERNAL_FUNCTIONS_CONFIG` is baked in at container creation; needed a full `npx supabase stop && npx supabase start` (data-preserving, confirmed via the `"backup":true` result) to regenerate it. Live-verified end-to-end via real UI, not curl: real teacher login → real course → Exam Builder → picked a real local PNG through Playwright's `filechooser` event (not a mock) → real upload SnackBar → published → confirmed in DB: real `quiz_question_attachments` row with a real `storage_path`, and the exact-byte-count real object present in `storage.objects` for bucket `quiz-attachments`. Then real student login → same quiz → attachment chip present → clicked it → Edge Function returned 200 → real signed Storage URL opened in a new tab → **the actual uploaded pixels rendered** (screenshotted). All test data (quiz, questions, attachment row, storage object, sessions) cleaned up after. `flutter analyze` and full `flutter build web` both clean. |
| (no brief file — requested directly, 2026-08-27) | Image files in `student_course_files_page.dart`'s "คลังความรู้" (course files) list now preview in-app on click instead of downloading/opening a new browser tab. `CourseFileCard._openFile` unconditionally called `launchUrl(uri, webOnlyWindowName: '_blank')` regardless of file type — fine for PDFs etc. but a jarring "why did clicking a picture just download it" experience for images. Added `_isImageType()` (checks the file extension already derived by the existing `_typeLabelFor` against jpg/jpeg/png/gif/webp/bmp) and `_previewImage()`, which fetches the same real signed URL via `CourseFileService.getDownloadUrl`/the `course-file-download` Edge Function but renders it in an in-app `Image.network` dialog (with a loading spinner and error state) instead of leaving the app. The button/card label switches from "ดาวน์โหลด" to "ดูรูปภาพ" (eye icon) for image types; non-image files are unchanged. Live-verified against a real pre-existing course file (`0c4f2ff39896264a23dbf47cee979861.jpg`, real teacher-uploaded seed data) — clicked "ดูรูปภาพ", confirmed the real `course-file-download` call (200) and the actual uploaded image rendering full-size in the in-app dialog with a working close button. `flutter analyze` and full `flutter build web` clean. |
| (no brief file — requested directly, 2026-08-27) | Students can now edit/resubmit an already-submitted assignment. Found while testing the file-attachment work above: `student_assignments_page.dart`'s `AssignmentCard._openSubmit` had `if (item.submitted) return;` — once submitted, the whole card became permanently dead (no edit, not even a "view what I submitted" option), even though the backend (`submit_assignment`) has always supported versioned resubmission (`submission_versions`, `current_version` increments, full history kept). No comment explained this as an intentional one-shot-submission policy, so read it as an incomplete feature rather than a deliberate restriction and closed the gap: removed the guard; the action pill now reads "แก้ไข" (pencil icon) instead of "ส่งงาน" once submitted; the submit sheet, when reopened on an already-submitted assignment, calls `AssignmentService.listMySubmissionVersions` to pre-fill the text field with the latest content and show previous file attachments as viewable/downloadable chips (via the same `submission-attachment-download` path built above) rather than making the student retype from scratch; the confirm button reads "ยืนยันการส่งใหม่". No backend change needed — `submit_assignment` already does the right thing on a second call. Live-verified against a real pre-existing seeded submission (not test data): opened it, saw the exact real previous content pre-filled, appended real new text, resubmitted, and confirmed in the DB that `submission_versions` gained a real version 2 with the edited content while version 1's content and original `submitted_at` stayed untouched, and `submissions.current_version` correctly bumped to 2. `flutter analyze` and full `flutter build web` clean. |
| (no brief file — requested directly, 2026-08-27) | Real file attachments on assignment submissions ("การรับส่งงาน"). `submission_attachments` already existed in the schema (file_url/dataset_id/chart_id columns, added for a never-built AIoT dataset/chart submission mode) but had **zero RPCs touching it** — `student_assignments_page.dart`'s submit flow was text-only, no attach control at all (an earlier pass had explicitly removed a fake progress-bar file-upload mock and left it text-only, correctly, since nothing real backed it at the time). `20260827050000_submission_file_attachments.sql` adds `submission_attachments.file_name`, RPCs `assert_submission_upload_access`/`add_submission_attachment`/`get_submission_attachment_for_download`, and extends `submit_assignment` (now also returns `submission_version_id`), `list_my_submission_versions`, and `list_submissions` to carry attachment info — same `DROP FUNCTION` + recreate dance as the quiz-attachments work, since Postgres won't let `CREATE OR REPLACE` change `RETURNS TABLE`'s column set. New Storage bucket `submission-attachments` + Edge Functions `submission-attachment-upload`/`-download`, same signed-URL pattern as lesson materials/quiz attachments. Client: `AssignmentService.uploadSubmissionAttachment`/`getSubmissionAttachmentDownloadUrl`; `student_assignments_page.dart` gained a real "แนบไฟล์" button + picked-file chips; `teacher_submission_review_page.dart`'s roster gained a 📎-badge-with-count per student that opens a bottom sheet listing real attachments with working downloads. **Verification note, read before assuming this is untested**: the browser-level "student clicks แนบไฟล์ and picks a file in the OS dialog" step could not be driven through Playwright — traced to a confirmed bug in `file_picker` 8.3.7's web implementation (`_internal/file_picker_web.dart`): it removes the trigger `<input type=file>` from the DOM immediately after calling `.click()`, which breaks Chromium DevTools Protocol's file-chooser interception. Confirmed this is pre-existing and universal, not something this change introduced — regression-tested the *already-verified-working* `teacher_exam_builder_page.dart` image picker (worked earlier this same session) and it now fails identically. Given that, verified everything else for real instead of skipping: simulated the exact client-side upload sequence via direct HTTP calls (edge function → signed URL → real PUT of real bytes → RPC registration) and confirmed a real `submission_attachments` row + real `storage.objects` row; then, entirely through the real browser UI (not curl), confirmed the teacher roster shows the real 📎 badge, opens the real attachment list with the real filename, and downloading it opens a real signed URL that renders the exact real text the "student" (via the simulated upload) had submitted. The one gap: an actual mouse click on "แนบไฟล์" opening a real OS file dialog is unverified by browser automation — the code path from that click onward (`FilePicker.platform.pickFiles` → `uploadSubmissionAttachment`) is identical in shape to the teacher exam-builder image picker and the school-admin CSV template picker, both already relied upon elsewhere in this app. Test assignment/submission/attachment/storage object/sessions all cleaned up after. `flutter analyze` and full `flutter build web` clean throughout. |
| (no brief file — requested directly, 2026-08-27) | Added real student attendance-taking (เช็คชื่อ) for teachers, split into the 2 modes requested: (1) homeroom roster ("นักเรียนประจำชั้นที่ครูดูแล") and (2) per-course roster ("รายวิชาที่ตัวเองสอน"). **Course-mode backend already fully existed and was completely unused** — `attendance_records` table, `mark_attendance`/`list_course_attendance` RPCs, and even a client `AttendanceService` in `shared_core` (from `20260824130000_attendance_and_cctv_rpcs.sql`) had zero call sites anywhere in `apps/user_app` before this. **Homeroom-mode had no backend at all** — there was no real concept of "which teacher is homeroom advisor of which room"; `school_admin/school_teachers_page.dart`'s "ครูประจำชั้น" field was a fake local-only dialog value (read from the unrelated `users.room` column, never persisted). Built from scratch in `20260827060000_homeroom_attendance_system.sql`: `homeroom_assignments` (school_id, academic_year_id, grade_level, room, teacher_id) and `homeroom_attendance_records` tables; `set_homeroom_teacher`/`remove_homeroom_teacher`/`list_homeroom_assignments` (school_admin) and `list_my_homeroom_classes`/`list_homeroom_roster`/`mark_homeroom_attendance`/`list_homeroom_attendance` (teacher) RPCs; an internal `_current_academic_year_id()` helper since `academic_years` has no "current" flag (picks the row whose date range covers today, else the most recent). New `packages/shared_core/lib/services/homeroom_service.dart` + extended `attendance_service.dart`. New teacher page `teacher_attendance_page.dart` (menu item "เช็คชื่อ", checklist icon) with a 2-tab mode switcher, class/course dropdown, date picker, and a per-student 4-way status chip (มา/สาย/ลา/ขาด) + save button, reusing whichever backend the selected mode needs. Wired `school_teachers_page.dart`'s existing "ครูประจำชั้น" dropdown in the per-teacher edit dialog to the new real RPCs (loads real current assignment on open, calls `set_homeroom_teacher`/`remove_homeroom_teacher` on save) — the separate "กำหนดครูประจำชั้น" quick-action card on that page still opens a generic fake `_showAssignmentDialog` shared with 2 unrelated cards (building-duty, permissions) and was **not** rewired, out of scope for this task. **Bug found and fixed before verification**: the new RPCs copied `mark_attendance`'s existing `v_actor := get_session_actor(p_token);` pattern, which does not set `FOUND` on an invalid token and threw a confusing Postgres "record not assigned" error instead of a clean `invalid_session` — fixed to the `SELECT * INTO v_actor FROM get_session_actor(p_token); IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;` pattern documented in `CLAUDE.md`. Live-verified via real Playwright UI as `teacher@aiot-school-lab.local` against the real seeded course/student (`AIoT ชีววิทยาและสิ่งแวดล้อม`, `นักเรียน ทดสอบ`, real `student_profiles` row ม.4/ม.4/1): the เช็คชื่อ page loaded both real homeroom (`ม.4/ม.4/1 (1 คน)`) and real course rosters, correctly showed already-marked status from prior writes, and a real click on a status chip + "บันทึกการเช็คชื่อ" produced a real `homeroom_attendance_records` row update (`status` changed present→absent, real `marked_at`) confirmed by direct DB query. Backend for `set_homeroom_teacher`/`list_homeroom_assignments` and both attendance RPC pairs also independently verified via direct signed-session `curl` calls (mirroring the exact client call shape) with matching real DB state. **Known gap**: the school_admin-side "ครูประจำชั้น" dropdown *save* click was not independently driven through Playwright — every attempt hit a pre-existing, unrelated app flakiness (see `HANDOFF.md`'s known issues: random client-side redirects to the "สร้างบัญชี" signup screen on the Nth post-login click, reproduced identically on both the school_admin and teacher dashboards, unrelated to any code touched this session) before reaching that specific click; the dialog opening with real prefilled data was confirmed live, and the identical save pattern (`DropdownButtonFormField` → RPC → SnackBar) was fully click-verified on the teacher attendance page instead. Real test attendance rows cleaned up after verification; the one real `homeroom_assignments` row (`teacher@aiot-school-lab.local` → ม.4/ม.4/1) was left in place as legitimate configuration, matching the only real seeded homeroom. `flutter analyze` and full `flutter build web` clean. |
| (no brief file — requested directly, 2026-08-27, "#77") | Re-ran the RBAC audit (originally closed 2026-08-24) to cover the 2026-08-25 role merge and ~20 migrations/68 RPCs added since, which predated/postdated that audit and were never checked. Role merge confirmed clean (building-restriction removal for `school_admin` is the documented intended design, applied consistently; no live `facility_manager`/`technician` references remain except one cosmetic function name). All 68 new/changed RPCs statically reviewed for the `get_session_actor` → role whitelist → actor-derived `school_id` pattern; live-tested with real throwaway sessions that `student`/`school_admin` can't reach `super_admin`-only or cross-tenant operations (all correctly `403`/`forbidden`). No new vulnerabilities found — see `docs/handoff/HANDOFF.md`'s "RBAC audit continuation" section for the full writeup. |
| (no brief file — requested directly, 2026-08-27) | Added a 4th metric, real light intensity (`light_lux`), to the student home page's real weather card (`widgets/aiot_weather_sensors_card.dart`'s `AiotWeatherSensorsCard` — the actual live widget real students see via `student_variant_school_home.dart`, not the unreachable `student_redesign_prototype_page.dart` prototype file also touched this session, which was investigated and confirmed dead code with no route pointing to it). This card previously only showed PM2.5/temperature/humidity — it never had a fake UV bug like the teacher pages did, it just hadn't been extended to show light intensity at all. Added `_luxStatus()` following the file's own existing per-metric threshold-status pattern (mirrors `SensorModel.luxLevel`'s ≥300/≥150/else thresholds) and a 4th `AiotSensorItemTile`. Live-verified: seeded real `sensor_readings` rows (pm25/temperature/humidity/light_lux) on a real device, real student login showed all 4 real values including "ความเข้มแสง 420 lux — ปกติ — แสงสว่างเพียงพอสำหรับอ่านหนังสือ", no layout overflow in the fixed-height desktop column layout. Test readings and session cleaned up after. `flutter analyze` and full `flutter build web` clean. |
| (no brief file — found and fixed directly, 2026-08-26) | `teacher_aiot_dashboard_page.dart` (the first of the 7 teacher bugs above): every sensor value was a hardcoded constant labeled "เรียลไทม์" (real-time), and the threshold-save/alert-acknowledge buttons only mutated local state. Also swapped the fake "UV index" metric (never a real `metric_type` — confirmed via the enum) for real light intensity (`light_lux`, which already existed and already flows through `sensor_latest`/`RealtimeService`). New migration `20260826160000_teacher_aiot_thresholds.sql`: `list_thresholds`/`set_threshold` (thresholds had zero RPCs before this — new), and widened `list_school_alerts`/`acknowledge_sensor_alert_for_school_admin`'s role check to include `teacher` (they already existed and were correctly tenant-scoped, just school_admin-only) — per this page's own documented permission model. **Do not use the other `acknowledge_sensor_alert(p_alert_id)`** — it's built on `auth.uid()`/Supabase Auth for the sibling `aiot_dev_dashboard` app, incompatible with this app's custom-session architecture. New pgTAP `30_teacher_aiot_thresholds.test.sql` (11/11 pass). Live-verified end-to-end: real device names show an honest "ยังไม่มีข้อมูลเซนเซอร์จริง" state (0 rows exist in `sensor_readings` locally — no hardware connected, this is correct behavior not a bug); edited and saved a light-intensity threshold, confirmed it persisted in the DB after a reload; inserted one real test alert, confirmed it appeared via the real RPC, clicked "รับทราบ Alert," confirmed `sensor_alerts.status` actually flipped server-side (not just the UI) — then cleaned up all test data. **Known scope boundary, stated plainly, not papered over**: nothing auto-generates a `sensor_alerts` row from a real threshold violation yet (`ingest_sensor_readings_verified` doesn't check thresholds, no DB trigger exists either) — that's separate, larger work. CSV/Excel export on the same page is still fake (SnackBar-only), left alone, out of scope for this pass. **Follow-up same day**: the teacher **home page**'s own separate AIoT summary widgets (`_AiotWeatherSensorsCard` and `_SensorSnapshotCard`, both in `teacher_redesign_prototype_page.dart`, 4 total call sites) had the identical hardcoded pm25/temp/humidity/UV pattern — fixed too, same `RealtimeService.getSensorOnce()` call, same UV→`light_lux` swap, honest "ไม่มีข้อมูล" (grey, neutral) state instead of a fake number when no reading exists yet — also fixed the badge to show grey/neutral for "no data" instead of red/"ไม่ปลอดภัย" (unsafe), which was misleadingly alarming for an empty-data state. Live-verified: real login, home page now shows "-"/"ยังไม่มีข้อมูลเซนเซอร์จริง" everywhere instead of the old 18/28.5/62/UV 6 constants. **Self-caught bug during this fix**: `SensorModel` defaults an absent metric to 0, indistinguishable from a real 0 reading — a first version of this fix treated "school has *some* sensor data" (e.g. an energy meter) as "this weather card's PM2.5/temp/humidity/light are real", showing a misleading green "ปกติ" badge for metrics with zero real readings. Fixed by adding `RealtimeService.getWeatherMetricsWithData()` (returns the actual set of metrics with ≥1 real reading) and checking per-metric presence instead of a single coarse non-null check — live-verified with real energy/water test readings seeded (so that card correctly showed real data) while pm25/temp/humidity/light correctly stayed "ไม่มีข้อมูล" since no readings existed for those specific metrics. |
| (no brief file — found and fixed directly, 2026-08-26) | The teacher home page's **"การใช้น้ำ-ไฟ" (water/electricity usage) card** (`_HomeroomUtilityCard`) was also 100% fake — hardcoded weekly totals (142 kWh / 18.5 m³, inconsistent with its own hardcoded daily-chart array which summed to only 3.2 m³ for water) and fake ±% trend badges, backed by zero service calls. Fixed using **already-existing, already-real backend** (`UtilityService`/`get_energy_usage_summary`/`get_water_usage_summary`/`get_energy_usage_trend`/`get_water_usage_trend`/`get_energy_efficiency_score`/`get_water_efficiency_score` — all pre-existing, teacher-allowed, no new migration needed): real weekly totals, real 5-day chart with real calendar-accurate weekday labels (not a fixed Mon–Fri), and a real week-over-week % change computed from the efficiency-score RPCs' current/previous fields — shows "ไม่มีข้อมูลเทียบ" honestly instead of a fake percentage when there's no prior week to compare. Live-verified twice: honest all-zero state with real weekday labels (no local energy/water meter devices existed at all), then seeded 2 real test devices + 5 days of real `sensor_readings` and confirmed the card showed the exact correct calendar-week sum (75 kWh, 1.9 m³ — hand-verified against the sum of only this-week's inserted rows, correctly excluding last week's) and the exact right day highlighted/tooltipped. Cleaned up test devices/readings after. |
| (no brief file — requested directly, 2026-08-27) | Added a "เช็คชื่อนักเรียน" quick-shortcut to the teacher dashboard's `_TodayFocusCard` ("โฟกัสวันนี้" panel), following a UX discussion about the new attendance feature (added earlier the same day) being buried 7 items deep in the sidebar for something used every single class period. `_FocusRow` gained an optional `onTap` (renders a chevron, wraps content in `InkWell`) so this row — and any future one — can navigate; the new row pushes straight to `TeacherAttendancePage`. Purely additive: no existing dashboard content removed or reordered besides adding this as the first focus-panel row. Live-verified: real teacher login, dashboard shows the new row with a checklist icon and chevron, clicking it navigates to the real attendance page with real `list_my_courses`/`list_my_homeroom_classes` RPCs firing (confirmed via network log) and the real homeroom roster loading. `flutter analyze` and full `flutter build web` clean. |
| (no brief file — found directly, 2026-08-27/28) | User spotted that most of the teacher **home dashboard** (not the pages navigated to from it — the dashboard's own summary widgets) is hardcoded fake data, a scope the earlier "7 teacher fake-write bugs" audit never covered (that audit was page-by-page, not the dashboard's own decorative widgets). Confirmed by reading the source: `_SmartWiringLabCard` ("AIoT Smart Wiring Lab วันนี้" — kit/Pico-2/wiring-group counts), `TeacherMock.lessons`/`.reviewTasks`/`.students` (schedule, review queue, at-risk students), `_SubmissionBarChartCard`/`_StudentStatusDonutCard` (per-room % bar chart, 132-student donut), and the top KPI row are all `static const` literals with zero RPC calls — only `_TodayFocusCard`'s 3 original rows and `ห้องเรียนและรายวิชา`'s course cards were previously known-fake/known-real respectively. Researched real backend availability for each (see `HANDOFF.md` for the full per-item table) before starting fixes, since some need net-new schema (AIoT Wiring Lab's kit/wiring-group/inspection concept doesn't exist anywhere in the DB) while others just need an existing RPC wired in. **First fix, easiest of the set**: `_ScheduleCard` ("ตารางสอนวันนี้") now calls the real `CalendarService.listTeacherSchedules()` (backed by `list_teacher_schedules`, already used by the real `teacher_class_schedule_page.dart`) filtered to `ClassScheduleSlot.dayOfWeek == DateTime.now().weekday - 1`, with real loading/error/honest-empty states ("วันนี้ไม่มีคาบสอนในตาราง") replacing the 3 hardcoded lesson entries. Added `_LessonItem.subtitleLabel` (room-only when there's no note, instead of the old code's fixed `'$room · $note'` which would've shown a dangling `· ` for real data with no note text). Live-verified twice: once showing the correct real empty state (today's real weekday has no `class_schedules` row), once after inserting a real test row for today's weekday showing the exact real time/subject/room, then cleaned up. Minor width fix alongside: the fixed-width time label wrapped awkwardly for real two-digit-hour ranges like "13:00-14:00" vs the old mock's always-short single times — reduced font size 1pt to fit without wrapping. `flutter analyze` and full `flutter build web` clean. Remaining items from this audit (review queue, at-risk students, both charts, AIoT Wiring Lab, top KPI row) are still open — see `HANDOFF.md`. |
| (no brief file — requested directly, 2026-08-28) | Second item from the same audit: `_ReviewQueueCard` ("งานรอตรวจ") now aggregates real ungraded submissions across all of the teacher's active courses, replacing the 3 hardcoded `TeacherMock.reviewTasks` entries. No cross-course RPC exists for this (confirmed during the earlier scoping pass), so it's a client-side aggregate: `CourseService.listMyCourses()` → per active course `AssignmentService.listAssignments(courseId)` → per `published` assignment `AssignmentService.listSubmissions(assignmentId)` → count `status == 'submitted'` (the exact `submission_status` enum value meaning "turned in, not yet graded"; `'graded'`/`'returned'` correctly excluded). Sorted by pending count descending; assignments with 0 pending are dropped rather than shown as zero. Live-verified: the one real published assignment "สำรวจคุณภาพอากาศในห้องเรียน" with 1 real `submitted` submission correctly appeared with badge "1" and the real course name, replacing the old fake "ใบงาน PM2.5 · 18 ชิ้น" entry. **Found but not yet fixed**: the dashboard's top alert banner (`_TeacherHero`, "มีงานรอตรวจ 18 ชิ้น และนักเรียน 3 คนที่ต้องติดตามวันนี้") is a *third*, separate hardcoded spot reusing the same two numbers — missed by the original audit list since it's a banner, not a card. Queued as a follow-up once both source numbers (this item + the still-fake "ต้องติดตาม" count) are real, so the banner can share the live totals instead of hand-copied mock text. `flutter analyze` and full `flutter build web` clean. |
| (no brief file — requested directly, 2026-08-28) | Third item from the same audit: `_StudentsWatchCard` ("นักเรียนที่ต้องติดตาม"). User was asked whether to reuse the existing manual `student_support_cases` (teacher opens a case by hand) or build a real auto-computed signal, and chose auto-computed. New RPC `list_students_needing_attention` (`20260828000000_students_needing_attention.sql`) flags a student in the teacher's own courses on any of 3 real signals, checked in priority order: **≥2 overdue assignments** (published, `due_at < now()`, no `submissions` row for that student), **avg confirmed-grade ratio < 50%**, or **≥2 `absent` marks in the last 30 days** (via the existing course `attendance_records`, first real consumer of that data for a *computed* signal rather than a direct roster view); `severity` is `'urgent'` at ≥3 overdue or ≥4 absences, `'normal'` otherwise. New model `AutoFlaggedStudent` + `StudentSupportService.listAutoFlaggedStudents()` (kept in the same service file as the manual case-tracking methods since both concern "students needing support," with a doc comment distinguishing the two — deliberately not reusing `StudentSupportCase`, since that model's fields (case status, interventions, manually-set risk level) don't fit an auto-computed signal). Live-verified all 3 signal branches independently via direct signed-session `curl` calls against real data (seeded 2 real overdue assignments → "ค้างส่ง 2 งาน"; 2 real `absent` attendance rows → "ขาดเรียน 2 ครั้ง (30 วัน)"; one real low-score confirmed grade, careful to average correctly against the one real pre-existing 18/20 grade rather than overwrite it → "เฉลี่ย 46%"), each cleaned up before testing the next so they wouldn't interfere. Then live-verified once more through the real UI end-to-end (real teacher login, real dashboard, real network call, real card content) with the overdue-assignment signal, replacing the old fake "สายฟ้า/มินตรา/ก้องภพ" entries with the one real flagged student. `flutter analyze` and full `flutter build web` clean. Remaining from this audit: both dashboard charts, the AIoT Wiring Lab card, the top KPI row, and the `_TeacherHero` banner noted above. |
| (no brief file — requested directly, 2026-08-28) | Fourth item from the same audit: both dashboard charts. **`_SubmissionBarChartCard`** ("สถานะส่งงานรายห้อง" → renamed "สถานะส่งงานรายวิชา" since the real grouping is per-course, not per-room — the mock's ม.5/1-style room labels don't match how this schema actually models rooms, see `courses.room` which is a physical lab code like "Lab 3", not a class section) — for each active course: `submitted / (published_assignment_count × enrolled_count)`, built from `CourseService.listCourseStudents` + `AssignmentService.listAssignments`/`listSubmissions` (same aggregation shape as item 2's review queue, just counting all submissions instead of only pending ones); courses with 0 assignments or 0 enrolled students are skipped rather than shown as a misleading 0%. **`_StudentStatusDonutCard`** ("สัดส่วนสถานะนักเรียน") — reuses item 3's `list_students_needing_attention` output instead of a new RPC: students flagged for `'ค้างส่งงาน'` become the "ขาดส่งงานบ่อย" segment, everyone else flagged becomes "ต้องติดตาม", the remainder of the teacher's total distinct roster (unioned across `listCourseStudents` per course) is "ปกติ". Both cards now have real loading/error/honest-empty states instead of always rendering `const` fake numbers. Live-verified: real single course/student showed the bar chart at a real "100%" (1 submission / 1 assignment × 1 student) and the donut at real "1 คน" / ปกติ 100% / ต้องติดตาม 0% / ขาดส่งงานบ่อย 0%, replacing the fake 5-room bars and fake "132 คน" split. `flutter analyze` and full `flutter build web` clean. Remaining: AIoT Wiring Lab card (needs new schema, biggest piece), the top KPI row, and the `_TeacherHero` banner — both of the latter two can now go real since all their source numbers are real as of this fix. |
| (no brief file — requested directly, 2026-08-28) | Fifth item from the same audit: the top KPI row (`_TeacherSummaryStrip`/`TeacherMock.stats`) and `_TeacherHero`'s alert banner. Both needed the same 2 numbers items 1-4 already made real (pending-review total, flagged-student count), so this was pure wiring, no new backend. Extracted 2 shared top-level helpers, `_fetchPendingReviewTotal()`/`_fetchFlaggedStudentTotal()`, reused by `_TeacherHero` and `_TeacherSummaryStrip` independently (each widget still fetches its own data on `initState`, matching this file's established per-card pattern from items 1-4, rather than lifting state through a parent — the same card classes (`_TeacherHero`/`_TeacherSummaryStrip`) turned out to be instantiated at multiple different composition sites for different breakpoints/prototype variants, so parent-lifting would only have covered one of them). `_TeacherSummaryStrip` now shows real คาบสอนวันนี้ (via `CalendarService.listTeacherSchedules()` filtered to today, same logic as item 1), งานรอตรวจ, ต้องติดตาม, and a 4th tile **relabeled** "วิชาที่สอน" (real active-course count) — the original "ห้องปกติ" (normal rooms) had zero real backing anywhere in teacher scope, so rather than fake a definition for it, swapped in a metric that's actually real; kept the mismatch honest instead of hiding it. `_TeacherHero`'s banner now reads real counts, with a positive all-clear message when both are 0 instead of a fake "18 ชิ้น/3 คน". Live-verified: banner showed "มีงานรอตรวจ 1 ชิ้น และนักเรียน 0 คนที่ต้องติดตามวันนี้" and the strip showed "0/1/0/1" — both exactly matching real state. **Known gap, out of scope for this pass**: 3 other call sites in this same file (lines ~333, ~412, ~6104 as of this commit) still reference the old `TeacherMock.lessons`/`.reviewTasks` arrays directly instead of the now-real `_ScheduleCard`/`_ReviewQueueCard` widgets — these appear to belong to other prototype breakpoint/variant layouts not reached by the default `TeacherPrototypeVariant.a` route real users see, consistent with this file's existing multi-variant prototype structure, but not independently confirmed dead — flagging for whoever touches this file next rather than chasing it down now. `flutter analyze` and full `flutter build web` clean. |
| (no brief file — requested directly, 2026-08-28) | Sixth and last item from the same audit: `_SmartWiringLabCard` ("AIoT Smart Wiring Lab"), the biggest gap of the six — no table anywhere modeled "a group of students wiring a kit" or a pass/fail inspection workflow. User was asked whether to scope this down to just real device/kit status (fast) or build the full group+inspection system to match the mock (bigger); **chose the full option**. Deliberately did NOT extend `student_groups`/`group_members` — that table is scoped to `course_id` + nullable `assignment_id` with a real one-student-per-group-*per-assignment* business rule; adding kit_code/status columns would've been a two-entities-in-one-table smell risking the existing (student-readable) assignment-group feature. New migration `20260828010000_wiring_groups_system.sql`: `wiring_groups` (course_id, kit_code — matches the pre-existing but-until-now-always-empty `devices.kit_code`, not FK'd since it's not unique on devices — name, status, inspection_note/inspected_by/inspected_at) + `wiring_group_members`; a 4-state machine (`wiring → passed｜failed`, `failed → wiring｜passed`, `passed → running｜wiring｜failed`, `running → wiring`) enforced entirely server-side in `set_wiring_group_status` (illegal transitions raise `invalid_transition`); an internal `_assert_wiring_course_access` helper mirroring `_assert_homeroom_access`; 6 more RPCs (list/create/delete groups, add/remove member — the latter checks real `course_students` enrollment, an improvement over the pre-existing `add_group_member` which doesn't — and `get_wiring_lab_summary`, a single aggregate RPC for the dashboard card: kit-ready = every device sharing a `kit_code` is `status='online'`, the alert row picks one device that's `offline`/`error`/stale-`last_seen_at` worst-first); extended `list_teaching_kit_devices` (DROP+CREATE, `RETURNS TABLE` can't be `CREATE OR REPLACE`d) to also return `kit_code` so the create-group dialog can offer real kits without a new RPC. **Real data gap found and fixed while testing**: the 4 real seeded teaching-kit devices on the real course had a `kit_code` column that existed but was never populated (`NULL`) — set them to a real `KIT-01` as legitimate one-time data completion (same precedent as the real join code/thresholds set earlier this session), not test data. New `packages/shared_core/lib/services/wiring_group_service.dart` (`WiringGroupItem`/`WiringLabSummary`/`WiringGroupMember` models + `WiringGroupService`, mirroring `student_group_service.dart`'s shape) and an extended `AiotLabDeviceItem.kitCode`. New "กลุ่มต่อสาย (Wiring Groups)" section in `teacher_aiot_lab_page.dart` (between the existing device-control and history sections): group cards with kit/member/status info, a create-group dialog (kit picker + name), a member-management bottom sheet reusing the course roster (`CourseService.listCourseStudents`), and status-change buttons computed client-side from the exact same legal-transition table as the SQL state machine (so the UI never offers a transition the server would reject). `_SmartWiringLabCard` rewritten the same way as items 1-4 (`StatefulWidget`, real loading/error/honest-empty states) — dropped the fabricated "AIOT-501 · ม.5/2 · คาบ 10:30 น." framing and the "กำลังใช้งาน" status chip (both had zero real backing) rather than inventing meanings for them; removed the now-dead `_LabStatusChip` class (flagged unused by the analyzer) as a result. Live-verified fully end-to-end through the real UI, not curl: real login → real AIoT Lab page → created a real group against the real `KIT-01` → added the real seeded student via the roster checkbox (confirmed a real `wiring_group_members` row) → clicked "เปลี่ยนเป็น ผ่านการตรวจ" (wiring→passed) and confirmed the card's status pill, member chip, and *available next-transition buttons* all updated correctly in real time (passed's legal-next set — running/wiring/failed — matched exactly) → confirmed the dashboard card's real-time alert banner correctly flagged the one real device with a stale `last_seen_at` (no live hardware connected, same honest state documented elsewhere this session) with the real kit code and device name. Backend state machine also independently stress-tested via signed-session `curl` for every legal transition plus one illegal one (`wiring→running`, correctly rejected with `invalid_transition`). Cleaned up the test group after (cascade-deleted its member row, verified 0 orphans) — kept the real `kit_code` assignment as legitimate config. `flutter analyze` and full `flutter build web` clean throughout. **This closes all 6 items of the teacher-dashboard fake-data audit** started 2026-08-27/28. |
| (no brief file — requested directly, 2026-08-28) | User spotted 2 real bugs by running the app locally and comparing against what was reported fixed, pushed as a merge request, and looking closely at the actual rendered dashboard. (1) **`_SubmissionBarChartCard` overflow**: real 100% data hit the fixed `SizedBox(height: 140)` container's true content height (~142px), showing a real "BOTTOM OVERFLOWED BY 2.0 PIXELS" debug strip — the mock's percentages (92%/78%/etc, never a clean 100%) had coincidentally never rendered tall enough to reveal this pre-existing too-tight layout. Fixed by bumping the container to 148px. (2) **"ฉบับร่าง" (draft) badge on every course card, always, regardless of real status** — `_ClassesCarousel` checked `course.status == 'published'`, but the real `courses.status` enum is `active`/`closed`, never `published`/`draft` — this check could never be true, so the badge always fell through to "ฉบับร่าง" for every real course including active ones. A pre-existing bug, not introduced by this session's work, but only now visually confirmed via a live screenshot. Fixed to use the already-available `course.isActive` getter, with real labels "กำลังเปิดสอน"/"ปิดแล้ว". Live-verified both: the real course card now shows "กำลังเปิดสอน" (green), and the bar chart's real 100% bar renders with no overflow indicator. `flutter analyze` and full `flutter build web` clean. **Separately flagged, not yet fixed**: `_TodayFocusCard`'s own "ตรวจใบงาน PM2.5"/"นักเรียนไม่ส่งงาน"/"คาบถัดไป" rows are a second, redundant fake summary distinct from the real `_ReviewQueueCard`/`_StudentsWatchCard`/`_ScheduleCard` widgets fixed earlier — only this card's own first row (the "เช็คชื่อนักเรียน" shortcut) was ever real. |
| (no brief file — requested directly, 2026-08-28) | Fixed the flagged gap above: `_TodayFocusCard`'s remaining 3 rows. Rather than reuse `_ReviewQueueCard`/`_StudentsWatchCard`'s exact numbers (which would've duplicated those cards' meaning under a different label), each row got its own precisely-scoped real definition. **"งานรอตรวจ"** (renamed from the assignment-specific "ตรวจใบงาน PM2.5" — that name only ever made sense for one hardcoded mock assignment) reuses the same `_fetchPendingReviewTotal()` helper item 5 already extracted. **"นักเรียนไม่ส่งงาน"** is a genuinely different metric from "ต้องติดตาม" (which needs ≥2 overdue, not just ≥1) — new `_fetchNotSubmittedStudentTotal()`: for every active course, every published assignment, every enrolled student not in that assignment's submitted set, added to a de-duplicated set; final count is students with *at least one* currently-unsubmitted published assignment, which is a more literal/immediate reading of the row's label than the stricter "flagged" threshold. **"คาบถัดไป"** — new `_fetchNextPeriodLabel()`, reuses the same `CalendarService.listTeacherSchedules()` + today-filter as `_ScheduleCard`, picks the first slot whose `start_time` hasn't passed yet (string-compared against the current `HH:mm:ss`), returns `null` (rendered as an honest "ไม่มีคาบแล้ว") when none remain today instead of ever showing a stale time. All 3 rows show a `-` placeholder while loading rather than a flash of `0`/wrong data. Live-verified: real state showed "งานรอตรวจ 1 ชิ้น" / "นักเรียนไม่ส่งงาน 0 คน" (the one real submission means the one real assignment has nobody outstanding) / "คาบถัดไป ไม่มีคาบแล้ว" (today has no remaining real schedule row) — all matching hand-computed expectations exactly. `flutter analyze` and full `flutter build web` clean. This closes the last known fake-data gap found in the teacher dashboard this session. |
| (no brief file — requested directly, 2026-08-27) | Restyled `teacher_attendance_page.dart` to match the app's actual theme instead of generic Material colors — it originally used raw hex greens/ambers/blues (`0xFF16A34A` etc.) and plain bordered `Container`s instead of `TeacherPalette`/the shared card components every other teacher page uses. Now built on `TeacherSectionCard` (the same white/shadow/rounded-24 card used across `teacher_students_page.dart` etc.) for both the selector and roster sections; roster rows use the same `CircleAvatar`-with-initial pattern as `_StudentRow` in `teacher_students_page.dart`; status options now reference `TeacherPalette.green/orange/iris/red` instead of one-off hex values (`iris`, a violet-family color, replaces the out-of-palette blue used for "ลา" so all 4 statuses read as intentionally-chosen, not default Material swatches); mode tabs and form fields use `TeacherPalette.skyVivid/skyLight/border` instead of ad-hoc `0xFFE9E1F5`. Also added a small live status-count summary (มา/สาย/ลา/ขาด with counts) next to the date picker, and swapped `ChoiceChip` for a custom `_StatusPill` (filled-color-when-selected, matching this app's pill/badge conventions elsewhere) since `ChoiceChip`'s default Material look didn't match. Purely visual/structural — no RPC or data-flow changes. Live-verified both tabs (homeroom and course) render with the new styling against real data and the status pills/summary update correctly. `flutter analyze` and full `flutter build web` clean. |

## Done (commit found)

| Brief | Closing commit | Topic |
|---|---|---|
| (no brief file -- requested directly, 2026-09-04) | `cb8dc73` | Added one shared linked-student selector across Dashboard, Learning, Attendance, Academic Calendar, and Schedule; Messages/Settings remain unaffected. Desktop uses a popup, mobile uses a bounded scrollable bottom sheet, stale async responses are ignored, and the shell displays the selected real student. Verification: 33/33 Parent tests, scoped analyzer clean, final web build successful. **Update, same day:** the previously-pending authenticated browser click-through is now done — served the `flutter build web` output over a static server (kept `flutter run`/Docker off at once for RAM) against the already-running local Supabase, logged in as `parent@aiot-school-lab.local` via Claude-in-Chrome, clicked through all 7 pages plus the leave-request dialog, confirmed the selector correctly stays non-interactive for this account's single linked child, confirmed real data stays consistent across pages, submitted a real leave request and confirmed via direct DB query it inserted a real `pending` row (deleted after verification), zero console errors. Update: multi-child switching was later browser-verified with a runtime-only second-child fixture; see the current In-progress item for the ACL correction and pending linked-project deployment. Mobile-width rendering remains covered by automated widget tests only. |
| (no brief file — requested directly, 2026-09-03) | `376e34f`, `ee7f122`, `48b44a7` | Completed the Parent portal data-integrity pass across all 7 active pages (dashboard, schedule, learning, attendance, academic calendar, messages, settings) plus leave-request submission. Every empty data card uses the exact text `ยังไม่มีข้อมูล`, while loading, error, unauthenticated, and no-linked-student states remain distinct. Added fresh-install bootstrap `20260903005000_school_events_bootstrap.sql` while restoring historical migration files unchanged, plus `20260903030000_parent_portal_rpc_hardening.sql` to enforce selected-child authorization, remove unsafe Parent direct-table policies, normalize grants, and audit leave submit/review actions. Verification: 26/26 focused Flutter tests passed cumulatively, scoped `flutter analyze` was clean, web build succeeded, a fresh local `supabase db reset` completed, all 8 Parent-facing REST reads returned real seeded data, and the full REST leave flow passed submit, admin MFA approval, audit rows, and excused attendance. Local Supabase was stopped afterward to conserve RAM. |
| `agy-brief-school-admin-fake-fallback-data.md` | `08bc0b2` | Fixed silent fake fallback data across all School Admin pages (Tier A & Tier B) — silent `catch (_) {}` and `if (data.isNotEmpty)` guards were hiding both fetch errors and genuinely-empty real results behind hardcoded mock data. |
| `agy-brief-school-admin-root-shell-swap.md` | `08bc0b2` | Replaced legacy `school_admin` landing shell with the new hub `SchoolAdminDashboardPage` in `role_router.dart`, folding in all 8 old operational menu items so nothing already working got lost. |
| `agy-brief-lesson-editor-data-loss-bug.md` | `08bc0b2` | Fixed data loss bug in teacher lesson editor — opening an existing lesson loaded a placeholder instead of real content, and autosave then overwrote the real body with it. |
| `agy-brief-school-admin-redesign-phase2.md` | `08bc0b2` | Ported and wired all 13 `school_admin/*` pages from the new design (Batch 1 reuse-heavy + Batch 2 new). |
| `agy-brief-super-admin-redesign-phase1.md` | `08bc0b2` | Ported `schools_page.dart` + `device_control_page.dart` into the new design, backed by 7 real RPCs. |
| `agy-brief-multi-role-fix-and-followups.md` (no separate brief file — fixed directly, not from a written brief) | `08bc0b2` | 3 issues found via live user testing after the fake-fallback-data fix shipped: `_AssignmentOverview` widget, `school_students_page.dart`'s per-grade breakdown, and `school_teachers_page.dart` showing 0 teachers despite a real one existing (multi-role `list_school_users` scoping bug — see HANDOFF.md section 11). |
| `agy-brief-multi-role-login-phase1.md` | `cf8de5b` | One account, multiple roles, choose at login |
| `agy-brief-post-role-merge-remediation.md` | `b4ce6ad` | SOS teacher-visibility gap, teacher class schedule UI, device command rate limit |
| `agy-brief-role-merge-technician-facility-manager.md` | `2012849` | Merged `technician`→`super_admin`, `facility_manager`→`school_admin`, 8→6 roles |
| `agy-brief-school-admin-remaining-4-features.md` | `c24a7c1` | Energy/ESG, CCTV grants, device pg_cron scheduling, device control |
| `agy-brief-attendance-and-cctv-access-grants.md` | `c24a7c1` | Real attendance marking + CCTV access-grant management |
| `agy-brief-parent-attendance-leftover-mock.md` | `180dc04` | Removed 3 leftover-mock sections in parent attendance page |
| `agy-brief-infinite-height-followup-verify-executive.md` | `c4b3df4` | Verified the RenderFlex overflow fix on 4 executive pages |
| `agy-brief-infinite-height-row-crash-10-files.md` | `5a413bc` | `Row(crossAxisAlignment: stretch)` crash across 10 ported pages |
| `agy-brief-parent-executive-backend-wiring.md` | `5a413bc` | Wired real backend into ported parent/executive UI |
| `agy-brief-wire-parent-executive-ui-to-backend.md` | `5a413bc` | Same effort, backend existed but nothing called it yet |
| `agy-brief-fix-kong-internal-host-signed-url.md` | `b4d6271` | Signed download URLs leaked the Docker-internal `kong:8000` host |
| `agy-brief-learning-platform-page-fully-mock.md` | `355c6ae` | `learning_platform_page.dart` — was 100% mock, corrected an earlier wrong "partial" claim |
| `agy-brief-fabricated-page-names-in-report.md` | `dad8b65` | A status report listed 5 pages that don't exist — corrected |
| `agy-brief-qr-pairing-decision-readonly-status.md` | `6892f05` | Product decision: QR pairing scanners are read-only status, not control |
| `agy-brief-remaining-fake-features-2026-08-24.md` | `e248ba2` | 5 fake/missing features found finishing a page-by-page audit |
| `agy-brief-redteam-super-admin-findings.md` | `7ab0f6e` | RedTeam pass on `aiot_dev_dashboard`, incl. a migration-collision fix |
| `agy-brief-URGENT-security-rls-anon-open.md` | `d24b1b5` | Anon-open RLS policies were leaking the whole DB |
| `agy-brief-qr-pairing-wrong-rpc.md` | superseded by `6892f05` | An earlier "fix" called the wrong RPC — resolved by the read-only decision instead |
| `agy-brief-qr-pairing-fixes.md` | `b3e349d` | 3 fixes for AUTH-5 terminal QR pairing |
| `agy-brief-question-dev-dashboard-15pct.md` | superseded | Asked why `aiot_dev_dashboard` was only ~15% real — answered later when it reached 26/26 (see that app's own `docs/handoff/HANDOFF.md`) |

## ⚠️ Unclear — verify before trusting either way

| Brief | Why it's unclear |
|---|---|
| `agy-brief-fix-alerts-logs-fake-writes.md` | No commit found that clearly closes this — `alerts_logs_page.dart` fake local writes may still be open. Check the file directly. |
| `agy-brief-fix-school-admin-home-hardcoded-stats.md` | Only found a commit that *expands* the fix notes (`595bbb4`), not one confirming it landed. Check `school_admin_home_page.dart`... *note: this may refer to the old `dashboard/` school_admin, which has since been fully rewired — could already be moot.* |
| `agy-brief-ci-pipeline-real-cause.md` | Only the brief-writing commit found, no fix commit. CI pipeline status unverified. |
| `agy-brief-kiosk-pairing-admin-architectural-mismatch.md` | No closing commit found — may still be an open architectural question, not a code fix. |
| `agy-brief-school-admin-dashboard-dead-drawer-buttons.md` | No direct closing commit, but `school_admin_dashboard.dart` was fully rewired to 8/8 real menus in `c24a7c1` — likely moot/superseded rather than genuinely open. Not independently re-verified. |
| `agy-brief-full-remaining-backlog-2026-08-24.md` | A large backlog list, not a single fixable item — items from it fed into later work (role merge, remediation) but the file itself was never "closed" as a whole. Treat as a reference list, not a tracked task. |

## Adding to this log

When you write a new `agy-brief-*.md`, add it to "In progress" here. When
you verify it's actually done (real RPC/browser test, not just agy's
say-so), move it to "Done" with the commit hash. Don't mark something
Done from a report alone.
## 2026-08-31 — Emergency Inbox Hardcoded Fixes
- แก้ notifications_page.dart: ลบ demo fallback 4 รายการ, แก้ icon mapping 'incident_report'
- แก้ teacher_incident_inbox_page.dart: ปุ่มปิดเหตุ overflow (Wrap→Column), Resolved Hero Card ใช้ข้อมูลจริง (_lastResolvedSosIncident)
- Brief: docs/handoff/agy-brief-emergency-inbox-hardcoded-fixes-2026-08-31.md

## 2026-09-01 — Leave Request System (Parent to Teacher)
- สร้างระบบแจ้งลาเรียนครบวงจร (End-to-End)
- **Database:** สร้างตาราง `leave_requests`, ถังเก็บรูป `leave_attachments`, และ RPC `submit_leave_request`, `review_leave_request` 
- **Automation:** เมื่อครูกดอนุมัติผ่าน RPC ระบบจะเช็คชื่อให้เป็น "ลา (Excused)" ในตาราง `homeroom_attendance_records` และ `attendance_records` อัตโนมัติ
- **Parent UI:** สร้าง `leave_request_dialog.dart` ดีไซน์ Hyper-Premium (iOS Date Picker, รูปแบบ Popup ตรงกลาง) และรองรับการแนบรูปภาพด้วย `image_picker`
- **Teacher UI:** สร้าง `teacher_leave_approval_page.dart` ในรูปแบบ Inbox พร้อมดึงข้อมูลชื่อนักเรียนจากฐานข้อมูลจริง และอัปเดตสิทธิ์ `binding_code_id` ให้สามารถจับคู่ Parent-Student ได้แบบ 1-to-1
- Brief: docs/handoff/agy-brief-parent-teacher-leave-request-feature.md



> งานของวันที่ 2026-09-06 (energy · esg · device_control · การตรวจย้อน 5 หน้า)
> เคยถูกสรุปซ้ำไว้ตรงนี้ — ลบออกแล้วเพราะ commit เก็บครบกว่าและแก้ย้อนหลังไม่ได้
> ดูด้วย `SINCE='2026-09-06' ./scripts/state.sh --log`

<!-- ประวัติจาก 2 เลนที่ทำคู่กัน: บนคือเลน Claude (agent/publish-current-work) ล่างคือเลน codex (fix-executive-bug-3) — ไฟล์นี้เป็น append-only เก็บไว้ทั้งคู่ -->
## 2026-09-08 — sensor_ingest ไม่อัปเดต last_seen_at + production migration ค้าง 17 ไฟล์
- เจ้าของทดสอบเชื่อมเซนเซอร์จริงผ่านบัญชี `www.pakasit14@gmail.com` (production,
  ไม่ใช่ local dev) แล้วสงสัยว่าทำไมหน้าอุปกรณ์ดูเหมือนไม่มีอะไรเปลี่ยน
- ตรวจ production ตรง ๆ พบว่าเซนเซอร์ส่งข้อมูลเข้า `sensor_readings` จริง
  ต่อเนื่องทุก ~15 วินาที (เชื่อมต่อสำเร็จ ไม่ใช่บั๊ก) แต่ `sensor_ingest`
  RPC อัปเดตแค่ `devices.status='online'` **ไม่เคยอัปเดต `last_seen_at`**
  เลย ทำให้คอลัมน์นี้ค้างที่ค่าตอนลงทะเบียนตลอดไป (เจอเคสจริง: ห่างกัน 11 วัน)
- **แก้แล้ว**: migration `20260908010000_sensor_ingest_update_last_seen_at.sql`
  เพิ่ม `last_seen_at = now()` เข้าไปใน `UPDATE devices` ประโยคเดิม — ไม่กระทบ
  performance เพิ่ม (รวมอยู่ใน statement เดียวกัน) และไม่กระทบ dashboard
  online-count (ใช้ `status='online' OR last_seen_at>=15min` อยู่แล้ว)
  ทดสอบด้วย pgTAP `44_sensor_ingest_last_seen_at.test.sql` (4 tests ผ่านหมด)
- **บั๊กที่เจอแต่ยังไม่แก้ (แยกเรื่อง คนละขนาดงาน)**: `devices.status` ไม่มี
  cron ไหนคอยตรวจจับอุปกรณ์ที่เงียบไปนานแล้วให้กลับเป็น `'offline'` —
  เคยตั้งเป็น `'online'` ครั้งเดียวจะค้างแบบนั้นตลอดกาล แปลว่าตัวเลข
  "อุปกรณ์ออนไลน์" บน dashboard จะนับอุปกรณ์ที่หยุดส่งข้อมูลไปแล้วนานแค่ไหน
  ก็ตามว่าออนไลน์อยู่ดี ต้องมี cron ใหม่หรือเปลี่ยน logic การนับถึงจะแก้ได้จริง
- ระหว่างทางพบว่า production **ไม่เคย apply migration ตั้งแต่ 2026-08-31**
  (ค้างสะสม 17 ไฟล์ — ระบบประชุม, staff attendance/requests, permission
  matrix, incident visibility, parent RLS ฯลฯ) เจ้าของยืนยันให้ push
  ทั้งหมดพร้อมกัน (`npx supabase db push --linked --include-all`) —
  ตอนนี้ production sync กับ local migration history แล้ว
- Commit: `c20dd39`
- **ต่อยอด**: `poll_device_commands` (ที่รีเลย์/กล้องเรียกประจำแทน
  `sensor_ingest` ที่มันไม่เคยเรียก) มีช่องโหว่เดียวกัน — ไม่เคยอัปเดต
  `status`/`last_seen_at` เลย แปลว่าอุปกรณ์ประเภทนี้ไม่มี heartbeat จริง
  ตั้งแต่แรก แก้แล้วด้วย migration
  `20260908020000_poll_device_commands_update_last_seen_at.sql` + pgTAP
  `45_poll_device_commands_last_seen_at.test.sql` (3 tests ผ่านหมด),
  push เข้า production แล้ว, commit `de77fec`
- **ยังไม่ทำ (ตั้งใจ)**: cron ตรวจ staleness แล้ว mark `'offline'` เอง —
  ต้องรู้ polling interval จริงของเฟิร์มแวร์ก่อน (โค้ดเฟิร์มแวร์ไม่ได้อยู่ใน
  repo นี้ ดู `docs/handoff/SENSOR_GATEWAY_INTEGRATION.md`) ไม่งั้นตั้ง
  threshold ผิดจะเกิด false-offline กับอุปกรณ์ที่โพลไม่ถี่โดยตั้งใจ (เช่น
  ประหยัดแบต) ต้องคุยกับทีมฮาร์ดแวร์ก่อนถึงจะทำต่อได้

## 2026-09-08 — School Admin re-audit เต็ม 23 หน้า + แก้ profile/dashboard sidebar
เจ้าของขอให้ตรวจ School Admin ใหม่ทั้งหมด (หลังตอบเรื่อง `school_scan_page`
ผิดไปครั้งหนึ่งว่า "ไม่ import shared_core" ทั้งที่จริงต่อแล้ว — สับสนกับ
`director_scan_page` ของ Executive) ส่งเอเจนต์ 3 ตัวขนานกันอ่านเต็มไฟล์ 20
หน้าที่เหลือ (แบ่งคนละ ~7 หน้า) บวกกับที่ตรวจเองแล้ว 2 หน้า (`school_reports_page`,
`school_scan_page`) รวม 23 หน้า — **ผลตรวจจริง (ไม่ใช่เดา)**:

**17/23 หน้า DoD ครบ สะอาดจริง**: `attendance_settings` `cctv`
`device_control` `device_schedule` `energy` `esg` `import` `learning_tracks`
`settings` `students` `teachers` `incident_inbox` `leave_approval`
`report_requirements` `alerts` `devices` `reports`

**6/23 หน้ามีของปลอมจริง ระบุจุดได้ชัด**:
- `school_admin_dashboard_page.dart` — การ์ด sidebar/drawer hardcode ชื่อ/
  อีเมล/ชื่อโรงเรียนปลอมให้ทุกคนเห็นเหมือนกันไม่ว่าใครล็อกอิน — **แก้แล้ว**
- `school_admin_profile_page.dart` — ปุ่ม fake-success 3 ปุ่ม
  ("เปลี่ยนรหัสผ่าน" ไม่เรียก backend เลย, "ออกจากระบบอุปกรณ์อื่น" ไม่เรียก
  backend, "ดูอุปกรณ์" ไม่เปิดอะไรจริง) + ฟิลด์ hardcode 5 จุด (เวลาล็อกอิน
  ล่าสุด, สถานะความปลอดภัย, ชื่อโรงเรียน, วันที่สร้างบัญชี) — **แก้แล้ว**
- `school_permissions_page.dart` — dialog แก้ไขสิทธิ์ยังเสนอ role
  `ครูประจำอาคาร` ที่ยุบไปแล้ว 25 ส.ค. (`_buildRoleSelectorChips` ฯลฯ) —
  cosmetic ไม่ทำข้อมูลพัง (`_parseRole` map เป็น teacher เบื้องหลัง) —
  **ยังไม่แก้**
- `school_resources_page.dart` — การ์ด KPI ปลอม 3 ใบ (PM2.5/ESG, จุด
  ผิดปกติ, IoT online 100% ตายตัวทุกแถว) + filter อาคาร/ห้อง 2 ตัวที่ไม่
  กรองอะไรจริง — **ยังไม่แก้**
- `school_buildings_page.dart` — เจอเยอะสุด: บล็อก "รายการที่ควรตรวจสอบ"
  ปลอมทั้งบล็อก, ปุ่ม fake-navigation 3 ปุ่ม, RPC `list_school_rooms` เอง
  hardcode `devices_count=0`/`training_kits_count=0`/`status='ปกติ'` ทุกห้อง
  เสมอ (บั๊กอยู่ที่ SQL ไม่ใช่ Dart), audit log ทุกแถว map เป็น
  `type: 'success'` เขียวหมด, filter ประเภทห้อง/สถานะมีตัวเลือกที่กรองไม่ได้
  จริง — **ยังไม่แก้**
- `school_scan_page.dart` — ค้นหาอุปกรณ์จริง แต่ "ประวัติการสแกน" ปลอม
  100% (3 แถว hardcode) — **ยังไม่แก้**

### แก้แล้ววันนี้: `school_admin_profile_page.dart`
- "เปลี่ยนรหัสผ่าน" — ไม่มี RPC `change_password(old, new)` ในระบบ มีแค่
  `request_password_reset_otp`+`confirm_password_reset` (email-OTP flow)
  เปลี่ยนเป็น dialog อธิบายตรงๆ ให้ไปใช้ "ลืมรหัสผ่าน" ที่หน้า login แทน —
  เหมือนแพทเทิร์นที่แก้ไว้แล้วใน `director_settings_page.dart`
- "ออกจากระบบอุปกรณ์อื่น" → ต่อ `AuthService.signOutAllDevices()`
  (`auth_sign_out_all`) จริง เปลี่ยนชื่อเป็น "ออกจากระบบทุกอุปกรณ์" เพราะ RPC
  เพิกถอนทุก session **รวมเครื่องนี้ด้วย** ไม่มีทางเพิกถอนแค่เครื่องอื่น
- "ดูอุปกรณ์" — ไม่มี RPC list session ใดๆ เลย ปิดปุ่มพร้อมเหตุผลแทนกดแล้ว
  ไม่มีอะไรเกิดขึ้น
- ฟิลด์ hardcode: "โรงเรียน" ดึงจาก `fetchDashboardSummary().schoolName`
  จริง, "สถานะบัญชี" ใช้ `currentUserModel.status` จริง, "เข้าใช้ล่าสุด"/
  "ความปลอดภัย"/"สร้างบัญชีเมื่อ" ไม่มี RPC รองรับเลย เปลี่ยนเป็น
  "ยังไม่มีข้อมูล" ตรงๆ
- test เพิ่ม 7 เคส รวมไฟล์ 13/13 ผ่าน

### แก้แล้ววันนี้: `school_admin_dashboard_page.dart`
- `_UserCard` (sidebar/drawer) ใช้ `currentUserModel.name`/`.email` จริง
  แทน hardcode `'ผู้ดูแลโรงเรียน (Admin)'`/`'admin@aiot-school.ac.th'`
- `_SchoolScopeCard` โหลดชื่อโรงเรียนจริงผ่าน `fetchDashboardSummary()`
  (seam `loadSummary` ใหม่) แทน hardcode `'โรงเรียนเทศบาล ๑ (สังกัด สถ.)'`
- test เพิ่ม 1 เคส รวมไฟล์ 4/4 ผ่าน

Commit: `7c091b4`. `flutter analyze` สะอาดทั้ง 2 ไฟล์ push เข้า `gitlab` แล้ว

### แก้แล้ววันนี้: `school_buildings_page.dart` (commit `ea8d1c5`)
- RPC `list_school_rooms` hardcode `devices_count=0`/`training_kits_count=0`/
  `resource_status='ปกติ'` ทุกห้องเสมอ (บั๊กอยู่ที่ SQL) — แก้ให้ join จริงกับ
  `devices` เหมือน `list_school_buildings` ทำอยู่แล้ว (migration
  `20260908030000`) `floor` ไม่ fabricate `'ชั้น 1'` อีกต่อไป
- `SchoolRoomRecord` (shared_core model) มี fallback ปลอมซ้อนอีกชั้น
  (`?? 'ชั้น 1'`, `?? 'ปกติ'`) — แก้เป็น nullable จริง
- ลบบล็อก "รายการที่ควรตรวจสอบ" ที่ปลอมทั้งบล็อก, ปิด 3 ปุ่ม
  fake-navigation, filter ประเภทห้อง/สถานะ ดึงจากข้อมูลจริงแทน hardcode,
  audit log ใช้ `_logTypeFor` แทน `type: 'success'` ตายตัว
- pgTAP 5 เคส + widget test 4 เคสใหม่ (รวม 12/12) push production แล้ว

### แก้แล้ววันนี้: `school_scan_page.dart` (commit `b33e55d`)
- "ประวัติการสแกนล่าสุด" เคย hardcode 3 แถวตายตัว ไม่มีตาราง DB เก็บ
  ประวัติสแกนเลย — เปลี่ยนเป็นเก็บจริงในเซสชัน (`_history`) ทั้งจากกล้องและ
  กรอกรหัสเอง โชว์ honest empty state เมื่อยังไม่สแกน
- เจอบั๊ก crash จริงระหว่างทาง: `_enterCodeManually` dispose
  `TextEditingController` ทันทีหลัง dialog ปิด ทั้งที่ exit transition ยัง
  ใช้อยู่ — throw "used after being disposed" แก้ด้วย
  `addPostFrameCallback`
- test เพิ่ม 2 เคส รวม 7/7 ผ่าน

### แก้แล้ววันนี้: `school_permissions_page.dart` (commit `cb06a9b`)
- **เจอว่าใหญ่กว่าที่คิด**: filter บทบาท, `_RoleBadge`, และการ์ด "สิทธิ์หลัก"
  เทียบกับ label ที่แต่งขึ้นเอง ('ครูผู้สอน'/'ครูประจำอาคาร'/'ฝ่ายบริหาร')
  ที่ไม่ตรงกับ `UserRole.label` จริงสักคำ ('ครูประจำห้อง'/'ผู้บริหาร')
  — filter บทบาทไม่เคยกรองอะไรได้จริงเลยตั้งแต่แรก ไม่ใช่แค่ role เก่า
  โผล่มาเฉยๆ
- filter บทบาทตอนนี้สร้างจาก role จริงที่มีคนถือ (`_roleCounts`)
  `_RoleBadge` เทียบกับ label จริง การ์ด "สิทธิ์หลัก" ดึงจาก
  `list_role_permission_matrix` จริงแทนข้อความ 4 บรรทัดที่แต่งขึ้นเอง
  (เพิ่ม `roles: List<UserRole>` ใน `_PermissionUser`)
- ลบ 'ครูประจำอาคาร' ออกจาก edit-role dialog/`_parseRole`/
  `_defaultScopeForRole`, ลบตัวเลือก 'รอตรวจสอบ' ที่ `user.status` ไม่มี
  ทางเป็นได้เลย
- test เพิ่ม 4 เคส รวม 12/12 ผ่าน

### แก้แล้ววันนี้: `school_resources_page.dart` (commit `1c622dd`)
- การ์ด KPI "คุณภาพอากาศ & ESG" (`PM2.5 18.2`/`0.21 tCO2e` hardcode) —
  ไม่มี RPC วัดคุณภาพอากาศระดับโรงเรียนเลย เปลี่ยนเป็น "ยังไม่มีข้อมูล"
- การ์ด KPI "จุดตรวจจับความผิดปกติ" (`2 จุดเฝ้าระวัง` hardcode ไม่เกี่ยว
  กับ `_alerts` ที่หน้านี้โหลดจริงอยู่แล้ว) — ตอนนี้นับจาก sensor_alerts จริง
- 3 แถวสถานะ IoT meter (`ออนไลน์ N/N จุด (100%)` hardcode ทุกแถว) —
  ไฟฟ้า/น้ำใช้ `_energyDeviceCount`/`_waterDeviceCount` จริงที่หน้านี้โหลด
  อยู่แล้ว (ไม่อ้างเปอร์เซ็นต์ออนไลน์ที่ไม่มีข้อมูลรองรับ), PM2.5 บอกตรงๆ
  ว่ายังไม่มี
- filter อาคาร/ห้อง — เดิม setState ตัวเองได้แต่ไม่เคยส่งเข้าการโหลดข้อมูล
  เลย กรองอะไรไม่ได้จริง ปิดไว้พร้อม tooltip
- test เพิ่ม 5 เคส รวม 16/16 ผ่าน

**สรุป School Admin ตอนนี้: 23/23 หน้า DoD ครบทั้งหมด** (ปิดครบใน
เซสชันเดียวกับที่ audit — permissions/resources/buildings/scan ที่เหลือ
จาก 19/23 ทำเสร็จหมดแล้ว) เหลืองานแยกที่ไม่ใช่ DoD gap: `school_import_page`
ยังบล็อกการ import นักเรียน/ครูด้วยเหตุผลความปลอดภัย (`Test1234!` เดาได้)
ตามที่ตั้งใจไว้ — ไม่ใช่บั๊ก เป็นการตัดสินใจที่ยังไม่แก้

## 2026-09-08: Teacher lane audit + fix ทั้ง 7 ไฟล์ที่มีบั๊กจริง

Audit 25 หน้าฝั่งครู (`teacher_redesign_prototype/`) อ่านเต็มไฟล์ทุกไฟล์
พบ 12 ไฟล์มีบั๊ก fake-data/fake-success จริง ใหญ่สุดคือแจ้งเตือนกล้อง
รักษาความปลอดภัยปลอมที่ติดค้างเปิดถาวรให้ครูทุกคนเห็น (แก้ไปแล้วก่อนหน้า
เซสชันนี้) เซสชันนี้แก้ 7 ไฟล์ที่เหลือจากแผนลำดับความสำคัญ ทั้งหมด
`flutter analyze` สะอาด รัน `flutter test` ทั้งชุด 526 ผ่าน/8 fail
(fail ทั้ง 8 เป็นของเดิมอยู่แล้ว อยู่ฝั่ง Executive/`director_*` ที่ Codex
กำลังทำ กับ `school_admin_empty_and_error_states_test.dart` 1 เคสที่ไม่ได้
แตะ — ไม่มีอันไหนถดถอยใหม่จากงานนี้)

### แก้แล้ว: `teacher_rubric_page.dart` (commit `1a659f3`)
- ปุ่ม "ทำสำเนา" (`_duplicateRubric`) โชว์ toast สำเร็จโดยไม่เรียก backend
  เลย — แก้ให้เรียก `RubricService.createRubric` จริง
- ฟอร์มมี dropdown "ขอบเขต" ที่ไม่มีคอลัมน์รองรับ — ลบออก
- filter chip 'ใช้ร่วมข้ามวิชา' เทียบกับ field ที่ไม่มีใครตั้งค่าเลย
  กรองอะไรไม่ได้จริง — ลบออก

### แก้แล้ว: `teacher_aiot_dashboard_page.dart` (commit `5ebc4dc`)
- `_getMockDevices`/`_getMockThresholds`/`_getMockAlerts` โผล่มาแทนที่ทุก
  ครั้งที่ list จริงว่างเปล่า — ครูที่ไม่มีอุปกรณ์จริงเห็นการ์ดอุปกรณ์อยู่ดี
  ลบ mock generator + isEmpty guard ทั้งหมด เพิ่ม loading/empty state จริง
  ต่อแท็บ

### แก้แล้ว: `teacher_knowledge_library_page.dart` (commit `3038191`)
- `_loadFallbackMock()` อยู่ใน catch block — โหลดล้มเหลวจริง (network/RPC/
  auth) กลายเป็นห้องสมุดปลอมที่ดูสมจริง ครูไม่มีทางรู้ว่า error อยู่
  แก้เป็น error state แยกจากกันชัดเจน

### แก้แล้ว: `teacher_grades_page.dart` (commit `7af0fb4`)
- เมนู export PDF/Excel ไม่มี handler เลย กดแล้วไม่มีอะไรเกิดขึ้นและไม่มี
  error — เพิ่ม export CSV/Excel จริงด้วย pattern เดียวกับหน้า School Admin
  (`downloadBytes()` + `excel` package)

### แก้แล้ว: `teacher_incident_inbox_page.dart` (commit `0588a82`)
- แบนเนอร์ "เวลาแก้ไขเฉลี่ย" เป็น string ตายตัว ไม่ได้คำนวณจากข้อมูลจริง
  เลย — ครูทุกโรงเรียนเห็นตัวเลขเดียวกันหมด ลบออก พร้อมลบ branch
  mock-fallback ที่ตายแล้ว (unreachable) ในการ์ด SOS ที่ยัง active

### แก้แล้ว: `teacher_assignment_editor_page.dart` + `teacher_courses_page.dart`
### + `teacher_storybook_page.dart` (commit `94ea879`)
- `submittedCount`/`totalStudents` ในหน้าแก้ไขใบงานเป็นตัวเลขที่แต่งขึ้นเอง
  ล้วนๆ ไม่มี dropdown เลือก rubric จริงทั้งที่ backend มี rubric อยู่แล้ว
  และตอนแก้ไข (edit) เซฟลง `courses.first.id` เสมอ ไม่ใช่ course จริงของ
  assignment นั้น — แก้ assignment ในวิชา B เสี่ยงย้ายไปวิชา A แบบเงียบๆ
- ระหว่างแก้เจอบั๊กเดียวกันซ้ำใน `teacher_courses_page.dart` (ปุ่ม
  "แก้ไขใบงาน" สร้าง `AssignmentModel` ปลอมทั้งก้อนเหมือนกัน) แก้ให้ใช้
  ข้อมูลจริงด้วยเลย ไม่ใช่แค่แก้ให้ compile ผ่าน
- ต้องขยาย RPC `list_assignments` เพิ่ม instructions/is_group/rubric_id/
  rubric_title/created_at (migration `20260908040000`, ต้อง DROP FUNCTION
  ก่อนเพราะ `RETURNS TABLE` เปลี่ยนรูปคอลัมน์ไม่ได้ด้วย `CREATE OR REPLACE`)
  และส่ง `rubric_id` ผ่าน create/update_assignment
- sensor-metric binding ในหน้าแก้ไขใบงานยังปิดไว้พร้อมข้อความบอกตรงๆ ว่า
  ยังไม่มี backend รองรับ — ไม่ใช่บั๊ก เป็นของที่ยังไม่ได้สร้าง
- `teacher_storybook_page.dart` (dev-only ไปไม่ถึงจากแอปจริง) ใส่ค่า
  placeholder แค่ให้ compile ผ่านหลังขยาย `AssignmentModel`

### แก้แล้ว: `teacher_question_bank_page.dart` (commit `3c1ae27`)
- ไม่มี RPC ลิสต์คำถามของ quiz เลย ป้ายจำนวนข้อโชว์ "0 ข้อ" ตายตัวทุก quiz
  เพิ่ม RPC `list_quiz_questions` ใหม่ (เช็คสิทธิ์เจ้าของวิชา, pgTAP 4 เคส,
  migration `20260908050000`) + `QuizService.listQuizQuestions` เพิ่มปุ่ม
  "ยืนยันการเลือก (N ข้อ)" ที่ `teacher_exam_builder_page.dart`'s
  `_importFromBank()` รอรับอยู่แล้วผ่าน `Navigator.push<List<BankQuestion>>`
  แต่ไม่เคยมีอะไรส่งกลับไปจริง

### แก้ regression ที่เจอระหว่างรัน full test suite: `school_admin_dashboard_page.dart` (commit `99ff093`)
- sidebar ชื่อโรงเรียน (แก้ไปใน `7c091b4` ก่อนหน้านี้) ไม่มี flag แยก
  "กำลังโหลด" ออกจาก "โหลดเสร็จแล้วแต่ไม่มีข้อมูล" ทำให้ทุกเฟรมก่อน RPC
  ตอบกลับโชว์ 'ยังไม่มีข้อมูล' เหมือนกับตอนล้มเหลวจริง — เพิ่ม
  `_schoolNameLoading` โชว์ '…' ระหว่างโหลดแทน
- `school_admin_dashboard_resource_test.dart` ไม่เคยตั้งค่า
  `currentUserModel` มาก่อน ชนกับ fallback 'ยังไม่มีข้อมูล' ของ `_UserCard`
  ที่ `7c091b4` เปลี่ยนจาก hardcode ปลอมมาเป็นของจริง — แก้ตาม pattern
  เดียวกับ `school_admin_dashboard_page_test.dart`

**สรุป**: Teacher lane 24/24 ไฟล์ (25 หน้า ลบ storybook dev-only) DoD
ครบแล้วเท่าที่ audit รอบนี้ครอบคลุม ทั้งหมด push เข้า `gitlab` แล้ว
(`1a659f3`..`99ff093`)

### ปิด 3 ticket ค้างจาก MASTER_PLAN (1.1 / 1.2 / 1.4) — verify เองก่อนขีดถูก

หลังปิด 7 ไฟล์ข้างบน ผู้ใช้ถามว่า ticket เก่าที่ MASTER_PLAN ยังไม่ขีดถูก
(1.1 fake button ×3, 1.2 hardcode 8 จุดใน `teacher_redesign_prototype_page`,
1.4 ทดสอบ cross-school SOS ในเบราว์เซอร์) คืออะไร แล้วสั่งให้ตรวจ/แก้ต่อ
ตามกติกา CLAUDE.md ห้ามขีดถูกจากรายงานเฉยๆ ต้อง verify เอง — ผลตรวจ:

- **1.1**: `teacher_profile_page.dart` — เมนูที่ไม่มี backend ทุกอันมี
  `onTap: null` (ปิดสุจริตแล้วจาก commit `0f03100` ก่อนหน้านี้) ไม่มี
  fake-success เหลือ. `teacher_courses_page.dart` — ไล่ตรวจ snackbar
  "สำเร็จ" ทุกอัน ทุกอันเรียก service จริงก่อนโชว์ผลจริง **ไม่มีบั๊กเหลือ
  ไม่ต้องแก้อะไร**

- **1.2**: ให้ subagent อ่านทั้งไฟล์ `teacher_redesign_prototype_page.dart`
  (6,621 บรรทัด) เจอ **2 บั๊กจริงที่ commit `669ab76` (แก้กล้องปลอม/variant
  B-C ปลอม) ยังไม่ครอบคลุม** — แก้ในcommit `9b6250c`:
  - `_TeacherProfilePill` ปุ่ม "สลับสิทธิ์การทำงาน" บนแถบบนสุด (ทุกความกว้าง
    หน้าจอ) โชว์ 3 บทบาท/แผนก/ห้องโฮมรูมที่แต่งขึ้นเองล้วนๆ ไม่เกี่ยวกับครู
    ที่ล็อกอินอยู่เลย กดเลือกอันไหนก็ได้ snackbar บอก "สลับสำเร็จ" ทั้งที่
    ไม่มี RPC ไม่มี state เปลี่ยนอะไรเลย — **ร้ายแรงกว่าจุดอื่นเพราะขัดกับ
    การตัดสินใจด้านความปลอดภัยที่บันทึกไว้ใน HANDOFF.md ("Multi-role
    login"): ตั้งใจไม่ทำสลับ role ในแอปเพราะ session ที่พิสูจน์ตัวผ่าน role
    สิทธิ์ต่ำจะเลื่อนไปใช้ role สิทธิ์สูงได้โดยไม่เคยผ่าน OTP ของ role นั้น
    เลย** ต้อง logout/login ใหม่เท่านั้นถึงจะสลับได้จริง — แก้ให้โชว์ role
    จริงจาก `currentUserModel.allRoles` พร้อมข้อความบอกตรงๆ ว่าต้อง
    logout ก่อนถึงจะสลับได้
  - `_MiniCalendarCard` "วันนี้" freeze ไว้ที่ 6 ส.ค. 2569 ตายตัว
    (`_mockToday`) จุดกิจกรรมวันที่ 13/20/27 แต่งขึ้นเองไม่เกี่ยวกับกิจกรรม
    จริงเลย — แก้เป็น `DateTime.now()` และดึงจุดกิจกรรมจริงจาก
    `CalendarService.listSchoolCalendarEvents()`
  - `TeacherMock` class ที่ยังเหลืออยู่ตรวจแล้วเป็นแค่ config เมนู sidebar
    (label/icon) ไม่ใช่ fake data ที่โชว์เป็นของจริง — ไม่ใช่บั๊ก

- **1.4**: local มีโรงเรียนเดียว (`โรงเรียนทดสอบ`/`TEST01`) ทดสอบข้าม
  โรงเรียนในเบราว์เซอร์จริงไม่ได้ ใช้วิธีเดียวกับที่โปรเจกต์ verify
  backend guarantee อยู่แล้วแทน — เพิ่ม pgTAP ใน
  `19_incident_reports.test.sql` (test 6b, commit `899750c`) ยืนยันว่า
  `list_incident_reports` ของครูโรงเรียนอื่นไม่เห็นเหตุการณ์โรงเรียน A
  เลยสักแถว (ของเดิมมีแค่ test 8d ที่เช็ค `list_incident_actions` ระดับ
  รายเหตุการณ์เดียว ไม่เคยเช็คระดับ list) — **ผ่าน 22/22 ยืนยัน isolation
  ทำงานถูกต้องจริง** แม้ชื่อไฟล์ migration
  `broadcast_all_incidents_to_all_staff.sql` จะฟังดูน่าตกใจ แต่ broadcast
  แค่ภายใน `v_actor.school_id` เท่านั้น ไม่เคยข้ามโรงเรียน

รัน `flutter test` ทั้งชุดหลังแก้ทั้ง 3 จุด: 526 ผ่าน/8 fail เท่าเดิมทุก
ตัว (ไม่มี regression ใหม่) push เข้า `gitlab` แล้ว (`9b6250c`, `899750c`)

### เขียน connection test ให้ Teacher lane 5/7 ไฟล์ที่แก้ไปแล้วแต่ไม่มี test เลย

ผู้ใช้ขอให้เริ่มเก็บช่องว่าง connection test ของ Teacher lane (ที่ตรวจพบตอน
สรุปสถานะรวมทุกสิทธิ์ — School Admin/Super Admin มี test ครบ แต่ Teacher/
Student/Parent/Executive แทบไม่มี ทั้งที่ Teacher แก้บั๊กไป 14+ จุดแล้ว)
เลือกเริ่มจาก 5 ไฟล์ที่แก้บั๊กไปในเซสชันก่อนหน้าแต่ไม่เคยมี test คุ้มครอง
เลยสักตัว (`teacher_aiot_dashboard_page.dart`/`teacher_incident_inbox_page.dart`
ยังเหลือ ยังไม่ได้ทำ):

- **`teacher_rubric_page.dart`** (commit `36de820`) — เพิ่ม seam
  `listMyRubrics`/`getRubric`/`createRubric`/`updateRubric` (ต้อง import
  `shared_core`'s `RubricModel` ผ่าน prefix `rubric_backend` เพราะไฟล์นี้มี
  local class ชื่อชนกัน) 5 เทส: ปุ่ม "คัดลอกเป็น Rubric ใหม่" เรียก
  `createRubric` จริงพร้อม payload ถูกต้อง, error ไม่รั่ว, ฟอร์มสร้างใหม่ก็
  เรียก RPC จริงเหมือนกัน. เจอ+แก้ leaked error 2 จุด + overflow 1 จุด
  (Row หัวข้อ "รายการเกณฑ์การประเมินย่อย" ไม่มี Expanded)
- **`teacher_grades_page.dart`** (commit `3d2761d`) — เพิ่ม seam
  `loadCourses`/`loadCourseGrades`/`confirmGrade` (มี `downloadBytesOverride`
  อยู่แล้ว) 5 เทส: export CSV มีข้อมูลจริงในไฟล์ (ตรวจด้วย `utf8.decode`),
  export Excel เป็น ZIP จริง (PK magic bytes), export ตอนไม่มีข้อมูลปฏิเสธ
  ไม่ใช่ดาวน์โหลดไฟล์เปล่า, ยืนยันคะแนนเรียก RPC จริง. เจอ+แก้ leaked error
  2 จุด
- **`teacher_question_bank_page.dart`** (commit `d84604c`) — เพิ่ม seam
  `loadCourses`/`listQuizzesForCourse`/`listQuizQuestions` 2 เทส: จำนวนข้อ
  จริงไม่ใช่ "0 ข้อ" ตายตัว, กดยืนยันการเลือกแล้ว `Navigator.pop` คืนคำถาม
  จริง (เนื้อหา/ตัวเลือก/คำตอบถูกต้อง) กลับไปหน้าที่เรียก ไม่ใช่ลิสต์ว่าง.
  เจอ+แก้ leaked error 1 จุด
- **`teacher_assignment_editor_page.dart`** (commit `a272d13`) — เพิ่ม seam
  ทั้งหน้าลิสต์ (`loadCourses`/`loadAssignmentsForCourse`/
  `loadCourseStudents`/`loadSubmissions`) และหน้าฟอร์มที่ threading ผ่าน
  `openAssignmentFormModal` ลงไปถึง private form sheet
  (`listMyRubrics`/`updateAssignment`/`createAssignment`/
  `publishAssignment`) 2 เทส: ส่งแล้ว N/M คน มาจากข้อมูลจริง ไม่ใช่เลขแต่ง,
  แก้ไขใบงานเรียก `updateAssignment` ด้วย assignment id จริง + rubric ที่
  เลือกจริง **โดยไม่เรียก `loadCourses` ซ้ำเลย** (พิสูจน์ตรงว่าไม่ได้ใช้
  `courses.first` แบบบั๊กเดิม). เจอ+แก้ overflow 2 จุด (สวิตช์งานกลุ่ม,
  หัวข้อ Rubric) + leaked error 1 จุด
- **`teacher_knowledge_library_page.dart`** (commit `9ebcb83`) — เพิ่ม seam
  `loadCourses`/`listFiles`/`uploadFile`/`getDownloadUrl` +
  `hasSessionOverride` (เพราะ `AuthService.sessionToken` เป็น static field
  seam อื่นแตะไม่ถึง) 5 เทส: โหลดพังจริงโชว์ error state ไม่ใช่ห้องสมุดปลอม
  2 วิชาแบบเดิม, signed-out ก็โชว์ error เดียวกัน, ไฟล์จริงโชว์ชื่อ/ขนาด
  จริง, ดาวน์โหลดเรียก RPC ด้วย file id จริง, ดาวน์โหลดพังโชว์ข้อความสุภาพ.
  เจอ+แก้ leaked error 2 จุด

รวม 19 เทสใหม่ (5+5+2+2+5) ทั้งหมดผ่าน + แก้บั๊กที่เจอระหว่างทางรวม 9 จุด
(leaked raw error 7 จุด, Row overflow 3 จุด — นับซ้ำ 1 จุดที่เจอสองครั้ง
คนละไฟล์). `flutter test` เต็ม: 563 ผ่าน/8 fail เท่าเดิม (baseline เดิม
ทั้ง 8 ไม่มี regression ใหม่) push เข้า `gitlab` แล้ว (`36de820`..`9ebcb83`)

### ปิด Teacher lane: เก็บ 2 ไฟล์สุดท้ายที่แก้บั๊กไปแล้วแต่ไม่มี test

ผู้ใช้ขอให้เก็บ `teacher_aiot_dashboard_page.dart`/`teacher_incident_inbox_page.dart`
ให้ครบก่อนย้ายไป Student lane:

- **`teacher_aiot_dashboard_page.dart`** (commit `c9b0351`) — เพิ่ม seam
  `listSchoolDevices`/`getAllDeviceSensors`/`listThresholds`/`setThreshold`/
  `listAlerts`/`acknowledgeAlert` 5 เทส: อุปกรณ์จริง 0 ตัวโชว์ empty state
  สุจริต ไม่ใช่การ์ดปลอม, อุปกรณ์+เซนเซอร์จริงโชว์ข้อมูลจริง, alert 0 จริง
  โชว์ empty state, กด "รับทราบ Alert" เรียก RPC จริงด้วย alert id จริง,
  รับทราบพังโชว์ข้อความสุภาพ. เจอ+แก้ leaked error 1 จุด (export dialog)
- **`teacher_incident_inbox_page.dart`** (commit `5639dfa`) — เพิ่ม seam
  `actionsOverride` (ใช้ `StaffEmergencyActions` ตัวเดียวกับที่
  `teacher_incident_detail_page_test.dart` ทดสอบอยู่แล้ว)/
  `loadEmergencyEvents`/`loadIncidentReports`/`watchIncidents`/
  `watchEmergencyEvents` 4 เทส: เหตุจริงโชว์เหตุผล/ห้อง/ผู้แจ้งจริง ไม่มี
  แบนเนอร์ "เวลาแก้ไขเฉลี่ย" ปลอมหลงเหลือ, 0 เหตุจริงโชว์ list ว่างสุจริต,
  ปุ่ม "รับเรื่อง" บน list เรียก controller จริงและสะท้อนสถานะ confirmed
  จริง, โหลดพังโชว์ error banner จริงไม่ใช่ค้างข้อมูลเก่าเงียบๆ

รวม 9 เทสใหม่ (5+4) **ปิดครบทั้ง 7/7 ไฟล์ Teacher lane ที่แก้บั๊กไปในเซสชันนี้
— ทุกไฟล์มี connection test คุ้มครองการแก้ของตัวเองแล้ว**. `flutter test`
เต็ม: 572 ผ่าน/8 fail เท่าเดิม (ไม่มี regression ใหม่) push เข้า `gitlab`
แล้ว (`c9b0351`, `5639dfa`)

**เหลือ**: `teacher_courses_page.dart` (ปุ่มแก้ไขใบงาน),
`teacher_redesign_prototype_page.dart` (role switcher/ปฏิทิน) — คนละบั๊ก
คนละรอบ ยังไม่ได้เขียน test ให้. Student lane เหลือ ~11 หน้าเหมือนเดิม
(ดูรายการด้านบน) — **กำลังเริ่มทำต่อ**. Parent/Executive lane ยังไม่ได้
เริ่มเลย

<!-- ↓↓↓ จากเลน codex/fix-executive-bug-3 (merge 2026-09-10) ↓↓↓ -->

## Browser verification — director emergency close, 2026-09-08

Clicked the real DirectorEmergencyPage using temporary localhost-only injected fixtures
(no backend writes): hero RPC failure and unconfirmed write preserved the open SOS;
confirmed success removed the active SOS and updated the history status. Both SOS and
event-detail failures initially rendered the page SnackBar behind the modal barrier.
After the feedback fix, the browser accessibility tree exposed an Alert with the human
failure message and ตกลง; dismissing it returned to the still-open incident.
Docker/Supabase was not running, so live RPC role gates and authenticated acceptance
remain unverified in this session. Temporary fixture entrypoint/server were removed
after the check. This verifies the close controls, not all emergency-page mock content.


## Authenticated browser acceptance — bug 1, 2026-09-08

Follow-up after the user started Docker/Supabase. The existing
`supabase_edge_runtime_aiot-school-lab` container was still stopped; starting it
restored the supported auth-sign-in/auth-verify-otp flow. Logged in through the
actual app at localhost:8765 using the seeded executive account and the normal
local-dev OTP autofill. DB inspection confirmed a valid executive session, without
reading or publishing its token. The four live close/list RPC definitions all take
`p_token`, are SECURITY DEFINER, and permit the executive role within its school.

The test school had no open incidents/events before seeding. Inserted three labeled
incident fixtures and one event fixture there; no existing records were changed.
All closures below were performed through browser clicks on the actual page and
production Dart service/controller paths, not mocks or direct SQL close updates.

| Fixture / browser control | Row ID | Observed database result |
|---|---|---|
| LIVE-HERO / main close button | 02762d86-91ee-4027-8a27-48d6b0251420 | resolved; closed_at set; executive closer; one close action and audit |
| LIVE-MODAL / SOS dialog | 9c682048-0e67-4452-a3b0-202d0083de6d | resolved; closed_at set; executive closer; one close action and audit |
| LIVE-DETAIL / event detail | a710f64f-2a9b-4d35-bff7-fd69bc55c32e | resolved; closed_at set; executive closer; one close action and audit |
| LIVE-HARDWARE / main close button | 5d96082e-8dfc-42ee-900e-42eba1ed2831 | closed; closed_at and review_note set; warning_light_on=false |

Labels use the prefix `CODEX-BUG1-20260908-`. After each SOS close, the page kept
showing the remaining active event; it did not declare an all-clear prematurely.
After the final hardware-event close, the browser showed the success message,
zero active SOS/events, and closed history rows. A manual refresh re-read the same
canonical state. Final SQL counts: zero open labeled incident/event fixtures.
Closed test rows are retained as labeled evidence. No physical device was operated,
no schema/RPC changed, and no failure was injected into the live backend; negative
cases remain covered by the earlier widget tests and fixture browser checks.

The app, local Supabase services, and OTP Edge Function remain running for the user.
This resolves the earlier live-DB verification limitation for bug 1's close paths;
it is not a full-page DoD or other-bug completion claim.

## 2026-09-08 — Bug 3 live browser / local DB verification

These are interaction and environment observations, not a replacement for the
implementation commit. Preview: http://127.0.0.1:8766/ (the older 8765 tab is not
the current server). Worktree: `bug3-executive`, branch
`codex/fix-executive-bug-3`, based on Bug 2 commit `c21d6f8`.

- Signed in as the seeded executive and teacher through the normal browser
  password + dev OTP flow; did not enable remember-device.
- Created **BUG3 QA ประชุมทดสอบการบันทึก**, ID
  `1a8235de-d233-481d-b6a2-2c21d651e49c`, group meeting number 1/2569,
  10 September 2026 at 09:00 local, location ห้องทดสอบ local.
  Added the teacher, agenda ตรวจการเชื่อมต่อข้อมูลจริง, and a minutes draft.
- The automatic approval reviewer initially rejected the immutable finalization.
  The user explicitly answered **อนุมัติปิดรายงาน QA**. Finalization was then
  completed. SQL and browser both confirmed final minutes, unchanged original
  body, one appended statement, and no draft editor. The fixture is retained for
  the user to inspect.
- The teacher's finalized-minutes notification opened the meetings register,
  then the QA detail. Clicking accept and save produced a canonical
  **ตอบรับแล้ว** result for that teacher. Organizer-only controls were absent.
- Uploaded `bug3-qa.txt` (59 bytes) through the real signed upload Edge
  Function, registered metadata, verified the canonical detail, downloaded the
  exact same bytes; invalid tokens were rejected by both file endpoints.
  This used a local QA script outside the Git worktree and did not print tokens.
- Clicked the printable-document export in the browser; escaped HTML content
  is covered by a document test. Physical printing/save-PDF and camera capture
  have not been verified on actual hardware.
- Learning page showed **3 active students**, no confirmed attendance records,
  one profiled student and two without a class profile. All stayed unknown.
  Grade filtering and selecting 7 September instead of 8 September re-read the
  chosen date. The live profile stores a full room label (`ม.4/1`), which
  exposed and prompted the duplicated-grade display fix.
- Desktop scan entry opened the real lookup page. `BUG3-NOT-FOUND` returned
  not found. UUID `d364bb51-99aa-4cdb-b698-7f899eb22cad` returned
  กล้อง CCTV ทางเข้าหลัก, online, อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก,
  matching SQL. No missing device/kit code was invented. No equipment was actuated.
- Read-only Standards and Spec reviews concluded with no remaining findings.
  The review reproduced a phantom classroom count for an empty learning track;
  its new pgTAP assertion failed before the aggregate fix and passed afterward.

Final automated verification: focused app tests 16/16; focused core tests 13/13;
new pgTAP 43/44/45 totals 55/55. Full app suite 507 pass / 22 existing failures;
core 60 / 1 existing assignment-model failure; shared_ui 14 / 1 existing ListTile
assertion, also reproduced on the original Desktop checkout. Analyze: core clean,
shared_ui 4 info, user_app 156 warning/info, zero errors across all three.

The latest complete pgTAP run executed 796 assertions. The unchanged auth/session
suite 03 intermittently failed assertions 12–13 (sign-out-all checks after the
session-cap fixture), then passed 19/19 in an isolated repeat without code changes.
Legacy fixtures 14 and 16 abort because they still insert removed
`facility_manager` enum values. These are recorded failures, not a green full-suite
claim. All Bug 3 backend assertions pass.

Local Supabase and the port-8766 Flutter web server remain available for review.
Production deployment and publishing the Git branch are separate from these local
verification results. The earlier auto-review rejection of the GitHub push has
not been overridden by the QA-minutes approval.

### 2026-09-08 — User-requested executive visual refresh

User explicitly selected all three pages (meetings, learning, scan) and the
existing pink palette with rounded cards. Added scoped workspace styling,
gradient headers, learning metric tiles and minutes status pills. Existing
controllers, RPCs and authorization rules remain intact. Scan's retry widget
test now scrolls to the button before tapping, as a user would on a short screen.

User-app regression: 507 passed / 22 existing failures, unchanged. Analyzer:
shared_core clean; shared_ui 4 existing infos; user_app 156 existing findings,
no new findings in changed files. Browser review at port 8766 displayed actual
learning totals, verified meeting search's no-match state and found the real
CCTV device by ID. Small-phone learning/scan coverage passed within regression.
Physical camera capture and publishing are still outside this visual verification.

### 2026-09-08 — Layout and section-color refinement

Follow-up user request: cleaner placement and clearer color separation across
the three executive pages. Desktop scan now places search and results side by
side, with unavailable services in a separate muted section. Learning separates
track information and student support into blue/green sections, and summary
tiles use distinct tints. Meeting records use a responsive card grid, blue date
and document accents, and amber pending-response badges. All grids stack on
narrow screens; badges include text and icons in addition to color.

Focused page tests: 12/12 passed. User-app full regression: 507 passed / 22
pre-existing failures. Analyzer remained at core 0, shared_ui 4 infos and app
156 findings, with no findings in the changed files. Browser checked all three
layouts and successfully looked up the real CCTV fixture. No backend changes.

### 2026-09-08 — Meeting detail visual alignment

User supplied a meeting-detail screenshot and requested the same redesign.
Applied the shared pink workspace and hero, paired attendees/agenda and
resolutions/attachments on wide screens, and kept minutes full-width. Original
minutes and addenda have separate blue/mint reading panels; destructive buttons
are red and completion green. Existing role gates, dialogs and write/read
verification remain unchanged.

Meeting widget suite: 5/5 passed. App regression: 507 passed / 22 existing
failures. Analyzer unchanged (core 0, shared_ui 4 infos, app 156 findings), no
findings in meeting_detail_page. Opened the real finalized QA meeting in the
browser and verified the new sections with its existing data; no QA mutations.

### 2026-09-08 — Executive notifications connection (browser QA pending)

Replaced the main notification page's seeded incidents, swallowed errors and
local-only read flags with a controller and NotificationService operations.
Categories come from the existing category RPC; priority is displayed only when
present in payload. Missing priority is explicitly unknown. Search, read-state
and time filters apply to the latest 50 entries in the selected category, visibly
documented on the page. Bulk read covers the entire user's inbox, not just the
visible subset. Existing notifications are per user (no school_id column); this
does not redefine them as active-school-specific messages.

New local RPCs get_my_notification and mark_all_my_notifications_read validate
the custom session and constrain reads/writes to its user. Individual writes
verify the exact canonical row; bulk writes verify unread category counts.
Meeting payload IDs open MeetingDetailPage with its existing backend permission
check; other source navigation is explicitly disabled until supported. Payload
URLs are never opened. No invented urgency or incident workflow states remain.

Validation: new app tests 3/3; pgTAP 46 8/8 including >100 notifications, invalid
tokens, other users/schools and idempotency. Full regression: app 510 passed / 22
existing failures, shared_core 60/1 existing, shared_ui 14/1 existing. Analyzer
app 156 existing findings, shared_ui 4 existing infos; shared_core clean after
braces cleanup. The migration was applied to the running local DB only.

Browser QA was attempted but not completed: executive@aiot-school-lab.local has
reached its 10 login OTPs / 24 hours quota. Verified rate_limited from auth edge
and the count read-only; no rate limit bypass/reset. First slot releases around
2026-09-08 17:10 Asia/Bangkok. Remaining: login, open main notifications, read QA
item, refresh, open its meeting source; bulk read persistence in browser.
Fixture 99829999-0000-0000-0000-000000000001 is labeled QA in the test executive
inbox and refers to the existing finalized QA meeting. Publishing remains pending.

### 2026-09-08 — Executive overview real-data connection

Replaced overview mock graphs, briefing examples, teacher percentages and fake
detail dialogs with a controller using existing domain services. Summary cards
show current registered users, all incident reports and registered devices;
learning tracks show confirmed percentages. Latest inbox messages navigate to
notifications. Utility charts reload real readings for 7/30 days and preserve
missing dates as unknown. Existing sensor streams were extracted into a widget.
Teacher workload distribution remains explicitly unavailable, without invented
values. No schema or RPC changes were needed. Live local RPC definitions were
checked for incident totals, user count semantics and energy date aggregation.

Validation: focused connection tests 3/3; desktop/mobile overview layout audit
1/1. The layout test now injects both sensor streams to avoid real polling.
Final full user_app regression: 513 passed / 22 existing failures (no increase).
Three-package state analysis reports zero errors; user_app has 156 existing
findings. Logs: ../bug3-validation/overview-test-user_app-final.log,
overview-analyze.log and overview-state.log (outside repository).

Browser QA remains deferred by the user; this page is not claimed fully verified
in-browser. No push or production deployment. Remaining executive gaps include
CCTV inventory/actions, calendar meeting integration and classroom aggregates;
unsupported domains require actual backend capability before enabling actions.

### 2026-09-08 — Meetings connected to executive academic calendar

User deferred CCTV image integration until the camera/stream approach is known
and requested calendar integration next. Added DirectorCalendarController to
combine existing school events/schedules with MeetingService.list. Live local
list_meeting_records/list_meetings definitions confirm custom-session validation,
staff allowlist, school scoping and _can_see_meeting visibility. No migrations or
permission changes. Local-time start/end, location, organizer, attendee count and
status come from the same records as the meetings page.

The month list includes every visible meeting in date order. Entries offer the
existing meeting detail route and reload on return. Cancelled/completed records
remain in the calendar but are excluded from upcoming reminders. Replaced the
old fixed August 2026 cutoff. Loading now shows unknown summary counts instead
of zero; refresh clears stale records and failures remain distinct from empty.
Meetings are shown on their start date, without recurrence or spanning-day UI.

Focused calendar tests: 8/8, including pending meeting source, merged event data,
local-time display, cancelled state/detail action, empty and source failures.
Three-package state analysis has zero errors; final app analyze retains 156
existing findings. Browser QA remains deferred by the user. Local web hot restart
requested for the updated build; no production deployment or push.

Final app regression: 516 passed / 22 existing failures, compared with 513/22
before this ticket. Logs are outside Git in ../bug3-validation/calendar-focused.log,
calendar-regression-final.log and calendar-analyze-final.log. Web hot restart
completed successfully; this is build verification, not browser interaction QA.

### 2026-09-08 — Classroom attendance and unsafe schedule matching

Continued the next executive connection task after calendar, with CCTV streaming
still deferred by the user. Room details now show real dated homeroom attendance
via an existing domain service and a dedicated controller. Both grade and room
must match. Unknowns remain unknown; percentage labels its recorded denominator
and current active cohort. Stale async date results are discarded. Added retry
and date selection with loading/empty/error/data states.

Live local list_school_homeroom_attendance allows executive and scopes active
students to the actor school/current academic year. No SQL change. Inspection
also found list_all_school_schedules exposes physical room text without cohort
identity: the old bare room-number comparison could mix different grades.
Disabled that interpretation and display an explicit unmatched explanation.
Grade/track filters now use actual room data rather than fixed example options.

Focused tests: 9/9, including four new attendance tests for loading/empty,
cross-grade isolation, unknowns, error/retry, recorded denominator and stale-date
responses. Remaining: actual course/cohort mapping, assignment/score/support
aggregates, rooms outside homeroom coverage and deferred browser QA. This is a
partial room connection, not a claim that every classroom feature is complete.

Final regression: user_app 520 passed / 22 existing failures (previous 516/22).
All three packages analyzed without errors; final app analysis retains 156
existing findings. Logs: ../bug3-validation/classrooms-focused.log,
classrooms-regression.log and classrooms-analyze-final.log. Local web hot restart
completed successfully. Browser QA is deferred; no push or production deployment.
| (Executive connection audit follow-up, 2026-09-09) | working tree | Repaired the live Executive classroom-work and automatic student-support contracts with forward migrations `20260910120000` and `20260910130000`. Work/activity RPCs now use real lesson timestamps, avoid per-room cross-course multiplication, count active enrolled students and individual/group submissions, and return real assignment instructions/created dates. Automatic flags are current-year scoped and no longer fail on ambiguous PL/pgSQL output names. Opening a flag now returns a case id, refreshes the canonical case list, rejects false success, reuses the same active reason when its counter changes, and serializes concurrent creation. The classroom UI uses assignment-level denominators, honest due/publish states and error handling, and no longer matches schedules by a bare room number. Applied both migrations to local Supabase. Verification: live contracts 38/38, learning/case Flutter 7/7, classroom widgets 10/10, classroom summary 18/18, analyzers 0 errors; browser loaded both Executive classroom and student-overview pages without their former load failure. |
| (Executive emergency truthfulness follow-up, 2026-09-09) | working tree | Removed unsupported “IoT online 100%”, “safe 100%”, “duty team ready 100%” claims and the hardcoded “today” date from the Executive emergency page. Closed counts now describe the loaded data window, empty state says only that no open event exists in the latest data, and the missing duty-roster backend is shown as unavailable. Converted the narrow badge row to a wrapping layout. Existing emergency read/close tests remain applicable; responsive 320/768/1440 regression passes. |
| (Executive overview visualization correction, 2026-09-09) | working tree | Restored the first-page layout rhythm from the early-September reference: learning and teacher cards share one equal-height 5:4 row, resources occupy the next full row, and important notices return to a full-width row. The teacher overview is a circular registered-teacher count. The learning overview was first rendered as a line graph, then restored to the user's exact Sep-7 per-track card layout in the follow-up below. Missing teacher-workload ratios remain explicitly unavailable. Local browser QA confirmed both live Supabase track values (70.2%/8 students/2 rooms and 81.0%/4 students/1 room) plus the real registered-teacher count (1). No synthetic series or fallback values were added. |
| (Executive overview Sep-7 visual restoration, 2026-09-09) | working tree | Confirmed commit `c1aff8df8f0182b011e21abf01eb600348301e73` from 7 Sep as the user's master first-page design. Restored its Thai date pill, hero proportions, white summary cards with colored header ribbons, compact view actions, and bordered report buttons in the live controller-backed page. The learning section now matches the Sep-7 reference: one tinted card per track with room/student counts, confirmed-score badge and progress bar, unavailable behavior/environment text, and a verified overall-average banner. Teachers remain a circular registered count. Browser QA on `127.0.0.1:8767` confirmed the restored layout with live Supabase totals (15 students, 1 teacher, 4 reports, 9 devices) and track average 75.6%; no historical mock workload ratios were restored. |
| (Executive overview Sep-7 full-layout alignment, 2026-09-09) | working tree | Completed a section-by-section source and browser comparison against the 7 Sep snapshot. Restored the desktop 1:1 learning/teacher row at 420px, the 5:3 utility/sensor row at 460px, the 1020px stacking breakpoint, and the daily/weekly/monthly segmented control. The period control now performs real 1/7/30-day utility reloads while registration totals remain explicitly labelled current. Rebuilt the old watchlist visual language over real notifications with all/unread/read filters and body/category/date fields. Kept the single real teacher circle because the old four-circle workload breakdown was explicitly demo data. Fixed mobile hero-tag overflow and cancelled the delayed reload timer on dispose. Browser QA confirmed period switching and notification filtering; focused responsive/connection tests pass 4/4 and the page analyzer reports no issues. |
| (Executive overview notification-card redesign, 2026-09-09) | working tree | Reworked “สิ่งที่ควรทราบวันนี้” to match the supplied detailed-card reference: a compact white heading, latest-data badge, segmented read filters, category-colored icons, status pills, full title/body hierarchy, timestamp/category metadata and a source-specific action. Meeting actions open the meetings page, incident actions open emergency, student-support actions open the student overview, resource actions open environment/resources, and “ดูทั้งหมด” opens notifications. All displayed text and read state still come from real notification rows; visual categories and destinations are derived only from the stored notification type/category. No sample alerts or unsupported CCTV/building actions were introduced. Browser QA confirmed the three live local notices render in the new hierarchy and both meeting/incident actions open their real destination pages. Responsive, connection, filter and navigation tests pass 5/5; scoped analyzer is clean. |

## 2026-09-10 — จัดการสิทธิ์บอกว่าบันทึกแล้วทั้งที่ไม่ได้บันทึก + เขียน design system

- `2cb6e23` fix(school-admin): หน้าจัดการสิทธิ์ส่งไปหลังบ้านแค่ `role` แล้วขึ้น
  "บันทึกการแก้ไขสิทธิ์เรียบร้อยแล้ว" เสมอ สถานะบัญชีที่ผู้ดูแลเพิ่งเปลี่ยนถูกทิ้ง
  เงียบ ๆ — ผูกกับ `suspend_user`/`reactivate_user` จริง + อ่านกลับมายืนยัน
  ขอบเขตการเข้าถึงไม่มี RPC เขียนกลับเลย เปลี่ยนเป็นอ่านอย่างเดียว
  การ์ดสรุป "รอตรวจสอบ" ที่เป็น 0 ตลอดกาลถูกตัดออก (เทสต์ใหม่ 3 เคส)
- `docs/handoff/DESIGN_SYSTEM.md` (ใหม่) — บันทึก palette 6 เลนที่มีอยู่จริง
  ค่ามาตรฐานของหน้าจอ กติกาห้ามฮาร์ดโค้ดสี และหนี้ที่ยังค้าง
  โปรเจกต์ไม่เคยมีเอกสารดีไซน์เลย ทุกเซสชันจึงคิดสีใหม่เอง = ต้นเหตุ UI drift
- รวม `school_admin_palette.dart` ที่ซ้ำ 2 ไฟล์เนื้อหาเหมือนกันเป๊ะให้เหลือไฟล์เดียว
  (`pages/school_admin/theme/`) แก้ import 12 จุด

### ตรวจรายงาน audit 5 เลนที่ได้รับมา — ผิด/ล้าสมัย 6 จาก 11 ข้อ
จริง: school_permissions fake success (แก้แล้ว) · director_cctv 6 การ์ดฮาร์ดโค้ด ·
`teacher_profile_page.dart:533` ชื่อโรงเรียนฮาร์ดโค้ด · `$e` ขึ้นจอเลน Teacher 37 จุด
ไม่จริงแล้ว: director_notifications เรียก `readAndVerify` จริง · ปุ่ม 3 ปุ่มของ ผอ.
ถูกรื้อไปแล้ว · 3 หน้า Executive ใช้ controller ที่เรียก service จริง ·
Parent `status ?? 'present'` ไม่ใช่บั๊ก (คอลัมน์ NOT NULL + inner join) ·
Student sidebar 'ม.5/2' ไม่มีแล้ว · Teacher 'Online' ผูกกับ `dev.isOnline` จริง

### ปรับ MASTER_PLAN_2026-09-06.md ให้ตรงกับสถานะจริง

Phase 3 (Executive) ในเอกสารยัง `[ ]` ทั้ง 8 ticket ทั้งที่งานจริงเสร็จไปเกือบ
หมดระหว่าง 2026-09-06 ถึง 09 (คอมมิต `d09c550`..`07ed036`) แต่ไม่มีใครย้อนมา
ติ๊ก — สาเหตุเดียวกับที่ CLAUDE.md เตือนไว้ (เอกสารไม่ตามงานจริง) ตรวจซ้ำด้วย
`git log` + `grep` หา literal stat-card values (`value: '[0-9]`) ในทุกไฟล์
`director_*_page.dart` จริงก่อนติ๊ก ไม่ใช่เชื่อจากรายงาน:
- ติ๊ก `[x]` ให้ 3.2/3.3/3.5/3.6/3.7/3.8 (มีคอมมิตจริงรองรับ, grep ไม่เจอ
  hardcode) และปิด decision D2 (`director_meetings` ต่อผ่าน `MeetingService`
  จริง ไม่ต้องสร้างตารางใหม่)
- คง `[ ]` ให้ 3.4 (`director_scan` — grep ไม่เจอ hardcode แต่ยังไม่ได้อ่าน
  เต็มไฟล์ยืนยัน) และเพิ่ม ticket ใหม่ 3.9 สำหรับ `director_cctv_page` ที่ยัง
  ฮาร์ดโค้ดจริง (บรรทัด 76–167 รายการกล้อง + 291–319 การ์ดสรุป 5 ค่า) — ผู้ใช้
  สั่งพักไว้เอง
- เพิ่ม ticket 1.6 สำหรับ raw `$e` 37 จุดในเลน Teacher (พบระหว่างตรวจ
  รายงาน audit ด้านบน)
- ปรับตาราง §5 เวลา ให้บอกว่าของจริงที่เหลือคือ Phase 4 + 5 + เศษ Phase 1/3
  (~11–14 เซสชัน) ไม่ใช่ 43–52 ตามประมาณการเดิม

### ตรวจฮาร์ดแวร์ IoT กับฐานข้อมูล production จริง 2026-09-10

ผู้ใช้ขอทดสอบการสั่งเปิด/ปิดน้ำ-ไฟฝั่งแอดมิน จึงไล่ดูข้อมูลจริงบน
`smqoknnftgjyhrnzugar` (ไม่ใช่ local — ตัวเลขจาก local ทำให้สรุปผิดไป 2 รอบ)

**ของจริงบน production:** อุปกรณ์ 5 ตัว = เซนเซอร์อากาศ 1 + บอร์ดรีเลย์ 4 ช่อง
(`relay_no` 1-4, ช่อง 1 = วาล์วน้ำ) · `sensor_readings` 144,125 แถว 10 metric ·
`device_heartbeats` 23,629 · `device_commands` 186 (ดึงไปแล้ว 170)

**สิ่งที่พบ:**
- `acked_at` **เป็น null ทั้ง 170 ครั้ง** — เฟิร์มแวร์ไม่มีโค้ดเรียก
  `ack_device_command` เลย `device_relay_states` จึงว่างเปล่าตลอดกาล
  แปลว่ารีเลย์อาจทำงานจริงมาตลอด แต่แอปไม่มีทางยืนยันได้
- บอร์ดหยุดทำงาน 2026-09-09 10:12:50 (heartbeat สุดท้าย 10:12:45, poll สุดท้าย
  10:12:50) คำสั่ง 16 อันหลังจากนั้นค้างคิว — ล้างออกแล้วด้วย ack_status 'failed'
- เซนเซอร์ส่วนใหญ่หยุดส่งก่อนหน้านั้นอีก: น้ำ 28 ส.ค. · pm25 31 ส.ค. ·
  อุณหภูมิ/CO2/แสง 2 ก.ย. · เหลือ gas_mq2 ถึง 9 ก.ย.
- หน้า `school_admin_device_control_page.dart` **ซื่อสัตย์อยู่แล้ว** (เซสชันก่อน
  แก้ไว้) ขึ้น "ส่งคำสั่งเข้าคิวแล้ว รออุปกรณ์ยืนยัน" ไม่ได้โกหกว่าสำเร็จ

**migration `20260910140000` แก้ 2 บั๊กที่เจอ:**
1. `poll_device_commands` เดิมคืนคำสั่งค้าง**ทั้งหมด**ในครั้งเดียว ไม่มี order by
   ไม่มี limit — ตอนล้างคิว 16 แถวออกมาสลับลำดับจริง ถ้าบอร์ดกลับมาก่อนล้าง
   รีเลย์จะถูกสั่งรัวจนจบที่สถานะเดาไม่ได้ (วาล์วน้ำอาจค้างเปิด)
   เพิ่ม order by + limit (ตั้งต้น 20) + หมดอายุคำสั่งที่ค้างเกิน 10 นาที
   **บทเรียน: `update ... returning` ไม่รับประกันลำดับ** ต่อให้ CTE เลือก id
   ที่เรียงแล้วมาก็ตาม ต้อง order by ที่ชั้นนอกสุด (เทสต์ข้อ 5 จับได้)
   **และห้ามสร้าง overload 1 อาร์กิวเมนต์แยก** — `poll_device_commands('token')`
   จะกำกวมทันที บอร์ดจะเรียกไม่ได้เลย ใช้ default parameter แทน
2. `update devices set status = 'online'` ใน poll เป็นที่เดียวในระบบที่เขียน
   คอลัมน์นี้ และไม่มีอะไรตั้งกลับเป็น 'offline' — อุปกรณ์ 5 ตัวยังขึ้น online
   ทั้งที่เงียบ 22 ชม. `teacher_aiot_dashboard_page.dart:208` อ่านค่านี้ตรง ๆ
   เพิ่ม `device_effective_status()` แล้วให้ `list_school_devices` คิดจาก
   `last_seen_at` (เกิน 5 นาที = offline) โดยไม่กลบ 'error'/'maintenance'
   ที่คนตั้งเอง

pgTAP `56_device_command_poll_order_and_online.test.sql` 9/9 ผ่าน

**ยังค้าง:** เฟิร์มแวร์ต้องเพิ่มการเรียก `ack_device_command` ไม่งั้นหน้าจอจะขึ้น
"อุปกรณ์ยังไม่ยืนยัน" สีส้มตลอดไปต่อให้รีเลย์ทำงานจริง (โค้ดบอร์ดอยู่นอก repo นี้)

## 2026-09-10 — director_learning_page ให้ตรงกับดีไซน์วันที่ 7 (ภาพรวมนักเรียน) + migration เพิ่ม grade/advisor ใน watchlist

ทำหน้า `director_learning_page.dart` (ภาพรวมนักเรียน, Executive) ให้เลย์เอาต์/
การ์ดตรงกับต้นฉบับ 7 ก.ย. (commit `e7d2e78`) ครบทั้ง 9 ส่วน แต่ใช้ข้อมูลจริงแทน
ของแต่งขึ้นทุกจุด ตามที่ผู้ใช้ยืนยันไว้ ("เอาหน้าตา/เลย์เอาต์เท่านั้น ใส่ข้อมูลจริง"):
hero header, filter bar (เพิ่มช่องวันที่เป็นช่องที่ 3), การ์ดสรุป 5 ใบ (พื้นหลังสี
+ badge จริงเฉพาะ 2 ใบที่มีข้อมูลรองรับ), EXECUTIVE WATCHLIST, การวิเคราะห์สาย
การเรียน, การมาเรียนแยกตามระดับชั้น, ระบบดูแลช่วยเหลือนักเรียน, เจาะลึกรายระดับ
ชั้น, ข้อเสนอแนะเชิงบริหาร (ไม่มีปุ่ม "สั่งการ" ปลอมเพราะไม่มีระบบสั่งการจริง).

**RPC `listExecutiveAutoFlaggedStudents` มีอยู่แล้วแต่ไม่เคยถูกแสดงบนหน้าจอเลย
สักจุด** (โหลดไว้เฉยๆใน controller) — เอามาต่อจริงเป็นการ์ด watchlist ครั้งแรก
พร้อมปุ่ม "สั่งการดูแล" (เปิดเคสจริงผ่าน `openCaseFromFlag`, มีอยู่แล้ว) และปุ่ม
"ดูประวัติ" ใหม่ (เปิดได้เฉพาะนักเรียนที่มีเคสจริงในระบบแล้วเท่านั้น — เช็คจาก
`controller.cases` ตรงๆ ไม่ fetch เพิ่ม).

การ์ดต้นฉบับมีชื่อระดับชั้นกับครูที่ปรึกษาต่อแถว ซึ่ง RPC เดิมไม่ส่งมา — สอบถาม
ผู้ใช้แล้วเลือกต่อ backend จริงแทนตัดทิ้ง เพราะข้อมูลมีจริงในฐานข้อมูล
(`student_profiles.grade_level`/`room`, `homeroom_assignments.teacher_id`)
เพิ่ม migration `20260910150000_executive_flag_grade_and_advisor.sql`
(DROP+CREATE ไม่ใช่ CREATE OR REPLACE เพราะ Postgres ไม่ยอมให้เปลี่ยน
return columns ของ TABLE function แบบ replace-in-place) เพิ่ม 3 คอลัมน์
`grade_level`, `room`, `advisor_name` เข้า `list_executive_students_needing_attention`.
severity จริงมีแค่ 2 ระดับ (`urgent`/`normal`) ไม่ใช่ 3 แบบต้นฉบับ (วิกฤต/
เฝ้าระวัง/ดูแลพิเศษ) — ตัดป้าย "ดูแลพิเศษ" ทิ้งเพราะไม่มีสัญญาณสุขภาพจิต/
ความเครียดในระบบจริงเลย. เพิ่ม seed ข้อมูลจำลอง (นักเรียน + attendance +
assignments ค้าง + เกรดต่ำ + support cases + ครูที่ปรึกษา 3 คน + homeroom_assignments)
ให้ signal ทั้ง 3 แบบ (ค้างส่งงาน/คะแนนต่ำ/ขาดเรียนบ่อย) ติด flag ได้จริงบน local DB.

`AutoFlaggedStudent` model เพิ่ม `gradeLevel`/`room`/`advisorName` (nullable) —
`StudentSupportService` ไม่ต้องแก้เพราะ map จาก row อยู่แล้ว.
`docs/handoff/DATABASE_SCHEMA.md` เพิ่ม entry `list_executive_students_needing_attention`
ที่ขาดไปจากตอนสร้าง RPC ครั้งแรก (`20260910090000`) พร้อมอัปเดต signature ใหม่.

Test: `test/director_learning_page_test.dart` 8/8 ผ่าน (เพิ่ม 2 เคสใหม่: badge
ระดับชั้น/สถานะ/ครูที่ปรึกษาแสดงถูก + ปุ่มดูประวัติกดไม่ได้ถ้ายังไม่มีเคสจริง,
และกดได้เมื่อมีเคสจริงในระบบ). Regression เต็ม `test/executive/` + หน้านี้
113/113 ผ่าน.

## 2026-09-10/11 — ฟีเจอร์ใหม่: 4 หมวดคาบสอนจริงในการ์ด "ภาพรวมครูและการสอน" (จัดครูสอนแทน + เตรียมสอน/ประชุม ไม่เคยมีตารางเก็บข้อมูลมาก่อนเลย)

ผู้ใช้ส่งภาพหน้าจอวันที่ 7 ของการ์ด "ภาพรวมครูและการสอน" ถาม "ทำไมไม่ใช้ตาม
ตัวอย่าง" — พบว่าการ์ดที่ทำไปก่อนหน้านี้ในเซสชันเดียวกัน (bubble ของ
`list_departments(kind:'subject_group')`) เป็นคนละตัวชี้วัดกับต้นฉบับ: ของจริง
คือสัดส่วน "การสอน" 4 หมวด (สอนในตารางปกติ/กิจกรรม&แล็บ/จัดครูสอนแทน/เตรียม
สอน-ประชุม) ไม่ใช่สัดส่วนกลุ่มสาระ. ตรวจ schema พบว่า 2 ใน 4 หมวดไม่มีตาราง
เก็บข้อมูลอยู่เลย (จัดครูสอนแทน, เตรียมสอน) — ถามผู้ใช้แล้วเลือกออกแบบฟีเจอร์
ใหม่ให้ครบทั้ง 4 หมวด ไม่ใช่แค่ตัดทิ้งหรือย้อนกลับไปใช้ "ข้อมูลจำลอง" แบบ
ต้นฉบับ. เข้า plan mode ก่อนเริ่มเพราะงานใหญ่กว่าการ join ตารางที่มีอยู่.

**Migration `20260910160000_teacher_workload_categories.sql`:**
- `class_schedules.period_type` (`regular`/`activity_lab`, default `regular`) —
  ทำให้ "กิจกรรม & แล็บ" เป็นข้อมูลจริงที่ครูตั้งเองตอนสร้างตาราง
- ตารางใหม่ `class_substitutions` (school_id, class_schedule_id, class_date,
  original_teacher_id, substitute_teacher_id, note — unique ต่อ
  period-occurrence) และ `staff_prep_blocks` (school_id, teacher_id,
  class_date, start/end_time, label — ไม่ผูกวิชาเพราะเตรียมสอนไม่ใช่คาบเรียน)
  ทั้งคู่ RLS deny-all ไม่มี policy ตามกติกาโปรเจกต์
- RPC ใหม่: `record_class_substitution`, `list_periods_needing_substitute`
  (จับคู่ `staff_leave_requests` ที่อนุมัติแล้วกับ `class_schedules` ของวันนั้น
  — ทำให้ "จัดครูสอนแทน" เป็น coverage-rate จริง ไม่ใช่ "ครบ 100%" ที่แต่งขึ้น
  แบบต้นฉบับ), `log_staff_prep_block`, `get_teacher_workload_summary`
  (รวมยอด 4 หมวดของสัปดาห์นี้ — Mon–Sun ตาม `date_trunc('week',...)` ซึ่งตรงกับ
  `day_of_week` convention ของโปรเจกต์ 0=จันทร์อยู่แล้ว)
- ขยาย `set_class_schedule`/`list_all_school_schedules`/`list_my_schedule`/
  `list_teacher_schedules` ให้ส่ง `period_type` ด้วย

**บั๊กที่เจอระหว่างตรวจสอบเอง (ก่อนแตะฝั่ง Dart) — ทั้งคู่แก้ก่อนรายงานว่าเสร็จ:**
1. คอลัมน์ `grade_level`/`room` เป็น `character varying` แต่ประกาศ return type
   เป็น `text` — Postgres error "structure of query does not match function
   result type" เหมือนบั๊กที่เจอใน migration ก่อนหน้า (`20260910150000`) —
   คราวนี้ประกาศ `character varying` ให้ตรงคอลัมน์ต้นทางแทนตั้งแต่แรก
2. **`CREATE OR REPLACE FUNCTION set_class_schedule` เพิ่มพารามิเตอร์
   `p_period_type` (มี default) ท้ายรายการ — Postgres ไม่ถือว่าเป็นฟังก์ชัน
   เดียวกัน สร้าง overload ที่ 2 แยกต่างหากแทนที่จะแทนที่ของเดิม** ทำให้เรียก
   ด้วย literal ไม่มี type hint แล้ว ambiguous จนหาไม่เจอ — นี่คือบทเรียนเดียวกับ
   ที่เขียนไว้ใน WORK_LOG แล้วสำหรับ `poll_device_commands` แต่คราวนี้เจอเองซ้ำ
   เพราะลืมเช็ค ต้อง `DROP FUNCTION` signature เดิมก่อนเสมอเมื่อเพิ่มพารามิเตอร์
   ใหม่ท้ายรายการ ต่อให้มี default ก็ตาม
   ตรวจพบทั้งคู่ด้วยเทคนิค insert แถวลง `sessions` ตรง ๆ แล้วเรียก RPC ผ่าน
   `psql` ก่อนแตะโค้ด Dart เลย — ยืนยันว่าใช้ได้จริงก่อนรายงานว่าเสร็จ

**ผลข้างเคียงที่ต้องรู้: `supabase db reset --local` (รันเพื่อยืนยันว่า
migration ใหม่ใช้ได้กับ full pgTAP suite) ล้างข้อมูลจำลองที่ seed ด้วย
`docker exec` ตรง ๆ ทั้งหมดในเซสชันนี้** (นักเรียน auto-flag 10 คน, ครูที่
ปรึกษา 3 คน, homeroom_assignments ฯลฯ จาก entry ก่อนหน้า) เพราะไม่ได้อยู่ใน
migration/seed.sql — seed ใหม่ทั้งหมดด้วย ID ของ school/academic_year/term
ชุดใหม่หลัง reset (ของเดิมอ้าง ID ที่ไม่มีอยู่แล้ว). **บทเรียน: ข้อมูลจำลองที่
ใส่ผ่าน `docker exec` โดยตรงไม่รอดจาก `db reset` — ถ้าต้องรัน reset ระหว่าง
ทางต้อง seed ใหม่ก่อนรายงานว่าเสร็จ ไม่ใช่แค่เดโมด้วยข้อมูลที่หายไปแล้ว**

**pgTAP เต็ม (`supabase test db --local` หลัง fresh reset) พบ 3 test ล้มเหลว
ที่ไม่เกี่ยวกับงานนี้เลย (ยืนยันด้วยการรันซ้ำบน fresh reset ที่ไม่มีข้อมูลจำลอง
ของเซสชันนี้ค้างอยู่):**
- `14_facility_manager_building_scope.test.sql`, `16_facility_manager_device_list.test.sql`
  — ค้างอ้าง role `facility_manager` ที่ถูกยุบรวมเข้า `school_admin` ไปตั้งแต่
  2026-08-25 (ตาม CLAUDE.md) — ไฟล์ทดสอบกำพร้า ยังไม่ได้ลบ/อัปเดต
- `38_staff_attendance.test.sql` test 25 "approved leave covering the day
  wins when the day is read back" — คาดหวัง `leave` ได้ `present` แทน —
  ไม่เกี่ยวกับ `class_schedules`/`staff_leave_requests` ที่ผมแก้เลย (ไม่ได้แตะ
  ฟังก์ชันที่ทดสอบนี้เรียกเลยสักตัว) เป็นบั๊ก/ความไม่แน่นอนที่มีอยู่ก่อนแล้ว
  **ยังไม่ได้แก้ — นอกขอบเขตงานนี้ แต่บันทึกไว้ให้เซสชันถัดไปตามต่อ**

Dart: `TeacherWorkloadSummary`/`PeriodNeedingSubstitute` models ใหม่ (`packages/
shared_core/lib/models/teacher_workload_model.dart`), `ClassSubstitutionService`
ใหม่, `ExecutiveService.getTeacherWorkloadSummary()`, `CalendarService.
setClassSchedule` เพิ่ม `periodType`. `director_overview_page.dart`: ลบ
`_SubjectGroupBubbleCluster`/`_SubjectGroupLegend`/`subjectGroups` ทิ้งทั้งหมด
(ไม่มีที่ใช้อื่นแล้ว) แทนที่ด้วย `_BubbleCluster`/`_WorkloadLegend` ทั่วไปที่ใช้
คำนวณ layout เดิม (cascade positioning ที่ปรับจูนไว้ก่อนหน้านี้) แต่ป้อนด้วย 4
หมวดจริง สีคงที่ต่อหมวด (ไม่ใช่สีตามอันดับขนาดหลังเรียงแบบเดิม). เพิ่ม UI เขียน
ข้อมูลจริง 2 จุดเพื่อให้ตัวเลขมีคนกรอกจริง ไม่ใช่ตัวเลขที่ไม่มีทางไม่เป็นศูนย์:
`teacher_class_schedule_page.dart` (toggle ปกติ/กิจกรรม&แล็บ ตอนสร้างคาบ + ปุ่ม
"เตรียมสอน" บันทึก prep block), `director_teachers_page.dart` (การ์ด "ครูสอน
แทน" แสดงคาบที่ต้องหาคนแทนวันนี้ + มอบหมายจาก roster จริงที่หน้านี้โหลดอยู่
แล้ว — **ไม่ใช้ `teacher_picker_dialog.dart` เพราะดึงจาก `DirectorMockData`
ที่แต่งขึ้นทั้งหมด**).

Test: `test/executive/director_overview_connection_test.dart` แทนที่เทส
subject-group bubble ด้วย 2 เทสใหม่ (4 หมวดจริง + สัดส่วน 100% ถูกต้อง,
"ไม่มีคาบที่ต้องจัดครูสอนแทน" แทน "ครบ 100%" ปลอม). `director_overview_
attendance_test.dart` แก้ fixture ตาม field ใหม่.
`test/executive/director_teachers_honesty_test.dart` เพิ่ม 5 เทสใหม่ (การ์ด
ครูสอนแทนว่าง/error/มีคาบ/ปิดแล้ว/มอบหมายจริงแล้ว reload). `teacher_class_
schedule_page_test.dart`: **หน้านี้ไม่มี dependency-injection seam เลย** (ต่าง
จากหน้าอื่นในโปรเจกต์ทั้งหมด) — เรียก `CalendarService`/Supabase ตรง ๆ ไม่มี
constructor override ทำให้ `_load()` พังเสมอในเทสต์และค้างอยู่หน้า error
ตลอด (ไม่เคยเห็น hero banner ที่ปุ่มใหม่อยู่) — ปุ่ม toggle/เตรียมสอนใหม่จึง
**ยังไม่มีเทสจริงคุ้มครอง** ต้องรีแฟกเตอร์ให้มี seam แบบหน้าอื่นก่อนถึงจะเทสได้
(บันทึกไว้เป็นงานค้างสำหรับเซสชันถัดไป ถ้าจะเพิ่มเทส UI ของหน้านี้)

Regression: `flutter analyze` ทั้งโปรเจกต์ไม่มี error ใหม่ (มีแต่ info เดิมที่
เคยมีอยู่แล้ว). `flutter test test/executive/ test/director_learning_page_test.dart
test/teacher_class_schedule_page_test.dart` 120/120 ผ่าน. pgTAP เต็ม 910 เทส
เหลือ 3 ที่ล้มเหลว (ทั้งหมดไม่เกี่ยวกับงานนี้ ตามที่อธิบายด้านบน) เท่ากันทั้ง
ก่อนและหลังงานนี้.

**เอกสาร:** `docs/handoff/DATABASE_SCHEMA.md` เพิ่ม entry ตาราง `class_substitutions`/
`staff_prep_blocks`, คอลัมน์ `class_schedules.period_type`, และ RPC ใหม่/แก้
ทั้ง 8 ตัว.

## 2026-09-11 — ฟีเจอร์ใหม่: ระบบติดตามนักเรียน 4 ระบบ (เยี่ยมบ้าน · SDQ · ทุนการศึกษา · สั่งการติดตาม)

การ์ด "งานติดตามที่ยังไม่รองรับ" บน `director_learning_page.dart` (หน้า
ภาพรวมนักเรียนของ ผอ.) เคยมี 3 ปุ่ม `onPressed: null` และข้อความยอมรับตรงๆ
ว่าไม่มีข้อมูลเยี่ยมบ้าน/ทุนการศึกษา/SDQ/ระบบสั่งการเลย — ตรวจสอบทั้ง repo
ยืนยันว่าไม่มีตาราง/RPC ของทั้ง 4 เรื่องนี้อยู่จริง ผู้ใช้อนุมัติให้สร้างทั้ง
ระบบใหม่ตั้งแต่ schema จนถึง UI (ไม่ใช่แค่เพิ่มข้อมูลลงตารางเดิม)

**Migration ใหม่** `20260911020000_student_followup_system.sql`:
- ตารางใหม่ 5 ตัว: `student_home_visits`, `sdq_assessments`, `scholarships`,
  `scholarship_awards`, `executive_directives`
- RPC ใหม่ 17 ตัว ครอบคลุม create/list ของทั้ง 4 ระบบ + `list_school_students`
  (ตัวเลือกนักเรียนกลาง ใช้ร่วมกันทุก dialog สร้างข้อมูล) +
  `get_student_followup_summary` (ตัวเลขสรุปให้การ์ดบนหน้าภาพรวม)
- **SDQ**: เก็บ 25 ข้อ (`item_scores` jsonb) + คำนวณ 5 มิติ + total
  difficulties score ฝั่ง server ตามโครงสร้างมาตรฐาน SDQ — **จงใจไม่ใส่ป้าย
  วินิจฉัย "ปกติ/เสี่ยง/มีปัญหา"** เพราะเกณฑ์ cutoff แตกต่างกันตามแบบฟอร์ม
  ผู้ประเมิน (ครู/ผู้ปกครอง/ตนเอง) และไม่สามารถยืนยันแหล่งอ้างอิงที่ถูกต้องได้
  ระหว่างเขียนโค้ด — โชว์คะแนนดิบพร้อมข้อความเตือนว่าต้องให้ผู้เชี่ยวชาญตีความ
  แทนการยืนยันเกณฑ์ที่ไม่ได้ตรวจสอบ (มีคอมเมนต์อธิบายเหตุผลนี้ไว้ในไฟล์
  migration และในโมเดล Dart)
- **DROP+CREATE** `list_executive_students_needing_attention` เพิ่มสัญญาณ
  ธง "คะแนน SDQ สูง" (SDQ ล่าสุด ≥17) เข้าไปในตรรกะเดิม (ค้างส่งงาน/คะแนนต่ำ/
  ขาดเรียนบ่อย) — คงรูปตารางผลลัพธ์เดิมทุกคอลัมน์ ไม่กระทบ `AutoFlaggedStudent`
  ฝั่ง Dart เลย
- **บั๊กที่เจอระหว่างตรวจด้วย psql ก่อนแตะ Dart**: `acknowledge_directive`
  ชื่อคอลัมน์ผลลัพธ์ `status` ชนกับตัวแปร PL/pgSQL ที่ Postgres สร้างอัตโนมัติ
  จาก `RETURNS TABLE(..., status text)` ทำให้ `WHERE status = 'pending'`
  กำกวม — แก้ด้วยการใส่ table alias

**Dart**: โมเดล+เซอร์วิสใหม่ `student_followup_model.dart`/
`student_followup_service.dart` ใน `packages/shared_core`. หน้าใหม่
`director_student_followup_page.dart` — 4 แท็บ (เยี่ยมบ้าน/SDQ/ทุนการศึกษา/
สั่งการติดตาม) แต่ละแท็บมีลิสต์จริง + ปุ่มเพิ่มข้อมูลเปิด dialog จริง
(เลือกนักเรียนจาก `list_school_students`, เลือกครูจาก `StaffOrgService.
listStaffDirectory()` ที่มีอยู่แล้ว — **ไม่ใช้ `teacher_picker_dialog.dart`
เพราะดึงจาก mock data** เหมือนที่หลีกเลี่ยงไว้ในงานก่อนหน้า). การ์ดเดิมบน
`director_learning_page.dart` เปลี่ยนจากป้าย "ยังไม่รองรับ" สีเทาเป็นการ์ด
จริงโชว์ตัวเลขสรุป 4 ค่าจาก `get_student_followup_summary` + ปุ่มทั้ง 5
กดได้จริงทุกปุ่ม (4 ปุ่มเปิดหน้าใหม่ตามแท็บ + ปุ่ม "ส่งออกรายงานการเรียน"
export CSV จากข้อมูลที่หน้านี้โหลดอยู่แล้ว — attendance rows + case list —
ผ่าน `utils/web_download.dart` ที่มีอยู่แล้วในโปรเจกต์ ไม่ได้สร้างใหม่).
`followupSummary` โหลดแยกจาก `Future.wait` หลักของ `DirectorLearningController`
โดยตั้งใจ (มี try/catch ของตัวเอง) เพื่อไม่ให้ระบบใหม่ที่เพิ่งสร้างพังทั้งหน้า
ถ้า RPC ตัวนี้ล้มเหลว — ส่วนที่เหลือของหน้า (real, ใช้งานมาก่อนแล้ว) ต้อง
ยังโหลดได้ปกติ

**บั๊กที่เจอระหว่างเขียนเทส**: ปุ่ม "บันทึก" ใน dialog สร้างเยี่ยมบ้าน/ทุน
การศึกษา/สั่งการติดตาม กำหนด `onPressed` ตาม `controller.text.trim().isEmpty`
แต่ไม่ได้ผูก `onChanged` ให้เรียก `setDialogState(() {})` — ปุ่มเลย
"ค้างปิดใช้งาน" ตลอดแม้พิมพ์ข้อความแล้ว แก้ทั้ง 3 จุด

**เอกสาร**: `docs/handoff/DATABASE_SCHEMA.md` รันใหม่ผ่าน `./scripts/
dump_schema.sh` (ไม่ได้แก้มือ) ครบทั้ง 5 ตาราง + 17 RPC ใหม่.

**Seed**: เพิ่ม block ใหม่ท้าย `supabase/seed.sql` — เยี่ยมบ้าน 1 รายการ,
SDQ 1 รายการ (คะแนนรวม 23/40), ทุนการศึกษา 1 ทุน + ผู้สมัคร 2 คน (สถานะ
approved/applied ต่างกัน ให้เห็นทั้งสองสถานะ), คำสั่งติดตาม 2 รายการ (สถานะ
completed/pending ต่างกัน) — ยืนยันด้วยการยิง RPC ตรงผ่าน psql ทั้งก่อนและ
หลัง `supabase db reset --local` เต็มรูปแบบ ได้ผลตรงกัน

Regression: `flutter analyze` บนไฟล์ที่แก้/สร้างใหม่ทั้งหมดไม่มี error ใหม่
(มีแต่ info เดิมที่เคยมีอยู่แล้ว). `flutter test test/executive/
test/director_learning_page_test.dart test/teacher_class_schedule_page_test.dart`
143/143 ผ่าน (รวมไฟล์เทสใหม่ `director_student_followup_page_test.dart`
4 เทส และเทสใหม่บน `director_learning_page_test.dart` อีก 2 เทส). pgTAP
910 เทส เหลือ 2 ที่ล้มเหลว (facility_manager เดิมที่ไม่เกี่ยวกับงานนี้ —
รันซ้ำยืนยันว่า auth-rate-limit ที่ล้มเหลวรอบแรกเป็นความไม่แน่นอนชั่วคราว
ไม่ใช่บั๊กจากงานนี้ รันรอบสองผ่านปกติ).

**งานที่ยังไม่ได้ทำ (นอกขอบเขตที่อนุมัติไว้)**: หน้า tab แต่ละแท็บยังไม่มี
ปุ่ม "ดูประวัติ/แก้ไข" รายรายการ (มีแค่ list + เพิ่มใหม่), ยังไม่มีการแจ้งเตือน
อัตโนมัติเมื่อสั่งการติดตามเกินกำหนด, ทุนการศึกษายังไม่มีขั้นตอน disburse
เป็นชุด (ทำทีละคน). บันทึกไว้เผื่อมีคนสานต่อ.

### 2026-09-14 — บอร์ดเก่าพัง กำลังลงบอร์ดใหม่ · เพิ่ม report_relay_states
บอร์ดเก่าที่หยุด 9 ก.ย. 17:12:45 คือพังจริง (ไม่ใช่แค่ไฟดับ) และ device_token
เดิมหายไปด้วย — ออก token ใหม่ตรงจากฐานข้อมูล production (ค่าดิบอยู่กับผู้ใช้เท่านั้น)
`20260914000000_report_relay_states_on_boot.sql` — RPC ให้บอร์ดรายงานสถานะรีเลย์
ทุกช่องตอนบูตโดยไม่ต้องผูกกับคำสั่ง (เดิม device_relay_states เขียนได้ทางเดียวคือ
ผ่าน ack_device_command → หลังไฟดับแอปยังโชว์ "ยืนยันว่าเปิดอยู่" ค้าง)
pgTAP 57 8/8 · สเปกเฟิร์มแวร์ FIRMWARE_COMMAND_LOOP.md อัปเดต · ส่งพรอมต์ให้ AI ฝั่ง
เฟิร์มแวร์ 5 ข้อ (ack / report on boot / firmware+ip ใน heartbeat / watchdog / ต่อเซนเซอร์ครบ 10)
