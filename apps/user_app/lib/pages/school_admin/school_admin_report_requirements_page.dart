import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

/// สร้างรายการรายงานที่ต้องส่ง — school_admin declares a report_requirement
/// (which ฝ่าย must file it, and by when); the real "3/6" tracking on
/// `school_reports_page` has nothing to count against until at least one of
/// these exists.
class SchoolAdminReportRequirementsPage extends StatefulWidget {
  const SchoolAdminReportRequirementsPage({
    super.key,
    this.loadRequirements,
    this.loadDepartments,
    this.createRequirement,
    this.closeRequirement,
  });

  final Future<List<ReportRequirement>> Function({bool onlyOpen})?
  loadRequirements;
  final Future<List<SchoolDepartment>> Function()? loadDepartments;
  final Future<String> Function({
    required String title,
    required String reportType,
    required List<String> departmentIds,
    DateTime? dueDate,
    String? description,
  })?
  createRequirement;
  final Future<void> Function(String requirementId)? closeRequirement;

  @override
  State<SchoolAdminReportRequirementsPage> createState() =>
      _SchoolAdminReportRequirementsPageState();
}

class _SchoolAdminReportRequirementsPageState
    extends State<SchoolAdminReportRequirementsPage> {
  bool _isLoading = true;
  String? _loadError;
  List<ReportRequirement> _requirements = [];
  bool _onlyOpen = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final load = widget.loadRequirements ??
          ({onlyOpen = false}) =>
              SchoolReportService.listRequirements(onlyOpen: onlyOpen);
      final rows = await load(onlyOpen: _onlyOpen);
      if (!mounted) return;
      setState(() {
        _requirements = rows;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SchoolAdminReportRequirementsPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'โหลดข้อมูลไม่สำเร็จ กรุณาลองใหม่';
      });
    }
  }

  void _message(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isError ? SchoolAdminPalette.red : null,
        ),
      );
  }

  Future<void> _openCreateDialog() async {
    final departments = await (widget.loadDepartments ??
        () => StaffOrgService.listDepartments(kind: 'administrative'))();
    if (!mounted) return;
    if (departments.isEmpty) {
      _message('ยังไม่มีฝ่ายในระบบให้กำหนดผู้รับผิดชอบ');
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String reportType = 'monthly';
    DateTime? dueDate;
    final selectedDeptIds = <String>{};
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('สร้างรายการรายงานที่ต้องส่ง'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'ชื่อรายงานที่ต้องส่ง'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: reportType,
                    decoration: const InputDecoration(labelText: 'ความถี่'),
                    items: SchoolReport.reportTypeLabels.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => reportType = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      dueDate == null
                          ? 'กำหนดส่ง (ไม่บังคับ)'
                          : 'กำหนดส่ง: ${_fmtDate(dueDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ฝ่ายที่ต้องส่ง',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in departments)
                        FilterChip(
                          label: Text(d.name),
                          selected: selectedDeptIds.contains(d.departmentId),
                          onSelected: (selected) => setDialogState(() {
                            if (selected) {
                              selectedDeptIds.add(d.departmentId);
                            } else {
                              selectedDeptIds.remove(d.departmentId);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'รายละเอียด (ไม่บังคับ)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        _message('กรุณากรอกชื่อรายงาน', isError: true);
                        return;
                      }
                      if (selectedDeptIds.isEmpty) {
                        _message('กรุณาเลือกอย่างน้อย 1 ฝ่าย', isError: true);
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final create = widget.createRequirement ??
                            ({
                              required title,
                              required reportType,
                              required departmentIds,
                              dueDate,
                              description,
                            }) =>
                                SchoolReportService.createRequirement(
                                  title: title,
                                  reportType: reportType,
                                  departmentIds: departmentIds,
                                  dueDate: dueDate,
                                  description: description,
                                );
                        await create(
                          title: title,
                          reportType: reportType,
                          departmentIds: selectedDeptIds.toList(),
                          dueDate: dueDate,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        _message('สร้างรายการรายงานที่ต้องส่งแล้ว');
                        await _load(showLoading: false);
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        _message('สร้างรายการไม่สำเร็จ กรุณาลองใหม่', isError: true);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('สร้าง'),
            ),
          ],
        ),
      ),
    );

    // Not disposed here deliberately: the dialog's own exit animation can
    // still be reading these controllers when this function resumes
    // (showDialog's future completes at pop(), not after the transition
    // finishes), and disposing on that race crashes with "used after being
    // disposed." Same tradeoff already made by this app's other one-shot
    // create dialogs (e.g. super_admin's register-device dialog).
  }

  Future<void> _confirmClose(ReportRequirement r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ปิดรายการนี้?'),
        content: Text('"${r.title}" จะไม่ถูกนับในรายการที่ต้องส่งอีกต่อไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ปิดรายการ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final close = widget.closeRequirement ??
          (id) => SchoolReportService.closeRequirement(id);
      await close(r.requirementId);
      _message('ปิดรายการแล้ว');
      await _load(showLoading: false);
    } catch (e) {
      _message('ปิดรายการไม่สำเร็จ กรุณาลองใหม่', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolAdminPalette.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: SchoolAdminPalette.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('สร้างรายการ'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    'รายการรายงานที่ต้องส่ง',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  FilterChip(
                    label: const Text('เฉพาะยังเปิดอยู่'),
                    selected: _onlyOpen,
                    onSelected: (v) {
                      setState(() => _onlyOpen = v);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: SchoolAdminPalette.red),
            const SizedBox(height: 8),
            Text(_loadError!, style: TextStyle(color: SchoolAdminPalette.red)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('ลองใหม่')),
          ],
        ),
      );
    }
    if (_requirements.isEmpty) {
      return Center(
        child: Text(
          'ยังไม่มีรายการรายงานที่ต้องส่ง',
          style: TextStyle(color: SchoolAdminPalette.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(showLoading: false),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
        itemCount: _requirements.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _requirementCard(_requirements[i]),
      ),
    );
  }

  Widget _requirementCard(ReportRequirement r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.isOverdue ? SchoolAdminPalette.red : SchoolAdminPalette.border,
        ),
        boxShadow: SchoolAdminPalette.smallShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${r.reportTypeLabel} • ส่งแล้ว ${r.filedCount}/${r.expectedCount} ฝ่าย'
                  '${r.dueDate != null ? ' • กำหนด ${_fmtDate(r.dueDate!)}' : ''}',
                  style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
                ),
                if (r.isOverdue) ...[
                  const SizedBox(height: 3),
                  Text(
                    'เกินกำหนด',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'ปิดรายการ',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmClose(r),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year + 543}';
}
