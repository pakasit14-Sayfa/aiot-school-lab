# คำสั่งปิดช่องโหว่บน production (ticket 0.2–0.4 + สิทธิ์อนุมัติผู้ปกครอง)

Claude ถูกระบบความปลอดภัยบล็อกไม่ให้ link/เขียน production จึงเตรียมคำสั่งไว้ให้รันเอง
รันตามลำดับ **1 → 2 → 3** และหยุดทันทีถ้าขั้นไหนผลไม่ตรงกับที่คาด

> โปรเจกต์ production: `smqoknnftgjyhrnzugar` (`aiot-school-lab-cli`)
> เช็คเอาต์นี้ยัง `linked: false` — ต้อง link ก่อน

---

## ขั้นที่ 0 — เชื่อมต่อ production

```bash
cd ~/my_first_app
npx supabase link --project-ref smqoknnftgjyhrnzugar
```

(อาจถามรหัสผ่านฐานข้อมูล — เป็นรหัสของ project ไม่ใช่รหัสบัญชี Supabase)

---

## ขั้นที่ 1 — ดูสถานะก่อนแก้ (อ่านอย่างเดียว ยังไม่เปลี่ยนอะไร)

```bash
npx supabase db query --linked "
select
  has_function_privilege('anon','redeem_parent_binding_code(text,text,text,text,text,text)','execute') as anon_ยังเรียกได้,
  has_function_privilege('authenticated','redeem_parent_binding_code(text,text,text,text,text,text)','execute') as auth_ยังเรียกได้;
"
```

**คาดว่าจะได้ `t | t`** = ช่องโหว่ยังเปิดอยู่จริง
ถ้าได้ `f | f` แปลว่ามีคนปิดไปแล้ว — **ข้ามขั้นที่ 2 ไปเลย**

---

## ขั้นที่ 2 — 🔐 ปิดช่องโหว่ `redeem_parent_binding_code`

ช่องโหว่นี้คืออะไร: เป็น endpoint รุ่นเก่าที่ผูกบัญชีผู้ปกครองเข้ากับนักเรียน
**โดยข้ามขั้นตอนยืนยัน OTP** ถูกเปิดค้างไว้ตั้งแต่ 2026-09-04 เพื่อความสะดวกตอนพัฒนา
ระบบจริงใช้ `request_parent_binding_otp` + `confirm_parent_binding` ซึ่งไม่กระทบ

```bash
npx supabase db query --linked "
revoke execute on function redeem_parent_binding_code(text,text,text,text,text,text)
  from anon, authenticated;
"
```

**ตรวจผลทันที:**

```bash
npx supabase db query --linked "
select
  has_function_privilege('anon','redeem_parent_binding_code(text,text,text,text,text,text)','execute') as anon_ยังเรียกได้,
  has_function_privilege('authenticated','redeem_parent_binding_code(text,text,text,text,text,text)','execute') as auth_ยังเรียกได้;
"
```

**ต้องได้ `f | f`** ถ้ายังเป็น `t` แปลว่า revoke ไม่ติด อย่าไปต่อ

---

## ขั้นที่ 3 — 🔐 ปิด audit-log รั่วข้ามโรงเรียน

ปัญหา: `list_school_admin_audit_logs` มีเงื่อนไข `OR al.school_id IS NULL`
ทำให้ผู้ดูแลโรงเรียนเห็น log ที่ไม่ผูกกับโรงเรียนไหนเลย (เช่น การรีเซ็ตรหัสผ่าน,
เหตุการณ์ login/2FA ของทั้งระบบ) ทั้งที่ควรเห็นเฉพาะของโรงเรียนตัวเอง
migration นี้แก้แล้วและทดสอบผ่าน 9/9 บนเครื่อง local แต่ยังไม่เคยขึ้น production

```bash
npx supabase db query --linked \
  --file supabase/migrations/20260905040000_harden_school_admin_audit_scope.sql
```

