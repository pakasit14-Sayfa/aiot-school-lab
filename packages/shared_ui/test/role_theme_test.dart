import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

const _blueRole = RoleColors(
  primary: Color(0xFF0D5C9D),
  onPrimary: Colors.white,
  secondary: Color(0xFFB0232B),
  background: Color(0xFFF8F4EE),
  surface: Colors.white,
  border: Color(0xFFE5D5C1),
  textPrimary: Color(0xFF17324A),
  textSecondary: Color(0xFF6B7782),
);

const _brownRole = RoleColors(
  primary: Color(0xFFA66B1F),
  onPrimary: Colors.white,
  secondary: Color(0xFFD49A18),
  background: Color(0xFFF7F1E7),
  surface: Colors.white,
  border: Color(0xFFD9C7A8),
  textPrimary: Color(0xFF35291E),
  textSecondary: Color(0xFF665544),
);

void main() {
  group('buildRoleTheme: same structure, different colors', () {
    final blueTheme = buildRoleTheme(_blueRole);
    final brownTheme = buildRoleTheme(_brownRole);

    test('filled button color follows the role, shape does not', () {
      final Color? blueBg = blueTheme.filledButtonTheme.style?.backgroundColor
          ?.resolve({});
      final Color? brownBg = brownTheme
          .filledButtonTheme
          .style
          ?.backgroundColor
          ?.resolve({});
      expect(blueBg, _blueRole.primary);
      expect(brownBg, _brownRole.primary);
      expect(blueBg, isNot(brownBg));

      final blueShape =
          blueTheme.filledButtonTheme.style?.shape?.resolve({})
              as RoundedRectangleBorder;
      final brownShape =
          brownTheme.filledButtonTheme.style?.shape?.resolve({})
              as RoundedRectangleBorder;
      expect(blueShape.borderRadius, brownShape.borderRadius);
    });

    test('text field border radius and padding are identical across roles', () {
      final blueBorder =
          blueTheme.inputDecorationTheme.border as OutlineInputBorder;
      final brownBorder =
          brownTheme.inputDecorationTheme.border as OutlineInputBorder;
      expect(blueBorder.borderRadius, brownBorder.borderRadius);
      expect(
        blueTheme.inputDecorationTheme.contentPadding,
        brownTheme.inputDecorationTheme.contentPadding,
      );

      // But the focused-border color still follows the role.
      final blueFocused =
          blueTheme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      final brownFocused =
          brownTheme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(blueFocused.borderSide.color, _blueRole.primary);
      expect(brownFocused.borderSide.color, _brownRole.primary);
    });
  });

  group('components render without error under a role theme', () {
    testWidgets('AppButton.filled, AppButton.outlined, AppTextField', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRoleTheme(_brownRole),
          home: Scaffold(
            body: Column(
              children: [
                AppButton.filled(label: 'บันทึก', onPressed: () {}),
                AppButton.outlined(
                  label: 'ยกเลิก',
                  icon: Icons.close_rounded,
                  onPressed: () {},
                ),
                const AppTextField(label: 'ชื่อ', hint: 'กรอกชื่อ'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('บันทึก'), findsOneWidget);
      expect(find.text('ยกเลิก'), findsOneWidget);
      expect(find.byType(AppTextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppSearchField', () {
    testWidgets('shows a clear button only once text is entered', (
      tester,
    ) async {
      String? lastValue;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRoleTheme(_blueRole),
          home: Scaffold(
            body: AppSearchField(onChanged: (v) => lastValue = v),
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.enterText(find.byType(TextField), 'ทดสอบ');
      await tester.pump();
      expect(lastValue, 'ทดสอบ');
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(lastValue, '');
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });
}
