import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/utils/utils.dart';

import '../model/duration_components.dart';

class DurationWidget extends StatelessWidget {
  const DurationWidget({
    Key? key,
    required this.duration,
    this.numberStyle,
    this.separatorStyle,
    this.alwaysPadSeconds = false,
  }) : super(key: key);
  final Duration duration;
  final TextStyle? numberStyle;
  final TextStyle? separatorStyle;
  final bool alwaysPadSeconds;

  @override
  Widget build(BuildContext context) {
    final time = DurationComponents.fromDuration(duration);
    final writeHours = time.hours > 0;
    final writeMinutes = time.minutes > 0 || writeHours;

    final timeComponents = [
      if (writeHours) time.hours,
      if (writeMinutes) time.minutes,
      time.seconds,
    ];
    final shouldPad = [
      if (writeHours) true,
      if (writeMinutes) writeHours,
      alwaysPadSeconds || writeMinutes,
    ];

    return TimeComponentsWidget(
      components: timeComponents,
      padComponent: shouldPad,
      numberStyle: numberStyle,
      separatorStyle: separatorStyle,
    );
  }
}

class TimeOfDayWidget extends StatelessWidget {
  const TimeOfDayWidget({
    Key? key,
    required this.timeOfDay,
    this.numberStyle,
    this.separatorStyle,
    this.padHours = false,
  }) : super(key: key);
  final TimeOfDay timeOfDay;
  final TextStyle? numberStyle;
  final TextStyle? separatorStyle;
  final bool padHours;

  @override
  Widget build(BuildContext context) {
    final timeComponents = [
      timeOfDay.hour,
      timeOfDay.minute,
    ];
    final shouldPad = [
      padHours,
      true,
    ];

    return TimeComponentsWidget(
      components: timeComponents,
      padComponent: shouldPad,
      numberStyle: numberStyle,
      separatorStyle: separatorStyle,
    );
  }
}

class TimeComponentsWidget extends StatelessWidget {
  const TimeComponentsWidget({
    Key? key,
    required this.components,
    required this.padComponent,
    this.numberStyle,
    this.separatorStyle,
  }) : super(key: key);
  final List<int> components;
  final List<bool> padComponent;
  final TextStyle? numberStyle;
  final TextStyle? separatorStyle;
  static String _valueToPaddedString(int value) =>
      value.toString().padLeft(2, '0');

  Widget _digits(
    int digits,
    bool pad,
    TextStyle style,
  ) =>
      Text(
        pad ? _valueToPaddedString(digits) : digits.toString(),
        style: style,
      );
  Widget _separator(TextStyle style) => Text(
        ':',
        style: style,
      );

  @override
  Widget build(BuildContext context) {
    final numberStyle = this.numberStyle ?? context.textTheme.displayLarge;
    final separatorStyle =
        this.separatorStyle ?? context.textTheme.displayMedium;
    final separator = _separator(separatorStyle);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: Iterable.generate(
        components.length,
        (i) => _digits(
          components[i],
          padComponent[i],
          numberStyle,
        ),
      )
          .interleaved(
            (_) => separator,
          )
          .toList(),
    );
  }
}
