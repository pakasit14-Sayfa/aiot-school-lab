import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

typedef SchoolAdminLearningTrackLoader = Future<List<LearningTrack>> Function();
typedef SchoolAdminLearningTrackRoomLoader =
    Future<List<LearningTrackRoom>> Function();
typedef SchoolAdminLearningTrackCreate =
    Future<String> Function({required String name, required String color});
typedef SchoolAdminLearningTrackUpdate =
    Future<void> Function({
      required String trackId,
      required String name,
      required String color,
      required int sortOrder,
    });
typedef SchoolAdminLearningTrackDelete = Future<void> Function(String trackId);
typedef SchoolAdminLearningTrackRoomSetter =
    Future<void> Function({
      required String gradeLevel,
      required String room,
      required String? trackId,
    });

final class SchoolAdminLearningTracksSnapshot {
  SchoolAdminLearningTracksSnapshot({
    required List<LearningTrack> tracks,
    required List<LearningTrackRoom> rooms,
  }) : tracks = List<LearningTrack>.unmodifiable(tracks),
       rooms = List<LearningTrackRoom>.unmodifiable(rooms);

  final List<LearningTrack> tracks;
  final List<LearningTrackRoom> rooms;

  bool get isEmpty => tracks.isEmpty && rooms.isEmpty;
}

final class SchoolAdminLearningTracksController extends ChangeNotifier {
  SchoolAdminLearningTracksController({
    required SchoolAdminLearningTrackLoader loadTracks,
    required SchoolAdminLearningTrackRoomLoader loadRooms,
    required SchoolAdminLearningTrackCreate createTrack,
    required SchoolAdminLearningTrackUpdate updateTrack,
    required SchoolAdminLearningTrackDelete deleteTrack,
    required SchoolAdminLearningTrackRoomSetter setTrackRoom,
  }) : _loadTracks = loadTracks,
       _loadRooms = loadRooms,
       _createTrack = createTrack,
       _updateTrack = updateTrack,
       _deleteTrack = deleteTrack,
       _setTrackRoom = setTrackRoom;

  static const Set<String> permittedColors = <String>{
    '#7C3AED',
    '#0284C7',
    '#D97706',
    '#059669',
    '#DB2777',
    '#DC2626',
  };

  final SchoolAdminLearningTrackLoader _loadTracks;
  final SchoolAdminLearningTrackRoomLoader _loadRooms;
  final SchoolAdminLearningTrackCreate _createTrack;
  final SchoolAdminLearningTrackUpdate _updateTrack;
  final SchoolAdminLearningTrackDelete _deleteTrack;
  final SchoolAdminLearningTrackRoomSetter _setTrackRoom;

  SchoolAdminAsyncState<SchoolAdminLearningTracksSnapshot> _state =
      const SchoolAdminLoading<SchoolAdminLearningTracksSnapshot>();
  SchoolAdminLearningTracksSnapshot? _lastConfirmedData;
  final Set<String> _busyKeys = <String>{};
  bool _disposed = false;

  SchoolAdminAsyncState<SchoolAdminLearningTracksSnapshot> get state => _state;
  SchoolAdminLearningTracksSnapshot? get lastConfirmedData =>
      _lastConfirmedData;
  bool get isCreating => _busyKeys.contains('create');
  bool isTrackBusy(String trackId) =>
      _busyKeys.contains('track:${trackId.trim()}');
  bool isRoomBusy(String gradeLevel, String room) =>
      _busyKeys.contains('room:${gradeLevel.trim()}/${room.trim()}');

