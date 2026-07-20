-- =====================================================================
-- Dev/test seed data — one test school + one account per role, so each
-- role's dashboard/permissions can be checked manually in the UI without
-- going through the full invite/binding flows first.
--
-- NOT for production. All seeded accounts share the password 'Test1234!'
-- (same hashing as the bootstrap super_admin in
-- 20260715010000_auth_rpc.sql). Delete or change these before go-live.
--
-- This does NOT run automatically against a remote/hosted Supabase
-- project — `supabase db reset` only auto-applies seed.sql for local
-- dev. For the real project, paste this file into the Supabase Dashboard
-- SQL Editor and run it once, or `psql "$DATABASE_URL" -f supabase/seed.sql`.
-- Safe to re-run: every insert is guarded, so running it twice is a no-op.
-- =====================================================================

do $$
declare
  v_super_admin_id uuid;
  v_package_id uuid;
  v_school_id uuid;
  v_password_hash varchar;
  v_user_id uuid;
  v_role record;
begin
  select id into v_super_admin_id from users where email = 'admin@aiot-school-lab.local';
  if v_super_admin_id is null then
    raise exception 'bootstrap super_admin not found — run migrations first (20260715010000_auth_rpc.sql)';
  end if;

  v_password_hash := crypt('Test1234!', gen_salt('bf'));

  -- 20260720000000_rotate_default_credentials.sql rotates the bootstrap
  -- admin's default password away; restore the known dev password here so
  -- local `supabase db reset` still leaves a usable super_admin login.
  update users set password_hash = v_password_hash where id = v_super_admin_id;

  select id into v_package_id from packages where name = 'ทดสอบ Package';
  if v_package_id is null then
    insert into packages (name, license_type, max_users)
    values ('ทดสอบ Package', 'perpetual', 500)
    returning id into v_package_id;
  end if;

  select id into v_school_id from schools where school_code = 'TEST01';
  if v_school_id is null then
    insert into schools (package_id, name, school_code, status)
    values (v_package_id, 'โรงเรียนทดสอบ', 'TEST01', 'active')
    returning id into v_school_id;
  end if;

  for v_role in
    select * from (values
      ('school_admin'::role_type,     'schooladmin@aiot-school-lab.local', 'แอดมิน',    'โรงเรียน', null::varchar),
      ('teacher'::role_type,          'teacher@aiot-school-lab.local',     'ครู',       'ทดสอบ',    null::varchar),
      ('executive'::role_type,        'executive@aiot-school-lab.local',   'ผู้บริหาร',  'ทดสอบ',    null::varchar),
      ('student'::role_type,          'student@aiot-school-lab.local',     'นักเรียน',   'ทดสอบ',    'STU0001'::varchar),
      ('parent'::role_type,           'parent@aiot-school-lab.local',      'ผู้ปกครอง',  'ทดสอบ',    null::varchar),
      ('facility_manager'::role_type, 'facility@aiot-school-lab.local',    'ผู้ดูแล',    'อาคาร',    null::varchar),
      ('technician'::role_type,       'technician@aiot-school-lab.local',  'ช่าง',      'เทคนิค',   null::varchar)
    ) as t(role, email, first_name, last_name, student_code)
  loop
    if not exists (select 1 from users where email = v_role.email) then
      insert into users (school_id, email, password_hash, first_name, last_name, created_by, student_code)
      values (v_school_id, v_role.email, v_password_hash, v_role.first_name, v_role.last_name, v_super_admin_id, v_role.student_code)
      returning id into v_user_id;

      insert into user_roles (user_id, role, school_id, granted_by)
      values (v_user_id, v_role.role, v_school_id, v_super_admin_id);
    end if;
  end loop;
end $$;

-- Quick reference: everything logs in with password Test1234!
-- (except admin@aiot-school-lab.local, which uses ChangeMe123! from the
-- bootstrap migration).
select email, (select role from user_roles ur where ur.user_id = u.id limit 1) as role
from users u
where u.email like '%@aiot-school-lab.local'
order by role;
