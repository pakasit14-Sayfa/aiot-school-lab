import 'dart:async';

import 'package:flutter/widgets.dart';

/// Detaches polling subscriptions in retained tabs and covered routes.
class VisibleSensorStreamBuilder<T> extends StatefulWidget {
  const VisibleSensorStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
  });

  final Stream<T> stream;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<VisibleSensorStreamBuilder<T>> createState() =>
      _VisibleSensorStreamBuilderState<T>();
}

class _VisibleSensorStreamBuilderState<T>
    extends State<VisibleSensorStreamBuilder<T>> {
  late Stream<T> _stream;
  StreamSubscription<T>? _singleSubscription;

  @override
  void initState() {
    super.initState();
    _adaptStream();
  }

  void _adaptStream() {
    // Production polling is broadcast and detaches fully. One-shot injected
    // streams cannot be listened to twice when a dialog covers the page.
    _stream = widget.stream.isBroadcast
        ? widget.stream
        : widget.stream.asBroadcastStream(
            onListen: (subscription) {
              _singleSubscription = subscription;
              if (subscription.isPaused) subscription.resume();
            },
            onCancel: (subscription) => subscription.pause(),
          );
  }

  @override
  void didUpdateWidget(covariant VisibleSensorStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.stream, widget.stream)) {
      unawaited(_singleSubscription?.cancel());
      _singleSubscription = null;
      _adaptStream();
    }
  }

  @override
  void dispose() {
    unawaited(_singleSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    return StreamBuilder<T>(
      stream: visible ? _stream : null,
      builder: widget.builder,
    );
  }
}
