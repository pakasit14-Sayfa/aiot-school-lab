import 'package:flutter/material.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลด Consent Policy ไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> showPublishDialog() async {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController();
    final versionController = TextEditingController();
    final urlController = TextEditingController();
    final hashController = TextEditingController();
    var isRequired = false;

    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เผยแพร่ Consent Policy'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'ประเภท/วัตถุประสงค์',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'กรุณาระบุประเภท'
                          : null,
                    ),
                    TextFormField(
                      controller: versionController,
                      decoration: const InputDecoration(labelText: 'Version'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'กรุณาระบุ Version'
                          : null,
                    ),
                    TextFormField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'HTTPS URL ของเอกสาร',
                      ),
                      validator: (value) {
                        final uri = Uri.tryParse(value?.trim() ?? '');
                        return uri?.scheme == 'https' &&
                                uri?.host.isNotEmpty == true
                            ? null
                            : 'ต้องเป็น HTTPS URL ที่ถูกต้อง';
                      },
                    ),
                    TextFormField(
                      controller: hashController,
                      decoration: const InputDecoration(
                        labelText: 'SHA-256 ของเอกสาร (64 ตัวอักษร)',
                      ),
                      validator: (value) =>
                          RegExp(
                            r'^[0-9a-fA-F]{64}$',
                          ).hasMatch(value?.trim() ?? '')
                          ? null
                          : 'SHA-256 ไม่ถูกต้อง',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isRequired,
                      title: const Text('เป็น policy ที่จำเป็น'),
                      subtitle: const Text(
                        'ต้องได้รับการอนุมัติจากโรงเรียน/DPO ก่อนเลือกค่านี้',
                      ),
                      onChanged: (value) =>
                          setDialogState(() => isRequired = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('เผยแพร่'),
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
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เผยแพร่ไม่สำเร็จ: $error')));
        }
      }
    }

    typeController.dispose();
    versionController.dispose();
    urlController.dispose();
    hashController.dispose();
  }

  Future<void> retirePolicy(AdminConsentPolicy policy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยุติ Consent Policy'),
        content: Text(
          'ยุติ ${policy.consentType} version ${policy.version} หรือไม่? '
          'หลักฐาน Consent เดิมจะยังถูกเก็บไว้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยุติ Policy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ConsentService.retireConsentPolicy(policy.id);
    await loadPolicies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการ Consent Policy')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showPublishDialog,
        icon: const Icon(Icons.add),
        label: const Text('เผยแพร่ Version'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : policies.isEmpty
          ? const Center(child: Text('ยังไม่มี Consent Policy ของโรงเรียน'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: policies.length,
              itemBuilder: (context, index) {
                final policy = policies[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      policy.isActive ? Icons.verified : Icons.archive,
                      color: policy.isActive ? Colors.green : Colors.grey,
                    ),
                    title: Text('${policy.consentType} · ${policy.version}'),
                    subtitle: SelectableText(
                      '${policy.isRequired ? 'จำเป็น' : 'กิจกรรมเสริม'} · '
                      '${policy.isActive ? 'มีผลใช้งาน' : 'ยุติแล้ว/รอมีผล'}\n'
                      '${policy.contentUrl}\nSHA-256: ${policy.documentHash}',
                    ),
                    trailing: policy.retiredAt == null
                        ? IconButton(
                            onPressed: () => retirePolicy(policy),
                            icon: const Icon(Icons.archive),
                            tooltip: 'ยุติ Policy',
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
