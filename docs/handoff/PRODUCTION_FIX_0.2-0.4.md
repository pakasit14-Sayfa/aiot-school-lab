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

> **ผลตรวจ production จริง 2026-09-09: `homeroom_assignments = 0 แถว` ·
> นักเรียนที่ยังไม่มีห้อง = 3 คน** → **แยกรัน 2 ขั้น อย่ารันรวดเดียว**
> ถ้ารัน 3.5b ตอนนี้จะไม่มีครูคนไหนอนุมัติได้เลยทั้งโรงเรียน

ปัญหา 2 ข้อที่ยังเปิดอยู่บน production:

1. **ครูทุกคนเห็นคำขอผูกบัญชีของทั้งโรงเรียน** — `list_parent_links` กรองแค่
   "นักเรียนอยู่โรงเรียนเดียวกัน" ครูคนไหนก็เห็นชื่อนักเรียนทุกคน + **ชื่อและ
   อีเมลผู้ปกครอง** ทั้งที่ `approve_parent_link` ให้อนุมัติได้แคบกว่านั้นมาก
2. **ครูที่แค่สอนวิชาก็อนุมัติได้** — สเปก STK-1a ระบุว่าเป็นครูประจำชั้น แต่
   RPC เช็คแค่ `course_teachers ⋈ course_students`

> คำสั่งด้านล่างใช้พาธไฟล์แบบสัมพัทธ์ — **ต้อง `cd ~/my_first_app` ก่อน**
> (ถ้ารันจาก `~` จะหาไฟล์ migration ไม่เจอ)

---

### ขั้น 3.5a — ปิดรอยรั่วของรายการ ✅ รันได้เลย ไม่มีเงื่อนไข

หดให้ครูเห็นเฉพาะคำขอที่ตัวเองอนุมัติได้อยู่แล้ว — **ไม่เปลี่ยนว่าใครอนุมัติได้**
จึงไม่มีใครทำงานที่เคยทำได้ไม่ได้ ปิดเรื่องอีเมลผู้ปกครองรั่วได้ทันที

```bash
cd ~/my_first_app
npx supabase db query --linked \
  --file supabase/migrations/20260909000000_scope_list_parent_links_to_approver.sql

npx supabase db query --linked "
insert into supabase_migrations.schema_migrations (version, name)
values ('20260909000000','scope_list_parent_links_to_approver')
on conflict (version) do nothing;
"
```

**ตรวจผล — ต้องได้ `t`:**

```bash
npx supabase db query --linked "
select pg_get_functiondef(oid) like '%course_teachers%' as รายการกรองตามครูผู้สอนแล้ว
from pg_proc where proname = 'list_parent_links';
"
```

---

### ขั้น 3.5b — บีบเป็นครูประจำชั้น ⏸ **รอจนกว่าจะกรอกครูประจำชั้นครบ**

**เงื่อนไขก่อนรัน:** `homeroom_assignments` ต้องมีข้อมูลของปีการศึกษาปัจจุบัน
ครบทุกห้องที่มีนักเรียน (ห้องละ 2 คนได้ตามปกติ) กรอกได้จากแอป:
**School Admin → ครูและบุคลากร → กำหนดครูประจำชั้น** (ใส่ทีละคน กดซ้ำเพื่อเพิ่มคนที่ 2)

เช็คซ้ำก่อนรันทุกครั้ง:

```bash
npx supabase db query --linked "
select
  (select count(*) from homeroom_assignments) as กำหนดครูประจำชั้นแล้วกี่แถว,
  (select count(*) from users u join user_roles r on r.user_id = u.id
    where r.role = 'student'
      and not exists (select 1 from student_profiles sp where sp.student_id = u.id)
  ) as นักเรียนที่ยังไม่มีห้อง;
"
```

`นักเรียนที่ยังไม่มีห้อง` = จำนวนเคสที่ครูจะอนุมัติไม่ได้ ต้องให้แอดมินอนุมัติแทน
(ไม่ตัน แต่ควรรู้ตัวเลขก่อน — วัดได้ 3 คน เมื่อ 2026-09-09)

```bash
cd ~/my_first_app
npx supabase db query --linked \
  --file supabase/migrations/20260909010000_parent_link_homeroom_teacher_only.sql

npx supabase db query --linked "
insert into supabase_migrations.schema_migrations (version, name)
values ('20260909010000','parent_link_homeroom_teacher_only')
on conflict (version) do nothing;
"
```

**ตรวจผล — ต้องได้ `1 | t | t | t`:**

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

