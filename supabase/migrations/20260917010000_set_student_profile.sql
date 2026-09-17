-- set_student_profile — the first writer of student_profiles.
--
-- Found 2026-09-17 while bringing production up: 18 RPCs read
-- student_profiles (homeroom roster, attendance, learning tracks, parent
-- views, executive classroom pages) and NOTHING writes it. Local dev only
-- ever had rows because seed.sql inserts them directly. On production the
-- table was empty and there was no screen that could fill it — so every
-- feature keyed on grade/room was unreachable.
--
-- Upserts the student's row for the school's current academic year.
-- school_admin (own school) and super_admin only. Empty grade AND room
-- removes the row (a student with no class this year).

create or replace function public.set_student_profile(
  p_token text,
  p_student_id uuid,
  p_grade_level text,
  p_room text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_student users%rowtype;
  v_year uuid;
  v_grade text := nullif(trim(coalesce(p_grade_level, '')), '');
  v_room text := nullif(trim(coalesce(p_room, '')), '');
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_student from users where id = p_student_id;
  if not found then raise exception 'student_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_student.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from user_roles ur
    where ur.user_id = p_student_id and ur.role = 'student'
  ) then raise exception 'not_a_student'; end if;

  v_year := _current_academic_year_id(v_student.school_id);
  if v_year is null then raise exception 'no_academic_year'; end if;

  if v_grade is null and v_room is null then
    delete from student_profiles
    where student_id = p_student_id and academic_year_id = v_year;
  else
    if v_grade is null or v_room is null then
      raise exception 'missing_required_field';
    end if;
    insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by)
    values (p_student_id, v_year, v_grade, v_room, v_actor.user_id)
    on conflict (student_id, academic_year_id) do update
      set grade_level = excluded.grade_level, room = excluded.room;
  end if;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_student.school_id, v_actor.user_id, v_actor.role, 'student_profile.set',
          'student_profiles', p_student_id::text,
          jsonb_build_object('grade_level', v_grade, 'room', v_room, 'academic_year_id', v_year));
end;
$$;

grant execute on function public.set_student_profile(text, uuid, text, text) to anon, authenticated, service_role;


-- ---------------------------------------------------------------------------
-- import_school_users_batch_for_school_admin: accept grade_level/room per
-- student row and write student_profiles (same rule as set_student_profile).
-- Body otherwise identical to 20260914020000.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.import_school_users_batch_for_school_admin(p_token text, p_role text, p_users jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_actor record;
  v_item jsonb;
  v_role_type public.role_type;
  v_email text;
  v_first_name text;
  v_last_name text;
  v_student_code text;
  v_building text;
  v_grade text;
  v_room text;
  v_year uuid;
  v_user_id uuid;
  v_temp_password text;
  v_row_index int := 0;
  v_inserted_count int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_credentials jsonb := '[]'::jsonb;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden: school_admin or super_admin role required';
  end if;
  if v_actor.school_id is null then raise exception 'no_active_school'; end if;

  begin
    v_role_type := p_role::public.role_type;
  exception when others then
    raise exception 'invalid_role: %', p_role;
  end;
  if v_role_type = 'super_admin'::role_type and v_actor.role <> 'super_admin' then
    raise exception 'forbidden: cannot import super_admin';
  end if;

  for v_item in select * from jsonb_array_elements(p_users)
  loop
    v_row_index := v_row_index + 1;
    v_email := lower(trim(coalesce(v_item->>'email', '')));
    v_first_name := trim(coalesce(v_item->>'first_name', v_item->>'name', ''));
    v_last_name := trim(coalesce(v_item->>'last_name', ''));
    v_student_code := trim(coalesce(v_item->>'student_code', ''));
    v_building := trim(coalesce(v_item->>'building', ''));
    v_grade := trim(coalesce(v_item->>'grade_level', v_item->>'grade', ''));
    v_room := trim(coalesce(v_item->>'room', ''));

    if v_email = '' then
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'missing_required_field');
      continue;
    end if;
    if v_first_name = '' then
      v_first_name := split_part(v_email, '@', 1);
    end if;
    if v_last_name = '' then
      v_last_name := '-';
    end if;

    select id into v_user_id from users where email = v_email;
    if v_user_id is not null then
      -- เดิมข้ามเงียบ แอดมินไม่รู้ว่าแถวไหนไม่ถูกสร้าง
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'duplicate_email');
      continue;
    end if;

    v_temp_password := _generate_temp_password();

    insert into users (
      school_id, email, first_name, last_name, password_hash, must_change_password,
      student_code, building, status
    ) values (
      v_actor.school_id, v_email, v_first_name, v_last_name,
      crypt(v_temp_password, gen_salt('bf')), true,
      nullif(v_student_code, ''), nullif(v_building, ''), 'active'::user_status
    ) returning id into v_user_id;

    insert into user_roles (user_id, school_id, role, granted_by)
    values (v_user_id, v_actor.school_id, v_role_type, v_actor.user_id)
    on conflict do nothing;

    -- 20260917010000: a student row may carry grade_level/room. Written to
    -- student_profiles for the current academic year, same as
    -- set_student_profile. Ignored (not an error) when only one is given.
    if v_role_type = 'student'::role_type and v_grade <> '' and v_room <> '' then
      v_year := _current_academic_year_id(v_actor.school_id);
      if v_year is not null then
        insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by)
        values (v_user_id, v_year, v_grade, v_room, v_actor.user_id)
        on conflict (student_id, academic_year_id) do update
          set grade_level = excluded.grade_level, room = excluded.room;
      end if;
    end if;

    v_inserted_count := v_inserted_count + 1;
    v_credentials := v_credentials || jsonb_build_object(
      'row', v_row_index, 'email', v_email, 'temp_password', v_temp_password
    );
  end loop;

  -- ไม่บันทึกรหัสชั่วคราวลง log — คืนให้ผู้เรียกครั้งเดียวเท่านั้น
  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role::role_type, 'users.batch_import',
          'users', v_actor.school_id::text,
          jsonb_build_object('role', p_role, 'count', v_inserted_count,
                             'skipped', jsonb_array_length(v_skipped)));

  return jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count,
    'skipped', v_skipped,
    'credentials', v_credentials
  );
end;
$function$

;
