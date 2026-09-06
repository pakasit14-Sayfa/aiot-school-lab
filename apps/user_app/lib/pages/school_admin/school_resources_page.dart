import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

enum _ResourcePeriod { daily, weekly, monthly, yearly }

class SchoolResourcesPage extends StatefulWidget {
  const SchoolResourcesPage({
    super.key,
    this.loadEnergySummary,
    this.loadWaterSummary,
    this.loadEnergyTrend,
    this.loadWaterTrend,
    this.loadEnergyScore,
    this.loadWaterScore,
    this.loadAlerts,
  });

  /// Injectable read seams, same pattern as the other connected School Admin
  /// pages. Production passes nothing and the real services are used; tests
  /// supply these to drive loading / data / empty / error without a live
  /// Supabase client.
  final Future<EnergyUsageSummary?> Function(String period)? loadEnergySummary;
  final Future<WaterUsageSummary?> Function(String period)? loadWaterSummary;
  final Future<List<UtilityTrendPoint>> Function(int days)? loadEnergyTrend;
  final Future<List<UtilityTrendPoint>> Function(int days)? loadWaterTrend;
  final Future<UtilityEfficiencyScore?> Function()? loadEnergyScore;
  final Future<UtilityEfficiencyScore?> Function()? loadWaterScore;
  final Future<List<SchoolSensorAlertRecord>> Function()? loadAlerts;

  @override
  State<SchoolResourcesPage> createState() => _SchoolResourcesPageState();
}

class _SchoolResourcesPageState extends State<SchoolResourcesPage> {
  _ResourcePeriod _period = _ResourcePeriod.daily;
  String _selectedBuilding = 'ทุกอาคาร';
  String _selectedRoom = 'ทุกห้อง';
  bool _isLoading = false;
  /// ป้าย "IoT Live Sync" เคยเป็น `final bool = true` ติดค้างเสมอ — ขึ้นเป็น
  /// สีเขียวแม้ในโรงเรียนที่ไม่มีมิเตอร์สักตัวและไม่มีข้อมูลไหลเข้าเลย
  /// ตอนนี้ผูกกับจำนวนมิเตอร์ที่ backend เห็นจริง
  bool get _liveTelemetry => _energyDeviceCount > 0 || _waterDeviceCount > 0;

  // Chart datasets
  // ชุดข้อมูลกราฟเคยเป็น `static const Map` สองก้อน (~170 บรรทัด) ที่แต่งขึ้น
  // ทั้งหมด: ยอดรวม "428.5 kWh" ค่าไฟ "฿1,885.40" ส่วนต่าง "ลดลง 3.2%" และ
  // คำบรรยายที่อ้างข้อสรุปเชิงวิเคราะห์อย่าง "Peak: 14:00 - 16:00 น." กับ
  // "เสาร์-อาทิตย์ ปิดทำการประหยัดได้ 65%" — ระบบไม่เคยมีข้อมูลรายชั่วโมง
  // และไม่เคยคำนวณอะไรพวกนี้เลย
  //
  // ตอนนี้ทุกค่ามาจาก RPC จริงที่ school_admin เรียกได้:
  //   get_energy_usage_summary / get_water_usage_summary (p_period)
  //   get_energy_usage_trend  / get_water_usage_trend   (จุดรายวัน)
  //   get_energy_efficiency_score / get_water_efficiency_score (current/previous)
  // ส่วนต่างเทียบช่วงก่อนหน้าคำนวณจาก current/previous ที่ backend คืนมาจริง
  // ไม่ได้เดา — และค่า peak/avg/ต่ำสุด คำนวณจากจุดใน trend จริง
  _ChartSeries? _electricitySeries;
  _ChartSeries? _waterSeries;

  /// แยก "โหลดไม่สำเร็จ" ออกจาก "ไม่มีข้อมูล" — ของเดิมกลืน error แล้วโชว์
  /// ตัวเลขปลอมต่อ ทำให้ทั้งสองกรณีหน้าตาเหมือนข้อมูลจริง
  bool _loadFailed = false;

  /// จำนวนมิเตอร์ที่ backend เห็น ใช้แยก "วัดแล้วได้ศูนย์" ออกจาก
  /// "ไม่มีอะไรวัด" — RPC รวมยอดด้วย coalesce(sum(...), 0) โรงเรียนที่ไม่มี
  /// มิเตอร์เลยจึงได้ 0.0 ที่อ่านเหมือนค่าจริง (บทเรียนจาก energy page)
  int _energyDeviceCount = 0;
  int _waterDeviceCount = 0;

  /// การแจ้งเตือนค่าเกินเกณฑ์จริงจาก sensor_alerts (cron เขียน) ใช้แทนรายการ
  /// "ความผิดปกติ" ที่เคยแต่งขึ้น
  List<SchoolSensorAlertRecord> _alerts = const [];
  bool _alertsLoading = true;

  /// ยังไม่มีข้อมูลจริง → คืนชุดที่บอกสถานะตรง ๆ แทนที่จะเป็น null
  /// (ทุกช่องเป็นข้อความสถานะ ไม่ใช่ตัวเลข จึงไม่มีทางถูกอ่านว่าเป็นค่าจริง)
  _ChartSeries _placeholderSeries() {
    final String text = _isLoading
        ? 'กำลังโหลด…'
        : (_loadFailed ? 'โหลดไม่สำเร็จ' : 'ยังไม่มีข้อมูล');
    return _ChartSeries(
      labels: const [],
      values: const [],
      total: text,
      cost: text,
      previous: text,
      change: _loadFailed ? 'โหลดไม่สำเร็จ' : 'ไม่มีข้อมูลเทียบ',
      isPositive: true,
      caption: _loadFailed
          ? 'โหลดข้อมูลการใช้ทรัพยากรไม่สำเร็จ'
          : 'ยังไม่มีมิเตอร์ที่ส่งค่าเข้าระบบ',
      peakValue: text,
      avgValue: text,
      lowestValue: text,
    );
  }

