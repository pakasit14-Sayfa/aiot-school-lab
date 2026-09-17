import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'student_aiot_dashboard_page.dart';
import 'student_redesign_palette.dart';

class AiotWeatherSensorsCard extends StatefulWidget {
  const AiotWeatherSensorsCard({
    super.key,
    this.height,
    this.sensorStreamOverride,
    this.rawReadingsStreamOverride,
  });

  final double? height;

  /// Test seams (same shape as DirectorOverviewPage's): production leaves
  /// them null and subscribes to RealtimeService.
  final Stream<SensorModel?>? sensorStreamOverride;
  final Stream<List<Map<String, dynamic>>>? rawReadingsStreamOverride;

  @override
  State<AiotWeatherSensorsCard> createState() =>
      _AiotWeatherSensorsCardState();
}

class _AiotWeatherSensorsCardState extends State<AiotWeatherSensorsCard> {
  // ต้อง cache stream ไว้ครั้งเดียวใน initState ห้ามเรียก
  // RealtimeService.sensorStream(...)/rawReadingsStream() แบบ inline
  // ใน builder: ของ StreamBuilder — เพราะ builder: ของ StreamBuilder
  // ชั้นนอก (rawReadingsStream) จะถูกเรียกซ้ำทุก ~5 วินาทีตาม poll tick
  // ของมันเอง ถ้า sensorStream(...) อยู่ inline ข้างในนั้น จะได้ Stream
  // object ใหม่ทุกครั้ง ทำให้ StreamBuilder ชั้นในตัด connection เดิมทิ้ง
  // แล้วต่อใหม่ทุก 5 วินาทีวนไปเรื่อยๆ ไม่มีทางได้ข้อมูลจริงมาแสดงเลย
  // (บั๊กเดียวกับที่การ์ดนี้เจอ — director_overview_page.dart ทำถูกอยู่
  // แล้วด้วย pattern นี้ ใช้เป็นต้นแบบ)
  late final Stream<List<Map<String, dynamic>>> _rawStream;
  late final Stream<SensorModel?> _sensorStream;

  @override
  void initState() {
    super.initState();
    _rawStream =
        widget.rawReadingsStreamOverride ?? RealtimeService.rawReadingsStream();
    _sensorStream =
        widget.sensorStreamOverride ??
        RealtimeService.sensorStream(
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

  // Same live/delayed/offline thresholds as SensorModel.freshnessOf, but
  // for a raw timestamp — aqi/gas_mq2_percent aren't tracked fields on
  // SensorModel so they need their own freshness calc.
  static SensorFreshness _freshnessOf(DateTime? ts) {
    if (ts == null) return SensorFreshness.noData;
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age <= const Duration(minutes: 2)) return SensorFreshness.live;
    if (age <= const Duration(minutes: 10)) return SensorFreshness.delayed;
    return SensorFreshness.offline;
  }

  static String _relativeTimeLabel(DateTime? ts) {
    if (ts == null) return 'ไม่มีข้อมูล';
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age.inSeconds < 60) return 'เมื่อสักครู่';
    if (age.inMinutes < 60) return '${age.inMinutes} นาทีที่แล้ว';
    if (age.inHours < 24) return '${age.inHours} ชม.ที่แล้ว';
    return '${age.inDays} วันที่แล้ว';
  }

  // Confirmed with the board's firmware author (2026-08-31): the "aqi"
  // metric is the ENS160 (ScioSense) gas sensor's own AQI-UBA index — a
  // 1-5 scale from the German Federal Environmental Agency (UBA)
  // guideline, derived internally by the chip from its TVOC signal. This
  // is NOT the 0-500 US EPA / Thai PCD Air Quality Index most people
  // expect from the term "AQI" — do not convert it 1:1 to that scale.
  static String _aqiUbaLabel(double level) {
    final rounded = level.round();
    switch (rounded) {
      case 1:
        return 'ดีมาก';
      case 2:
        return 'ดี';
      case 3:
        return 'ปานกลาง';
      case 4:
        return 'แย่';
      case 5:
        return 'ไม่ปลอดภัย';
      default:
        return 'ไม่ทราบระดับ';
    }
  }

