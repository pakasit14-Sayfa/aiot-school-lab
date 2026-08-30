import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolLearningTracksPage extends StatefulWidget {
  const SchoolLearningTracksPage({super.key});

  @override
  State<SchoolLearningTracksPage> createState() =>
      _SchoolLearningTracksPageState();
}

class _SchoolLearningTracksPageState extends State<SchoolLearningTracksPage> {
  bool _loading = true;
  String? _error;
  List<LearningTrack> _tracks = [];
  List<LearningTrackRoom> _rooms = [];

  static const List<String> _colorChoices = [
    '#7C3AED',
    '#0284C7',
    '#D97706',
    '#059669',
    '#DB2777',
    '#DC2626',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        LearningTrackService.listTracks(),
        LearningTrackService.listTrackRooms(),
      ]);
      if (!mounted) return;
      setState(() {
        _tracks = results[0] as List<LearningTrack>;
        _rooms = results[1] as List<LearningTrackRoom>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  Color _colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x7C3AED;
    return Color(0xFF000000 | value);
  }

  Future<void> _showTrackDialog({LearningTrack? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    String selectedColor = existing?.color ?? _colorChoices.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'เพิ่มสายการเรียน' : 'แก้ไขสายการเรียน'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสายการเรียน',
                    hintText: 'เช่น วิทย์-คณิต, สายภาษา',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('สี', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _colorChoices.map((hex) {
                    final selected = hex == selectedColor;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _colorFromHex(hex),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.black87, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;

    try {
      if (existing == null) {
        await LearningTrackService.createTrack(name: name, color: selectedColor);
      } else {
        await LearningTrackService.updateTrack(
          trackId: existing.trackId,
          name: name,
          color: selectedColor,
          sortOrder: existing.sortOrder,
        );
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _deleteTrack(LearningTrack track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบสายการเรียน?'),
        content: Text(
          'ลบ "${track.name}" — ห้องเรียนที่กำหนดสายนี้ไว้จะถูกยกเลิกการกำหนดด้วย',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await LearningTrackService.deleteTrack(track.trackId);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _assignRoom(LearningTrackRoom room, String? trackId) async {
    try {
      await LearningTrackService.setTrackRoom(
        gradeLevel: room.gradeLevel,
        room: room.room,
        trackId: trackId,
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กำหนดสายไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolAdminPalette.background,
      appBar: AppBar(
        title: const Text('สายการเรียน'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTracksSection(),
                      const SizedBox(height: 24),
                      _buildRoomsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTracksSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'สายการเรียน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showTrackDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('เพิ่มสาย'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ชื่อสายการเรียนของโรงเรียนนี้ — ใช้แสดงในหน้าภาพรวมผู้บริหาร',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          if (_tracks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'ยังไม่มีสายการเรียน กด "เพิ่มสาย" เพื่อเริ่มตั้งค่า',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          else
            ..._tracks.map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _colorFromHex(t.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(t.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showTrackDialog(existing: t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: () => _deleteTrack(t),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กำหนดสายให้ห้องเรียน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ห้องเรียนทุกห้องที่มีนักเรียนในปีการศึกษานี้ — เลือกสายการเรียนของแต่ละห้อง',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          if (_rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'ยังไม่มีห้องเรียนที่มีนักเรียนในปีการศึกษานี้',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          else
            ..._rooms.map((r) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.gradeLevel} / ${r.room}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${r.studentCount} คน',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String?>(
                        value: r.trackId,
                        isDense: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('ไม่ระบุสาย'),
                          ),
                          ..._tracks.map(
                            (t) => DropdownMenuItem<String?>(
                              value: t.trackId,
                              child: Text(t.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => _assignRoom(r, value),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
