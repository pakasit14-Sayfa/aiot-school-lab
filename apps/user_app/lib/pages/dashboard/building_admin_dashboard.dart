import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/info_card.dart';
import '../../widgets/sensor_card.dart';

class BuildingAdminDashboard extends StatelessWidget {
  const BuildingAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'ผู้ดูแลอาคาร';
    final schoolId = user?.schoolId ?? '';
    final building = user?.building.isNotEmpty == true ? user!.building : 'ยังไม่กำหนดอาคาร';
    final hasLocation = schoolId.isNotEmpty && user?.building.isNotEmpty == true;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('ควบคุมอาคาร'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.business,
            title: 'ภาพรวมอาคาร',
            color: Colors.orange,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.power_settings_new,
            title: 'ควบคุมอุปกรณ์',
            color: Colors.orange,
            onTap: (_) {},
          ),
          DrawerItem(
            icon: Icons.history,
            title: 'ประวัติการสั่งงาน',
            color: Colors.grey,
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
              'สวัสดี, $name',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              'อาคาร: $building',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            InfoCard(
              icon: Icons.business,
              title: 'อาคารที่รับผิดชอบ',
              value: building,
              color: Colors.orange,
              subtitle: 'ผู้ดูแลอาคาร',
            ),

            if (hasLocation)
              StreamBuilder<Map<String, SensorModel>>(
                stream: RealtimeService.buildingSensorStream(
                  schoolId: schoolId,
                  building: building,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SensorLoadingCard();
                  }
                  final rooms = snapshot.data ?? {};
                  if (rooms.isEmpty) return const SensorNoDataCard();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ทุกห้องในอาคาร',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...rooms.entries.map((entry) {
                        final sensor = entry.value;
                        final color = sensor.overallColor;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: Icon(sensor.overallLevel.icon,
                                color: color),
                            title: Text('ห้อง ${entry.key}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(sensor.overallLabel,
                                style: TextStyle(color: color)),
                            trailing: Text(
                              'CO₂ ${sensor.co2.toStringAsFixed(0)} ppm',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),

            const SizedBox(height: 8),
            const ComingSoonCard(
              icon: Icons.toggle_on,
              title: 'ควบคุมไฟ / น้ำ ทุกห้องในอาคาร',
              phase: 'Phase 4',
              color: Colors.orange,
            ),
            const ComingSoonCard(
              icon: Icons.history,
              title: 'Log การสั่งงาน',
              phase: 'Phase 4',
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
