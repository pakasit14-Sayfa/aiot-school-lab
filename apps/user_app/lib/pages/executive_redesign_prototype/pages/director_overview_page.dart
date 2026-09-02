import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorOverviewPage extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final Stream<SensorModel?>? sensorStreamOverride;
  final Stream<List<Map<String, dynamic>>>? rawReadingsStreamOverride;

  const DirectorOverviewPage({
    super.key,
    required this.onNavigate,
    this.sensorStreamOverride,
    this.rawReadingsStreamOverride,
  });

  @override
  State<DirectorOverviewPage> createState() => _DirectorOverviewPageState();
}

class _DirectorOverviewPageState extends State<DirectorOverviewPage> {
  int selectedPeriod = 0;
  int selectedUtilityPeriod = 0;
  int _importantFilterIndex = 0;
  final DateTime _selectedDate = DateTime.now();
  final ScrollController _importantScrollController = ScrollController();
  late final Stream<SensorModel?> _sensorStream;

  Map<String, int> _userCounts = {};
  List<DeviceOption> _devices = [];
  List<IncidentSummaryItem> _incidentSummary = [];
  List<LearningTrackOverview> _trackOverview = [];

  static const List<String> _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  static const List<String> _thaiShortMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  static const List<String> _thaiDayNames = [
    'วันจันทร์', 'วันอังคาร', 'วันพุธ', 'วันพฤหัสบดี', 'วันศุกร์', 'วันเสาร์', 'วันอาทิตย์'
  ];

  String get _todayDateText {
    final now = DateTime.now();
    final dayName = _thaiDayNames[now.weekday - 1];
    final monthName = _thaiMonths[now.month - 1];
    final year = now.year + 543;
    return '$dayNameที่ ${now.day} $monthName พ.ศ. $year';
  }

