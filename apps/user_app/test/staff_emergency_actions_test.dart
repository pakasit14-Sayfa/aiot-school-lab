import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart';

void main() {
  StaffEmergencyActions actions({
    Future<void> Function(String)? incident,
    Future<void> Function(String)? hardware,
    Future<String?> Function(StaffEmergencySource, String)? read,
    Future<void> Function(String, String)? close,
  }) => StaffEmergencyActions(
    acknowledgeIncident: incident ?? (_) async {},
    acknowledgeHardware: hardware ?? (_) async {},
    closeIncident: close ?? (_, __) async {},
    closeHardware: close ?? (_, __) async {},
    readStatus: read ?? (_, __) async => 'acknowledged',
  );

  test('rejected acknowledge never confirms success', () async {
    final a = actions(incident: (_) async => throw StateError('secret'));
    expect(await a.acknowledge(StaffEmergencySource.incident, 'a'),
      StaffEmergencyResult.failed);
    expect(a.isBusy, false);
    a.dispose();
  });

  test('hardware uses its own write and canonical ID', () async {
    final states = {'hardware-a': 'new'};
    final a = actions(
      incident: (_) async => throw StateError('wrong source'),
      hardware: (id) async { states[id] = 'acknowledged'; },
      read: (source, id) async => source == StaffEmergencySource.hardware ? states[id] : null,
    );
    expect(await a.acknowledge(StaffEmergencySource.hardware, 'hardware-a'),
      StaffEmergencyResult.confirmed);
    expect(states['hardware-a'], 'acknowledged');
    a.dispose();
  });

  test('write success without canonical change is unconfirmed', () async {
    final a = actions(read: (_, __) async => 'new');
    expect(await a.acknowledge(StaffEmergencySource.incident, 'a'),
      StaffEmergencyResult.unconfirmed);
    a.dispose();
  });

  test('read failure after write is distinct from write rejection', () async {
    final a = actions(read: (_, __) async => throw StateError('offline'));
    expect(await a.acknowledge(StaffEmergencySource.hardware, 'a'),
      StaffEmergencyResult.unconfirmed);
    a.dispose();
  });

  test('close confirms hardware closed but not an unrelated status', () async {
    var status = 'acknowledged';
    final a = actions(
      close: (_, note) async { expect(note, 'checked'); status = 'closed'; },
      read: (_, __) async => status,
    );
    expect(await a.close(StaffEmergencySource.hardware, 'a', ' checked '),
      StaffEmergencyResult.confirmed);
    expect(await a.close(StaffEmergencySource.incident, 'b', 'checked'),
      StaffEmergencyResult.unconfirmed);
    a.dispose();
  });

  test('blank close note cannot write', () async {
    var writes = 0;
    final a = actions(close: (_, __) async { writes++; });
    expect(await a.close(StaffEmergencySource.hardware, 'a', '  '),
      StaffEmergencyResult.failed);
    expect(writes, 0);
    a.dispose();
  });

  test('duplicate target blocked until canonical read finishes', () async {
    final response = Completer<String?>();
    var writes = 0;
    final a = actions(
      hardware: (_) async { writes++; },
      read: (_, __) => response.future,
    );
    final first = a.acknowledge(StaffEmergencySource.hardware, 'a');
    expect(a.isBusy, true);
    expect(await a.acknowledge(StaffEmergencySource.hardware, 'a'),
      StaffEmergencyResult.busy);
    response.complete('acknowledged');
    expect(await first, StaffEmergencyResult.confirmed);
    expect(writes, 1);
    expect(a.isBusy, false);
    a.dispose();
  });

  test('dispose during request produces no late notifications', () async {
    final response = Completer<String?>();
    final a = actions(read: (_, __) => response.future);
    final pending = a.acknowledge(StaffEmergencySource.incident, 'a');
    a.dispose();
    response.complete('acknowledged');
    expect(await pending, StaffEmergencyResult.confirmed);
  });
}

