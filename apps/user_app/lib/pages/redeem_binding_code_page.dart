import 'package:flutter/material.dart';

import 'package:shared_core/shared_core.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_card.dart';
import '../utils/app_validators.dart';

class RedeemBindingCodePage extends StatefulWidget {
  const RedeemBindingCodePage({super.key});

  @override
  State<RedeemBindingCodePage> createState() => _RedeemBindingCodePageState();
}

class _RedeemBindingCodePageState extends State<RedeemBindingCodePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isLoading = false;
  String? verificationToken;

  void submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (verificationToken == null) {
        final token = await ParentBindingService.requestParentBindingOtp(
          code: codeController.text.trim(),
          email: emailController.text.trim(),
        );

        if (!mounted) return;
        setState(() => verificationToken = token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('หากข้อมูลถูกต้อง ระบบได้ส่ง OTP ไปยังอีเมลแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      await ParentBindingService.confirmParentBinding(
        verificationToken: verificationToken!,
        otpCode: otpController.text.trim(),
        relationship: relationshipController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งคำขอผูกบัญชีแล้ว รอโรงเรียนตรวจสอบและอนุมัติ'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verificationToken == null
                ? 'ไม่สามารถส่งรหัสยืนยันได้ กรุณาลองใหม่ภายหลัง'
                : 'OTP ไม่ถูกต้อง หมดอายุ หรือข้อมูลบัญชีไม่ตรงกัน',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    relationshipController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ผูกบัญชีผู้ปกครอง')),
      body: AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthHeader(
                icon: Icons.family_restroom,
                title: 'มีรหัสผูกบัญชีจากโรงเรียน?',
                subtitle:
                    'กรอกรหัสที่ได้รับจากโรงเรียน พร้อมข้อมูลของคุณ '
                    'เพื่อผูกบัญชีกับบุตรหลาน (ต้องรอโรงเรียนอนุมัติก่อนใช้งานได้เต็มรูปแบบ)',
              ),

              const SizedBox(height: 28),

              CustomTextField(
                controller: codeController,
                labelText: 'รหัสผูกบัญชี',
                hintText: 'กรอกรหัสที่ได้รับจากโรงเรียน',
                prefixIcon: Icons.vpn_key,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกรหัส'
                    : null,
              ),

              const SizedBox(height: 16),

              if (verificationToken != null) ...[
                CustomTextField(
                  controller: otpController,
                  labelText: 'รหัส OTP ทางอีเมล',
                  hintText: 'กรอกรหัสตัวเลข 6 หลัก',
                  prefixIcon: Icons.mark_email_read_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (verificationToken == null) return null;
                    return RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                        ? null
                        : 'กรุณากรอก OTP 6 หลัก';
                  },
                ),
                const SizedBox(height: 16),
              ],

              CustomTextField(
                controller: relationshipController,
                labelText: 'ความสัมพันธ์กับนักเรียน',
                hintText: 'เช่น พ่อ, แม่, ผู้ปกครอง',
                prefixIcon: Icons.diversity_1,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'กรุณากรอกความสัมพันธ์'
                    : null,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                hintText: 'กรอกอีเมลของคุณ',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: firstNameController,
                labelText: 'ชื่อ',
                hintText: 'กรอกชื่อของคุณ',
                prefixIcon: Icons.person,
                validator: AppValidators.name,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: lastNameController,
                labelText: 'นามสกุล',
                hintText: 'กรอกนามสกุลของคุณ',
                prefixIcon: Icons.person_outline,
                validator: AppValidators.name,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: passwordController,
                labelText: 'รหัสผ่าน',
                hintText:
                    'ตั้งรหัสผ่าน (หรือกรอกรหัสผ่านเดิมถ้ามีบัญชีอยู่แล้ว)',
                prefixIcon: Icons.lock,
                obscureText: isPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => isPasswordHidden = !isPasswordHidden);
                  },
                ),
                validator: AppValidators.password,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: confirmPasswordController,
                labelText: 'ยืนยันรหัสผ่าน',
                hintText: 'กรอกรหัสผ่านอีกครั้ง',
                prefixIcon: Icons.lock_outline,
                obscureText: isConfirmPasswordHidden,
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                      () => isConfirmPasswordHidden = !isConfirmPasswordHidden,
                    );
                  },
                ),
                validator: (value) => AppValidators.confirmPassword(
                  value: value,
                  password: passwordController.text.trim(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isLoading
                        ? 'กำลังดำเนินการ...'
                        : verificationToken == null
                        ? 'ส่ง OTP ทางอีเมล'
                        : 'ยืนยัน OTP และส่งคำขอ',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
