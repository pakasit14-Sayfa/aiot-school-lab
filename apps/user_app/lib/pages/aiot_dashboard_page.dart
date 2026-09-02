import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../widgets/sensor_card.dart';

class AiotDashboardPage extends StatefulWidget {
  const AiotDashboardPage({super.key});

  @override
  State<AiotDashboardPage> createState() => _AiotDashboardPageState();
}

class _AiotDashboardPageState extends State<AiotDashboardPage> {
  // ต้อง cache stream ไว้ครั้งเดียวใน initState ห้ามเรียก
  // RealtimeService.sensorStream(...)/rawReadingsStream() แบบ inline ใน
  // builder: ของ StreamBuilder — เพราะ builder: ของ StreamBuilder ชั้นนอก
  // (rawReadingsStream) จะถูกเรียกซ้ำทุก ~5 วินาทีตาม poll tick ของมันเอง
  // ถ้า sensorStream(...) อยู่ inline ข้างในนั้น จะได้ Stream object ใหม่
  // ทุกครั้ง ทำให้ StreamBuilder ชั้นในตัด connection เดิมทิ้งแล้วต่อใหม่
  // ทุก 5 วินาทีวนไปเรื่อยๆ ไม่มีทางได้ข้อมูลจริงมาแสดงเลย (บั๊กเดียวกับที่
  // เจอในหน้านักเรียน/ครู)
  late final Stream<List<Map<String, dynamic>>> _rawStream;
  late final Stream<SensorModel?> _sensorStream;

  @override
  void initState() {
    super.initState();
    _rawStream = RealtimeService.rawReadingsStream();
    _sensorStream = RealtimeService.sensorStream(
      schoolId: currentUserModel?.schoolId ?? '',
      building: '',
      floor: '',
      room: '',
    );
  }

  static ({double value, DateTime? ts})? _latestValueOf(
    List<Map<String, dynamic>> rows,
    String metric,
  ) {
    Map<String, dynamic>? latest;
    DateTime? latestTs;
    for (final r in rows) {
      if (r['metric'] != metric) continue;
      final ts = DateTime.tryParse(r['ts'] as String? ?? '');
      if (latest == null ||
          (ts != null && (latestTs == null || ts.isAfter(latestTs)))) {
        latest = r;
        latestTs = ts;
      }
    }
    final v = latest?['value'];
    if (v is! num) return null;
    return (value: v.toDouble(), ts: latestTs);
  }

  @override
  Widget build(BuildContext context) {
    // เดิมหน้านี้บังคับต้องมี schoolId+building+room ครบถึงจะดูข้อมูลได้ —
    // ต่างจากทุกหน้า AIoT weather card อื่นในแอปที่ query แบบรวมทั้งโรงเรียน
    // (room ว่าง) ทำให้บัญชีที่ยังไม่ผูกห้อง/อาคาร (พบได้ทั่วไป โดยเฉพาะ
    // ผู้บริหาร/ผู้ปกครอง) มาหน้านี้แล้วเจอแต่ "ยังไม่กำหนดห้องเรียน" ทั้งที่
    // ข้อมูลจริงของทั้งโรงเรียนมีอยู่ปกติ — เปลี่ยนให้ query แบบเดียวกับ
    // หน้าอื่นทั้งหมด (รวมทั้งโรงเรียน) แทน
    return Scaffold(
      appBar: AppBar(title: const Text('AIoT Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _rawStream,
          builder: (context, rawSnapshot) {
            final rawRows = rawSnapshot.data ?? const <Map<String, dynamic>>[];
            final aqiReading = _latestValueOf(rawRows, 'aqi');
            final gasReading = _latestValueOf(rawRows, 'gas_mq2_percent');

            return StreamBuilder<SensorModel?>(
              stream: _sensorStream,
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
                    SensorGrid(
                      sensor: sensor,
                      aqiReading: aqiReading,
                      gasReading: gasReading,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
