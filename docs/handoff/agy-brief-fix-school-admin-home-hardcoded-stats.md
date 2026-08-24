# Brief: Fix Hardcoded Stats in `school_admin_home_page.dart`

> **Target File:** `lib/pages/school_admin/school_admin_home_page.dart`  
> **Component:** `_SummaryGrid`, `_StudentWatchList`, `_TeacherWorkCard`

---

## 1. จุดที่พบการ Hardcode ชัดเจน (Hardcoded Demo Literals)

ในไฟล์ `lib/pages/school_admin/school_admin_home_page.dart` มีการฝังค่าคงที่ (`static const`) เป็นตัวเลขม็อค ซึ่งไม่ตรงกับข้อมูลจริงในฐานข้อมูล PostgreSQL (ที่มี Seed Data: 1 นักเรียน, 1 คุณครู, 11 อุปกรณ์):

### 1.1 `_SummaryGrid` (Lines 107-140)
```dart
static const data = [
  _SummaryData('1,250', 'นักเรียนทั้งหมด', 'มาเรียนวันนี้ 1,184 คน', ...),
  _SummaryData('86', 'ครูและบุคลากร', 'พร้อมปฏิบัติงาน 72 คน', ...),
  _SummaryData('7', 'รายการที่ต้องตรวจสอบ', 'เร่งด่วน 2 รายการ', ...),
  _SummaryData('148', 'อุปกรณ์พร้อมใช้งาน', 'จากทั้งหมด 154 เครื่อง', ...),
];
```

### 1.2 `_StudentWatchList` (Lines 287-312)
```dart
static const students = [
  _StudentData('กัญญาวีร์ มีทรัพย์', 'ม.2/1', 'ขาดเรียน', ...),
  _StudentData('ธนกฤต ศรีสุข', 'ม.1/2', 'ลาป่วย', ...),
  ...
];
```

### 1.3 `_TeacherWorkCard` (Lines 407-412)
```dart
static const teachers = [
  _TeacherData('ครูเจน', 'ครูประจำชั้น', 88, ...),
  _TeacherData('ครูมายด์', 'ครูวิชาการ', 75, ...),
  ...
];
```

---

## 2. Pattern Query ที่มีอยู่แล้ว ให้ Copy ใช้ (Reuse Sibling Query Patterns)

ไม่ต้องคิดวิธี Query หรือโครงสร้างใหม่ ให้ Copy Pattern เดียวกันกับที่หน้าข้างเคียงใช้งานอยู่แล้ว ได้แก่:
* `school_students_page.dart` (Lines 54-67)
* `school_teachers_page.dart` (Lines 54-67)
* `school_devices_page.dart` (Lines 72-85)
* `school_alerts_page.dart`

### โค้ดต้นแบบการดึงข้อมูลตาม Pattern มาตรฐาน:

```dart
final client = Supabase.instance.client;
final user = client.auth.currentUser;
if (user == null) return;

// 1. Resolve Active School ID
final profile = await client
    .from('profiles')
    .select('school_id')
    .eq('id', user.id)
    .maybeSingle();
final String? schoolId = profile?['school_id']?.toString() ?? '9a113f7c-a715-4a8f-a0d3-b1e50cbb3912';

// 2. นักเรียนทั้งหมด (Total Students)
final studentRows = await client
    .from('profiles')
    .select('id, full_name, is_active')
    .eq('school_id', schoolId)
    .eq('role', 'student');
final int totalStudents = studentRows.length;

// 3. ครูและบุคลากร (Total Teachers)
final teacherRows = await client
    .from('profiles')
    .select('id, full_name, is_active')
    .eq('school_id', schoolId)
    .eq('role', 'teacher');
final int totalTeachers = teacherRows.length;

// 4. อุปกรณ์พร้อมใช้งาน / ทั้งหมด (Devices Online vs Total)
final deviceRows = await client
    .from('devices')
    .select('id, status')
    .eq('school_id', schoolId);
final int totalDevices = deviceRows.length;
final int onlineDevices = deviceRows.where((d) => d['status'] == 'online').length;

// 5. รายการที่ต้องตรวจสอบ (Unresolved Alerts)
final alertRows = await client
    .from('sensor_alerts')
    .select('id, severity, is_acknowledged')
    .eq('school_id', schoolId)
    .eq('is_acknowledged', false);
final int pendingAlerts = alertRows.length;
```

---

## 3. วิธีการแก้โครงสร้าง UI Widget

1. เปลี่ยน `SchoolAdminHomePage` ให้เป็น `StatefulWidget` และมีฟังก์ชัน `_loadHomeStats()` เรียกใน `initState()`
2. นำตัวเลขจริงมาสร้าง `_SummaryData` แบบ Dynamic:
   * **นักเรียน:** แสดง `${totalStudents}` คน
   * **คุณครู:** แสดง `${totalTeachers}` คน
   * **อุปกรณ์:** แสดง `${onlineDevices}` เครื่อง (จากทั้งหมด `${totalDevices}` เครื่อง, Progress = `onlineDevices / (totalDevices == 0 ? 1 : totalDevices)`)
   * **แจ้งเตือน:** แสดง `${pendingAlerts}` รายการ

---

## 4. วิธีการ Verify ที่ถูกต้อง (Strict Verification Protocol)

ห้ามสรุปว่าเสร็จเพียงแค่รัน `flutter analyze` ผ่าน เพราะ `static const` ที่คอมไพล์ผ่านก็ตรวจไม่พบข้อผิดพลาดนี้

### ขั้นตอนการทดสอบ Verify จริง:
1. **รันคำสั่งตรวจสอบตัวเลขจริงในฐานข้อมูล PostgreSQL โดยตรง:**
   ```bash
   docker exec -i supabase_db_aiot-school-lab psql -U postgres -d postgres << 'EOF'
   SELECT 
     (SELECT COUNT(*) FROM public.profiles WHERE school_id = '9a113f7c-a715-4a8f-a0d3-b1e50cbb3912' AND role = 'student') as student_count,
     (SELECT COUNT(*) FROM public.profiles WHERE school_id = '9a113f7c-a715-4a8f-a0d3-b1e50cbb3912' AND role = 'teacher') as teacher_count,
     (SELECT COUNT(*) FROM public.devices WHERE school_id = '9a113f7c-a715-4a8f-a0d3-b1e50cbb3912') as total_devices,
     (SELECT COUNT(*) FROM public.devices WHERE school_id = '9a113f7c-a715-4a8f-a0d3-b1e50cbb3912' AND status = 'online') as online_devices;
   EOF
   ```
2. **Login เข้าสู่ระบบแอดมินโรงเรียนจริง:**
   * Email: `schooladmin@aiot-school-lab.local` (หรือ `admin@aiot-school-lab.local`)
   * Password: `Test1234!`
3. **เทียบตัวเลขบนการ์ดในหน้า Home:**
   * ตัวเลขสถิติบนการ์ด 4 ใบต้องตรงกับค่าที่ Query ได้จากฐานข้อมูลจริงทุกประการ (ไม่ใช่ 1,250 / 86 / 148 อีกต่อไป)
