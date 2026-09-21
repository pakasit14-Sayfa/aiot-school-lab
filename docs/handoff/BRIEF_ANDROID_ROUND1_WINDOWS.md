# ใบสั่งงาน — Android รอบแรก บน Windows (ทำคู่ขนานกับ iOS บน Mac)

> เขียน 2026-09-21 · ผู้ทำ: เซสชัน Claude/agy บนเครื่อง **Windows** ของเจ้าของ · ผู้ตรวจ: เซสชันบน Mac
> เป้าหมายของรอบนี้: **แอปรันบน Android จำลองต่อ prod ได้ + ไล่ดูทุกหน้าหลักของ 3 บทบาท (นักเรียน/ครู/แอดมิน)
> แล้วรายงานสิ่งที่พัง** — ยังไม่ต้องขึ้น Play Store
>
> ข้อจำกัด: **Mac รัน iOS อย่างเดียว** (เจ้าของกำหนด 2026-09-17) · Windows รัน Android อย่างเดียว ·
> ทั้งสองฝั่งแชร์ repo เดียวกันบน GitLab/GitHub — **ห้ามแตะไฟล์ iOS จาก Windows** (`apps/user_app/ios/**`)
> และห้ามแก้ `pubspec.yaml`/เวอร์ชันแพ็กเกจโดยไม่บอกฝั่ง Mac (mobile_scanner 7.4.2 + Flutter 3.47.4 ถูกล็อกไว้เพราะ iOS)

## 0. อ่านก่อนเริ่ม

- `CLAUDE.md` (กฎ 6 ข้อ โดยเฉพาะ: ไม่ใช่ Supabase Auth · RLS deny-all · ห้าม `supabase` global)
- `AGENTS.md` (branch/push · เกณฑ์ "เสร็จ")
- `docs/handoff/DESIGN_SYSTEM.md` §4 กติกามือถือ (safe area · 16pt ขอบ · breakpoints <430 / 430–899 / ≥900)
- `docs/handoff/HANDOFF.md` หัวข้อ mobile build (สิ่งที่ฝั่ง iOS เจอ: Flutter ต้อง 3.47.4, mobile_scanner 7)
- **ห้ามเขียน production** ทุกกรณี — ถ้าต้องแก้ DB ให้เขียน migration + สคริปต์ `scripts/prod_apply_<date>.sh` ให้เจ้าของรัน

## 1. ติดตั้งบน Windows (ครั้งเดียว)

| ต้องมี | เวอร์ชัน | หมายเหตุ |
|---|---|---|
| Flutter | **3.47.4** (Dart 3.13.x) — ตรงกับ Mac | `flutter --version` ต้องตรง ไม่งั้น `pubspec.lock` จะเพี้ยนและชนกับฝั่ง Mac · ติดตั้งผ่าน zip จาก flutter.dev แล้ว `flutter config --no-enable-swift-package-manager` ไม่จำเป็นบน Windows |
| Android Studio | ล่าสุด (Ladybug+) | ลง Android SDK Platform 35, Build-Tools, **NDK ตาม `flutter.ndkVersion`**, Emulator, Command-line tools |
| JDK | **17** | Android Gradle Plugin 9.0.1 + Kotlin 2.3.20 (ดู `android/settings.gradle.kts`) ต้องการ JDK 17 · ตั้ง `JAVA_HOME` |
| Git | ล่าสุด | `git config core.autocrlf false` **สำคัญ** — ไม่งั้นทุกไฟล์จะ diff ทั้งไฟล์ (CRLF) |
| Node | 20+ | สำหรับ `npx supabase` (ใช้แค่ local dev / pgTAP ถ้าจำเป็น) |
| Docker Desktop | ตามต้องการ | เฉพาะถ้าจะรัน `npx supabase start` local — รอบนี้ **ไม่จำเป็น** เพราะทดสอบต่อ prod |

ตรวจ: `flutter doctor -v` ต้องเขียว Android toolchain + Android Studio (iOS/Xcode แดงได้ ไม่เกี่ยว)

## 2. เอาโค้ดมา + ตั้งค่า

```bash
git clone git@gitlab.com:diliondev/aiot-school-lab.git my_first_app
cd my_first_app
git remote add origin git@github.com:pakasit14-Sayfa/aiot-school-lab.git   # remote ที่ 2 (push ทั้งคู่)
git config core.autocrlf false
```

- `env.prod.json` **ไม่อยู่ใน git** — เจ้าของคัดลอกจาก Mac (`/Users/sayfa/my_first_app/env.prod.json`) มาวางที่ root ของ repo บน Windows
  (มี `SUPABASE_URL`, `SUPABASE_ANON_KEY` ของ prod เท่านั้น ไม่มี secret key)
- `cd apps/user_app && flutter pub get` (melos ไม่จำเป็น — `flutter pub get` ใน user_app พอสำหรับรัน)
- **ห้าม commit** `pubspec.lock` ถ้ามันเปลี่ยนจากการ pub get บน Windows (ถ้าเปลี่ยน แปลว่าเวอร์ชัน Flutter ไม่ตรง — แก้ที่ Flutter ไม่ใช่ที่ lock)

