import 'dart:async';

import 'package:flutter/widgets.dart';

/// One non-overlapping request shared by all listeners. No timer survives the
/// last listener, and background apps do not keep polling the database.
class SensorPollingStream<T> with WidgetsBindingObserver {
  SensorPollingStream(
    this.fetch, {
    this.interval = const Duration(seconds: 5),
  }) {
    _controller = StreamController<T>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final Future<T> Function() fetch;
  final Duration interval;
  late final StreamController<T> _controller;
  Timer? _timer;
  bool _listening = false;
  bool _foreground = true;
  bool _running = false;
  int _generation = 0;

  Stream<T> get stream => _controller.stream;

  void _start() {
    _listening = true;
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    unawaited(_tick());
  }

  void _stop() {
    _listening = false;
    _generation++;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _generation++;
    _timer?.cancel();
    _timer = null;
    if (_foreground) unawaited(_tick());
  }

  Future<void> _tick() async {
    if (!_listening || !_foreground || _running) return;
    _running = true;
    final generation = _generation;
    try {
      final value = await fetch();
      if (_listening && _foreground && generation == _generation) {
        _controller.add(value);
      }
    } catch (error, stack) {
      if (_listening && _foreground && generation == _generation) {
        _controller.addError(error, stack);
      }
    } finally {
      _running = false;
      if (_listening && _foreground) {
        _timer = Timer(
          generation == _generation ? interval : Duration.zero,
          () => unawaited(_tick()),
        );
      }
    }
  }
}
