-- Migration: 20260824080000_learning_platform_tables.sql
-- Description: Creates learning_items and learning_simulators tables with RLS and per-school publish control

CREATE TABLE IF NOT EXISTS public.learning_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  training_set TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('lesson', 'video', 'activity')),
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT,
  duration_minutes INT,
  points INT DEFAULT 0,
  link TEXT,
  published BOOLEAN NOT NULL DEFAULT false,
  publish_to_all_schools BOOLEAN NOT NULL DEFAULT true,
  published_school_ids UUID[] DEFAULT '{}',
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.learning_simulators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  training_set TEXT NOT NULL,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  description TEXT,
  auto_check BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.learning_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_simulators ENABLE ROW LEVEL SECURITY;

-- Learning Items Policies
DROP POLICY IF EXISTS "read_learning_items" ON public.learning_items;
CREATE POLICY "read_learning_items" ON public.learning_items
  FOR SELECT TO authenticated
  USING (
    public.is_super_admin()
    OR (
      published = true
      AND (
        publish_to_all_schools = true
        OR public.get_auth_school_id() = ANY(published_school_ids)
      )
    )
  );

DROP POLICY IF EXISTS "super_admin_write_learning_items" ON public.learning_items;
CREATE POLICY "super_admin_write_learning_items" ON public.learning_items
  FOR ALL TO authenticated
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

-- Learning Simulators Policies
DROP POLICY IF EXISTS "read_learning_simulators" ON public.learning_simulators;
CREATE POLICY "read_learning_simulators" ON public.learning_simulators
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "super_admin_write_learning_simulators" ON public.learning_simulators;
CREATE POLICY "super_admin_write_learning_simulators" ON public.learning_simulators
  FOR ALL TO authenticated
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

-- Permissions
REVOKE ALL ON TABLE public.learning_items FROM PUBLIC, anon;
REVOKE ALL ON TABLE public.learning_simulators FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.learning_items TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.learning_simulators TO authenticated, service_role;

-- Seed default learning content
DO $$
DECLARE
  v_admin_id UUID;
  v_school_id UUID := '9a113f7c-a715-4a8f-a0d3-b1e50cbb3912';
BEGIN
  IF EXISTS (SELECT 1 FROM public.learning_items) THEN
    RETURN;
  END IF;

  SELECT id INTO v_admin_id FROM public.users WHERE email = 'admin@aiot-school-lab.local' LIMIT 1;
  IF v_admin_id IS NULL THEN
    SELECT id INTO v_admin_id FROM public.users LIMIT 1;
  END IF;

  -- Insert default learning items
  INSERT INTO public.learning_items (
    training_set, type, title, description, difficulty, duration_minutes, points, link, published, publish_to_all_schools, published_school_ids, created_by
  ) VALUES
  (
    'ESP32 Smart Farm Kit', 'lesson', 'บทนำสู่ระบบฟาร์มอัจฉริยะด้วย ESP32',
    'เรียนรู้การอ่านค่าความชื้นในดิน อุณหภูมิ และการสั่งงานปั๊มน้ำอัตโนมัติ',
    'ปานกลาง', 45, 100, 'https://wokwi.com', true, true, '{}', v_admin_id
  ),
  (
    'ESP32 Smart Farm Kit', 'video', 'วิดีโอสาธิตการต่อวงจรเซนเซอร์วัดดิน',
    'ขั้นตอนการเชื่อมต่อ Soil Moisture Sensor เข้ากับบอร์ด ESP32',
    'เบื้องต้น', 20, 50, 'https://youtube.com', true, true, '{}', v_admin_id
  ),
  (
    'IoT Air Quality Kit', 'lesson', 'การวัดและวิเคราะห์ค่าฝุ่น PM2.5 ในโรงเรียน',
    'เรียนรู้การใช้งาน MQ-135 และ Dust Sensor พร้อมการคำนวณดัชนีคุณภาพอากาศ AQI',
    'ขั้นสูง', 60, 150, 'https://wokwi.com', true, false, ARRAY[v_school_id], v_admin_id
  );

  -- Insert default simulators
  INSERT INTO public.learning_simulators (
    training_set, name, url, description, auto_check, created_by
  ) VALUES
  (
    'ESP32 Smart Farm Kit', 'Wokwi ESP32 Relay & Sensor Lab',
    'https://wokwi.com/projects/new/esp32', 'ตัวจำลองบอร์ด ESP32 เชื่อมต่อกับ Relay และ DHT22',
    true, v_admin_id
  ),
  (
    'IoT Air Quality Kit', 'Air Quality Monitoring Circuit Lab',
    'https://wokwi.com/projects/new/esp32', 'ตัวจำลองการอ่านค่าเซนเซอร์คุณภาพอากาศผ่าน I2C/Analog',
    true, v_admin_id
  );
END;
$$;
