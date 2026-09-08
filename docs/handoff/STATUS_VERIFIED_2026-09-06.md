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

### 1.6 School Admin — 5 หน้าผ่านเกณฑ์เต็ม

Alerts · CCTV · Device schedule · Incident inbox · Learning tracks
(มี controller + pgTAP + widget test ครบ)

---

## ⚠️ ส่วนที่ 2 — ทำแล้วบางส่วน / ยังตรวจไม่ครบ

| เรื่อง | ทำแล้ว | ยังขาด |
|---|---|---|
| แก้ audit-log null-school leak | migration + pgTAP 9/9 + apply local | **ยังไม่ apply ขึ้น production** |
| CI pipeline | ไฟล์ config มีครบ | ยังไม่รู้ว่ารันผ่านไหม |
| School Admin 14 หน้าที่เหลือ | ต่อ backend แล้วทุกหน้า | ยังไม่ผ่าน DoD (empty-state 13 หน้า, loading/error 6 หน้า, ตารางปลอม 4 หน้า) |
| Executive 5 หน้า | โหลดข้อมูลจริงบางส่วน | ยังแสดงตารางปลอมทับ (`classrooms` 205 บรรทัด, `cameras` 105) |
| Super Admin 10 หน้า | ต่อ backend ครบ | ขาด `ยังไม่มีข้อมูล` 9/10 หน้า, ไม่แยก loading/error 3 หน้า |

---

## ❌ ส่วนที่ 3 — ยังไม่ได้ทำเลย

### 3.1 ความปลอดภัย production (ร้ายแรงสุด)

| เรื่อง | สภาพ |
|---|---|
| `redeem_parent_binding_code` | **ยังเปิดให้ `anon` เรียกได้บน production** — ข้าม OTP ผูก parent↔student เปิดค้างตั้งแต่ 2026-09-04 |
| audit-log null-school leak | แก้แล้วแต่ยังอยู่แค่ local |

### 3.2 งานยังไม่ push — 7 commits อยู่บนเครื่องเดียว

### 3.3 หน้าที่ต่อ backend ไม่ได้เลย (7 หน้า ~12,380 บรรทัด)

Executive 6 หน้า: `learning`(2,815) `meetings`(2,216) `teachers`(1,927) `settings`(1,790)
`reports`(1,705) `scan`(1,082) · School Admin 1 หน้า: `scan`(851)

### 3.4 Blocker ความปลอดภัยของ School Admin import

สร้างผู้ใช้ด้วยรหัส `Test1234!` และไม่บังคับเปลี่ยน — ต้องแก้ก่อนเปิดใช้ import

### 3.5 Dead code 3,485 บรรทัด ยังไม่ลบ

### 3.6 Test debt ยังไม่เคลียร์ — Flutter fail 16 + pgTAP fail 6

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
