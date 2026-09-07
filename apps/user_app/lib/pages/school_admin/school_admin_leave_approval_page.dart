import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme/school_admin_palette.dart';

/// อนุมัติการลา — school_admin reviews staff_leave_requests, with any
/// attached document (ใบรับรองแพทย์) viewable before deciding.
class SchoolAdminLeaveApprovalPage extends StatefulWidget {
  const SchoolAdminLeaveApprovalPage({
    super.key,
    this.loadRequests,
    this.loadAttachments,
    this.reviewRequest,
    this.getDownloadUrl,
  });

  final Future<List<StaffLeaveRequest>> Function({String? status})?
  loadRequests;
  final Future<List<StaffLeaveAttachment>> Function(String requestId)?
  loadAttachments;
  final Future<void> Function({
    required String requestId,
    required bool approve,
    String? note,
  })?
  reviewRequest;
  final Future<String> Function(String attachmentId)? getDownloadUrl;

  @override
  State<SchoolAdminLeaveApprovalPage> createState() =>
      _SchoolAdminLeaveApprovalPageState();
}

class _SchoolAdminLeaveApprovalPageState
    extends State<SchoolAdminLeaveApprovalPage> {
  bool _isLoading = true;
  String? _loadError;
  List<StaffLeaveRequest> _requests = [];
  String _statusFilter = 'pending';

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
      final load = widget.loadRequests ??
          ({status}) => StaffAttendanceService.listLeaveRequests(status: status);
      final requests =
          await load(status: _statusFilter == 'all' ? null : _statusFilter);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SchoolAdminLeaveApprovalPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'โหลดข้อมูลไม่สำเร็จ กรุณาลองใหม่';
      });
    }
  }

  void _setFilter(String status) {
    setState(() => _statusFilter = status);
    _load();
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

  Future<void> _openDetail(StaffLeaveRequest request) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LeaveDetailSheet(
        request: request,
        loadAttachments: widget.loadAttachments ??
            (id) => StaffLeaveAttachmentService.list(id),
        getDownloadUrl: widget.getDownloadUrl ??
            (id) => StaffLeaveAttachmentService.getDownloadUrl(id),
        onDecide: (approve, note) async {
          final review = widget.reviewRequest ??
              ({required requestId, required approve, note}) =>
                  StaffAttendanceService.reviewLeaveRequest(
                    requestId: requestId,
                    approve: approve,
                    note: note,
                  );
          try {
            await review(
              requestId: request.requestId,
              approve: approve,
              note: note,
            );
            if (!sheetContext.mounted) return;
            Navigator.of(sheetContext).pop();
            if (!mounted) return;
            _message(approve ? 'อนุมัติการลาแล้ว' : 'ปฏิเสธการลาแล้ว');
            await _load(showLoading: false);
          } catch (e) {
            _message('ดำเนินการไม่สำเร็จ กรุณาลองใหม่', isError: true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolAdminPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    'อนุมัติการลา',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'รีเฟรช',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => _load(showLoading: false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _filterChips(),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() {
    const filters = [
      ('pending', 'รออนุมัติ'),
      ('approved', 'อนุมัติแล้ว'),
      ('rejected', 'ปฏิเสธแล้ว'),
      ('all', 'ทั้งหมด'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.$2),
                selected: _statusFilter == f.$1,
                onSelected: (_) => _setFilter(f.$1),
                selectedColor: SchoolAdminPalette.primarySoft,
              ),
            ),
        ],
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
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          'ไม่พบคำขอลาในหมวดนี้',
          style: TextStyle(color: SchoolAdminPalette.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(showLoading: false),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _requestCard(_requests[i]),
      ),
    );
  }

  Widget _requestCard(StaffLeaveRequest r) {
    return InkWell(
      onTap: () => _openDetail(r),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SchoolAdminPalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SchoolAdminPalette.border),
          boxShadow: SchoolAdminPalette.smallShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.fullName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${r.leaveTypeLabel} • ${r.dayCount} วัน',
                    style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmtDate(r.startDate)} - ${_fmtDate(r.endDate)}',
                    style: TextStyle(fontSize: 11.5, color: SchoolAdminPalette.textMuted),
                  ),
                ],
              ),
            ),
            _statusBadge(r.status),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'pending' => ('รออนุมัติ', SchoolAdminPalette.orange),
      'approved' => ('อนุมัติแล้ว', SchoolAdminPalette.green),
      'rejected' => ('ปฏิเสธแล้ว', SchoolAdminPalette.red),
      'cancelled' => ('ยกเลิกแล้ว', SchoolAdminPalette.textMuted),
      _ => (status, SchoolAdminPalette.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year + 543}';
}

class _LeaveDetailSheet extends StatefulWidget {
  const _LeaveDetailSheet({
    required this.request,
    required this.loadAttachments,
    required this.getDownloadUrl,
    required this.onDecide,
  });

  final StaffLeaveRequest request;
  final Future<List<StaffLeaveAttachment>> Function(String requestId)
  loadAttachments;
  final Future<String> Function(String attachmentId) getDownloadUrl;
  final Future<void> Function(bool approve, String? note) onDecide;

  @override
  State<_LeaveDetailSheet> createState() => _LeaveDetailSheetState();
}

class _LeaveDetailSheetState extends State<_LeaveDetailSheet> {
  bool _isLoadingAttachments = true;
  List<StaffLeaveAttachment> _attachments = [];
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAttachments() async {
    try {
      final rows = await widget.loadAttachments(widget.request.requestId);
      if (!mounted) return;
      setState(() {
        _attachments = rows;
        _isLoadingAttachments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingAttachments = false);
    }
  }

  Future<void> _openAttachment(StaffLeaveAttachment a) async {
    try {
      final url = await widget.getDownloadUrl(a.attachmentId);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปิดไฟล์ไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  Future<void> _decide(bool approve) async {
    setState(() => _isSubmitting = true);
    await widget.onDecide(
      approve,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.leaveTypeLabel} • ${r.dayCount} วัน',
                  style: TextStyle(color: SchoolAdminPalette.textSecondary),
                ),
                if (r.reason != null) ...[
                  const SizedBox(height: 12),
                  Text('เหตุผล', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(r.reason!),
                ],
                const SizedBox(height: 16),
                Text('ไฟล์แนบ', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (_isLoadingAttachments)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else if (_attachments.isEmpty)
                  Text(
                    'ไม่มีไฟล์แนบ',
                    style: TextStyle(color: SchoolAdminPalette.textMuted, fontSize: 12.5),
                  )
                else
                  for (final a in _attachments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.description_rounded),
                      title: Text(a.fileName, style: const TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _openAttachment(a),
                    ),
                if (r.isPending) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'หมายเหตุ (ถ้ามี)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => _decide(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            foregroundColor: SchoolAdminPalette.red,
                          ),
                          child: const Text('ปฏิเสธ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : () => _decide(true),
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            backgroundColor: SchoolAdminPalette.green,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('อนุมัติ'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  if (r.reviewerName != null)
                    Text(
                      'ตัดสินใจโดย ${r.reviewerName}'
                      '${r.reviewNote != null ? ' • ${r.reviewNote}' : ''}',
                      style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
