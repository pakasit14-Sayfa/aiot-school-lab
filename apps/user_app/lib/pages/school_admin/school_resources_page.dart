import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

enum _ResourcePeriod {
  daily,
  monthly,
  yearly,
}

class SchoolResourcesPage extends StatefulWidget {
  const SchoolResourcesPage({super.key});

  @override
  State<SchoolResourcesPage> createState() => _SchoolResourcesPageState();
}

class _SchoolResourcesPageState extends State<SchoolResourcesPage> {
  _ResourcePeriod _period = _ResourcePeriod.daily;
  String _building = 'ทุกอาคาร';
  String _room = 'ทุกห้อง';

  static const Map<_ResourcePeriod, _ChartSeries> _electricitySeries = {
    _ResourcePeriod.daily: _ChartSeries(
      labels: [
        '00:00',
        '03:00',
        '06:00',
        '09:00',
        '12:00',
        '15:00',
        '18:00',
        '21:00',
      ],
      values: [18, 14, 21, 62, 79, 88, 91, 55],
      total: '428 kWh',
      previous: '442 kWh',
      change: 'ลดลง 3.2%',
      caption: 'การใช้ไฟวันนี้แยกตามช่วงเวลา',
    ),
    _ResourcePeriod.monthly: _ChartSeries(
      labels: ['1', '5', '10', '15', '20', '25', '30'],
      values: [368, 402, 389, 431, 417, 456, 428],
      total: '12,840 kWh',
      previous: '13,210 kWh',
      change: 'ลดลง 2.8%',
      caption: 'การใช้ไฟเดือนนี้แยกตามวัน',
    ),
    _ResourcePeriod.yearly: _ChartSeries(
      labels: [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ],
      values: [
        11240,
        10860,
        11920,
        12640,
        13110,
        12840,
        13520,
        12980,
        12140,
        11820,
        11460,
        10990,
      ],
      total: '145,520 kWh',
      previous: '151,300 kWh',
      change: 'ลดลง 3.8%',
      caption: 'การใช้ไฟปีนี้แยกตามเดือน',
    ),
  };

  static const Map<_ResourcePeriod, _ChartSeries> _waterSeries = {
    _ResourcePeriod.daily: _ChartSeries(
      labels: [
        '00:00',
        '03:00',
        '06:00',
        '09:00',
        '12:00',
        '15:00',
        '18:00',
        '21:00',
      ],
      values: [0.4, 0.3, 1.1, 2.3, 2.6, 2.1, 2.4, 1.4],
      total: '12.6 m³',
      previous: '12.5 m³',
      change: 'เพิ่มขึ้น 1.1%',
      caption: 'การใช้น้ำวันนี้แยกตามช่วงเวลา',
    ),
    _ResourcePeriod.monthly: _ChartSeries(
      labels: ['1', '5', '10', '15', '20', '25', '30'],
      values: [10.8, 11.6, 12.4, 11.9, 13.1, 12.8, 12.6],
      total: '372.4 m³',
      previous: '380.2 m³',
      change: 'ลดลง 2.1%',
      caption: 'การใช้น้ำเดือนนี้แยกตามวัน',
    ),
    _ResourcePeriod.yearly: _ChartSeries(
      labels: [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ],
      values: [
        342,
        331,
        355,
        371,
        389,
        402,
        396,
        382,
        368,
        351,
        340,
        328,
      ],
      total: '4,455 m³',
      previous: '4,610 m³',
      change: 'ลดลง 3.4%',
      caption: 'การใช้น้ำปีนี้แยกตามเดือน',
    ),
  };

  _ChartSeries get _electricity => _electricitySeries[_period]!;
  _ChartSeries get _water => _waterSeries[_period]!;

