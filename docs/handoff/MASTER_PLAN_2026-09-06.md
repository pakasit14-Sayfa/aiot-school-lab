# Audit ทั้งระบบ + แผนงานรวม — 2026-09-06

อ่านทุกสิทธิ์ ทุกหน้า สกัดหลักฐานตามเช็คลิสต์ `DATA_CONNECTION_METHODOLOGY.md` §2
เอกสารนี้แทนที่ตัวเลขทุกอันที่เคยประเมินไว้ก่อนหน้า (ซึ่งผิด — ดู §0)

## 0. ความน่าเชื่อถือของ audit นี้

**เครื่องมือนับผิด 3 รอบระหว่างทาง** และทุกรอบเจอเพราะเอาผลไปเทียบกับไฟล์ที่เปิดอ่านจริง:

| รอบ | บั๊ก | ผลเสียถ้าเชื่อ |
|---|---|---|
| 1 | regex `Service\.` จับ `_service.` ไม่ได้ | สรุปผิดว่า Super Admin 5 หน้าไม่ต่อ backend |
| 2 | จับ `Service().method()` ไม่ได้ | สรุปผิดว่า School Admin 5 หน้าไม่ต่อ |
| 3 | นับ `children:` ของ Widget เป็นข้อมูลปลอม | ทุกหน้าดูเหมือนมี mock |

**สัญญาณที่เชื่อได้แน่นอน:** `import 'package:shared_core/...'` — ทุก service อยู่ใน
`shared_core` ตาม hard rule ข้อ 4 ⇒ *ไม่ import = แตะ backend ไม่ได้ 100%*

**สิ่งที่ audit นี้ยังไม่ทำ:** อ่านทีละบรรทัดในหน้าที่ต่อ backend แล้ว ว่าต่อครบ
*ทุกการ์ด/ทุกปุ่ม* หรือไม่ — ต้องอ่านเต็มตอนลงมือทำจริงทีละหน้า

---

## 1. ปัญหาที่พบ แยกตามความรุนแรง

### 🔴 A. ช่องโหว่ความปลอดภัยบน production (2 จุด)

| จุด | สภาพ |
|---|---|
| ~~`redeem_parent_binding_code`~~ | ✅ **ปิดแล้วบน production 2026-09-09** — `has_function_privilege` = `false \| false` (เปิดค้างมาตั้งแต่ 2026-09-04) |
| ~~audit-log null-school leak~~ | ✅ **apply ขึ้น production แล้ว 2026-09-09** — ไม่มีเงื่อนไข `school_id IS NULL` เหลือแล้ว |
| สิทธิ์อนุมัติผูกบัญชีผู้ปกครอง (พบใหม่ 2026-09-09) | ⚠️ **ปิดครึ่งเดียว** — 3.5a (ครูเห็นเฉพาะคำขอที่ตัวเองอนุมัติได้) ขึ้น production แล้ว · 3.5b (บีบเป็นครูประจำชั้น) **ยังไม่ขึ้น** เพราะ production มี `homeroom_assignments` = 0 แถว ถ้ารันตอนนี้จะไม่มีครูคนไหนอนุมัติได้เลย |

### 🔴 B. งานยังไม่ push — 6 commits อยู่บนเครื่องเดียว

### 🟠 C. Executive — สิทธิ์ที่แย่ที่สุด (13 หน้าใช้งานได้จริง)

**C1. ต่อ backend ไม่ได้เลย 6 หน้า (~11,530 บรรทัด)**

| ไฟล์ | บรรทัด | ข้อมูลปลอมที่ฝังอยู่ |
|---|---:|---|
| `director_learning_page` | 2,815 | `programs`(46) `gradeData`(85) `urgentStudents`(37) `followUps`(41) |
| `director_meetings_page` | 2,216 | `meetings`(127) `requests`(37) — **ไม่มีตารางใน DB รองรับเลย** |
| `director_teachers_page` | 1,927 | `personnel`(151) `departmentData`(67) `subjectGroups`(9) |
| `director_settings_page` | 1,790 | — |
| `director_reports_page` | 1,705 | `reports`(191) `pendingReports`(31) |
| `director_scan_page` | 1,082 | `teachers`(25) `kits`(25) `recent`(7) |

