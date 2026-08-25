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
        return const Color(0xFFD32F2F);
      case UserRole.schoolAdmin:
        return const Color(0xFF1976D2);
      case UserRole.teacher:
        return const Color(0xFF388E3C);
      case UserRole.executive:
        return const Color(0xFF7B1FA2);
      case UserRole.student:
        return const Color(0xFF0097A7);
      case UserRole.parent:
        return const Color(0xFFE65100);
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
    final theme = Theme.of(context);
    final roles = widget.challenge.availableRoles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกบทบาทการใช้งาน'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.switch_account_rounded,
                        size: 56,
                        color: Color(0xFF1976D2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'พบบัญชีของคุณมีหลายบทบาท',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กรุณาเลือกบทบาทที่คุณต้องการเข้าใช้งานในครั้งนี้',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () => _handleSelectRole(option),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: roleColor.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          roleColor.withValues(alpha: 0.12),
                                      child: isThisLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
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
                                              size: 26,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            option.subtitle,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('กลับไปยังหน้าเข้าสู่ระบบ'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
