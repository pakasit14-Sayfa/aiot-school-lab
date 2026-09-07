import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_redesign_prototype_page.dart';

void main() {
  // Full-page widget pumps are intentionally avoided here: the dashboard's
  // unrelated `_UtilitySplitMetric`/`_UtilityGradientAreaChartPainter`
  // widgets have pre-existing layout/paint bugs (RenderFlex overflow, NaN
  // chart offsets) in the test harness's zero-real-session environment,
  // independent of anything touched in this fix — pumping the whole page
  // would make this test flaky for reasons unrelated to what it verifies.
  test('TeacherPrototypeVariant only exposes the real dashboard', () {
    // Variants B/C used to be reachable by any real teacher via the
    // sidebar's variant-cycle arrows and rendered entirely from hardcoded
    // fake schedule/review-task data (TeacherMock.classes/lessons/
    // reviewTasks). Both were deleted 2026-09-07 — this pins the enum down
    // to just the one real variant so they can't silently come back.
    expect(TeacherPrototypeVariant.values, [TeacherPrototypeVariant.a]);
    expect(TeacherPrototypeVariant.fromQuery('b'), TeacherPrototypeVariant.a);
    expect(TeacherPrototypeVariant.fromQuery('c'), TeacherPrototypeVariant.a);
    expect(TeacherPrototypeVariant.fromQuery(null), TeacherPrototypeVariant.a);
  });
}