  _ChartSeries get _electricity => _electricitySeries ?? _placeholderSeries();
  _ChartSeries get _water => _waterSeries ?? _placeholderSeries();

  /// ค่าที่ backend รองรับจริง — ตรวจจากตัวฟังก์ชันในฐานข้อมูล ไม่ใช่เดา
  String get _periodParam {
    switch (_period) {
      case _ResourcePeriod.daily:
        return 'today';
      case _ResourcePeriod.weekly:
        return 'week';
      case _ResourcePeriod.monthly:
        return 'month';
      case _ResourcePeriod.yearly:
        return 'year';
    }
  }

  int get _trendDays {
    switch (_period) {
      case _ResourcePeriod.daily:
        return 1;
      case _ResourcePeriod.weekly:
        return 7;
      case _ResourcePeriod.monthly:
        return 30;
      case _ResourcePeriod.yearly:
        return 365;
    }
  }


  String get _periodTitle {
    switch (_period) {
      case _ResourcePeriod.daily:
        return 'วันนี้';
      case _ResourcePeriod.weekly:
        return 'สัปดาห์นี้';
      case _ResourcePeriod.monthly:
        return 'เดือนนี้';
      case _ResourcePeriod.yearly:
        return 'ปีนี้';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUtilityData();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (mounted) setState(() => _alertsLoading = true);
    try {
      final rows = await (widget.loadAlerts?.call() ??
          IncidentService.listSchoolAlerts(status: 'new'));
      if (!mounted) return;
      setState(() {
        _alerts = rows;
        _alertsLoading = false;
      });
    } catch (e) {
      debugPrint('listSchoolAlerts failed: $e');
      if (!mounted) return;
      setState(() {
        _alerts = const [];
        _alertsLoading = false;
      });
    }
  }

  /// เดิมฟังก์ชันนี้ `await UtilityService.getSchoolUtilityRates()` แล้ว
  /// **ทิ้งผลลัพธ์ทันที** ไม่เก็บใส่ตัวแปรใด ๆ ส่วน `catch (_)` เขียนคอมเมนต์ว่า
  /// "Offline fallback" ทั้งที่ไม่มี fallback อะไรเลย — หน้าจึงแสดงค่าคงที่
  /// เหมือนเดิมไม่ว่าจะโหลดสำเร็จหรือล้มเหลว
  Future<void> _loadUtilityData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }
    try {
      final results = await Future.wait([
        widget.loadEnergySummary?.call(_periodParam) ??
            UtilityService.getEnergyUsageSummary(period: _periodParam),
        widget.loadWaterSummary?.call(_periodParam) ??
            UtilityService.getWaterUsageSummary(period: _periodParam),
        widget.loadEnergyTrend?.call(_trendDays) ??
            UtilityService.getEnergyUsageTrend(days: _trendDays),
        widget.loadWaterTrend?.call(_trendDays) ??
            UtilityService.getWaterUsageTrend(days: _trendDays),
        widget.loadEnergyScore?.call() ??
            UtilityService.getEnergyEfficiencyScore(),
        widget.loadWaterScore?.call() ??
            UtilityService.getWaterEfficiencyScore(),
      ]);
      if (!mounted) return;

      final energySummary = results[0] as EnergyUsageSummary?;
      final waterSummary = results[1] as WaterUsageSummary?;
      final energyTrend = results[2] as List<UtilityTrendPoint>;
      final waterTrend = results[3] as List<UtilityTrendPoint>;
      final energyScore = results[4] as UtilityEfficiencyScore?;
      final waterScore = results[5] as UtilityEfficiencyScore?;

      setState(() {
        _energyDeviceCount = energySummary?.deviceCount ?? 0;
        _waterDeviceCount = waterSummary?.deviceCount ?? 0;
        _electricitySeries = _buildSeries(
          points: energyTrend,
          total: energySummary == null
              ? null
              : '${energySummary.totalKwh.toStringAsFixed(1)} kWh',
          cost: energySummary == null
              ? null
              : '฿${energySummary.estimatedCostThb.toStringAsFixed(2)}',
          score: energyScore,
          unit: 'kWh',
          deviceCount: _energyDeviceCount,
          meterNoun: 'มิเตอร์ไฟ',
        );
        _waterSeries = _buildSeries(
          points: waterTrend,
          total: waterSummary == null
              ? null
              : '${waterSummary.totalM3.toStringAsFixed(1)} m³',
          cost: waterSummary == null
              ? null
              : '฿${waterSummary.estimatedCostThb.toStringAsFixed(2)}',
          score: waterScore,
          unit: 'm³',
          deviceCount: _waterDeviceCount,
          meterNoun: 'มิเตอร์น้ำ',
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SchoolResourcesPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _electricitySeries = null;
        _waterSeries = null;
      });
    }
  }