**C2. ต่อบางส่วน แต่ยังแสดงตารางปลอมทับข้อมูลจริง — 5 หน้า** (อันตรายกว่า C1 เพราะดูเหมือนใช้ได้)

| ไฟล์ | โหลดจริง | แต่ยัง hardcode |
|---|---|---|
| `director_classrooms_page` | `getClassroomsOverview` | **`classrooms`(205)** `greenScores`(17) `supportItems`(33) |
| `director_cctv_page` | `listCameraAccessGrants` `revokeCameraAccess` | **`cameras`(105)** `alerts`(31) |
| `director_emergency_page` | 9 RPC จริง | `events`(86) `teams`(29) |
| `director_environment_page` | 7 RPC จริง | `electricityBreakdown` `waterBreakdown` `recommendations` `zones` |
| `director_academic_calendar_page` | `listAllSchoolSchedules` | `alerts`(33) |

**C3. สะอาด 2 หน้า:** `director_overview_page` ✅ · `director_notifications_page` (โหลดจริง ไม่มี hardcode)

### 🟠 D. School Admin (20 หน้า)

- **ผ่านเกณฑ์เต็มแล้ว 5 หน้า** ✅ Alerts · CCTV · Device schedule · Incident inbox · Learning tracks
- **ต่อ backend ไม่ได้ 1 หน้า** ❌ `school_scan_page` (851) — มีแค่กล้อง ไม่มีการค้นหาอุปกรณ์จริง
- **ต่อแล้วแต่ยังมีตารางปลอม 4 หน้า:** `reports`(data×3) `resources`(`buildings` 71) `permissions`(`rows` 50) `dashboard`(data×2)
- **ขาด `ยังไม่มีข้อมูล` 13 หน้า** · **ไม่แยก loading/error 6 หน้า**
- 🔴 **Blocker ความปลอดภัย:** `school_import_page` สร้างผู้ใช้ด้วยรหัส `Test1234!` และไม่บังคับเปลี่ยน

### 🟡 E. Super Admin (10 หน้า) — ดีกว่าที่เคยประเมินมาก

**ทุกหน้าต่อ backend จริง มี service call จริง — `HANDOFF.md` ถูก**
ช่องว่างเป็นเรื่องคุณภาพ ไม่ใช่การเชื่อมต่อ:
- ขาด `ยังไม่มีข้อมูล` **9/10 หน้า**
- ไม่แยก loading/error 3 หน้า
- hardcode 2 จุดเล็ก (`_checks` ใน device_test, `cards` ใน schools)

### 🟡 F. Teacher / Student / Parent — ใกล้เสร็จ

- `teacher_courses_page` (5,158) — fake button ×1 + hardcode ×2
- `teacher_profile_page` — fake button ×2
- `teacher_redesign_prototype_page` (6,993) — hardcode ×8 (เคย audit แล้วรอบหนึ่ง ต้องเช็คว่าเป็นของเหลือหรือ false positive)
- `student_profile_page` — fake ×1 + hardcode ×1
- Parent สะอาดเกือบหมด (`cards` ที่เจอเป็น UI config ไม่ใช่ข้อมูล)

### 🟢 G. Dead code — ลบได้เลย

| ไฟล์ | บรรทัด |
|---|---:|
| `executive_redesign_prototype/pages/director_dashboard.dart` | 2,110 |
| `dashboard/` (school_admin, super_admin, student, parent, executive) | 1,186 |
| `student/student_main_nav.dart`, `student_home_page_model.dart`, `parent_palette.dart` | 189 |
| **รวม** | **3,485** |

*(`teacher_storybook_page` 8,227 + `teacher_design_system_page` 849 ถูกอ้างจาก `main.dart`
เฉพาะโหมด dev-preview — ผู้ใช้จริงเข้าไม่ถึง ตัดสินใจแยกว่าจะเก็บหรือลบ)*

### 🟡 H. ปัญหาข้ามระบบ

1. **`ยังไม่มีข้อมูล` หายไปเกือบทั้งระบบ** — มีครบเฉพาะ 5 หน้าของ School Admin ที่ทำตาม DoD
2. **loading/error ไม่แยกจากกัน** ในหน้าส่วนใหญ่นอก 5 หน้านั้น
3. **Test debt:** Flutter fail 16 + pgTAP fail 6 (ตีตรา pre-existing มานาน)
4. **fixture dual-role ไม่อยู่ใน `seed.sql`** — หายทุกครั้งที่ `db reset`

