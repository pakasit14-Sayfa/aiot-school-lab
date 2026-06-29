// ⚠️ ไฟล์นี้เป็น placeholder — ต้องรัน "flutterfire configure" ก่อนใช้งาน
// รันคำสั่งนี้ใน Terminal:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
// แล้วไฟล์นี้จะถูกสร้างใหม่อัตโนมัติ

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'กรุณารัน "flutterfire configure" ก่อนใช้งาน Firebase\n'
      'คำสั่ง: dart pub global activate flutterfire_cli && flutterfire configure',
    );
  }
}