**ย้อนกลับ 3.5b ได้** โดยรัน `20260909000000` ทับอีกครั้ง (กลับไปเป็นกฎครูผู้สอน)

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

### ขั้น 4.1 — migration ชุด School Admin 100% (2026-09-14) — 4 ไฟล์ รันตามลำดับ

> ✅ **รันบน production แล้ว 2026-09-17** ด้วย `scripts/prod_apply_2026-09-16.sh` — ตรวจแล้ว: RPC ใหม่ 5 ตัวมีครบ · default ปลอมของ firmware ถูกถอด · `device_effective_status` อ่าน `offline_minutes` แล้ว · `migration list --linked` ทุกแถวมี remote

รันได้เลย ไม่มีเงื่อนไขล่วงหน้า แต่**ต้องรันเรียงตามเลข** และรันในทรานแซกชันเดียว
ต่อไฟล์ (ไฟล์ที่ 4 มี `alter table` + `update` ที่ต้องไปด้วยกัน):

| ลำดับ | ไฟล์ | ทำอะไร | ผลข้างเคียงที่ต้องรู้ |
|---|---|---|---|
| 1 | `20260914010000_school_admin_assets_mutations.sql` | 10 RPC: แก้/ลบ อาคาร-ห้อง · ผู้รับผิดชอบอาคาร · แก้อุปกรณ์ · รับทราบทั้งหมด · สร้างปีการศึกษา/ภาคเรียน | ไม่แตะข้อมูลเดิม |
| 2 | `20260914020000_my_account_password_sessions_import.sql` | change_my_password · list/revoke_my_session · **เขียนทับ** `import_school_users_batch_for_school_admin` | บัญชีที่นำเข้าหลังจากนี้ได้รหัสชั่วคราวสุ่ม + ต้องเปลี่ยนรหัสก่อนใช้ (แอปเวอร์ชันใหม่บังคับ) — **บัญชีที่นำเข้าก่อนหน้าด้วย Test1234! ไม่ถูกแตะ** ถ้ามี ให้สั่ง `update users set must_change_password = true where ...` เอง |
| 3 | `20260914030000_utility_usage_by_location.sql` | get_utility_usage_by_location | ไม่แตะข้อมูลเดิม |
| 4 | `20260914040000_school_device_detail.sql` | get_school_device_detail + **ถอด default ปลอม** `ip_address='192.168.1.100'` / `firmware_version='v1.2.0-prod'` และ **ล้างค่านั้นในอุปกรณ์ที่ไม่เคยส่ง heartbeat** | หน้าอุปกรณ์จะขึ้น "ยังไม่เคยรายงาน" แทนค่าปลอม — ถูกต้องแล้ว |

ตรวจหลังรัน:

```bash
npx supabase db query --linked "select count(*) from pg_proc where proname in ('update_school_building','change_my_password','get_utility_usage_by_location','get_school_device_detail')"
```

ต้องได้ `4` · และ `select column_default from information_schema.columns where table_name='devices' and column_name='firmware_version'` ต้องว่าง

**ต้อง deploy แอปเวอร์ชันที่มี `ForcePasswordChangePage` (commit ชุดนี้) ก่อนหรือพร้อมกัน**
ไม่งั้นบัญชีที่นำเข้าใหม่จะล็อกอินได้ด้วยรหัสชั่วคราวโดยไม่ถูกบังคับเปลี่ยน
(แอปเก่าไม่อ่าน `must_change_password`)

### ขั้น 4.2 — migration Teacher 100% (2026-09-16) — 1 ไฟล์

> ✅ **รันบน production แล้ว 2026-09-17** ด้วย `scripts/prod_apply_2026-09-16.sh` — ตรวจแล้ว: RPC ใหม่ 5 ตัวมีครบ · default ปลอมของ firmware ถูกถอด · `device_effective_status` อ่าน `offline_minutes` แล้ว · `migration list --linked` ทุกแถวมี remote

`20260916010000_list_lesson_progress.sql` — RPC อ่านอย่างเดียว `list_lesson_progress(p_token, p_lesson_id)`
ให้ครูเจ้าของวิชา/school_admin ดูความคืบหน้าบทเรียนรายคน (นักเรียนเขียน `lesson_progress`
มาตั้งแต่แรกแต่ไม่เคยมีตัวอ่านฝั่งครู) ไม่แตะข้อมูลเดิม รันได้ทุกลำดับหลัง 4.1 หรือก่อนก็ได้

