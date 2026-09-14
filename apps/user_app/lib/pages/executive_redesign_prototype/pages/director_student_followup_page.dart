import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../theme/app_palette.dart';
import '../widgets/director_workspace_widgets.dart';

typedef StudentSearchLoader = Future<List<SchoolStudentOption>> Function(
  String? search,
);
typedef StaffDirectoryLoader = Future<List<StaffDirectoryEntry>> Function();
typedef HomeVisitsLoader = Future<List<HomeVisit>> Function();
typedef CreateHomeVisitFn =
    Future<String> Function({
      required String studentId,
      required DateTime visitDate,
      required String purpose,
      String? familySituation,
      bool followUpNeeded,
      String? followUpNotes,
    });
typedef SdqSummaryLoader = Future<List<SchoolSdqSummaryRow>> Function();
typedef RecordSdqFn =
    Future<({String assessmentId, int totalDifficultiesScore})> Function({
      required String studentId,
      required List<int> itemScores,
      String raterType,
      String? notes,
    });
typedef ScholarshipsLoader = Future<List<Scholarship>> Function();
typedef ScholarshipAwardsLoader =
    Future<List<ScholarshipAward>> Function({String? scholarshipId});
typedef CreateScholarshipFn =
    Future<String> Function({
      required String name,
      String? sponsor,
      double? amountThb,
      String? description,
    });
typedef NominateAwardFn =
    Future<String> Function({
      required String scholarshipId,
      required String studentId,
      String? notes,
    });
typedef SetAwardStatusFn =
    Future<void> Function({
      required String awardId,
      required String status,
      double? awardedAmountThb,
      String? notes,
    });
typedef DirectivesLoader = Future<List<ExecutiveDirective>> Function();
typedef CreateDirectiveFn =
    Future<String> Function({
      required String assignedTo,
      required String title,
      String? instructions,
      String? studentId,
      DateTime? dueDate,
    });

/// Real backend behind the 4 buttons that used to be onPressed:null on
/// director_learning_page.dart's "งานติดตามที่ยังไม่รองรับ" card. RPCs from
/// 20260911020000_student_followup_system.sql.
class DirectorStudentFollowupPage extends StatefulWidget {
  const DirectorStudentFollowupPage({
    super.key,
    this.initialTab = 0,
    this.loadStudents,
    this.loadStaff,
    this.loadHomeVisits,
    this.createHomeVisit,
    this.loadSdq,
    this.recordSdq,
    this.loadScholarships,
    this.loadScholarshipAwards,
    this.createScholarship,
    this.nominateAward,
    this.setAwardStatus,
    this.loadDirectives,
    this.createDirective,
  });

  final int initialTab;
  final StudentSearchLoader? loadStudents;
  final StaffDirectoryLoader? loadStaff;
  final HomeVisitsLoader? loadHomeVisits;
  final CreateHomeVisitFn? createHomeVisit;
  final SdqSummaryLoader? loadSdq;
  final RecordSdqFn? recordSdq;
  final ScholarshipsLoader? loadScholarships;
  final ScholarshipAwardsLoader? loadScholarshipAwards;
  final CreateScholarshipFn? createScholarship;
  final NominateAwardFn? nominateAward;
  final SetAwardStatusFn? setAwardStatus;
  final DirectivesLoader? loadDirectives;
  final CreateDirectiveFn? createDirective;

  @override
  State<DirectorStudentFollowupPage> createState() =>
      _DirectorStudentFollowupPageState();
}

final _softCard = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppPalette.border, width: 1.2),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ],
);

String _dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year + 543}';

