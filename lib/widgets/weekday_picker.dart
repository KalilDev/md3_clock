import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/utils/utils.dart';

import '../model/weekday.dart';

const _kWeekdaySize = 32.0;
const _kWeekdayMinSep = 6.0;
const _weekdayMinSpace = SizedBox(width: _kWeekdayMinSep);

class WeekdaysPicker extends StatelessWidget {
  const WeekdaysPicker({
    Key? key,
    required this.value,
    required this.onTap,
    required this.isActive,
  }) : super(key: key);

  final Weekdays value;
  final ValueChanged<Weekday> onTap;
  final bool isActive;

  Widget _buildValue(BuildContext context, Weekday day) {
    final isSelected = value.active.contains(day);
    final states = {if (isSelected) MaterialState.selected};
    final scheme = context.colorScheme;
    final backgroundColor = MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return isActive ? scheme.primary : scheme.secondary;
      }
      return Colors.transparent;
    });
    final foregroundColor = MaterialStateColor.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return isActive ? scheme.onPrimary : scheme.onSecondary;
      }
      // TODO
      return scheme.outline;
    });
    final side = MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return BorderSide.none;
      }
      return BorderSide(
        width: 0.0,
        color: scheme.outline,
      );
    });
    return SizedBox.square(
      dimension: _kWeekdaySize,
      child: Material(
        shape: CircleBorder(
          side: side.resolve(states),
        ),
        color: backgroundColor.resolve(states),
        textStyle: context.textTheme.labelLarge.copyWith(
          color: foregroundColor.resolve(states),
          fontWeight: FontWeight.normal,
        ),
        child: InkWell(
          onTap: () => onTap(day),
          overlayColor: MD3StateOverlayColor(
            foregroundColor.resolve(states),
            context.stateOverlayOpacity,
          ),
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(day.letter),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: Weekday.values
          .map((e) => _buildValue(context, e))
          .interleaved((_) => _weekdayMinSpace)
          .toList(),
    );
    final minRowWidth = (Weekday.values.length - 1) * _kWeekdayMinSep +
        Weekday.values.length * _kWeekdaySize;
    final rowWidth = max(minRowWidth, width);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: rowWidth == minRowWidth
            ? const EdgeInsets.all(1.0)
            : EdgeInsets.zero,
        child: SizedBox(
          width: rowWidth,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);
}

extension WeekdayViewE on Weekday {
  String get text {
    switch (this) {
      case Weekday.saturday:
        return 'sáb';
      case Weekday.sunday:
        return 'dom';
      case Weekday.monday:
        return 'seg';
      case Weekday.tuesday:
        return 'ter';
      case Weekday.wednsday:
        return 'qua';
      case Weekday.thursday:
        return 'qui';
      case Weekday.friday:
        return 'sex';
    }
  }

  String get letter {
    switch (this) {
      case Weekday.saturday:
        return 'S';
      case Weekday.sunday:
        return 'D';
      case Weekday.monday:
        return 'S';
      case Weekday.tuesday:
        return 'T';
      case Weekday.wednsday:
        return 'Q';
      case Weekday.thursday:
        return 'Q';
      case Weekday.friday:
        return 'S';
    }
  }

  String get longText {
    switch (this) {
      case Weekday.saturday:
        return 'sábado';
      case Weekday.sunday:
        return 'domingo';
      case Weekday.monday:
        return 'segunda-feira';
      case Weekday.tuesday:
        return 'terça-feira';
      case Weekday.wednsday:
        return 'quarta-feira';
      case Weekday.thursday:
        return 'quinta-feira';
      case Weekday.friday:
        return 'sexta-feira';
    }
  }
}
