# บันทึกความคืบหน้า — AIoT Safe & Green School Lab

## ข้อมูลโปรเจกต์

- **ชื่อแอป:** AIoT Safe & Green School Lab
- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Realtime DB)
- **ที่เก็บโปรเจกต์:** `C:\Users\user\Desktop\my_first_app`

---

## Phase 1 — Firebase Auth Migration
**วันที่เสร็จ:** 2026-06-28

### สิ่งที่ทำ
- ติดตั้ง Firebase packages ใน `pubspec.yaml`
- สร้าง `lib/firebase_options.dart` (placeholder รอรัน `flutterfire configure`)
- สร้าง `lib/models/user_model.dart` — enum UserRole 7 ระดับ + UserModel
- สร้าง `lib/services/auth_service.dart` — แทนที่ SharedPreferences ด้วย Firebase Auth + Firestore
- แก้ไข `lib/main.dart` — ใช้ StreamBuilder บน authStateChanges
- แก้ไข `lib/pages/login_page.dart` — ใช้ AuthService.signIn()
- แก้ไข `lib/pages/register_page.dart` — ใช้ AuthService.register()
- แก้ไข `lib/pages/forgot_password_page.dart` — ใช้ AuthService.resetPassword()
- แก้ไข `lib/pages/profile_page.dart` — ใช้ AuthService.updateProfile()
- แก้ไข `lib/pages/user_list_page.dart` — โหลด users จาก Firestore

### Packages ที่เพิ่ม
```yaml
firebase_core: ^3.13.1
firebase_auth: ^5.5.2
cloud_firestore: ^5.6.6
firebase_database: ^11.3.5
firebase_messaging: ^15.2.5
```

### UserRole ทั้ง 7 ระดับ
| Role | ภาษาไทย |
|------|---------|
| student | นักเรียน |
| teacher | ครูประจำห้อง |
| buildingAdmin | ผู้ดูแลอาคาร |
| schoolAdmin | แอดมินโรงเรียน |
| executive | ผู้บริหาร |
| developer | ผู้พัฒนาระบบ |
| parent | ผู้ปกครอง |

### หมายเหตุ
- ต้องรัน `flutterfire configure` เพื่อสร้าง `firebase_options.dart` จริงก่อนใช้งาน
- `lib/data/user_data.dart` ยังคงอยู่แต่ไม่ได้ใช้แล้ว (ลบได้)

---

## Phase 2 — Multi-Role Navigation
**วันที่เสร็จ:** 2026-06-28

### สิ่งที่ทำ
- สร้าง `lib/pages/role_router.dart` — อ่าน role แล้วส่งไปหน้าที่ถูกต้องอัตโนมัติ
- สร้าง `lib/widgets/app_drawer.dart` — Drawer เมนูที่ใช้ร่วมกันทุก role พร้อม logout confirm
- สร้าง `lib/widgets/info_card.dart` — InfoCard + ComingSoonCard widget
- สร้าง Dashboard 7 หน้าแยกตาม role:

| ไฟล์ | Role | สี |
|------|------|----|
| `student_dashboard.dart` | นักเรียน | เขียว |
| `teacher_dashboard.dart` | ครู | น้ำเงิน |
| `building_admin_dashboard.dart` | ผู้ดูแลอาคาร | ส้ม |
| `school_admin_dashboard.dart` | แอดมินโรงเรียน | ม่วง |
| `executive_dashboard.dart` | ผู้บริหาร | กรมท่า |
| `developer_dashboard.dart` | ผู้พัฒนา | เทา |
| `parent_dashboard.dart` | ผู้ปกครอง | เขียวน้ำทะเล |

- แก้ไข `lib/main.dart` — ใช้ RoleRouter แทน HomePage

### โครงสร้าง RoleRouter
```
Login → Firebase Auth → โหลด UserModel → RoleRouter → Dashboard ตาม Role
```

---

## Phase 3 — IoT Real-time Dashboard
**วันที่เสร็จ:** 2026-06-29

### สิ่งที่ทำ
- สร้าง `lib/models/sensor_model.dart` — โมเดลเซ็นเซอร์ 6 ตัวพร้อมระดับความเสี่ยง
- สร้าง `lib/services/realtime_service.dart` — stream จาก Firebase Realtime DB
- สร้าง `lib/widgets/sensor_card.dart` — widgets แสดงข้อมูลเซ็นเซอร์
- อัปเดต `student_dashboard.dart` — แสดงเซ็นเซอร์ห้องตัวเองแบบ real-time
- อัปเดต `teacher_dashboard.dart` — แสดงเซ็นเซอร์ห้องที่รับผิดชอบ
- อัปเดต `building_admin_dashboard.dart` — แสดงสถานะทุกห้องในอาคาร
- แก้ไข `lib/main.dart` — เปิด offline persistence

### เซ็นเซอร์ที่รองรับ

| เซ็นเซอร์ | หน่วย | ดี | ปานกลาง | อันตราย |
|----------|-------|-----|---------|---------|
| PM2.5 | µg/m³ | < 12 | 12–35 | > 35 |
| CO₂ | ppm | < 800 | 800–1500 | > 1500 |
| TVOC | mg/m³ | < 0.3 | 0.3–0.5 | > 0.5 |
| อุณหภูมิ | °C | 20–28 | 28–32 | > 32 |
| ความชื้น | % | 40–70 | 70–80 | > 80 |
| แสงสว่าง | lux | ≥ 300 | 150–300 | < 150 |

### โครงสร้าง Firebase Realtime DB
```
schools/
  {school_id}/
    facilities/
      {building}/
        {floor}/
          {room}/
            sensors/
              pm25: 8.5
              co2: 620
              tvoc: 0.15
              temperature: 26.5
              humidity: 62
              lux: 380
            switches/
              light: true
              water: false
```

### Offline Support
- Firestore: `persistenceEnabled: true`
- Realtime DB: `setPersistenceEnabled(true)` + cache 10MB

---

## สิ่งที่ต้องทำก่อนทดสอบ

- [ ] รัน `flutter pub get`
- [ ] รัน `dart pub global activate flutterfire_cli`
- [ ] รัน `flutterfire configure` เพื่อสร้าง `firebase_options.dart` จริง
- [ ] สร้างข้อมูลทดสอบใน Firebase Realtime Database ตามโครงสร้างด้านบน

---

## Phases ที่เหลือ

| Phase | หัวข้อ | สถานะ |
|-------|--------|-------|
| Phase 4 | Device Control Panel (เปิด/ปิดไฟ-น้ำ) | รอดำเนินการ |
| Phase 5 | Emergency Alerts & FCM Push Notifications | รอดำเนินการ |
| Phase 6 | ESG Reports & Green Score (fl_chart) | รอดำเนินการ |
| Phase 7 | LMS (file_picker, firebase_storage) | รอดำเนินการ |
| Phase 8 | Parent Features & PDPA | รอดำเนินการ |
