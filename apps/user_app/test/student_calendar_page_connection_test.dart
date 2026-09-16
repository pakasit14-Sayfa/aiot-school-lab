import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_calendar_page.dart';
import 'package:shared_core/shared_core.dart';

/// StudentCalendarPage's personal-task CRUD (create/delete/toggle) writes
/// through real CalendarService RPCs then reloads from the canonical list -
/// these tests pin that down so a future edit can't quietly turn a mutation
/// into a client-side-only fake success.

// The desktop week board renders only Monday–Friday of the week containing
// _selectedDay (which defaults to DateTime.now()) — school timetables have
// no weekend columns. A fixture dated "today" therefore vanished whenever
// the suite ran on a Saturday or Sunday (first seen 2026-09-13, a Sunday):
// two tests went red and the other two passed only through their silent
// early-return. Pin every fixture to the Monday of the current week instead,
// which the board always shows no matter which day the tests run.
final DateTime _now = DateTime.now();
final DateTime _mondayThisWeek = DateTime(
  _now.year,
  _now.month,
  _now.day,
).subtract(Duration(days: _now.weekday - DateTime.monday));

PersonalTask _task({
  String id = 'task-1',
  String title = 'ทบทวนวิชาเคมี',
  bool done = false,
}) => PersonalTask(
  id: id,
  title: title,
  note: null,
  dueAt: DateTime(
    _mondayThisWeek.year,
    _mondayThisWeek.month,
    _mondayThisWeek.day,
    16,
  ),
  done: done,
  createdAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<ClassScheduleSlot>> Function()? loadSchedule,
  Future<List<PersonalTask>> Function()? loadTasks,
  Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse,
  Future<void> Function({required String title, required DateTime dueAt})?
  createTask,
  Future<void> Function(String taskId)? deleteTask,
  Future<void> Function({required String taskId, required bool done})?
  toggleTask,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentCalendarPage(
        loadCourses: loadCourses ?? () async => const [],
        loadSchedule: loadSchedule ?? () async => const [],
        loadTasks: loadTasks ?? () async => const [],
        loadAssignmentsForCourse: loadAssignmentsForCourse ?? (_) async => const [],
        createTask: createTask,
        deleteTask: deleteTask,
        toggleTask: toggleTask,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('deleting a personal task calls the real RPC, not just local state', (
    tester,
  ) async {
    var deleteCalls = 0;
    var reloadCalls = 0;
    final tasks = [_task()];

    await _pump(
      tester,
      loadTasks: () async {
        reloadCalls++;
        return tasks;
      },
      deleteTask: (taskId) async {
        deleteCalls++;
        expect(taskId, 'task-1');
      },
    );

    expect(reloadCalls, 1, reason: 'initial load');
    expect(find.textContaining('ทบทวนวิชาเคมี'), findsWidgets);

    // Tap the event to select it, then delete via the detail panel/action.
    await tester.tap(find.textContaining('ทบทวนวิชาเคมี').first);
    await tester.pumpAndSettle();

    // Used to `return` silently when the icon was missing — which is exactly
    // what happened every weekend, so the RPC assertions below never ran.
    final deleteButton = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteButton, findsWidgets, reason: 'selecting a personal task must offer delete');
    await tester.tap(deleteButton.first);
    await tester.pumpAndSettle();

    expect(deleteCalls, 1, reason: 'delete must call the real RPC exactly once');
    expect(
      reloadCalls,
      2,
      reason: 'a successful delete reloads from the canonical list, not just local state',
    );
  });

  testWidgets('toggling a personal task calls the real RPC with the flipped value', (
    tester,
  ) async {
    var toggleCalls = 0;
    final tasks = [_task(done: false)];

    await _pump(
      tester,
      loadTasks: () async => tasks,
      toggleTask: ({required taskId, required done}) async {
        toggleCalls++;
        expect(taskId, 'task-1');
        expect(done, true, reason: 'toggling an undone task must send done: true');
      },
    );

    // There is no Checkbox anywhere on this page — the old finder never
    // matched, so the `if (isEmpty) return` that followed it made this test
    // pass without ever tapping anything. The real affordance is the
    // "ทำเครื่องหมายว่าเสร็จ" button in the detail panel of a selected event.
    await tester.tap(find.textContaining('ทบทวนวิชาเคมี').first);
    await tester.pumpAndSettle();

    final markDone = find.text('ทำเครื่องหมายว่าเสร็จ');
    expect(markDone, findsOneWidget, reason: 'an undone personal task must offer mark-as-done');
    await tester.tap(markDone);
    await tester.pumpAndSettle();

    expect(toggleCalls, 1, reason: 'toggle must call the real RPC exactly once');
  });

  testWidgets('an empty account shows an honest empty state, no fabricated events', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.textContaining('428'), findsNothing);
    expect(find.textContaining('เคมี'), findsNothing);
  });

  testWidgets('class schedule and assignment due-dates are read-only, never deletable', (
    tester,
  ) async {
    var deleteCalls = 0;
    await _pump(
      tester,
      loadSchedule: () async => [
        ClassScheduleSlot(
          id: 'sch-1',
          courseId: 'course-1',
          subjectName: 'คณิตศาสตร์',
          dayOfWeek: 0, // จันทร์ — คอลัมน์แรกของบอร์ด แสดงเสมอ
          startTime: '09:00:00',
          endTime: '10:00:00',
          room: '101',
        ),
      ],
      deleteTask: (_) async => deleteCalls++,
    );

    expect(find.textContaining('คณิตศาสตร์'), findsWidgets);
    // No assertion on tap-to-delete here — _EventSource.classSchedule
    // sets isEditable=false, so the delete affordance shouldn't even be
    // offered; this just confirms no accidental delete call happens from
    // rendering alone.
    expect(deleteCalls, 0);
  });
}
