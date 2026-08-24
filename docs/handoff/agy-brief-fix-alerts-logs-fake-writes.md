# Brief for agy: Fix Fake Local Writes on Alerts & Logs Page (`alerts_logs_page.dart`)

> **Document Purpose:** บันทึกข้อตรวจพบเชิงลึกเกี่ยวกับพฤติกรรม "Fake Writes" (การเขียนหลอกเฉพาะในตัวแปร Local State / Memory) ในหน้าจัดการแจ้งเตือน [`alerts_logs_page.dart`](file:///Users/sayfa/aiot_dev_dashboard/lib/pages/alerts_logs_page.dart) พร้อมโค้ด Migration RPC สำหรับนำไปปรับใช้ และมาตรฐานการ Verify กับฐานข้อมูลจริง

---

## 🔎 1. หลักฐานที่ตรวจพบ (Findings & Technical Evidence)

จากการตรวจสอบโค้ดใน [`lib/pages/alerts_logs_page.dart`](file:///Users/sayfa/aiot_dev_dashboard/lib/pages/alerts_logs_page.dart) (บรรทัดที่ 2622–2675) พบว่า:

1. **การโหลดข้อมูล (Read):** หน้านี้เชื่อมต่อและดึงข้อมูลแจ้งเตือนจาก View `public.alerts` และตาราง `public.devices` มาแสดงผลจริงแล้วในฟังก์ชัน `_loadAlertsFromDatabase()`
2. **การบันทึกการกระทำ (Write):** ปุ่มการทำงานหลักทั้งหมด เช่น **"รับทราบเหตุ" (`_acknowledgeAlert`)**, **"มอบหมายผู้รับผิดชอบ" (`_assignAlert`)**, และ **"ปิดเคส/แก้ไขแล้ว"** เป็น **การแก้ไขเฉพาะตัวแปรในหน่วยความจำ (Local State Mutation)**:
   ```dart
   // โค้ดปัจจุบันใน alerts_logs_page.dart (บรรทัด 2622-2642)
   void _acknowledgeAlert(_AlertItem item) {
     setState(() {
       item.status = _AlertStatus.acknowledged;
       item.acknowledgedBy = 'admin@aiotlab.com';

       _activityLogs.insert(
         0,
         _ActivityLog(
           action: 'รับทราบเหตุแจ้งเตือน',
           actor: 'admin@aiotlab.com',
           detail: '${item.id} • ${item.title}',
           time: TimeOfDay.now().format(context),
           success: true,
         ),
       );
     });
     _message('รับทราบเหตุ ${item.id} แล้ว');
   }
   ```
3. **ผลกระทบทางเทคนิค:**
   * ไม่มีการส่งคำสั่ง HTTP Request, PostgREST Query หรือเรียก RPC ฟังก์ชันใดๆ ไปยัง PostgreSQL เลย
   * เมื่อผู้ใช้ Refresh หน้าจอ หรือออกจากหน้าแล้วเปิดกลับเข้ามาใหม่ ข้อมูลจะย้อนกลับเป็นสถานะเดิม (Unacknowledged) ทันที และประวัติใน Activity Log ก็จะสูญหายทั้งหมด

---

## 🗄️ 2. โค้ด Migration RPC ตัวอย่างสำหรับนำไปใช้ (Ready-to-Use Database RPCs)

สร้างไฟล์ Migration (เช่น `20260824050000_sensor_alert_actions.sql`) โดยใช้ Pattern Security Definer ที่มี Dual-Check ดังนี้:

```sql
-- 1. ฟังก์ชันรับทราบเหตุแจ้งเตือน (Acknowledge Alert)
CREATE OR REPLACE FUNCTION public.acknowledge_sensor_alert(p_alert_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_alert RECORD;
  v_school_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  -- ดึงข้อมูล Alert พร้อมตรวจสอบโรงเรียนเจ้าของอุปกรณ์
  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  -- Dual-Check Rule: เฉพาะ Super Admin หรือ School Admin/Technician ประจำโรงเรียนนั้น
  IF NOT (
    public.is_super_admin()
    OR (
      (public.has_role('school_admin') OR public.has_role('technician'))
      AND v_alert.school_id = public.current_user_school_id()
    )
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- อัปเดตสถานะในตาราง sensor_alerts
  UPDATE public.sensor_alerts
  SET status = 'acknowledged',
      acknowledged_by = auth.uid(),
      acknowledged_at = NOW()
  WHERE id = p_alert_id;

  -- บันทึกลง audit_logs
  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    auth.uid(),
    CASE WHEN public.is_super_admin() THEN 'super_admin'::role_type ELSE 'school_admin'::role_type END,
    'alert.acknowledge',
    'sensor_alerts',
    p_alert_id::text,
    jsonb_build_object('previous_status', v_alert.status, 'new_status', 'acknowledged')
  );

  RETURN jsonb_build_object(
    'success', true,
    'alert_id', p_alert_id,
    'status', 'acknowledged',
    'acknowledged_at', NOW()
  );
END;
$$;

-- 2. ฟังก์ชันแก้ไข/ปิดเหตุแจ้งเตือน (Resolve Alert)
CREATE OR REPLACE FUNCTION public.resolve_sensor_alert(
  p_alert_id UUID,
  p_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_alert RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  IF NOT (
    public.is_super_admin()
    OR (
      (public.has_role('school_admin') OR public.has_role('technician'))
      AND v_alert.school_id = public.current_user_school_id()
    )
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.sensor_alerts
  SET status = 'resolved',
      acknowledged_at = COALESCE(acknowledged_at, NOW()),
      acknowledged_by = COALESCE(acknowledged_by, auth.uid())
  WHERE id = p_alert_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    auth.uid(),
    CASE WHEN public.is_super_admin() THEN 'super_admin'::role_type ELSE 'school_admin'::role_type END,
    'alert.resolve',
    'sensor_alerts',
    p_alert_id::text,
    jsonb_build_object('note', p_note, 'resolved_status', 'resolved')
  );

  RETURN jsonb_build_object(
    'success', true,
    'alert_id', p_alert_id,
    'status', 'resolved'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.acknowledge_sensor_alert(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.resolve_sensor_alert(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.acknowledge_sensor_alert(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.resolve_sensor_alert(UUID, TEXT) TO authenticated, service_role;
```

---

## 💻 3. ตัวอย่างการปรับโค้ดฝั่ง Flutter (`alerts_logs_page.dart`)

ปรับปรุงฟังก์ชัน `_acknowledgeAlert` ให้เรียกใช้ RPC:

```dart
Future<void> _acknowledgeAlert(_AlertItem item) async {
  if (item.dbId == null || item.dbId!.isEmpty) {
    _message('ไม่พบรหัสอ้างอิงของเหตุการณ์ในฐานข้อมูล');
    return;
  }

  try {
    final client = Supabase.instance.client;
    await client.rpc('acknowledge_sensor_alert', params: {
      'p_alert_id': item.dbId,
    });

    setState(() {
      item.status = _AlertStatus.acknowledged;
      item.acknowledgedBy = client.auth.currentUser?.email ?? 'ผู้ดูแลระบบ';
    });

    _message('รับทราบเหตุ ${item.id} ในฐานข้อมูลเรียบร้อยแล้ว');
  } catch (e) {
    debugPrint('Error acknowledging alert in database: $e');
    _message('เกิดข้อผิดพลาดในการบันทึก: $e');
  }
}
```

---

## 🎯 4. วิธีการ Verify ที่ถูกต้องตามมาตรฐาน Ground Truth

> [!CAUTION]
> **ข้อห้าม:** การที่ `flutter analyze` ผ่าน 0 issues หรือ `flutter test` ผ่าน **เป็นเพียงการตรวจสอบความถูกต้องของไวยากรณ์ (Syntax Check) เท่านั้น** ไม่ใช่เครื่องยืนยันว่าข้อมูลถูกเขียนลงฐานข้อมูลจริง

### 📋 ขั้นตอนการ Verify จริง (Mandatory Verification Protocol):
1. **ทำการ Login เข้าสู่ระบบจริง** ด้วยบัญชี Super Admin หรือ School Admin
2. **เปิดหน้าจอ [`AlertsLogsPage`](file:///Users/sayfa/aiot_dev_dashboard/lib/pages/alerts_logs_page.dart)** และเลือกรายการแจ้งเตือน
3. **กดปุ่ม "รับทราบเหตุ" หรือ "ปิดเคส"**
4. **เปิด Terminal แล้วยิง Query ตรวจสอบค่าใน PostgreSQL โดยตรง:**
   ```sql
   SELECT id, metric, value, status, acknowledged_by, acknowledged_at 
   FROM public.sensor_alerts 
   WHERE id = '<db_alert_id>';
   ```
5. **เกณฑ์ผ่าน (Definition of Done):**
   * คอลัมน์ `status` ในตาราง `sensor_alerts` ต้องเปลี่ยนจาก `'new'` เป็น `'acknowledged'` หรือ `'resolved'`
   * คอลัมน์ `acknowledged_by` ต้องเก็บ UUID ของผู้ใช้ที่กดจริง
   * คอลัมน์ `acknowledged_at` ต้องมี Timestamp ที่บันทึกจริง
   * ตาราง `audit_logs` มี Record การกระทำ `'alert.acknowledge'` บันทึกไว้
   * เมื่อกด Refresh หน้าจอ สถานะบน UI ต้องยังคงเป็น `'รับทราบแล้ว'` ไม่ย้อนกลับเป็นค่าเดิม