  String get _dateLabelFormatted {
    final now = DateTime.now();
    final day = now.day;
    final year = now.year + 543;
    if (selectedPeriod == 0) {
      final dayName = _thaiDayNames[now.weekday - 1];
      final month = _thaiMonths[now.month - 1];
      return '$dayNameที่ $day $month พ.ศ. $year';
    } else if (selectedPeriod == 1) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final mMonth = _thaiShortMonths[monday.month - 1];
      final sMonth = _thaiShortMonths[sunday.month - 1];
      final sYear = sunday.year + 543;
      return '${monday.day} $mMonth - ${sunday.day} $sMonth $sYear';
    } else {
      final month = _thaiMonths[now.month - 1];
      return '$month พ.ศ. $year';
    }
  }

  String get _scopeLabelFormatted {
    if (selectedPeriod == 0) {
      return 'ข้อมูลประจำ$_dateLabelFormatted';
    } else if (selectedPeriod == 1) {
      return 'ข้อมูลประจำสัปดาห์ $_dateLabelFormatted';
    } else {
      return 'ข้อมูลประจำเดือน $_dateLabelFormatted';
    }
  }

  @override
  void initState() {
    super.initState();
    _sensorStream = widget.sensorStreamOverride ??
        RealtimeService.sensorStream(
          schoolId: currentUserModel?.schoolId ?? '',
          building: '',
          floor: '',
          room: '',
        );
    _loadExecutiveData();
  }

  Future<void> _loadExecutiveData() async {
    try {
      final results = await Future.wait([
        UserAdminService.countUsersByRole(),
        LessonService.listSchoolDevices(),
        IncidentService.getIncidentSummary(),
        LearningTrackService.getOverview(),
      ]);
      if (!mounted) return;
      setState(() {
        _userCounts = results[0] as Map<String, int>;
        _devices = results[1] as List<DeviceOption>;
        _incidentSummary = results[2] as List<IncidentSummaryItem>;
        _trackOverview = results[3] as List<LearningTrackOverview>;
      });
    } catch (error) {
      debugPrint('director_overview_page: _loadExecutiveData failed: $error');
    }
  }

  /// จัดกลุ่มอุปกรณ์ IoT จริงตามห้อง (location) — ใช้คำนวณสถิติห้อง/เซนเซอร์
  /// ในหน้าต่างรายละเอียด แทนตัวเลขสมมติ อุปกรณ์ที่ไม่มี location จะไม่ถูกนับ
  /// เป็นห้อง (นับรวมอยู่ใน "เซนเซอร์ออนไลน์" เท่านั้น)
  Map<String, List<DeviceOption>> get _devicesByRoom {
    final map = <String, List<DeviceOption>>{};
    for (final d in _devices) {
      final room = (d.location ?? '').trim();
      if (room.isEmpty) continue;
      map.putIfAbsent(room, () => []).add(d);
    }
    return map;
  }

  Widget _demoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Text(
        'ข้อมูลจำลอง',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF92400E),
        ),
      ),
    );
  }

  /// ค่าล่าสุดของ metric หนึ่งตัวจาก sensor_latest แบบ raw rows — ใช้สำหรับ
  /// metric ที่ไม่มีอยู่ใน SensorModel (aqi, gas_mq2_percent) ต่างจาก
  /// pm25/temperature/humidity/lux ที่มาจาก _sensorStream ข้างบนอยู่แล้ว
  static ({double value, DateTime? ts})? _latestValueOf(
    List<Map<String, dynamic>> rows,
    String metric,
  ) {
    Map<String, dynamic>? latest;
    DateTime? latestTs;
    for (final r in rows) {
      if (r['metric'] != metric) continue;
      final ts = DateTime.tryParse(r['ts'] as String? ?? '');
      if (latest == null || (ts != null && (latestTs == null || ts.isAfter(latestTs)))) {
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

  List<_ProgramOverviewData> get programOverview {
    return _trackOverview
        .map(
          (t) => _ProgramOverviewData(
            title: t.name,
            color: _colorFromHex(t.color),
            studentCount: t.studentCount,
            roomCount: t.roomCount,
            avgGradePercent: t.avgGradePercent,
          ),
        )
        .toList();
  }

  String get _trackBannerText {
    final graded = _trackOverview.where((t) => t.avgGradePercent != null).toList();
    if (graded.isEmpty) {
      return 'ยังไม่มีคะแนนที่ครูยืนยันแล้วสำหรับคำนวณผลสัมฤทธิ์ภาพรวม';
    }
    final overall =
        graded.map((t) => t.avgGradePercent!).reduce((a, b) => a + b) /
        graded.length;
    return 'ผลสัมฤทธิ์เฉลี่ยทุกสายการเรียน ${overall.toStringAsFixed(1)}% (จากคะแนนที่ครูยืนยันแล้ว)';
  }

  static Color _colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x7C3AED;
    return Color(0xFF000000 | value);
  }

  List<String> get _resourceLabels {
    switch (selectedPeriod) {
      case 0:
        final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        const dayNames = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
        return List.generate(7, (i) {
          final d = monday.add(Duration(days: i));
          return '${dayNames[i]} ${d.day}';
        });
      case 1:
        final mShort = _thaiShortMonths[_selectedDate.month - 1];
        return [
          'W1 (1-7 $mShort)',
          'W2 (8-14 $mShort)',
          'W3 (15-21 $mShort)',
          'W4 (22+ $mShort)',
        ];
      default:
        final list = <String>[];
        for (int i = 5; i >= 0; i--) {
          int m = _selectedDate.month - i;
          while (m < 1) {
            m += 12;
          }
          list.add(_thaiShortMonths[m - 1]);
        }
        return list;
    }
  }

  List<double> get _electricValues {
    final seed = (_selectedDate.year * 37 + _selectedDate.month * 17 + _selectedDate.day * 13) % 40;
    switch (selectedPeriod) {
      case 0:
        return [
          350.0 + seed,
          380.0 + (seed * 1.3) % 35,
          368.0 + (seed * 0.8) % 25,
          401.0 + (seed * 1.5) % 45,
          389.0 + (seed * 0.9) % 30,
          412.0 + (seed * 1.1) % 40,
          427.0 + (seed * 0.7) % 35,
        ];
      case 1:
        return [
          2400.0 + seed * 20,
          2550.0 + (seed * 25) % 300,
          2620.0 + (seed * 18) % 250,
          2710.0 + (seed * 22) % 350,
        ];
      default:
        return [
          10600.0 + seed * 50,
          10950.0 + (seed * 60) % 800,
          11120.0 + (seed * 45) % 700,
          10840.0 + (seed * 55) % 650,
          11410.0 + (seed * 70) % 900,
          11890.0 + (seed * 65) % 850,
        ];
    }
  }

  List<double> get _waterValues {
    final seed = (_selectedDate.year * 19 + _selectedDate.month * 11 + _selectedDate.day * 7) % 20;
    switch (selectedPeriod) {
      case 0:
        return [
          12.2 + (seed % 4) * 0.5,
          13.1 + ((seed + 1) % 4) * 0.6,
          14.4 + ((seed + 2) % 4) * 0.4,
          13.6 + ((seed + 3) % 4) * 0.5,
          15.0 + (seed % 3) * 0.7,
          16.1 + ((seed + 1) % 3) * 0.6,
          16.8 + ((seed + 2) % 3) * 0.5,
        ];
      case 1:
        return [
          90.0 + seed * 2,
          95.0 + (seed * 2.5) % 15,
          101.0 + (seed * 1.8) % 18,
          108.0 + (seed * 2.1) % 20,
        ];
      default:
        return [
          392.0 + seed * 4,
          406.0 + (seed * 5) % 30,
          414.0 + (seed * 4.5) % 25,
          421.0 + (seed * 5.2) % 28,
          433.0 + (seed * 6) % 35,
          446.0 + (seed * 5.5) % 32,
        ];
    }
  }

  @override
  void dispose() {
    _importantScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1020;
        return SingleChildScrollView(
          child: Column(
            children: [
              _hero(constraints.maxWidth),
              const SizedBox(height: 16),
              _periodSelector(),
              const SizedBox(height: 16),
              _summaryCards(constraints.maxWidth),
              const SizedBox(height: 16),
              if (!compact)
                SizedBox(
                  height: 420,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _learningOverview(isCompact: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _teacherOverviewCard(isCompact: false),
                      ),
                    ],
                  ),
                )
              else ...[
                _learningOverview(isCompact: true),
                const SizedBox(height: 16),
                _teacherOverviewCard(isCompact: true),
              ],
              const SizedBox(height: 16),
              if (!compact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _utilityCard(isCompact: false),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _resourceSixTileCard(),
                    ),
                  ],
                )
              else ...[
                _utilityCard(isCompact: true),
                const SizedBox(height: 16),
                _resourceSixTileCard(),
              ],
              const SizedBox(height: 16),
              _importantCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(double width) {
    final isPhone = width < 700;
    final isSmallPhone = width < 520;
    final titleFont = isPhone ? 22.0 : 28.0;
    final bodyFont = isPhone ? 11.0 : 12.0;
    final dateFont = isSmallPhone ? 12.0 : (isPhone ? 13.5 : 15.0);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.heroTag,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'ศูนย์ควบคุมสำหรับผู้อำนวยการโรงเรียน',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'ภาพรวมโรงเรียน\nAIoT Smart Lab',
          style: TextStyle(
            fontSize: titleFont,
            fontWeight: FontWeight.w800,
            height: 1.12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ติดตามการเรียน ครู เหตุฉุกเฉิน พลังงาน น้ำ และสภาพแวดล้อมในหน้าเดียว',
          style: TextStyle(fontSize: bodyFont, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallPhone ? 10 : 13,
            vertical: isSmallPhone ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: AppPalette.tint(Colors.white, 0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppPalette.tint(Colors.white, 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: isSmallPhone ? 15 : (isPhone ? 16 : 18),
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _todayDateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dateFont,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroTag(Icons.cloud_done_rounded, 'ระบบออนไลน์'),
            _HeroTag(Icons.schedule_rounded, 'อัปเดตล่าสุด 2 นาที'),
            _HeroTag(Icons.verified_rounded, 'สถานะปกติ'),
          ],
        ),
      ],
    );

    final mascotOuterSize = isSmallPhone ? 90.0 : (isPhone ? 150.0 : 240.0);

    final mascot = SizedBox(
      width: mascotOuterSize,
      height: mascotOuterSize,
      child: Container(
        padding: EdgeInsets.all(isSmallPhone ? 4 : (isPhone ? 6 : 8)),
        decoration: BoxDecoration(
          color: AppPalette.tint(Colors.white, 0.12),
          borderRadius: BorderRadius.circular(isSmallPhone ? 20 : (isPhone ? 30 : 38)),
        ),
        child: Image.asset(
          'assets/images/robot_logo.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.smart_toy_rounded,
                size: isSmallPhone ? 42 : 84,
                color: AppPalette.primaryPink,
              ),
            );
          },
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.heroPink, AppPalette.heroPinkDark],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: isSmallPhone
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: text),
                const SizedBox(width: 8),
                mascot,
              ],
            )
          : (isPhone
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: text,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: mascot,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 20),
                    mascot,
                  ],
                )),
    );
  }

  Widget _periodSelector() {
    const labels = ['รายวัน', 'สัปดาห์', 'เดือน'];
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ภาพรวมข้อมูล',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _scopeLabelFormatted,
                style: const TextStyle(fontSize: 11, color: AppPalette.textMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(labels.length, (index) {
              final active = selectedPeriod == index;
              return InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => setState(() {
                  selectedPeriod = index;
                  selectedUtilityPeriod = index;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? const Color(0xFF1E293B) : AppPalette.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _summaryCards(double width) {
    final numberFormat = NumberFormat.decimalPattern('th');
    final studentCount = _userCounts['student'] ?? 0;
    final teacherCount = _userCounts['teacher'] ?? 0;
    final totalIncidents = _incidentSummary.fold<int>(
      0,
      (sum, item) => sum + item.totalCount,
    );
    final incidentCount = '$totalIncidents';
    final deviceCount = _devices.length;

    final items = <_SummaryData>[
      _SummaryData(
        title: 'นักเรียนทั้งหมด',
        value: numberFormat.format(studentCount),
        unit: 'คน',
        sub: '',
        badge: '',
        badgeBg: const Color(0xFFDCFCE7),
        badgeTextColor: const Color(0xFF047857),
        icon: Icons.people_outline_rounded,
        headerBg: const Color(0xFFE6F7ED),
        headerColor: const Color(0xFF047857),
      ),
      _SummaryData(
        title: 'ครูและบุคลากร',
        value: numberFormat.format(teacherCount),
        unit: 'คน',
        sub: '',
        badge: '',
        badgeBg: const Color(0xFFDCFCE7),
        badgeTextColor: const Color(0xFF047857),
        icon: Icons.badge_outlined,
        headerBg: const Color(0xFFFEF3C7),
        headerColor: const Color(0xFF92400E),
      ),
      _SummaryData(
        title: 'ความปลอดภัย & ฉุกเฉิน',
        value: incidentCount,
        unit: 'เหตุการณ์',
        sub: totalIncidents > 0 ? 'พบรายงานที่ต้องดำเนินการ' : 'ไม่พบเหตุผิดปกติใน 24 ชม.',
        badge: totalIncidents > 0 ? 'เฝ้าระวัง' : 'ปลอดภัย',
        badgeBg: totalIncidents > 0 ? const Color(0xFFFFE4E6) : const Color(0xFFDCFCE7),
        badgeTextColor: totalIncidents > 0 ? const Color(0xFFE11D48) : const Color(0xFF047857),
        badgeIcon: totalIncidents > 0 ? Icons.arrow_downward_rounded : Icons.check_rounded,
        icon: Icons.shield_outlined,
        headerBg: const Color(0xFFFFE4E6),
        headerColor: const Color(0xFFBE123C),
      ),
      _SummaryData(
        title: 'อุปกรณ์ IoT ในห้องเรียน',
        value: numberFormat.format(deviceCount),
        unit: 'จุด',
        sub: '',
        badge: '',
        badgeBg: const Color(0xFFDCFCE7),
        badgeTextColor: const Color(0xFF047857),
        icon: Icons.sensors_rounded,
        headerBg: const Color(0xFFF3E8FF),
        headerColor: const Color(0xFF6D28D9),
      ),
    ];

    final int columns = width < 520 ? 1 : (width < 900 ? 2 : 4);
    final double cardHeight = width < 650 ? 142 : 138;

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: width < 650 ? 10 : 14,
        mainAxisSpacing: width < 650 ? 10 : 14,
        mainAxisExtent: cardHeight,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            mouseCursor: SystemMouseCursors.click,
            hoverColor: item.headerBg.withValues(alpha: 0.25),
            splashColor: item.headerColor.withValues(alpha: 0.12),
            highlightColor: item.headerBg.withValues(alpha: 0.3),
            onTap: () {
              if (index == 0) {
                _showStudentAttendanceDialog();
              } else if (index == 1) {
                _showTeacherDetailDialog('การมาปฏิบัติหน้าที่ของครู');
              } else if (index == 2) {
                _showSafetyDialog();
              } else {
                _showTeacherDetailDialog('ความพร้อมห้องเรียนและ IoT');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Full-width colored pill header banner (Image 2 style with click affordance)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: item.headerBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 15, color: item.headerColor),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.headerColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ดูข้อมูล',
                                style: TextStyle(
                                  fontSize: 9.2,
                                  fontWeight: FontWeight.w700,
                                  color: item.headerColor,
                                ),
                              ),
                              const SizedBox(width: 2.5),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 8.5,
                                color: item.headerColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Large Bold Metric Value
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.unit,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (item.sub.isNotEmpty || item.badge.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    // Bottom row: Subtitle on left + Trend pill badge on right
                    Row(
                      children: [
                        if (item.sub.isNotEmpty)
                          Expanded(
                            child: Text(
                              item.sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.8,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (item.badge.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: item.badgeBg,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.badgeIcon != null) ...[
                                  Icon(
                                    item.badgeIcon,
                                    size: 10.5,
                                    color: item.badgeTextColor,
                                  ),
                                  const SizedBox(width: 2.5),
                                ],
                                Text(
                                  item.badge,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: item.badgeTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _learningOverview({bool isCompact = false}) {
    final rows = Column(
      mainAxisAlignment: isCompact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
      children: programOverview.map((item) => _programFullRow(item, isCompact: isCompact)).toList(),
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCompact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ภาพรวมตามสายการเรียน',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'จำนวนนักเรียน/ห้อง และผลการเรียนจริงจากคะแนนที่ครูยืนยันแล้ว',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onNavigate(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'ดูรายงาน',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Real learning-track rows, or a setup prompt when none exist yet
          if (_trackOverview.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppPalette.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ยังไม่ได้ตั้งค่าสายการเรียน — ผู้ดูแลโรงเรียนสามารถตั้งค่าได้ในเมนูตั้งค่า',
                      style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
                    ),
                  ),
                ],
              ),
            )
          else if (isCompact)
            rows
          else
            Expanded(child: rows),

          const SizedBox(height: 8),
          // Bottom Executive Action Banner (Vibrant Emerald)
          if (_trackOverview.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _trackBannerText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _programFullRow(_ProgramOverviewData item, {bool isCompact = false}) {
    final Color streamThemeColor = item.color;
    final Color streamBgColor = item.color.withValues(alpha: 0.04);
    final Color streamBorderColor = item.color.withValues(alpha: 0.28);
    final Color statusColor = item.color;
    final Color statusBgColor = item.color.withValues(alpha: 0.12);
    final Color statusBorderColor = item.color.withValues(alpha: 0.35);
    const IconData icon = Icons.school_rounded;

    final rowContent = Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: streamBgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStreamDetailDialog(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: streamBorderColor,
                width: 0.9,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isCompact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
              children: [
                // Row 1: Header (Icon, Title, Room & Student count, Overall score badge)
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: streamThemeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 14.5, color: streamThemeColor),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Text(
                          '${item.roomCount} ห้อง • ${item.studentCount} คน',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (item.avgGradePercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: statusBorderColor, width: 0.8),
                        ),
                        child: Text(
                          '${item.avgGradePercent!.toStringAsFixed(0)}% ผลการเรียน',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: streamThemeColor,
                    ),
                  ],
                ),
                if (isCompact) const SizedBox(height: 6),

                // Row 2: real avg-grade bar (when confirmed grades exist)
                if (item.avgGradePercent != null)
                  _streamMicroBar(
                    label: 'ผลการเรียนเฉลี่ย (จากคะแนนที่ครูยืนยันแล้ว)',
                    value: item.avgGradePercent!.round(),
                    color: item.color,
                    trackColor: item.color.withValues(alpha: 0.12),
                  ),
                if (isCompact) const SizedBox(height: 6),

                // Row 3: honest note — no behavior/environment source exists yet
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 12.5,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'พฤติกรรมและสิ่งแวดล้อม: ยังไม่มีข้อมูลในระบบ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'แตะดูข้อมูล >',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return isCompact ? rowContent : Expanded(child: rowContent);
  }

  Widget _streamMicroBar({
    required String label,
    required int value,
    required Color color,
    required Color trackColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '$value%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 4.5,
            width: double.infinity,
            color: trackColor,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (value / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _utilityCard({bool isCompact = false}) {
    final electricitySeries = <_ChartSeries>[
      _ChartSeries(
        name: 'ไฟฟ้า',
        color: AppPalette.chartPink,
        values: _electricValues,
        latestValue:
            '${_electricValues.last.toStringAsFixed(0)} kWh',
      ),
    ];

    final waterSeries = <_ChartSeries>[
      _ChartSeries(
        name: 'น้ำ',
        color: AppPalette.learningBlue,
        values: _waterValues,
        latestValue:
            '${_waterValues.last.toStringAsFixed(selectedUtilityPeriod == 0 ? 1 : 0)} m³',
      ),
    ];

    return Container(
      width: double.infinity,
      height: isCompact ? null : 460,
      padding: const EdgeInsets.all(14),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 560;
              final titleRow = Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(
                        AppPalette.chartPink,
                        0.12,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.electric_bolt_rounded,
                      size: 18,
                      color: AppPalette.chartPink,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'แนวโน้มการใช้ทรัพยากร',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _demoBadge(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ติดตามการใช้ไฟฟ้าและน้ำ แยกตามรายวัน รายสัปดาห์ และรายเดือน',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 10),
                    _miniPeriodSelector(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 8),
                  _miniPeriodSelector(),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          if (isCompact) ...[
            _compactChartCard(
              title: 'ไฟฟ้า',
              subtitle: 'แนวโน้มการใช้ไฟฟ้า',
              icon: Icons.bolt_rounded,
              color: AppPalette.chartPink,
              series: electricitySeries,
              labels: _resourceLabels,
              isCompact: true,
            ),
            const SizedBox(height: 10),
            _compactChartCard(
              title: 'น้ำ',
              subtitle: 'แนวโน้มการใช้น้ำ',
              icon: Icons.water_drop_rounded,
              color: AppPalette.learningBlue,
              series: waterSeries,
              labels: _resourceLabels,
              isCompact: true,
            ),
          ] else
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _compactChartCard(
                      title: 'ไฟฟ้า',
                      subtitle: 'แนวโน้มการใช้ไฟฟ้า',
                      icon: Icons.bolt_rounded,
                      color: AppPalette.chartPink,
                      series: electricitySeries,
                      labels: _resourceLabels,
                      isCompact: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _compactChartCard(
                      title: 'น้ำ',
                      subtitle: 'แนวโน้มการใช้น้ำ',
                      icon: Icons.water_drop_rounded,
                      color: AppPalette.learningBlue,
                      series: waterSeries,
                      labels: _resourceLabels,
                      isCompact: false,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resourceSixTileCard() {
    // aqi/gas_mq2_percent used to be fetched once in initState and never
    // again — a real bug: the value froze at whatever was newest when the
    // page first loaded, while the freshness caption (computed live from
    // that frozen row's own timestamp) kept correctly counting up, making
    // it look like the sensor went offline days ago even when fresh rows
    // were arriving the whole time. Poll them the same way as the
    // pm25/temp/humidity/lux StreamBuilder below instead of a one-shot.
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.rawReadingsStreamOverride ?? RealtimeService.rawReadingsStream(),
      builder: (context, rawSnapshot) {
        final rawRows = rawSnapshot.data ?? const <Map<String, dynamic>>[];
        final aqiReading = _latestValueOf(rawRows, 'aqi');
        final gasReading = _latestValueOf(rawRows, 'gas_mq2_percent');

        return StreamBuilder<SensorModel?>(
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
        final bool hasTemp = sensor != null &&
            sensor.metricUpdatedAt.containsKey('temperature');
        final bool hasLux =
            sensor != null && sensor.metricUpdatedAt.containsKey('light_lux');
        final bool hasHumidity = sensor != null &&
            sensor.metricUpdatedAt.containsKey('humidity');
        final bool hasCo2 =
            sensor != null && sensor.metricUpdatedAt.containsKey('co2');
        final bool hasTvoc =
            sensor != null && sensor.metricUpdatedAt.containsKey('tvoc');

        final pm25Val = hasPm25
            ? '${sensor.pm25.toStringAsFixed(0)} µg/m³ · ${_levelLabel(sensor.pm25Level)}'
            : 'ไม่มีข้อมูล';
        final tempVal = hasTemp
            ? '${sensor.temperature.toStringAsFixed(1)} °C · ${_levelLabel(sensor.tempLevel)}'
            : 'ไม่มีข้อมูล';
        final luxVal = hasLux
            ? '${sensor.lux.toStringAsFixed(0)} lux · ${_levelLabel(sensor.luxLevel)}'
            : 'ไม่มีข้อมูล';
        final humidityVal = hasHumidity
            ? '${sensor.humidity.toStringAsFixed(0)}%RH · ${_levelLabel(sensor.humidityLevel)}'
            : 'ไม่มีข้อมูล';
        final aqiVal = aqiReading != null
            ? '${aqiReading.value.toStringAsFixed(0)} · ${_aqiUbaLabel(aqiReading.value)}'
            : 'ไม่มีข้อมูล';
        final gasVal = gasReading != null
            ? '${gasReading.value.toStringAsFixed(0)}% (ดิบ)'
            : 'ไม่มีข้อมูล';
        final co2Val = hasCo2
            ? '${sensor.co2.toStringAsFixed(0)} ppm · ${_levelLabel(sensor.co2Level)}'
            : 'ไม่มีข้อมูล';
        final tvocVal = hasTvoc
            ? '${sensor.tvoc.toStringAsFixed(0)} ppb · ${_levelLabel(sensor.tvocLevel)}'
            : 'ไม่มีข้อมูล';

        // สีของแต่ละ tile ตามระดับความรุนแรงจริง (ปรับสีเมื่อค่าเกินเกณฑ์)
        // ใช้เกณฑ์ good/moderate/danger ที่มีอยู่แล้วบน SensorModel — ไม่มี
        // ข้อมูลเลยหรือยังไม่ผ่าน calibrate (MQ-2) ใช้สีตกแต่งเดิมคงที่
        final pm25Color = hasPm25 ? _levelColor(sensor.pm25Level) : AppPalette.chartCream;
        final luxColor = hasLux ? _levelColor(sensor.luxLevel) : AppPalette.behaviorYellow;
        final tempColor = hasTemp ? _levelColor(sensor.tempLevel) : AppPalette.learningBlue;
        final humidityColor = hasHumidity ? _levelColor(sensor.humidityLevel) : AppPalette.environmentGreen;
        final aqiColor = aqiReading != null ? _levelColor(_aqiUbaSensorLevel(aqiReading.value)) : AppPalette.warning;
        final co2Color = hasCo2 ? _levelColor(sensor.co2Level) : AppPalette.chartBlue;
        final tvocColor = hasTvoc ? _levelColor(sensor.tvocLevel) : AppPalette.chartPink2;

        final headerFreshness = sensor?.overallFreshnessOf(const [
          'pm25',
          'temperature',
          'humidity',
          'light_lux',
        ]) ?? SensorFreshness.noData;

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
                                    color: headerFreshness.color.withValues(alpha: 0.45),
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
                              icon: Icons.water_drop_rounded,
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
                              icon: Icons.eco_rounded,
                              color: aqiColor,
                              level: aqiReading != null
                                  ? _aqiUbaSensorLevel(aqiReading.value)
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

  Widget _resourceTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    SensorFreshness freshness = SensorFreshness.noData,
    String? timeLabel,
    SensorLevel? level,
  }) {
    // เซนเซอร์ตัวนี้เอง "ออนไลน์ (สด/ล่าช้าเล็กน้อย)" หรือ "ไม่ออนไลน์"
    // แยกทีละ tile — ค่าแต่ละตัวอาจมาจากอุปกรณ์/เวลาอัปเดตคนละตัวกัน
    // (เดียวกับที่เพิ่มในหน้านักเรียน aiot_weather_sensors_card.dart)
    final bool isOnline =
        freshness == SensorFreshness.live || freshness == SensorFreshness.delayed;

    // สีเข้มขึ้นทั้งหมด (ตามที่ผู้ใช้ขอ — ค่าพวกนี้สำคัญ ต้องเด่นชัด) และ
    // เข้มขึ้นไปอีกเป็นพิเศษเมื่อ "เกินเกณฑ์" เพื่อให้สายตาสะดุดจุดที่ต้อง
    // ระวังก่อนจุดที่ปกติ
    final bool isDanger = level == SensorLevel.danger;
    final double bgAlpha = isDanger ? 0.24 : 0.15;
    final double borderAlpha = isDanger ? 0.65 : 0.4;
    final double borderWidth = isDanger ? 2.0 : 1.3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, bgAlpha),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppPalette.tint(color, borderAlpha),
          width: borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 15,
              color: color,
            ),
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
                    fontSize: 9,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDanger ? color : AppPalette.textDark,
                  ),
                ),
                if (timeLabel != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: freshness.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          isOnline ? 'ออนไลน์ • $timeLabel' : 'ไม่ออนไลน์ • $timeLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.5,
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

  Widget _compactChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<_ChartSeries> series,
    required List<String> labels,
    bool isCompact = false,
  }) {
    final values = series.expand((item) => item.values).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b) * 1.12;

    final chartBody = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 32,
          child: _ScaledYAxisLabels(maxValue: maxValue),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(
                    '${title}_$selectedUtilityPeriod',
                  ),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeInOutQuart,
                  builder: (context, progress, _) {
                    return CustomPaint(
                      painter: _AnimatedLineChartPainter(
                        series: series,
                        maxValue: maxValue,
                        progress: progress,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(labels.length, (index) {
                  return Expanded(
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppPalette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPalette.tint(color, 0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppPalette.tint(color, 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _resourceLegendChip(
                color: series.first.color,
                text:
                    '${series.first.name} ${series.first.latestValue}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isCompact)
            SizedBox(
              height: 140,
              child: chartBody,
            )
          else
            Expanded(
              child: chartBody,
            ),
        ],
      ),
    );
  }

  Widget _miniPeriodSelector() {
    const labels = ['รายวัน', 'สัปดาห์', 'เดือน'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.primaryPinkSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final active = selectedUtilityPeriod == index;
          return InkWell(
            onTap: () => setState(() => selectedUtilityPeriod = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppPalette.textDark : AppPalette.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _resourceLegendChip({
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherOverviewCard({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCompact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: [
          // Header: Title + Subtitle + View Report Button (matching screenshot)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'ภาพรวมครูและการสอน',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _demoBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ครูและบุคลากรทั้งหมด ${_userCounts['teacher'] ?? 0} คน • สัดส่วนการสอนด้านล่างเป็นตัวอย่าง',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onNavigate(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'ดูรายงาน',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Central Organic Clustered Bubbles (48%, 32%, 13%, 7%)
          _teacherBubbleCluster(),

          const SizedBox(height: 10),
          // Top Dotted Divider
          const _DottedLine(color: Color(0xFFE5E5EA), dotRadius: 1.2, spacing: 5.5),
          const SizedBox(height: 8),

          // 2x2 Grid of Category Legends (matching screenshot)
          Row(
            children: [
              Expanded(
                child: _bubbleLegendItem(
                  color: const Color(0xFF7C3AED),
                  title: 'สอนในตารางปกติ',
                  value: '72 คาบ (ครู 38 คน)',
                  onTap: () => _showTeacherDetailDialog('การสอนตามตารางวิชาการ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bubbleLegendItem(
                  color: const Color(0xFF059669),
                  title: 'กิจกรรม & แล็บ',
                  value: '48 คาบ (14 ห้อง IoT)',
                  onTap: () => _showTeacherDetailDialog('กิจกรรมและห้องปฏิบัติการ IoT'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          // Middle Dotted Divider
          const _DottedLine(color: Color(0xFFF1F5F9), dotRadius: 1.0, spacing: 5.5),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _bubbleLegendItem(
                  color: const Color(0xFFE11D48),
                  title: 'จัดครูสอนแทน',
                  value: '20 คาบ (ครบ 100%)',
                  onTap: () => _showTeacherDetailDialog('การจัดครูสอนแทน'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bubbleLegendItem(
                  color: const Color(0xFFD97706),
                  title: 'เตรียมสอน/ประชุม',
                  value: '11 คาบ (ครู 6 คน)',
                  onTap: () => _showTeacherDetailDialog('เตรียมการสอนและภาระงาน'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teacherBubbleCluster() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 300,
          height: 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bubble 1: Purple 48% (Largest)
              Positioned(
                left: 10,
                top: 14,
                child: _bubbleItem(
                  size: 144,
                  bgColor: const Color(0xFFEDE9FE),
                  textColor: const Color(0xFF5B21B6),
                  percent: '48%',
                  fontSize: 32,
                  onTap: () => _showTeacherDetailDialog('การสอนตามตารางวิชาการ'),
                ),
              ),

              // Bubble 2: Mint Green 32% (Medium)
              Positioned(
                left: 148,
                top: 8,
                child: _bubbleItem(
                  size: 108,
                  bgColor: const Color(0xFFDCFCE7),
                  textColor: const Color(0xFF059669),
                  percent: '32%',
                  fontSize: 25,
                  onTap: () => _showTeacherDetailDialog('กิจกรรมและห้องปฏิบัติการ IoT'),
                ),
              ),

              // Bubble 3: Coral Pink 13% (Small-Medium)
              Positioned(
                left: 144,
                top: 96,
                child: _bubbleItem(
                  size: 82,
                  bgColor: const Color(0xFFFFE4E6),
                  textColor: const Color(0xFFE11D48),
                  percent: '13%',
                  fontSize: 19,
                  onTap: () => _showTeacherDetailDialog('การจัดครูสอนแทน'),
                ),
              ),

              // Bubble 4: Amber 7% (Smallest)
              Positioned(
                left: 236,
                top: 92,
                child: _bubbleItem(
                  size: 48,
                  bgColor: const Color(0xFFFEF3C7),
                  textColor: const Color(0xFFD97706),
                  percent: '7%',
                  fontSize: 13,
                  onTap: () => _showTeacherDetailDialog('เตรียมการสอนและภาระงาน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubbleItem({
    required double size,
    required Color bgColor,
    required Color textColor,
    required String percent,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              percent,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubbleLegendItem({
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _importantCard() {
    final allItems = <_ImportantItemData>[
      const _ImportantItemData(
        id: 'brawl',
        title: 'ตรวจพบเหตุทะเลาะวิวาท',
        subtitle: '10:24 น. • อาคาร 2 ชั้น 3',
        detail:
            'กล้อง AI ตรวจพบพฤติกรรมเสี่ยงต่อการทะเลาะวิวาทบริเวณทางเดินหน้าห้อง ม.5/2 ระบบส่งการแจ้งเตือนไปยังครูเวรและฝ่ายปกครองแล้ว',
        status: 'ต้องดำเนินการด่วน',
        categoryTag: 'ความปลอดภัย',
        color: Color(0xFFE11D48),
        icon: Icons.shield_rounded,
        category: 'urgent',
        actionLabel: 'ดูกล้อง CCTV',
        actionIcon: Icons.videocam_rounded,
      ),
      const _ImportantItemData(
        id: 'water',
        title: 'การใช้น้ำสูงผิดปกติที่อาคาร 2',
        subtitle: '10:30 น. • อาคาร 2 ชั้น 1–3 (+28%)',
        detail:
            'ปริมาณการใช้น้ำสูงกว่าค่าเฉลี่ย 28% เพิ่มขึ้นต่อเนื่องตั้งแต่ช่วงเช้า แนะนำตรวจสอบห้องน้ำ จุดล้างมือ และท่อบริเวณชั้น 2',
        status: 'รอการตรวจสอบ',
        categoryTag: 'สาธารณูปโภค',
        color: Color(0xFFD97706),
        icon: Icons.water_drop_rounded,
        category: 'warning',
        actionLabel: 'แจ้งช่างอาคาร',
        actionIcon: Icons.build_rounded,
      ),
      const _ImportantItemData(
        id: 'absence',
        title: 'นักเรียน ม.5/2 ขาดเรียนสูงกว่าปกติ',
        subtitle: 'วันนี้ • ม.5/2 ขาดเรียน 8 คน',
        detail:
            'จำนวนผู้ขาดเรียนสูงกว่าค่าเฉลี่ยประจำห้อง ควรให้ครูประจำชั้นตรวจสอบสาเหตุ แยกกรณีลาป่วย ลากิจ หรือขาดเรียนโดยไม่แจ้ง',
        status: 'กำลังติดตาม',
        categoryTag: 'กิจการนักเรียน',
        color: Color(0xFF7C3AED),
        icon: Icons.groups_rounded,
        category: 'warning',
        actionLabel: 'โทรหาครู',
        actionIcon: Icons.phone_rounded,
      ),
      const _ImportantItemData(
        id: 'electricity',
        title: 'การใช้ไฟฟ้าอาคาร 3 สูงกว่าค่าเฉลี่ย',
        subtitle: 'ช่วง 08:00–12:00 น. • สูงขึ้น +18%',
        detail:
            'การใช้ไฟเพิ่มขึ้นชัดเจนในช่วงก่อนเที่ยง โดยเฉพาะพื้นที่ห้องแล็บและชั้น 3 ควรตรวจเครื่องปรับอากาศและอุปกรณ์ไฟฟ้า',
        status: 'เฝ้าระวังการใช้',
        categoryTag: 'พลังงาน',
        color: Color(0xFFD97706),
        icon: Icons.bolt_rounded,
        category: 'warning',
        actionLabel: 'ตรวจแอร์ IoT',
        actionIcon: Icons.ac_unit_rounded,
      ),
      const _ImportantItemData(
        id: 'air',
        title: 'คุณภาพอากาศในห้องเรียนส่วนใหญ่อยู่ในเกณฑ์ปกติ',
        subtitle: 'PM2.5 เฉลี่ย 18 µg/m³ • CO₂ เฉลี่ย 690 ppm',
        detail:
            'ค่าฝุ่นและคาร์บอนไดออกไซด์ในภาพรวมอยู่ในเกณฑ์เหมาะสม มีระบบระบายอากาศอัจฉริยะทำงานต่อเนื่อง',
        status: 'ปกติ เรียบร้อย',
        categoryTag: 'สิ่งแวดล้อม',
        color: Color(0xFF059669),
        icon: Icons.air_rounded,
        category: 'info',
        actionLabel: 'ดูเซนเซอร์',
        actionIcon: Icons.sensors_rounded,
      ),
      const _ImportantItemData(
        id: 'meeting',
        title: 'มีนัดประชุมฝ่ายบริหารวันนี้',
        subtitle: '15:00 น. • ห้องประชุม 1',
        detail:
            'หัวข้อหลัก: ติดตามข้อมูลการมาเรียน การใช้ทรัพยากร และเหตุการณ์ประจำสัปดาห์ พร้อมเอกสารสรุปในระบบ',
        status: 'ตามกำหนดการ',
        categoryTag: 'การบริหาร',
        color: Color(0xFF0284C7),
        icon: Icons.calendar_month_rounded,
        category: 'info',
        actionLabel: 'เปิดดูวาระ',
        actionIcon: Icons.description_rounded,
      ),
    ];

    final filteredItems = _importantFilterIndex == 1
        ? allItems.where((i) => i.category == 'urgent' || i.category == 'warning').toList()
        : _importantFilterIndex == 2
            ? allItems.where((i) => i.category == 'info').toList()
            : allItems;

    final filterTabs = [
      'ทั้งหมด (${allItems.length})',
      'ต้องติดตาม (${allItems.where((i) => i.category == 'urgent' || i.category == 'warning').length})',
      'ข้อมูล & นัดหมาย (${allItems.where((i) => i.category == 'info').length})',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;

          final filterWidget = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(filterTabs.length, (idx) {
                  final active = _importantFilterIndex == idx;
                  return InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () => setState(() => _importantFilterIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        filterTabs[idx],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                          color: active ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );

          final titleWidget = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 18,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'สิ่งที่ควรทราบวันนี้',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _demoBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'ตัวอย่างศูนย์แจ้งเตือนเหตุการณ์และข้อมูลสำคัญ ยังไม่เชื่อมกับระบบตรวจจับจริง',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                titleWidget,
                const SizedBox(height: 12),
                filterWidget,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 10),
                    filterWidget,
                  ],
                ),
              const SizedBox(height: 14),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: filteredItems.length > 5 ? 715 : double.infinity,
                ),
                child: filteredItems.length > 5
                    ? RawScrollbar(
                        controller: _importantScrollController,
                        thumbVisibility: true,
                        thickness: 5,
                        radius: const Radius.circular(8),
                        thumbColor: const Color(0xFFCBD5E1),
                        child: SingleChildScrollView(
                          controller: _importantScrollController,
                          child: Column(
                            children: filteredItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildBriefingCard(item),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    : Column(
                        children: filteredItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildBriefingCard(item),
                          );
                        }).toList(),
                      ),
              ),
              if (filteredItems.length > 5) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.unfold_more_rounded, size: 13, color: Color(0xFF94A3B8)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'แสดง 5 รายการแรก • เลื่อนในกรอบเพื่อดูรายการที่เหลือ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBriefingCard(_ImportantItemData item) {
    final isUrgent = item.category == 'urgent';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: item.color.withValues(alpha: 0.03),
        splashColor: item.color.withValues(alpha: 0.08),
        onTap: () => _showImportantDetailDialog(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent
                  ? item.color.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
              width: isUrgent ? 1.3 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isUrgent
                    ? item.color.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Header: Left Squircle Icon + System/Category + Right Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(item.icon, size: 16, color: item.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categoryTag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        const Text(
                          'ระบบตรวจจับอัตโนมัติ AIoT & ฝ่ายปกครอง',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // High-clarity Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),

              // Notification Detail Message
              Text(
                item.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Notification Action Footer
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: item.color.withValues(alpha: 0.2),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.actionIcon, size: 10.5, color: item.color),
                          const SizedBox(width: 3.5),
                          Text(
                            item.actionLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: item.color,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 7.5,
                            color: item.color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportantDetailDialog(_ImportantItemData item) {
    _showAppleModal(
      icon: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, size: 22, color: item.color),
      ),
      title: item.title,
      subtitle: '${item.categoryTag} • ${item.subtitle}',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: item.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.detail,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.color.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สถานะปัจจุบัน: ${item.status}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.category == 'urgent'
                            ? 'ระบบตรวจพบความเสี่ยงสูง ได้แจ้งเตือนเจ้าหน้าที่รับผิดชอบแล้ว กรุณาติดตามผลทันที'
                            : (item.category == 'warning'
                                ? 'แจ้งเตือนเพื่อเฝ้าระวังและตรวจสอบตามขั้นตอนปฏิบัติงาน'
                                : 'ข้อมูลสรุปเพื่อการวางแผนและติดตามความพร้อมของโรงเรียน'),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: item.color.withValues(alpha: 0.9),
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
      primaryActionText: 'บันทึกรับทราบ',
      onPrimaryAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกรับทราบ "${item.title}" เรียบร้อยแล้ว'),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      secondaryAction: item.category == 'urgent'
          ? GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                widget.onNavigate(7);
              },
              child: const Row(
                children: [
                  Icon(Icons.videocam_rounded, size: 16, color: Color(0xFF007AFF)),
                  SizedBox(width: 4),
                  Text(
                    'เปิดกล้อง CCTV',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _showAppleModal({
    required Widget icon,
    required String title,
    required String subtitle,
    Widget? statusBadge,
    required Widget content,
    Widget? secondaryAction,
    String primaryActionText = 'เสร็จสิ้น',
    VoidCallback? onPrimaryAction,
    Color primaryColor = const Color(0xFF007AFF),
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AppleModal',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (dialogContext, anim, secondaryAnim) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Apple Modal Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                        child: Row(
                          children: [
                            icon,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D1D1F),
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF86868B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (statusBadge != null) ...[
                              statusBadge,
                              const SizedBox(width: 8),
                            ],
                            GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E5EA).withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 17,
                                  color: Color(0xFF48484A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E5EA)),

                      // Content Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: content,
                        ),
                      ),

                      const Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E5EA)),

                      // Apple Bottom Action Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: const Color(0xFFF9F9FB).withValues(alpha: 0.6),
                        child: Row(
                          children: [
                            if (secondaryAction != null)
                              secondaryAction
                            else
                              const Spacer(),
                            if (secondaryAction != null) const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                onPrimaryAction?.call();
                              },
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(19),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  primaryActionText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    }

  void _showStudentAttendanceDialog() {
    _showAppleModal(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFF2D55).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.school_rounded, size: 21, color: Color(0xFFFF2D55)),
      ),
      title: 'การเข้าเรียนของนักเรียน',
      subtitle: 'สรุปการเข้าเรียนของนักเรียนรายวัน',
      statusBadge: _demoBadge(),
      content: Column(
        children: [
          Row(
            children: [
              Expanded(child: _appleMetricCard(label: 'ลงทะเบียนทั้งหมด', value: '1,248 คน', percent: 1.0, color: const Color(0xFF86868B))),
              const SizedBox(width: 8),
              Expanded(child: _appleMetricCard(label: 'มาเรียนวันนี้', value: '1,228 คน', percent: 1228 / 1248, color: const Color(0xFF34C759))),
              const SizedBox(width: 8),
              Expanded(child: _appleMetricCard(label: 'ขาด/ลา', value: '20 คน', percent: 20 / 1248, color: const Color(0xFFFF9500))),
            ],
          ),
          const SizedBox(height: 14),
          _appleInsetSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สรุปการมาเรียนรายระดับชั้น:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1D1D1F)),
                ),
                const SizedBox(height: 8),
                _appleLevelProgressRow('มัธยมศึกษาตอนต้น (ม.1 - ม.3)', 'มาเรียน 612 / 624 คน (98.1%)', 'ลา 8 คน • ขาด 4 คน (ห้อง ม.2/3)'),
                _appleLevelProgressRow('มัธยมศึกษาตอนปลาย (ม.4 - ม.6)', 'มาเรียน 616 / 624 คน (98.7%)', 'ลา 6 คน • ขาด 2 คน (ติดตามครบ)', isLast: true),
              ],
            ),
          ),
        ],
      ),
      secondaryAction: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          widget.onNavigate(2);
        },
        child: const Row(
          children: [
            Text('ดูรายงานพฤติกรรม', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF007AFF))),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF007AFF)),
          ],
        ),
      ),
      primaryActionText: 'เสร็จสิ้น',
    );
  }

  void _showSafetyDialog() {
    final int totalIncidents = _incidentSummary.fold<int>(
      0,
      (sum, item) => sum + item.totalCount,
    );
    final bool isNormal = totalIncidents == 0;

    _showAppleModal(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF34C759).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.health_and_safety_rounded, size: 21, color: Color(0xFF34C759)),
      ),
      title: 'ความปลอดภัย & ฉุกเฉิน',
      subtitle: 'สรุปเหตุการณ์และการแจ้งเตือนความปลอดภัย',
      content: Column(
        children: [
          _appleInsetSection(
            backgroundColor: isNormal
                ? const Color(0xFFF0FDF4).withValues(alpha: 0.9)
                : const Color(0xFFFFF1F2).withValues(alpha: 0.9),
            borderColor: isNormal
                ? const Color(0xFFBBF7D0).withValues(alpha: 0.8)
                : const Color(0xFFFECDD3).withValues(alpha: 0.8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isNormal ? const Color(0xFF34C759) : const Color(0xFFE11D48))
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNormal ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    size: 22,
                    color: isNormal ? const Color(0xFF34C759) : const Color(0xFFE11D48),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNormal ? 'สภาวะปกติ (ไม่มีเหตุฉุกเฉิน)' : 'พบ $totalIncidents เหตุการณ์ที่ต้องดำเนินการ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isNormal ? const Color(0xFF15803D) : const Color(0xFFBE123C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isNormal
                            ? 'ไม่พบรายงานเหตุฉุกเฉินที่ยังไม่ปิดในระบบ'
                            : 'มีรายงานเหตุการณ์ในระบบที่ยังต้องติดตาม',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF1D1D1F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _appleInsetSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'จุดตรวจความปลอดภัยรอบสถานศึกษา:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1D1D1F)),
                      ),
                    ),
                    _demoBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                _appleSafetyItem('ปุ่มแจ้งเหตุฉุกเฉิน (SOS)', '14 จุด', 'พร้อมใช้งาน 100%'),
                _appleSafetyItem('เซนเซอร์ตรวจจับควันและไฟ (Smoke)', '32 จุด', 'สัญญาณปกติ 100%'),
                _appleSafetyItem('กล้องวงจรปิด AI เฝ้าระวังพื้นที่เสี่ยง', '48 ตัว', 'ออนไลน์ครบทุกจุด', isLast: true),
              ],
            ),
          ),
        ],
      ),
      primaryActionText: 'รับทราบ',
    );
  }

  void _showStreamDetailDialog(_ProgramOverviewData item) {
    const IconData icon = Icons.school_rounded;

    _showAppleModal(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 21, color: item.color),
      ),
      title: 'รายละเอียด: ${item.title}',
      subtitle: '${item.roomCount} ห้องเรียน • รวม ${item.studentCount} คน',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _appleMetricCard(
                  label: 'นักเรียน',
                  value: '${item.studentCount} คน',
                  percent: 1.0,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _appleMetricCard(
                  label: 'ห้องเรียน',
                  value: '${item.roomCount} ห้อง',
                  percent: 1.0,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _appleMetricCard(
                  label: 'ผลการเรียน',
                  value: item.avgGradePercent != null
                      ? '${item.avgGradePercent!.toStringAsFixed(0)}%'
                      : 'ไม่มีข้อมูล',
                  percent: (item.avgGradePercent ?? 0) / 100,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _appleInsetSection(
            backgroundColor: const Color(0xFFF2F2F7).withValues(alpha: 0.8),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF86868B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'พฤติกรรมและสิ่งแวดล้อมของสายการเรียนนี้ยังไม่มีข้อมูลในระบบ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      primaryActionText: 'เสร็จสิ้น',
    );
  }

  void _showTeacherDetailDialog(String title) {
    final isAttendance = title.contains('ปฏิบัติหน้าที่') || title.contains('สอนแทน');
    final isCurriculum = title.contains('ตาราง') || title.contains('วิชาการ') || title.contains('เตรียมสอน');
    final iconColor = isAttendance
        ? const Color(0xFFFF9500)
        : isCurriculum
            ? const Color(0xFF007AFF)
            : const Color(0xFF34C759);

    final IconData icon = isAttendance
        ? Icons.badge_rounded
        : isCurriculum
            ? Icons.menu_book_rounded
            : Icons.sensors_rounded;

    final totalRooms = _devicesByRoom.length;

    _showAppleModal(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 21, color: iconColor),
      ),
      title: title,
      subtitle: isAttendance
          ? 'สรุปการมาปฏิบัติงานและการจัดครูสอนแทนประจำวัน'
          : isCurriculum
              ? 'สรุปการจัดการเรียนรู้และความคืบหน้าตามแผนการสอน'
              : 'สรุปการตรวจวัดสภาพแวดล้อมและเซนเซอร์ IoT $totalRooms ห้อง',
      statusBadge: (isAttendance || isCurriculum) ? _demoBadge() : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAttendance) ...[
            Row(
              children: [
                Expanded(child: _appleMetricCard(label: 'ครูทั้งหมด', value: '61 คน', percent: 1.0, color: const Color(0xFF86868B))),
                const SizedBox(width: 8),
                Expanded(child: _appleMetricCard(label: 'มาปฏิบัติงาน', value: '58 คน', percent: 58 / 61, color: const Color(0xFF34C759))),
                const SizedBox(width: 8),
                Expanded(child: _appleMetricCard(label: 'สอนแทนครบ', value: '100%', percent: 1.0, color: const Color(0xFF007AFF))),
              ],
            ),
            const SizedBox(height: 14),
            _appleInsetSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'การจัดครูสอนแทนวันนี้ (3 คาบ):',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1D1D1F)),
                  ),
                  const SizedBox(height: 8),
                  _appleSubstituteRow('ครูสมศักดิ์ (คณิต ม.4)', 'ลาป่วย', 'ครูพิมพ์ใจ สอนแทน คาบ 2-3 (ห้อง 402)'),
                  _appleSubstituteRow('ครูอภิญญา (อังกฤษ ม.2)', 'ลากิจ', 'ครูจิราพร สอนแทน คาบ 4 (ห้อง 204)'),
                  _appleSubstituteRow('ครูธีรพงษ์ (ฟิสิกส์ ม.5)', 'ลาป่วย', 'ครูเอกชัย สอนแทน คาบ 5 (ห้อง 501)', isLast: true),
                ],
              ),
            ),
          ] else if (isCurriculum) ...[
            Row(
              children: [
                Expanded(child: _appleMetricCard(label: 'คาบสอนตามตาราง', value: '151 คาบ', percent: 1.0, color: const Color(0xFF86868B))),
                const SizedBox(width: 8),
                Expanded(child: _appleMetricCard(label: 'สำเร็จตามแผน', value: '142 คาบ', percent: 142 / 151, color: const Color(0xFF007AFF))),
                const SizedBox(width: 8),
                Expanded(child: _appleMetricCard(label: 'คาบหลุด', value: '0 คาบ', percent: 0.0, color: const Color(0xFF34C759))),
              ],
            ),
            const SizedBox(height: 14),
            _appleInsetSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ความคืบหน้ารายระดับชั้น:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1D1D1F)),
                  ),
                  const SizedBox(height: 8),
                  _appleLevelProgressRow('มัธยมศึกษาตอนต้น (ม.1 - ม.3)', '72 / 72 คาบ (100%)', 'การสอนสมบูรณ์ตามหลักสูตร'),
                  _appleLevelProgressRow('มัธยมศึกษาตอนปลาย (ม.4 - ม.6)', '70 / 79 คาบ (94%)', 'อีก 9 คาบเป็นกิจกรรมพัฒนาผู้เรียน', isLast: true),
                ],
              ),
            ),
          ] else ...[
            Builder(builder: (context) {
              final devicesByRoom = _devicesByRoom;
              final totalRooms = devicesByRoom.length;
              final readyRooms = devicesByRoom.values
                  .where((ds) => ds.every((d) => d.status == 'online'))
                  .length;
              final onlineDevices =
                  _devices.where((d) => d.status == 'online').length;
              final onlinePercent =
                  _devices.isEmpty ? 0.0 : onlineDevices / _devices.length;
              final issueRooms = devicesByRoom.entries
                  .where((e) => e.value.any((d) => d.status != 'online'))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _appleMetricCard(label: 'ห้องเรียนทั้งหมด', value: '$totalRooms ห้อง', percent: 1.0, color: const Color(0xFF86868B))),
                      const SizedBox(width: 8),
                      Expanded(child: _appleMetricCard(label: 'พร้อมสมบูรณ์', value: '$readyRooms ห้อง', percent: totalRooms == 0 ? 0.0 : readyRooms / totalRooms, color: const Color(0xFF34C759))),
                      const SizedBox(width: 8),
                      Expanded(child: _appleMetricCard(label: 'เซนเซอร์ออนไลน์', value: '${(onlinePercent * 100).toStringAsFixed(0)}%', percent: onlinePercent, color: const Color(0xFF007AFF))),
                    ],
                  ),
                  if (issueRooms.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _appleInsetSection(
                      backgroundColor: const Color(0xFFFFF9EE).withValues(alpha: 0.95),
                      borderColor: const Color(0xFFFFE0B2).withValues(alpha: 0.8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFFFF9500)),
                              const SizedBox(width: 6),
                              Text(
                                'ห้องที่มีอุปกรณ์ไม่ออนไลน์ (${issueRooms.length} ห้อง):',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (var i = 0; i < issueRooms.length; i++)
                            _appleIssueRow(
                              issueRooms[i].key,
                              '${issueRooms[i].value.where((d) => d.status != 'online').length}/${issueRooms[i].value.length} อุปกรณ์ไม่ออนไลน์',
                              'ตรวจสอบอุปกรณ์ IoT ในห้องนี้',
                              isLast: i == issueRooms.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ],
      ),
      secondaryAction: isCurriculum
          ? GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                widget.onNavigate(3);
              },
              child: const Row(
                children: [
                  Text(
                    'ดูตารางสอนรวม',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF007AFF)),
                ],
              ),
            )
          : null,
      primaryActionText: isAttendance ? 'อนุมัติบันทึกสอนแทน' : !isCurriculum ? 'เร่งรัดงานช่าง' : 'เสร็จสิ้น',
      primaryColor: isAttendance ? const Color(0xFF34C759) : !isCurriculum ? const Color(0xFFFF9500) : const Color(0xFF007AFF),
      onPrimaryAction: () {
        if (isAttendance) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อนุมัติบันทึกการจัดครูสอนแทนแล้ว'), backgroundColor: Color(0xFF34C759)),
          );
        } else if (!isCurriculum) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ส่งสัญญาณเร่งรัดไปยังฝ่ายอาคารสถานที่แล้ว'), backgroundColor: Color(0xFFFF9500)),
          );
        }
      },
    );
  }

  Widget _appleMetricCard({
    required String label,
    required String value,
    required double percent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 4.5,
              width: double.infinity,
              color: const Color(0xFFE5E5EA),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appleInsetSection({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF2F2F7).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE5E5EA).withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: child,
    );
  }

  Widget _appleSubstituteRow(String teacher, String reason, String subTeacher, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacher, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1D1D1F))),
                    Text(reason, style: const TextStyle(fontSize: 10, color: Color(0xFFFF9500))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF86868B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(subTeacher, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF34C759))),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),
      ],
    );
  }

  Widget _appleLevelProgressRow(String title, String count, String sub, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1D1D1F))),
                    Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF86868B))),
                  ],
                ),
              ),
              Text(count, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF007AFF))),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),
      ],
    );
  }

  Widget _appleIssueRow(String room, String issue, String action, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                    Text(issue, style: const TextStyle(fontSize: 10, color: Color(0xFF1D1D1F))),
                    Text(action, style: const TextStyle(fontSize: 9.5, color: Color(0xFF86868B))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.5, color: Color(0xFFFFE0B2)),
      ],
    );
  }

  Widget _appleSafetyItem(String title, String count, String status, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF34C759)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D1D1F)))),
              Text('$count • $status', style: const TextStyle(fontSize: 10, color: Color(0xFF86868B))),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),
      ],
    );
  }
}

