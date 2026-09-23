#!/usr/bin/env bash
# Rename www.pakasit14@gmail.com to match its "ทุกสิทธิ์" identity, and merge
# the duplicate www.pakasit14+admin@gmail.com account into it.
#
# รันจาก repo root:  bash scripts/prod_apply_2026-09-23d.sh
#
# ทำไมต้องมี: เจ้าของงานมี 2 บัญชีบน prod ที่เป็นคนเดียวกัน (สร้างเวลาเดียวกันเป๊ะ
# 2026-07-18 08:03:58) — www.pakasit14@gmail.com (6 role: teacher/school_admin/
# super_admin/executive/student/parent, ชื่อยังเป็น "นักเรียน คนที่1" ค้างจาก
# ตอนสมัครแรก) กับ www.pakasit14+admin@gmail.com (role เดียว: school_admin,
# ชื่อ "แอดมิน โรงเรียน") บัญชี +admin ไม่ได้ว่างเปล่า — สร้างวิชาคณิตศาสตร์,
# เชิญ/ให้สิทธิ์ teacher@aiot-school-lab.local, อนุมัติ parent_links, ออกรหัส
# parent binding, และลงทะเบียนนักเรียนไว้จริง ต้องย้ายประวัติทั้งหมดไปบัญชีหลัก
# ก่อนลบ ไม่ใช่ลบทิ้งเฉย ๆ
set -euo pipefail
cd "$(dirname "$0")/.."

MAIN="www.pakasit14@gmail.com"
DUP="www.pakasit14+admin@gmail.com"

echo "== ก่อนแก้ (ยืนยันบัญชีทั้งสองยังอยู่)"
npx supabase db query --linked "
  select email, first_name, last_name from users where email in ('$MAIN','$DUP');" < /dev/null

echo
echo "== 0) ด่านตรวจก่อนแตะอะไร — ไล่ FK ที่ชี้มาที่ users.id ทุกคอลัมน์"
echo "      (หยุดทันทีถ้าบัญชีซ้ำถูกอ้างถึงในตารางที่ FK เป็น CASCADE/SET NULL"
echo "       เพราะการลบจะลากข้อมูลนั้นหายไปด้วยโดยไม่มีคำเตือน)"
npx supabase db query --linked "
  do \$\$
  declare
    dup_id uuid := (select id from users where email = '$DUP');
    r record; n bigint;
    destructive text[] := '{}';
    remaining   text[] := '{}';
  begin
    if dup_id is null then
      raise notice 'ไม่พบบัญชี $DUP — ข้ามการตรวจ';
      return;
    end if;

    for r in
      select distinct tc.table_name, kcu.column_name, rc.delete_rule
      from information_schema.table_constraints tc
      join information_schema.key_column_usage kcu
        on kcu.constraint_name = tc.constraint_name
      join information_schema.constraint_column_usage ccu
        on ccu.constraint_name = tc.constraint_name
      join information_schema.referential_constraints rc
        on rc.constraint_name = tc.constraint_name
      where tc.constraint_type = 'FOREIGN KEY'
        and tc.table_schema = 'public'
        and ccu.table_name = 'users' and ccu.column_name = 'id'
    loop
      execute format('select count(*) from public.%I where %I = \$1',
                     r.table_name, r.column_name)
        into n using dup_id;
      if n > 0 then
        if r.delete_rule in ('CASCADE', 'SET NULL') then
          destructive := destructive ||
            format('%s.%s [%s] %s แถว', r.table_name, r.column_name, r.delete_rule, n);
        else
          remaining := remaining ||
            format('%s.%s %s แถว', r.table_name, r.column_name, n);
        end if;
      end if;
    end loop;

    if array_length(destructive, 1) is not null then
      raise exception E'หยุด — ลบบัญชีนี้แล้วข้อมูลจะหายตามไปเงียบ ๆ (FK เป็น CASCADE/SET NULL):\n  %\n\nต้องย้ายข้อมูลพวกนี้ไปบัญชีหลักก่อน แล้วค่อยรันใหม่',
        array_to_string(destructive, E'\n  ');
    end if;

    if array_length(remaining, 1) is not null then
      raise notice E'ยังมีอ้างอิงที่ต้องย้ายในขั้นถัดไป (ปกติ):\n  %',
        array_to_string(remaining, E'\n  ');
    end if;

    raise notice 'ตรวจผ่าน';
  end \$\$;
" < /dev/null

echo
echo "== 1) เปลี่ยนชื่อบัญชีหลักให้ตรงกับ 'ทุกสิทธิ์'"
npx supabase db query --linked "
  update users set first_name = 'ทดสอบ', last_name = 'ทุกสิทธิ์'
  where email = '$MAIN';" < /dev/null

