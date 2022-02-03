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

  static TextStyle defaultStyleFor(BuildContext context) =>
      TimeComponentsWidget.defaultStyleFor(context);
  static TextSpan spanFor({
    required Duration duration,
    required TextStyle style,
    bool alwaysPadSeconds = false,
  }) {
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

    return TimeComponentsWidget.spanFor(
      components: timeComponents,
      padComponent: shouldPad,
      style: style,
    );
  }

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

  static String _digits(
    int digits,
    bool pad,
  ) =>
      pad ? _valueToPaddedString(digits) : digits.toString();
  static const _kSeparator = ':';

  static TextStyle defaultStyleFor(BuildContext context) =>
      context.textTheme.displayLarge;
  static TextSpan spanFor({
    required List<int> components,
    required List<bool> padComponent,
    required TextStyle style,
  }) {
    return TextSpan(
      style: style,
      text: Iterable.generate(
        components.length,
        (i) => _digits(
          components[i],
          padComponent[i],
        ),
      )
          .interleaved(
            (_) => _kSeparator,
          )
          .join(),
    );
  }
}

class NumberText extends StatelessWidget {
  const NumberText(
    this.number, {
    Key? key,
    this.style,
  }) : super(key: key);
  final String number;
  final TextStyle? style;

  static String _referenceDigits(
    String digits,
  ) {
    final length = digits.length;
    return '0' * length;
  }

  static const _kDigits = {
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  };

  @override
  Widget build(BuildContext context) {
    var text = number.toString();
    final referenceText = _referenceDigits(text);
    return PrototypeText(
      reference: referenceText,
      target: text,
      initialCharacterSet: _kDigits,
      style: style,
    );
  }
}
