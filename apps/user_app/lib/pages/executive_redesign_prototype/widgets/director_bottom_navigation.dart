import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// รายการเมนูสำหรับแถบนำทางด้านล่าง (Bottom Navigation)
class DirectorBottomNavItem {
  final String title;
  final IconData icon;

  /// ค่าตัวเลือก (badge) เช่น จำนวนการแจ้งเตือน; ใส่ null หากไม่ต้องการแสดง
  final int? badge;

  const DirectorBottomNavItem(this.title, this.icon, {this.badge});
}

/// แถบนำทางด้านล่างสำหรับมือถือ สไตล์ปุ่มกลางยกลอย
/// - เมนู 2 อันซ้าย + ปุ่มวงกลมเด่นตรงกลาง + เมนู 2 อันขวา
/// - รายการที่เลือกอยู่จะเป็นสีชมพู ปุ่มกลางเป็นวงกลมไล่สีชมพูลอยขึ้นเหนือแถบ
class DirectorBottomNavigation extends StatelessWidget {
  /// เมนูด้านข้าง 4 อัน (ซ้าย 2 + ขวา 2)
  final List<DirectorBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// ปุ่มกลาง (ยกลอย)
  final DirectorBottomNavItem centerItem;
  final VoidCallback onCenterTap;

  const DirectorBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    required this.centerItem,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = items.take(2).toList();
    final right = items.skip(2).take(2).toList();

    return SizedBox(
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // แถบพื้น
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              decoration: BoxDecoration(
                color: AppPalette.sidebarSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPalette.border),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.tint(Colors.black, 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (int i = 0; i < left.length; i++)
                    Expanded(child: _sideItem(left[i], i)),
                  const SizedBox(width: 66),
                  for (int i = 0; i < right.length; i++)
                    Expanded(child: _sideItem(right[i], i + 2)),
                ],
              ),
            ),
          ),
          // ปุ่มกลางยกลอย
          Align(
            alignment: Alignment.topCenter,
            child: _centerButton(),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(DirectorBottomNavItem item, int index) {
    final selected = selectedIndex == index;
    final iconColor =
        selected ? AppPalette.primaryPink : AppPalette.sidebarIcon;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _iconWithBadge(item, iconColor),
            const SizedBox(height: 3),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? AppPalette.primaryPinkDark
                    : AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconWithBadge(DirectorBottomNavItem item, Color color) {
    final icon = Icon(item.icon, size: 21, color: color);

    if (item.badge == null || item.badge == 0) {
      return icon;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.danger,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.sidebarSurface, width: 1.5),
            ),
            child: Text(
              item.badge! > 9 ? '9+' : '${item.badge}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _centerButton() {
    return InkWell(
      onTap: onCenterTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppPalette.heroPink, AppPalette.primaryPinkDark],
              ),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.tint(AppPalette.primaryPink, 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(centerItem.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 3),
          Text(
            centerItem.title,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: AppPalette.primaryPinkDark,
            ),
          ),
        ],
      ),
    );
  }
}
