import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';
import '../../widgets/sensor_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'นักเรียน';
    final schoolId = user?.schoolId ?? '';
    final building = user?.building ?? '';
    final room = user?.room ?? '';
    final hasLocation =
        schoolId.isNotEmpty && building.isNotEmpty && room.isNotEmpty;

    return Scaffold(
      // ใช้สีพื้นหลังแบบ gradient เพื่อความหรูหรา
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(name),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // แสดงตำแหน่งหรือแจ้งว่าต้องตั้งค่าห้องเรียนก่อน
                  if (!hasLocation)
                    const InfoCard(
                      icon: Icons.info_outline,
                      title: 'ยังไม่กำหนดห้องเรียน',
                      value: 'กรุณาติดต่อครูหรือแอดมิน',
                      color: Colors.orange,
                      subtitle: 'เพื่อกำหนดห้องเรียนในระบบ',
                    )
                  else
                    _buildSensorSection(schoolId, building, room),
                  const SizedBox(height: 24),
                  const ComingSoonCard(
                    icon: Icons.emoji_events,
                    title: 'Green Score ห้องเรียน',
                    phase: 'Phase 6',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  const ComingSoonCard(
                    icon: Icons.warning_amber,
                    title: 'การแจ้งเตือนฉุกเฉิน',
                    phase: 'Phase 5',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Drawer ยังคงไว้เหมือนเดิมเพื่อเข้าถึงเมนูอื่น
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            color: Colors.green,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.eco,
            title: 'Green Score',
            color: Colors.green,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.notifications,
            title: 'การแจ้งเตือน',
            color: Colors.orange,
            onTap: (_) {},
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SliverAppBar – ทำให้ส่วนหัวยืด/หดได้พร้อม gradient และ avatar
  // ---------------------------------------------------------------------
  Widget _buildSliverAppBar(String name) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 240.0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1ABC9C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Icon(Icons.school, size: 44, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'สวัสดี 👋',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: IconButton(
              icon: const Badge(
                label: Text('3'),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Sensor Section – แสดงข้อมูลเซ็นเซอร์ใน Card แบบ glassmorphism
  // ---------------------------------------------------------------------
  Widget _buildSensorSection(String schoolId, String building, String room) {
    return StreamBuilder<SensorModel?>(
      stream: RealtimeService.sensorStream(
        schoolId: schoolId,
        building: building,
        floor: '1',
        room: room,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SensorLoadingCard();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SensorNoDataCard();
        }
        final sensor = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สถานะอากาศ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Glassmorphism Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                // blur effect – emulate glass
                // Note: BackdropFilter needed in real UI, kept simple here
              ),
              child: Column(
                children: [
                  OverallAirQualityCard(sensor: sensor),
                  const SizedBox(height: 16),
                  SensorGrid(sensor: sensor),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
