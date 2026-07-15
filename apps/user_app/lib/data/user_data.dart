import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ไฟล์นี้ใช้เก็บข้อมูลผู้ใช้แบบจำลอง
// ตอนนี้ใช้ shared_preferences ช่วยบันทึกข้อมูลลงเครื่อง

// รายชื่อผู้ใช้ทั้งหมด
List<Map<String, String>> users = [
  {
    'name': 'Admin',
    'email': 'admin@gmail.com',
    'password': '123456',
    'role': 'admin',
  },
];

// เก็บข้อมูลผู้ใช้ที่ Login อยู่ตอนนี้
Map<String, String>? currentUser;

// โหลดรายชื่อผู้ใช้จากเครื่อง
Future<void> loadUsers() async {
  final prefs = await SharedPreferences.getInstance();

  // ดึงข้อมูล users ที่เคยบันทึกไว้
  final String? usersJson = prefs.getString('users');

  // ถ้ายังไม่มีข้อมูล ให้บันทึก Admin เริ่มต้นลงไป
  if (usersJson == null) {
    await saveUsers();
    return;
  }

  // แปลง String กลับมาเป็น List
  final List<dynamic> decodedUsers = jsonDecode(usersJson);

  users = decodedUsers.map<Map<String, String>>((item) {
    final user = Map<String, String>.from(item);

    // ถ้าข้อมูลเก่ายังไม่มี role ให้เติมให้อัตโนมัติ
    user['role'] ??= user['email'] == 'admin@gmail.com' ? 'admin' : 'user';

    return user;
  }).toList();
}

// บันทึกรายชื่อผู้ใช้ลงเครื่อง
Future<void> saveUsers() async {
  final prefs = await SharedPreferences.getInstance();

  // แปลง List เป็น String ก่อนบันทึก
  final String usersJson = jsonEncode(users);

  await prefs.setString('users', usersJson);
}

// ฟังก์ชันเช็กว่า Email นี้มีในระบบแล้วหรือยัง
bool emailExists(String email) {
  return users.any((user) => user['email'] == email);
}

// ฟังก์ชันเพิ่มผู้ใช้ใหม่
Future<void> addUser({
  required String name,
  required String email,
  required String password,
}) async {
  users.add({
    'name': name,
    'email': email,
    'password': password,
    'role': 'user',
  });

  // หลังเพิ่มผู้ใช้แล้ว ให้บันทึกลงเครื่องทันที
  await saveUsers();
}

// ฟังก์ชันค้นหาผู้ใช้จาก Email และ Password
Map<String, String>? findUserByEmailAndPassword({
  required String email,
  required String password,
}) {
  for (final user in users) {
    if (user['email'] == email && user['password'] == password) {
      return user;
    }
  }

  return null;
}

// ฟังก์ชันแสดงรายชื่อผู้ใช้ทั้งหมดใน Terminal
void printAllUsers() {
  print('===== รายชื่อผู้ใช้ทั้งหมด =====');

  for (final user in users) {
    print('ชื่อ: ${user['name']}');
    print('Email: ${user['email']}');
    print('Password: ${user['password']}');
    print('-----------------------------');
  }
}

// ฟังก์ชันลบผู้ใช้จาก Email
Future<void> deleteUserByEmail(String email) async {
  users.removeWhere((user) => user['email'] == email);

  // หลังลบแล้ว บันทึกข้อมูลใหม่ลงเครื่อง
  await saveUsers();
}

// ฟังก์ชันแก้ไขข้อมูลผู้ใช้จาก Email
Future<void> updateUserByEmail({
  required String email,
  required String newName,
  required String newPassword,
}) async {
  final index = users.indexWhere((user) => user['email'] == email);

  if (index != -1) {
    users[index]['name'] = newName;
    users[index]['password'] = newPassword;

    // หลังแก้ไขแล้ว บันทึกข้อมูลใหม่ลงเครื่อง
    await saveUsers();
  }
}

// บันทึก Email ของผู้ใช้ที่ Login อยู่
Future<void> saveCurrentUser(Map<String, String> user) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('current_user_email', user['email'] ?? '');
}

// โหลดผู้ใช้ที่เคย Login ค้างไว้
Future<void> loadCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();

  final email = prefs.getString('current_user_email');

  if (email == null || email.isEmpty) {
    currentUser = null;
    return;
  }

  // หา user จาก email ที่เคยบันทึกไว้
  final index = users.indexWhere((user) => user['email'] == email);

  if (index != -1) {
    currentUser = users[index];
  } else {
    currentUser = null;
  }
}

// ล้างข้อมูลผู้ใช้ที่ Login ค้างไว้
Future<void> logoutUser() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('current_user_email');

  currentUser = null;
}

// ฟังก์ชันเปลี่ยนสิทธิ์ผู้ใช้ admin <-> user
Future<void> toggleUserRoleByEmail(String email) async {
  // ไม่ให้เปลี่ยนสิทธิ์ของตัวเอง
  if (currentUser?['email'] == email) {
    return;
  }

  final index = users.indexWhere((user) => user['email'] == email);

  if (index != -1) {
    final currentRole = users[index]['role'] ?? 'user';

    if (currentRole == 'admin') {
      users[index]['role'] = 'user';
    } else {
      users[index]['role'] = 'admin';
    }

    // บันทึกข้อมูลใหม่ลงเครื่อง
    await saveUsers();
  }
}

// ฟังก์ชันแก้ไขโปรไฟล์ของผู้ใช้ที่ Login อยู่
Future<void> updateCurrentUserProfile({
  required String newName,
  required String newPassword,
}) async {
  final email = currentUser?['email'];

  if (email == null || email.isEmpty) {
    return;
  }

  // แก้ไขข้อมูลใน users
  await updateUserByEmail(
    email: email,
    newName: newName,
    newPassword: newPassword,
  );

  // โหลดข้อมูลล่าสุดกลับมาใส่ currentUser
  final index = users.indexWhere((user) => user['email'] == email);

  if (index != -1) {
    currentUser = users[index];

    // บันทึกสถานะ Login ค้างไว้เหมือนเดิม
    await saveCurrentUser(currentUser!);
  }
}
