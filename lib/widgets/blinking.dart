import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:value_notifier/value_notifier.dart';

class BlinkingOpacity extends StatelessWidget {
  const BlinkingOpacity({
    Key? key,
    required this.canBlink,
    required this.child,
  }) : super(key: key);
  final ValueListenable<bool> canBlink;
  final Widget child;

  @override
  Widget build(BuildContext context) => BlinkingWidgetBuilder(
        canBlink: canBlink,
        builder: (context, isVisible, child) => Opacity(
          opacity: isVisible ? 1.0 : 0.0,
          child: child!,
        ),
        child: child,
      );
}

class BlinkingTextStyle extends StatelessWidget {
  const BlinkingTextStyle({
    Key? key,
    required this.canBlink,
    required this.child,
  }) : super(key: key);
  final ValueListenable<bool> canBlink;
  final Widget child;

  @override
  Widget build(BuildContext context) => BlinkingWidgetBuilder(
        canBlink: canBlink,
        builder: (context, isVisible, child) => DefaultTextStyle.merge(
          style: isVisible ? null : const TextStyle(color: Colors.transparent),
          child: child!,
        ),
        child: child,
      );
}

class BlinkingWidgetBuilder extends StatefulWidget {
  const BlinkingWidgetBuilder({
    Key? key,
    required this.canBlink,
    required this.builder,
    this.child,
  }) : super(key: key);
  final ValueListenable<bool> canBlink;
  final Widget Function(BuildContext, bool isVisible, Widget? child) builder;
  final Widget? child;
  @override
  _BlinkingWidgetBuilderState createState() => _BlinkingWidgetBuilderState();
}

class _BlinkingWidgetBuilderState extends State<BlinkingWidgetBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late IDisposable _connection;
  static const _kBlinkDuration = Duration(milliseconds: 500);
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: _kBlinkDuration * 2);
    _connection =
        widget.canBlink.unique().tap(_onCanBlinkChange, includeInitial: true);
  }

  void didUpdateWidget(BlinkingWidgetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.canBlink == oldWidget.canBlink) {
      return;
    }
    _connection.dispose();
    _connection =
        widget.canBlink.unique().tap(_onCanBlinkChange, includeInitial: true);
  }

  void _onCanBlinkChange(bool canBlink) {
    if (canBlink) {
      controller.repeat();
    } else {
      controller.stop();
      controller.value = 0;
    }
  }

  void dispose() {
    controller.dispose();
    _connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => controller.view
      .view()
      .map((value) => value >= 0.5 ? false : true)
      .unique()
      .build(
        builder: (context, isVisible, child) => widget.builder(
          context,
          isVisible,
          child,
        ),
        child: widget.child,
      );
}
