import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('signed-out user sees the real login screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('EDUSMART'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