class _DirectorStudentFollowupPageState
    extends State<DirectorStudentFollowupPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  List<HomeVisit>? _visits;
  List<SchoolSdqSummaryRow>? _sdq;
  List<Scholarship>? _scholarships;
  List<ScholarshipAward>? _awards;
  List<ExecutiveDirective>? _directives;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait<Object?>([
        (widget.loadHomeVisits ?? StudentFollowupService.listSchoolHomeVisits)(),
        (widget.loadSdq ?? StudentFollowupService.listSchoolSdqAssessments)(),
        (widget.loadScholarships ?? StudentFollowupService.listScholarships)(),
        (widget.loadScholarshipAwards ??
            ({String? scholarshipId}) =>
                StudentFollowupService.listScholarshipAwards())(),
        (widget.loadDirectives ??
            StudentFollowupService.listExecutiveDirectives)(),
      ]);
      if (!mounted) return;
      setState(() {
        _visits = results[0] as List<HomeVisit>;
        _sdq = results[1] as List<SchoolSdqSummaryRow>;
        _scholarships = results[2] as List<Scholarship>;
        _awards = results[3] as List<ScholarshipAward>;
        _directives = results[4] as List<ExecutiveDirective>;
        _error = null;
      });
    } catch (e) {
      debugPrint('DirectorStudentFollowupPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _visits = null;
        _sdq = null;
        _scholarships = null;
        _awards = null;
        _directives = null;
        _error = 'โหลดข้อมูลไม่สำเร็จ กรุณาลองอีกครั้ง';
      });
    }
  }

  Future<List<SchoolStudentOption>> _students(String? q) =>
      (widget.loadStudents ?? StudentFollowupService.listSchoolStudents)(q);
  Future<List<StaffDirectoryEntry>> _staff() =>
      (widget.loadStaff ?? StaffOrgService.listStaffDirectory)();

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    // `DirectorWorkspace` is Theme+ColoredBox+layout only, no Scaffold — it
    // was never a problem for the other director pages (they're embedded
    // shell destinations, no TabBar). This page is pushed via
    // Navigator.push, so it needs its own Material ancestor for TabBar
    // (crashed with "No Material widget found" without it) and a real back
    // button (browser back doesn't pop an in-app Navigator route on
    // Flutter web). Scaffold+AppBar fixes both, matching the same pattern
    // meeting_detail_page.dart already uses for a pushed page.
    return DirectorWorkspace(
      child: Scaffold(
        backgroundColor: AppPalette.pageBg,
        appBar: AppBar(
          title: const Text('งานติดตามนักเรียนรายบุคคล'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เยี่ยมบ้าน · SDQ · ทุนการศึกษา · สั่งการติดตาม',
                style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: _softCard,
                clipBehavior: Clip.antiAlias,
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppPalette.learningBlueDark,
                  unselectedLabelColor: AppPalette.textMuted,
                  indicatorColor: AppPalette.learningBlueDark,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'เยี่ยมบ้าน'),
                    Tab(text: 'SDQ'),
                    Tab(text: 'ทุนการศึกษา'),
                    Tab(text: 'สั่งการติดตาม'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: _softCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _loadAll, child: const Text('ลองอีกครั้ง')),
                    ],
                  ),
                )
              else
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _homeVisitTab(),
                      _sdqTab(),
                      _scholarshipTab(),
                      _directiveTab(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Home visits
  // ------------------------------------------------------------------
  Widget _homeVisitTab() {
    final visits = _visits;
    return _tabScaffold(
      loading: visits == null,
      empty: visits != null && visits.isEmpty,
      emptyText: 'ยังไม่มีการบันทึกเยี่ยมบ้าน',
      addLabel: '+ บันทึกการเยี่ยมบ้าน',
      onAdd: _openCreateHomeVisit,
      children: [
        for (final v in visits ?? const <HomeVisit>[])
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _softCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      _dateLabel(v.visitDate),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(v.purpose, style: const TextStyle(fontSize: 12)),
                if (v.familySituation?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    v.familySituation!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'ผู้เยี่ยม: ${v.visitedByName}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (v.followUpNeeded)
                      _pillBadge('ต้องติดตามต่อ', AppPalette.warning),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openCreateHomeVisit() async {
    final student = await _pickStudent();
    if (student == null || !mounted) return;
    final purposeCtrl = TextEditingController();
    final familyCtrl = TextEditingController();
    final followUpCtrl = TextEditingController();
    var followUpNeeded = false;
    var date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('บันทึกการเยี่ยมบ้าน · ${student.studentName}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(date.year - 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 14),
                    label: Text('วันที่เยี่ยม: ${_dateLabel(date)}'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: purposeCtrl,
                    decoration: const InputDecoration(labelText: 'วัตถุประสงค์การเยี่ยม *'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: familyCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'สภาพครอบครัว/บันทึกเพิ่มเติม'),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: followUpNeeded,
                    onChanged: (v) => setDialogState(() => followUpNeeded = v ?? false),
                    title: const Text('ต้องติดตามต่อ'),
                  ),
                  if (followUpNeeded)
                    TextField(
                      controller: followUpCtrl,
                      decoration: const InputDecoration(labelText: 'แผนติดตามต่อ'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: purposeCtrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogCtx, true),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await (widget.createHomeVisit ??
          ({
            required studentId,
            required visitDate,
            required purpose,
            familySituation,
            followUpNeeded = false,
            followUpNotes,
          }) => StudentFollowupService.createHomeVisit(
            studentId: studentId,
            visitDate: visitDate,
            purpose: purpose,
            familySituation: familySituation,
            followUpNeeded: followUpNeeded,
            followUpNotes: followUpNotes,
          ))(
        studentId: student.studentId,
        visitDate: date,
        purpose: purposeCtrl.text.trim(),
        familySituation: familyCtrl.text.trim().isEmpty ? null : familyCtrl.text.trim(),
        followUpNeeded: followUpNeeded,
        followUpNotes: followUpCtrl.text.trim().isEmpty ? null : followUpCtrl.text.trim(),
      );
      _snack('บันทึกการเยี่ยมบ้านแล้ว');
      await _loadAll();
    } catch (e) {
      debugPrint('createHomeVisit failed: $e');
      _snack('บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  // ------------------------------------------------------------------
  // SDQ
  // ------------------------------------------------------------------
  Widget _sdqTab() {
    final rows = _sdq;
    return _tabScaffold(
      loading: rows == null,
      empty: rows != null && rows.isEmpty,
      emptyText: 'ยังไม่มีการประเมิน SDQ',
      addLabel: '+ ประเมิน SDQ',
      onAdd: _openRecordSdq,
      footer: 'คะแนนดิบสำหรับคัดกรองเบื้องต้นตามโครงสร้าง 5 มิติของ SDQ ไม่ใช่ผลวินิจฉัย '
          'ควรให้ผู้เชี่ยวชาญ/ฝ่ายแนะแนวตีความก่อนใช้ประกอบการตัดสินใจ',
      children: [
        for (final r in rows ?? const <SchoolSdqSummaryRow>[])
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _softCard,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.studentName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateLabel(r.assessmentDate),
                        style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.totalDifficultiesScore}/40',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const Text(
                      'คะแนนรวม',
                      style: TextStyle(fontSize: 9, color: AppPalette.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  static const _sdqItems = [
    // Emotional (1-5)
    'บ่นปวดหัว ปวดท้อง หรือไม่สบายบ่อยๆ โดยไม่มีสาเหตุชัดเจน',
    'วิตกกังวลง่าย ดูกระวนกระวายบ่อย',
    'ไม่มีความสุข ท้อแท้ หรือร้องไห้บ่อย',
    'ประหม่าในสถานการณ์ใหม่ๆ ขาดความมั่นใจในตนเองง่าย',
    'มีความกลัวหลายอย่าง หรือตกใจง่าย',
    // Conduct (6-10)
    'โมโหฉุนเฉียวบ่อย อารมณ์รุนแรง',
    'มักเชื่อฟังผู้ใหญ่ (คะแนนสูง = ไม่ค่อยเชื่อฟัง)',
    'ทะเลาะวิวาทกับเพื่อนหรือรังแกผู้อื่นบ่อย',
    'พูดโกหกหรือขี้โกงบ่อย',
    'ขโมยของที่บ้าน โรงเรียน หรือที่อื่นๆ',
    // Hyperactivity (11-15)
    'อยู่ไม่นิ่ง กระสับกระส่าย นั่งนิ่งนานๆ ไม่ได้',
    'อยู่ไม่สุข ขยับตัวตลอดเวลา',
    'วอกแวกง่าย สมาธิสั้น',
    'คิดก่อนทำได้ยาก หุนหันพลันแล่น',
    'ทำงานที่ได้รับมอบหมายจนจบได้ยาก',
    // Peer problems (16-20)
    'ค่อนข้างอยู่คนเดียว มักเล่นคนเดียว',
    'มีเพื่อนสนิทอย่างน้อยหนึ่งคน (คะแนนสูง = ไม่มี)',
    'เพื่อนวัยเดียวกันมักไม่ชอบ/ไม่อยากเล่นด้วย',
    'ถูกเพื่อนแกล้งหรือรังแกบ่อย',
    'เข้ากับผู้ใหญ่ได้ดีกว่าเด็กวัยเดียวกัน',
    // Prosocial (21-25)
    'ใส่ใจความรู้สึกของผู้อื่น',
    'แบ่งปันสิ่งของกับผู้อื่นเต็มใจ',
    'ช่วยเหลือเมื่อมีคนเจ็บ เสียใจ หรือไม่สบายใจ',
    'มีน้ำใจกับเด็กที่อายุน้อยกว่า',
    'อาสาช่วยเหลือผู้อื่น (ผู้ปกครอง ครู เด็กคนอื่น) บ่อย',
  ];

  Future<void> _openRecordSdq() async {
    final student = await _pickStudent();
    if (student == null || !mounted) return;
    final scores = List<int>.filled(25, 0);
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ประเมิน SDQ · ${student.studentName}'),
          content: SizedBox(
            width: 560,
            height: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ให้คะแนนแต่ละข้อ 0 = ไม่จริง · 1 = ค่อนข้างจริง · 2 = จริงแน่นอน',
                    style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _sdqItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '${i + 1}. ${_sdqItems[i]}',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('0')),
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                            ],
                            selected: {scores[i]},
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            onSelectionChanged: (sel) =>
                                setDialogState(() => scores[i] = sel.first),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'บันทึกเพิ่มเติม'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('บันทึกผลประเมิน'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final result = await (widget.recordSdq ??
          ({required studentId, required itemScores, raterType = 'teacher', notes}) =>
              StudentFollowupService.recordSdqAssessment(
                studentId: studentId,
                itemScores: itemScores,
                raterType: raterType,
                notes: notes,
              ))(
        studentId: student.studentId,
        itemScores: scores,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      _snack('บันทึกผล SDQ แล้ว — คะแนนรวม ${result.totalDifficultiesScore}/40');
      await _loadAll();
    } catch (e) {
      debugPrint('recordSdq failed: $e');
      _snack('บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  // ------------------------------------------------------------------
  // Scholarships
  // ------------------------------------------------------------------
  Widget _scholarshipTab() {
    final scholarships = _scholarships;
    final awards = _awards ?? const <ScholarshipAward>[];
    return _tabScaffold(
      loading: scholarships == null,
      empty: scholarships != null && scholarships.isEmpty,
      emptyText: 'ยังไม่มีทุนการศึกษาในระบบ',
      addLabel: '+ เพิ่มทุนการศึกษา',
      onAdd: _openCreateScholarship,
      children: [
        for (final s in scholarships ?? const <Scholarship>[])
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _softCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _openNominateAward(s),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('เสนอชื่อนักเรียน', style: TextStyle(fontSize: 10.5)),
                    ),
                  ],
                ),
                if (s.sponsor != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ผู้สนับสนุน: ${s.sponsor}',
                    style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                  ),
                ],
                if (s.amountThb != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'จำนวนเงิน: ${s.amountThb!.toStringAsFixed(0)} บาท',
                    style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${s.awardCount} คนเสนอชื่อแล้ว',
                  style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
                ),
                for (final a in awards.where((a) => a.scholarshipId == s.scholarshipId)) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text(a.studentName, style: const TextStyle(fontSize: 11.5))),
                      _pillBadge(a.statusLabel, _awardStatusColor(a.status)),
                      const SizedBox(width: 6),
                      if (a.status == 'applied')
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 16),
                          onSelected: (status) => _updateAwardStatus(a, status),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'approved', child: Text('อนุมัติ')),
                            PopupMenuItem(value: 'rejected', child: Text('ไม่อนุมัติ')),
                          ],
                        )
                      else if (a.status == 'approved')
                        TextButton(
                          onPressed: () => _updateAwardStatus(a, 'disbursed'),
                          child: const Text('เบิกจ่ายแล้ว', style: TextStyle(fontSize: 10.5)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Color _awardStatusColor(String status) => switch (status) {
    'approved' => AppPalette.success,
    'disbursed' => AppPalette.learningBlueDark,
    'rejected' => AppPalette.danger,
    _ => AppPalette.warning,
  };

  Future<void> _updateAwardStatus(ScholarshipAward a, String status) async {
    try {
      await (widget.setAwardStatus ??
          ({required awardId, required status, awardedAmountThb, notes}) =>
              StudentFollowupService.setScholarshipAwardStatus(
                awardId: awardId,
                status: status,
                awardedAmountThb: awardedAmountThb,
                notes: notes,
              ))(
        awardId: a.awardId,
        status: status,
        awardedAmountThb: status == 'approved' ? a.awardedAmountThb : null,
      );
      _snack('อัปเดตสถานะทุนแล้ว');
      await _loadAll();
    } catch (e) {
      debugPrint('setAwardStatus failed: $e');
      _snack('อัปเดตไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Future<void> _openCreateScholarship() async {
    final nameCtrl = TextEditingController();
    final sponsorCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('เพิ่มทุนการศึกษา'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ชื่อทุน *'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(controller: sponsorCtrl, decoration: const InputDecoration(labelText: 'ผู้สนับสนุน')),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'จำนวนเงิน (บาท)'),
                ),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'รายละเอียด')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: nameCtrl.text.trim().isEmpty ? null : () => Navigator.pop(dialogCtx, true),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await (widget.createScholarship ??
          ({required name, sponsor, amountThb, description}) =>
              StudentFollowupService.createScholarship(
                name: name,
                sponsor: sponsor,
                amountThb: amountThb,
                description: description,
              ))(
        name: nameCtrl.text.trim(),
        sponsor: sponsorCtrl.text.trim().isEmpty ? null : sponsorCtrl.text.trim(),
        amountThb: double.tryParse(amountCtrl.text.trim()),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      );
      _snack('เพิ่มทุนการศึกษาแล้ว');
      await _loadAll();
    } catch (e) {
      debugPrint('createScholarship failed: $e');
      _snack('บันทึกไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  Future<void> _openNominateAward(Scholarship s) async {
    final student = await _pickStudent();
    if (student == null || !mounted) return;
    try {
      await (widget.nominateAward ??
          ({required scholarshipId, required studentId, notes}) =>
              StudentFollowupService.nominateScholarshipAward(
                scholarshipId: scholarshipId,
                studentId: studentId,
              ))(scholarshipId: s.scholarshipId, studentId: student.studentId);
      _snack('เสนอชื่อ ${student.studentName} แล้ว');
      await _loadAll();
    } catch (e) {
      debugPrint('nominateAward failed: $e');
      _snack('เสนอชื่อไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  // ------------------------------------------------------------------
  // Executive directives
  // ------------------------------------------------------------------
  Widget _directiveTab() {
    final directives = _directives;
    return _tabScaffold(
      loading: directives == null,
      empty: directives != null && directives.isEmpty,
      emptyText: 'ยังไม่มีคำสั่งติดตามที่มอบหมาย',
      addLabel: '+ สั่งการติดตาม',
      onAdd: _openCreateDirective,
      children: [
        for (final d in directives ?? const <ExecutiveDirective>[])
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _softCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    _pillBadge(
                      d.statusLabel,
                      d.status == 'completed'
                          ? AppPalette.success
                          : (d.isOverdue ? AppPalette.danger : AppPalette.warning),
                    ),
                  ],
                ),
                if (d.instructions?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(d.instructions!, style: const TextStyle(fontSize: 11.5)),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    if (d.studentName != null) 'นักเรียน: ${d.studentName}',
                    'มอบหมายให้: ${d.counterpartyName}',
                    if (d.dueDate != null) 'กำหนด: ${_dateLabel(d.dueDate!)}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openCreateDirective() async {
    final staff = await _staff();
    if (!mounted) return;
    final teachers = staff.where((s) => s.hasRole('teacher')).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (teachers.isEmpty) {
      _snack('ไม่พบครูในระบบที่มอบหมายได้');
      return;
    }
    SchoolStudentOption? student;
    String? assignedTo;
    final titleCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    DateTime? dueDate;

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('สั่งการติดตาม'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await _pickStudent();
                      if (picked != null) setDialogState(() => student = picked);
                    },
                    child: Text(student == null ? 'เลือกนักเรียน (ถ้ามี)' : student!.label),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: assignedTo,
                    isExpanded: true,
                    hint: const Text('มอบหมายให้ครู'),
                    items: [
                      for (final t in teachers)
                        DropdownMenuItem(value: t.userId, child: Text(t.fullName)),
                    ],
                    onChanged: (v) => setDialogState(() => assignedTo = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'หัวข้อคำสั่ง *'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: instructionsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'รายละเอียด/สิ่งที่ต้องทำ'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => dueDate = picked);
                    },
                    icon: const Icon(Icons.event_rounded, size: 14),
                    label: Text(dueDate == null ? 'กำหนดวันครบกำหนด' : _dateLabel(dueDate!)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: (assignedTo == null || titleCtrl.text.trim().isEmpty)
                  ? null
                  : () => Navigator.pop(dialogCtx, true),
              child: const Text('สั่งการ'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted || assignedTo == null) return;
    try {
      await (widget.createDirective ??
          ({required assignedTo, required title, instructions, studentId, dueDate}) =>
              StudentFollowupService.createDirective(
                assignedTo: assignedTo,
                title: title,
                instructions: instructions,
                studentId: studentId,
                dueDate: dueDate,
              ))(
        assignedTo: assignedTo!,
        title: titleCtrl.text.trim(),
        instructions: instructionsCtrl.text.trim().isEmpty ? null : instructionsCtrl.text.trim(),
        studentId: student?.studentId,
        dueDate: dueDate,
      );
      _snack('สั่งการติดตามแล้ว');
      await _loadAll();
    } catch (e) {
      debugPrint('createDirective failed: $e');
      _snack('สั่งการไม่สำเร็จ ลองอีกครั้ง');
    }
  }

  // ------------------------------------------------------------------
  // Shared helpers
  // ------------------------------------------------------------------
  Future<SchoolStudentOption?> _pickStudent() async {
    var options = await _students(null);
    if (!mounted) return null;
    return showDialog<SchoolStudentOption>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('เลือกนักเรียน'),
          content: SizedBox(
            width: 420,
            height: 420,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'ค้นหาชื่อนักเรียน',
                  ),
                  onChanged: (q) async {
                    final results = await _students(q);
                    setDialogState(() => options = results);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: options.isEmpty
                      ? const Center(child: Text('ไม่พบนักเรียน'))
                      : ListView.builder(
                          itemCount: options.length,
                          itemBuilder: (_, i) => ListTile(
                            title: Text(options[i].studentName),
                            subtitle: options[i].room != null ? Text(options[i].room!) : null,
                            onTap: () => Navigator.pop(dialogCtx, options[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('ยกเลิก')),
          ],
        ),
      ),
    );
  }

  Widget _pillBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppPalette.tint(color, 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _tabScaffold({
    required bool loading,
    required bool empty,
    required String emptyText,
    required String addLabel,
    required VoidCallback onAdd,
    required List<Widget> children,
    String? footer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(onPressed: onAdd, child: Text(addLabel)),
        ),
        const SizedBox(height: 10),
        if (footer != null) ...[
          Text(footer, style: const TextStyle(fontSize: 10, color: AppPalette.textMuted)),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : empty
                  ? Center(
                      child: Text(emptyText, style: const TextStyle(color: AppPalette.textMuted)),
                    )
                  : ListView(children: children),
        ),
      ],
    );
  }
}