ตรวจ: `select count(*) from pg_proc where proname='list_lesson_progress'` → `1`

### ขั้น 4.3 — migration Super Admin 100% (2026-09-16) — 1 ไฟล์

> ✅ **รันบน production แล้ว 2026-09-17** ด้วย `scripts/prod_apply_2026-09-16.sh` — ตรวจแล้ว: RPC ใหม่ 5 ตัวมีครบ · default ปลอมของ firmware ถูกถอด · `device_effective_status` อ่าน `offline_minutes` แล้ว · `migration list --linked` ทุกแถวมี remote

`20260916020000_offline_minutes_enforced.sql` — เขียนทับ `device_effective_status()` ให้อ่าน
`platform_settings.offline_minutes` แทนค่าตายตัว 5 นาที (ค่าใน prod ตอนนี้คือ 5 อยู่แล้ว →
พฤติกรรมไม่เปลี่ยนจนกว่า Super Admin จะแก้ค่าในหน้าตั้งค่า) ไม่แตะข้อมูล

ตรวจ: `select device_effective_status('online', now() - interval '8 minutes')` → `offline`

### ขั้น 4.4 — `set_student_profile` (2026-09-17) — 1 ไฟล์

`20260917010000_set_student_profile.sql` — RPC `set_student_profile(p_token, p_student_id, p_grade_level, p_room)`
(school_admin/super_admin) **ตัวเขียน `student_profiles` ตัวแรกของระบบ** — พบตอนจะกรอกครูประจำชั้นบน prod ว่า
18 RPC อ่านตารางนี้แต่ไม่มีตัวไหนเขียน (local มีข้อมูลเพราะ seed.sql เขียนตรง) + เขียนทับ import RPC ให้รับ
`grade_level`/`room` ต่อแถว ไม่แตะข้อมูลเดิม

```bash
bash scripts/prod_apply_2026-09-17.sh
```

หลังรัน: หน้านักเรียน School Admin → กดรายชื่อ → "กำหนดระดับชั้น / ห้อง" แล้วค่อยไปมอบหมายครูประจำชั้น (ทาง ก)

### ขั้น 4.5 — `delete_school_event` (2026-09-17) — 1 ไฟล์

`20260917020000_delete_school_event.sql` — คู่กับ `create_school_event` ที่มีอยู่แล้วแต่ไม่เคยมีหน้าเรียก
(ปฏิทินทุกบทบาทอ่าน school_events ได้ แต่สร้างจากแอปไม่ได้เลย) ตอนนี้หน้าตั้งค่า School Admin
สร้าง/ลบกิจกรรมได้ · ครูยื่นคำขอเข้าพบ/ไปราชการได้ (RPC มีอยู่แล้ว ไม่ต้อง migrate) ไม่แตะข้อมูลเดิม

```bash
bash scripts/prod_apply_2026-09-17b.sh
```

**✅ รันบน prod แล้ว 2026-09-17** (เจ้าของรันเอง) — verify `delete_school_event_expect_1 = 1`,
`migration list --linked` แสดง `20260917020000` ทั้ง local/remote

### ขั้น 4.6 — งานกลุ่ม PBL-10 (2026-09-18) — 1 ไฟล์

`20260918010000_group_submissions.sql` — `create_assignment`/`update_assignment` รับ `p_is_group`
(เดิม hardcode `false` → สวิตช์ "งานกลุ่ม" ของครูถูกทิ้งเงียบ ๆ มาตลอด) · `submit_assignment` งานกลุ่ม
= กลุ่มของผู้ส่งเป็นเจ้าของแถวเดียว สมาชิกส่งซ้ำเป็นเวอร์ชันถัดไป G-Score ส่งตรงเวลาให้ทุกคน ·
`list_my_submission_versions` สมาชิกเห็นเวอร์ชันร่วม · `list_submissions` เพิ่ม `group_id`/`group_name`
(คอลัมน์เพิ่ม ไม่ลบ) · pgTAP `65_group_submissions` 13/13 บน local · **ไม่แตะข้อมูลเดิม** งานเดี่ยวทำงานเหมือนเดิม

```bash
bash scripts/prod_apply_2026-09-18.sh
```

หลังรัน: ครูสร้างใบงานติ๊ก "งานกลุ่ม" → นักเรียนในกลุ่มเห็นป้าย "งานกลุ่ม" ในแผ่นส่งงาน ·
นักเรียนที่ยังไม่มีกลุ่มจะได้ข้อความบอกให้ครูจัดกลุ่มก่อน

