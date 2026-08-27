import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_core/models/consent_model.dart';
import 'package:shared_core/services/consent_service.dart';

class ConsentPolicyAdminPage extends StatefulWidget {
  const ConsentPolicyAdminPage({super.key});

  @override
  State<ConsentPolicyAdminPage> createState() => _ConsentPolicyAdminPageState();
}

class _ConsentPolicyAdminPageState extends State<ConsentPolicyAdminPage> {
  List<AdminConsentPolicy> policies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPolicies();
  }

  Future<void> loadPolicies() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final result = await ConsentService.listAdminConsentPolicies();
      if (mounted) setState(() => policies = result);
    } catch (error) {
      if (mounted) {
        _showMessage('โหลด Consent Policy ไม่สำเร็จ: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int get _activeCount => policies.where((p) => p.isActive).length;
  int get _requiredCount => policies.where((p) => p.isRequired).length;
  int get _retiredCount => policies.where((p) => p.retiredAt != null).length;

  Future<void> showPublishDialog() async {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController(text: 'นโยบายคุ้มครองข้อมูลส่วนบุคคล (PDPA)');
    final versionController = TextEditingController(text: 'v1.0.0');
    final urlController = TextEditingController(text: 'https://school.ac.th/pdpa/policy-v1.pdf');
    final hashController = TextEditingController(
      text: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    var isRequired = true;

    final shouldPublish = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9E401A).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.policy_rounded, color: Color(0xFF9E401A), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เผยแพร่ Consent Policy ใหม่',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'สร้างเวอร์ชันนโยบายความยินยอมตามข้อกำหนด PDPA',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'เลือกประเภทนโยบายที่พบบ่อย:',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _QuickTypeChip(
                          label: 'PDPA นักเรียน',
                          onTap: () {
                            typeController.text = 'นโยบายคุ้มครองข้อมูลส่วนบุคคลนักเรียน (PDPA)';
                            urlController.text = 'https://school.ac.th/pdpa/student-v1.pdf';
                          },
                        ),
                        _QuickTypeChip(
                          label: 'ความยินยอมกล้อง CCTV',
                          onTap: () {
                            typeController.text = 'ความยินยอมการบันทึกภาพกล้องวงจรปิด (CCTV Policy)';
                            urlController.text = 'https://school.ac.th/pdpa/cctv-v1.pdf';
                          },
                        ),
                        _QuickTypeChip(
                          label: 'การใช้ระบบ AIoT & IoT',
                          onTap: () {
                            typeController.text = 'ข้อกำหนดการใช้งานระบบ AIoT Smart Lab';
                            urlController.text = 'https://school.ac.th/pdpa/aiot-lab-v1.pdf';
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: typeController,
                      decoration: _inputDecoration('ประเภท / วัตถุประสงค์นโยบาย', Icons.category_rounded),
                      validator: (value) => value == null || value.trim().isEmpty ? 'กรุณาระบุประเภท': null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: versionController,
                            decoration: _inputDecoration('เวอร์ชัน (Version)', Icons.tag_rounded),
                            validator: (value) => value == null || value.trim().isEmpty ? 'กรุณาระบุ Version': null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: isRequired,
                              title: const Text('เป็นนโยบายจำเป็น', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              onChanged: (value) => setDialogState(() => isRequired = value),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: urlController,
                      decoration: _inputDecoration('HTTPS URL ของเอกสารต้นฉบับ (PDF)', Icons.link_rounded),
                      validator: (value) {
                        final uri = Uri.tryParse(value?.trim() ?? '');
                        return uri?.scheme == 'https' && uri?.host.isNotEmpty == true
                            ? null
                            : 'ต้องเป็น HTTPS URL ที่ถูกต้อง';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: hashController,
                      decoration: _inputDecoration('SHA-256 Checksum ของเอกสาร (64 หลัก)', Icons.fingerprint_rounded),
                      validator: (value) =>
                          RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value?.trim() ?? '')
                              ? null
                              : 'SHA-256 ต้องเป็นเลขฐาน 16 ความยาว 64 ตัวอักษร',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(dialogContext, true);
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('เผยแพร่ Version'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9E401A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldPublish == true) {
      try {
        await ConsentService.publishConsentPolicy(
          consentType: typeController.text,
          version: versionController.text,
          documentHash: hashController.text,
          contentUrl: urlController.text,
          isRequired: isRequired,
        );
        await loadPolicies();
        _showMessage('เผยแพร่ Consent Policy สำเร็จเรียบร้อย');
      } catch (error) {
        if (mounted) {
          _showMessage('เผยแพร่ไม่สำเร็จ: $error', isError: true);
        }
      }
    }

    typeController.dispose();
    versionController.dispose();
    urlController.dispose();
    hashController.dispose();
  }

  static InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9E401A), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> retirePolicy(AdminConsentPolicy policy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.archive_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'ยุติ Consent Policy',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการยุติ ${policy.consentType} (Version ${policy.version}) หรือไม่?\n\nหลักฐานความยินยอมเดิมที่ผู้ปกครองและนักเรียนเคยกดรับไว้จะยังคงถูกเก็บรักษาไว้อย่างปลอดภัยตามกฎหมาย',
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ยืนยันยุติ Policy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ConsentService.retireConsentPolicy(policy.id);
      await loadPolicies();
      _showMessage('ยุติการใช้งาน Consent Policy สำเร็จ');
    } catch (e) {
      _showMessage('ยุติไม่สำเร็จ: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E401A)))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
                        _buildSummary(),
                        const SizedBox(height: 18),
                        _buildPdpaComplianceBanner(),
                        const SizedBox(height: 18),
                        _buildPolicyList(),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget title = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9E401A), Color(0xFF6E280C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x289E401A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.policy_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จัดการ Consent Policy & PDPA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'บริหารจัดการนโยบายความเป็นส่วนตัว PDPA ข้อกำหนด และหลักฐานความยินยอมในระบบ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                onPressed: loadPolicies,
                tooltip: 'รีเฟรช',
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              FilledButton.icon(
                onPressed: showPublishDialog,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('เผยแพร่ Version'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9E401A),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), actions],
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
    );
  }

  Widget _buildSummary() {
    final List<_SummaryItemData> items = [
      _SummaryItemData(
        title: 'นโยบายทั้งหมด',
        value: '${policies.length}',
        detail: 'บันทึกในระบบโรงเรียน',
        icon: Icons.description_rounded,
        color: const Color(0xFF0284C7),
      ),
      _SummaryItemData(
        title: 'มีผลบังคับใช้ (Active)',
        value: '$_activeCount',
        detail: 'ผู้ใช้ต้องยินยอม',
        icon: Icons.verified_rounded,
        color: const Color(0xFF16A34A),
      ),
      _SummaryItemData(
        title: 'นโยบายภาคบังคับ',
        value: '$_requiredCount',
        detail: 'จำเป็นต่อการใช้งานระบบ',
        icon: Icons.shield_rounded,
        color: const Color(0xFF9E401A),
      ),
      _SummaryItemData(
        title: 'ยุติการใช้งานแล้ว',
        value: '$_retiredCount',
        detail: 'เก็บหลักฐานเดิมตามกฎหมาย',
        icon: Icons.archive_rounded,
        color: const Color(0xFF64748B),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 520) columns = 1;

        const double spacing = 14;
        final double width = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: _SummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPdpaComplianceBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_rounded, color: Color(0xFF16A34A), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'มาตรฐานความปลอดภัยและการจัดเก็บหลักฐาน PDPA',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14532D),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'ทุกครั้งที่มีการกดให้ความยินยอม ระบบจะบันทึก Timestamp, SHA-256 ของเอกสารต้นฉบับ และ User UID ไว้เป็นหลักฐานเพื่อความโปร่งใสและปฏิบัติตาม พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายการ Consent Policy ของโรงเรียน',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'รายการนโยบายความยินยอมทั้งหมดที่เผยแพร่ในระบบ',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${policies.length} นโยบาย',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (policies.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.policy_outlined, size: 52, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 14),
                  const Text(
                    'ยังไม่มี Consent Policy ของโรงเรียน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'กดปุ่ม "เผยแพร่ Version" ด้านบน เพื่อสร้างนโยบายความยินยอมแรกสำหรับสถานศึกษา',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: showPublishDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('เผยแพร่ Version แรก'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9E401A),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: policies.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final policy = policies[index];
                return _PolicyCard(
                  policy: policy,
                  onRetire: policy.retiredAt == null ? () => retirePolicy(policy) : null,
                  onCopyHash: () {
                    Clipboard.setData(ClipboardData(text: policy.documentHash));
                    _showMessage('คัดลอก SHA-256 Checksum สำเร็จ');
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.policy,
    required this.onRetire,
    required this.onCopyHash,
  });

  final AdminConsentPolicy policy;
  final VoidCallback? onRetire;
  final VoidCallback onCopyHash;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: policy.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  policy.isActive ? Icons.verified_rounded : Icons.archive_rounded,
                  color: policy.isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            policy.consentType,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            policy.version,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        _StatusBadge(
                          text: policy.isRequired ? 'จำเป็น (Mandatory)' : 'กิจกรรมเสริม',
                          color: policy.isRequired ? const Color(0xFF9E401A) : const Color(0xFF0284C7),
                          bg: policy.isRequired ? const Color(0xFFFFEDD5) : const Color(0xFFE0F2FE),
                        ),
                        _StatusBadge(
                          text: policy.isActive ? 'มีผลใช้งาน (Active)' : 'ยุติแล้ว (Retired)',
                          color: policy.isActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          bg: policy.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onRetire != null)
                IconButton(
                  icon: const Icon(Icons.archive_outlined, color: Color(0xFFDC2626), size: 20),
                  tooltip: 'ยุติ Policy',
                  onPressed: onRetire,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        policy.contentUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0284C7),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.fingerprint_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SHA-256: ${policy.documentHash}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onCopyHash,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
    required this.bg,
  });

  final String text;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _QuickTypeChip extends StatelessWidget {
  const _QuickTypeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onPressed: onTap,
    );
  }
}

class _SummaryItemData {
  const _SummaryItemData({
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryItemData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: data.color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