  /// ประกอบชุดกราฟจากข้อมูลจริงเท่านั้น ค่าไหนที่ backend ไม่ได้ให้มาจะเป็น
  /// `ยังไม่มีข้อมูล` ไม่ใช่ตัวเลขที่เดาขึ้น
  _ChartSeries _buildSeries({
    required List<UtilityTrendPoint> points,
    required String? total,
    required String? cost,
    required UtilityEfficiencyScore? score,
    required String unit,
    required int deviceCount,
    required String meterNoun,
  }) {
    const String noData = 'ยังไม่มีข้อมูล';
    final values = points.map((p) => p.value).toList();
    final labels = points
        .map((p) => '${p.day.day}/${p.day.month}')
        .toList(growable: false);

    // ส่วนต่างเทียบช่วงก่อนหน้ามาจาก current/previous ที่ backend คืนมาจริง
    // ถ้าไม่มีช่วงก่อนหน้าให้เทียบ (previous = 0) ก็บอกตรง ๆ ว่าเทียบไม่ได้
    String change = 'ไม่มีข้อมูลเทียบ';
    bool isPositive = true;
    String previous = noData;
    if (score != null) {
      previous = '${score.previous.toStringAsFixed(1)} $unit';
      if (score.previous > 0) {
        final diff = (score.current - score.previous) / score.previous * 100;
        isPositive = diff <= 0;
        change =
            '${diff <= 0 ? 'ลดลง' : 'เพิ่มขึ้น'} ${diff.abs().toStringAsFixed(1)}%';
      }
    }

    String stat(double Function(List<double>) pick) => values.isEmpty
        ? noData
        : '${pick(values).toStringAsFixed(1)} $unit';

    return _ChartSeries(
      labels: labels,
      values: values,
      total: total ?? noData,
      cost: cost ?? noData,
      previous: previous,
      change: change,
      isPositive: isPositive,
      // ไม่ใส่ข้อสรุปเชิงวิเคราะห์ที่ระบบคำนวณไม่ได้ บอกแค่ที่มาของข้อมูล
      caption: deviceCount == 0
          ? 'ยังไม่มี$meterNounที่ส่งค่าเข้าระบบ'
          : 'จาก$meterNoun $deviceCount จุด · ${points.length} วันที่มีข้อมูล',
      peakValue: stat((v) => v.reduce((a, b) => a > b ? a : b)),
      avgValue: stat((v) => v.reduce((a, b) => a + b) / v.length),
      lowestValue: stat((v) => v.reduce((a, b) => a < b ? a : b)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // เกณฑ์การแจ้งเตือน: เดิมสามช่องนี้เป็นค่าตายตัวและปุ่มบันทึกแค่ขึ้นข้อความ
  // "บันทึกเรียบร้อยแล้ว" โดยไม่เขียนอะไรลงฐานข้อมูลเลย
  //
  // ตรวจกับฐานข้อมูลที่รันอยู่แล้วว่า `set_threshold` เปิดให้
  // ('teacher','school_admin','super_admin') และ metric_type มีค่า
  // energy_kwh / water_m3 / pm25 ตรงกับสามช่องนี้พอดี จึงต่อของจริงได้
  // โดยไม่ต้องเขียน backend ใหม่
  final TextEditingController _energyLimitCtrl = TextEditingController();
  final TextEditingController _waterLimitCtrl = TextEditingController();
  final TextEditingController _pm25LimitCtrl = TextEditingController();
  bool _thresholdSaving = false;
  bool _thresholdsLoaded = false;

  @override
  void dispose() {
    _energyLimitCtrl.dispose();
    _waterLimitCtrl.dispose();
    _pm25LimitCtrl.dispose();
    super.dispose();
  }

  /// โหลดเกณฑ์ที่บันทึกไว้จริง ไม่เติมค่าตั้งต้นสมมติ — ช่องว่างแปลว่า
  /// ยังไม่เคยตั้งเกณฑ์นั้น ไม่ใช่ว่าเกณฑ์เป็น 500
  Future<void> _loadThresholds() async {
    try {
      final rows = await RealtimeService.listThresholds();
      double? maxFor(String metric) {
        for (final r in rows) {
          if (r['metric'] == metric) return (r['max_value'] as num?)?.toDouble();
        }
        return null;
      }

      if (!mounted) return;
      final energy = maxFor('energy_kwh');
      final water = maxFor('water_m3');
      final pm25 = maxFor('pm25');
      setState(() {
        _energyLimitCtrl.text = energy?.toString() ?? '';
        _waterLimitCtrl.text = water?.toString() ?? '';
        _pm25LimitCtrl.text = pm25?.toString() ?? '';
        _thresholdsLoaded = true;
      });
    } catch (e) {
      debugPrint('listThresholds failed: $e');
      if (mounted) setState(() => _thresholdsLoaded = true);
    }
  }

  /// เขียนจริง แล้วอ่านกลับมายืนยันก่อนบอกว่าสำเร็จ ถ้าอ่านกลับไม่ตรงจะบอกว่า
  /// ยืนยันไม่ได้ ไม่ใช่บอกว่าสำเร็จ
  Future<void> _saveThresholds() async {
    final entries = <String, TextEditingController>{
      'energy_kwh': _energyLimitCtrl,
      'water_m3': _waterLimitCtrl,
      'pm25': _pm25LimitCtrl,
    };
    final wanted = <String, double>{};
    for (final e in entries.entries) {
      final raw = e.value.text.trim();
      if (raw.isEmpty) continue;
      final parsed = double.tryParse(raw);
      if (parsed == null) {
        _showMessage('กรอกตัวเลขให้ถูกต้องก่อนบันทึก');
        return;
      }
      wanted[e.key] = parsed;
    }
    if (wanted.isEmpty) {
      _showMessage('ยังไม่ได้กรอกเกณฑ์ใดเลย');
      return;
    }

    setState(() => _thresholdSaving = true);
    try {
      for (final e in wanted.entries) {
        await RealtimeService.setThreshold(
          metric: e.key,
          min: 0,
          max: e.value,
        );
      }
      // อ่าน canonical กลับมาตรวจว่าเขียนติดจริง
      final rows = await RealtimeService.listThresholds();
      final confirmed = wanted.entries.every((e) {
        for (final r in rows) {
          if (r['metric'] == e.key &&
              ((r['max_value'] as num?)?.toDouble() ?? -1) == e.value) {
            return true;
          }
        }
        return false;
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage(
        confirmed
            ? 'บันทึกเกณฑ์การแจ้งเตือนแล้ว'
            : 'ส่งคำขอแล้ว แต่ยืนยันผลไม่ได้ กรุณาเปิดดูอีกครั้ง',
      );
    } catch (e) {
      debugPrint('setThreshold failed: $e');
      if (!mounted) return;
      _showMessage('บันทึกเกณฑ์ไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _thresholdSaving = false);
    }
  }

  void _openThresholdDialog() {
    if (!_thresholdsLoaded) _loadThresholds();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: SchoolAdminPalette.primaryDark),
              SizedBox(width: 10),
              Text(
                'ตั้งค่าเพดานการใช้ทรัพยากร',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'กำหนดขีดจำกัดแจ้งเตือนอัตโนมัติเมื่อมีการใช้พลังงานหรือน้ำเกินเกณฑ์',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                // ช่องว่าง = ยังไม่เคยตั้งเกณฑ์นี้ ไม่ใช่ค่าตั้งต้นสมมติ
                TextFormField(
                  controller: _energyLimitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'เพดานการใช้ไฟฟ้าสูงสุดรายวัน (kWh/วัน)',
                    hintText: 'ยังไม่ได้ตั้งเกณฑ์',
                    suffixText: 'kWh',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _waterLimitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'เพดานการใช้น้ำสูงสุดรายวัน (m³/วัน)',
                    hintText: 'ยังไม่ได้ตั้งเกณฑ์',
                    suffixText: 'm³',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pm25LimitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'เกณฑ์แจ้งเตือนฝุ่นละออง PM2.5 (µg/m³)',
                    hintText: 'ยังไม่ได้ตั้งเกณฑ์',
                    suffixText: 'µg/m³',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: _thresholdSaving ? null : _saveThresholds,
              style: FilledButton.styleFrom(
                backgroundColor: SchoolAdminPalette.primaryDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('บันทึกการตั้งค่า'),
            ),
          ],
        );
      },
    );
  }

  void _showBuildingDetailDialog(_BuildingResourceRecord building) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'พื้นที่ ${building.area} • มิเตอร์ IoT ${building.meterCount} จุด',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BuildingModalMetricRow(
                    label: 'การใช้ไฟฟ้า$_periodTitle',
                    value: building.electricityText,
                    subValue: 'คิดเป็น ${building.electricityPercent}% ของโรงเรียน',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 10),
                  _BuildingModalMetricRow(
                    label: 'การใช้น้ำประปา$_periodTitle',
                    value: building.waterText,
                    subValue: 'คิดเป็น ${building.waterPercent}% ของโรงเรียน',
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF0284C7),
                  ),
                  const SizedBox(height: 10),
                  _BuildingModalMetricRow(
                    label: 'ดัชนีประสิทธิภาพพลังงาน',
                    value: 'เกรด ${building.efficiencyGrade}',
                    subValue: building.efficiencyDetail,
                    icon: Icons.eco_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                  _BuildingModalMetricRow(
                    label: 'คุณภาพอากาศเฉลี่ย',
                    value: 'PM2.5 ${building.pm25} µg/m³',
                    subValue: 'สถานะ: ${building.airQualityStatus}',
                    icon: Icons.air_rounded,
                    color: const Color(0xFF059669),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showMessage('เปิดหน้าควบคุมอุปกรณ์ของ ${building.name}');
              },
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('ปรับแต่งระบบอัตโนมัติ'),
              style: FilledButton.styleFrom(
                backgroundColor: SchoolAdminPalette.primaryDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  _buildKpiSummaryGrid(),
                  const SizedBox(height: 16),
                  _buildMainAnalyticsSection(),
                  const SizedBox(height: 16),
                  _buildBuildingTableSection(),
                  const SizedBox(height: 16),
                  _buildAnomaliesAndIoTStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Banner
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget titleArea = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA45C23), Color(0xFF4C2113)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2AA45C23),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.energy_savings_leaf_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'การใช้ทรัพยากรและพลังงาน',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (_liveTelemetry)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'IoT Live Sync',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ติดตามวิเคราะห์ข้อมูลการใช้ไฟฟ้า น้ำประปา และสิ่งแวดล้อมทั่วสถานศึกษาแบบ Real-Time พร้อมระบบตรวจจับจุดผิดปกติอัจฉริยะ',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget actionButtons = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _openThresholdDialog,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('ตั้งค่าเกณฑ์แจ้งเตือน'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // ไม่มี pipeline สร้างไฟล์รายงานในระบบ ปุ่มนี้เคยขึ้นว่า "สำเร็จ"
              // ทั้งที่ไม่มีไฟล์ใดถูกสร้างเลย จึงปิดไว้พร้อมบอกเหตุผล
              Tooltip(
                message:
                    'ยังไม่รองรับการส่งออกไฟล์รายงาน — ฟีเจอร์นี้ยังไม่ได้เชื่อมกับเซิร์ฟเวอร์',
                child: FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.file_download_outlined, size: 17),
                  label: const Text('ส่งออกรายงาน (ยังไม่เปิดใช้งาน)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SchoolAdminPalette.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 850) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleArea,
                const SizedBox(height: 14),
                actionButtons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleArea),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  // 2. Filter Bar
  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget periodPills = Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPeriodPill('วันนี้', _ResourcePeriod.daily),
                _buildPeriodPill('สัปดาห์นี้', _ResourcePeriod.weekly),
                _buildPeriodPill('เดือนนี้', _ResourcePeriod.monthly),
                _buildPeriodPill('ปีนี้', _ResourcePeriod.yearly),
              ],
            ),
          );

          final Widget buildingFilter = DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedBuilding,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'เลือกอาคาร',
                prefixIcon: const Icon(
                  Icons.apartment_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'ทุกอาคาร', child: Text('ทุกอาคาร')),
                DropdownMenuItem(
                  value: 'อาคารเรียน A',
                  child: Text('อาคารเรียน A'),
                ),
                DropdownMenuItem(
                  value: 'อาคารเรียน B',
                  child: Text('อาคารเรียน B'),
                ),
                DropdownMenuItem(
                  value: 'อาคารปฏิบัติการ',
                  child: Text('อาคารปฏิบัติการ'),
                ),
                DropdownMenuItem(
                  value: 'อาคารอำนวยการ',
                  child: Text('อาคารอำนวยการ'),
                ),
                DropdownMenuItem(value: 'โรงอาหาร', child: Text('โรงอาหาร')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedBuilding = value;
                    _selectedRoom = 'ทุกห้อง';
                  });
                }
              },
            ),
          );

          final Widget roomFilter = DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedRoom,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'เลือกห้อง / โซน',
                prefixIcon: const Icon(
                  Icons.meeting_room_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'ทุกห้อง', child: Text('ทุกห้อง')),
                DropdownMenuItem(value: 'ห้อง 101', child: Text('ห้อง 101')),
                DropdownMenuItem(value: 'ห้อง 102', child: Text('ห้อง 102')),
                DropdownMenuItem(value: 'ห้อง 201', child: Text('ห้อง 201')),
                DropdownMenuItem(value: 'ห้อง 202', child: Text('ห้อง 202')),
                DropdownMenuItem(
                  value: 'ห้องปฏิบัติการ 1',
                  child: Text('ห้องปฏิบัติการ 1'),
                ),
                DropdownMenuItem(
                  value: 'ห้องปฏิบัติการ 2',
                  child: Text('ห้องปฏิบัติการ 2'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _selectedRoom = value);
                }
              },
            ),
          );

          if (constraints.maxWidth < 980) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                periodPills,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: buildingFilter),
                    const SizedBox(width: 10),
                    Expanded(child: roomFilter),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              periodPills,
              const SizedBox(width: 16),
              Expanded(flex: 3, child: buildingFilter),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: roomFilter),
              const SizedBox(width: 12),
              IconButton.outlined(
                tooltip: 'รีเฟรชข้อมูลล่าสุด',
                onPressed: _loadUtilityData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF475569),
                      ),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodPill(String title, _ResourcePeriod target) {
    final bool isSelected = _period == target;

    return InkWell(
      onTap: () => setState(() => _period = target),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? SchoolAdminPalette.primaryDark
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // 3. Executive KPI Grid (4 Cards)
  Widget _buildKpiSummaryGrid() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1180) columns = 2;
        if (constraints.maxWidth < 580) columns = 1;

        const double spacing = 14;
        final double cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        final List<Widget> cards = [
          _buildKpiCard(
            title: 'การใช้ไฟฟ้า$_periodTitle',
            value: _electricity.total,
            subValue: 'ประมาณการ ${_electricity.cost}',
            trendText: _electricity.change,
            isPositive: _electricity.isPositive,
            icon: Icons.bolt_rounded,
            accentColor: const Color(0xFFD97706),
            accentBg: const Color(0xFFFEF3C7),
          ),
          _buildKpiCard(
            title: 'การใช้น้ำประปา$_periodTitle',
            value: _water.total,
            subValue: 'ประมาณการ ${_water.cost}',
            trendText: _water.change,
            isPositive: _water.isPositive,
            icon: Icons.water_drop_rounded,
            accentColor: const Color(0xFF0284C7),
            accentBg: const Color(0xFFE0F2FE),
          ),
          _buildKpiCard(
            title: 'คุณภาพอากาศ & ESG',
            value: 'PM2.5 18.2',
            subValue: 'เกณฑ์ดีเยี่ยม • 0.21 tCO2e',
            trendText: 'อากาศบริสุทธิ์',
            isPositive: true,
            icon: Icons.eco_rounded,
            accentColor: const Color(0xFF16A34A),
            accentBg: const Color(0xFFDCFCE7),
          ),
          _buildKpiCard(
            title: 'จุดตรวจจับความผิดปกติ',
            value: '2 จุดเฝ้าระวัง',
            subValue: 'อาคารปฏิบัติการ / อาคาร B',
            trendText: 'ต้องตรวจสอบด่วน',
            isPositive: false,
            icon: Icons.warning_amber_rounded,
            accentColor: const Color(0xFFDC2626),
            accentBg: const Color(0xFFFEE2E2),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((Widget c) => SizedBox(width: cardWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subValue,
    required String trendText,
    required bool isPositive,
    required IconData icon,
    required Color accentColor,
    required Color accentBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPositive
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      size: 13,
                      color: isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isPositive
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Main Analytics Chart Hub
  Widget _buildMainAnalyticsSection() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget electricityCard = _buildModernChartCard(
          title: 'วิเคราะห์การใช้ไฟฟ้า (Power Analytics)',
          subtitle: _electricity.caption,
          icon: Icons.bolt_rounded,
          accentColor: const Color(0xFFD97706),
          chartSeries: _electricity,
          unit: 'kWh',
        );

        final Widget waterCard = _buildModernChartCard(
          title: 'วิเคราะห์การใช้น้ำประปา (Water Analytics)',
          subtitle: _water.caption,
          icon: Icons.water_drop_rounded,
          accentColor: const Color(0xFF0284C7),
          chartSeries: _water,
          unit: 'm³',
        );

        if (constraints.maxWidth < 1050) {
          return Column(
            children: [
              electricityCard,
              const SizedBox(height: 16),
              waterCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: electricityCard),
            const SizedBox(width: 16),
            Expanded(child: waterCard),
          ],
        );
      },
    );
  }

  Widget _buildModernChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required _ChartSeries chartSeries,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sub-metrics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildChartMetricColumn(
                    'ยอดรวม',
                    chartSeries.total,
                    const Color(0xFF0F172A),
                  ),
                ),
                Expanded(
                  child: _buildChartMetricColumn(
                    'ช่วงพีคสูงสุด',
                    chartSeries.peakValue,
                    accentColor,
                  ),
                ),
                Expanded(
                  child: _buildChartMetricColumn(
                    'ค่าเฉลี่ย',
                    chartSeries.avgValue,
                    const Color(0xFF475569),
                  ),
                ),
                Expanded(
                  child: _buildChartMetricColumn(
                    'ต่ำสุด',
                    chartSeries.lowestValue,
                    const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Interactive Custom Painter Chart
          SizedBox(
            height: 250,
            width: double.infinity,
            child: _ModernInteractiveChart(
              labels: chartSeries.labels,
              values: chartSeries.values,
              color: accentColor,
              unit: unit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // 5. Building Consumption & Efficiency Table Section
  Widget _buildBuildingTableSection() {
    // ตารางนี้เคยเป็นอาคาร 4 หลังที่แต่งขึ้นทั้งหมด — ชื่อ พื้นที่ จำนวนมิเตอร์
    // ยอดใช้ไฟ/น้ำ เกรดประสิทธิภาพ และค่า PM2.5 รายอาคาร
    //
    // ตรวจแล้วว่าไม่มีทางแสดงของจริงได้ตอนนี้ ด้วยเหตุผลสองชั้น:
    //   1. ไม่มี RPC รวมยอดรายอาคารเลย (มีแค่ระดับโรงเรียน: summary/trend/score)
    //   2. ต่อให้เขียน RPC ก็ยังไม่มีอะไรให้จัดกลุ่ม — devices.building เป็น
    //      null ทั้งหมด ยังไม่มีการผูกมิเตอร์เข้ากับอาคาร
    // จึงแสดง empty state ที่บอกเงื่อนไขตรง ๆ แทนการเดาตัวเลขรายอาคาร
    final List<_BuildingResourceRecord> buildings = const [];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: SchoolAdminPalette.primaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'การใช้ทรัพยากรและประสิทธิภาพแยกตามอาคาร',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'เปรียบเทียบปริมาณการใช้ไฟฟ้า น้ำประปา และดัชนีประสิทธิภาพพลังงาน (Energy Efficiency Grade)',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth >= 980) {
                return Table(
                  border: const TableBorder(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    horizontalInside: BorderSide(
                      color: Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(2.2),
                    1: FlexColumnWidth(1.6),
                    2: FlexColumnWidth(1.6),
                    3: FlexColumnWidth(1.3),
                    4: FlexColumnWidth(1.1),
                    5: FlexColumnWidth(1.0),
                    6: FlexColumnWidth(0.9),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      children: [
                        _ResourceTableHeader(text: 'อาคาร / พื้นที่', align: TextAlign.left),
                        _ResourceTableHeader(text: 'การใช้ไฟฟ้า'),
                        _ResourceTableHeader(text: 'การใช้น้ำประปา'),
                        _ResourceTableHeader(text: 'เกรดประสิทธิภาพ'),
                        _ResourceTableHeader(text: 'PM2.5 / อากาศ'),
                        _ResourceTableHeader(text: 'สถานะ'),
                        _ResourceTableHeader(text: 'จัดการ'),
                      ],
                    ),
                    if (buildings.isEmpty)
                      const TableRow(
                        children: [
                          _ResourceTableHeader(
                            text: 'ยังไม่มีข้อมูล — ต้องผูกมิเตอร์เข้ากับอาคารก่อน',
                            align: TextAlign.left,
                          ),
                          SizedBox.shrink(),
                          SizedBox.shrink(),
                          SizedBox.shrink(),
                          SizedBox.shrink(),
                          SizedBox.shrink(),
                          SizedBox.shrink(),
                        ],
                      ),
                    ...buildings.map((_BuildingResourceRecord b) {
                      return TableRow(
                        children: [
                          _buildBuildingNameCell(b),
                          _buildUsageBarCell(
                            b.electricityText,
                            b.electricityPercent / 100,
                            const Color(0xFFD97706),
                          ),
                          _buildUsageBarCell(
                            b.waterText,
                            b.waterPercent / 100,
                            const Color(0xFF0284C7),
                          ),
                          _buildEfficiencyGradeCell(b.efficiencyGrade),
                          _buildAirQualityCell(b.pm25, b.airQualityStatus),
                          _buildStatusBadgeCell(b.status),
                          _buildActionCell(b),
                        ],
                      );
                    }),
                  ],
                );
              }

              // Mobile Card List
              return Padding(
                padding: const EdgeInsets.all(14),
                child: buildings.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'ยังไม่มีข้อมูล — ต้องผูกมิเตอร์เข้ากับอาคารก่อน '
                          'จึงจะแยกยอดรายอาคารได้',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      )
                    : Column(
                        children: buildings
                            .map((b) => _buildMobileBuildingCard(b))
                            .toList(),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingNameCell(_BuildingResourceRecord b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: SchoolAdminPalette.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${b.area} • ${b.meterCount} มิเตอร์',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBarCell(String text, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyGradeCell(String grade) {
    Color bg = const Color(0xFFDCFCE7);
    Color text = const Color(0xFF166534);
    if (grade.startsWith('B')) {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
    } else if (grade.startsWith('C') || grade.startsWith('D')) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'เกรด $grade',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAirQualityCell(int pm25, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Center(
        child: Column(
          children: [
            Text(
              '$pm25 µg/m³',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadgeCell(String status) {
    final bool isWarning = status == 'เฝ้าระวัง';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isWarning ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWarning
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFBBF7D0),
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isWarning
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCell(_BuildingResourceRecord b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Center(
        child: IconButton(
          tooltip: 'ดูรายละเอียด',
          onPressed: () => _showBuildingDetailDialog(b),
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBuildingCard(_BuildingResourceRecord b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                b.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _buildEfficiencyGradeCell(b.efficiencyGrade),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ไฟฟ้า',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      b.electricityText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'น้ำประปา',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      b.waterText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PM2.5',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '${b.pm25} µg/m³',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showBuildingDetailDialog(b),
              child: const Text('ดูรายละเอียดอาคาร'),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Smart Anomalies & IoT Health Section
  Widget _buildAnomaliesAndIoTStatus() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget anomaliesCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: Color(0x0E0F172A),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notification_important_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'รายการแจ้งเตือนที่ต้องตรวจสอบ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // เดิมส่วนนี้เป็นความผิดปกติสองรายการที่แต่งขึ้นทั้งหมด — ระบุเวลา
              // ("12:45 น."), สถานที่ ("อาคารปฏิบัติการ ชั้น 2") และข้อสรุป
              // ("เปิดเครื่องปรับอากาศทิ้งไว้ 3 ห้อง", "อัตราไหล 0.35 m³/ชม.")
              // ทั้งที่ระบบไม่มีการตรวจจับความผิดปกติเชิงพฤติกรรมแบบนั้นเลย
              // และปุ่มก็ขึ้นแค่ข้อความว่าสั่งงานแล้วโดยไม่ส่งคำสั่งอะไรจริง
              //
              // แหล่งข้อมูลจริงที่มีคือ sensor_alerts ซึ่ง cron
              // threshold-violation-check เขียนเมื่อค่าเกินเกณฑ์ที่ตั้งไว้
              if (_alertsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'ยังไม่มีข้อมูล — ยังไม่มีค่าที่เกินเกณฑ์ที่ตั้งไว้',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                )
              else
                ..._alerts.take(5).map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildAnomalyItem(
                      title: '${a.metric} เกินเกณฑ์ (${a.value})',
                      subtitle: '${a.deviceName} · ${a.deviceCode}',
                      severity: a.status == 'new' ? 'ยังไม่รับเรื่อง' : a.status,
                      time:
                          '${a.triggeredAt.hour.toString().padLeft(2, '0')}:'
                          '${a.triggeredAt.minute.toString().padLeft(2, '0')} น.',
                      color: a.status == 'new'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                      // ไม่มี RPC สำหรับสั่งปิดอุปกรณ์หรือแจ้งฝ่ายอาคารจากหน้านี้
                      // จึงไม่ให้ปุ่มที่กดแล้วไม่เกิดอะไร
                      onAction: null,
                    ),
                  ),
                ),
            ],
          ),
        );

        final Widget iotStatusCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: Color(0x0E0F172A),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.sensors_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'สถานะการเชื่อมต่อ IoT มิเตอร์',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildIoTMeterStatusRow(
                title: 'สมาร์ตมิเตอร์ไฟฟ้า (Modbus RTU)',
                detail: 'ออนไลน์ 12 / 12 จุด (100%)',
                icon: Icons.electric_meter_rounded,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(height: 10),
              _buildIoTMeterStatusRow(
                title: 'มิเตอร์น้ำดิจิทัล (Ultrasonic)',
                detail: 'ออนไลน์ 8 / 8 จุด (100%)',
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF0284C7),
              ),
              const SizedBox(height: 10),
              _buildIoTMeterStatusRow(
                title: 'เซนเซอร์สภาพอากาศ & PM2.5 (LoRaWAN)',
                detail: 'ออนไลน์ 18 / 18 จุด (100%)',
                icon: Icons.air_rounded,
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 1000) {
          return Column(
            children: [
              anomaliesCard,
              const SizedBox(height: 16),
              iotStatusCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: anomaliesCard),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: iotStatusCard),
          ],
        );
      },
    );
  }

  Widget _buildAnomalyItem({
    required String title,
    required String subtitle,
    required String severity,
    required String time,
    required Color color,
    // null = ไม่มี backend รองรับการกระทำนี้ จึงไม่แสดงปุ่มเลย ดีกว่ามีปุ่ม
    // ที่กดแล้วขึ้นข้อความว่าสั่งงานแล้วทั้งที่ไม่ได้ส่งคำสั่งอะไร
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (onAction != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ดำเนินการแก้ไข',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: SchoolAdminPalette.primaryDark,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: SchoolAdminPalette.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIoTMeterStatusRow({
    required String title,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 18,
          ),
        ],
      ),
    );
  }
}

// 7. Interactive Modern Line/Stepped-Area Chart
class _ModernInteractiveChart extends StatelessWidget {
  const _ModernInteractiveChart({
    required this.labels,
    required this.values,
    required this.color,
    required this.unit,
  });

  final List<String> labels;
  final List<double> values;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ModernChartPainter(
        labels: labels,
        values: values,
        color: color,
        unit: unit,
      ),
    );
  }
}

class _ModernChartPainter extends CustomPainter {
  const _ModernChartPainter({
    required this.labels,
    required this.values,
    required this.color,
    required this.unit,
  });

  final List<String> labels;
  final List<double> values;
  final Color color;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || labels.isEmpty) return;

    const double left = 44;
    const double right = 14;
    const double top = 14;
    const double bottom = 32;

    final Rect plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    double maxValue = values.first;
    double minValue = values.first;

    for (final double v in values) {
      if (v > maxValue) maxValue = v;
      if (v < minValue) minValue = v;
    }

    if (maxValue == minValue) {
      maxValue += 1;
      minValue -= 1;
    }

    final double padding = (maxValue - minValue) * 0.15;
    maxValue += padding;
    minValue -= padding;
    if (minValue < 0) minValue = 0;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const int gridRows = 4;
    for (int i = 0; i <= gridRows; i++) {
      final double y = plot.top + (plot.height / gridRows) * i;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);

      final double val = maxValue - ((maxValue - minValue) / gridRows) * i;
      final String valStr = val >= 1000
          ? '${(val / 1000).toStringAsFixed(1)}k'
          : val >= 100
              ? val.toStringAsFixed(0)
              : val.toStringAsFixed(1);

      textPainter.text = TextSpan(
        text: valStr,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: 40);
      textPainter.paint(
        canvas,
        Offset(plot.left - textPainter.width - 6, y - (textPainter.height / 2)),
      );
    }

    final int count = values.length;
    final double stepX = count <= 1 ? 0 : plot.width / (count - 1);

    Offset pointAt(int i) {
      final double x = plot.left + stepX * i;
      final double norm = (values[i] - minValue) / (maxValue - minValue);
      final double y = plot.bottom - (norm * plot.height);
      return Offset(x, y);
    }

    final Path fillPath = Path();
    final Path linePath = Path();

    for (int i = 0; i < count; i++) {
      final Offset pt = pointAt(i);
      if (i == 0) {
        linePath.moveTo(pt.dy, pt.dy);
        fillPath.moveTo(pt.dx, plot.bottom);
        fillPath.lineTo(pt.dx, pt.dy);
      } else {
        final Offset prev = pointAt(i - 1);
        final double midX = (prev.dx + pt.dx) / 2;
        linePath.cubicTo(midX, prev.dy, midX, pt.dy, pt.dx, pt.dy);
        fillPath.cubicTo(midX, prev.dy, midX, pt.dy, pt.dx, pt.dy);
      }
    }

    final Offset lastPt = pointAt(count - 1);
    fillPath.lineTo(lastPt.dx, plot.bottom);
    fillPath.close();

    // Fill Gradient
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withAlpha(50), color.withAlpha(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(plot);

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // Draw Points
    final Paint dotOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint dotInner = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final Offset pt = pointAt(i);
      canvas.drawCircle(pt, 4.5, dotOuter);
      canvas.drawCircle(pt, 2.5, dotInner);
    }

    // X Labels
    final int labelStep = labels.length > 8 ? 2 : 1;
    for (int i = 0; i < labels.length && i < count; i++) {
      if (i % labelStep != 0 && i != labels.length - 1) continue;

      final Offset pt = pointAt(i);
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: 50);

      double x = pt.dx - (textPainter.width / 2);
      if (x < 0) x = 0;
      if (x + textPainter.width > size.width) {
        x = size.width - textPainter.width;
      }
      textPainter.paint(canvas, Offset(x, plot.bottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _ModernChartPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.unit != unit;
  }
}

// 8. Reusable Header & Detail Widgets
class _ResourceTableHeader extends StatelessWidget {
  const _ResourceTableHeader({
    required this.text,
    this.align = TextAlign.center,
  });

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BuildingModalMetricRow extends StatelessWidget {
  const _BuildingModalMetricRow({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  subValue,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data model definitions
class _ChartSeries {
  const _ChartSeries({
    required this.labels,
    required this.values,
    required this.total,
    required this.cost,
    required this.previous,
    required this.change,
    required this.isPositive,
    required this.caption,
    required this.peakValue,
    required this.avgValue,
    required this.lowestValue,
  });

  final List<String> labels;
  final List<double> values;
  final String total;
  final String cost;
  final String previous;
  final String change;
  final bool isPositive;
  final String caption;
  final String peakValue;
  final String avgValue;
  final String lowestValue;
}

class _BuildingResourceRecord {
  const _BuildingResourceRecord({
    required this.name,
    required this.area,
    required this.meterCount,
    required this.electricityText,
    required this.electricityPercent,
    required this.waterText,
    required this.waterPercent,
    required this.efficiencyGrade,
    required this.efficiencyDetail,
    required this.pm25,
    required this.airQualityStatus,
    required this.status,
  });

  final String name;
  final String area;
  final int meterCount;
  final String electricityText;
  final int electricityPercent;
  final String waterText;
  final int waterPercent;
  final String efficiencyGrade;
  final String efficiencyDetail;
  final int pm25;
  final String airQualityStatus;
  final String status;
}