**✅ รันบน prod แล้ว 2026-09-18** (เจ้าของรันเอง) — verify `has_is_group = true` ทั้ง 2 ฟังก์ชัน,
`list_submissions_has_group_name = true`

### ขั้น 4.7 — กราฟของนักเรียน PBL-7 (2026-09-18) — 1 ไฟล์

`20260918020000_charts_rpc.sql` — ตาราง `charts` มีมาตั้งแต่แรกแต่ไม่มี RPC เลย → เพิ่ม
`list_my_sensor_datasets` (ชุดข้อมูลที่ผู้ใช้อ่านได้ พร้อมชื่ออุปกรณ์) · `create_chart` (ตรวจขอบเขตเดียวกับ
`sensor_history`: นักเรียนสร้างได้เฉพาะช่วงที่ครูผูกไว้ในใบงาน/บทเรียน) · `list_my_charts` · `delete_chart` ·
helper `student_sensor_window_allowed` (ไม่ grant ให้ client) · pgTAP `66_charts_rpc` 13/13 · ไม่แตะข้อมูลเดิม

```bash
bash scripts/prod_apply_2026-09-18b.sh
```

หลังรัน: นักเรียน → AIoT Dashboard → "กราฟของฉัน" → สร้างกราฟ (เห็นเฉพาะชุดข้อมูลที่ครูผูก)

**✅ รันบน prod แล้ว 2026-09-18** (เจ้าของรันเอง) — verify `charts_rpc_expect_4 = 4`

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

### 4.8 ✅ รันแล้ว 2026-09-20 — แต่เป็นเวอร์ชันก่อนตรวจ (ต้องรัน 4.9 ซ่อม)

เจ้าของรัน `scripts/prod_apply_2026-09-19.sh` เวอร์ชันแรกของ agy ซึ่งใช้ `npx supabase db push`
→ prod ได้ `20260919000000` ฉบับ `9bd32dc` (ก่อน review fix `5beea08`): ตัว sync จับคู่ห้องแบบ
ตรงตัว (`auto_enrolled = 0`), `set_class_schedule` มี 2 overload, `create_course` ไม่เช็ค
โรงเรียนของ term, ครูยังตั้งตารางได้ · สคริปต์ 09-19 ถูกแทนด้วย stub ที่ exit 1 กันรันซ้ำ

### 4.9 (รอเจ้าของรัน) ซ่อม D6 เฟส 1 บน prod ให้ตรงกับฉบับที่ตรวจแล้ว

migration `20260920000000_d6_phase1_prod_repair.sql` — ทุกคำสั่ง idempotent (CREATE OR REPLACE /
DROP IF EXISTS / guarded) · ทดสอบ local ด้วยการจำลอง "ก่อน D6 → ฉบับ 9bd32dc → ซ่อม" ใน
transaction เดียวแล้ว overload เหลือ 1, `_class_room_key` มา, `create_course` เช็คโรงเรียน ·
ทั้งชุด 65 ไฟล์ PASS หลังเพิ่ม migration นี้

```bash
bash scripts/prod_apply_2026-09-20.sh
```

verify ในสคริปต์: `set_class_schedule_overloads = 1` · `room_key_fn = 1` ·
`create_course_checks_school = true` · **`auto_enrolled = 3`** (นักเรียน ม.1/1 ทั้ง 3 คน
เข้าคอร์สคณิตศาสตร์ ม.1/1) — ถ้าไม่ตรง หยุดแล้วบอก

### 4.10 ✅ รันแล้ว 2026-09-20 — sensor_history ย่อข้อมูลตามช่วง — เลิกโดนตัดที่ 1,000 แถว

migration `20260920020000_sensor_history_downsample.sql` · pgTAP `69_sensor_history_downsample` 8/8 ·
เพิ่ม `p_max_points integer default 1000` — RPC จัด bucket เฉลี่ยตามช่วงของข้อมูลที่มีจริง
ผู้เรียกเดิมไม่ต้องแก้

```bash
bash scripts/prod_apply_2026-09-20b.sh
```

ผล: `has_max_points = true`, `overloads = 1`, raw 30 วัน = 20,812 แถว → แอปนักเรียนเห็น 135 จุด ครบ 29/8 09:46 – 2/9 14:06 (ต่ำสุด 23.6 / เฉลี่ย 28.4 / สูงสุด 32.8 °C) แกน X มีวันที่ · เดิมคาดว่า: เปิดแอปนักเรียน → ชุดข้อมูลอุณหภูมิ 21/8–20/9
ต้องเห็นทั้งชุด 29 ส.ค. (ไม่ใช่แค่ 09:48–10:37) และแกน X มีวันที่