  Future<void> load() async {
    final previous = _lastConfirmedData;
    _publish(SchoolAdminLoading(previousData: previous));
    try {
      _publishCanonical(await _loadCanonical());
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: 'โหลดข้อมูลสายการเรียนไม่สำเร็จ',
          error: error,
          stackTrace: stackTrace,
          previousData: previous,
        ),
      );
    }
  }

  Future<bool> create({required String name, required String color}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || !permittedColors.contains(color)) {
      return false;
    }
    return _runMutation(
      key: 'create',
      failureMessage: 'บันทึกสายการเรียนไม่สำเร็จ',
      action: () async {
        final id = (await _createTrack(
          name: normalizedName,
          color: color,
        )).trim();
        if (id.isEmpty || id.toLowerCase() == 'null') {
          throw StateError('backend_track_id_missing');
        }
        final canonical = await _loadCanonical();
        if (!canonical.tracks.any(
          (track) =>
              track.trackId == id &&
              track.name == normalizedName &&
              track.color == color,
        )) {
          throw StateError('backend_create_not_confirmed');
        }
        return canonical;
      },
    );
  }

  Future<bool> update({
    required String trackId,
    required String name,
    required String color,
    required int sortOrder,
  }) async {
    final id = trackId.trim();
    final normalizedName = name.trim();
    if (id.isEmpty ||
        normalizedName.isEmpty ||
        sortOrder < 0 ||
        !permittedColors.contains(color)) {
      return false;
    }
    return _runMutation(
      key: 'track:$id',
      failureMessage: 'บันทึกสายการเรียนไม่สำเร็จ',
      action: () async {
        await _updateTrack(
          trackId: id,
          name: normalizedName,
          color: color,
          sortOrder: sortOrder,
        );
        final canonical = await _loadCanonical();
        if (!canonical.tracks.any(
          (track) =>
              track.trackId == id &&
              track.name == normalizedName &&
              track.color == color &&
              track.sortOrder == sortOrder,
        )) {
          throw StateError('backend_update_not_confirmed');
        }
        return canonical;
      },
    );
  }

  Future<bool> delete(String trackId) async {
    final id = trackId.trim();
    if (id.isEmpty) return false;
    return _runMutation(
      key: 'track:$id',
      failureMessage: 'ลบสายการเรียนไม่สำเร็จ',
      action: () async {
        await _deleteTrack(id);
        final canonical = await _loadCanonical();
        if (canonical.tracks.any((track) => track.trackId == id)) {
          throw StateError('backend_delete_not_confirmed');
        }
        return canonical;
      },
    );
  }

  Future<bool> assignRoom({
    required String gradeLevel,
    required String room,
    required String? trackId,
  }) async {
    final grade = gradeLevel.trim();
    final normalizedRoom = room.trim();
    final normalizedTrack = trackId?.trim();
    if (grade.isEmpty ||
        normalizedRoom.isEmpty ||
        (normalizedTrack != null && normalizedTrack.isEmpty)) {
      return false;
    }
    return _runMutation(
      key: 'room:$grade/$normalizedRoom',
      failureMessage: 'กำหนดสายการเรียนให้ห้องไม่สำเร็จ',
      action: () async {
        await _setTrackRoom(
          gradeLevel: grade,
          room: normalizedRoom,
          trackId: normalizedTrack,
        );
        final canonical = await _loadCanonical();
        if (!canonical.rooms.any(
          (item) =>
              item.gradeLevel == grade &&
              item.room == normalizedRoom &&
              item.trackId == normalizedTrack,
        )) {
          throw StateError('backend_room_assignment_not_confirmed');
        }
        return canonical;
      },
    );
  }

  Future<bool> _runMutation({
    required String key,
    required String failureMessage,
    required Future<SchoolAdminLearningTracksSnapshot> Function() action,
  }) async {
    if (_disposed || !_busyKeys.add(key)) return false;
    final previous = _lastConfirmedData;
    notifyListeners();
    try {
      final canonical = await action();
      if (_disposed) return false;
      _publishCanonical(canonical);
      return true;
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: failureMessage,
          error: error,
          stackTrace: stackTrace,
          previousData: previous,
        ),
      );
      return false;
    } finally {
      _busyKeys.remove(key);
      if (!_disposed) notifyListeners();
    }
  }

  Future<SchoolAdminLearningTracksSnapshot> _loadCanonical() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _loadTracks(),
      _loadRooms(),
    ]);
    return SchoolAdminLearningTracksSnapshot(
      tracks: results[0] as List<LearningTrack>,
      rooms: results[1] as List<LearningTrackRoom>,
    );
  }

  void _publishCanonical(SchoolAdminLearningTracksSnapshot snapshot) {
    if (_disposed) return;
    _lastConfirmedData = snapshot;
    _publish(
      snapshot.isEmpty
          ? const SchoolAdminEmpty<SchoolAdminLearningTracksSnapshot>()
          : SchoolAdminData<SchoolAdminLearningTracksSnapshot>(snapshot),
    );
  }

  void _publish(SchoolAdminAsyncState<SchoolAdminLearningTracksSnapshot> next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
