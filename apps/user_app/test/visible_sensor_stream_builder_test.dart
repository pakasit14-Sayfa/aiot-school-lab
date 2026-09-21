import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/widgets/visible_sensor_stream_builder.dart';

void main() {
  testWidgets(
    'sensor snapshots preserve loading, empty, data and error states',
    (tester) async {
      final source = StreamController<List<int>>.broadcast();
      await tester.pumpWidget(
        MaterialApp(
          home: VisibleSensorStreamBuilder<List<int>>(
            stream: source.stream,
            builder: (_, snapshot) => Text(
              snapshot.hasError
                  ? 'error'
                  : snapshot.connectionState == ConnectionState.waiting
                  ? 'loading'
                  : snapshot.data?.isEmpty == true
                  ? 'empty'
                  : 'data',
            ),
          ),
        ),
      );
      expect(find.text('loading'), findsOneWidget);
      source.add([]);
      await tester.pumpAndSettle();
      expect(find.text('empty'), findsOneWidget);
      source.add([1]);
      await tester.pumpAndSettle();
      expect(find.text('data'), findsOneWidget);
      source.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('error'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      unawaited(source.close());
    },
  );

  testWidgets('retained hidden tab and covered route detach listeners', (
    tester,
  ) async {
    final source = StreamController<int>.broadcast();
    final visible = ValueNotifier(true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, enabled, _) => TickerMode(
            enabled: enabled,
            child: VisibleSensorStreamBuilder<int>(
              stream: source.stream,
              builder: (_, snapshot) => Text('${snapshot.data}'),
            ),
          ),
        ),
      ),
    );
    expect(source.hasListener, isTrue);
    visible.value = false;
    await tester.pumpAndSettle();
    expect(source.hasListener, isFalse);
    visible.value = true;
    await tester.pumpAndSettle();
    expect(source.hasListener, isTrue);
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('another page')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(source.hasListener, isFalse);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(source.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(source.hasListener, isFalse);
    visible.dispose();
    unawaited(source.close());
  });
}
