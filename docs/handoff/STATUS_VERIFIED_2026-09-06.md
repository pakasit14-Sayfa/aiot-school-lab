# ตรวจสอบสถานะจริง แยก "ทำแล้ว" กับ "ยังไม่ทำ" — 2026-09-06

> **ตรวจซ้ำบั๊ก 1 เมื่อ 2026-09-08:** canonical close มีแล้วใน `c1aff8d`;
> แก้ loading ที่บอกว่าไม่มีเหตุก่อนอ่านเสร็จ และ error ที่ถูก dialog บังเพิ่มแล้ว
> เทสต์ 23/23; regression 485 ผ่าน / 22 fail เดิม (จาก 475 / 24)
> ทดสอบเบราว์เซอร์ผ่าน OTP กับ Supabase local จริงแล้ว: ปิด incident ทั้ง 3 จุด
> และ emergency-event fixture สำเร็จ ตรวจสถานะ/เวลาปิดกับ DB แล้ว ไม่มีเหตุทดสอบค้าง
> หลักฐานและขอบเขตดู [บรีฟบั๊ก 1 ฉบับอัปเดต](FIX_BRIEF_FOR_CODEX.md)
> ข้อมูล audit เก่าด้านล่างไม่ได้รับรองว่าส่วนอื่นของหน้าฉุกเฉินผ่าน DoD

ไล่ตรวจข้ออ้างทุกข้อในเอกสารเทียบกับโค้ด/DB/git จริง **ไม่เชื่อเอกสารโดยไม่ตรวจ**
คู่กับ `MASTER_PLAN_2026-09-06.md` (แผนงาน) — ไฟล์นี้คือ *สถานะ* ไม่ใช่ *แผน*

---

## ✅ ส่วนที่ 1 — ทำแล้ว และตรวจสอบแล้วว่าจริง

### 1.1 commit ที่เอกสารอ้าง — จริงทั้งหมด

ตรวจ hash ทั้ง **28 ตัว** ที่ `WORK_LOG.md` อ้างว่าปิดงาน → **มีอยู่จริงทุกตัว
และหัวข้อ commit ตรงกับงานที่อ้าง** ไม่พบการกุ commit

### 1.2 รายการ "⚠️ ไม่แน่ใจ" ใน WORK_LOG — ปิดได้ 4 จาก 6

| รายการ | ผลตรวจจริง | สรุป |
|---|---|---|
| `agy-brief-fix-alerts-logs-fake-writes` | `super_admin_alerts_logs_page.dart:1302,1355` เรียก `IncidentService.acknowledgeSensorAlert` / `resolveSensorAlert` จริง | ✅ **ปิดได้** |
| `agy-brief-fix-school-admin-home-hardcoded-stats` | ไฟล์เก่า `dashboard/school_admin_dashboard.dart` **ไม่มีใคร import แล้ว** (dead code) | ✅ **moot** |
| `agy-brief-school-admin-dashboard-dead-drawer-buttons` | เหตุผลเดียวกัน — อยู่ในไฟล์ที่ตายแล้ว | ✅ **moot** |
| `agy-brief-kiosk-pairing-admin-architectural-mismatch` | `TerminalPairingService` มีจริงใน `shared_core` + ใช้งานใน `student_qr_login_page.dart` | ✅ **ปิดได้** (ตามมติ read-only, commit `6892f05`) |
| `agy-brief-ci-pipeline-real-cause` | `.gitlab-ci.yml` + `.github/workflows/ci.yml` มีจริง แต่**ยังไม่ได้ตรวจว่ารันผ่านไหม** | ⚠️ ยังไม่สรุป |
| `agy-brief-full-remaining-backlog-2026-08-24` | เป็นรายการอ้างอิง ไม่ใช่งานเดี่ยว | — ไม่ต้องปิด |

### 1.3 `agy-brief-emergency-hero-card-cover-panic-button` — **เสร็จแล้ว ทั้งที่ WORK_LOG ยังบอกว่ากำลังทำ**

ตรวจทั้ง 2 ฝั่งตามที่ brief ระบุ:

