import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_async_state.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_incident_inbox_controller.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('load exposes an immutable canonical incident list', () async {
    final controller = _controller(
      loadIncidents: () async => <TeacherIncidentReport>[_report()],
    );

    await controller.load();

    final state =
        controller.state as SchoolAdminData<List<TeacherIncidentReport>>;
    expect(state.value.single.id, 'incident-1');
    expect(
      () => state.value.add(_report(id: 'incident-2')),
      throwsUnsupportedError,
    );
  });

  test('load distinguishes an empty database result', () async {
    final controller = _controller(
      loadIncidents: () async => const <TeacherIncidentReport>[],
    );

    await controller.load();

    expect(
      controller.state,
      isA<SchoolAdminEmpty<List<TeacherIncidentReport>>>(),
    );
  });

  test(
    'load failure uses stable Thai copy without exposing raw errors',
    () async {
      final controller = _controller(
        loadIncidents: () async => throw StateError('secret backend detail'),
      );

      await controller.load();

      final state =
          controller.state as SchoolAdminError<List<TeacherIncidentReport>>;
      expect(state.message, 'โหลดรายการเหตุการณ์ไม่สำเร็จ');
      expect(state.message, isNot(contains('secret backend detail')));
    },
  );

  test(
    'detail load publishes canonical data and supports stable retry errors',
    () async {
      var fail = true;
      final controller = _controller(
        loadDetail: (id) async {
          if (fail) throw StateError('database internals');
          return _detail(id: id);
        },
      );

      await controller.loadDetail('incident-1');
      final failed =
          controller.detailStateFor('incident-1')
              as SchoolAdminError<IncidentReportDetail>;
      expect(failed.message, 'โหลดรายละเอียดเหตุการณ์ไม่สำเร็จ');
      expect(failed.message, isNot(contains('database internals')));

      fail = false;
      await controller.loadDetail('incident-1');
      final loaded =
          controller.detailStateFor('incident-1')
              as SchoolAdminData<IncidentReportDetail>;
      expect(loaded.value.id, 'incident-1');
    },
  );

  test(
    'acknowledge succeeds only after canonical refetch confirms status',
    () async {
      var backend = <TeacherIncidentReport>[_report()];
      var acknowledgeCalls = 0;
      final controller = _controller(
        loadIncidents: () async => List<TeacherIncidentReport>.of(backend),
        acknowledge: (id) async {
          acknowledgeCalls += 1;
          backend = <TeacherIncidentReport>[_report(status: 'acknowledged')];
        },
      );
      await controller.load();

      final succeeded = await controller.acknowledge('incident-1');

      expect(succeeded, isTrue);
      expect(acknowledgeCalls, 1);
      final state =
          controller.state as SchoolAdminData<List<TeacherIncidentReport>>;
      expect(state.value.single.status, 'acknowledged');
    },
  );

  test(
    'acknowledge fails truthfully and preserves prior canonical data',
    () async {
      final controller = _controller(
        loadIncidents: () async => <TeacherIncidentReport>[_report()],
      );
      await controller.load();

      final succeeded = await controller.acknowledge('incident-1');

      expect(succeeded, isFalse);
      final state =
          controller.state as SchoolAdminError<List<TeacherIncidentReport>>;
      expect(state.message, 'รับเรื่องเหตุการณ์ไม่สำเร็จ');
      expect(state.previousData?.single.status, 'new');
    },
  );

  test(
    'mutation lock is per incident and blocks duplicate submission only',
    () async {
      final firstMutation = Completer<void>();
      final controller = _controller(
        loadIncidents: () async => <TeacherIncidentReport>[
          _report(id: 'incident-1'),
          _report(id: 'incident-2'),
        ],
        acknowledge: (id) async {
          if (id == 'incident-1') await firstMutation.future;
        },
      );
      await controller.load();

      final pending = controller.acknowledge('incident-1');
      await Future<void>.delayed(Duration.zero);

      expect(controller.isMutating('incident-1'), isTrue);
      expect(controller.isMutating('incident-2'), isFalse);
      expect(await controller.acknowledge('incident-1'), isFalse);

      firstMutation.complete();
      await pending;
    },
  );

  test('close validates note and confirms resolved state by refetch', () async {
    var backend = <TeacherIncidentReport>[_report(status: 'acknowledged')];
    var closeCalls = 0;
    final controller = _controller(
      loadIncidents: () async => List<TeacherIncidentReport>.of(backend),
      close:
          ({
            required id,
            required resolutionType,
            required resolutionNote,
          }) async {
            closeCalls += 1;
            backend = <TeacherIncidentReport>[_report(status: 'resolved')];
          },
    );
    await controller.load();

    expect(await controller.close('incident-1', '   '), isFalse);
    expect(closeCalls, 0);
    expect(await controller.close('incident-1', ' ตรวจสอบแล้ว '), isTrue);
    expect(closeCalls, 1);
    final state =
        controller.state as SchoolAdminData<List<TeacherIncidentReport>>;
    expect(state.value.single.status, 'resolved');
  });

  test('close failure keeps the last confirmed list available', () async {
    final controller = _controller(
      loadIncidents: () async => <TeacherIncidentReport>[
        _report(status: 'acknowledged'),
      ],
    );
    await controller.load();

    final succeeded = await controller.close('incident-1', 'ตรวจสอบแล้ว');

    expect(succeeded, isFalse);
    final state =
        controller.state as SchoolAdminError<List<TeacherIncidentReport>>;
    expect(state.message, 'ปิดเหตุการณ์ไม่สำเร็จ');
    expect(state.previousData?.single.status, 'acknowledged');
  });
}

SchoolAdminIncidentInboxController _controller({
  Future<List<TeacherIncidentReport>> Function()? loadIncidents,
  Future<IncidentReportDetail> Function(String id)? loadDetail,
  Future<void> Function(String id)? acknowledge,
  Future<void> Function({
    required String id,
    required String resolutionType,
    required String resolutionNote,
  })?
  close,
}) => SchoolAdminIncidentInboxController(
  loadIncidents:
      loadIncidents ?? () async => <TeacherIncidentReport>[_report()],
  loadDetail: loadDetail ?? (id) async => _detail(id: id),
  acknowledgeIncident: acknowledge ?? (id) async {},
  closeIncident:
      close ??
      ({
        required id,
        required resolutionType,
        required resolutionNote,
      }) async {},
);

TeacherIncidentReport _report({
  String id = 'incident-1',
  String status = 'new',
}) => TeacherIncidentReport(
  id: id,
  category: IncidentCategory.anomaly,
  room: 'A-101',
  status: status,
  reporterName: 'นักเรียนทดสอบ',
  createdAt: DateTime.utc(2030, 1, 1),
  reason: 'ประตูชำรุด',
  severity: 'medium',
);

IncidentReportDetail _detail({required String id}) => IncidentReportDetail(
  id: id,
  category: IncidentCategory.anomaly,
  room: 'A-101',
  status: 'new',
  resolutionType: null,
  resolutionNote: null,
  createdAt: DateTime.utc(2030, 1, 1),
  acknowledgedAt: null,
  closedAt: null,
  reason: 'ประตูชำรุด',
  severity: 'medium',
);
