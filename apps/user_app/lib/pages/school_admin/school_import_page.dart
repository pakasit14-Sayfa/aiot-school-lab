import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

enum _ImportSource { file, googleSheets }

class SchoolImportPage extends StatefulWidget {
  const SchoolImportPage({super.key});

  @override
  State<SchoolImportPage> createState() => _SchoolImportPageState();
}

class _SchoolImportPageState extends State<SchoolImportPage> {
  /// 🔐 การนำเข้า "นักเรียน" และ "ครูและบุคลากร" ถูกปิดไว้
  ///
  /// ตรวจกับฐานข้อมูลที่รันอยู่เมื่อ 2026-09-07 พบว่าเส้นทางนี้สร้างบัญชีที่
  /// เข้าใช้งานได้ทันทีด้วยรหัสผ่านที่เดาได้ ครบทั้งสามชั้น:
  ///   1. `import_school_users_batch_for_school_admin` ตั้งรหัสเป็น
  ///      `crypt('Test1234!', ...)` เหมือนกันทุกคน
  ///   2. คำสั่ง INSERT ไม่ตั้ง `must_change_password` และค่า default คือ false
  ///   3. ไม่มีโค้ด Dart ที่ไหนในทั้ง repo อ่าน `must_change_password` เลย
  ///      แปลว่าไม่มีการบังคับเปลี่ยนรหัสอยู่จริง
  /// บัญชีถูกสร้างเป็น `status = 'active'` ด้วย
  ///
  /// ผลคือ นำเข้านักเรียน 500 คน = 500 บัญชีที่ใครรู้อีเมลก็ล็อกอินแทนได้
  ///
  /// ทำตามมติที่บันทึกไว้ใน task_plan §"Security defects": ถ้ายังไม่มีเส้นทาง
  /// ส่งมอบ/รีเซ็ตรหัสที่สมบูรณ์ ให้ปิดการนำเข้าผู้ใช้ไว้ก่อน ดีกว่าแจกรหัส
  /// ที่เดาได้ การนำเข้าอาคาร/ห้อง/อุปกรณ์/ชุดฝึกไม่สร้างบัญชี จึงยังใช้ได้ปกติ
  static const Set<String> _credentialCreatingTypes = {
    'นักเรียน',
    'ครูและบุคลากร',
  };

  bool get _importBlocked => _credentialCreatingTypes.contains(_dataType);

  String _dataType = 'อาคารและห้อง';
  _ImportSource _source = _ImportSource.file;

  final TextEditingController _sheetUrlController = TextEditingController();
  final SchoolAdminPlatformService _platformService =
      SchoolAdminPlatformService();

  String? _selectedFileName;
  bool _hasPreview = false;
  bool _isImporting = false;
  bool _isLoadingSource = false;

  List<ImportPreviewRow> _validatedRows = [];
  List<String> _existingBuildingCodes = [];

  /// โหลดรายชื่ออาคารเดิมไม่สำเร็จ — ผลตรวจสอบจะเชื่อถือไม่ได้ ต้องบอกผู้ใช้
  /// ไม่ใช่ปล่อยให้เข้าใจว่าไฟล์ตัวเองผิด
  bool _buildingCodesFailed = false;

  final List<_ImportLogRecord> _logs = [];

  @override
  void dispose() {
    _sheetUrlController.dispose();
    super.dispose();
  }

  List<_PreviewRow> get _previewRows => _validatedRows
      .map(
        (r) => _PreviewRow(
          row: '${r.rowNumber}',
          code: r.code,
          name: r.name,
          detail: r.detail,
          status: switch (r.status) {
            ImportRowStatus.ready => 'พร้อมนำเข้า',
            ImportRowStatus.warning => 'คำเตือน',
            ImportRowStatus.needsFix => 'ต้องแก้ไข',
          },
        ),
      )
      .toList();

  int get _readyCount =>
      _validatedRows.where((row) => row.status == ImportRowStatus.ready).length;

  int get _errorCount => _validatedRows
      .where((row) => row.status == ImportRowStatus.needsFix)
      .length;

  int get _warningCount => _validatedRows
      .where((row) => row.status == ImportRowStatus.warning)
      .length;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetImport() {
    setState(() {
      _selectedFileName = null;
      _sheetUrlController.clear();
      _hasPreview = false;
      _isImporting = false;
      _validatedRows = [];
    });
  }

