import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_async_state.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_learning_tracks_controller.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test(
    'load publishes immutable canonical data and loads concurrently',
    () async {
      final tracksGate = Completer<List<LearningTrack>>();
      final roomsGate = Completer<List<LearningTrackRoom>>();
      var roomsStarted = false;
      final controller = _controller(
        loadTracks: () => tracksGate.future,
        loadRooms: () {
          roomsStarted = true;
          return roomsGate.future;
        },
      );

      final loading = controller.load();
      expect(roomsStarted, isTrue);
      tracksGate.complete(<LearningTrack>[_track()]);
      roomsGate.complete(<LearningTrackRoom>[_room()]);
      await loading;

      final snapshot =
          (controller.state
                  as SchoolAdminData<SchoolAdminLearningTracksSnapshot>)
              .value;
      expect(snapshot.tracks.single.trackId, 'track-1');
      expect(
        () => snapshot.tracks.add(_track(id: 'x')),
        throwsUnsupportedError,
      );
      expect(() => snapshot.rooms.clear(), throwsUnsupportedError);
    },
  );

  test('empty load is distinct and failures use stable copy', () async {
    final empty = _controller();
    await empty.load();
    expect(
      empty.state,
      isA<SchoolAdminEmpty<SchoolAdminLearningTracksSnapshot>>(),
    );

    final failing = _controller(
      loadTracks: () async => throw StateError('raw db'),
    );
    await failing.load();
    final error =
        failing.state as SchoolAdminError<SchoolAdminLearningTracksSnapshot>;
    expect(error.message, 'โหลดข้อมูลสายการเรียนไม่สำเร็จ');
  });

  test('failed refresh retains last confirmed snapshot', () async {
    var fail = false;
    final controller = _controller(
      loadTracks: () async {
        if (fail) throw StateError('offline');
        return <LearningTrack>[_track()];
      },
    );
    await controller.load();
    fail = true;
    await controller.load();

    final error =
        controller.state as SchoolAdminError<SchoolAdminLearningTracksSnapshot>;
    expect(error.previousData!.tracks.single.trackId, 'track-1');
  });

  test(
    'create validates input and succeeds only after canonical confirmation',
    () async {
      var backend = <LearningTrack>[];
      var createCalls = 0;
      final controller = _controller(
        loadTracks: () async => List<LearningTrack>.of(backend),
        createTrack: ({required name, required color}) async {
          createCalls++;
          backend = <LearningTrack>[_track(name: name, color: color)];
          return 'track-1';
        },
      );
      await controller.load();

      expect(await controller.create(name: ' ', color: '#7C3AED'), isFalse);
      expect(await controller.create(name: 'STEM', color: '#BADBAD'), isFalse);
      expect(createCalls, 0);
      expect(await controller.create(name: ' STEM ', color: '#7C3AED'), isTrue);
      expect(
        (controller.state as SchoolAdminData<SchoolAdminLearningTracksSnapshot>)
            .value
            .tracks
            .single
            .name,
        'STEM',
      );
    },
  );

  test('create failure retains data and uses stable copy', () async {
    final controller = _controller(
      loadTracks: () async => <LearningTrack>[_track()],
      createTrack: ({required name, required color}) async => 'missing-id',
    );
    await controller.load();

    expect(await controller.create(name: 'ภาษา', color: '#0284C7'), isFalse);
    final error =
        controller.state as SchoolAdminError<SchoolAdminLearningTracksSnapshot>;
    expect(error.message, 'บันทึกสายการเรียนไม่สำเร็จ');
    expect(error.previousData!.tracks.single.trackId, 'track-1');
  });

  test('create returns false and keeps previous data when the backend '
      'confirms no id', () async {
    final controller = _controller(
      loadTracks: () async => <LearningTrack>[_track()],
      createTrack: ({required name, required color}) async => '',
    );
    await controller.load();

    expect(await controller.create(name: 'ภาษา', color: '#0284C7'), isFalse);
    final error =
        controller.state as SchoolAdminError<SchoolAdminLearningTracksSnapshot>;
    expect(error.message, 'บันทึกสายการเรียนไม่สำเร็จ');
    expect(error.previousData!.tracks.single.trackId, 'track-1');
  });

  test('update validates and confirms all canonical fields', () async {
    var backend = <LearningTrack>[_track()];
    final controller = _controller(
      loadTracks: () async => List<LearningTrack>.of(backend),
      updateTrack:
          ({
            required trackId,
            required name,
            required color,
            required sortOrder,
          }) async {
            backend = <LearningTrack>[
              _track(
                id: trackId,
                name: name,
                color: color,
                sortOrder: sortOrder,
              ),
            ];
          },
    );
    await controller.load();
    expect(
      await controller.update(
        trackId: '',
        name: 'x',
        color: '#7C3AED',
        sortOrder: 0,
      ),
      isFalse,
    );
    expect(
      await controller.update(
        trackId: 'track-1',
        name: 'x',
        color: '#7C3AED',
        sortOrder: -1,
      ),
      isFalse,
    );
    expect(
      await controller.update(
        trackId: 'track-1',
        name: 'ภาษา',
        color: '#0284C7',
        sortOrder: 2,
      ),
      isTrue,
    );
  });

  test('update returns false and keeps previous data when the backend '
      'does not confirm the change', () async {
    final controller = _controller(
      loadTracks: () async => <LearningTrack>[_track()],
      updateTrack:
          ({
            required trackId,
            required name,
            required color,
            required sortOrder,
          }) async {}, // backend silently ignores the write
    );
    await controller.load();
    expect(
      await controller.update(
        trackId: 'track-1',
        name: 'ภาษา',
        color: '#0284C7',
        sortOrder: 2,
      ),
      isFalse,
    );
    final error =
        controller.state as SchoolAdminError<SchoolAdminLearningTracksSnapshot>;
    expect(error.message, 'บันทึกสายการเรียนไม่สำเร็จ');
    expect(error.previousData!.tracks.single.name, 'วิทย์-คณิต');
  });

  test('delete and room assignment require canonical confirmation', () async {
    var tracks = <LearningTrack>[_track()];
    var rooms = <LearningTrackRoom>[_room()];
    final controller = _controller(
      loadTracks: () async => List<LearningTrack>.of(tracks),
      loadRooms: () async => List<LearningTrackRoom>.of(rooms),
      deleteTrack: (id) async => tracks = <LearningTrack>[],
      setTrackRoom:
          ({required gradeLevel, required room, required trackId}) async {
            rooms = <LearningTrackRoom>[
              _room(
                trackId: trackId,
                trackName: trackId == null ? null : 'วิทย์-คณิต',
              ),
            ];
          },
    );
    await controller.load();
    expect(
      await controller.assignRoom(gradeLevel: ' ', room: '1', trackId: null),
      isFalse,
    );
    expect(
      await controller.assignRoom(
        gradeLevel: 'ม.1',
        room: '1',
        trackId: 'track-1',
      ),
      isTrue,
    );
    expect(
      await controller.assignRoom(gradeLevel: 'ม.1', room: '1', trackId: null),
      isTrue,
    );
    expect(await controller.delete('track-1'), isTrue);
  });

  test(
    'per-item busy keys reject double submit without blocking other items',
    () async {
      final firstGate = Completer<void>();
      var calls = 0;
      final controller = _controller(
        loadTracks: () async => <LearningTrack>[
          _track(),
          _track(id: 'track-2'),
        ],
        deleteTrack: (id) async {
          calls++;
          if (id == 'track-1') await firstGate.future;
        },
      );
      await controller.load();

      final first = controller.delete('track-1');
      expect(controller.isTrackBusy('track-1'), isTrue);
      expect(await controller.delete('track-1'), isFalse);
      expect(controller.isTrackBusy('track-2'), isFalse);
      firstGate.complete();
      expect(await first, isFalse); // backend still contains the track
      expect(calls, 1);
    },
  );

  test('delete returns false and keeps previous data when the backend '
      'does not remove the track', () async {
    final controller = _controller(
      loadTracks: () async => <LearningTrack>[_track()],
      deleteTrack: (id) async {}, // backend silently ignores the delete
    );
    await controller.load();
    expect(await controller.delete('track-1'), isFalse);
    final error =
        controller.state as SchoolAdminError<SchoolAdminLearningTracksSnapshot>;
    expect(error.message, 'ลบสายการเรียนไม่สำเร็จ');
    expect(error.previousData!.tracks.single.trackId, 'track-1');
  });

  test('failed room assignment keeps the previous track id and reports '
      'a stable error', () async {
    final controller = _controller(
      loadRooms: () async => <LearningTrackRoom>[_room(trackId: null)],
      setTrackRoom:
          ({required gradeLevel, required room, required trackId}) async {
            // backend accepts the write but never actually persists it
          },
    );
    await controller.load();
    expect(
      await controller.assignRoom(
        gradeLevel: 'ม.1',
        room: '1',
        trackId: 'track-1',
      ),
      isFalse,
    );
    final error =
        controller.state as SchoolAdminError<SchoolAdminLearningTracksSnapshot>;
    expect(error.message, 'กำหนดสายการเรียนให้ห้องไม่สำเร็จ');
    expect(error.previousData!.rooms.single.trackId, isNull);
  });
}