### 4.11 ✅ รันแล้ว 2026-09-20 — D6 เฟส 2 — RPC ที่หน้าจัดตารางแอดมินต้องใช้

migration `20260920030000_timetable_phase2_rpc_fixes.sql` · pgTAP 68 30/30 (+4) · ทั้งชุด 66 ไฟล์ 1,078 เคส PASS
- `list_teacher_subjects(p_token, null)` โดยแอดมิน = ครูทุกคนในโรงเรียน + `teacher_name` (เดิม forbidden → หน้าจัดตารางเปิดไม่ขึ้น)
- `admin_set_room_timetable_slot` บังคับครู (`teacher_required`) และจำคู่ครู↔วิชาลง `teacher_subjects` ให้เอง

```bash
bash scripts/prod_apply_2026-09-20c.sh
```
verify: `returns_teacher_name = true`, `slot_records_subject = true`

### 4.12 ✅ รันแล้ว 2026-09-20 — list_school_classes — cast varchar→text

หน้าจัดตารางเรียนบน iPhone โหลดไม่ขึ้น: `list_school_classes` ประกาศคืน text แต่ select varchar
ตรง ๆ → 42804 · pgTAP 68 เพิ่ม 5 เคส "RPC ที่หน้านี้เรียกต้องรันได้" (35/35)

```bash
bash scripts/prod_apply_2026-09-20d.sh
```
verify: `casts_to_text = true`

### 4.13 ✅ รันแล้ว 2026-09-20 — ตารางเรียน: อ่าน/ล้างช่องต้องจับคู่ห้องผ่าน `_class_room_key`

จัดคาบจริงบน prod สำเร็จ (จันทร์ คาบ 1 คณิตศาสตร์ ม.1/1 บันทึกลง `class_schedules` แล้ว) แต่กริดไม่แสดง
เพราะ `list_room_timetable` เทียบ `c.room = p_room` ตรงตัว ('ม.1/1' ≠ '1') · migration `20260920050000`
แก้ทั้ง list และ clear · pgTAP 68 40/40

```bash
bash scripts/prod_apply_2026-09-20e.sh
```
ผล: ทั้งคู่ true · iPhone: กริดห้อง ม.1/1 แสดง จันทร์/คาบ 1 = คณิตศาสตร์ · ครู ทดสอบ ✅ — **D6 ครบวงจรบน prod**: แอดมินตั้งคาบ → จัดวิชาลงห้อง → นักเรียนในห้องเห็นวิชา

### 4.14 ✅ รันแล้ว 2026-09-20 22:37 — ตารางเรียน v2 — ทั้งโรงเรียน → ม.ต้น/ม.ปลาย → ห้อง

migration `20260921000000_timetable_v2.sql` · pgTAP `70_timetable_v2` 20/20 · ทั้งชุด PASS
- `school_periods.kind` lesson/break (พักกลางวัน) · `set_school_periods` ตรวจทับซ้อน
- `list_timetable_overview` (ห้องทั้งปี + จัดแล้วกี่คาบ) · `list_teacher_week` · `list_teacher_conflicts` (ครูชน)
- `admin_copy_room_timetable` (จากห้องอื่น/เทอมอื่น) · `admin_clear_room_timetable`
- `admin_set_room_timetable_slot` ปฏิเสธคาบพัก (`period_is_break`)

```bash
bash scripts/prod_apply_2026-09-21.sh
```
ผล: 5 / true · iPhone: ภาพรวมเห็น ม.1/1 1/40 → หน้าห้อง จันทร์ คาบ 1 คณิต → แตะคาบ 2 เลือกจาก "วิชาที่ห้องนี้เรียนอยู่" แตะเดียว บันทึก → 2/40 ✅

### 4.15 (รอเจ้าของรัน) list_assignments คืนตัวเลขจริง (ส่งแล้ว / รอตรวจ / ทั้งหมด / ชุดข้อมูล)

migration `20260921010000_list_assignments_counts.sql` · pgTAP 11 +4 (19/19) · ทั้งชุด PASS
แท็บใบงานครูแบบใหม่ (รายการ iOS) ใช้ตัวเลขชุดนี้ · ก่อนรัน แอปจะแสดง 0 ทุกช่อง (ไม่พัง)

```bash
bash scripts/prod_apply_2026-09-21b.sh
```
verify: `has_counts = true`