  /// Real building codes for this school, used to validate อาคารและห้อง room
  /// rows that reference a building already saved in the system (as opposed
  /// to one being created in the same file).
  Future<void> _refreshExistingBuildingCodesIfNeeded() async {
    if (_dataType != 'อาคารและห้อง') return;
    try {
      final buildings = await _platformService.fetchBuildings();
      _existingBuildingCodes = buildings.map((b) => b.code).toList();
      _buildingCodesFailed = false;
    } catch (e) {
      // เดิม `catch (_)` ตั้งลิสต์เป็นว่างเงียบ ๆ ซึ่งอันตรายกว่าที่เห็น:
      // การตรวจสอบใช้ลิสต์นี้ยืนยันว่าห้องอ้างอิงอาคารที่มีอยู่จริงหรือไม่
      // พอลิสต์ว่าง ทุกแถวที่อ้างอาคารเดิมจะถูกตัดสินว่า "ต้องแก้ไข" และ
      // ผู้ดูแลจะเข้าใจว่าไฟล์ตัวเองผิด ทั้งที่ความจริงคือระบบโหลดไม่ได้
      debugPrint('fetchBuildings failed during import validation: $e');
      _existingBuildingCodes = [];
      _buildingCodesFailed = true;
    }
  }

  Future<void> _applyParsedRows(
    List<Map<String, String>> rawRows, {
    required String sourceLabel,
  }) async {
    if (rawRows.isEmpty) {
      _showMessage(
        'ไม่พบข้อมูลในไฟล์นี้ (ต้องมีหัวคอลัมน์และอย่างน้อย 1 แถวข้อมูล)',
      );
      return;
    }

    await _refreshExistingBuildingCodesIfNeeded();

    final validated = SchoolImportService.validateRows(
      _dataType,
      rawRows,
      existingBuildingCodes: _existingBuildingCodes,
    );

    if (!mounted) return;
    setState(() {
      _selectedFileName = sourceLabel;
      _validatedRows = validated;
      _hasPreview = true;
    });

    if (_buildingCodesFailed) {
      _showMessage(
        'โหลดรายชื่ออาคารเดิมไม่สำเร็จ — ผลตรวจสอบห้องที่อ้างอิงอาคารเดิม'
        'อาจไม่ถูกต้อง กรุณาลองใหม่ก่อนนำเข้า',
      );
    }
  }

  Future<void> _pickFile() async {
    if (_isLoadingSource) return;
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      _showMessage('ไม่สามารถอ่านไฟล์นี้ได้');
      return;
    }

    setState(() => _isLoadingSource = true);
    try {
      final rawRows = SchoolImportService.parseFile(bytes, picked.name);
      await _applyParsedRows(rawRows, sourceLabel: picked.name);
    } catch (e) {
      _showMessage('อ่านไฟล์ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSource = false);
    }
  }

  Future<void> _loadGoogleSheet() async {
    final String url = _sheetUrlController.text.trim();

    if (url.isEmpty) {
      _showMessage('กรุณาวางลิงก์ Google Sheets ก่อน');
      return;
    }

    setState(() => _isLoadingSource = true);
    try {
      final rawRows = await SchoolImportService.fetchGoogleSheetCsv(url);
      await _applyParsedRows(rawRows, sourceLabel: 'Google Sheets');
    } catch (e) {
      _showMessage(
        'โหลดข้อมูลจาก Google Sheets ไม่สำเร็จ: $e '
        '(รองรับเฉพาะลิงก์ที่เผยแพร่แบบ CSV จาก File > Share > Publish to web)',
      );
    } finally {
      if (mounted) setState(() => _isLoadingSource = false);
    }
  }

  void _downloadTemplate() {
    final bytes = SchoolImportService.buildTemplateCsv(_dataType);
    FilePicker.platform.saveFile(
      fileName: 'แบบฟอร์มนำเข้า_$_dataType.csv',
      bytes: bytes,
    );
  }

