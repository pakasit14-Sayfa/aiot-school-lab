import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';
import 'controllers/school_admin_async_state.dart';
import 'controllers/school_admin_learning_tracks_controller.dart';

class SchoolLearningTracksPage extends StatefulWidget {
  const SchoolLearningTracksPage({super.key, this.controller});

  final SchoolAdminLearningTracksController? controller;

  @override
  State<SchoolLearningTracksPage> createState() =>
      _SchoolLearningTracksPageState();
}

class _SchoolLearningTracksPageState extends State<SchoolLearningTracksPage> {
  late final SchoolAdminLearningTracksController _controller;
  late final bool _ownsController;

  static const List<String> _colorChoices = <String>[
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
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SchoolAdminLearningTracksController(
          loadTracks: LearningTrackService.listTracks,
          loadRooms: LearningTrackService.listTrackRooms,
          createTrack: ({required name, required color}) =>
              LearningTrackService.createTrack(name: name, color: color),
          updateTrack:
              ({
                required trackId,
                required name,
                required color,
                required sortOrder,
              }) => LearningTrackService.updateTrack(
                trackId: trackId,
                name: name,
                color: color,
                sortOrder: sortOrder,
              ),
          deleteTrack: LearningTrackService.deleteTrack,
          setTrackRoom:
              ({required gradeLevel, required room, required trackId}) =>
                  LearningTrackService.setTrackRoom(
                    gradeLevel: gradeLevel,
                    room: room,
                    trackId: trackId,
                  ),
        );
    _controller.addListener(_onControllerChanged);
    _controller.load();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Color _colorFromHex(String hex) {
    final value =
        int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0x7C3AED;
    return Color(0xFF000000 | value);
  }

  SchoolAdminLearningTracksSnapshot? get _visibleSnapshot =>
      switch (_controller.state) {
        SchoolAdminData<SchoolAdminLearningTracksSnapshot>(
          value: final value,
        ) =>
          value,
        SchoolAdminLoading<SchoolAdminLearningTracksSnapshot>(
          previousData: final value,
        ) =>
          value,
        SchoolAdminError<SchoolAdminLearningTracksSnapshot>(
          previousData: final value,
        ) =>
          value,
        SchoolAdminEmpty<SchoolAdminLearningTracksSnapshot>() =>
          _controller.lastConfirmedData,
      };

  Future<void> _showTrackDialog({LearningTrack? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var selectedColor = existing?.color ?? _colorChoices.first;
    String? dialogError;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final submitting = existing == null
              ? _controller.isCreating
              : _controller.isTrackBusy(existing.trackId);
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: Text(
                existing == null ? 'เพิ่มสายการเรียน' : 'แก้ไขสายการเรียน',
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      enabled: !submitting,
                      decoration: InputDecoration(
                        labelText: 'ชื่อสายการเรียน',
                        hintText: 'เช่น วิทย์-คณิต, สายภาษา',
                        errorText: dialogError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'สี',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: _colorChoices
                          .map(
                            (hex) => GestureDetector(
                              onTap: submitting
                                  ? null
                                  : () =>
                                        setDialogState(
                                          () => selectedColor = hex,
                                        ),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _colorFromHex(hex),
                                  shape: BoxShape.circle,
                                  border: hex == selectedColor
                                      ? Border.all(
                                          color: Colors.black87,
                                          width: 2.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            setDialogState(
                              () => dialogError = 'กรุณาระบุชื่อสายการเรียน',
                            );
                            return;
                          }
                          setDialogState(() => dialogError = null);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dialogContext);
                          final succeeded = existing == null
                              ? await _controller.create(
                                  name: name,
                                  color: selectedColor,
                                )
                              : await _controller.update(
                                  trackId: existing.trackId,
                                  name: name,
                                  color: selectedColor,
                                  sortOrder: existing.sortOrder,
                                );
                          if (!mounted) return;
                          if (succeeded) {
                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('บันทึกสายการเรียนเรียบร้อยแล้ว'),
                              ),
                            );
                          } else {
                            setDialogState(
                              () => dialogError = 'บันทึกสายการเรียนไม่สำเร็จ',
                            );
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            ),
          );
        },
      ),
    );
    // Not disposed here: the dialog is driven by an AnimatedBuilder over
    // _controller, which can still rebuild this field mid exit-transition
    // after a mutation settles — disposing immediately races that rebuild
    // (same tradeoff as noteController in the incident inbox close dialog).
  }

  Future<void> _deleteTrack(LearningTrack track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบสายการเรียน?'),
        content: Text(
          'ลบ "${track.name}" — ห้องเรียนที่กำหนดสายนี้ไว้จะถูกยกเลิกการกำหนดด้วย',
        ),
        actions: <Widget>[
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
    final succeeded = await _controller.delete(track.trackId);
    if (!mounted) return;
    _showMessage(
      succeeded ? 'ลบสายการเรียนเรียบร้อยแล้ว' : 'ลบสายการเรียนไม่สำเร็จ',
    );
  }

  Future<void> _assignRoom(LearningTrackRoom room, String? trackId) async {
    final succeeded = await _controller.assignRoom(
      gradeLevel: room.gradeLevel,
      room: room.room,
      trackId: trackId,
    );
    if (!mounted) return;
    _showMessage(
      succeeded
          ? 'กำหนดสายการเรียนเรียบร้อยแล้ว'
          : 'กำหนดสายการเรียนให้ห้องไม่สำเร็จ',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final snapshot = _visibleSnapshot;
    final initialLoading =
        state is SchoolAdminLoading<SchoolAdminLearningTracksSnapshot> &&
        snapshot == null;
    final initialError =
        state is SchoolAdminError<SchoolAdminLearningTracksSnapshot> &&
        snapshot == null;

    return Scaffold(
      backgroundColor: SchoolAdminPalette.background,
      appBar: AppBar(
        title: const Text('สายการเรียน'),
        actions: <Widget>[
          IconButton(
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: initialLoading ? null : _controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: initialLoading
          ? const Center(child: CircularProgressIndicator())
          : initialError
          ? _InitialError(onRetry: _controller.load)
          : RefreshIndicator(
              onRefresh: _controller.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (state
                      case SchoolAdminError<SchoolAdminLearningTracksSnapshot>(
                        message: final message,
                      )) ...<Widget>[
                    _ErrorBanner(message: message, onRetry: _controller.load),
                    const SizedBox(height: 12),
                  ],
                  _buildTracksSection(
                    snapshot?.tracks ?? const <LearningTrack>[],
                  ),
                  const SizedBox(height: 24),
                  _buildRoomsSection(
                    snapshot?.rooms ?? const <LearningTrackRoom>[],
                    snapshot?.tracks ?? const <LearningTrack>[],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTracksSection(List<LearningTrack> tracks) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'สายการเรียน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: _controller.isCreating
                  ? null
                  : () => _showTrackDialog(),
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
        if (tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'ยังไม่มีข้อมูล',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          )
        else
          ...tracks.map(
            (track) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _colorFromHex(track.color),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(track.name),
              trailing: _controller.isTrackBusy(track.trackId)
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showTrackDialog(existing: track),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          onPressed: () => _deleteTrack(track),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    ),
  );

  Widget _buildRoomsSection(
    List<LearningTrackRoom> rooms,
    List<LearningTrack> tracks,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
        if (rooms.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'ยังไม่มีข้อมูล',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          )
        else
          ...rooms.map((room) {
            final busy = _controller.isRoomBusy(room.gradeLevel, room.room);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${room.gradeLevel} / ${room.room}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${room.studentCount} คน',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: busy
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : DropdownButtonFormField<String?>(
                            isExpanded: true,
                            value: room.trackId,
                            isDense: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('ไม่ระบุสาย'),
                              ),
                              ...tracks.map(
                                (track) => DropdownMenuItem<String?>(
                                  value: track.trackId,
                                  child: Text(track.name),
                                ),
                              ),
                            ],
                            onChanged: (value) => _assignRoom(room, value),
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

class _InitialError extends StatelessWidget {
  const _InitialError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('โหลดข้อมูลสายการเรียนไม่สำเร็จ'),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('ลองใหม่')),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFEF2F2),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    ),
  );
}
