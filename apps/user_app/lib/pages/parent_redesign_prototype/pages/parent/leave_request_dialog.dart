import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/services/parent_portal_service.dart';

class LeaveRequestFormDialog extends StatefulWidget {
  final String? studentId;
  final VoidCallback onSubmitted;
  
  const LeaveRequestFormDialog({
    super.key,
    required this.studentId,
    required this.onSubmitted,
  });

  @override
  State<LeaveRequestFormDialog> createState() => _LeaveRequestFormDialogState();
}

class _LeaveRequestFormDialogState extends State<LeaveRequestFormDialog> with SingleTickerProviderStateMixin {
  String _leaveType = 'sick';
  late DateTime _startDate;
  late DateTime _endDate;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  XFile? _attachedFile;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachedFile = pickedFile;
      });
    }
  }

  Future<void> _showModernDatePicker(
      BuildContext context, DateTime initialDate, DateTime firstDate, DateTime lastDate, ValueChanged<DateTime> onDateSelected) async {
    DateTime tempDate = initialDate;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 360,
            height: 320,
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ยกเลิก', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                      ),
                      const Text('เลือกวันที่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      TextButton(
                        onPressed: () {
                          onDateSelected(tempDate);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ยืนยัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.5),
                // Picker
                Expanded(
                  child: Localizations.override(
                    context: context,
                    locale: const Locale('th', 'TH'),
                    child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: firstDate,
                    maximumDate: lastDate,
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุเหตุผลการลา'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    if (widget.studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถส่งใบลาได้ เนื่องจากไม่พบข้อมูลนักเรียน'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    try {
      await ParentPortalService.submitLeaveRequest(
        studentId: widget.studentId!,
        leaveType: _leaveType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        attachmentFile: _attachedFile,
      );
      if (mounted) {
        _animController.reverse().then((_) {
          Navigator.pop(context);
          widget.onSubmitted();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), behavior: SnackBarBehavior.floating),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTypePill(String title, String typeId, Color color, IconData icon) {
    final isActive = _leaveType == typeId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _leaveType = typeId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : const Color(0xFFF3F5F9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isActive
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : const Color(0xFF8A94A4)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF8A94A4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    String _formatThaiDate(DateTime date) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A4), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatThaiDate(date),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Premium Header ---
                        Container(
                          padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ยื่นคำขอลาเรียน',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'ระบุข้อมูลและส่งให้ครูประจำชั้นพิจารณา',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 2,
                                shadowColor: Colors.black.withValues(alpha: 0.05),
                                child: IconButton(
                                  onPressed: () {
                                    _animController.reverse().then((_) => Navigator.pop(context));
                                  },
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                                ),
                              )
                            ],
                          ),
                        ),
                        
                        // --- Form Content ---
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Leave Type (Capsule Toggle)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F5F9),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    _buildTypePill('ลาป่วย', 'sick', const Color(0xFFEF4444), Icons.local_hospital_rounded),
                                    _buildTypePill('ลากิจ', 'personal', const Color(0xFFF59E0B), Icons.cases_rounded),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 28),
                              
                              // 2. Dates
                              const Text('ระยะเวลาที่ลา', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    _buildDateSelector('วันแรกที่ลา', _startDate, () async {
                                      await _showModernDatePicker(
                                        context,
                                        _startDate,
                                        DateTime.now().subtract(const Duration(days: 30)),
                                        DateTime.now().add(const Duration(days: 365)),
                                        (date) {
                                          setState(() {
                                            _startDate = date;
                                            if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                                          });
                                        },
                                      );
                                    }),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(Icons.arrow_forward_rounded, size: 18, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                                    ),
                                    _buildDateSelector('วันสุดท้าย', _endDate, () async {
                                      await _showModernDatePicker(
                                        context,
                                        _endDate,
                                        _startDate,
                                        DateTime.now().add(const Duration(days: 365)),
                                        (date) {
                                          setState(() => _endDate = date);
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 28),
                              
                              // 3. Reason
                              const Text('เหตุผลการลา', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _reasonController,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  hintText: 'ระบุสาเหตุ (เช่น มีไข้สูง, ไปต่างจังหวัด...)',
                                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.all(16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                                ),
                              ),
                              
                              const SizedBox(height: 28),
                              
                              // 4. Attachment (Sleek Box)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ใบรับรองแพทย์ / เอกสารแนบ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('ไม่บังคับ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              if (_attachedFile != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                                        child: const Icon(Icons.done_rounded, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('แนบเอกสารสำเร็จ', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700, fontSize: 14)),
                                            Text(_attachedFile!.name, style: const TextStyle(color: Color(0xFF15803D), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      Material(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        shape: const CircleBorder(),
                                        child: IconButton(
                                          onPressed: () => setState(() => _attachedFile = null),
                                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF166534)),
                                          splashRadius: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))]
                                          ),
                                          child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF3B82F6), size: 24),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('แตะเพื่ออัปโหลดไฟล์', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
                                        const SizedBox(height: 4),
                                        const Text('รองรับ JPG, PNG, PDF', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              const SizedBox(height: 32),
                              
                              // 5. Submit
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB), // Sleek blue
                                    foregroundColor: Colors.white,
                                    shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isSubmitting 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('ส่งคำขอลาเรียน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
          ),
        ),
      ),
    );
  }
}
