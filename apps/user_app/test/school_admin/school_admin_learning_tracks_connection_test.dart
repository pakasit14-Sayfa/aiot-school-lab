import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_learning_tracks_controller.dart';
import 'package:my_first_app/pages/school_admin/school_learning_tracks_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets('shows a distinct loading indicator before first load settles', (
    tester,
  ) async {
    final gate = Completer<List<LearningTrack>>();
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = _controller(loadTracks: () => gate.future);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: SchoolLearningTracksPage(controller: controller)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
    gate.complete(<LearningTrack>[]);
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีข้อมูล'), findsNWidgets(2));
  });

  testWidgets('loading then renders exact empty heading in both cards', (
    tester,
  ) async {
    await _pump(tester, _controller());
    expect(find.text('ยังไม่มีข้อมูล'), findsNWidgets(2));
  });

  testWidgets('renders canonical tracks and rooms', (tester) async {
    await _pump(
      tester,
      _controller(
        loadTracks: () async => <LearningTrack>[_track()],
        loadRooms: () async => <LearningTrackRoom>[
          _room(trackId: 'track-1', trackName: 'วิทย์-คณิต'),
        ],
      ),
    );
    expect(find.text('วิทย์-คณิต'), findsWidgets);
    expect(find.text('ม.1 / 1'), findsOneWidget);
    expect(find.text('30 คน'), findsOneWidget);
  });

  testWidgets('initial failure hides raw error and retry succeeds', (
    tester,
  ) async {
    var fail = true;
    await _pump(
      tester,
      _controller(
        loadTracks: () async {
          if (fail) throw StateError('sensitive database text');
          return <LearningTrack>[_track()];
        },
      ),
    );
    expect(find.text('โหลดข้อมูลสายการเรียนไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('sensitive database text'), findsNothing);
    fail = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('วิทย์-คณิต'), findsOneWidget);
  });

  testWidgets('refresh failure keeps canonical cards and retry', (
    tester,
  ) async {
    var fail = false;
    await _pump(
      tester,
      _controller(
        loadTracks: () async {
          if (fail) throw StateError('raw');
          return <LearningTrack>[_track()];
        },
      ),
    );
    fail = true;
    await tester.tap(find.byTooltip('รีเฟรชข้อมูล'));
    await tester.pumpAndSettle();
    expect(find.text('โหลดข้อมูลสายการเรียนไม่สำเร็จ'), findsOneWidget);
    expect(find.text('วิทย์-คณิต'), findsOneWidget);
    expect(find.textContaining('raw'), findsNothing);
  });

  testWidgets(
    'failed create keeps dialog input for retry and has no fake success',
    (tester) async {
      await _pump(
        tester,
        _controller(
          createTrack: ({required name, required color}) async => 'missing',
        ),
      );
      await tester.tap(find.text('เพิ่มสาย'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'สายภาษา');
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(find.text('สายภาษา'), findsOneWidget);
      expect(find.text('บันทึกสายการเรียนไม่สำเร็จ'), findsWidgets);
      expect(find.textContaining('เรียบร้อย'), findsNothing);
    },
  );

  testWidgets('failed assignment keeps the last confirmed dropdown value', (
    tester,
  ) async {
    await _pump(
      tester,
      _controller(
        loadTracks: () async => <LearningTrack>[
          _track(),
          _track(id: 'track-2', name: 'ภาษา'),
        ],
        loadRooms: () async => <LearningTrackRoom>[
          _room(trackId: 'track-1', trackName: 'วิทย์-คณิต'),
        ],
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษา').last);
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String?>>(
      find.byType(DropdownButtonFormField<String?>),
    );
    expect(dropdown.initialValue, 'track-1');
    expect(find.text('กำหนดสายการเรียนให้ห้องไม่สำเร็จ'), findsWidgets);
  });

  testWidgets('create success shows the new track only after canonical refetch', (
    tester,
  ) async {
    var backend = <LearningTrack>[];
    await _pump(
      tester,
      _controller(
        loadTracks: () async => List<LearningTrack>.of(backend),
        createTrack: ({required name, required color}) async {
          backend = <LearningTrack>[
            LearningTrack(
              trackId: 'track-new',
              name: name,
              color: color,
              sortOrder: 0,
            ),
          ];
          return 'track-new';
        },
      ),
    );
    await tester.tap(find.text('เพิ่มสาย'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'สายภาษา');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('สายภาษา'), findsOneWidget);
    expect(find.text('บันทึกสายการเรียนเรียบร้อยแล้ว'), findsWidgets);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('update success renders the confirmed fields after refetch', (
    tester,
  ) async {
    var backend = <LearningTrack>[_track()];
    await _pump(
      tester,
      _controller(
        loadTracks: () async => List<LearningTrack>.of(backend),
        updateTrack:
            ({
              required trackId,
              required name,
              required color,
              required sortOrder,
            }) async {
              backend = <LearningTrack>[
                LearningTrack(
                  trackId: trackId,
                  name: name,
                  color: color,
                  sortOrder: sortOrder,
                ),
              ];
            },
      ),
    );
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ภาษาแก้ไข');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('ภาษาแก้ไข'), findsOneWidget);
    expect(find.text('บันทึกสายการเรียนเรียบร้อยแล้ว'), findsWidgets);
  });

  testWidgets('delete success removes the track only after canonical refetch', (
    tester,
  ) async {
    var backend = <LearningTrack>[_track()];
    await _pump(
      tester,
      _controller(
        loadTracks: () async => List<LearningTrack>.of(backend),
        deleteTrack: (id) async => backend = <LearningTrack>[],
      ),
    );
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();
    expect(find.text('วิทย์-คณิต'), findsNothing);
    expect(find.text('ลบสายการเรียนเรียบร้อยแล้ว'), findsWidgets);
  });

  testWidgets('delete failure keeps the track visible with no fake success', (
    tester,
  ) async {
    await _pump(
      tester,
      _controller(
        loadTracks: () async => <LearningTrack>[_track()],
        deleteTrack: (id) async {}, // backend silently ignores the delete
      ),
    );
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();
    expect(find.text('วิทย์-คณิต'), findsOneWidget);
    expect(find.text('ลบสายการเรียนไม่สำเร็จ'), findsWidgets);
  });

  testWidgets('room assignment success is visible only after canonical refetch', (
    tester,
  ) async {
    var rooms = <LearningTrackRoom>[_room(trackId: null)];
    await _pump(
      tester,
      _controller(
        loadTracks: () async => <LearningTrack>[
          _track(),
          _track(id: 'track-2', name: 'ภาษา'),
        ],
        loadRooms: () async => List<LearningTrackRoom>.of(rooms),
        setTrackRoom:
            ({required gradeLevel, required room, required trackId}) async {
              rooms = <LearningTrackRoom>[
                _room(trackId: trackId, trackName: 'ภาษา'),
              ];
            },
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษา').last);
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String?>>(
      find.byType(DropdownButtonFormField<String?>),
    );
    expect(dropdown.initialValue, 'track-2');
    expect(find.text('กำหนดสายการเรียนเรียบร้อยแล้ว'), findsWidgets);
  });

  testWidgets('clearing a room assignment persists only after canonical refetch', (
    tester,
  ) async {
    var rooms = <LearningTrackRoom>[
      _room(trackId: 'track-1', trackName: 'วิทย์-คณิต'),
    ];
    await _pump(
      tester,
      _controller(
        loadTracks: () async => <LearningTrack>[_track()],
        loadRooms: () async => List<LearningTrackRoom>.of(rooms),
        setTrackRoom:
            ({required gradeLevel, required room, required trackId}) async {
              rooms = <LearningTrackRoom>[_room(trackId: trackId)];
            },
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ไม่ระบุสาย').last);
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String?>>(
      find.byType(DropdownButtonFormField<String?>),
    );
    expect(dropdown.initialValue, isNull);
    expect(find.text('กำหนดสายการเรียนเรียบร้อยแล้ว'), findsWidgets);
  });

  testWidgets('controls stay disabled while their own mutation is active', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pump(
      tester,
      _controller(
        loadTracks: () async => <LearningTrack>[_track()],
        deleteTrack: (id) async => gate.future,
      ),
    );
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
  });
}

Future<void> _pump(
  WidgetTester tester,
  SchoolAdminLearningTracksController controller,
) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    controller.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(home: SchoolLearningTracksPage(controller: controller)),
  );
  await tester.pumpAndSettle();
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
      createTrack ?? ({required name, required color}) async => 'missing',
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

LearningTrack _track({String id = 'track-1', String name = 'วิทย์-คณิต'}) =>
    LearningTrack(trackId: id, name: name, color: '#7C3AED', sortOrder: 0);

LearningTrackRoom _room({String? trackId, String? trackName}) =>
    LearningTrackRoom(
      gradeLevel: 'ม.1',
      room: '1',
      studentCount: 30,
      trackId: trackId,
      trackName: trackName,
    );