class _AnimatedLineChartPainter extends CustomPainter {
  final List<_ChartSeries> series;
  final double maxValue;
  final double progress;

  const _AnimatedLineChartPainter({
    required this.series,
    required this.maxValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double topPadding = 12;
    const double bottomPadding = 10;
    final double chartHeight = size.height - topPadding - bottomPadding;
    final double chartWidth = size.width;

    final gridPaint = Paint()
      ..color = AppPalette.border
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = topPadding + (chartHeight * i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    if (series.isEmpty || series.first.values.isEmpty) return;

    final visibleWidth = chartWidth * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, visibleWidth, size.height));

    final pointCount = series.first.values.length;
    final dx = pointCount > 1 ? chartWidth / (pointCount - 1) : chartWidth;

    for (final item in series) {
      final points = <Offset>[];
      for (int i = 0; i < item.values.length; i++) {
        final x = dx * i;
        final y = topPadding + chartHeight - ((item.values[i] / maxValue) * chartHeight);
        points.add(Offset(x, y));
      }

      final fillPath = Path();
      fillPath.moveTo(points.first.dx, topPadding + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final current = points[i];
        final midX = (prev.dx + current.dx) / 2;
        final midY = (prev.dy + current.dy) / 2;
        linePath.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
        fillPath.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
      }

      final last = points.last;
      linePath.lineTo(last.dx, last.dy);
      fillPath.lineTo(last.dx, last.dy);
      fillPath.lineTo(last.dx, topPadding + chartHeight);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = item.color.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );

      // soft glow behind line
      canvas.drawPath(
        linePath,
        Paint()
          ..color = item.color.withValues(alpha: 0.20)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..color = item.color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      final pointPaint = Paint()..color = item.color;
      final pointInner = Paint()..color = Colors.white;

      Offset? lastVisiblePoint;
      for (final point in points) {
        if (point.dx <= visibleWidth) {
          lastVisiblePoint = point;
          canvas.drawCircle(point, 5, pointPaint);
          canvas.drawCircle(point, 2.3, pointInner);
        }
      }

      if (lastVisiblePoint != null) {
        canvas.drawCircle(
          lastVisiblePoint,
          9,
          Paint()..color = item.color.withValues(alpha: 0.16),
        );
        canvas.drawCircle(lastVisiblePoint, 5, pointPaint);
        canvas.drawCircle(lastVisiblePoint, 2.3, pointInner);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedLineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.series != series;
  }
}

class _ChartSeries {
  final String name;
  final Color color;
  final List<double> values;
  final String latestValue;

  _ChartSeries({
    required this.name,
    required this.color,
    required this.values,
    required this.latestValue,
  });
}

class _ScaledYAxisLabels extends StatelessWidget {
  final double maxValue;

  const _ScaledYAxisLabels({
    required this.maxValue,
  });

  String _label(double ratio) {
    final value = maxValue * ratio;
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }
    if (value >= 10) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 27),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_label(1.0), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          Text(_label(0.75), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          Text(_label(0.50), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          Text(_label(0.25), style: const TextStyle(fontSize: 8, color: AppPalette.textMuted)),
          const Text('0', style: TextStyle(fontSize: 8, color: AppPalette.textMuted)),
        ],
      ),
    );
  }
}