---

## 2. แนวทางทำงาน (ใช้กับทุกหน้า)

จาก 5 หน้าที่ทำสำเร็จแล้ว รูปแบบที่ได้ผลคือ:

```
Page (บาง)  →  Controller (ถือ state + busy key)  →  Service (shared_core)  →  RPC
```

**ต่อ 1 หน้า ทำตามนี้:**
1. อ่านทั้งไฟล์ ทำรายการทุกการ์ด/ทุกปุ่ม ว่าอันไหนจริง อันไหนปลอม
2. หา RPC ที่มีอยู่แล้วก่อน (มี **207 ตัว**, whitelist `executive` ไว้แล้ว **56 จุด**) — อย่ารีบเขียนใหม่
3. เขียน pgTAP ให้ fail ก่อน (token หาย/role ผิด/ข้ามโรงเรียน/school_id null)
4. เพิ่ม migration แบบ append-only — **ต้อง `revoke service_role` ด้วยเสมอ** (เจอ leak แบบนี้มาแล้ว 3 ครั้ง)
5. ต่อ controller + widget test (loading/data/empty/error/mutation สำเร็จ/mutation ล้มเหลว)
6. mutation ต้อง **write → re-read canonical → ค่อยบอกว่าสำเร็จ**
7. รัน regression ของหน้าที่ทำไปแล้วทั้งหมดซ้ำ
8. คลิกจริงในเบราว์เซอร์
9. อัปเดตเอกสารในเซสชันเดียวกัน

---

## 3. แผนการทำงาน (ticket ที่ติดตามได้)

**วิธีใช้:** ทำจากบนลงล่างตาม `ต้องทำหลัง` · ทำเสร็จ 1 ticket = 1 commit ·
เปลี่ยน `[ ]` เป็น `[x]` พร้อมใส่ commit hash · **ห้ามติ๊กจากรายงาน ต้อง verify เอง**

**เกณฑ์จบงาน (DoD) ใช้กับทุก ticket ที่แตะหน้าจอ:**
`ข้อมูลจริงหรือ ยังไม่มีข้อมูล` · `แยก loading/data/empty/error` · `เขียนจริงรอด reload` ·
`ปุ่มที่ไม่มี backend = disable` · `RPC fail closed 4 เคส` · `pgTAP + widget test` ·
`regression หน้าที่ทำแล้วทั้งหมด` · `คลิกจริงในเบราว์เซอร์` · `อัปเดตเอกสารในเซสชันเดียวกัน`

---

### PHASE 0 — ความปลอดภัย + กันงานหาย · 1 เซสชัน · ไม่มี prerequisite