echo
echo "== 2) ย้ายประวัติทั้งหมดจากบัญชี +admin ไปบัญชีหลัก"
npx supabase db query --linked "
  do \$\$
  declare
    main_id uuid := (select id from users where email = '$MAIN');
    dup_id  uuid := (select id from users where email = '$DUP');
  begin
    update courses set created_by = main_id where created_by = dup_id;
    update users set created_by = main_id where created_by = dup_id;
    update user_roles set granted_by = main_id where granted_by = dup_id;
    update user_invitations set invited_by = main_id where invited_by = dup_id;
    update parent_binding_codes set issued_by = main_id where issued_by = dup_id;
    update parent_links set first_reviewed_by = main_id where first_reviewed_by = dup_id;
    update parent_links set approved_by = main_id where approved_by = dup_id;
    update course_students set enrolled_by = main_id where enrolled_by = dup_id;
    update audit_logs set user_id = main_id where user_id = dup_id;
    delete from sessions where user_id = dup_id;
    delete from otp_codes where user_id = dup_id;
    delete from trusted_devices where user_id = dup_id;
    delete from user_roles where user_id = dup_id;
  end \$\$;" < /dev/null

echo
echo "== 2.5) ด่านตรวจซ้ำก่อนลบจริง — ต้องไม่เหลืออ้างอิงใดเลย"
npx supabase db query --linked "
  do \$\$
  declare
    dup_id uuid := (select id from users where email = '$DUP');
    r record; n bigint;
    destructive text[] := '{}';
    remaining   text[] := '{}';
  begin
    if dup_id is null then
      raise notice 'ไม่พบบัญชี $DUP — ข้ามการตรวจ';
      return;
    end if;

    for r in
      select distinct tc.table_name, kcu.column_name, rc.delete_rule
      from information_schema.table_constraints tc
      join information_schema.key_column_usage kcu
        on kcu.constraint_name = tc.constraint_name
      join information_schema.constraint_column_usage ccu
        on ccu.constraint_name = tc.constraint_name
      join information_schema.referential_constraints rc
        on rc.constraint_name = tc.constraint_name
      where tc.constraint_type = 'FOREIGN KEY'
        and tc.table_schema = 'public'
        and ccu.table_name = 'users' and ccu.column_name = 'id'
    loop
      execute format('select count(*) from public.%I where %I = \$1',
                     r.table_name, r.column_name)
        into n using dup_id;
      if n > 0 then
        if r.delete_rule in ('CASCADE', 'SET NULL') then
          destructive := destructive ||
            format('%s.%s [%s] %s แถว', r.table_name, r.column_name, r.delete_rule, n);
        else
          remaining := remaining ||
            format('%s.%s %s แถว', r.table_name, r.column_name, n);
        end if;
      end if;
    end loop;

    if array_length(destructive, 1) is not null then
      raise exception E'หยุด — ลบบัญชีนี้แล้วข้อมูลจะหายตามไปเงียบ ๆ (FK เป็น CASCADE/SET NULL):\n  %\n\nต้องย้ายข้อมูลพวกนี้ไปบัญชีหลักก่อน แล้วค่อยรันใหม่',
        array_to_string(destructive, E'\n  ');
    end if;

    if array_length(remaining, 1) is not null then
      raise exception E'หยุด — ยังมีอ้างอิงค้างที่ขั้นที่ 2 ไม่ได้ย้าย ลบไม่ผ่านแน่นอน:\n  %\n\nเพิ่ม update ของตารางพวกนี้ในขั้นที่ 2 ก่อน',
        array_to_string(remaining, E'\n  ');
    end if;

    raise notice 'ตรวจผ่าน';
  end \$\$;
" < /dev/null

echo
echo "== 3) ลบบัญชี +admin ที่ซ้ำ"
npx supabase db query --linked "
  delete from users where email = '$DUP';" < /dev/null

echo
echo "== verify 1 (บัญชี +admin ต้องหายไป บัญชีหลักต้องมีชื่อใหม่)"
npx supabase db query --linked "
  select email, first_name, last_name from users where email in ('$MAIN','$DUP');" < /dev/null

echo
echo "== verify 2 (บัญชีหลักต้องมีครบ 6 role เหมือนเดิม)"
npx supabase db query --linked "
  select role from user_roles ur join users u on u.id = ur.user_id
  where u.email = '$MAIN' order by role;" < /dev/null

echo
echo "== verify 3 (วิชาคณิตศาสตร์ยังต้องผูกกับบัญชีหลัก)"
npx supabase db query --linked "
  select subject_name, u.email as created_by_email
  from courses c join users u on u.id = c.created_by
  where c.subject_name ilike '%คณิต%';" < /dev/null

cat <<'EOF'

─────────────────────────────────────────────────────────────
verify 1 ต้องไม่มีแถว +admin เหลือ, บัญชีหลักชื่อ "ทดสอบ ทุกสิทธิ์"
verify 2 ต้องมีครบ 6 role
verify 3 ต้องขึ้น created_by_email = www.pakasit14@gmail.com
ถ้าข้อไหนไม่ตรง อย่าลบสคริปต์นี้ทิ้ง — เอาผลลัพธ์มาคุยกันก่อน
─────────────────────────────────────────────────────────────
EOF