  // 1-2 ดีมาก/ดี, 3 ปานกลาง, 4-5 แย่/ไม่ปลอดภัย — ตามตาราง AQI-UBA
  // ของ ENS160 ด้านบน แปลงเป็น SensorLevel เพื่อใช้สีเดียวกับ
  // metric อื่นที่มีเกณฑ์ good/moderate/danger อยู่แล้ว
  static SensorLevel _aqiUbaSensorLevel(double value) {
    final rounded = value.round();
    if (rounded <= 2) return SensorLevel.good;
    if (rounded == 3) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  // สีของ tile ตามระดับความรุนแรงจริง (เขียว/ส้ม/แดง) แทนสีตกแต่งคงที่
  // เดิม — ใช้เฉพาะ metric ที่มีเกณฑ์ค่าจริงยืนยันแล้ว (pm25/temp/
  // humidity/co2/aqi/tvoc) ส่วน MQ-2 ยังไม่มีเกณฑ์ calibrate จริง เลย
  // ไม่ใช้สีตามระดับ (ดูคอมเมนต์ตรง tile MQ-2 ด้านล่าง)
  static Color _levelColor(SensorLevel level) {
    switch (level) {
      case SensorLevel.good:
        return SchoolPalette.green;
      case SensorLevel.moderate:
        return SchoolPalette.orange;
      case SensorLevel.danger:
        return const Color(0xFFE11D48);
    }
  }

  // ข้อความสถานะคู่กับสี — สีอย่างเดียวไม่พอ (โดยเฉพาะกับคนตาบอดสี) ต้องมี
  // ตัวหนังสือกำกับด้วยเสมอว่า "ปกติ/ปานกลาง/เกินเกณฑ์" จริงๆ
  static String _levelLabel(SensorLevel level) {
    switch (level) {
      case SensorLevel.good:
        return 'ปกติ';
      case SensorLevel.moderate:
        return 'ปานกลาง';
      case SensorLevel.danger:
        return 'เกินเกณฑ์';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // aqi/gas_mq2_percent used to be fetched once in initState and
            // never again — a real bug: the value froze at whatever was
            // newest when the widget first mounted, while the freshness
            // caption (computed live from that frozen row's own timestamp)
            // kept correctly counting up, making it look like the sensor
            // went offline days ago even when fresh rows were arriving the
            // whole time. Poll them the same way as the sensor StreamBuilder
            // below instead of a one-shot fetch.
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _rawStream,
              builder: (context, rawSnapshot) {
                final rawRows = rawSnapshot.data ?? const <Map<String, dynamic>>[];
                final aqi = _latestValueOf(rawRows, 'aqi');
                final gas = _latestValueOf(rawRows, 'gas_mq2_percent');

                return StreamBuilder<SensorModel?>(
              stream: _sensorStream,
              builder: (context, snapshot) {
                final sensor = snapshot.data;
                const trackedMetrics = [
                  'pm25',
                  'temperature',
                  'humidity',
                  'light_lux',
                ];
                final headerFreshness =
                    sensor?.overallFreshnessOf(trackedMetrics) ??
                    SensorFreshness.noData;
                final bool hasAnyData =
                    sensor != null && sensor.updatedAt != null;

                final header = Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: headerFreshness.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: headerFreshness.color.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ข้อมูลเซนเซอร์สภาพอากาศ AIoT',
                        style: TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                );

                if (!hasAnyData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'ยังไม่มีข้อมูลเซนเซอร์จากอุปกรณ์ในโรงเรียน',
                          style: TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // SensorModel defaults an absent metric to 0, indistinguishable
                // from a real 0 reading — check metricUpdatedAt per metric
                // instead of trusting a non-null SensorModel alone (same fix
                // as director_overview_page.dart's identical bug).
                final bool hasPm25 = sensor.metricUpdatedAt.containsKey(
                  'pm25',
                );
                final bool hasTemp = sensor.metricUpdatedAt.containsKey(
                  'temperature',
                );
                final bool hasHumidity = sensor.metricUpdatedAt.containsKey(
                  'humidity',
                );
                final bool hasLux = sensor.metricUpdatedAt.containsKey(
                  'light_lux',
                );
                final bool hasCo2 = sensor.metricUpdatedAt.containsKey('co2');
                final bool hasTvoc = sensor.metricUpdatedAt.containsKey(
                  'tvoc',
                );

                // สีของแต่ละ tile ตามระดับความรุนแรงจริง (ปรับสีเมื่อค่า
                // เกินเกณฑ์) ใช้เกณฑ์ good/moderate/danger ที่มีอยู่แล้วบน
                // SensorModel — ไม่มีข้อมูลเลยหรือยังไม่ผ่าน calibrate
                // (MQ-2) ใช้สีตกแต่งเดิมคงที่
                final pm25Color = hasPm25
                    ? _levelColor(sensor.pm25Level)
                    : const Color(0xFF0284C7);
                final luxColor = hasLux
                    ? _levelColor(sensor.luxLevel)
                    : const Color(0xFFD97706);
                final tempColor = hasTemp
                    ? _levelColor(sensor.tempLevel)
                    : const Color(0xFFEA580C);
                final humidityColor = hasHumidity
                    ? _levelColor(sensor.humidityLevel)
                    : const Color(0xFF059669);
                final aqiColor = aqi != null
                    ? _levelColor(_aqiUbaSensorLevel(aqi.value))
                    : const Color(0xFF65A30D);
                final co2Color = hasCo2
                    ? _levelColor(sensor.co2Level)
                    : const Color(0xFF4C6EF5);
                // ใช้เกณฑ์ SensorModel.tvocLevel (0.3/0.5) ที่มีอยู่แล้วใน
                // widgets/sensor_card.dart — แต่ยังไม่ยืนยัน 100% ว่าหน่วยที่
                // ENS160 ส่งมาคือ ppb (ตามที่แสดงไว้) หรือ mg/m³ (ตามที่
                // sensor_card.dart กำกับหน่วยไว้) ถ้าคลาดเคลื่อน สีตรงนี้
                // อาจผิดไปด้วย — ควรยืนยันหน่วยกับผู้ทำ firmware อีกครั้ง
                final tvocColor = hasTvoc
                    ? _levelColor(sensor.tvocLevel)
                    : const Color(0xFFAE3EC9);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 3),
                    Text(
                      'ข้อมูลสดจาก Supabase • อัปเดต ${sensor.relativeTimeLabel("pm25")}',
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ห้ามใช้ CrossAxisAlignment.stretch แบบลอยๆ ตรงนี้ —
                    // เมื่อการ์ดนี้ถูกเรียกแบบไม่ระบุ height (โหมดมือถือ/
                    // คอลัมน์เดียวใน student_variant_school_home.dart) ระยะ
                    // สูงที่ได้รับมาจากบรรพบุรุษ (สืบทอดมาจาก scroll view)
                    // จะไม่จำกัด (Infinity) การ stretch แนวตั้งจะสั่งให้ลูก
                    // ขยายเต็มความสูงที่ไม่จำกัด เกิด "BoxConstraints forces
                    // an infinite height" ตอนรันจริง — ต้องห่อ IntrinsicHeight
                    // ก่อนเสมอ (แพทเทิร์นเดียวกับ teacher_redesign_prototype_page.dart:1106)
                    IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _WeatherTile(
                            icon: Icons.air_rounded,
                            title: 'PM2.5',
                            value: hasPm25
                                ? '${sensor.pm25.toStringAsFixed(0)} µg/m³ · ${_levelLabel(sensor.pm25Level)}'
                                : 'ไม่มีข้อมูล',
                            color: pm25Color,
                            level: hasPm25 ? sensor.pm25Level : null,
                            freshness: hasPm25
                                ? sensor.freshnessOf('pm25')
                                : SensorFreshness.noData,
                            timeLabel: hasPm25
                                ? sensor.relativeTimeLabel('pm25')
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WeatherTile(
                            icon: Icons.wb_sunny_rounded,
                            title: 'ความเข้มแสง',
                            value: hasLux
                                ? '${sensor.lux.toStringAsFixed(0)} lux · ${_levelLabel(sensor.luxLevel)}'
                                : 'ไม่มีข้อมูล',
                            color: luxColor,
                            level: hasLux ? sensor.luxLevel : null,
                            freshness: hasLux
                                ? sensor.freshnessOf('light_lux')
                                : SensorFreshness.noData,
                            timeLabel: hasLux
                                ? sensor.relativeTimeLabel('light_lux')
                                : null,
                          ),
                        ),
                      ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _WeatherTile(
                            icon: Icons.thermostat_rounded,
                            title: 'อุณหภูมิ',
                            value: hasTemp
                                ? '${sensor.temperature.toStringAsFixed(1)} °C · ${_levelLabel(sensor.tempLevel)}'
                                : 'ไม่มีข้อมูล',
                            color: tempColor,
                            level: hasTemp ? sensor.tempLevel : null,
                            freshness: hasTemp
                                ? sensor.freshnessOf('temperature')
                                : SensorFreshness.noData,
                            timeLabel: hasTemp
                                ? sensor.relativeTimeLabel('temperature')
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WeatherTile(
                            icon: Icons.water_drop_rounded,
                            title: 'ความชื้น',
                            value: hasHumidity
                                ? '${sensor.humidity.toStringAsFixed(0)}%RH · ${_levelLabel(sensor.humidityLevel)}'
                                : 'ไม่มีข้อมูล',
                            color: humidityColor,
                            level: hasHumidity ? sensor.humidityLevel : null,
                            freshness: hasHumidity
                                ? sensor.freshnessOf('humidity')
                                : SensorFreshness.noData,
                            timeLabel: hasHumidity
                                ? sensor.relativeTimeLabel('humidity')
                                : null,
                          ),
                        ),
                      ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): นี่คือ
                          // ดัชนี AQI-UBA ของชิป ENS160 สเกล 1-5 (ตาม
                          // German UBA) ไม่ใช่ AQI มาตรฐาน 0-500 ของ US EPA/
                          // กรมควบคุมมลพิษไทย — ห้ามเขียนแค่ "AQI" เฉยๆ
                          child: _WeatherTile(
                            icon: Icons.eco_rounded,
                            title: 'AQI-UBA (ENS160)',
                            value: aqi != null
                                ? '${aqi.value.toStringAsFixed(0)} · ${_aqiUbaLabel(aqi.value)}'
                                : 'ไม่มีข้อมูล',
                            color: aqiColor,
                            level: aqi != null ? _aqiUbaSensorLevel(aqi.value) : null,
                            freshness: _freshnessOf(aqi?.ts),
                            timeLabel: aqi != null
                                ? _relativeTimeLabel(aqi.ts)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          // MQ-2 ตอบสนองต่อทั้งแก๊สติดไฟและควันจริงตามสเปกชิป
                          // แต่ส่งออกมาเป็นสัญญาณตัวเลขเดียวรวมกัน แยกไม่ออก
                          // ว่าเกิดจากแก๊สหรือควัน — ห้ามเขียนค่าเป็น
                          // "แก๊ส/ควัน X%" เฉยๆ (จะดูเหมือนความเข้มข้นที่
                          // calibrate แล้ว) ต้องกำกับ "(ดิบ)" เสมอจนกว่าจะ
                          // calibrate เป็น ppm จริง (แพทเทิร์นเดียวกับ
                          // director_environment_page.dart /
                          // teacher_aiot_lab_page.dart) — สีคงที่ไม่ปรับ
                          // ตามระดับเหมือน metric อื่น เพราะไม่มีเกณฑ์ที่
                          // calibrate แล้วมาตัดสินว่า "เกิน" จริงๆ
                          child: _WeatherTile(
                            icon: Icons.local_fire_department_rounded,
                            title: 'แก๊ส/ควัน (MQ-2)',
                            value: gas != null
                                ? '${gas.value.toStringAsFixed(0)}% (ดิบ)'
                                : 'ไม่มีข้อมูล',
                            color: const Color(0xFFE11D48),
                            freshness: _freshnessOf(gas?.ts),
                            timeLabel: gas != null
                                ? _relativeTimeLabel(gas.ts)
                                : null,
                          ),
                        ),
                      ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): บอร์ด
                          // ใช้ชิปแก๊ส ENS160 (ScioSense, MOX multi-gas —
                          // ไม่ใช่ SGP30/SGP40 ตามที่เคยสันนิษฐานไว้) ค่า
                          // "co2" ที่ส่งเข้าระบบคือ eCO2 (Equivalent CO2) ที่
                          // ชิปคำนวณจาก VOCs/hydrogen ภายใน ไม่ใช่การวัด CO2
                          // ตรงแบบเซนเซอร์ NDIR — ต้องเขียนกำกับว่า
                          // "ประมาณการ" เสมอ
                          child: _WeatherTile(
                            icon: Icons.cloud_outlined,
                            title: 'eCO2 (ประมาณการ)',
                            value: hasCo2
                                ? '${sensor.co2.toStringAsFixed(0)} ppm · ${_levelLabel(sensor.co2Level)}'
                                : 'ไม่มีข้อมูล',
                            color: co2Color,
                            level: hasCo2 ? sensor.co2Level : null,
                            freshness: hasCo2
                                ? sensor.freshnessOf('co2')
                                : SensorFreshness.noData,
                            timeLabel: hasCo2
                                ? sensor.relativeTimeLabel('co2')
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          // ใช้เกณฑ์ SensorModel.tvocLevel (0.3/0.5) ที่มี
                          // อยู่แล้วใน widgets/sensor_card.dart — แต่ยัง
                          // ไม่ยืนยัน 100% ว่าหน่วยที่ ENS160 ส่งมาคือ ppb
                          // (ตามที่แสดงไว้) หรือ mg/m³ (ตามที่
                          // sensor_card.dart กำกับหน่วยไว้) ถ้าคลาดเคลื่อน
                          // สีตรงนี้อาจผิดไปด้วย — ควรยืนยันหน่วยกับผู้ทำ
                          // firmware อีกครั้ง
                          child: _WeatherTile(
                            icon: Icons.science_outlined,
                            title: 'TVOC',
                            value: hasTvoc
                                ? '${sensor.tvoc.toStringAsFixed(0)} ppb · ${_levelLabel(sensor.tvocLevel)}'
                                : 'ไม่มีข้อมูล',
                            color: tvocColor,
                            level: hasTvoc ? sensor.tvocLevel : null,
                            freshness: hasTvoc
                                ? sensor.freshnessOf('tvoc')
                                : SensorFreshness.noData,
                            timeLabel: hasTvoc
                                ? sensor.relativeTimeLabel('tvoc')
                                : null,
                          ),
                        ),
                      ],
                      ),
                    ),
                  ],
                );
              },
                );
              },
            ),
            if (widget.height != null)
              const Spacer()
            else
              const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentAiotDashboardPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                label: const Text(
                  'ไปหน้า AIoT Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 28, 127, 70),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shadowColor: const Color.fromARGB(
                    255,
                    28,
                    127,
                    70,
                  ).withValues(alpha: 0.25),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherTile extends StatelessWidget {
  const _WeatherTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.freshness = SensorFreshness.noData,
    this.timeLabel,
    this.level,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final SensorFreshness freshness;
  final String? timeLabel;
  final SensorLevel? level;

  @override
  Widget build(BuildContext context) {
    // เซนเซอร์ตัวนี้เอง "ออนไลน์ (สด/ล่าช้าเล็กน้อย)" หรือ "ไม่ออนไลน์
    // (เกิน 10 นาที/ไม่มีข้อมูล)" — สีจุด+ข้อความอิงจาก SensorFreshness
    // เดียวกับที่ใช้ตัดสินจุดสถานะหัวการ์ด แค่แสดงแยกทีละอุปกรณ์/metric
    final bool isOnline =
        freshness == SensorFreshness.live ||
        freshness == SensorFreshness.delayed;

    // สีเข้มขึ้นทั้งหมด (ตามที่ผู้ใช้ขอ — ค่าพวกนี้สำคัญ ต้องเด่นชัด) และ
    // เข้มขึ้นไปอีกเป็นพิเศษเมื่อ "เกินเกณฑ์" เพื่อให้สายตาสะดุดจุดที่ต้อง
    // ระวังก่อนจุดที่ปกติ
    final bool isDanger = level == SensorLevel.danger;
    final double bgAlpha = isDanger ? 0.24 : 0.15;
    final double borderAlpha = isDanger ? 0.65 : 0.4;
    final double borderWidth = isDanger ? 2.0 : 1.3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: borderAlpha),
          width: borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: SchoolPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                if (timeLabel != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: freshness.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isOnline ? 'ออนไลน์ • $timeLabel' : 'ไม่ออนไลน์ • $timeLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: freshness.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