| | ID | งาน | ต้องทำหลัง | จบเมื่อ |
|---|---|---|---|---|
| [x] | 0.1 | `git push` ขึ้น gitlab | — | ✅ **เสร็จ 2026-09-06** — push 11 commits (`e3fd2d2..66b83a2`) · remote ตรงกับ local แล้ว |
| [x] | 0.2 | 🔐 ปิด `redeem_parent_binding_code` บน production | 0.1 + **ผู้ใช้อนุญาต** | ✅ **เสร็จ 2026-09-09 บน production จริง** — เจ้าของรัน `revoke execute ... from anon, authenticated` เอง (Claude ถูกบล็อกไม่ให้เขียน production) หลักฐาน: `has_function_privilege` ก่อนแก้ = `true \| true` หลังแก้ = **`false \| false`** ตามที่เห็นในเทอร์มินัลจริง คำสั่งอยู่ใน `PRODUCTION_FIX_0.2-0.4.md` ขั้นที่ 2 |
| [x] | 0.3 | 🔐 apply `20260905040000` (audit-log leak) ขึ้น production | 0.2 | ✅ **เสร็จ 2026-09-09 บน production จริง** — รัน migration + บันทึกลง `schema_migrations` แล้ว หลักฐาน: `pg_get_functiondef(...) like '%school_id IS NULL%'` = **`false`** (ไม่มีเงื่อนไขรั่วแล้ว) และ `has_function_privilege('service_role', ...)` = **`false`** |
| [x] | 0.4 | ตรวจ migration ทุกตัวว่าขึ้น production ครบ | 0.3 | ✅ **เสร็จ 2026-09-09** — เจ้าของรัน `npx supabase migration list --linked` เอง ผลจริง: **ทุกแถวมีเลขทั้ง Local และ Remote** ยกเว้นแถวสุดท้าย `20260909010000` ที่ Remote ว่าง ซึ่ง **จงใจไม่รัน** (ขั้น 3.5b — บีบเป็นครูประจำชั้น ต้องรอ production กรอก `homeroom_assignments` ก่อน ตอนนี้ 0 แถว) **ข้อกังวลเดิมที่ว่า production อาจค้างอยู่ที่ snapshot เก่ากว่าเดือน — ไม่จริง** ตรงกันครบทั้ง 158 migration |
| [ ] | 0.5 | ใส่ fixture dual-role ลง `seed.sql` | — | `db reset` แล้ว teacher ยังมี 2 role |
| [x] | 0.6 | ลบ dead code + ปิด route `/prototype/*` | — | ✅ **เสร็จ 2026-09-06** (`66b83a2`) — ลบ 9 ไฟล์ + test ล้าสมัย 2 ไฟล์ รวม **-10,121 บรรทัด** · route `/prototype/*` ถูกครอบ `isPrototypeMode` แล้วทั้ง `routes:` และ `onGenerateRoute` · analyze 0 error/0 warning · build web ผ่าน · test fail คงที่ 16 ชุดเดิม |

---

### PHASE 1 — ปิด Teacher / Student / Parent · 2–3 เซสชัน

| | ID | งาน | ต้องทำหลัง | จบเมื่อ |
|---|---|---|---|---|
| [x] | 1.1 | แก้ fake button: `teacher_courses`×1 `teacher_profile`×2 ~~`student_profile`×1~~ | 0.6 | ตรวจ 2026-09-08: `teacher_courses`/`teacher_profile` สะอาดแล้วจาก commit `0f03100`/`2d53126`/`94ea879` ก่อนหน้านี้ ไม่มีบั๊กเหลือ. `student_profile` เป็นคนละเลน (Student) ยังไม่ตรวจในรอบนี้ |
| [x] | 1.2 | ตรวจ hardcode 8 จุดใน `teacher_redesign_prototype_page` (6,993 บรรทัด) | 0.6 | commit `669ab76` แก้ 3 จุด (กล้องปลอม/variant B-C/mock search) + commit `9b6250c` แก้อีก 2 จุดที่ตกหล่น (role switcher fake-success ขัดกับสถาปัตยกรรม no-in-app-switch, ปฏิทิน freeze วันที่) ที่เหลือเป็น false positive (`TeacherMock` = config เมนู ไม่ใช่ fake data) |
| [ ] | 1.3 | เคลียร์ test debt: Flutter fail 16 + pgTAP fail 6 | — | ทุกตัวถูก แก้ / ลบ / ขึ้นทะเบียน known พร้อมเหตุผล — Flutter fail ล่าสุด (2026-09-08) เหลือ 8 (ทั้งหมดฝั่ง Executive ที่ Codex ทำอยู่ + 1 school_admin) ยังไม่ได้ re-count pgTAP fail 6 |
| [x] | 1.4 | ทดสอบเคสลบข้ามโรงเรียนในเบราว์เซอร์ | 0.5 | local มีโรงเรียนเดียว ทดสอบเบราว์เซอร์จริงไม่ได้ — พิสูจน์ด้วย pgTAP แทน (`19_incident_reports.test.sql` test 6b, commit `899750c`) ยืนยัน `list_incident_reports` ของครูโรงเรียนอื่นไม่เห็นเหตุการณ์โรงเรียน A เลยสักแถว ผ่าน 22/22 |
| [ ] | 1.5 | Parent regression ซ้ำหลัง merge | 1.1 | 7 หน้าผ่าน + สลับลูกได้ 2 ทาง |

---

### PHASE 2 — School Admin 15 หน้า · 16–18 เซสชัน · **สายที่ 1**

