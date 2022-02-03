import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/model/date.dart';
import 'package:md3_clock/utils/layout.dart';
import 'package:md3_clock/widgets/duration.dart';
import 'package:md3_clock/widgets/weekday_picker.dart';
import 'package:value_notifier/value_notifier.dart';
import '../../model/weekday.dart';
import 'controller.dart';

enum CurrentTimeLayout {
  compactStartAligned,
  expandedCenterAligned,
}

class CurrentTime extends StatelessWidget {
  const CurrentTime({
    Key? key,
    required this.controller,
    this.layout = CurrentTimeLayout.compactStartAligned,
  }) : super(key: key);
  final CurrentTimeControler controller;
  final CurrentTimeLayout layout;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case CurrentTimeLayout.compactStartAligned:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DigitalClock(controller: controller),
            _DateAndNextAlarm(controller: controller),
          ],
        );
      case CurrentTimeLayout.expandedCenterAligned:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            _DigitalClock(controller: controller),
            const Spacer(),
            _DateAndNextAlarm(controller: controller),
          ],
        );
    }
  }
}

class _DateAndNextAlarm extends StatelessWidget {
  const _DateAndNextAlarm({
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
  Widget build(BuildContext context) => DefaultTextStyle(
        style: context.textTheme.bodyMedium.copyWith(
          color: context.colorScheme.onSurface,
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
      );
}

class _DigitalClock extends StatelessWidget {
  const _DigitalClock({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final CurrentTimeControler controller;

  @override
  Widget build(BuildContext context) {
    TextStyle? numberStyle;
    if (isHuge(context)) {
      const adaptativeStyle = MD3TextStyle(
        base: TextStyle(),
        scale: MD3TextAdaptativeScale.single(
          MD3TextAdaptativeProperties(
            size: 128,
            height: 194,
          ),
        ),
      );
      numberStyle = adaptativeStyle.resolveTo(context.deviceType);
    }
    return controller.currentTime.build(
      builder: (context, time, _) => TimeOfDayWidget(
        timeOfDay: time,
        numberStyle: numberStyle,
      ),
    );
  }
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
