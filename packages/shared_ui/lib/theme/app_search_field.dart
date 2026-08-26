import 'package:flutter/material.dart';

/// A search box — leading search icon, a hint, and a clear ("x") button
/// that appears once there's text — structured identically everywhere
/// it's used, colored by whichever role [Theme] wraps it (see
/// `buildRoleTheme`). Pages should reach for this instead of a raw
/// `TextField` with a hand-added search icon so every role's search
/// experience behaves the same way (same debounce-free `onChanged`
/// contract, same clear-button behavior).
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.hint = 'ค้นหา...',
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final String hint;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  ),
          ),
        );
      },
    );
  }
}
