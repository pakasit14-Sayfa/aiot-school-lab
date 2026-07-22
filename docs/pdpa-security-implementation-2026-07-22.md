# สรุปการทำ PDPA/Security Gate — 2026-07-22

> สถานะ: งานเทคนิคใน local source เสร็จและผ่าน automated tests แล้ว  
> ยังไม่ใช่การรับรองทางกฎหมาย และยังไม่ได้ deploy ไป Supabase production

## ที่มาของงาน

- งาน Sensor, MQTT, Dashboard และ Relay เดิมเป็นงานที่เจ้าของโครงการทำร่วมกับ **Claude** ตามบันทึกวันที่ 2026-07-20 ถึง 2026-07-21
- ไฟล์ `supabase/migrations/20260721010000_relay_commands.sql` เป็นงานเดิมจาก Claude และถูกเก็บไว้โดยไม่แก้ประวัติหรืออ้างว่าเป็นงานใหม่
- งานในเอกสารนี้เป็นการปิด 4 Security Gate ที่ดำเนินการต่อโดย **Codex**: RLS/RPC isolation, Parent Binding/Consent, Session Token และ Rate Limit

## 1. RLS และการแยกข้อมูลข้ามโรงเรียน

- เปิด RLS ให้ทุกตารางใน `public` โดยอัตโนมัติ
- ถอนสิทธิ์เข้าตารางและ sequence โดยตรงจาก `PUBLIC`, `anon` และ `authenticated`
- ถอน implicit `PUBLIC EXECUTE` จาก `SECURITY DEFINER` functions ทั้งหมด
- ใช้สถาปัตยกรรม RPC-only ตาม custom session ของโครงการ: client เข้าได้เฉพาะ RPC ที่ allow-list และทุก RPC ต้องตรวจ Active Role + Active School
- เพิ่ม negative tests ยืนยันว่า School Admin โรงเรียน A อ่าน แก้ผู้ใช้ หรือให้ role ในโรงเรียน B ไม่ได้

หมายเหตุ: ระบบนี้ไม่ได้ใช้ Supabase Auth JWT จึงไม่สร้าง direct-table RLS policy แบบ `auth.uid()` การใช้ deny-all RLS + ถอน table grants + RPC ที่ตรวจ tenant พร้อม integration tests เป็นขอบเขตป้องกันที่ใช้งานจริงของสถาปัตยกรรมปัจจุบัน

## 2. Parent Binding และ Consent

- Binding Code ใช้ครั้งเดียว อายุ 7 วัน และจำกัดไม่เกิน 2 ผู้ปกครองต่อนักเรียน
- ขอ OTP ผ่าน Edge Function โดยไม่เปิดเผยว่านักเรียนหรือรหัสมีอยู่จริง
- OTP เป็นตัวเลข 6 หลัก อายุ 10 นาที จำกัดการส่งและจำกัดการกรอกผิด
- app ได้เฉพาะ opaque verification token; plaintext OTP คืนให้ `service_role` ภายในเพื่อส่งอีเมลเท่านั้น
- ยังไม่ให้ parent role หรือ session ก่อนโรงเรียนอนุมัติ Parent Link
- บล็อกการอนุมัติตนเอง และรองรับ second review โดย School Admin คนละคน
- รองรับการปฏิเสธพร้อมเหตุผลและ Audit Log
- ผู้ปกครองดู policy version, HTTPS URL และ SHA-256 ก่อนให้หรือถอน Consent
- เก็บ `consent_events` แบบ append-only และเก็บ Audit Log ทุก transition
- เพิ่มหน้า School Admin สำหรับสร้าง/publish/retire Consent Policy
- policy ทุก version บังคับ HTTPS URL, SHA-256 64 ตัวอักษร, school scope และสถานะ required/optional
- การ retire ไม่ลบ policy หรือหลักฐาน Consent เดิม

## 3. Session Token

- ย้าย `session_token` จาก `SharedPreferences` ไป `flutter_secure_storage`
- migration token เก่าทำครั้งเดียวและลบ plaintext copy เสมอ
- token ฝั่งฐานข้อมูลเก็บเฉพาะ SHA-256 hash
- session หมดอายุ 7 วันและจำกัดไม่เกิน 5 session ที่ active ต่อบัญชี
- เพิ่ม `auth_sign_out_all` เพื่อ revoke ทุกอุปกรณ์ พร้อม Audit Log
- เชื่อมปุ่ม “ออกจากระบบทั้งหมด” เข้ากับ RPC จริง
- ลบ dead-code auth จำลองที่เคยเก็บอีเมลและรหัสผ่าน plaintext ใน `SharedPreferences`

## 4. Login Rate Limit

