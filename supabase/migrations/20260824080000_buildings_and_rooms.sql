-- Migration: 20260824070000_buildings_and_rooms.sql
-- Description: Creates normalized tables for buildings and rooms with RLS & Multi-tenant isolation

CREATE TABLE IF NOT EXISTS public.buildings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT,
  floors INT DEFAULT 1,
  manager_name TEXT,
  note TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  building_id UUID REFERENCES public.buildings(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  code TEXT,
  floor TEXT,
  room_type TEXT DEFAULT 'classroom',
  capacity INT DEFAULT 30,
  teacher_name TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.buildings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

-- Buildings Policies
DROP POLICY IF EXISTS "school_read_buildings" ON public.buildings;
CREATE POLICY "school_read_buildings" ON public.buildings
  FOR SELECT TO authenticated
  USING (school_id = public.get_auth_school_id() OR public.is_super_admin());

DROP POLICY IF EXISTS "school_admin_write_buildings" ON public.buildings;
CREATE POLICY "school_admin_write_buildings" ON public.buildings
  FOR ALL TO authenticated
  USING (
    public.is_super_admin()
    OR (school_id = public.get_auth_school_id() AND public.has_role('school_admin'))
  )
  WITH CHECK (
    public.is_super_admin()
    OR (school_id = public.get_auth_school_id() AND public.has_role('school_admin'))
  );

-- Rooms Policies
DROP POLICY IF EXISTS "school_read_rooms" ON public.rooms;
CREATE POLICY "school_read_rooms" ON public.rooms
  FOR SELECT TO authenticated
  USING (school_id = public.get_auth_school_id() OR public.is_super_admin());

DROP POLICY IF EXISTS "school_admin_write_rooms" ON public.rooms;
CREATE POLICY "school_admin_write_rooms" ON public.rooms
  FOR ALL TO authenticated
  USING (
    public.is_super_admin()
    OR (school_id = public.get_auth_school_id() AND public.has_role('school_admin'))
  )
  WITH CHECK (
    public.is_super_admin()
    OR (school_id = public.get_auth_school_id() AND public.has_role('school_admin'))
  );

-- Permissions
REVOKE ALL ON TABLE public.buildings FROM PUBLIC, anon;
REVOKE ALL ON TABLE public.rooms FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.buildings TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.rooms TO authenticated, service_role;

-- Seed default buildings & rooms for School A
DO $$
DECLARE
  v_school_id UUID := '9a113f7c-a715-4a8f-a0d3-b1e50cbb3912';
  v_bld_a UUID;
  v_bld_b UUID;
  v_bld_lab UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM public.schools WHERE id = v_school_id)
     AND NOT EXISTS (SELECT 1 FROM public.buildings WHERE school_id = v_school_id) THEN
    INSERT INTO public.buildings (school_id, name, code, floors, manager_name, note)
    VALUES (v_school_id, 'อาคารเรียน A', 'BLD-A', 3, 'นายวิชาญ แก้วคำ', 'อาคารเรียนหลัก')
    RETURNING id INTO v_bld_a;

    INSERT INTO public.buildings (school_id, name, code, floors, manager_name, note)
    VALUES (v_school_id, 'อาคารเรียน B', 'BLD-B', 3, 'นางพิมพ์ใจ ศรีสุข', 'อาคารเรียนทั่วไป')
    RETURNING id INTO v_bld_b;

    INSERT INTO public.buildings (school_id, name, code, floors, manager_name, note)
    VALUES (v_school_id, 'อาคารปฏิบัติการ', 'BLD-LAB', 2, 'นายวิชาญ แก้วคำ', 'ห้องทดลองและชุดฝึก')
    RETURNING id INTO v_bld_lab;

    INSERT INTO public.rooms (school_id, building_id, name, code, floor, room_type, capacity, teacher_name)
    VALUES 
      (v_school_id, v_bld_a, 'ห้องเรียน 101', 'A-101', 'ชั้น 1', 'ห้องเรียน', 40, 'นางสาวอรทัย วัฒนชัย'),
      (v_school_id, v_bld_a, 'ห้องเรียน 102', 'A-102', 'ชั้น 1', 'ห้องเรียน', 40, 'นายสมชาย ใจดี'),
      (v_school_id, v_bld_lab, 'ห้องปฏิบัติการ IoT 1', 'LAB-101', 'ชั้น 1', 'ห้องปฏิบัติการ', 30, 'นายวิชาญ แก้วคำ');
  END IF;
END;
$$;
