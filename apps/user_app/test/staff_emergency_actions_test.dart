import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart';

void main() {
  StaffEmergencyActions actions({
    Future<void> Function(String)? incident,
    Future<void> Function(String)? hardware,
    Future<void> Function(String)? escalate,
    Future<String?> Function(StaffEmergencySource, String)? read,
    Future<void> Function(String, String)? close,
    Future<void> Function(String, String, String)? closeIncident,
    Future<void> Function(String, String)? saveNote,
    Future<String?> Function(String)? readLatestNote,
  }) => StaffEmergencyActions(
    acknowledgeIncident: incident ?? (_) async {},
    acknowledgeHardware: hardware ?? (_) async {},
    escalateIncident: escalate ?? (_) async {},
    closeIncident:
        closeIncident ??
        (id, note, __) => (close ?? (_, __) async {})(id, note),
    closeHardware: close ?? (_, __) async {},
    readStatus: read ?? (_, __) async => 'acknowledged',
    saveIncidentNote: saveNote ?? (_, __) async {},
    readLatestIncidentNote: readLatestNote ?? (_) async => null,
  );

  test('rejected acknowledge never confirms success', () async {
    final a = actions(incident: (_) async => throw StateError('secret'));
    expect(
      await a.acknowledge(StaffEmergencySource.incident, 'a'),
      StaffEmergencyResult.failed,
    );
    expect(a.isBusy, false);
    a.dispose();
  });

  test('hardware uses its own write and canonical ID', () async {
    final states = {'hardware-a': 'new'};
    final a = actions(
      incident: (_) async => throw StateError('wrong source'),
      hardware: (id) async {
        states[id] = 'acknowledged';
      },
      read: (source, id) async =>
          source == StaffEmergencySource.hardware ? states[id] : null,
    );
    expect(
      await a.acknowledge(StaffEmergencySource.hardware, 'hardware-a'),
      StaffEmergencyResult.confirmed,
    );
    expect(states['hardware-a'], 'acknowledged');
    a.dispose();
  });

  test('write success without canonical change is unconfirmed', () async {
    final a = actions(read: (_, __) async => 'new');
    expect(
      await a.acknowledge(StaffEmergencySource.incident, 'a'),
      StaffEmergencyResult.unconfirmed,
    );
    a.dispose();
  });

  test('read failure after write is distinct from write rejection', () async {
    final a = actions(read: (_, __) async => throw StateError('offline'));
    expect(
      await a.acknowledge(StaffEmergencySource.hardware, 'a'),
      StaffEmergencyResult.unconfirmed,
    );
    a.dispose();
  });

  test('close confirms hardware closed but not an unrelated status', () async {
    var status = 'acknowledged';
    final a = actions(
      close: (_, note) async {
        expect(note, 'checked');
        status = 'closed';
      },
      read: (_, __) async => status,
    );
    expect(
      await a.close(StaffEmergencySource.hardware, 'a', ' checked '),
      StaffEmergencyResult.confirmed,
    );
    expect(
      await a.close(StaffEmergencySource.incident, 'b', 'checked'),
      StaffEmergencyResult.unconfirmed,
    );
    a.dispose();
  });

  test('blank close note cannot write', () async {
    var writes = 0;
    final a = actions(
      close: (_, __) async {
        writes++;
      },
    );
    expect(
      await a.close(StaffEmergencySource.hardware, 'a', '  '),
      StaffEmergencyResult.failed,
    );
    expect(writes, 0);
    a.dispose();
  });

  test('duplicate target blocked until canonical read finishes', () async {
    final response = Completer<String?>();
    var writes = 0;
    final a = actions(
      hardware: (_) async {
        writes++;
      },
      read: (_, __) => response.future,
    );
    final first = a.acknowledge(StaffEmergencySource.hardware, 'a');
    expect(a.isBusy, true);
    expect(
      await a.acknowledge(StaffEmergencySource.hardware, 'a'),
      StaffEmergencyResult.busy,
    );
    response.complete('acknowledged');
    expect(await first, StaffEmergencyResult.confirmed);
    expect(writes, 1);
    expect(a.isBusy, false);
    a.dispose();
  });

  test('escalate confirms only when status becomes escalated', () async {
    var status = 'new';
    final a = actions(
      escalate: (_) async {
        status = 'escalated';
      },
      read: (_, __) async => status,
    );
    expect(await a.escalate('a'), StaffEmergencyResult.confirmed);
    a.dispose();
  });

  test('escalate rejection is distinct from unconfirmed', () async {
    final a = actions(escalate: (_) async => throw StateError('forbidden'));
    expect(await a.escalate('a'), StaffEmergencyResult.failed);
    a.dispose();
  });

  test(
    'close passes the chosen resolution type through and confirms on match',
    () async {
      var status = 'escalated';
      String? capturedType;
      final a = actions(
        closeIncident: (id, note, resolutionType) async {
          capturedType = resolutionType;
          status = resolutionType;
        },
        read: (_, __) async => status,
      );
      expect(
        await a.close(
          StaffEmergencySource.incident,
          'a',
          'ตรวจสอบแล้ว',
          resolutionType: 'cancelled',
        ),
        StaffEmergencyResult.confirmed,
      );
      expect(capturedType, 'cancelled');
    },
  );

  test(
    'addNote confirms only when the canonical latest note matches exactly',
    () async {
      final a = actions(
        saveNote: (_, __) async {},
        readLatestNote: (_) async => 'ตรวจสอบแล้ว',
      );
      expect(
        await a.addNote('a', ' ตรวจสอบแล้ว '),
        StaffEmergencyResult.confirmed,
      );
      a.dispose();
    },
  );

  test(
    'addNote is unconfirmed when the canonical read does not match the written text',
    () async {
      final a = actions(
        saveNote: (_, __) async {},
        readLatestNote: (_) async => 'a different note entirely',
      );
      expect(
        await a.addNote('a', 'ตรวจสอบแล้ว'),
        StaffEmergencyResult.unconfirmed,
      );
      a.dispose();
    },
  );

  test('addNote rejection is a failure, never a false success', () async {
    final a = actions(saveNote: (_, __) async => throw StateError('rejected'));
    expect(await a.addNote('a', 'note'), StaffEmergencyResult.failed);
    a.dispose();
  });

  test('a blank note is rejected before any write is attempted', () async {
    var writes = 0;
    final a = actions(saveNote: (_, __) async => writes++);
    expect(await a.addNote('a', '   '), StaffEmergencyResult.failed);
    expect(writes, 0);
    a.dispose();
  });

  test(
    'a read failure after a successful note write is unconfirmed, not failed',
    () async {
      final a = actions(
        saveNote: (_, __) async {},
        readLatestNote: (_) async => throw StateError('offline'),
      );
      expect(await a.addNote('a', 'note'), StaffEmergencyResult.unconfirmed);
      a.dispose();
    },
  );

  test(
    'a duplicate addNote submission for the same incident is blocked while one is pending',
    () async {
      final response = Completer<String?>();
      var writes = 0;
      final a = actions(
        saveNote: (_, __) async => writes++,
        readLatestNote: (_) => response.future,
      );
      final first = a.addNote('a', 'note');
      expect(a.isBusy, true);
      expect(await a.addNote('a', 'note'), StaffEmergencyResult.busy);
      response.complete('note');
      expect(await first, StaffEmergencyResult.confirmed);
      expect(writes, 1);
      a.dispose();
    },
  );

  test(
    'addNote and acknowledge on the same incident do not share a busy key',
    () async {
      // Progress notes and status actions are tracked separately, but the
      // page's own _isSubmitting flag is what actually keeps their controls
      // mutually exclusive in the UI — this only pins the controller-level
      // contract so a future page refactor cannot silently rely on this
      // union blocking both at once.
      final a = actions(
        saveNote: (_, __) async {},
        readLatestNote: (_) async => 'note',
      );
      final noteResult = a.addNote('shared-id', 'note');
      expect(a.isBusy, true);
      final ackResult = await a.acknowledge(
        StaffEmergencySource.incident,
        'shared-id',
      );
      expect(ackResult, StaffEmergencyResult.confirmed);
      expect(await noteResult, StaffEmergencyResult.confirmed);
      a.dispose();
    },
  );

  test('dispose during request produces no late notifications', () async {
    final response = Completer<String?>();
    final a = actions(read: (_, __) => response.future);
    final pending = a.acknowledge(StaffEmergencySource.incident, 'a');
    a.dispose();
    response.complete('acknowledged');
    expect(await pending, StaffEmergencyResult.confirmed);
  });
}
