import 'package:flutter/material.dart';
import 'package:shared_core/models/login_otp_challenge.dart';
import 'package:shared_core/models/role_selection_challenge.dart';
import 'package:shared_core/models/user_model.dart';
import 'package:shared_core/services/auth_service.dart';
import 'login_otp_page.dart';

typedef RoleSelector =
    Future<AuthSignInResult> Function({
      required String roleSelectionToken,
      required UserRole role,
      String? schoolId,
    });

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({
    super.key,
    required this.challenge,
    required this.onSelected,
    this.selectRole,
  });

  final RoleSelectionChallenge challenge;
  final ValueChanged<UserModel> onSelected;
  final RoleSelector? selectRole;

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false;
  UserRole? _selectedRole;
  String? _errorText;

  IconData _iconForRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.schoolAdmin:
        return Icons.manage_accounts_rounded;
      case UserRole.teacher:
        return Icons.school_rounded;
      case UserRole.executive:
        return Icons.insights_rounded;
      case UserRole.student:
        return Icons.person_rounded;
      case UserRole.parent:
        return Icons.family_restroom_rounded;
    }
  }

  Color _colorForRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const Color(0xFFDC2626);
      case UserRole.schoolAdmin:
        return const Color(0xFFA45C23);
      case UserRole.teacher:
        return const Color(0xFF059669);
      case UserRole.executive:
        return const Color(0xFF7C3AED);
      case UserRole.student:
        return const Color(0xFF0284C7);
      case UserRole.parent:
        return const Color(0xFFEA580C);
    }
  }

  Future<void> _handleSelectRole(AvailableRoleOption option) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedRole = option.role;
      _errorText = null;
    });

    try {
      final selector = widget.selectRole ?? AuthService.selectRole;
      final result = await selector(
        roleSelectionToken: widget.challenge.roleSelectionToken,
        role: option.role,
        schoolId: option.schoolId,
      );

      if (!mounted) return;

      if (result.requiresOtp && result.challenge != null) {
        // Proceed to existing OTP verification screen
        final user = await Navigator.of(context).push<UserModel>(
          MaterialPageRoute(
            builder: (otpContext) => LoginOtpPage(
              challenge: result.challenge!,
              onVerified: (verifiedUser) {
                Navigator.of(otpContext).pop(verifiedUser);
              },
            ),
          ),
        );

        if (!mounted) return;
        if (user != null) {
          widget.onSelected(user);
        }
      } else if (result.isAuthenticated && result.user != null) {
        widget.onSelected(result.user!);
      } else {
        setState(() {
          _errorText = 'เกิดข้อผิดพลาดในการเลือกบทบาท กรุณาลองใหม่อีกครั้ง';
        });
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      setState(() {
        if (msg.contains('rate_limited')) {
          _errorText = 'ส่งรหัสยืนยันถี่เกินไป กรุณารอสักครู่แล้วลองใหม่';
        } else if (msg.contains('invalid') || msg.contains('expired')) {
          _errorText = 'คำขอเลือกบทบาทหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        } else {
          _errorText = 'ไม่สามารถเข้าสู่ระบบในบทบาทนี้ได้ กรุณาลองใหม่อีกครั้ง';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = widget.challenge.availableRoles;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'เลือกบทบาทการใช้งาน',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Color(0x0E0F172A),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Squircle Hub Icon
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x334F46E5),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title & Subtitle
                    const Text(
                      'พบบัญชีของคุณมีหลายบทบาท',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'กรุณาเลือกบทบาทที่คุณต้องการเข้าใช้งานในครั้งนี้',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Box
                    if (_errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Role List Items
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: roles.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final option = roles[index];
                        final roleColor = _colorForRole(option.role);
                        final isThisLoading =
                            _isLoading && _selectedRole == option.role;

                        return Material(
                          color: isThisLoading
                              ? roleColor.withAlpha(12)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _isLoading
                                ? null
                                : () => _handleSelectRole(option),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isThisLoading
                                      ? roleColor
                                      : const Color(0xFFE2E8F0),
                                  width: isThisLoading ? 1.8 : 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Squircle Avatar Icon Box
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: roleColor.withAlpha(22),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: roleColor.withAlpha(45),
                                        width: 1.1,
                                      ),
                                    ),
                                    child: Center(
                                      child: isThisLoading
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  roleColor,
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              _iconForRole(option.role),
                                              color: roleColor,
                                              size: 25,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Name & Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15.5,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          option.subtitle,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Trailing Arrow Button
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Back to Login
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      label: const Text(
                        'กลับไปยังหน้าเข้าสู่ระบบ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