ทำทีละ ticket ตามลำดับ แต่ละอันจบด้วย DoD เต็ม

> ✅ **ปิดแล้ว 2026-09-08 — School Admin 23/23 หน้า DoD ครบทั้งหมด**
> (ยกเว้น 2.10 ที่ตั้งใจปล่อยบล็อกไว้ด้วยเหตุผลความปลอดภัย ไม่ใช่ของค้าง)
> รายละเอียดการตรวจ/แก้แต่ละหน้าอยู่ใน `WORK_LOG.md` หัวข้อวันที่ 2026-09-08
> (audit เต็ม 23 หน้าด้วย agent คู่ขนาน 3 ตัว อ่านทุกไฟล์เต็ม ไม่ใช่ grep)

| | ID | หน้า | หมายเหตุจาก audit | เซสชัน |
|---|---|---|---|---:|
| [x] | 2.1 | Permissions | ✅ **ปิดแล้ว 2026-09-08** — เมทริกซ์สิทธิ์จริง (`f2a4d17`/`8b00c76`/`873dbc2`) + filter บทบาท/badge/การ์ดสิทธิ์ที่พังทั้งระบบ (เทียบ label ผิดคำมาตั้งแต่แรก) แก้ครบ (`cb06a9b`) |
| [x] | 2.2 | Dashboard + Resources + Energy + ESG | ✅ **ปิดแล้ว** — Energy/ESG/Device-control เสร็จ 2026-09-06, export จริงเพิ่ม 2026-09-07/08 (S3), Dashboard sidebar identity ปลอมแก้ 2026-09-08 (`7c091b4`), Resources 3 การ์ด KPI ปลอมสุดท้ายแก้ 2026-09-08 (`1c622dd`) |
| [x] | 2.3 | Device control | ✅ ปิดแล้ว 2026-09-06 — แยก queued/acknowledged/applied ครบ ยืนยันสะอาดอีกครั้งตอน audit 2026-09-08 |
| [x] | 2.4 | Reports | ✅ **ปิดแล้ว 2026-09-08** — insights/กราฟปลอม + export ปลอม แก้ครบ (`1202caf`/`f0e71e8`) |
| [x] | 2.5 | Buildings + Rooms | ✅ **ปิดแล้ว 2026-09-08** — เจอบั๊กอยู่ที่ RPC `list_school_rooms` เอง (hardcode count/status ทุกห้อง) ไม่ใช่แค่ Dart แก้ทั้ง SQL+Dart (`ea8d1c5`) |
| [x] | 2.6 | Students + Teachers | ✅ ยืนยันสะอาดแล้วตอน audit 2026-09-08 — mutation เขียนแล้วอ่านย้อนกลับมายืนยันก่อนบอกสำเร็จ ไม่มีของปลอม |
| [x] | 2.7 | Devices | ✅ ยืนยันสะอาดแล้วตอน audit 2026-09-08 |
| [x] | 2.8 | Settings + Profile | ✅ Settings สะอาดอยู่แล้ว · Profile มี fake-success 3 ปุ่ม + ฟิลด์ hardcode 5 จุด แก้ครบ 2026-09-08 (`7c091b4`) |
| [x] | 2.9 | **Scan** | ✅ **ปิดแล้ว 2026-09-08** — เอกสารนี้เขียนผิดไว้ว่า "ไม่ import shared_core" ทั้งที่จริงต่อ backend แล้วตั้งแต่ก่อนหน้า เหลือแค่ประวัติสแกนปลอมที่แก้แล้ว (`b33e55d`, เจอ crash bug จริงแถมมาด้วย) |
| [ ] | 2.10 | 🔐 **Import + credential lifecycle** | **blocker ยังไม่แก้ ตั้งใจ**: สร้างผู้ใช้ด้วย `Test1234!` ไม่บังคับเปลี่ยน — import นักเรียน/ครูยังถูกบล็อกไว้ด้วยเหตุผลนี้ (ตรวจแล้วว่ายังบล็อกอยู่จริง 2026-09-08) |

---

### PHASE 3 — Executive 13 หน้า · 15–19 เซสชัน · **สายที่ 2 (ทำขนานกับ Phase 2 ได้)**

