import 'package:my_first_app/widgets/visible_sensor_stream_builder.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../theme/app_palette.dart';
import 'director_common_widgets.dart';

class DirectorOverviewSensors extends StatefulWidget {
  const DirectorOverviewSensors({
    super.key,
    this.sensorStreamOverride,
    this.rawReadingsStreamOverride,
  });
  final Stream<SensorModel?>? sensorStreamOverride;
  final Stream<List<Map<String, dynamic>>>? rawReadingsStreamOverride;
  @override
  State<DirectorOverviewSensors> createState() =>
      _DirectorOverviewSensorsState();
}

class _DirectorOverviewSensorsState extends State<DirectorOverviewSensors> {
  late final Stream<SensorModel?> _sensorStream =
      widget.sensorStreamOverride ??
      RealtimeService.sensorStream(
        schoolId: currentUserModel?.schoolId ?? '',
        building: '',
        floor: '',
        room: '',
      );
  late final Stream<List<Map<String, dynamic>>> _rawStream =
      widget.rawReadingsStreamOverride ?? RealtimeService.rawReadingsStream();
  @override
  Widget build(BuildContext context) => _resourceSixTileCard();
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
  // SensorModel so they need their own freshness calc (same helper as
  // aiot_weather_sensors_card.dart's identical case on the student page).
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
  // humidity/co2/aqi) ส่วน MQ-2 ยังไม่มีเกณฑ์ calibrate จริง เลย
  // ไม่ใช้สีตามระดับ (ดูคอมเมนต์ตรง tile MQ-2 ด้านล่าง)
  static Color _levelColor(SensorLevel level) {
    switch (level) {
      case SensorLevel.good:
        return AppPalette.success;
      case SensorLevel.moderate:
        return AppPalette.warning;
      case SensorLevel.danger:
        return AppPalette.danger;
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

  Widget _resourceSixTileCard() {
    // aqi/gas_mq2_percent used to be fetched once in initState and never
    // again — a real bug: the value froze at whatever was newest when the
    // page first loaded, while the freshness caption (computed live from
    // that frozen row's own timestamp) kept correctly counting up, making
    // it look like the sensor went offline days ago even when fresh rows
    // were arriving the whole time. Poll them the same way as the
    // pm25/temp/humidity/lux StreamBuilder below instead of a one-shot.
    return VisibleSensorStreamBuilder<List<Map<String, dynamic>>>(
      stream: _rawStream,
      builder: (context, rawSnapshot) {
        final rawRows = rawSnapshot.data ?? const <Map<String, dynamic>>[];
        final aqiReading = _latestValueOf(rawRows, 'aqi');
        final gasReading = _latestValueOf(rawRows, 'gas_mq2_percent');

        return VisibleSensorStreamBuilder<SensorModel?>(
          stream: _sensorStream,
          builder: (context, snapshot) {
            final sensor = snapshot.data;
            // SensorModel defaults an absent metric to 0, indistinguishable
            // from a real 0 reading — check metricUpdatedAt per metric
            // (same fix as the teacher dashboard's identical bug, see
            // RealtimeService.getWeatherMetricsWithData's doc comment)
            // instead of trusting a non-null SensorModel alone.
            final bool hasPm25 =
                sensor != null && sensor.metricUpdatedAt.containsKey('pm25');
            final bool hasTemp =
                sensor != null &&
                sensor.metricUpdatedAt.containsKey('temperature');
            final bool hasLux =
                sensor != null &&
                sensor.metricUpdatedAt.containsKey('light_lux');
            final bool hasHumidity =
                sensor != null &&
                sensor.metricUpdatedAt.containsKey('humidity');
            final bool hasCo2 =
                sensor != null && sensor.metricUpdatedAt.containsKey('co2');
            final bool hasTvoc =
                sensor != null && sensor.metricUpdatedAt.containsKey('tvoc');

            // เดิมรวม "ตัวเลข · ระดับ" เป็นสตริงเดียว — ดีไซน์ใหม่ (อ้างอิงการ์ด
            // สไตล์ Apple Health ที่ผู้ใช้ส่งมา) แยกตัวเลข/หน่วยกับป้ายระดับ
            // ออกจากกัน ป้ายระดับให้ _resourceTile คำนวณเองจาก level โดยตรง
            final pm25Val = hasPm25 ? sensor.pm25.toStringAsFixed(0) : null;
            final tempVal = hasTemp
                ? sensor.temperature.toStringAsFixed(1)
                : null;
            final luxVal = hasLux ? sensor.lux.toStringAsFixed(0) : null;
            final humidityVal = hasHumidity
                ? sensor.humidity.toStringAsFixed(0)
                : null;
            final aqiVal = aqiReading?.value.toStringAsFixed(0);
            final gasVal = gasReading?.value.toStringAsFixed(0);
            final co2Val = hasCo2 ? sensor.co2.toStringAsFixed(0) : null;
            final tvocVal = hasTvoc ? sensor.tvoc.toStringAsFixed(0) : null;

            // สีของแต่ละ tile ตามระดับความรุนแรงจริง (ปรับสีเมื่อค่าเกินเกณฑ์)
            // ใช้เกณฑ์ good/moderate/danger ที่มีอยู่แล้วบน SensorModel — ไม่มี
            // ข้อมูลเลยหรือยังไม่ผ่าน calibrate (MQ-2) ใช้สีตกแต่งเดิมคงที่
            final pm25Color = hasPm25
                ? _levelColor(sensor.pm25Level)
                : AppPalette.chartCream;
            final luxColor = hasLux
                ? _levelColor(sensor.luxLevel)
                : AppPalette.behaviorYellow;
            final tempColor = hasTemp
                ? _levelColor(sensor.tempLevel)
                : AppPalette.learningBlue;
            final humidityColor = hasHumidity
                ? _levelColor(sensor.humidityLevel)
                : AppPalette.environmentGreen;
            final aqiColor = aqiReading != null
                ? _levelColor(_aqiUbaSensorLevel(aqiReading.value))
                : AppPalette.warning;
            final co2Color = hasCo2
                ? _levelColor(sensor.co2Level)
                : AppPalette.chartBlue;
            final tvocColor = hasTvoc
                ? _levelColor(sensor.tvocLevel)
                : AppPalette.chartPink2;

            final headerFreshness =
                sensor?.overallFreshnessOf(const [
                  'pm25',
                  'temperature',
                  'humidity',
                  'light_lux',
                ]) ??
                SensorFreshness.noData;

            return Container(
              width: double.infinity,
              height: 460,
              padding: const EdgeInsets.all(14),
              decoration: directorWhiteCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(
                            AppPalette.environmentGreen,
                            0.12,
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          size: 18,
                          color: AppPalette.environmentGreen,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: headerFreshness.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: headerFreshness.color.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 6,
                                        spreadRadius: 1.5,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Expanded(
                                  child: Text(
                                    'ข้อมูลเซนเซอร์สภาพอากาศ AIoT',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sensor != null && sensor.updatedAt != null
                                  ? 'ข้อมูลสดจาก Supabase • อัปเดต ${sensor.relativeTimeLabel("pm25")}'
                                  : 'ภาพรวมคุณภาพอากาศ แสง อุณหภูมิ และการแจ้งเตือนก๊าซภายในห้องเรียน',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // แบ่งพื้นที่ที่เหลือให้ 3 แถวเท่ากัน
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _resourceTile(
                                  title: 'PM2.5',
                                  value: pm25Val,
                                  unit: 'µg/m³',
                                  icon: Icons.air_rounded,
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: _resourceTile(
                                  title: 'ความเข้มแสง',
                                  value: luxVal,
                                  unit: 'lux',
                                  icon: Icons.light_mode_rounded,
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
                        const SizedBox(height: 8),

                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _resourceTile(
                                  title: 'อุณหภูมิ',
                                  value: tempVal,
                                  unit: '°C',
                                  icon: Icons.thermostat_rounded,
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: _resourceTile(
                                  title: 'ความชื้น',
                                  value: humidityVal,
                                  unit: '%RH',
                                  icon: Icons.water_drop_rounded,
                                  color: humidityColor,
                                  level: hasHumidity
                                      ? sensor.humidityLevel
                                      : null,
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
                        const SizedBox(height: 8),

                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _resourceTile(
                                  // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): นี่คือ
                                  // ดัชนี AQI-UBA ของชิป ENS160 สเกล 1-5 (ตาม
                                  // German UBA) ไม่ใช่ AQI มาตรฐาน 0-500 ของ US EPA/
                                  // กรมควบคุมมลพิษไทย — ห้ามเขียนแค่ "AQI" เฉยๆ
                                  title: 'AQI-UBA (ENS160)',
                                  value: aqiVal,
                                  unit: '',
                                  icon: Icons.eco_rounded,
                                  color: aqiColor,
                                  level: aqiReading != null
                                      ? _aqiUbaSensorLevel(aqiReading.value)
                                      : null,
                                  // สเกล UBA 5 ระดับมีความหมายเฉพาะของตัวเอง
                                  // (ดีมาก/ดี/ปานกลาง/แย่/ไม่ปลอดภัย) ไม่ใช่
                                  // ปกติ/ปานกลาง/เกินเกณฑ์ ทั่วไปแบบ metric อื่น
                                  levelLabelOverride: aqiReading != null
                                      ? _aqiUbaLabel(aqiReading.value)
                                      : null,
                                  freshness: _freshnessOf(aqiReading?.ts),
                                  timeLabel: aqiReading != null
                                      ? _relativeTimeLabel(aqiReading.ts)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _resourceTile(
                                  // MQ-2 ตอบสนองต่อทั้งแก๊สติดไฟและควันจริงตาม
                                  // สเปกชิป แต่ส่งออกมาเป็นสัญญาณตัวเลขเดียวรวมกัน
                                  // แยกไม่ออกว่าเกิดจากแก๊สหรือควัน — ห้ามเขียนค่า
                                  // เป็น "แก๊ส/ควัน X%" เฉยๆ (จะดูเหมือนความเข้มข้น
                                  // ที่ calibrate แล้ว) ต้องกำกับ "(ดิบ)" เสมอ
                                  // จนกว่าจะ calibrate เป็น ppm จริง (แพทเทิร์น
                                  // เดียวกับ director_environment_page.dart /
                                  // teacher_aiot_lab_page.dart) — สีคงที่ไม่ปรับ
                                  // ตามระดับเหมือน metric อื่น เพราะไม่มีเกณฑ์
                                  // ที่ calibrate แล้วมาตัดสินว่า "เกิน" จริงๆ
                                  title: 'แก๊ส/ควัน (MQ-2)',
                                  value: gasVal,
                                  unit: '% (ดิบ)',
                                  freshness: _freshnessOf(gasReading?.ts),
                                  timeLabel: gasReading != null
                                      ? _relativeTimeLabel(gasReading.ts)
                                      : null,
                                  icon: Icons.local_fire_department_rounded,
                                  color: AppPalette.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _resourceTile(
                                  // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): บอร์ด
                                  // ใช้ชิปแก๊ส ENS160 (ScioSense, MOX multi-gas —
                                  // ไม่ใช่ SGP30/SGP40 ตามที่เคยสันนิษฐานไว้) ค่า
                                  // "co2" ที่ส่งเข้าระบบคือ eCO2 (Equivalent CO2)
                                  // ที่ชิปคำนวณจาก VOCs/hydrogen ภายใน ไม่ใช่การวัด
                                  // CO2 ตรงแบบเซนเซอร์ NDIR — ต้องเขียนกำกับว่า
                                  // "ประมาณการ" เสมอ
                                  title: 'eCO2 (ประมาณการ)',
                                  value: co2Val,
                                  unit: 'ppm',
                                  icon: Icons.cloud_outlined,
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: _resourceTile(
                                  // ใช้เกณฑ์ SensorModel.tvocLevel (0.3/0.5) ที่มี
                                  // อยู่แล้วใน widgets/sensor_card.dart — แต่ยัง
                                  // ไม่ยืนยัน 100% ว่าหน่วยที่ ENS160 ส่งมาคือ
                                  // ppb (ตามที่แสดงไว้) หรือ mg/m³ (ตามที่
                                  // sensor_card.dart กำกับหน่วยไว้) ถ้าคลาดเคลื่อน
                                  // สีตรงนี้อาจผิดไปด้วย — ควรยืนยันหน่วยกับผู้ทำ
                                  // firmware อีกครั้ง
                                  title: 'TVOC',
                                  value: tvocVal,
                                  unit: 'ppb',
                                  icon: Icons.science_outlined,
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
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ดีไซน์อ้างอิงการ์ดสไตล์ Apple Health ที่ผู้ใช้ส่งมา: ไอคอน+ป้ายชื่อสีเทา
  // (ไม่ใช่กล่องสี), ตัวเลขใหญ่สีเข้ม+หน่วยเล็กข้างๆ, แถวสถานะสีพร้อมไอคอน,
  // และแท่งวัดแนวตั้งด้านขวา —ต่างจากต้นฉบับตรงตำแหน่งจุดบนแท่งวัด: ของจริง
  // อิงจากระดับ good/moderate/danger ที่มีเกณฑ์รองรับอยู่แล้วเท่านั้น (ไม่ใช่
  // ตำแหน่งเทียบช่วงค่าปกติเฉพาะบุคคล/เซนเซอร์แบบแอปต้นแบบ เพราะไม่มีข้อมูล
  // ช่วงอ้างอิงที่ calibrate จริงมาให้ใช้)
  Widget _resourceTile({
    required String title,
    required IconData icon,
    required Color color,
    String? value,
    String unit = '',
    SensorFreshness freshness = SensorFreshness.noData,
    String? timeLabel,
    SensorLevel? level,
    String? levelLabelOverride,
  }) {
    final bool isOnline =
        freshness == SensorFreshness.live ||
        freshness == SensorFreshness.delayed;
    final String? statusLabel =
        levelLabelOverride ?? (level != null ? _levelLabel(level) : null);
    final IconData? statusIcon = switch (level) {
      SensorLevel.good => Icons.check_circle_rounded,
      SensorLevel.moderate => Icons.remove_circle_rounded,
      SensorLevel.danger => Icons.arrow_circle_down_rounded,
      null => null,
    };
    final double? gaugePosition = switch (level) {
      SensorLevel.good => .82,
      SensorLevel.moderate => .5,
      SensorLevel.danger => .18,
      null => null,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 13, color: AppPalette.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  value == null
                      ? const Text(
                          'ไม่มีข้อมูล',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.textMuted,
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppPalette.textDark,
                                letterSpacing: -.5,
                              ),
                            ),
                            if (unit.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              Text(
                                unit,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                  // แถวสถานะ+ความสดรวมกันบรรทัดเดียว (เดิมแยก 2 บรรทัด แต่
                  // พื้นที่ต่อ tile มีจำกัดแค่ ~66px ทำให้ล้นออกนอกกรอบ) ยังคง
                  // บอกทั้งระดับจริงและความสดของข้อมูลไว้ครบ ไม่ตัดออก
                  if (statusLabel != null || timeLabel != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (statusLabel != null)
                          Icon(statusIcon, size: 10, color: color),
                        if (statusLabel != null) const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            [
                              if (statusLabel case final label?) label,
                              if (timeLabel != null)
                                isOnline ? 'ออนไลน์' : 'ไม่ออนไลน์ $timeLabel',
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: statusLabel != null ? color : freshness.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (gaugePosition != null) ...[
              const SizedBox(width: 6),
              _SensorGauge(color: color, position: gaugePosition),
            ],
          ],
        ),
      ),
    );
  }
}

/// แท่งวัดแนวตั้งเล็กๆ ด้านขวาของแต่ละ tile — จุดสีอยู่ตามตำแหน่งที่คำนวณจาก
/// [position] (0=ล่างสุด, 1=บนสุด) ซึ่งมาจากระดับ good/moderate/danger จริง
class _SensorGauge extends StatelessWidget {
  const _SensorGauge({required this.color, required this.position});
  final Color color;
  final double position;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14,
    child: LayoutBuilder(
      builder: (_, box) {
        final h = box.hasBoundedHeight ? box.maxHeight : 60.0;
        const dot = 10.0;
        final top = ((1 - position) * (h - dot)).clamp(0.0, h - dot);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              top: top,
              left: (14 - dot) / 2,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: .4), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
