# Brief for agy: Architectural Mismatch on Kiosk QR Pairing in `aiot_dev_dashboard`

> **Document Purpose:** รายงานข้อตรวจพบทางสถาปัตยกรรมระดับ Critical เกี่ยวกับ RPC `claim_terminal_pairing_session` ในหน้า [`kiosk_pairing_scanner_page.dart`](file:///Users/sayfa/aiot_dev_dashboard/lib/pages/kiosk_pairing_scanner_page.dart) และ [`school_scan_page.dart`](file:///Users/sayfa/aiot_dev_dashboard/lib/pages/school_admin/school_scan_page.dart) พร้อมเสนอ 3 ทางเลือกเชิง Design / UX ให้ตัดสินใจก่อนลงมือปรับโค้ด

---

## 🔎 1. ข้อตรวจพบเชิงสถาปัตยกรรม (Architectural Root Cause Analysis)

จากการตรวจสอบเงื่อนไขและความปลอดภัยของฟังก์ชัน `claim_terminal_pairing_session(p_token text, p_pairing_code text)` ในฐานข้อมูล PostgreSQL ([`supabase/migrations/20260823040000_terminal_pairing_and_student_support.sql`](file:///Users/sayfa/my_first_app/supabase/migrations/20260823040000_terminal_pairing_and_student_support.sql)):

```sql
-- โค้ดในฐานข้อมูลของ claim_terminal_pairing_session
CREATE OR REPLACE FUNCTION public.claim_terminal_pairing_session(
  p_token text,
  p_pairing_code text
) ...
AS $$
BEGIN
  -- 1. ต้องเป็น session ของนักเรียน (student) ที่ล็อกอินอยู่จริง
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND OR v_actor.role != 'student' THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  ...
END;
$$;
```

### ❌ ปัญหาที่เกิดขึ้นจริง:
1. **Parameter `p_token` ไม่ใช่ Token จาก QR:** RPC ตัวนี้ออกแบบมาให้รับ **Session Token ของผู้ใช้งานที่กำลังล็อกอินอยู่** (เพื่อพิสูจน์ตัวตนว่านักเรียนคนไหนกำลังสแกนตู้) ไม่ใช่ Token ของตัวตู้ Kiosk
2. **Role Enforcement:** ฟังก์ชันบังคับเฉพาะ `role = 'student'` เท่านั้น เพื่อให้นักเรียนล็อกอินเข้าใช้ตู้ Kiosk ในโรงเรียน
3. **Admin Context Mismatch:** ในแอป `aiot_dev_dashboard` ผู้ใช้งานคือ **Developer, Super Admin หรือ School Admin** ซึ่งไม่มี Session Token ของนักเรียน และไม่มีสิทธิ์เป็น `student`
4. **ผลการทดสอบจริง (Live Test Result):** เมื่อจำลองการส่งค่าตามโค้ดปัจจุบัน ระบบจะโยนข้อผิดพลาด **`invalid_session` 100% ทุกครั้ง** โดยไม่มีทางทำงานสำเร็จได้จากการออกแบบดั้งเดิม

---

## 🧭 2. ข้อเสนอ 3 ทางเลือกเชิง UX / Architecture (3 Strategic Options)

เนื่องจากปัญหานี้เป็นเรื่องของ **Domain Flow & UX Intent** (เจตนาของการใช้งานหน้าจอนี้ในบริบทของ Admin) จึงต้องเลือกแนวทางที่สอดคล้องกับ Use Case จริง:

| ทางเลือก (Option) | รายละเอียดการทำงาน (How it works) | ข้อดี / ความเหมาะสม | สิ่งที่ต้องทำ (Action Items) |
| :--- | :--- | :--- | :--- |
| **ทางเลือกที่ 1: Debug & Status Inspector** *(แนะนำ)* | เปลี่ยนปุ่มให้เรียก `check_terminal_pairing_status(p_pairing_code)` ซึ่งเป็น Read-Only RPC ไม่ต้องส่ง Token และไม่จำกัด Role | เหมาะสมอย่างยิ่งสำหรับ **Dev/Admin Dashboard** เพื่อใช้ตรวจสอบว่าตู้ Kiosk นี้ออนไลน์อยู่ไหม มีนักเรียนคนไหนจับคู่อยู่ หรือเซสชันหมดอายุหรือยัง | ปรับโค้ดปุ่มบน UI ให้แสดง Popup สถานะตู้ Kiosk จากผลลัพธ์ของ `check_terminal_pairing_status` |
| **ทางเลือกที่ 2: Scope Down / ตัดฟีเจอร์นี้ออก** | ตัดปุ่ม "ยืนยันการจับคู่" ออกจาก Dashboard เหลือเฉพาะการสแกนอ่านข้อมูล QR ทั่วไป (เช่น ดู Device Serial หรือ JSON Data) | Clean ที่สุดในแง่ Separation of Concerns เพราะการ Pair ตู้เพื่อเข้าใช้งานเป็นพฤติกรรมของนักเรียนบน **User/Mobile App** ไม่ใช่หน้าที่ของแอดมิน | ลบปุ่ม Claim Kiosk ออกจาก BottomSheet ของ Dashboard |
| **ทางเลือกที่ 3: สร้าง Admin Kiosk Provisioning RPC ใหม่** | สร้าง Stored Procedure ใหม่ เช่น `admin_claim_kiosk_terminal(p_pairing_code, p_terminal_name)` ที่อนุญาตให้ Super Admin/School Admin เป็นผู้ Bind ตู้ Kiosk ประจำโรงเรียน | รองรับในกรณีที่มี Requirement จริงว่า **แอดมินหรือครูต้องเป็นผู้เปิดระบบ/อนุมัติตู้ Kiosk** ประจำห้องแล็บ | 1. เขียน Migration สร้าง RPC ใหม่<br/>2. กำหนด RLS ให้ Admin สั่ง Claim ตู้ได้ |

---

## 📊 3. สรุปความคืบหน้าระบบภาพรวม (Dashboard Completion Matrix)

| ส่วนงาน / หน้าจอ | สถานะการเชื่อมต่อจริง | จำนวนหน้า | หมายเหตุ |
| :--- | :---: | :---: | :--- |
| **🟢 Fully Live & Verified (ใช้งานได้จริง 100%)** | ใช้งานได้สมบูรณ์ | **21 หน้า (~78%)** | • `dev_dashboard`, `schools`, `devices`, `device_control`, `alerts_logs`, `settings`<br/>• `school_admin_home`, `school_devices`, `school_users`, `school_classes`, `school_import`, `school_reports`, `school_analytics`<br/>• **+3 หน้าล่าสุด:** `school_admin_profile` (Auth Update), `school_buildings` (Normalized Tables), `school_permissions` (Role RPC) |
| **🟡 Pending Design Decision (รอเลือกแนวทาง)** | รอตัดสินใจ UX | **2 หน้า** | • `kiosk_pairing_scanner_page.dart`<br/>• `school_scan_page.dart` (QR Pairing Mismatch ตามบรีฟนี้) |
| **🔧 Hardware / Lab Simulators** | Sandbox Testing | **4 หน้า** | • `learning_platform_page.dart` (Circuit Simulator / Wokwi Mock data)<br/>• `device_test_page.dart` (Hardware Diagnostics Tool) |
| **รวมทั้งหมด** | | **27 หน้า** | **ความพร้อมใช้งานจริงอยู่ที่ 78% (21/27)** |

---

## 🎯 คำแนะนำในการตัดสินใจ:
* หากต้องการให้ `aiot_dev_dashboard` ทำหน้าที่เป็นเครื่องมือ **ตรวจสอบและวินิจฉัย (Admin Diagnostics)** แนะนำ **ทางเลือกที่ 1** (เรียก `check_terminal_pairing_status`) เพื่อแสดงสถานะตู้ Kiosk สดๆ บนหน้าจอ