| สิ่งที่ brief ขอ | ผลตรวจ |
|---|---|
| hero card ต้องนับ `emergency_events` (ปุ่มฉุกเฉินฮาร์ดแวร์) เป็นเหตุจริงด้วย | ✅ ทั้งคู่มี `_activeRealEmergencyEvent` และใช้ `hasActiveReal = activeIncident != null \|\| activeEvt != null` |
| ปุ่มรับเรื่องฝั่งครูเป็น fake-success สำหรับเหตุฮาร์ดแวร์ | ✅ แก้แล้ว — `acknowledgeHardware: EmergencyService.acknowledgeEmergencyEvent` |
| ข้อความทางตัน "ไปกดที่เครื่อง" | ✅ ลบแล้ว (ค้นไม่เจอ) |
| ป้าย real/demo ต้องผูกเงื่อนไขเดียวกับเนื้อหา (methodology §8) | ✅ `badge = hasActiveReal ? _realBadge() : _demoBadge()` — และฝั่ง director มีคอมเมนต์อธิบายว่าห้ามใช้ `_hasRealData` เพราะจะติดป้าย "ฐานข้อมูลจริง" ให้ข้อมูลจำลอง |

> หมายเหตุ: hero มี fallback ข้อความจำลอง (`SOS จากนักเรียน ห้อง ม.3/2`) เมื่อไม่มีเหตุจริง
> — **แต่เปิดเผยตรงไปตรงมาด้วยป้าย "ข้อมูลจำลอง"** ไม่ใช่การหลอก

### 1.4 Teacher SOS + Student notification — verify ในเบราว์เซอร์จริงแล้ว (2026-09-06)

นักเรียนกด SOS จริง → ครูเห็นทันที → บันทึกความคืบหน้า + รับเรื่อง เขียน DB จริง ·
ครูเผยแพร่ใบงาน → trigger ยิง → นักเรียนเห็น badge + รายการจริง ไม่มีของปลอมปน

### 1.5 Super Admin — ต่อ backend ครบทั้ง 10 หน้า

`HANDOFF.md` ถูก (เคยสงสัยว่าผิด แต่ผลจากการอ่านไฟล์จริงยืนยันว่าถูก)

### 1.6 School Admin — เดิม 5 หน้าผ่านเกณฑ์เต็ม (2026-09-06) → **23/23 หน้าครบทั้งหมดแล้ว (2026-09-08)**

Alerts · CCTV · Device schedule · Incident inbox · Learning tracks
(มี controller + pgTAP + widget test ครบ) — ตอนนี้อีก 18 หน้าที่เหลือก็ผ่าน
DoD ครบเช่นกัน รายละเอียดดู `WORK_LOG.md` หัวข้อ 2026-09-08

---

## ⚠️ ส่วนที่ 2 — ทำแล้วบางส่วน / ยังตรวจไม่ครบ