## 3. สร้างจำลอง Android ให้ครอบขนาดจอเดียวกับที่ iOS ทดสอบ

| AVD | ขนาด | เทียบ |
|---|---|---|
| Pixel 4a (API 34) | 1080×2340 · 393×851 dp | iPhone 14–16 (390×844) |
| Pixel 3a / Medium Phone (API 34) | 360×760 dp | จอเล็กสุดที่ layout test ใช้ (360×640) |
| Pixel Tablet (API 34) | 1600×2560 · 800×1280 dp | iPad ≥ 900 desktop layout |

รัน:
```bash
cd apps/user_app
flutter run -d <emulator-id> --dart-define-from-file=../../env.prod.json
```
(`flutter devices` เพื่อดู id · hot reload กด `r` ในเทอร์มินัล, hot restart `R`)

## 4. สิ่งที่ต้องตรวจ (เรียงตามลำดับ) — ทุกข้อ **ถ่ายจอแนบผล**

### 4.1 build + เปิดแอป
- [ ] `flutter build apk --debug` ผ่าน (ถ้า Gradle ล้ม: ดู §6)
- [ ] เปิดแอป เห็นหน้าล็อกอิน "EDUSMART / AIoT School Lab"
- [ ] ล็อกอิน `www.pakasit14@gmail.com` (เจ้าของพิมพ์รหัสผ่านเอง · เครื่องใหม่จะต้อง OTP ทาง Gmail ครั้งแรก) → เลือกบทบาท **นักเรียน**
- [ ] ปิดแอป-เปิดใหม่ **ต้องไม่ต้องล็อกอินซ้ำ** (session restore — ฝั่ง iOS เคยพังที่ `main.dart` ข้ามการเรียก `AuthService.initialize()`; แก้แล้ว `b12c631` แต่ Android ใช้ `flutter_secure_storage` คนละ backend ต้องยืนยัน)

### 4.2 นักเรียน (บัญชีเจ้าของ อยู่ห้อง ม.1/1 เห็นวิชาคณิตศาสตร์)
- [ ] หน้าแรก: hero + มาสคอต + แถบความคืบหน้า · การ์ดเซนเซอร์ 4×2 · ไม่มีอะไรล้นขอบ · status bar/notch ไม่ทับเนื้อหา (Android มี navigation bar ล่างด้วย — ดูว่า bottom nav ไม่โดนบัง)
- [ ] รายวิชา → คณิตศาสตร์ · ใบงาน (2 ชิ้น) → เปิดใบงาน "แบบฝึกหัดบทที่ 1" → ชุดข้อมูลเซนเซอร์ → กราฟอุณหภูมิ **ต้องมีเส้นข้อมูล** (21/8–20/9 มีข้อมูล 29/8–2/9)
- [ ] AIoT Dashboard · กราฟของฉัน → สร้างกราฟ → ดูตัวอย่าง (ไม่ต้องบันทึกซ้ำ มี 1 กราฟอยู่แล้ว)
- [ ] ปฏิทิน · โปรไฟล์ · แจ้งเหตุ (เปิดดู **ไม่ต้องกดส่ง**)
- [ ] **ปุ่มย้อนกลับของ Android** (hardware/gesture back) ในทุกหน้า — iOS ไม่มีปุ่มนี้ ฝั่ง Mac ไม่เคยทดสอบ: ต้องกลับทีละหน้า ไม่ปิดแอปทันที ไม่ทำให้ bottom sheet ค้าง
- [ ] แป้นพิมพ์ Android ดันช่องพิมพ์ขึ้นไหม (ช่องส่งงาน, ค้นหา)

### 4.3 ครู (ออกจากระบบ → ล็อกอินใหม่ เลือกครู)
- [ ] หน้าแรก **ไม่จอขาว** (เคยพังบน iOS จาก NaN ในกราฟน้ำ-ไฟ แก้ `22e0dbe`)
- [ ] รายวิชา → คณิตศาสตร์ → แท็บ ใบงาน/นักเรียน — ฝั่ง iOS รู้อยู่แล้วว่า**ล้นขอบขวาหลายจุด** (แถบปุ่มบน, "สร้างกิจกรรม PBL", ป้าย "ผูกเซนเซอร์ AIoT") → **แค่บันทึกว่าบน Android ล้นเหมือนกันไหม ยังไม่ต้องแก้** (ฝั่ง Mac จะแก้ใน S3)
- [ ] ตารางสอน (อ่านอย่างเดียวหลัง D6 — ต้องไม่มีปุ่มเพิ่ม/ลบคาบ)

### 4.4 แอดมินโรงเรียน
- [ ] หน้าหลัก → เลื่อนลง เมนู "จัดตารางเรียน" (รายการที่ 21) → ภาพรวม (มัธยมต้น · ม.1/1) → เปิดห้อง → ปฏิทินสัปดาห์ · **แตะช่องว่างแล้วปิด sheet ด้วยปุ่ม back ของ Android** ต้องไม่พัง
- [ ] ไม่ต้องบันทึกอะไรเพิ่ม (ข้อมูลบน prod เป็นของจริง)

