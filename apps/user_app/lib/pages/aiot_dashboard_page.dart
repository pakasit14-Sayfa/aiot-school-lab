import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../widgets/sensor_card.dart';
import '../widgets/info_card.dart';

class AiotDashboardPage extends StatelessWidget {
  const AiotDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final schoolId = user?.schoolId ?? '';
    final building = user?.building ?? '';
    final room = user?.room ?? '';
    final hasLocation = schoolId.isNotEmpty && building.isNotEmpty && room.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('AIoT Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: hasLocation
            ? StreamBuilder<SensorModel?>(
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
                  return ListView(
                    children: [
                      OverallAirQualityCard(sensor: sensor),
                      const SizedBox(height: 16),
                      SensorGrid(sensor: sensor),
                    ],
                  );
                },
              )
            : const InfoCard(
                icon: Icons.info_outline,
                title: 'ยังไม่กำหนดห้องเรียน',
                value: 'กรุณาติดต่อครูหรือแอดมิน',
                color: Colors.orange,
                subtitle: 'เพื่อกำหนดห้องเรียนในระบบก่อนดูข้อมูลเซ็นเซอร์',
              ),
      ),
    );
  }
}