| เรื่อง | ทำแล้ว | ยังขาด |
|---|---|---|
| แก้ audit-log null-school leak | migration + pgTAP 9/9 + apply local | **ยังไม่ apply ขึ้น production** |
| CI pipeline | ไฟล์ config มีครบ | ยังไม่รู้ว่ารันผ่านไหม |
| ~~School Admin 14 หน้าที่เหลือ~~ | ✅ **ปิดครบแล้ว 2026-09-08** — School Admin ทั้ง 23/23 หน้าผ่าน DoD เต็ม (audit ด้วย agent คู่ขนาน 3 ตัวอ่านทุกไฟล์เต็ม ไม่ใช่ grep แล้วแก้ 4 หน้าสุดท้าย: permissions/resources/buildings/scan) ดู `WORK_LOG.md` 2026-09-08 | — |
| Executive 5 หน้า | โหลดข้อมูลจริงบางส่วน | ยังแสดงตารางปลอมทับ (`classrooms` 205 บรรทัด, `cameras` 105) |
| Super Admin 10 หน้า | ต่อ backend ครบ | ขาด `ยังไม่มีข้อมูล` 9/10 หน้า, ไม่แยก loading/error 3 หน้า |
| Teacher 26 หน้า | **2026-09-09: ตรวจซ้ำทั้งเลน** — ข้อมูลปลอมที่ audit 2026-09-07 รายงานไว้ถูกปิดครบแล้ว รอบนี้ปิดเพิ่มอีก 3 จุดสุดท้าย (โจทย์ข้อสอบปลอมที่ถูกบันทึกลง DB จริง, ลิสต์รายวิชาปลอมระดับโมดูล, fake-success ตอนจัดกลุ่มต่อวงจร AIoT) มี connection test 31 ไฟล์ | ปุ่มที่ยัง disclose ว่าเป็น UI Prototype (`showTeacherMockAction`) และคัดลอกรายวิชา (CLS-6) ที่ยังไม่มี RPC — เปิดเผยตรง ๆ ไม่ใช่ของปลอมที่หลอก · `teacher_aiot_lab_page` ยังไม่มี connection test |
| Student 16 หน้า | **2026-09-09: ตรวจซ้ำทั้งเลน ไม่พบของปลอมที่ไม่ disclose** ทุกหน้าที่เข้าถึงได้จริงต่อ service จริงและมี connection test ครบ | demo fallback ที่ติดป้าย "ข้อมูลจำลอง" 2 จุด (G-Score, utility trend) — ตั้งใจและมี test บังคับป้าย · `lib/pages/student/` **แก้ข้อมูลผิด 2026-09-09**: ไม่ใช่ dead code — 3 ใน 4 ไฟล์ (`course_list`/`course_detail`/`lesson_view`) เข้าถึงได้จริงผ่าน `student_qr_login_page` → `/home` → `HomePage` `grades_overview_page.dart` ที่ตายจริงถูกลบแล้ว และปุ่ม "คะแนนของฉัน" ต่อเข้า `StudentScorePage` แทน ComingSoonPage · error ดิบ 13 จุดในนั้นแก้แล้ว + มี connection test |

---

## ❌ ส่วนที่ 3 — ยังไม่ได้ทำเลย

### 3.1 ความปลอดภัย production (ร้ายแรงสุด)

| เรื่อง | สภาพ |
|---|---|
| ~~`redeem_parent_binding_code`~~ | ✅ **ปิดแล้วบน production 2026-09-09** — เจ้าของรัน revoke เอง (Claude เขียน production ไม่ได้) ตรวจซ้ำได้ `false \| false` |
| ~~audit-log null-school leak~~ | ✅ **ขึ้น production แล้ว 2026-09-09** — `like '%school_id IS NULL%'` = false, service_role ถูก revoke |
| สิทธิ์อนุมัติผูกบัญชีผู้ปกครอง | ⚠️ **ครึ่งเดียว** — ครูไม่เห็นคำขอของทั้งโรงเรียนแล้ว (3.5a ขึ้น production 2026-09-09) แต่กฎ "ต้องเป็นครูประจำชั้น" (3.5b) ยังไม่ขึ้น เพราะ production ยังไม่กำหนดครูประจำชั้นสักห้อง (0 แถว) |

### 3.2 งานยังไม่ push — 7 commits อยู่บนเครื่องเดียว

### 3.3 หน้าที่ต่อ backend ไม่ได้เลย (7 หน้า ~12,380 บรรทัด)

Executive 6 หน้า: `learning`(2,815) `meetings`(2,216) `teachers`(1,927) `settings`(1,790)
`reports`(1,705) `scan`(1,082) · School Admin 1 หน้า: `scan`(851)

### 3.4 Blocker ความปลอดภัยของ School Admin import

สร้างผู้ใช้ด้วยรหัส `Test1234!` และไม่บังคับเปลี่ยน — ต้องแก้ก่อนเปิดใช้ import

### 3.5 Dead code 3,485 บรรทัด ยังไม่ลบ

### 3.6 Test debt ยังไม่เคลียร์ — Flutter fail 16 + pgTAP fail 6

