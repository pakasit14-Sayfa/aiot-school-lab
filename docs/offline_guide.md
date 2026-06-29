# ระบบ Offline — AIoT Smart School

## แนวคิดหลัก

```
มี Internet     → ดึงข้อมูลจาก Server + บันทึกลงเครื่อง
ไม่มี Internet  → ใช้ข้อมูลที่บันทึกไว้ในเครื่อง
กลับมา Online  → sync ข้อมูลที่ค้างไว้ขึ้น Server อัตโนมัติ
```

---

## Firebase Offline Support (มีในตัวอยู่แล้ว)

Firebase รองรับ offline ได้โดยไม่ต้องเขียน logic ซับซ้อน เปิดใช้แค่นี้:

```dart
// ใน main.dart หลัง Firebase.initializeApp()

// Firestore — cache ข้อมูล users, logs
FirebaseFirestore.instance.settings =
    const Settings(persistenceEnabled: true);

// Realtime DB — cache ข้อมูล sensor IoT
FirebaseDatabase.instance.setPersistenceEnabled(true);
FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000); // 10MB
```

### Firebase จัดการให้อัตโนมัติ
- Cache ข้อมูลล่าสุดไว้ในเครื่อง
- สั่ง write ได้แม้ offline → sync อัตโนมัติเมื่อกลับมา online
- ไม่ต้องเขียน sync logic เอง

---

## ตรวจสอบสถานะ Internet

### เพิ่ม Package

```yaml
# pubspec.yaml
dependencies:
  connectivity_plus: ^6.0.0
```

### สร้าง connectivity_service.dart

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Stream<bool> get isOnline =>
      Connectivity().onConnectivityChanged.map(
        (result) => result != ConnectivityResult.none,
      );

  static Future<bool> checkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

### แสดง Banner เมื่อ Offline

```dart
// ใส่ใน scaffold ของทุก dashboard
StreamBuilder<bool>(
  stream: ConnectivityService.isOnline,
  builder: (context, snapshot) {
    final isOnline = snapshot.data ?? true;
    if (isOnline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.orange,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'กำลังทำงานแบบ Offline — ข้อมูลอาจไม่เป็นปัจจุบัน',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  },
)
```

---

## ตัวเลือก Local Storage เพิ่มเติม

| Package | เหมาะกับ | ข้อดี |
|---------|---------|-------|
| **Hive** | cache settings, user profile | เร็วมาก ใช้ง่าย |
| **sqflite / drift** | sensor logs ย้อนหลัง | query SQL ได้ |
| **SharedPreferences** | ค่าง่ายๆ เช่น theme, token | ง่ายที่สุด |

### แนะนำสำหรับโปรเจกต์นี้
- **Firebase persistence** → ข้อมูล IoT และ user (Phase 3)
- **Hive** → เก็บ settings และ profile cache (Phase 3-4)
- **sqflite** → เก็บ sensor logs ย้อนหลัง 30 วัน (Phase 6 ESG Reports)

---

## สรุปฟีเจอร์แต่ละอย่างเมื่อ Offline

| ฟีเจอร์ | ทำได้ Offline? | หมายเหตุ |
|--------|:---:|---------|
| Login ครั้งแรก | ❌ | ต้องมี internet |
| Login ครั้งต่อไป | ✅ | Firebase จำ session |
| ดู Dashboard | ✅ | ใช้ข้อมูล cache ล่าสุด |
| ดูค่า Sensor เก่า | ✅ | Firebase Realtime DB cache |
| ค่า Sensor Real-time | ❌ | ต้องมี internet |
| สั่งเปิด/ปิดไฟ | ⚠️ | บันทึกไว้ sync ตอน online |
| ดู ESG Report | ✅ | ถ้าเคยเปิดแล้ว |
| รับ Push Notification | ❌ | ต้องมี internet |

---

## ลำดับการทำ

| Phase | งาน Offline ที่เพิ่ม |
|-------|-------------------|
| Phase 3 | เปิด `persistenceEnabled` ทั้ง Firestore + Realtime DB |
| Phase 3 | เพิ่ม `connectivity_plus` + Offline Banner |
| Phase 4 | Queue คำสั่ง device เมื่อ offline → sync ตอน online |
| Phase 6 | เก็บ sensor logs ใน sqflite สำหรับ ESG Report ย้อนหลัง |
