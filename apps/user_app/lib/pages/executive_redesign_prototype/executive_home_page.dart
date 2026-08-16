// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// Shell ของฝั่งผู้บริหารสถานศึกษา (ผอ) — สร้างวันนี้ (2026-08-15) หลังมี
// 2 หน้าแล้ว (LA-9 dashboard + ศูนย์แจ้งเตือน) แทนที่การเข้าถึงแบบ URL ตรงๆ/
// Navigator.push เดิม ด้วยแท็บสลับที่ด้านบน (มีแค่ 2 ปลายทาง ยังไม่ต้องมี
// sidebar เต็มรูปแบบแบบฝั่งผู้ดูแลอาคาร) — ถ้ามีหน้าเพิ่มในอนาคตค่อย
// พิจารณาเปลี่ยนเป็น sidebar ทีหลัง
import 'package:flutter/material.dart';
import 'executive_dashboard_page.dart';
import 'executive_escalation_inbox_page.dart';
import 'executive_shared_widgets.dart';

class ExecutiveHomePage extends StatefulWidget {
  const ExecutiveHomePage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ExecutiveHomePage> createState() => _ExecutiveHomePageState();
}

class _ExecutiveHomePageState extends State<ExecutiveHomePage> {
  late int _activeIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecutiveTheme.bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: IndexedStack(
                index: _activeIndex,
                children: [
                  ExecutiveDashboardContent(
                    onOpenInbox: () => setState(() => _activeIndex = 1),
                  ),
                  const ExecutiveEscalationInboxContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ExecutiveTheme.lightIndigoBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 18,
              color: ExecutiveTheme.primaryIndigo,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'EXECUTIVE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: ExecutiveTheme.inkIndigo,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildTabSwitcher(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ExecutiveTheme.bgSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(
            index: 0,
            icon: Icons.dashboard_rounded,
            label: 'ภาพรวม',
          ),
          const SizedBox(width: 4),
          _buildTabButton(
            index: 1,
            icon: Icons.notifications_rounded,
            label: 'ศูนย์แจ้งเตือน',
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeIndex == index;
    return Material(
      color: isSelected ? ExecutiveTheme.primaryIndigo : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() => _activeIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : ExecutiveTheme.softMauve,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : ExecutiveTheme.softMauve,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