- ย้าย public login ไป Edge Function `auth-sign-in`
- ถอนสิทธิ์ `anon`/`authenticated` ไม่ให้เรียก `auth_sign_in` RPC โดยตรง
- ให้ Edge Function ใช้ `service_role` เรียก RPC ภายในเท่านั้น
- จำกัดตามบัญชี: ผิด 5 ครั้งใน 15 นาที บล็อก 15 นาที
- จำกัดตาม IP ที่ hash แล้ว: ผิด 20 ครั้งใน 15 นาที บล็อก 15 นาที
- Edge สร้าง HMAC-SHA256 fingerprint ด้วย `LOGIN_IP_PEPPER` (fallback เป็น service-role secret ฝั่ง server)
- ฐานข้อมูลรับและเก็บเฉพาะ fingerprint 64 ตัวอักษร ไม่รับหรือเก็บ IP plaintext
- ล้างค่า `sessions.ip_address` แบบ plaintext จาก flow เก่าเมื่อ apply migration
- ผลตอบกลับกรณีบัญชีผิด, ถูกบล็อก หรือไม่มีบัญชีเป็นรูปแบบกลางเพื่อลด account enumeration

## 5. ไฟล์สำคัญที่เพิ่มหรือแก้

- `supabase/migrations/20260721020000_pdpa_security_hardening.sql`
- `supabase/functions/auth-sign-in/index.ts`
- `supabase/functions/request-parent-binding-otp/index.ts`
- `supabase/tests/database/03_auth_session_rate_limit.test.sql`
- `supabase/tests/database/04_parent_binding_consent.test.sql`
- `supabase/tests/database/05_tenant_isolation.test.sql`
- `supabase/tests/database/06_consent_policy_admin.test.sql`
- `packages/shared_core/lib/services/session_token_storage.dart`
- `packages/shared_core/lib/services/auth_service.dart`
- `packages/shared_core/lib/pages/parent_consent_page.dart`
- `packages/shared_core/lib/pages/consent_policy_admin_page.dart`
- `apps/user_app/lib/pages/profile_page.dart`

## 6. ผลทดสอบ

| รายการ | ผล |
|---|---:|
| Supabase migration จากฐานข้อมูลว่าง | ผ่าน |
| pgTAP database/security tests | 56/56 ผ่าน |
| Edge security source regression | 3/3 ผ่าน |
| shared_core unit tests | 10/10 ผ่าน |
| user_app widget test | 1/1 ผ่าน |
| user_app/shared_core analyzer hard error | 0 |
| admin_app analyzer | ผ่าน ไม่มี issue |
| Edge login invalid/success integration | ผ่านทั้งสองกรณี |
| Auth timing probe | ก่อนแก้ 193.8/2.4 ms; หลังแก้ 92.5/80.0 ms |
| Parent OTP HTTP timing (warm) | invalid 0.366s; valid 0.375s |
| Operational email alert | สร้าง durable alert สำเร็จเมื่อ provider config หาย |
| Flutter Web production build | ผ่าน |
| Secret scan ใน source | ไม่พบ secret จริง; พบเพียงค่าตัวอย่างใน comment ของ config |

## 7. สิ่งที่ยังต้องทำก่อนใช้ข้อมูลจริง

- deploy migration และ Edge Functions แบบ coordinated ไปยัง Supabase remote หลังผ่าน review
- กรอกและอนุมัติ Privacy Notice, Controller/Processor, Legal Basis, Retention, DPA และ cross-border assessment โดยโรงเรียน/DPO/ที่ปรึกษากฎหมาย
- ตั้งค่าและทดสอบผู้ส่งอีเมลจริงสำหรับ OTP
- ทำ 2FA/Trusted Device/Active Role + Active School ตาม scope F02 ที่อยู่นอก 4 gate รอบนี้
- ห้ามเปิดระบบกล้องหรือข้อมูลชีวมิติจนกว่า Camera DPIA และ approval gate จะผ่าน
- ทดสอบ Relay กับฮาร์ดแวร์จริงแยกต่างหาก; งานนี้ไม่สามารถยืนยันจากซอฟต์แวร์เพียงอย่างเดียว

## 8. ผล Claude `/redteam` และการแก้ไข

เจ้าของโครงการนำผลตรวจจาก Claude `/redteam` มาให้ Codex โดยพบ Blocker ทางเทคนิค 2 จุดและข้อเสนอเร่งด่วน 3 จุด

| ข้อค้นพบจาก Claude | ผู้แก้ | สถานะ |
|---|---|---|
| `auth_sign_in` ข้าม bcrypt เมื่อไม่พบ user | Codex | แก้ด้วย dummy bcrypt hash และวัด timing ซ้ำผ่าน |
| Parent OTP รอ Resend เฉพาะ valid code | Codex | ย้ายไป `EdgeRuntime.waitUntil` และบังคับเวลาตอบขั้นต่ำ |
| `sessions.ip_address` เป็น plaintext | Codex | ล้างค่าเดิมและเก็บเฉพาะ HMAC fingerprint |
| IP hash เดา IPv4 ย้อนกลับได้ | Codex | เพิ่ม server-side pepper/HMAC ก่อนส่งเข้าฐานข้อมูล |
| Resend ล้มเหลวไม่มี alert | Codex | เพิ่ม durable `operational_alerts` และ optional alert webhook |
| Privacy Notice/DPA ยังไม่อนุมัติ | โรงเรียน/DPO/กฎหมาย | ยังเป็น blocker ทางกฎหมายก่อนใช้ข้อมูลจริง |