**บันทึกลงประวัติ migration** (ถ้าไม่ทำ ประวัติจะไม่ตรงกับของจริง — เป็นปัญหาที่เกิดซ้ำในโปรเจกต์นี้):

```bash
npx supabase db query --linked "
insert into supabase_migrations.schema_migrations (version, name)
values ('20260905040000','harden_school_admin_audit_scope')
on conflict (version) do nothing;
"
```

**ตรวจผล:**

```bash
npx supabase db query --linked "
select
  pg_get_functiondef(oid) like '%school_id IS NULL%' as ยังรั่วอยู่ไหม,
  has_function_privilege('service_role','list_school_admin_audit_logs(text,integer)','execute') as service_role_ยังเรียกได้
from pg_proc where proname = 'list_school_admin_audit_logs';
"
```

**ต้องได้ `f | f`** (ไม่รั่วแล้ว และ `service_role` ถูก revoke แล้ว)

---

## ขั้นที่ 3.5 — 🔐 ปิดสิทธิ์อนุมัติผูกบัญชีผู้ปกครองที่กว้างเกินไป (เพิ่ม 2026-09-09)

ปัญหา 2 ข้อที่ยังเปิดอยู่บน production:

1. **ครูทุกคนเห็นคำขอผูกบัญชีของทั้งโรงเรียน** — `list_parent_links` กรองแค่
   "นักเรียนอยู่โรงเรียนเดียวกัน" ครูคนไหนก็เห็นชื่อนักเรียนทุกคน + **ชื่อและ
   อีเมลผู้ปกครอง** ทั้งที่ `approve_parent_link` ให้อนุมัติได้แคบกว่านั้นมาก
2. **ครูที่แค่สอนวิชาก็อนุมัติได้** — สเปก STK-1a ระบุว่าเป็นครูประจำชั้น แต่
   RPC เช็คแค่ `course_teachers ⋈ course_students` ครูสอนวิชาใดก็ได้ที่เจอเด็ก
   สัปดาห์ละคาบจึงตัดสินได้ว่าใครมีสิทธิ์เห็นข้อมูลเด็กคนนั้น

แก้แล้ว 2 migration ทดสอบผ่านบน local (pgTAP 48: 7/7 · 49: 9/9)

> **ตรวจความพร้อมของข้อมูลก่อนรัน** — หลังแก้ ครูจะอนุมัติได้เฉพาะห้องที่ตัวเอง
> เป็นครูประจำชั้น ถ้าโรงเรียนยังไม่ได้กรอกข้อมูลนี้ คำขอจะไปกองที่ฝ่ายทะเบียน
> (ไม่ตัน แต่ควรรู้ตัวเลขก่อน):
>
> ```bash
> npx supabase db query --linked "
> select
>   (select count(*) from homeroom_assignments) as กำหนดครูประจำชั้นแล้วกี่แถว,
>   (select count(*) from users u join user_roles r on r.user_id = u.id
>     where r.role = 'student') as นักเรียนทั้งหมด,
>   (select count(*) from users u join user_roles r on r.user_id = u.id
>     where r.role = 'student'
>       and not exists (select 1 from student_profiles sp where sp.student_id = u.id)
>   ) as นักเรียนที่ยังไม่มีห้อง;
> "
> ```
>
> `นักเรียนที่ยังไม่มีห้อง` คือจำนวนเคสที่ครูจะอนุมัติไม่ได้เลย ต้องให้แอดมิน
> อนุมัติแทน ถ้าเลขนี้สูงมาก ให้กรอกห้อง/ครูประจำชั้นให้ครบก่อนค่อยรันขั้นนี้

```bash
npx supabase db query --linked \
  --file supabase/migrations/20260909000000_scope_list_parent_links_to_approver.sql
npx supabase db query --linked \
  --file supabase/migrations/20260909010000_parent_link_homeroom_teacher_only.sql
```

**บันทึกลงประวัติ migration:**