> 2026-09-14: 5 เลนนอก Executive ผ่านการสแกน 82 หน้าตามเกณฑ์ DATA_CONNECTION_METHODOLOGY แล้ว **ไม่เหลือ**: ข้อมูลปลอมบนเส้นทางที่ผู้ใช้ถึง · fake-success · `$e` ดิบ · `catch (_) {}` ที่ซ่อนความล้มเหลวจากผู้ใช้ · เมนูที่เปิดหน้าผิด · ปุ่มตาย (14 จุดสุดท้ายแก้ในแถว WORK_LOG 2026-09-14) สิ่งที่ยัง "ยังไม่เปิดใช้งาน" คือฟีเจอร์ที่ **ไม่มี RPC จริง** และบอกผู้ใช้ตรง ๆ (แก้ไข/ลบอาคาร · กำหนดครูประจำอาคาร · ลงทะเบียนอุปกรณ์จากหน้าแอดมิน · ส่งออกคะแนน ฯลฯ) — เป็นงาน backend ไม่ใช่ความไม่ซื่อสัตย์
>
> 2026-09-13 (รอบ 2): shared_core **61/61** หลังแก้ fixture `submission_version_id` · Student/Parent/School Admin เหลือ 0 จุดที่โชว์ `$e` ดิบหรือข้อมูลจำลองบนเส้นทางที่ผู้ใช้ถึง (ยกเว้น Executive ที่อีกบัญชีทำอยู่)
>
> 2026-09-13: pgTAP **0 fail** (`Result: PASS`, 53 ไฟล์) หลังลบ 14/16 ที่ทดสอบ role ที่ไม่มีแล้ว และเขียน 57 แทน · Flutter user_app **720 ผ่าน / 6 พัง บน main** (774/6 เมื่อรวม branch `agent/fix-6-audit-bugs` ที่มีเทสต์เพิ่ม — ทั้ง 6 คือ Executive ที่รอ seam `DirectorOverviewController`) · shared_core 60/61 · shared_ui 17/17

---

## 📄 ส่วนที่ 4 — เอกสารที่ล้าสมัย ต้องแก้

| ไฟล์ | ปัญหา |
|---|---|
| `WORK_LOG.md` | ยังลิสต์ `agy-brief-emergency-hero-card-cover-panic-button` และ `agy-brief-student-notifications-phase1` ไว้ใน "In progress" ทั้งที่**ทำเสร็จแล้วทั้งคู่** · 4 รายการใน "⚠️ Unclear" ปิดได้แล้ว |
| แผนซ้อนกัน 6 ฉบับ | `task_plan.md` · `AI_SYSTEM_COMPLETION_MASTER_PLAN.md` · `TEACHER_STUDENT_COMPLETION_MAP.md` · `CLAUDE_TEACHER_STUDENT_HANDOFF.md` · `CLAUDE_ACCOUNT_1/2_*` · `MASTER_PLAN_2026-09-06.md` — **เสี่ยงให้เซสชันหน้าอ่านผิดฉบับ** (เคยเกิดแล้ว ตามที่ `CLAUDE.md` เตือน) |
| `docs/handoff/` 53 ไฟล์ | ~30 ไฟล์เป็น `agy-brief-*` ที่ปิดไปแล้ว ควรย้ายเข้า `archive/` |

---

## สรุปตัวเลข

| หมวด | จำนวน |
|---|---|
| ✅ ยืนยันแล้วว่าทำจริง | commit 28 ตัว · brief ปิดเพิ่ม 5 รายการ · 5 หน้า School Admin · 10 หน้า Super Admin · Teacher/Student/Parent |
| ⚠️ ทำบางส่วน | 5 กลุ่มงาน |
| ❌ ยังไม่ทำ | 6 กลุ่ม — ที่ร้ายแรงสุดคือช่องโหว่ production 2 จุด |
| 📄 เอกสารต้องแก้ | 3 เรื่อง |

**ข่าวดีจากการตรวจ:** งานที่ทำไปแล้วมีคุณภาพจริง ไม่พบการกุผลงาน — ที่เอกสารผิดคือ
**ประเมินตัวเองต่ำไป** (ลิสต์งานที่เสร็จแล้วว่ายังไม่เสร็จ) ไม่ใช่เคลมเกินจริง
