import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_shared_widgets.dart';

/// Owner's rule 2026-09-21: no manual refresh buttons in the teacher lane —
/// TeacherMockPageShell reloads by itself (pull-down, app resume, return
/// from a page pushed on top).
void main() {
  Future<int Function()> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherMockPageShell(
          title: 'ทดสอบ',
          onRefresh: () async => calls++,
          builder: (context, _) => Column(
            children: [
              const SizedBox(height: 200, child: Text('เนื้อหา')),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('หน้าแก้ไข')),
                    ),
                  ),
                ),
                child: const Text('เปิดหน้าแก้ไข'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => calls;
  }

  testWidgets('no refresh button; pull-down reloads', (tester) async {
    final calls = await pump(tester);
    expect(find.byTooltip('รีเฟรช'), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(calls(), 0);
    await tester.fling(find.text('เนื้อหา'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(calls(), 1);
  });

  testWidgets('returning from a pushed page reloads', (tester) async {
    final calls = await pump(tester);
    await tester.tap(find.text('เปิดหน้าแก้ไข'));
    await tester.pumpAndSettle();
    expect(find.text('หน้าแก้ไข'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(calls(), 1);
  });

  testWidgets('app resume reloads', (tester) async {
    final calls = await pump(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls(), 1);
  });
}
