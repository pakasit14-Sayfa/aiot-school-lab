import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_learning_controller.dart';

const signal = AutoFlaggedStudent(
  studentId: 'qa-student',
  studentName: 'QA',
  reason: 'ค้างส่งงาน',
  detail: 'ค้างส่ง 2 งาน',
  actionLabel: 'ดูงานค้าง',
  severity: 'urgent',
);
DirectorLearningController controller({bool failRead = false}) =>
    DirectorLearningController(
      overview: () async => const ClassroomsOverviewItem(
        roomCount: 1,
        courseCount: 1,
        activeStudentCount: 1,
        assignmentsDueThisWeek: 0,
      ),
      tracks: () async => [],
      rooms: () async => [],
      attendance: (_) async => [],
      cases: () async {
        if (failRead) throw StateError('read_failed');
        return [];
      },
      autoFlags: () async => [signal],
      interventions: (_) async => [],
      openCase: (_) async => 'new-case',
    );
void main() {
  test(
    'opening case must reject success when canonical list lacks new case',
    () async {
      final c = controller();
      addTearDown(c.dispose);
      await expectLater(c.openCaseFromFlag(signal), throwsA(isA<StateError>()));
    },
  );
  test(
    'opening case must reject success when canonical refresh fails',
    () async {
      final c = controller(failRead: true);
      addTearDown(c.dispose);
      await expectLater(c.openCaseFromFlag(signal), throwsA(isA<StateError>()));
    },
  );
}
