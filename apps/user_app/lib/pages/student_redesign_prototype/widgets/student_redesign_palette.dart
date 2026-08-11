import 'dart:ui';
import 'package:flutter/material.dart';

class SchoolPalette {
  static const green = Color.fromARGB(255, 28, 127, 70);
  static const deepGreen = Color(0xFF165042);
  static const softGreenBg = Color(0xFFF3F8F5);
  static const yellow = Color(0xFFFFC939);
  static const orange = Color(0xFFDB6D24);
  static const blue = Color(0xFF4CA4F1);
  static const cream = Color(0xFFFBEAA8);
  static const sky = Color(0xFFAADBF9);
  static const lime = Color(0xFFA9CD30);
  static const lavender = Color(0xFFC8BADD);
  static const ink = Color(0xFF263238);
  static const navy = Color(0xFF16283A);
  static const muted = Color(0xFF607D8B);
  static const page = Colors.white;
  static const glassBorder = Color(0xFFDCE7E2);

  // Fresher secondary accent (mint) used sparingly for small highlights
  // (progress bar fill, subtle tints) — never in the primary gradient
  // itself, so it doesn't clash with the hero banner's established tones.
  static const mint = Color(0xFF35C99A);

  // Same three tones as the home page hero banner (_buildHeroHeader in
  // student_variant_school_home.dart) so every gradient surface across the
  // app — hero, headers, buttons — reads as one consistent brand gradient
  // instead of each screen inventing its own shade of green.
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF0F3E33), deepGreen, Color(0xFF2A6B58)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.isGlass = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool isGlass;

  @override
  Widget build(BuildContext context) {
    // Slightly more opaque + less blur than a "pure" glass look — keeps text
    // legible on mobile screens in bright/outdoor light.
    final effectiveColor =
        isGlass && (color == Colors.white || color == const Color(0xFFFFFFFF))
        ? Colors.white.withValues(alpha: 0.95)
        : color;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(28),
              // A faint green-tinted hairline instead of a flat grey border
              // reads as a lot less "default Material card" at a glance.
              border: Border.all(
                color: isGlass
                    ? const Color(0xFFBEDCD0)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: const [
                // Key tight shadow (Apple Crisp Edge)
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
                // Ambient soft shadow (Apple Wide Elevation Diffusion)
                BoxShadow(
                  color: Color(0x0E0F172A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
                // Faint tinted glow picks up the brand color instead of a
                // purely neutral shadow — a small touch that reads as
                // deliberate rather than a stock Material elevation.
                BoxShadow(
                  color: Color(0x0F165042),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Primary CTA button with the brand gradient instead of a flat fill —
/// swap-in replacement for `FilledButton.icon` wherever a screen's main
/// action button lives, so the app doesn't read as flat-color everywhere.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 50,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? SchoolPalette.primaryGradient : null,
          color: enabled ? null : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x33165042),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
