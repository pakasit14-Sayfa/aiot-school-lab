// Physical Emergency Events Page (รายการแจ้งเหตุฉุกเฉินจากปุ่มกดกายภาพ)
// Wireframe MVP v1 Section 2.8.1 & emergency-alert-app-proposal-v1.md
// SEPARATED FROM teacher_incident_inbox_page.dart (incident_reports vs emergency_events).
// Handles physical panic button triggers, responder acknowledgments, and mandatory review_note entry upon event resolution.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart' show TeacherMockPageShell;

class TeacherEmergencyEventsPage extends StatefulWidget {
  const TeacherEmergencyEventsPage({super.key});

  @override
  State<TeacherEmergencyEventsPage> createState() =>
      _TeacherEmergencyEventsPageState();
}

class _TeacherEmergencyEventsPageState
    extends State<TeacherEmergencyEventsPage> {
  String _selectedFilter =
      'ทั้งหมด'; // 'ทั้งหมด', 'ค้างดำเนินการ', 'ปิดเหตุการณ์แล้ว'

  bool _isLoading = true;
  List<EmergencyEventItem> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final items = await EmergencyService.listEmergencyEvents();
      if (mounted) {
        setState(() {
          _events = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _events = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดรายการเหตุฉุกเฉินไม่สำเร็จ: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _acknowledgeEvent(EmergencyEventItem event) async {
    try {
      await EmergencyService.acknowledgeEmergencyEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'รับทราบสัญญาณ SOS ของ ${event.deviceName} เรียบร้อย กำลังเข้าช่วยเหลือ',
          ),
          backgroundColor: const Color(0xFFEA580C),
        ),
      );
      _loadEvents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('รับทราบเหตุไม่สำเร็จ: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showResolveDialog(EmergencyEventItem event) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'ปิดเหตุการณ์ฉุกเฉิน (Resolve)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตำแหน่ง: ${event.deviceName} (${event.location})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'บังคับกรอกสรุปรายงานผลการเข้าช่วยเหลือ (review_note) ก่อนปิดเหตุการณ์:',
              style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'กรอกสรุปเหตุการณ์ การเข้าช่วยเหลือ และสถานะความปลอดภัยปัจจุบัน...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'กรุณากรอกสรุปรายงานผลการช่วยเหลือ (review_note) ก่อนปิดเหตุการณ์',
                    ),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await EmergencyService.closeEmergencyEvent(
                  eventId: event.id,
                  reviewNote: note,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ปิดเหตุการณ์ฉุกเฉินของ ${event.deviceName} เรียบร้อยแล้ว',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                _loadEvents();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ปิดเหตุการณ์ไม่สำเร็จ: $e'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('ยืนยันปิดเหตุการณ์'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _events.where((e) {
      if (_selectedFilter == 'ค้างดำเนินการ') {
        return !e.isClosed;
      } else if (_selectedFilter == 'ปิดเหตุการณ์แล้ว') {
        return e.isClosed;
      }
      return true;
    }).toList();

    final activeSosCount = _events.where((e) => e.isNew).length;

    return TeacherMockPageShell(
      title: 'เหตุฉุกเฉิน (ปุ่มกดกายภาพ SOS)',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      actions: [
        if (activeSosCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'มี SOS ฉุกเฉิน $activeSosCount รายการ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
      ],
      builder: (context, isDesktop) {
        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Banner explaining Entity Isolation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFEA580C),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'หน้านี้แสดงเฉพาะรายการจากปุ่มกดกายภาพฉุกเฉิน (emergency_events) แยกต่างหากจากรายการรับแจ้งเหตุทั่วไปผ่านแอป (incident_reports) เพื่อการเข้าถึงข้อมูลที่รวดเร็วสูงสุด',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC2410C),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filter Chips Row
              Row(
                children: [
                  const Text(
                    'สถานะเหตุการณ์:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: TeacherPalette.muted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Wrap(
                    spacing: 8,
                    children: ['ทั้งหมด', 'ค้างดำเนินการ', 'ปิดเหตุการณ์แล้ว']
                        .map(
                          (filter) => ChoiceChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _selectedFilter = filter);
                              }
                            },
                            selectedColor: TeacherPalette.primary.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: TextStyle(
                              color: _selectedFilter == filter
                                  ? TeacherPalette.primary
                                  : TeacherPalette.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: _selectedFilter == filter
                                  ? TeacherPalette.primary
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: TeacherPalette.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 48,
                        color: TeacherPalette.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ไม่มีรายการเหตุฉุกเฉินในขณะนี้',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'สถานะระบบเป็นปกติ ความปลอดภัย 100%',
                        style: TextStyle(
                          fontSize: 12,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    final isEmergency = event.isNew;
                    final statusLabel = event.isNew
                        ? 'เกิดเหตุฉุกเฉิน'
                        : (event.isAcknowledged
                              ? 'กำลังตอบสนอง'
                              : 'ปิดเหตุการณ์แล้ว');

                    final triggerFormatted =
                        '${event.triggeredAt.hour.toString().padLeft(2, '0')}:${event.triggeredAt.minute.toString().padLeft(2, '0')} น.';

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isEmergency
                              ? const Color(0xFFFECACA)
                              : TeacherPalette.border,
                          width: isEmergency ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isEmergency
                                ? const Color(0x1AEA580C)
                                : const Color(0x0A0F172A),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isEmergency
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.emergency_rounded,
                                  color: isEmergency
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF64748B),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'อุปกรณ์: ${event.deviceName}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'เวลาแจ้ง: $triggerFormatted',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: TeacherPalette.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event.deviceName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: TeacherPalette.ink,
                                      ),
                                    ),
                                    Text(
                                      event.location,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: TeacherPalette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Status Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isEmergency
                                      ? const Color(0xFFFEF2F2)
                                      : (event.isAcknowledged
                                            ? const Color(0xFFFFF7ED)
                                            : const Color(0xFFECFDF5)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isEmergency
                                        ? const Color(0xFFFECACA)
                                        : (event.isAcknowledged
                                              ? const Color(0xFFFED7AA)
                                              : const Color(0xFFA7F3D0)),
                                  ),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isEmergency
                                        ? const Color(0xFFDC2626)
                                        : (event.isAcknowledged
                                              ? const Color(0xFFEA580C)
                                              : const Color(0xFF059669)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (event.acknowledgedByName != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'ผู้รับทราบและกำลังเข้าตรวจสอบ: ${event.acknowledgedByName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ],

                          if (event.reviewNote != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'สรุปรายงานผลการช่วยเหลือ (review_note):',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: TeacherPalette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.reviewNote!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: TeacherPalette.ink,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Action Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isEmergency)
                                ElevatedButton.icon(
                                  onPressed: () => _acknowledgeEvent(event),
                                  icon: const Icon(
                                    Icons.shield_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'รับทราบ SOS / เข้าช่วยเหลือ',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              if (!event.isClosed) ...[
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _showResolveDialog(event),
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('ปิดเหตุการณ์ (Resolve)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF10B981),
                                    side: const BorderSide(
                                      color: Color(0xFFA7F3D0),
                                    ),
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
