import 'package:flutter/material.dart';

import '../models/consent_model.dart';
import '../services/auth_service.dart';

class ParentConsentPage extends StatefulWidget {
  const ParentConsentPage({super.key});

  @override
  State<ParentConsentPage> createState() => _ParentConsentPageState();
}

class _ParentConsentPageState extends State<ParentConsentPage> {
  List<MyParentLink> links = [];
  List<ParentConsent> consents = [];
  MyParentLink? selectedLink;
  bool isLoading = true;
  final Set<String> readPolicies = {};

  @override
  void initState() {
    super.initState();
    loadLinks();
  }

  Future<void> loadLinks() async {
    setState(() => isLoading = true);
    try {
      final result = await AuthService.listMyParentLinks();
      final approved = result.where((link) => link.isApproved).toList();
      if (!mounted) return;
      setState(() {
        links = approved;
        selectedLink = approved.isEmpty ? null : approved.first;
      });
      if (selectedLink != null) await loadConsents();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadConsents() async {
    final link = selectedLink;
    if (link == null) return;
    final result = await AuthService.listMyConsents(link.id);
    if (mounted) setState(() => consents = result);
  }

  Future<void> toggleConsent(ParentConsent consent) async {
    final link = selectedLink;
    if (link == null) return;

    if (consent.isGranted) {
      await AuthService.withdrawParentConsent(consent.consentId!);
    } else {
      if (!readPolicies.contains(consent.policyId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณายืนยันว่าอ่านเอกสารแล้ว')),
        );
        return;
      }
      await AuthService.grantParentConsent(
        parentLinkId: link.id,
        policyId: consent.policyId,
      );
    }
    await loadConsents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการ Consent')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : links.isEmpty
          ? const Center(child: Text('ยังไม่มี Parent Link ที่ได้รับอนุมัติ'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<MyParentLink>(
                  value: selectedLink,
                  decoration: const InputDecoration(
                    labelText: 'เลือกนักเรียน',
                    border: OutlineInputBorder(),
                  ),
                  items: links
                      .map(
                        (link) => DropdownMenuItem(
                          value: link,
                          child: Text(
                            '${link.studentName} (${link.relationship})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (link) async {
                    setState(() {
                      selectedLink = link;
                      consents = [];
                      readPolicies.clear();
                    });
                    await loadConsents();
                  },
                ),
                const SizedBox(height: 16),
                if (consents.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'ยังไม่มี Consent Policy ที่มีผลใช้งาน '
                        'โรงเรียนต้องเผยแพร่ policy ก่อน',
                      ),
                    ),
                  ),
                ...consents.map(
                  (consent) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consent.consentType,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Version ${consent.version}'),
                          Text(
                            consent.isRequired
                                ? 'ประเภท: จำเป็นตามนโยบายที่โรงเรียนอนุมัติ'
                                : 'ประเภท: กิจกรรมเสริม (เลือกได้)',
                          ),
                          SelectableText(
                            'เอกสาร: ${consent.contentUrl}\n'
                            'SHA-256: ${consent.documentHash}',
                          ),
                          if (!consent.isGranted)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: readPolicies.contains(consent.policyId),
                              title: const Text(
                                'ฉันได้อ่านและเข้าใจเอกสารฉบับนี้แล้ว',
                              ),
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  readPolicies.add(consent.policyId);
                                } else {
                                  readPolicies.remove(consent.policyId);
                                }
                              }),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () => toggleConsent(consent),
                              style: consent.isGranted
                                  ? ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    )
                                  : null,
                              child: Text(
                                consent.isGranted
                                    ? 'ถอน Consent'
                                    : 'ให้ Consent',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