```bash
npx supabase db query --linked "
insert into supabase_migrations.schema_migrations (version, name) values
  ('20260909000000','scope_list_parent_links_to_approver'),
  ('20260909010000','parent_link_homeroom_teacher_only')
on conflict (version) do nothing;
"
```

**ตรวจผล:**

```bash
npx supabase db query --linked "
select
  (select count(*) from pg_proc where proname = '_is_homeroom_teacher_of') as มีฟังก์ชันกลางแล้ว,
  (select pg_get_functiondef(oid) like '%_is_homeroom_teacher_of%'
     from pg_proc where proname = 'approve_parent_link') as อนุมัติใช้กฎครูประจำชั้น,
  (select pg_get_functiondef(oid) like '%_is_homeroom_teacher_of%'
     from pg_proc where proname = 'reject_parent_link') as ปฏิเสธใช้กฎครูประจำชั้น,
  (select pg_get_functiondef(oid) like '%_is_homeroom_teacher_of%'
     from pg_proc where proname = 'list_parent_links') as รายการใช้กฎครูประจำชั้น;
"
```

**ต้องได้ `1 | t | t | t`** — ถ้าตัวใดเป็น `f` แปลว่า migration ไม่ติดครบ อย่าไปต่อ

---

## ขั้นที่ 4 — ตรวจว่า migration ทุกตัวขึ้น production ครบ

โปรเจกต์นี้มีประวัติ **"ไฟล์ migration มีอยู่ แต่ไม่เคยถูกรันจริง"** ซ้ำหลายรอบ
รวมถึงครั้งที่ production ค้างอยู่ที่ snapshot เก่ากว่าเดือนโดยไม่มีใครรู้

```bash
npx supabase migration list --linked
```

ดูคอลัมน์ `Local | Remote` — **ทุกแถวต้องมีเลขทั้งสองฝั่ง**
แถวไหนมีแค่ฝั่ง Local = ยังไม่เคยขึ้น production ให้รันทีละไฟล์:

```bash
npx supabase db query --linked --file supabase/migrations/<ชื่อไฟล์>.sql
npx supabase db query --linked "
insert into supabase_migrations.schema_migrations (version, name)
values ('<timestamp>','<ชื่อ_ไม่รวม_timestamp>') on conflict (version) do nothing;
"
```

---

## ขั้นที่ 5 — ทดสอบว่าระบบยังใช้งานได้จริงหลังแก้

```bash
curl -s -X POST "https://smqoknnftgjyhrnzugar.supabase.co/rest/v1/rpc/auth_sign_in" \
  -H "apikey: <ANON_KEY_ของ_production>" \
  -H "Content-Type: application/json" \
  -d '{"p_email":"schooladmin@aiot-school-lab.local","p_password":"Test1234!"}'
```

**ต้องได้ `auth_state: "mfa_required"`** = ระบบล็อกอินยังทำงานปกติ ไม่พังจากการแก้

---

## ถ้ามีอะไรผิดพลาด — วิธีย้อนกลับ

ขั้นที่ 2 (ถ้าจำเป็นต้องเปิดชั่วคราวอีกครั้ง — **ไม่แนะนำ**):
```sql
grant execute on function redeem_parent_binding_code(text,text,text,text,text,text)
  to anon, authenticated;
```

ขั้นที่ 3 คือ `create or replace function` — ย้อนได้โดยรัน migration ตัวก่อนหน้า
`supabase/migrations/20260826140000_super_admin_audit_logs_scope.sql`
(แต่การย้อนจะเปิดช่องรั่วกลับมา)

---

## เสร็จแล้วบอก Claude

ส่งผลลัพธ์ของขั้นที่ 2, 3, 3.5, 5 กลับมา แล้ว Claude จะติ๊ก ticket 0.2–0.4
ใน `MASTER_PLAN_2026-09-06.md` ให้ — **จะไม่ติ๊กจนกว่าจะเห็นผลลัพธ์จริง**
