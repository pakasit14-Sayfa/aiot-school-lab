import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/services/sensor_polling_stream.dart';

void main() {
  testWidgets('listeners share requests; last cancellation stops polling', (
    tester,
  ) async {
    var calls = 0;
    final poller = SensorPollingStream(() async => ++calls);
    final first = <int>[];
    final second = <int>[];
    final a = poller.stream.listen(first.add);
    final b = poller.stream.listen(second.add);
    await tester.pump();
    expect(calls, 1);
    expect(first, [1]);
    expect(second, [1]);
    unawaited(a.cancel());
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 2);
    unawaited(b.cancel());
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 2);
    final c = poller.stream.listen(first.add);
    await tester.pump();
    expect(calls, 3);
    unawaited(c.cancel());
  });

  testWidgets(
    'slow request never overlaps and cancelled results are discarded',
    (tester) async {
      var calls = 0;
      final pending = Completer<int>();
      final poller = SensorPollingStream(() {
        calls++;
        return calls == 1 ? pending.future : Future.value(2);
      });
      final values = <int>[];
      final a = poller.stream.listen(values.add);
      await tester.pump(const Duration(seconds: 30));
      expect(calls, 1);
      unawaited(a.cancel());
      final b = poller.stream.listen(values.add);
      await tester.pump();
      expect(calls, 1);
      pending.complete(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(values, [2]);
      expect(calls, 2);
      unawaited(b.cancel());
    },
  );

  testWidgets('background stops polling and foreground fetches again', (
    tester,
  ) async {
    var calls = 0;
    final poller = SensorPollingStream(() async => ++calls);
    final subscription = poller.stream.listen((_) {});
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 2);
    unawaited(subscription.cancel());
  });

  testWidgets('errors reach listeners and a later tick recovers', (
    tester,
  ) async {
    var calls = 0;
    final errors = <Object>[];
    final values = <int>[];
    final poller = SensorPollingStream(() async {
      if (++calls == 1) throw StateError('unavailable');
      return calls;
    });
    final subscription = poller.stream.listen(values.add, onError: errors.add);
    await tester.pump();
    expect(errors, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    expect(values, [2]);
    unawaited(subscription.cancel());
  });
}
