import 'package:flutter/material.dart';
import '../../models/sensor_model.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_service.dart';
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
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        title: const Text('AIoT Smart School'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'สวัสดี, $name 👋',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              hasLocation
                  ? 'ห้อง $room • อาคาร $building'
                  : 'ยังไม่กำหนดห้องเรียน',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            if (!hasLocation)
              const InfoCard(
                icon: Icons.info_outline,
                title: 'ยังไม่กำหนดห้องเรียน',
                value: 'กรุณาติดต่อครูหรือแอดมิน',
                color: Colors.orange,
                subtitle: 'เพื่อกำหนดห้องเรียนในระบบ',
              )
            else
              StreamBuilder<SensorModel?>(
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
                    children: [
                      OverallAirQualityCard(sensor: sensor),
                      const SizedBox(height: 16),
                      SensorGrid(sensor: sensor),
                    ],
                  );
                },
              ),

            const SizedBox(height: 16),
            const ComingSoonCard(
              icon: Icons.emoji_events,
              title: 'Green Score ห้องเรียน',
              phase: 'Phase 6',
              color: Colors.green,
            ),
            const ComingSoonCard(
              icon: Icons.warning_amber,
              title: 'การแจ้งเตือนฉุกเฉิน',
              phase: 'Phase 5',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