| | ID | งาน | หมายเหตุ | เซสชัน |
|---|---|---|---|---:|
| [ ] | 3.0 | **สำรวจ backend ก่อนเขียนโค้ดใดๆ** | 6 หน้าที่ตัดขาดต้องใช้ข้อมูลอะไร · มี RPC ใน 207 ตัวรองรับกี่หน้า · `executive` ถูก whitelist แล้ว 56 จุด | 1 |
| [ ] | 3.1 | ⚠️ **ลบตารางปลอมใน 5 หน้าที่ต่อครึ่งเดียว** | `classrooms`(205) `cameras`(105) `events`(86) `teams`(29) `alerts` ฯลฯ — **ทำก่อน** เพราะอันตรายกว่าหน้าที่ตัดขาด (ดูเหมือนใช้ได้) | 3 |
| [ ] | 3.2 | `director_teachers` (1,927) | ปลอม `personnel`(151) — น่าจะ reuse `getAllUsers` ได้ | 2 |
| [ ] | 3.3 | `director_reports` (1,705) | ปลอม `reports`(191) | 2 |
| [ ] | 3.4 | `director_scan` (1,082) | ปลอม `teachers`/`kits`/`recent` | 1.5 |
| [ ] | 3.5 | `director_learning` (2,815) | ปลอม `gradeData`(85) `urgentStudents`(37) `followUps`(41) | 2.5 |
| [ ] | 3.6 | `director_settings` (1,790) | | 1.5 |
| [ ] | 3.7 | ❓ **`director_meetings` (2,216)** | **ต้องตัดสินใจก่อน:** ไม่มีตารางใน DB เลย → สร้างใหม่ (+3–4) หรือ disable (0.3) | 0.3–4 |
| [ ] | 3.8 | verify `director_overview` + `director_notifications` | 2 หน้าที่สะอาดแล้ว เหลือคลิกจริง | 1 |

---

### PHASE 4 — Super Admin 10 หน้า · 6–8 เซสชัน

**ไม่ต้องต่อใหม่** — ทุกหน้าต่อ backend จริงแล้ว งานคือตรวจสอบ + เติมสิ่งที่ขาด

| | ID | งาน | เซสชัน |
|---|---|---|---:|
| [ ] | 4.1 | อ่านเต็มทั้ง 10 หน้า ระบุว่าต่อครบทุกการ์ด/ปุ่มไหม | 2 |
| [ ] | 4.2 | เติม `ยังไม่มีข้อมูล` (ขาด 9/10 หน้า) + แยก loading/error (ขาด 3 หน้า) | 2 |
| [ ] | 4.3 | ลบ hardcode `_checks`(device_test) `cards`(schools) | 0.5 |
| [ ] | 4.4 | ตรวจ scope ข้ามโรงเรียนของทุก RPC ที่ super_admin เรียก | 1.5 |
| [ ] | 4.5 | คลิกจริงทั้ง 10 หน้า | 1 |

---

### PHASE 5 — รวมระบบ + release · 3 เซสชัน

| | ID | งาน |
|---|---|---|
| [ ] | 5.1 | `flutter analyze` + `build web` + test suite ทั้งหมด |
| [ ] | 5.2 | คลิกจริง 6 role ทั้ง desktop และ mobile width |
| [ ] | 5.3 | audit ความปลอดภัย/tenant รอบสุดท้าย |
| [ ] | 5.4 | regenerate `DATABASE_SCHEMA.md` + อัปเดต HANDOFF/WORK_LOG/CLAUDE.md |
| [ ] | 5.5 | ล้าง fixture ทดสอบ + ทำทะเบียน known-issue |
| [ ] | 5.6 | 🔐 deploy production (ขออนุญาตแยก) |

---

## 4. การตัดสินใจที่ค้างอยู่ (บล็อกงานข้างล่าง)