  Future<void> _startImport() async {
    // ด่านที่สอง นอกเหนือจากปุ่มที่ถูก disable ไว้ — กันไม่ให้เส้นทางสร้าง
    // บัญชีถูกเรียกจากทางอื่นโดยไม่ตั้งใจ
    if (_importBlocked) {
      _showMessage(
        'ยังนำเข้าบัญชีผู้ใช้ไม่ได้ — ระบบยังตั้งรหัสผ่านเริ่มต้นเหมือนกันทุกบัญชี',
      );
      return;
    }

    if (!_hasPreview) {
      _showMessage('กรุณาเลือกไฟล์หรือโหลด Google Sheets ก่อน');
      return;
    }

    if (_errorCount > 0) {
      final bool? continueImport = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('พบข้อมูลที่ต้องแก้ไข'),
            content: Text(
              'พบ $_errorCount รายการที่ไม่สามารถนำเข้าได้ '
              'ระบบจะนำเข้าเฉพาะรายการที่ผ่านการตรวจสอบ ต้องการดำเนินการต่อหรือไม่',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('กลับไปตรวจสอบ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('นำเข้ารายการที่ผ่าน'),
              ),
            ],
          );
        },
      );

      if (continueImport != true) return;
    }

    setState(() => _isImporting = true);

    final rowsToSend = _validatedRows
        .where((r) => r.status != ImportRowStatus.needsFix)
        .toList();

    int inserted = 0;
    List<SkippedRow> skipped = const [];
    String? errorMessage;

    try {
      switch (_dataType) {
        case 'อาคารและห้อง':
          final buildingRows = rowsToSend
              .where((r) => r.rowType == 'อาคาร')
              .map((r) => r.payload)
              .toList();
          final roomRows = rowsToSend
              .where((r) => r.rowType == 'ห้อง')
              .map((r) => r.payload)
              .toList();

          if (buildingRows.isNotEmpty) {
            final res = await _platformService.importBuildingsBatch(
              buildingRows,
            );
            inserted += res.insertedCount;
            skipped = [...skipped, ...res.skipped];
          }
          if (roomRows.isNotEmpty) {
            final res = await _platformService.importRoomsBatch(roomRows);
            inserted += res.insertedCount;
            skipped = [...skipped, ...res.skipped];
          }
          break;

        case 'อุปกรณ์':
        case 'ชุดฝึก':
          final payload = rowsToSend.map((r) => r.payload).toList();
          if (payload.isNotEmpty) {
            final res = await _platformService.importDevicesBatch(payload);
            inserted = res.insertedCount;
            skipped = res.skipped;
          }
          break;

        default:
          final role = _dataType == 'ครูและบุคลากร'
              ? UserRole.teacher
              : UserRole.student;
          final payload = rowsToSend.map((r) => r.payload).toList();
          if (payload.isNotEmpty) {
            inserted = await UserAdminService.importSchoolUsersBatch(
              role: role,
              users: payload,
            );
          }
      }
    } catch (e) {
      // ไม่โยน e.toString() ขึ้นจอ — เดิมข้อความ error ดิบจากฐานข้อมูลถูก
      // แสดงตรง ๆ ให้ผู้ดูแลเห็น
      debugPrint('SchoolImportPage import failed: $e');
      errorMessage = 'นำเข้าไม่สำเร็จ กรุณาตรวจสอบไฟล์แล้วลองใหม่';
    }

    if (!mounted) return;

    final int totalFailed = _errorCount + skipped.length;

    setState(() {
      _isImporting = false;
      _logs.insert(
        0,
        _ImportLogRecord(
          date:
              'วันนี้ ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} น.',
          // เดิม hardcode 'ผู้ดูแลโรงเรียน' ทุกแถว ทำให้ประวัติไม่บอกว่าใครทำจริง
          user: currentUserModel?.name.isNotEmpty == true
              ? currentUserModel!.name
              : 'ยังไม่มีข้อมูล',
          dataType: _dataType,
          source: _source == _ImportSource.file
              ? (_selectedFileName?.toLowerCase().endsWith('.csv') == true
                    ? 'CSV'
                    : 'Excel')
              : 'Google Sheets',
          fileName: _source == _ImportSource.file
              ? (_selectedFileName ?? 'ไฟล์นำเข้า')
              : 'Google Sheets',
          total: _validatedRows.length,
          success: inserted,
          failed: totalFailed,
          status: errorMessage != null
              ? 'ผิดพลาด'
              : (totalFailed == 0 ? 'สำเร็จ' : 'เสร็จสิ้น'),
        ),
      );
    });

    if (errorMessage != null) {
      _showMessage(errorMessage);
      return;
    }

    final skipReasons = skipped
        .map((s) => SkippedRow.reasonLabel(s.reason))
        .toSet()
        .join(', ');
    final skipNote = skipped.isEmpty
        ? (_errorCount > 0 ? ' และข้าม $_errorCount รายการที่มีปัญหา' : '')
        : ' และข้าม ${skipped.length} รายการ ($skipReasons)';

    _showMessage('นำเข้า $inserted รายการเรียบร้อย$skipNote');
  }

  void _showLogDetail(_ImportLogRecord log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: SchoolAdminPalette.primarySoft,
                            child: Icon(
                              Icons.history_rounded,
                              color: SchoolAdminPalette.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'รายละเอียด Log การนำเข้า',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: SchoolAdminPalette.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ImportDetailRow(
                        label: 'วันและเวลา',
                        value: log.date,
                        icon: Icons.schedule_rounded,
                      ),
                      _ImportDetailRow(
                        label: 'ผู้ดำเนินการ',
                        value: log.user,
                        icon: Icons.person_rounded,
                      ),
                      _ImportDetailRow(
                        label: 'ประเภทข้อมูล',
                        value: log.dataType,
                        icon: Icons.category_rounded,
                      ),
                      _ImportDetailRow(
                        label: 'แหล่งข้อมูล',
                        value: log.source,
                        icon: Icons.source_rounded,
                      ),
                      _ImportDetailRow(
                        label: 'ชื่อไฟล์ / ชีต',
                        value: log.fileName,
                        icon: Icons.description_rounded,
                      ),
                      _ImportDetailRow(
                        label: 'ข้อมูลทั้งหมด',
                        value: '${log.total} รายการ',
                        icon: Icons.list_alt_rounded,
                      ),
                      _ImportDetailRow(
                        label: 'นำเข้าสำเร็จ',
                        value: '${log.success} รายการ',
                        icon: Icons.check_circle_rounded,
                      ),
                      _ImportDetailRow(
                        label: 'ไม่สำเร็จ',
                        value: '${log.failed} รายการ',
                        icon: Icons.error_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: SchoolAdminPalette.border),
                        ),
                        child: const Text(
                          'ระบบจะเก็บ Log การนำเข้าไว้เพื่อใช้ตรวจสอบย้อนหลัง '
                          'รวมถึงผู้ดำเนินการ เวลา ประเภทข้อมูล และผลการนำเข้า',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.5,
                            color: SchoolAdminPalette.textSecondary,
                          ),
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
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildImportWorkspace(),
                  const SizedBox(height: 14),
                  if (_hasPreview) ...[
                    _buildValidationSummary(),
                    const SizedBox(height: 14),
                    _buildPreview(),
                    const SizedBox(height: 14),
                  ],
                  _buildRecentLogs(),
                  const SizedBox(height: 14),
                  _buildGuide(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget title = const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: SchoolAdminPalette.primarySoft,
                    child: Icon(
                      Icons.upload_file_rounded,
                      color: SchoolAdminPalette.primaryDark,
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'นำเข้าข้อมูล',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'เพิ่มข้อมูลจำนวนมากจาก Excel, CSV หรือ Google Sheets '
                          'พร้อมตรวจสอบความถูกต้องก่อนบันทึกเข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.45,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final Widget actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('ดาวน์โหลดแบบฟอร์ม'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetImport,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('เริ่มใหม่'),
                  ),
                ],
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 14), actions],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 14),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final int importedTotal = _logs.fold<int>(
      0,
      (sum, log) => sum + log.success,
    );

    final int failedTotal = _logs.fold<int>(0, (sum, log) => sum + log.failed);

    final List<_ImportSummaryData> items = [
      _ImportSummaryData(
        title: 'นำเข้าล่าสุด',
        value: _logs.isNotEmpty ? _logs.first.date.split(' ').last : '-',
        detail: _logs.isNotEmpty
            ? '${_logs.first.dataType} • ${_logs.first.success} รายการ'
            : 'ยังไม่มีประวัติการนำเข้า',
        icon: Icons.schedule_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _ImportSummaryData(
        title: 'นำเข้าสำเร็จทั้งหมด',
        value: '$importedTotal',
        detail: 'จากประวัติการนำเข้าล่าสุด',
        icon: Icons.check_circle_rounded,
        color: SchoolAdminPalette.green,
      ),
      _ImportSummaryData(
        title: 'รายการที่มีปัญหา',
        value: '$failedTotal',
        detail: 'สามารถตรวจสอบย้อนหลังจาก Log',
        icon: Icons.warning_amber_rounded,
        color: SchoolAdminPalette.red,
      ),
      _ImportSummaryData(
        title: 'Log ล่าสุด',
        value: '${_logs.length}',
        detail: 'รายการประวัติที่แสดงในหน้านี้',
        icon: Icons.history_rounded,
        color: const Color(0xFF4F6078),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 300) columns = 1;

        const double spacing = 12;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_ImportSummaryData item) {
            return SizedBox(
              width: width,
              child: _ImportSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildImportWorkspace() {
    return _ImportSectionCard(
      title: 'นำเข้าข้อมูลใหม่',
      subtitle: 'ทำตามขั้นตอนจากซ้ายไปขวา ระบบจะตรวจข้อมูลก่อนนำเข้าจริง',
      child: Column(
        children: [
          _buildStepOne(),
          const SizedBox(height: 12),
          _buildStepTwo(),
          const SizedBox(height: 12),
          _buildStepThree(),
        ],
      ),
    );
  }

  Widget _buildStepOne() {
    return _ImportStepCard(
      step: '1',
      title: 'เลือกประเภทข้อมูล',
      subtitle: 'เลือกว่ากำลังจะเพิ่มข้อมูลประเภทใด',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            [
              'นักเรียน',
              'ครูและบุคลากร',
              'อาคารและห้อง',
              'อุปกรณ์',
              'ชุดฝึก',
            ].map((String type) {
              final bool selected = _dataType == type;
              final bool blocked = _credentialCreatingTypes.contains(type);

              // ยังเลือกดูได้ เพื่อให้เห็นว่าฟีเจอร์มีอยู่และทำไมถึงปิด — แต่
              // ขั้นตอนนำเข้าจริงจะถูกล็อกไว้ในขั้นที่ 4
              return ChoiceChip(
                label: Text(blocked ? '$type (ปิดชั่วคราว)' : type),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _dataType = type;
                    _hasPreview = false;
                    _selectedFileName = null;
                    _validatedRows = [];
                  });
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildStepTwo() {
    return _ImportStepCard(
      step: '2',
      title: 'เลือกแหล่งข้อมูล',
      subtitle: 'รองรับไฟล์ Excel / CSV และลิงก์ Google Sheets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<_ImportSource>(
            segments: const [
              ButtonSegment<_ImportSource>(
                value: _ImportSource.file,
                label: Text('Excel / CSV'),
                icon: Icon(Icons.description_rounded),
              ),
              ButtonSegment<_ImportSource>(
                value: _ImportSource.googleSheets,
                label: Text('Google Sheets'),
                icon: Icon(Icons.table_chart_rounded),
              ),
            ],
            selected: {_source},
            onSelectionChanged: (Set<_ImportSource> value) {
              setState(() {
                _source = value.first;
                _hasPreview = false;
                _selectedFileName = null;
                _validatedRows = [];
              });
            },
          ),
          const SizedBox(height: 14),
          if (_source == _ImportSource.file)
            _FileUploadBox(fileName: _selectedFileName, onSelectFile: _pickFile)
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sheetUrlController,
                    decoration: const InputDecoration(
                      labelText: 'ลิงก์ Google Sheets',
                      hintText: 'https://docs.google.com/spreadsheets/...',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _isLoadingSource ? null : _loadGoogleSheet,
                  icon: _isLoadingSource
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_rounded),
                  label: const Text('โหลดข้อมูล'),
                ),
              ],
            ),
          if (_isLoadingSource && _source == _ImportSource.file) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'กำลังอ่านและตรวจสอบไฟล์...',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    final String statusText = !_hasPreview
        ? 'รอเลือกข้อมูล'
        : _errorCount > 0
        ? 'พบข้อมูลที่ต้องตรวจสอบ'
        : 'พร้อมนำเข้า';

    final Color statusColor = !_hasPreview
        ? SchoolAdminPalette.textMuted
        : _errorCount > 0
        ? SchoolAdminPalette.red
        : SchoolAdminPalette.green;

    return _ImportStepCard(
      step: '3',
      title: 'ตรวจสอบและนำเข้า',
      subtitle: 'ตรวจดูตัวอย่างข้อมูลและผลการตรวจสอบก่อนบันทึกเข้าสู่ระบบ',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget status = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SchoolAdminPalette.border),
            ),
            child: Row(
              children: [
                Icon(
                  _hasPreview
                      ? (_errorCount > 0
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded)
                      : Icons.hourglass_empty_rounded,
                  color: statusColor,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สถานะ',
                        style: TextStyle(
                          fontSize: 9,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final Widget button = _importBlocked
              ? Tooltip(
                  message:
                      'ปิดไว้ด้วยเหตุผลด้านความปลอดภัย — ระบบยังตั้งรหัสผ่าน'
                      'เริ่มต้นเหมือนกันทุกบัญชีและยังไม่มีการบังคับเปลี่ยนรหัส '
                      'จึงยังนำเข้าบัญชีผู้ใช้ไม่ได้',
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('ปิดชั่วคราวด้วยเหตุผลด้านความปลอดภัย'),
                  ),
                )
              : FilledButton.icon(
                  onPressed: _isImporting ? null : _startImport,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_rounded),
                  label: Text(
                    _isImporting ? 'กำลังนำเข้า...' : 'เริ่มนำเข้าข้อมูล',
                  ),
                );

          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [status, const SizedBox(height: 10), button],
            );
          }

          return Row(
            children: [
              Expanded(child: status),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildValidationSummary() {
    final List<_ValidationData> items = [
      _ValidationData(
        title: 'ข้อมูลทั้งหมด',
        value: '${_previewRows.length}',
        detail: 'รายการที่ตรวจพบ',
        icon: Icons.list_alt_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _ValidationData(
        title: 'พร้อมนำเข้า',
        value: '$_readyCount',
        detail: 'ผ่านการตรวจสอบ',
        icon: Icons.check_circle_rounded,
        color: SchoolAdminPalette.green,
      ),
      _ValidationData(
        title: 'คำเตือน',
        value: '$_warningCount',
        detail: 'นำเข้าได้แต่ควรตรวจดู',
        icon: Icons.info_outline_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _ValidationData(
        title: 'ต้องแก้ไข',
        value: '$_errorCount',
        detail: 'ระบบจะไม่นำเข้ารายการนี้',
        icon: Icons.error_outline_rounded,
        color: SchoolAdminPalette.red,
      ),
    ];

    return _ImportSectionCard(
      title: 'ผลการตรวจสอบข้อมูล',
      subtitle:
          'ระบบตรวจรหัสซ้ำ ช่องบังคับ ความสัมพันธ์ของข้อมูล และรูปแบบเบื้องต้น',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 4;
          if (constraints.maxWidth < 850) columns = 2;

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((_ValidationData item) {
              return SizedBox(
                width: width,
                child: _ValidationCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    return _ImportSectionCard(
      title: 'ตัวอย่างข้อมูลก่อนนำเข้า',
      subtitle: 'แสดงข้อมูลบางส่วนเพื่อให้ตรวจสอบก่อนบันทึกจริงเข้าสู่ระบบ',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= 850) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll<Color>(
                  Color(0xFFF8FAFC),
                ),
                headingTextStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
                columns: const [
                  DataColumn(label: Text('แถว')),
                  DataColumn(label: Text('รหัส')),
                  DataColumn(label: Text('ชื่อ / รายการ')),
                  DataColumn(label: Text('รายละเอียด')),
                  DataColumn(label: Text('ผลตรวจ')),
                ],
                rows: _previewRows.map((_PreviewRow row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row.row)),
                      DataCell(Text(row.code)),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            row.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            row.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(_ImportStatusBadge(status: row.status)),
                    ],
                  );
                }).toList(),
              ),
            );
          }

          return Column(
            children: _previewRows.map((_PreviewRow row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PreviewMobileCard(row: row),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRecentLogs() {
    return _ImportSectionCard(
      title: 'Log การใช้งานล่าสุด',
      subtitle: 'ประวัติการนำเข้าข้อมูลล่าสุด พร้อมผู้ดำเนินการและผลการนำเข้า',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 36,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ยังไม่มีประวัติการนำเข้าข้อมูลในระบบ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'เมื่อมีการอัปโหลดและนำเข้าข้อมูล รายการประวัติจะแสดงที่นี่',
                    style: TextStyle(
                      fontSize: 11,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 920) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: const WidgetStatePropertyAll<Color>(
                        Color(0xFFF8FAFC),
                      ),
                      headingTextStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                      ),
                      dataTextStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                      ),
                      columns: const [
                        DataColumn(label: Text('วันและเวลา')),
                        DataColumn(label: Text('ผู้ใช้งาน')),
                        DataColumn(label: Text('ประเภทข้อมูล')),
                        DataColumn(label: Text('แหล่งข้อมูล')),
                        DataColumn(label: Text('ทั้งหมด')),
                        DataColumn(label: Text('สำเร็จ')),
                        DataColumn(label: Text('ไม่สำเร็จ')),
                        DataColumn(label: Text('สถานะ')),
                        DataColumn(label: Text('รายละเอียด')),
                      ],
                      rows: _logs.map((_ImportLogRecord log) {
                        return DataRow(
                          cells: [
                            DataCell(Text(log.date)),
                            DataCell(Text(log.user)),
                            DataCell(Text(log.dataType)),
                            DataCell(Text(log.source)),
                            DataCell(Text('${log.total}')),
                            DataCell(
                              Text(
                                '${log.success}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: SchoolAdminPalette.green,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${log.failed}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: log.failed > 0
                                      ? SchoolAdminPalette.red
                                      : SchoolAdminPalette.textMuted,
                                ),
                              ),
                            ),
                            DataCell(
                              _LogStatusBadge(
                                status: log.status,
                                hasError: log.failed > 0,
                              ),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'ดูรายละเอียด',
                                onPressed: () => _showLogDetail(log),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 19,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }

                return Column(
                  children: _logs.map((_ImportLogRecord log) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _ImportLogMobileCard(
                        log: log,
                        onTap: () => _showLogDetail(log),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildGuide() {
    return const _ImportSectionCard(
      title: 'ข้อแนะนำก่อนนำเข้าข้อมูล',
      subtitle: 'ช่วยลดข้อมูลซ้ำและลดเวลาการแก้ไขภายหลัง',
      child: Column(
        children: [
          _GuideRow(
            number: '1',
            title: 'ดาวน์โหลดแบบฟอร์มก่อน',
            detail:
                'ใช้หัวคอลัมน์ตามแบบฟอร์มของระบบ เพื่อให้ระบบอ่านข้อมูลได้ถูกต้อง',
          ),
          SizedBox(height: 8),
          _GuideRow(
            number: '2',
            title: 'ตรวจรหัสไม่ให้ซ้ำ',
            detail:
                'รหัสนักเรียน รหัสครู รหัสอุปกรณ์ และรหัสชุดฝึกควรไม่ซ้ำกัน',
          ),
          SizedBox(height: 8),
          _GuideRow(
            number: '3',
            title: 'ตรวจข้อมูลที่เชื่อมโยงกัน',
            detail:
                'เช่น ห้องต้องมีอาคาร ครูประจำชั้นต้องตรงกับห้อง และอุปกรณ์ต้องระบุพื้นที่',
          ),
          SizedBox(height: 8),
          _GuideRow(
            number: '4',
            title: 'ตรวจ Log หลังนำเข้า',
            detail:
                'ทุกครั้งที่นำเข้า ระบบจะบันทึกผู้ใช้งาน เวลา จำนวนสำเร็จ และรายการที่มีปัญหา',
          ),
        ],
      ),
    );
  }
}

class _ImportSummaryCard extends StatelessWidget {
  const _ImportSummaryCard({required this.data});

  final _ImportSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 148 : 130),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ImportIconBox(icon: data.icon, color: data.color),
                    const SizedBox(height: 10),
                    Text(
                      data.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 10,
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
                        fontSize: 8,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _ImportIconBox(icon: data.icon, color: data.color),
                    const SizedBox(width: 11),
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
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 10.5,
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
                              fontSize: 8.5,
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

class _ImportSectionCard extends StatelessWidget {
  const _ImportSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
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
              const SizedBox(height: 4),
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
        ),
      ),
    );
  }
}

class _ImportStepCard extends StatelessWidget {
  const _ImportStepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String step;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: SchoolAdminPalette.primary,
                child: Text(
                  step,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
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
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _FileUploadBox extends StatelessWidget {
  const _FileUploadBox({required this.fileName, required this.onSelectFile});

  final String? fileName;
  final VoidCallback onSelectFile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: SchoolAdminPalette.primaryDark,
              ),
              const SizedBox(height: 8),
              Text(
                fileName ?? 'เลือกไฟล์ Excel หรือ CSV',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'รองรับ .xlsx, .xls และ .csv',
                style: TextStyle(
                  fontSize: 9,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onSelectFile,
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(fileName == null ? 'เลือกไฟล์' : 'เปลี่ยนไฟล์'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({required this.data});

  final _ValidationData data;

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
          _ImportIconBox(icon: data.icon, color: data.color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: data.color,
                  ),
                ),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  data.detail,
                  style: const TextStyle(
                    fontSize: 8,
                    color: SchoolAdminPalette.textSecondary,
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

class _PreviewMobileCard extends StatelessWidget {
  const _PreviewMobileCard({required this.row});

  final _PreviewRow row;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: SchoolAdminPalette.primarySoft,
            child: Text(
              row.row,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${row.code} • ${row.detail}',
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.4,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _ImportStatusBadge(status: row.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportStatusBadge extends StatelessWidget {
  const _ImportStatusBadge({required this.status});

  final String status;

  Color get color {
    switch (status) {
      case 'พร้อมนำเข้า':
        return SchoolAdminPalette.green;
      case 'คำเตือน':
        return SchoolAdminPalette.secondary;
      default:
        return SchoolAdminPalette.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BadgeBase(label: status, color: color);
  }
}

class _LogStatusBadge extends StatelessWidget {
  const _LogStatusBadge({required this.status, required this.hasError});

  final String status;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return _BadgeBase(
      label: status,
      color: hasError ? SchoolAdminPalette.secondary : SchoolAdminPalette.green,
    );
  }
}

class _BadgeBase extends StatelessWidget {
  const _BadgeBase({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _ImportLogMobileCard extends StatelessWidget {
  const _ImportLogMobileCard({required this.log, required this.onTap});

  final _ImportLogRecord log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ImportIconBox(
                    icon: Icons.history_rounded,
                    color: log.failed > 0
                        ? SchoolAdminPalette.secondary
                        : SchoolAdminPalette.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.dataType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        Text(
                          '${log.date} • ${log.user}',
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SchoolAdminPalette.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallLogMetric(label: 'แหล่งข้อมูล', value: log.source),
                  _SmallLogMetric(label: 'ทั้งหมด', value: '${log.total}'),
                  _SmallLogMetric(
                    label: 'สำเร็จ',
                    value: '${log.success}',
                    color: SchoolAdminPalette.green,
                  ),
                  _SmallLogMetric(
                    label: 'ไม่สำเร็จ',
                    value: '${log.failed}',
                    color: log.failed > 0
                        ? SchoolAdminPalette.red
                        : SchoolAdminPalette.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallLogMetric extends StatelessWidget {
  const _SmallLogMetric({
    required this.label,
    required this.value,
    this.color = SchoolAdminPalette.textPrimary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: SchoolAdminPalette.primarySoft,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: SchoolAdminPalette.textSecondary,
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

class _ImportIconBox extends StatelessWidget {
  const _ImportIconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80), width: 1.1),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ImportDetailRow extends StatelessWidget {
  const _ImportDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: SchoolAdminPalette.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportSummaryData {
  const _ImportSummaryData({
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

class _ValidationData {
  const _ValidationData({
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

class _PreviewRow {
  const _PreviewRow({
    required this.row,
    required this.code,
    required this.name,
    required this.detail,
    required this.status,
  });

  final String row;
  final String code;
  final String name;
  final String detail;
  final String status;
}

class _ImportLogRecord {
  const _ImportLogRecord({
    required this.date,
    required this.user,
    required this.dataType,
    required this.source,
    required this.fileName,
    required this.total,
    required this.success,
    required this.failed,
    required this.status,
  });

  final String date;
  final String user;
  final String dataType;
  final String source;
  final String fileName;
  final int total;
  final int success;
  final int failed;
  final String status;
}