class _ImportantItemData {
  final String id;
  final String title;
  final String subtitle;
  final String detail;
  final String status;
  final String categoryTag;
  final Color color;
  final IconData icon;
  final String category;
  final String actionLabel;
  final IconData actionIcon;

  const _ImportantItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.status,
    required this.categoryTag,
    required this.color,
    required this.icon,
    required this.category,
    required this.actionLabel,
    required this.actionIcon,
  });
}

class _SummaryData {
  final String title;
  final String value;
  final String unit;
  final String sub;
  final String badge;
  final Color badgeBg;
  final Color badgeTextColor;
  final IconData? badgeIcon;
  final IconData icon;
  final Color headerBg;
  final Color headerColor;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.unit,
    required this.sub,
    required this.badge,
    required this.badgeBg,
    required this.badgeTextColor,
    this.badgeIcon,
    required this.icon,
    required this.headerBg,
    required this.headerColor,
  });
}

class _ProgramOverviewData {
  final String title;
  final Color color;
  final int studentCount;
  final int roomCount;
  final double? avgGradePercent;

  const _ProgramOverviewData({
    required this.title,
    required this.color,
    required this.studentCount,
    required this.roomCount,
    this.avgGradePercent,
  });
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroTag(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.tint(Colors.white, 0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  final Color color;
  final double dotRadius;
  final double spacing;

  const _DottedLine({
    this.color = const Color(0xFFE5E5EA),
    this.dotRadius = 1.2,
    this.spacing = 5.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: dotRadius * 2,
      width: double.infinity,
      child: CustomPaint(
        painter: _DottedLinePainter(
          color: color,
          dotRadius: dotRadius,
          spacing: spacing,
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  _DottedLinePainter({
    required this.color,
    required this.dotRadius,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double startX = dotRadius;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, y), dotRadius, paint);
      startX += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