SchoolAdminLearningTracksController _controller({
  Future<List<LearningTrack>> Function()? loadTracks,
  Future<List<LearningTrackRoom>> Function()? loadRooms,
  SchoolAdminLearningTrackCreate? createTrack,
  SchoolAdminLearningTrackUpdate? updateTrack,
  Future<void> Function(String trackId)? deleteTrack,
  SchoolAdminLearningTrackRoomSetter? setTrackRoom,
}) => SchoolAdminLearningTracksController(
  loadTracks: loadTracks ?? () async => <LearningTrack>[],
  loadRooms: loadRooms ?? () async => <LearningTrackRoom>[],
  createTrack:
      createTrack ?? ({required name, required color}) async => 'unused',
  updateTrack:
      updateTrack ??
      ({
        required trackId,
        required name,
        required color,
        required sortOrder,
      }) async {},
  deleteTrack: deleteTrack ?? (trackId) async {},
  setTrackRoom:
      setTrackRoom ??
      ({required gradeLevel, required room, required trackId}) async {},
);

LearningTrack _track({
  String id = 'track-1',
  String name = 'วิทย์-คณิต',
  String color = '#7C3AED',
  int sortOrder = 0,
}) =>
    LearningTrack(trackId: id, name: name, color: color, sortOrder: sortOrder);

LearningTrackRoom _room({String? trackId, String? trackName}) =>
    LearningTrackRoom(
      gradeLevel: 'ม.1',
      room: '1',
      studentCount: 30,
      trackId: trackId,
      trackName: trackName,
    );