  String get _periodTitle {
    switch (_period) {
      case _ResourcePeriod.daily:
        return 'รายวัน';
      case _ResourcePeriod.monthly:
        return 'รายเดือน';
      case _ResourcePeriod.yearly:
        return 'รายปี';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUtilityData();
  }

  Future<void> _loadUtilityData() async {
    try {
      await UtilityService.getSchoolUtilityRates();
    } catch (_) {
      // Keep default series in test/offline
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 115),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildCharts(),
                  const SizedBox(height: 14),
                  _buildBuildingUsage(),
                  const SizedBox(height: 14),
                  _buildAlertsAndStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final Widget title = const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: SchoolAdminPalette.primarySoft,
                child: Icon(
                  Icons.energy_savings_leaf_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 26,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การใช้ทรัพยากร',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'ติดตามการใช้ไฟฟ้า การใช้น้ำ และคุณภาพอากาศของโรงเรียน พร้อมดูแนวโน้มรายวัน รายเดือน และรายปี',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget action = OutlinedButton.icon(
            onPressed: () {
              _showMessage('เตรียมข้อมูลสำหรับสร้างรายงานแล้ว');
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('ส่งออกรายงาน'),
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                action,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 14),
              action,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return _ResourceSectionCard(
      title: 'เลือกข้อมูลที่ต้องการดู',
      subtitle: 'เลือกช่วงเวลา อาคาร และห้อง ระบบจะเปลี่ยนกราฟให้ตามตัวเลือก',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final Widget period = _PeriodSelector(
            selected: _period,
            onChanged: (_ResourcePeriod value) {
              setState(() => _period = value);
            },
          );

          final Widget building = _ResourceDropdown(
            label: 'อาคาร',
            value: _building,
            items: const [
              'ทุกอาคาร',
              'อาคารเรียน A',
              'อาคารเรียน B',
              'อาคารปฏิบัติการ',
              'อาคารอำนวยการ',
              'โรงอาหาร',
            ],
            onChanged: (String value) {
              setState(() {
                _building = value;
                _room = 'ทุกห้อง';
              });
            },
          );

          final Widget room = _ResourceDropdown(
            label: 'ห้อง',
            value: _room,
            items: const [
              'ทุกห้อง',
              'ห้อง 101',
              'ห้อง 102',
              'ห้อง 201',
              'ห้อง 202',
              'ห้องปฏิบัติการ 1',
              'ห้องปฏิบัติการ 2',
            ],
            onChanged: (String value) {
              setState(() => _room = value);
            },
          );

          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                period,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: building),
                    const SizedBox(width: 10),
                    Expanded(child: room),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: period),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: building),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: room),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    final List<_ResourceSummaryData> items = [
      _ResourceSummaryData(
        title: 'ไฟฟ้า$_periodTitle',
        value: _electricity.total,
        detail: 'เทียบช่วงก่อนหน้า ${_electricity.change}',
        icon: Icons.bolt_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _ResourceSummaryData(
        title: 'น้ำ$_periodTitle',
        value: _water.total,
        detail: 'เทียบช่วงก่อนหน้า ${_water.change}',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF4F6078),
      ),
      const _ResourceSummaryData(
        title: 'คุณภาพอากาศ',
        value: 'PM2.5 21',
        detail: 'ระดับดี • AQI 37',
        icon: Icons.air_rounded,
        color: Color(0xFF3F7650),
      ),
      const _ResourceSummaryData(
        title: 'รายการผิดปกติ',
        value: '2 รายการ',
        detail: 'ควรตรวจสอบภายในวันนี้',
        icon: Icons.notifications_active_rounded,
        color: SchoolAdminPalette.red,
      ),
    ];

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 300) columns = 1;

        const double spacing = 12;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_ResourceSummaryData item) {
            return SizedBox(
              width: width,
              child: _ResourceSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCharts() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final Widget electricity = _UsageChartCard(
          title: 'กราฟการใช้ไฟฟ้า',
          subtitle: _electricity.caption,
          total: _electricity.total,
          previous: _electricity.previous,
          change: _electricity.change,
          unit: 'kWh',
          icon: Icons.bolt_rounded,
          color: SchoolAdminPalette.primaryDark,
          series: _electricity,
        );

        final Widget water = _UsageChartCard(
          title: 'กราฟการใช้น้ำ',
          subtitle: _water.caption,
          total: _water.total,
          previous: _water.previous,
          change: _water.change,
          unit: 'm³',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF4F6078),
          series: _water,
        );

        if (constraints.maxWidth < 1000) {
          return Column(
            children: [
              electricity,
              const SizedBox(height: 14),
              water,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: electricity),
            const SizedBox(width: 14),
            Expanded(child: water),
          ],
        );
      },
    );
  }

  Widget _buildBuildingUsage() {
    return _ResourceSectionCard(
      title: 'การใช้ทรัพยากรแยกตามอาคาร',
      subtitle: 'ช่วยดูว่าอาคารใดใช้ไฟหรือน้ำสูงกว่าส่วนอื่น',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          const List<_BuildingUsageData> items = [
            _BuildingUsageData(
              name: 'อาคารเรียน A',
              electricity: 82,
              water: 61,
              electricityText: '96 kWh',
              waterText: '2.7 m³',
            ),
            _BuildingUsageData(
              name: 'อาคารเรียน B',
              electricity: 68,
              water: 58,
              electricityText: '78 kWh',
              waterText: '2.4 m³',
            ),
            _BuildingUsageData(
              name: 'อาคารปฏิบัติการ',
              electricity: 94,
              water: 72,
              electricityText: '118 kWh',
              waterText: '3.1 m³',
            ),
            _BuildingUsageData(
              name: 'อาคารอำนวยการ',
              electricity: 52,
              water: 41,
              electricityText: '61 kWh',
              waterText: '1.7 m³',
            ),
          ];

          int columns = 2;
          if (constraints.maxWidth < 760) columns = 1;

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((_BuildingUsageData item) {
              return SizedBox(
                width: width,
                child: _BuildingUsageCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildAlertsAndStatus() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        const Widget alerts = _ResourceSectionCard(
          title: 'รายการที่ควรตรวจสอบ',
          subtitle: 'แจ้งเฉพาะค่าที่สูงผิดปกติหรือเซนเซอร์มีปัญหา',
          child: Column(
            children: [
              _ResourceAlertRow(
                icon: Icons.bolt_rounded,
                title: 'การใช้ไฟสูงกว่าค่าเฉลี่ย',
                detail: 'อาคารปฏิบัติการ • สูงกว่าปกติประมาณ 14%',
                status: 'ตรวจสอบ',
                color: SchoolAdminPalette.red,
              ),
              SizedBox(height: 9),
              _ResourceAlertRow(
                icon: Icons.water_drop_rounded,
                title: 'น้ำไหลต่อเนื่องนอกเวลา',
                detail: 'อาคารเรียน B • ตรวจพบหลัง 19:30 น.',
                status: 'ติดตาม',
                color: SchoolAdminPalette.secondary,
              ),
            ],
          ),
        );

        const Widget status = _ResourceSectionCard(
          title: 'สถานะระบบวัด',
          subtitle: 'ตรวจสอบว่าอุปกรณ์เก็บข้อมูลพร้อมใช้งาน',
          child: Column(
            children: [
              _SensorStatusRow(
                title: 'มิเตอร์ไฟฟ้า',
                detail: 'ออนไลน์ 12 / 12 จุด',
                icon: Icons.electric_meter_rounded,
                color: SchoolAdminPalette.green,
              ),
              SizedBox(height: 9),
              _SensorStatusRow(
                title: 'มิเตอร์น้ำ',
                detail: 'ออนไลน์ 8 / 8 จุด',
                icon: Icons.water_damage_rounded,
                color: SchoolAdminPalette.green,
              ),
              SizedBox(height: 9),
              _SensorStatusRow(
                title: 'เซนเซอร์คุณภาพอากาศ',
                detail: 'ออนไลน์ 18 / 18 จุด',
                icon: Icons.sensors_rounded,
                color: SchoolAdminPalette.green,
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 900) {
          return const Column(
            children: [
              alerts,
              SizedBox(height: 14),
              status,
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: alerts),
            SizedBox(width: 14),
            Expanded(flex: 4, child: status),
          ],
        );
      },
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final _ResourcePeriod selected;
  final ValueChanged<_ResourcePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodButton(
              title: 'รายวัน',
              selected: selected == _ResourcePeriod.daily,
              onTap: () => onChanged(_ResourcePeriod.daily),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              title: 'รายเดือน',
              selected: selected == _ResourcePeriod.monthly,
              onTap: () => onChanged(_ResourcePeriod.monthly),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              title: 'รายปี',
              selected: selected == _ResourcePeriod.yearly,
              onTap: () => onChanged(_ResourcePeriod.yearly),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SchoolAdminPalette.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : SchoolAdminPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceDropdown extends StatelessWidget {
  const _ResourceDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _ResourceSummaryCard extends StatelessWidget {
  const _ResourceSummaryCard({
    required this.data,
  });

  final _ResourceSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 150 : 132),
          padding: EdgeInsets.all(compact ? 13 : 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResourceIconBox(
                      icon: data.icon,
                      color: data.color,
                      compact: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.45,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _ResourceIconBox(
                      icon: data.icon,
                      color: data.color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              height: 1.45,
                              color: SchoolAdminPalette.textSecondary,
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
  }
}

class _ResourceIconBox extends StatelessWidget {
  const _ResourceIconBox({
    required this.icon,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 42 : 49;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(
          color: color.withAlpha(85),
          width: 1.2,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: compact ? 21 : 24,
      ),
    );
  }
}

class _UsageChartCard extends StatelessWidget {
  const _UsageChartCard({
    required this.title,
    required this.subtitle,
    required this.total,
    required this.previous,
    required this.change,
    required this.unit,
    required this.icon,
    required this.color,
    required this.series,
  });

  final String title;
  final String subtitle;
  final String total;
  final String previous;
  final String change;
  final String unit;
  final IconData icon;
  final Color color;
  final _ChartSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ResourceIconBox(icon: icon, color: color),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetric(
                label: 'ช่วงนี้',
                value: total,
                color: color,
              ),
              _MiniMetric(
                label: 'ช่วงก่อนหน้า',
                value: previous,
                color: SchoolAdminPalette.textSecondary,
              ),
              _MiniMetric(
                label: 'เปลี่ยนแปลง',
                value: change,
                color: change.contains('เพิ่ม')
                    ? SchoolAdminPalette.red
                    : SchoolAdminPalette.green,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 285,
            width: double.infinity,
            child: _SimpleLineChart(
              labels: series.labels,
              values: series.values,
              color: color,
              unit: unit,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({
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
      painter: _LineChartPainter(
        labels: labels,
        values: values,
        color: color,
        unit: unit,
        textColor: SchoolAdminPalette.textSecondary,
        gridColor: SchoolAdminPalette.border,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.labels,
    required this.values,
    required this.color,
    required this.unit,
    required this.textColor,
    required this.gridColor,
  });

  final List<String> labels;
  final List<double> values;
  final Color color;
  final String unit;
  final Color textColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || labels.isEmpty) return;

    const double left = 48;
    const double right = 12;
    const double top = 14;
    const double bottom = 38;

    final Rect plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    double maxValue = values.first;
    double minValue = values.first;

    for (final double value in values) {
      if (value > maxValue) maxValue = value;
      if (value < minValue) minValue = value;
    }

    if (maxValue == minValue) {
      maxValue += 1;
      minValue -= 1;
    }

    final double padding = (maxValue - minValue) * 0.12;
    maxValue += padding;
    minValue = minValue - padding;
    if (minValue < 0) minValue = 0;

    final Paint gridPaint = Paint()
      ..color = gridColor.withAlpha(120)
      ..strokeWidth = 1;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const int horizontalLines = 4;

    for (int i = 0; i <= horizontalLines; i++) {
      final double y = plot.top + (plot.height / horizontalLines) * i;

      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        gridPaint,
      );

      final double value =
          maxValue - ((maxValue - minValue) / horizontalLines) * i;

      final String label = value >= 1000
          ? '${(value / 1000).toStringAsFixed(1)}k'
          : value >= 100
              ? value.toStringAsFixed(0)
              : value.toStringAsFixed(1);

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10.5,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: 40);
      textPainter.paint(
        canvas,
        Offset(
          plot.left - textPainter.width - 7,
          y - (textPainter.height / 2),
        ),
      );
    }

    final int count = values.length;
    final double stepX = count <= 1 ? 0 : plot.width / (count - 1);

    Offset pointAt(int index) {
      final double x = plot.left + stepX * index;
      final double normalized =
          (values[index] - minValue) / (maxValue - minValue);
      final double y = plot.bottom - (normalized * plot.height);
      return Offset(x, y);
    }

    final Path fillPath = Path();
    final Path linePath = Path();

    for (int i = 0; i < count; i++) {
      final Offset point = pointAt(i);

      if (i == 0) {
        linePath.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, plot.bottom);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    final Offset lastPoint = pointAt(count - 1);
    fillPath.lineTo(lastPoint.dx, plot.bottom);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..color = color.withAlpha(18)
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final Paint pointOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint pointInner = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final Offset point = pointAt(i);
      canvas.drawCircle(point, 5.2, pointOuter);
      canvas.drawCircle(point, 3.2, pointInner);
    }

    final int labelEvery = labels.length > 9 ? 2 : 1;

    for (int i = 0; i < labels.length && i < count; i++) {
      if (i % labelEvery != 0 && i != labels.length - 1) continue;

      final Offset point = pointAt(i);
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10.5,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: 52);

      double x = point.dx - (textPainter.width / 2);
      if (x < 0) x = 0;
      if (x + textPainter.width > size.width) {
        x = size.width - textPainter.width;
      }

      textPainter.paint(
        canvas,
        Offset(x, plot.bottom + 10),
      );
    }

    textPainter.text = TextSpan(
      text: unit,
      style: TextStyle(
        fontSize: 10.5,
        color: textColor,
        fontWeight: FontWeight.w800,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(4, 1),
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.unit != unit;
  }
}

class _BuildingUsageCard extends StatelessWidget {
  const _BuildingUsageCard({
    required this.data,
  });

  final _BuildingUsageData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _UsageProgressRow(
            icon: Icons.bolt_rounded,
            title: 'ไฟฟ้า',
            value: data.electricity / 100,
            valueText: data.electricityText,
            color: SchoolAdminPalette.primaryDark,
          ),
          const SizedBox(height: 12),
          _UsageProgressRow(
            icon: Icons.water_drop_rounded,
            title: 'น้ำ',
            value: data.water / 100,
            valueText: data.waterText,
            color: const Color(0xFF4F6078),
          ),
        ],
      ),
    );
  }
}

class _UsageProgressRow extends StatelessWidget {
  const _UsageProgressRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.valueText,
    required this.color,
  });

  final IconData icon;
  final String title;
  final double value;
  final String valueText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: SchoolAdminPalette.sandSoft,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 58,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResourceAlertRow extends StatelessWidget {
  const _ResourceAlertRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _ResourceIconBox(
            icon: icon,
            color: color,
            compact: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorStatusRow extends StatelessWidget {
  const _SensorStatusRow({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _ResourceIconBox(
            icon: icon,
            color: color,
            compact: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: SchoolAdminPalette.green,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ResourceSectionCard extends StatelessWidget {
  const _ResourceSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChartSeries {
  const _ChartSeries({
    required this.labels,
    required this.values,
    required this.total,
    required this.previous,
    required this.change,
    required this.caption,
  });

  final List<String> labels;
  final List<double> values;
  final String total;
  final String previous;
  final String change;
  final String caption;
}

class _ResourceSummaryData {
  const _ResourceSummaryData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _BuildingUsageData {
  const _BuildingUsageData({
    required this.name,
    required this.electricity,
    required this.water,
    required this.electricityText,
    required this.waterText,
  });

  final String name;
  final double electricity;
  final double water;
  final String electricityText;
  final String waterText;
}
