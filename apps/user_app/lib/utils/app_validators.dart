class AppValidators {
  // ตรวจสอบรูปแบบ Email
  static bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  // ตรวจสอบช่องชื่อ
  static String? name(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'กรุณากรอกชื่อ';
    }

    if (name.length < 2) {
      return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
    }

    return null;
  }

  // ตรวจสอบช่อง Email
  static String? email(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'กรุณากรอก Email';
    }

    if (!isValidEmail(email)) {
      return 'รูปแบบ Email ไม่ถูกต้อง';
    }

    return null;
  }

  // ตรวจสอบช่อง Password
  static String? password(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'กรุณากรอก Password';
    }

    if (password.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }

    return null;
  }

  // ตรวจสอบช่องรหัสผ่านใหม่
  static String? newPassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'กรุณากรอกรหัสผ่านใหม่';
    }

    if (password.length < 6) {
      return 'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร';
    }

    return null;
  }

  // ตรวจสอบ Confirm Password
  static String? confirmPassword({
    required String? value,
    required String password,
  }) {
    final confirmPassword = value?.trim() ?? '';

    if (confirmPassword.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }

    if (confirmPassword != password) {
      return 'รหัสผ่านไม่ตรงกัน';
    }

    return null;
  }

  // ตรวจสอบ Confirm New Password
  static String? confirmNewPassword({
    required String? value,
    required String newPassword,
  }) {
    final confirmPassword = value?.trim() ?? '';

    if (confirmPassword.isEmpty) {
      return 'กรุณายืนยันรหัสผ่านใหม่';
    }

    if (confirmPassword != newPassword) {
      return 'รหัสผ่านใหม่ไม่ตรงกัน';
    }

    return null;
  }
}