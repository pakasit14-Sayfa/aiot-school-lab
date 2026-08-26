import 'package:flutter/material.dart';

/// A button that always inherits its shape/padding/color from the
/// ambient role [Theme] (see `buildRoleTheme`) rather than from a
/// per-call-site `style:` override. Use [AppButton.filled] for the
/// primary action on a screen, [AppButton.outlined] for a secondary one
/// — never construct a raw `FilledButton`/`OutlinedButton` with a custom
/// `style:` in a page that's been migrated to the shared design system,
/// or that call site silently opts back out of the shared structure.
class AppButton extends StatelessWidget {
  const AppButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _outlined = false;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _outlined = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool _outlined;

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    if (_outlined) {
      return icon == null
          ? OutlinedButton(onPressed: onPressed, child: child)
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: child,
            );
    }
    return icon == null
        ? FilledButton(onPressed: onPressed, child: child)
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: child,
          );
  }
}
