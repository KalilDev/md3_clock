import 'package:flutter/material.dart';

import '../model/duration_components.dart';

class DurationWidget extends StatelessWidget {
  const DurationWidget({
    Key? key,
    required this.duration,
    required this.numberStyle,
    required this.separatorStyle,
    this.padSeconds = false,
  }) : super(key: key);
  final Duration duration;
  final TextStyle numberStyle;
  final TextStyle separatorStyle;
  final bool padSeconds;
  static String _valueToString(int value) => value.toString().padLeft(2, '0');
  Widget _digits(
    int digits, [
    bool dontPad = false,
  ]) =>
      Text(
        dontPad ? digits.toString() : _valueToString(digits),
        style: numberStyle,
      );
  Widget _separator() => Text(
        ':',
        style: separatorStyle,
      );

  @override
  Widget build(BuildContext context) {
    final time = DurationComponents.fromDuration(duration);
    final writeHours = time.hours > 0;
    final writeMinutes = time.minutes > 0 || writeHours;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (writeHours) ...[
          _digits(time.hours),
          _separator(),
        ],
        if (writeMinutes) ...[
          _digits(time.minutes, !writeHours),
          _separator(),
        ],
        _digits(time.seconds, !padSeconds && !writeMinutes),
      ],
    );
  }
}
