import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/model/time.dart';
import 'package:md3_clock/utils/utils.dart';

import '../model/duration_components.dart';
import '../typography/typography.dart';

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
      isNegative: time.isNegative,
    );
  }
}

class MomentOfDayWidget extends StatelessWidget {
  const MomentOfDayWidget({
    Key? key,
    required this.momentOfDay,
    this.numberStyle,
    this.padHours = false,
  }) : super(key: key);
  final MomentOfDay momentOfDay;
  final TextStyle? numberStyle;
  final bool padHours;

  @override
  Widget build(BuildContext context) {
    final timeComponents = [
      momentOfDay.hour,
      momentOfDay.minute,
      momentOfDay.second,
    ];
    final shouldPad = [
      padHours,
      true,
      true,
    ];

    return TimeComponentsWidget(
      components: timeComponents,
      padComponent: shouldPad,
      numberStyle: numberStyle,
    );
  }
}

class TimeOfDayWidget extends StatelessWidget {
  const TimeOfDayWidget({
    Key? key,
    required this.timeOfDay,
    this.numberStyle,
    this.padHours = false,
  }) : super(key: key);
  final TimeOfDay timeOfDay;
  final TextStyle? numberStyle;
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
    );
  }
}

class TimeComponentsWidget extends StatelessWidget {
  const TimeComponentsWidget({
    Key? key,
    required this.components,
    required this.padComponent,
    this.numberStyle,
    this.isNegative,
  }) : super(key: key);
  final List<int> components;
  final List<bool> padComponent;
  final TextStyle? numberStyle;
  final bool? isNegative;
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

  @override
  Widget build(BuildContext context) {
    final isNegativeText = [if (isNegative == true) '-'];
    final text = isNegativeText
        .followedBy(Iterable.generate(
          components.length,
          (i) => _digits(
            components[i],
            padComponent[i],
          ),
        ).interleaved(
          (_) => _kSeparator,
        ))
        .join();
    return TabularNumberText(
      text,
      style: numberStyle ?? defaultStyleFor(context),
    );
  }
}

class TabularNumberText extends StatelessWidget {
  const TabularNumberText(
    this.data, {
    Key? key,
    this.style,
  }) : super(key: key);
  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: TextStyle(
        fontFeatures: [
          ...?style?.fontFeatures,
          const FontFeature.tabularFigures(),
        ],
      ).merge(style),
    );
  }
}