### 4.5 ขนาดจอ
- [ ] ทำ 4.2 บน **Medium Phone 360dp** ซ้ำเฉพาะหน้าแรก + ใบงาน + ตารางเรียน → ถ่ายจอ
- [ ] Pixel Tablet: หน้าแรกนักเรียน + จัดตารางเรียน (≥ 900 จะเข้า desktop layout) → ถ่ายจอ

## 5. สิ่งที่ห้ามทำ

- ห้ามแก้ `apps/user_app/ios/**`, `pubspec.yaml`, `pubspec.lock`, เวอร์ชัน Flutter
- ห้ามรัน `dart format` ทั้งโฟลเดอร์ (format เฉพาะไฟล์ที่แตะ)
- ห้ามแก้ UI แบบ "เพื่อให้ Android ผ่าน" โดยไม่ผ่านเทสต์ `test/iphone_layout_test.dart` (ทั้งสองแพลตฟอร์มใช้โค้ดเดียวกัน — แก้ที่ไหนกระทบทั้งคู่)
- ห้ามสร้าง/ส่งงาน/แจ้งเหตุ/เปลี่ยนตารางบน prod เพิ่ม — ทดสอบแบบ **อ่าน** ยกเว้นที่ระบุ
- ห้ามพิมพ์รหัสผ่านแทนเจ้าของ

## 6. ปัญหาที่คาดว่าจะเจอ (และทางแก้)

| อาการ | สาเหตุ/แก้ |
|---|---|
| Gradle: `Unsupported class file major version` / JDK | ต้อง JDK 17 · ตั้ง `JAVA_HOME` · ใน Android Studio: Settings → Build Tools → Gradle → Gradle JDK = 17 |
| `NDK not found` / เวอร์ชันไม่ตรง | ลง NDK เวอร์ชันที่ `flutter.ndkVersion` บอก (ดูใน error) ผ่าน SDK Manager |
| `mobile_scanner` build ล้ม | ห้ามลดเวอร์ชัน — 7.4.2 เป็นตัวที่ iOS ต้องใช้ · ถ้า Android ต้องการ `minSdk` สูงขึ้น ให้แก้ `minSdk = 21`→ค่าที่ต้องการใน `android/app/build.gradle.kts` **แล้วจดใน WORK_LOG** |
| `flutter_secure_storage` เตือน `encryptedSharedPreferences` | เตือนเฉย ๆ ใช้ได้ · ถ้า session ไม่ restore ให้จดเป็นบั๊ก อย่าเพิ่งแก้ |
| หน้าจอโดน navigation bar ล่างบัง | ใช้ `SafeArea`/`MediaQuery.padding.bottom` — บันทึกจุดที่พัง ยังไม่ต้องแก้ (รวมแก้กับ S3/S4) |
| ล็อกอินไม่ผ่าน "รหัสไม่ถูกต้อง" ทั้งที่ถูก | เช็คว่า `env.prod.json` ชี้ prod (`smqoknnftgjyhrnzugar`) ไม่ใช่ local |
| ภาษาไทยเป็นสี่เหลี่ยม | ฟอนต์ระบบ Android มีไทยอยู่แล้ว ถ้าเป็นสี่เหลี่ยมแปลว่า emulator image ไม่มี Google APIs → ใช้ image "Google Play"/"Google APIs" |

## 7. ส่งมอบ

1. branch `agent/android-round1` — ใส่เฉพาะ: `docs/handoff/ANDROID_ROUND1_REPORT_<date>.md` (ผลตาม §4 ทีละข้อ ✅/❌ + ภาพหน้าจอวางใน `docs/handoff/audit/android/`) และการแก้ที่จำเป็นต่อการ **build** เท่านั้น (เช่น minSdk) — **ไม่แก้ UI ในรอบนี้**
2. WORK_LOG.md เพิ่ม 1 แถว "Android รอบแรก" พร้อมสรุปสั้น
3. push branch ไปทั้ง gitlab + origin · **ไม่ push main** — ฝั่ง Mac จะ review แล้ว merge
4. รายการบั๊กที่พบ เขียนเป็นตารางในรายงาน: หน้า · อาการ · ขนาดจอ · ภาพ · เกิดบน iOS ด้วยไหม (เทียบกับ WORK_LOG 18–21 ก.ย.)

## 8. สิ่งที่ฝั่ง Mac จะทำคู่ขนาน (ไม่ชนกัน)

S1 ชื่อแอป/ไอคอน (แตะ `android/app/src/main/res/**` ด้วย — **ฝั่ง Windows อย่าแตะโฟลเดอร์นี้**) · S2 D7 OTP · S3 UI ครู · S4 UI ผอ./ผู้ปกครอง/super admin
ถ้าฝั่ง Windows เจอสิ่งที่ต้องแก้ใน `lib/**` ให้ **รายงาน** ไม่ต้องแก้เอง จะได้ไม่ชนกับ S3/S4