| # | เรื่อง | บล็อก | ตัวเลือก |
|---|---|---|---|
| D1 | อนุญาตให้เขียน production ไหม | 0.2 · 0.3 · 0.4 · 5.6 | อนุญาต / ทำเองโดยเจ้าของ |
| D2 | `director_meetings` เอายังไง | 3.7 | สร้างใหม่ (+3–4 เซสชัน) / disable (0.3) / ลบทิ้ง |
| D3 | Super Admin ใช้เกณฑ์ไหน | Phase 4 ทั้งหมด | เติม state อย่างเดียว (6–8) / refactor เป็น controller เหมือน School Admin (12–15) |
| D4 | เก็บ `teacher_storybook`(8,227) + `design_system`(849) ไหม | 0.6 | เก็บไว้เป็น dev tool / ลบ |
| D5 | โควต้า GitLab CI หมด (`ci_quota_exceeded`) — **ไม่ใช่ปัญหาโค้ด** | CI ทั้งหมด | ต่อโควต้า / ติดตั้ง self-hosted runner / ใช้ GitHub Actions อย่างเดียว |

---

## 5. เวลา

| Phase | เซสชัน |
|---|---:|
| 0 | 1 |
| 1 | 2–3 |
| 2 | 16–18 |
| 3 | 15–19 |
| 4 | 6–8 |
| 5 | 3 |
| **รวม เรียงลำดับ** | **43–52** |
| **ขนาน 2 สาย** (Phase 2 ‖ Phase 3 — คนละโฟลเดอร์ ไม่ชนกัน) | **28–34** |

1 เซสชัน ≈ 2–3 ชม. (รวมเวลารัน test/build/db reset และคลิกทดสอบจริง)
⇒ **~70–100 ชม. งาน AI** ถ้าทำขนาน 2 สาย

| ดูแลได้วันละ | เสร็จใน |
|---|---|
| 6–8 ชม. | ~2–3 สัปดาห์ |
| 3–4 ชม. | ~4–6 สัปดาห์ |
| 1–2 ชม. | ~10–14 สัปดาห์ |
| เสาร์-อาทิตย์ | ~3–4 เดือน |

**คอขวดคือเวลารีวิว/อนุมัติของเจ้าของโปรเจกต์ ไม่ใช่ความเร็ว AI**

### กติกาที่ห้ามลด

1. ห้ามติ๊ก `[x]` จากรายงานของ agent — ต้อง verify เอง (2026-09-06 agent รายงาน regression ผิด 2 ใน 4 เรื่อง)
2. `grep` บอกได้แค่ "ไม่ต่อแน่ๆ" — ต้องอ่านทั้งไฟล์ก่อนสรุปว่าต่อครบ
3. migration แก้แล้วต้อง **apply จริง** + บันทึกใน `schema_migrations`
4. ทุก migration ที่แตะ grant ต้อง `revoke service_role` ด้วย (เจอ leak แบบนี้ 3 ครั้งแล้ว)
5. อัปเดตเอกสารในเซสชันเดียวกับที่ทำงาน

---

## ภาคผนวก A — ช่องว่างรายหน้าของ School Admin

ยกมาจาก `task_plan.md` (2026-09-04) ก่อนลบไฟล์นั้น เพื่อรวมไว้ที่เดียว
ใช้ประกอบ Phase 2 — ยังไม่ได้ re-verify ทุกบรรทัด ให้ถือเป็นจุดตั้งต้นในการอ่านไฟล์จริง

