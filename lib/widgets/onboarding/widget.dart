import 'package:flutter/material.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:vector_drawable/src/widget/src/animator/animator.dart';

class AutoRepeatingAnimatedVector extends StatefulWidget {
  const AutoRepeatingAnimatedVector({
    Key? key,
    required this.vector,
    this.style = StyleMapping.empty,
    this.reverse = false,
  }) : super(key: key);
  final AnimatedVector vector;
  final StyleMapping style;
  final bool reverse;

  @override
  State<AutoRepeatingAnimatedVector> createState() =>
      _AutoRepeatingAnimatedVectorState();
}

class _AutoRepeatingAnimatedVectorState
    extends State<AutoRepeatingAnimatedVector> {
  final GlobalKey<AnimatedVectorState> vectorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.scheduleFrameCallback((_) => _resetAnim());
  }

  void _resetAnim() {
    if (mounted) {
      vectorKey.currentState!.start(forward: !widget.reverse, fromStart: true);
    }
  }

  void _onStatus(AnimatorStatus status) {
    final shouldReset = widget.reverse
        ? status == AnimatorStatus.dismissed
        : status == AnimatorStatus.completed;
    if (shouldReset) {
      _resetAnim();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedVectorWidget(
        key: vectorKey,
        onStatusChange: _onStatus,
        animatedVector: widget.vector,
        styleMapping: widget.style,
      );
}
