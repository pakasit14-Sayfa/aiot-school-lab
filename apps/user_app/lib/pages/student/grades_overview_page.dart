import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

class GradesOverviewPage extends StatefulWidget {
  const GradesOverviewPage({super.key});

  @override
  State<GradesOverviewPage> createState() => _GradesOverviewPageState();
}

class _GradesOverviewPageState extends State<GradesOverviewPage> {
  List<CourseGrade> grades = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await GradeService.listMyGrades();
      if (!mounted) return;
      setState(() => grades = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = 'โหลดคะแนนไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  double get _averagePercent {
    if (grades.isEmpty) return 0;
    final total = grades.fold<double>(0, (sum, g) => sum + g.percent);
    return total / grades.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'คะแนนและผลการเรียน',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: load)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: load,
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Average Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF047857), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    grades.isEmpty
                                        ? 'ยังไม่มีคะแนนที่ยืนยันแล้ว'
                                        : 'คะแนนเฉลี่ย (${grades.length} วิชา)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    grades.isEmpty
                                        ? '—'
                                        : '${_averagePercent.toStringAsFixed(1)}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF38BDF8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'กฎเหล็กระบบ: คะแนนทั้งหมดได้รับการยืนยันขั้นสุดท้ายโดยครูผู้สอนแล้ว',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFF59E0B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'สรุปคะแนนแต่ละรายวิชา',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (grades.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'ยังไม่มีคะแนนที่ครูยืนยันในรายวิชาใดเลย',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...grades.map((g) {
                        const color = Color(0xFF0284C7);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.subjectName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (g.percent / 100).clamp(0, 1),
                                        minHeight: 8,
                                        backgroundColor: const Color(
                                          0xFFE2E8F0,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              color,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '${g.score} / ${g.maxScore} คะแนน',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    g.confirmedAt == null
                                        ? 'ครูยืนยันเรียบร้อยแล้ว'
                                        : 'ครูยืนยันเรียบร้อยแล้ว (${g.confirmedAt!.day}/${g.confirmedAt!.month}/${g.confirmedAt!.year + 543})',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