| หน้า | สภาพตอนสำรวจ | สิ่งที่ต้องทำ |
|---|---|---|
| `school_admin_dashboard_page` | summary/assignments/alerts/logs จริง แต่ตัวเลขทรัพยากร hardcode | ลบตัวเลข hardcode หรือแทนด้วย UtilityService + เพิ่ม error/empty |
| `school_alerts_page` | ✅ ทำแล้ว (`c8346ff`) | — |
| `school_buildings_page` | อ่านอาคาร/ห้องจริง แต่ CRUD ปลอม | เพิ่ม RPC scoped แล้วต่อ mutation + refetch |
| `school_devices_page` | อ่านอุปกรณ์จริง แต่รายละเอียดที่โชว์ปลอม + ปุ่มทั้งหมดปลอม | โชว์เฉพาะฟิลด์ที่ backend คืนมา · ปุ่มที่ไม่มี RPC ให้ disable |
| `school_resources_page` | ดึง utility rate มาแล้ว **แต่ทิ้ง** · กราฟ/อาคาร/KPI hardcode · `IoT Live Sync` เป็น true ตลอด | โหลด summary/trend/rate จริง ห้าม fallback เป็นตัวอย่าง |
| `school_admin_energy_page` | อ่าน utility 6 จุดจริง | แทน null ด้วย empty state · เอา fallback ปลอมออก · export ที่ยังไม่เสร็จให้ disable |
| `school_admin_esg_page` | อ่าน utility 4 จุดจริง | แยกเนื้อหานโยบาย (static ได้) ออกจากตัวเลขวัดผล (ต้องจริง) |
| `school_admin_cctv_page` | ✅ ทำแล้ว (`830e20a`) | — |
| `school_admin_incident_inbox_page` | ✅ ทำแล้ว (`866d774`) | — |
| `school_admin_device_control_page` | อ่าน + queue command จริง แต่ UI เริ่มที่ OFF และแสดง queue เหมือนสำเร็จแล้ว | แสดงสถานะที่สังเกตได้จริง · แยก queued/acknowledged ให้ชัด |
| `school_admin_device_schedule_page` | ✅ ทำแล้ว (`b27f843`) | — |
| `school_students_page` | อ่าน user จริง แต่โชว์นักเรียนปลอมเมื่อผลลัพธ์ว่าง · ฟิลด์/mutation แต่งขึ้น | ลบ fallback ปลอม · ใช้เฉพาะฟิลด์จริง · ปุ่มที่ไม่มี contract ให้ disable |
| `school_teachers_page` | user/homeroom จริง · homeroom write จริง แต่ไม่ atomic | รวมการแทนที่ homeroom เป็น RPC เดียว · ลบฟิลด์/ปุ่มที่แต่งขึ้น |
| `school_permissions_page` | user/log/role/status write จริง · add-user และหลายฟิลด์ปลอม · error ถูกกลืน | จำกัดตัวแก้ไขเฉพาะฟิลด์ที่บันทึกจริง · เปิดเผย error · refetch |
| `school_import_page` | import 5 ชนิดจริง · ประวัติอยู่ในหน่วยความจำ · **รหัสผ่านคาดเดาได้** | 🔐 แก้ credential lifecycle ก่อน · ใช้ audit log จริงแทนประวัติในหน่วยความจำ |
| `school_learning_tracks_page` | ✅ ทำแล้ว (`8a6b4f8`) | — |
| `school_reports_page` | อ่าน summary/audit จริง · filter/กราฟ/insight/export ปลอม | สร้าง view model จากข้อมูลจริงเท่านั้น · export ทำได้เฉพาะจากแถวจริง |
| `school_scan_page` | กล้อง/คลิปบอร์ดจริง · ค้นหาอุปกรณ์/ประวัติ/นำทาง ปลอม | ❌ ไม่ import shared_core — ต่อจากศูนย์ |
| `school_settings_page` | ชื่อ/รหัสโรงเรียน + audit log จริง · setting/save/reset/backup ปลอม | นิยาม settings ระดับโรงเรียนเฉพาะฟิลด์ที่มีใน schema · ปุ่มอันตรายที่ยังไม่รองรับให้ disable |
| `school_admin_profile_page` | ชื่อ/อีเมล + audit log จริง · ฟิลด์อื่น/save/password/notification ปลอม | ใช้ flow เดิมที่มีอยู่ · ห้ามรายงานว่าเปลี่ยนรหัสผ่านสำเร็จทั้งที่ไม่ได้เปลี่ยน |

## ภาคผนวก B — งานที่เคยอยู่ใน backlog เก่า และตรวจแล้วว่าเสร็จ

ตรวจกับ DB จริง 2026-09-06 ก่อนลบ `agy-brief-full-remaining-backlog-2026-08-24.md`:

| รายการ | ผลตรวจ |
|---|---|
| `grades.assignment_id` | ✅ มีคอลัมน์แล้ว |
| `create_assignment` รับ `p_rubric_id` | ✅ มีพารามิเตอร์แล้ว |
| `auth_sign_out_all` + test | ✅ มีฟังก์ชัน และครอบใน `03_auth_session_rate_limit.test.sql` |
| Facility Manager 9 หน้า | ⚫ ล้าสมัย — role ถูกยุบรวมเข้า `school_admin` เมื่อ 2026-08-25 |
| Parent portal · Student G-Score · teacher_profile · exam_builder | ✅ ปิดแล้วตาม WORK_LOG |
