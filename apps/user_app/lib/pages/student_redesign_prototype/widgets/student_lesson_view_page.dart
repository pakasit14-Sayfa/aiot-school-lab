import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'student_redesign_palette.dart';

class StudentLessonViewPage extends StatefulWidget {
  const StudentLessonViewPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<StudentLessonViewPage> createState() => _StudentLessonViewPageState();
}

class _StudentLessonViewPageState extends State<StudentLessonViewPage> {
  bool _loading = true;
  String? _error;
  LessonDetail? _lesson;
  CourseDetail? _course;
  bool _isMarkingComplete = false;

  final Map<String, List<SensorDataPoint>> _sensorHistories = {};
  final Map<String, bool> _loadingSensors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lesson = await LessonService.getLesson(widget.lessonId);
      CourseDetail? course;
      try {
        course = await CourseService.getCourse(lesson.courseId);
      } catch (_) {}

      // Auto update progress when opening lesson
      try {
        await LessonService.updateProgress(
          lessonId: widget.lessonId,
          progressPct: lesson.progressPct ?? 50,
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _lesson = lesson;
          _course = course;
          _loading = false;
        });
      }

      // Fetch sensor history for links
      if (lesson.sensorLinks.isNotEmpty) {
        for (final link in lesson.sensorLinks) {
          _fetchSensorHistory(link);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'ไม่สามารถโหลดข้อมูลบทเรียนได้: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchSensorHistory(LessonSensorLink link) async {
    setState(() => _loadingSensors[link.id] = true);
    try {
      final from =
          link.timeStart ?? DateTime.now().subtract(const Duration(hours: 24));
      final points = await AiotLabService.getSensorHistory(
        deviceId: link.deviceId,
        metric: link.metric,
        from: from,
        to: link.timeEnd,
      );
      if (mounted) {
        setState(() {
          _sensorHistories[link.id] = points;
          _loadingSensors[link.id] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sensorHistories[link.id] = [];
          _loadingSensors[link.id] = false;
        });
      }
    }
  }

  Future<void> _markComplete() async {
    if (_lesson == null || _isMarkingComplete) return;

    setState(() => _isMarkingComplete = true);
    try {
      await LessonService.markComplete(widget.lessonId);
      if (!mounted) return;
      setState(() {
        _lesson = LessonDetail(
          id: _lesson!.id,
          courseId: _lesson!.courseId,
          title: _lesson!.title,
          content: _lesson!.content,
          status: _lesson!.status,
          publishedAt: _lesson!.publishedAt,
          materials: _lesson!.materials,
          sensorLinks: _lesson!.sensorLinks,
          progressPct: 100,
          completed: true,
        );
        _isMarkingComplete = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ทำเครื่องหมายว่าเรียนจบบทเรียนนี้เรียบร้อยแล้ว'),
          backgroundColor: SchoolPalette.deepGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMarkingComplete = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openMaterial(LessonMaterial mat) async {
    try {
      // Uploaded files (image/video/file) store a Storage path, not a
      // directly-reachable URL — resolve a short-lived signed URL first.
      // Only 'link' materials are already a real external URL.
      final url = mat.type == 'link'
          ? mat.url
          : await LessonService.getMaterialDownloadUrl(mat.id);

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเปิดไฟล์ได้: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolPalette.softGreenBg,
      appBar: AppBar(
        backgroundColor: SchoolPalette.softGreenBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _course != null ? _course!.subjectName : 'เนื้อหาบทเรียน',
          style: const TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: SchoolPalette.deepGreen),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: SchoolPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('ลองใหม่อีกครั้ง'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SchoolPalette.deepGreen,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _buildLessonView(),
    );
  }

  Widget _buildLessonView() {
    final lesson = _lesson!;
    final bodyText =
        (lesson.content?['body'] as String?) ??
        (lesson.content?['text'] as String?) ??
        'ไม่มีเนื้อหาข้อความในบทเรียนนี้';

    final isCompleted = lesson.completed == true;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject & Title Banner using SchoolPalette Brand Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: SchoolPalette.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x25165042),
                    blurRadius: 20,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          _course != null ? _course!.subjectName : 'บทเรียน',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: SchoolPalette.mint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: SchoolPalette.deepGreen,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'เรียนจบแล้ว',
                                style: TextStyle(
                                  color: SchoolPalette.deepGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),
                  if (lesson.publishedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'เผยแพร่เมื่อ: ${lesson.publishedAt!.day}/${lesson.publishedAt!.month}/${lesson.publishedAt!.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lesson Body Content Card
            const Text(
              '📖 เนื้อหาบทเรียน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: SchoolPalette.navy,
              ),
            ),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                bodyText,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.65,
                  color: SchoolPalette.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lesson Materials Section
            if (lesson.materials.isNotEmpty) ...[
              const Text(
                '📄 เอกสารและไฟล์ประกอบการเรียน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: SchoolPalette.navy,
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lesson.materials.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mat = lesson.materials[index];
                  return SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SchoolPalette.deepGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            mat.type == 'link'
                                ? Icons.link_rounded
                                : Icons.picture_as_pdf_rounded,
                            color: SchoolPalette.deepGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mat.title ?? mat.url,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: SchoolPalette.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mat.type.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SchoolPalette.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openMaterial(mat),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('เปิดอ่าน'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SchoolPalette.deepGreen,
                            side: const BorderSide(
                              color: SchoolPalette.glassBorder,
                              width: 1.2,
                            ),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Sensor Links & Charts Section
            if (lesson.sensorLinks.isNotEmpty) ...[
              const Text(
                '📊 ข้อมูลเซนเซอร์ AIoT ที่ผูกกับบทเรียน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: SchoolPalette.navy,
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lesson.sensorLinks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final link = lesson.sensorLinks[index];
                  final isSensorLoading = _loadingSensors[link.id] == true;
                  final points = _sensorHistories[link.id] ?? [];

                  return SoftCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SchoolPalette.deepGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.sensors_rounded,
                                color: SchoolPalette.deepGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                link.caption ??
                                    'กราฟข้อมูลเซนเซอร์ (${link.metric})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: SchoolPalette.ink,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: SchoolPalette.softGreenBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: SchoolPalette.glassBorder,
                                ),
                              ),
                              child: Text(
                                link.metric.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: SchoolPalette.deepGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (isSensorLoading)
                          Container(
                            height: 180,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: SchoolPalette.deepGreen,
                            ),
                          )
                        else if (points.isEmpty)
                          Container(
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: SchoolPalette.softGreenBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'ไม่พบข้อมูลเซนเซอร์ในช่วงเวลาดังกล่าว',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: SchoolPalette.muted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 200,
                            child: _buildSensorChart(points),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Complete Mark Button using GradientButton
            isCompleted
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: SchoolPalette.mint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SchoolPalette.mint, width: 1.2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: SchoolPalette.deepGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'เรียนจบบทเรียนนี้แล้ว',
                          style: TextStyle(
                            color: SchoolPalette.deepGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                : GradientButton(
                    label: _isMarkingComplete
                        ? 'กำลังบันทึก...'
                        : 'ทำเครื่องหมายว่าเรียนจบแล้ว',
                    icon: Icons.task_alt_rounded,
                    onPressed: _isMarkingComplete ? null : _markComplete,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorChart(List<SensorDataPoint> points) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: SchoolPalette.glassBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (points.length / 4).clamp(1, 10).toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                final dt = points[idx].ts;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: SchoolPalette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    color: SchoolPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: SchoolPalette.deepGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: SchoolPalette.deepGreen.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
