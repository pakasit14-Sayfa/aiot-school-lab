import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';

/// 🛠️ 6 Required UX States for Facility Manager Redesign Prototype:
/// 1. Loading Skeleton
/// 2. Empty State
/// 3. Error State
/// 4. Offline Sync Pending
/// 5. Permission Denied
/// 6. Success Confirmation Toast/Banner

class FacilityUXStates {
  /// 1. Loading Skeleton Box
  static Widget buildSkeleton({
    double width = double.infinity,
    double height = 120,
    double borderRadius = 16,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Empty State Widget
  static Widget buildEmptyState({
    required String title,
    required String message,
    IconData icon = Icons.inbox_rounded,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: FacilityTheme.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: FacilityTheme.textMuted,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacilityTheme.primaryNavy,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Error State Widget
  static Widget buildErrorState({
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: FacilityTheme.emergencyRed,
          ),
          const SizedBox(height: 10),
          const Text(
            'เกิดข้อผิดพลาดในการโหลดข้อมูล',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.emergencyRed,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: FacilityTheme.textDark),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('ลองใหม่อีกครั้ง'),
            style: OutlinedButton.styleFrom(
              foregroundColor: FacilityTheme.emergencyRed,
              side: const BorderSide(color: FacilityTheme.emergencyRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Offline Sync Pending Widget
  static Widget buildOfflineSyncBanner({
    required int pendingCount,
    required String lastSyncedTime,
    required VoidCallback onSyncNow,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: FacilityTheme.warningOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'โหมดออฟไลน์: บันทึกรอ Sync $pendingCount รายการ',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: FacilityTheme.warningOrange,
                  ),
                ),
                Text(
                  'ซิงค์ล่าสุดเมื่อ: $lastSyncedTime',
                  style: const TextStyle(
                    fontSize: 11,
                    color: FacilityTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onSyncNow,
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Sync เลย'),
            style: TextButton.styleFrom(
              foregroundColor: FacilityTheme.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Permission Denied Widget
  static Widget buildPermissionDenied({
    required String requiredRoleTitle,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            size: 40,
            color: FacilityTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'ต้องใช้สิทธิ์: $requiredRoleTitle',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: FacilityTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: FacilityTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Success Modal Dialog Card Confirmation (ป็อปอัปการ์ดเด้งกลางหน้าจอ)
  static void showSuccessToast(
    BuildContext context,
    String title, {
    String? subtitle,
    Color accentColor = FacilityTheme.safeGreen,
    IconData icon = Icons.check_circle_rounded,
    String buttonText = 'ตกลง',
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x290F172A),
                  blurRadius: 36,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // 1. Icon Badge ทรงกลมส่วนบน
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. หัวข้อหลัก (Title)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // 3. ปุ่มกดสีดำทรง Pill ด้านล่าง (Bottom Pill Action Button)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
