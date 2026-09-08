import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../controllers/director_overview_controller.dart';
import '../theme/app_palette.dart';
import '../widgets/director_workspace_widgets.dart';
import '../widgets/director_overview_sensors.dart';

class DirectorOverviewPage extends StatefulWidget {
  const DirectorOverviewPage({
    super.key,
    required this.onNavigate,
    this.sensorStreamOverride,
    this.rawReadingsStreamOverride,
    this.controller,
  });
  final ValueChanged<int> onNavigate;
  final Stream<SensorModel?>? sensorStreamOverride;
  final Stream<List<Map<String, dynamic>>>? rawReadingsStreamOverride;
  final DirectorOverviewController? controller;
  @override
  State<DirectorOverviewPage> createState() => _DirectorOverviewPageState();
}

class _DirectorOverviewPageState extends State<DirectorOverviewPage> {
  late final controller = widget.controller ?? DirectorOverviewController();
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  String date(DateTime d) => '${d.day}/${d.month}/${d.year + 543}';
  Widget link(String label, int page) =>
      TextButton(onPressed: () => widget.onNavigate(page), child: Text(label));
  Widget metric(String label, String value, int page, Color color) => SizedBox(
    width: 220,
    child: Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => widget.onNavigate(page),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              const Text('ดูข้อมูล →'),
            ],
          ),
        ),
      ),
    ),
  );
  Widget trend(
    String title,
    List<UtilityTrendPoint> source,
    String unit,
    Color color,
  ) {
    final points = [...source]..sort((a, b) => a.day.compareTo(b.day));
    final maxValue = points.fold<double>(
      0,
      (m, p) => p.value > m ? p.value : m,
    );
    return DirectorWorkspaceCard(
      title: title,
      accent: color,
      icon: Icons.bar_chart,
      children: [
        if (points.isEmpty)
          const Text('ยังไม่มีข้อมูลย้อนหลัง')
        else ...[
          Text(
            'รวม ${points.fold<double>(0, (n, p) => n + p.value).toStringAsFixed(2)} $unit ในวันที่มีข้อมูล',
          ),
          const SizedBox(height: 16),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${date(p.day)} · ${p.value.toStringAsFixed(2)} $unit'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: maxValue <= 0 ? 0 : (p.value / maxValue).clamp(0, 1),
                    color: color,
                    backgroundColor: color.withAlpha(20),
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => DirectorWorkspace(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DirectorWorkspaceHero(
            title: 'ภาพรวมโรงเรียน',
            subtitle: 'ข้อมูลปัจจุบันของโรงเรียน · ${date(DateTime.now())}',
            icon: Icons.dashboard_outlined,
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final d = controller.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.loading
                        ? null
                        : () => controller.load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('โหลดภาพรวมใหม่'),
                  ),
                  const SizedBox(height: 16),
                  if (controller.loading)
                    const DirectorWorkspaceCard(
                      title: 'กำลังโหลดภาพรวม',
                      children: [LinearProgressIndicator()],
                    )
                  else if (controller.error != null)
                    DirectorWorkspaceCard(
                      title: 'โหลดภาพรวมไม่สำเร็จ',
                      children: [
                        Text(controller.error!),
                        TextButton(
                          onPressed: () => controller.load(),
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    )
                  else if (d == null || d.isEmpty)
                    const DirectorWorkspaceCard(
                      title: 'ยังไม่มีข้อมูลภาพรวม',
                      children: [Text('เมื่อโรงเรียนมีข้อมูล จะแสดงที่นี่')],
                    )
                  else ...[
                    Text(
                      'โหลดข้อมูลเมื่อ ${controller.loadedAt!.hour.toString().padLeft(2, '0')}:${controller.loadedAt!.minute.toString().padLeft(2, '0')} · ยอดทะเบียนปัจจุบัน ไม่ใช่ยอดย้อนหลัง',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        metric(
                          'นักเรียน',
                          d.counts.containsKey('student')
                              ? '${d.counts['student']} คน'
                              : 'ไม่มีข้อมูล',
                          2,
                          AppPalette.primaryPinkDark,
                        ),
                        metric(
                          'ครู',
                          d.counts.containsKey('teacher')
                              ? '${d.counts['teacher']} คน'
                              : 'ไม่มีข้อมูล',
                          3,
                          const Color(0xFF356A9A),
                        ),
                        metric(
                          'รายงานเหตุทั้งหมด',
                          '${d.incidents.fold<int>(0, (n, i) => n + i.totalCount)} รายงาน',
                          1,
                          AppPalette.warning,
                        ),
                        metric(
                          'อุปกรณ์ในทะเบียน',
                          '${d.devices.length} จุด',
                          8,
                          const Color(0xFF467A65),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DirectorWorkspaceGrid(
                      children: [
                        DirectorWorkspaceCard(
                          title: 'สายการเรียน',
                          icon: Icons.school_outlined,
                          children: [
                            if (d.tracks.isEmpty)
                              const Text('ยังไม่มีข้อมูลสายการเรียน'),
                            for (final t in d.tracks)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${t.studentCount} คน · ${t.roomCount} ห้อง',
                                    ),
                                    Text(
                                      t.avgGradePercent == null
                                          ? 'ยังไม่มีคะแนนยืนยัน'
                                          : 'คะแนนเฉลี่ยที่ยืนยัน ${t.avgGradePercent!.toStringAsFixed(1)}%',
                                    ),
                                  ],
                                ),
                              ),
                            link('ดูภาพรวมนักเรียน', 2),
                          ],
                        ),
                        DirectorWorkspaceCard(
                          title: 'ครูและการสอน',
                          icon: Icons.people_outline,
                          accent: const Color(0xFF356A9A),
                          children: [
                            Text(
                              d.counts.containsKey('teacher')
                                  ? 'ครูในทะเบียน ${d.counts['teacher']} คน'
                                  : 'ยังไม่มีข้อมูลจำนวนครู',
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'ยังไม่มีข้อมูลยืนยันสัดส่วนการเข้าสอน สอนแทน และเตรียมสอน',
                            ),
                            link('ดูบุคลากรและการลงเวลา', 3),
                            link('ดูตารางสอนของห้องเรียน', 4),
                          ],
                        ),
                      ],
                    ),
                    DirectorWorkspaceCard(
                      title: 'แนวโน้มการใช้ทรัพยากร',
                      icon: Icons.insights,
                      children: [
                        const Text('ช่วงเวลานี้ใช้กับกราฟไฟฟ้าและน้ำเท่านั้น'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final days in [7, 30])
                              ChoiceChip(
                                label: Text('$days วันล่าสุด'),
                                selected: controller.days == days,
                                onSelected: (_) =>
                                    controller.load(period: days),
                              ),
                          ],
                        ),
                        link('ดูค่าใช้จ่ายและรายละเอียดทรัพยากร', 8),
                      ],
                    ),
                    DirectorWorkspaceGrid(
                      children: [
                        trend(
                          'ไฟฟ้า',
                          d.energy,
                          'kWh',
                          AppPalette.primaryPinkDark,
                        ),
                        trend('น้ำ', d.water, 'm³', const Color(0xFF356A9A)),
                      ],
                    ),
                    DirectorWorkspaceCard(
                      title: 'ข้อความล่าสุดถึงคุณ',
                      icon: Icons.notifications_none,
                      children: [
                        const Text(
                          '5 รายการล่าสุดจากกล่องข้อความ ไม่ใช่ผลวิเคราะห์สถานการณ์อัตโนมัติ',
                        ),
                        if (d.notices.isEmpty)
                          const Text('ยังไม่มีการแจ้งเตือน'),
                        for (final n in d.notices.take(5))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(n.title),
                            subtitle: Text(
                              '${date(n.createdAt.toLocal())} · ${n.isUnread ? 'ยังไม่อ่าน' : 'อ่านแล้ว'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onNavigate(10),
                          ),
                        link('ดูการแจ้งเตือนทั้งหมด', 10),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          DirectorOverviewSensors(
            sensorStreamOverride: widget.sensorStreamOverride,
            rawReadingsStreamOverride: widget.rawReadingsStreamOverride,
          ),
        ],
      ),
    ),
  );
}
