import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/model/date.dart';
import 'package:md3_clock/widgets/duration.dart';
import 'package:md3_clock/widgets/weekday_picker.dart';
import 'package:value_notifier/value_notifier.dart';
import '../../model/weekday.dart';
import 'controller.dart';

class CurrentTime extends StatelessWidget {
  const CurrentTime({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final CurrentTimeControler controller;

  Widget _currentWeekday(BuildContext context) =>
      controller.currentWeekday.build(
        builder: (context, weekday, _) => _WeekdayWidget(weekday: weekday),
      );
  Widget _currentDate(BuildContext context) => controller.currentDate.build(
        builder: (context, date, _) => _DateWidget(date: date),
      );
  Widget _nextAlarm(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: _kNextAlarmSeparatorWidth),
        child: controller.nextAlarm.cast<NextAlarmViewModel>().build(
              builder: (context, nextAlarm, _) =>
                  _NextAlarmWidget(nextAlarm: nextAlarm),
            ),
      );
  Widget _maybeNextAlarm(BuildContext context) => controller.hasNextAlarm.build(
        builder: (context, hasNextAlarm, _) =>
            hasNextAlarm ? _nextAlarm(context) : const SizedBox(),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          controller.currentTime.build(
            builder: (context, time, _) => TimeOfDayWidget(
              timeOfDay: time,
            ),
          ),
          DefaultTextStyle(
            style: context.textTheme.bodyMedium.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _currentWeekday(context),
                const Text(', '),
                _currentDate(context),
                _maybeNextAlarm(context),
              ],
            ),
          )
        ],
      );
}

const _kNextAlarmSeparatorWidth = 4.0;

class _WeekdayWidget extends StatelessWidget {
  const _WeekdayWidget({
    Key? key,
    required this.weekday,
    this.style,
  }) : super(key: key);
  final Weekday weekday;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      weekday.text,
      style: style,
    );
  }
}

class _DateWidget extends StatelessWidget {
  const _DateWidget({
    Key? key,
    required this.date,
    this.style,
  }) : super(key: key);
  final Date date;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = '${date.day} de ${date.month.name}';
    return Text(
      text,
      style: style,
    );
  }
}

class _NextAlarmWidget extends StatelessWidget {
  const _NextAlarmWidget({
    Key? key,
    required this.nextAlarm,
  }) : super(key: key);
  final NextAlarmViewModel nextAlarm;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.alarm,
            size: 14,
            color: DefaultTextStyle.of(context).style.color,
          ),
          const SizedBox(width: _kNextAlarmSeparatorWidth),
          _WeekdayWidget(weekday: nextAlarm.weekday),
          const Text(', '),
          Text(nextAlarm.time.format(context)),
        ],
      );
}
