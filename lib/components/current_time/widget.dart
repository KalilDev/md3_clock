import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/model/date.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
import 'package:md3_clock/typography/typography.dart';
import 'package:md3_clock/utils/layout.dart';
import 'package:md3_clock/widgets/analog_clock.dart';
import 'package:md3_clock/widgets/duration.dart';
import 'package:md3_clock/widgets/weekday_picker.dart';
import 'package:value_notifier/value_notifier.dart';
import '../../model/weekday.dart';
import 'controller.dart';

enum CurrentTimeLayout {
  portrait,
  expandedCenterAligned,
}

class CurrentTime extends StatelessWidget {
  const CurrentTime({
    Key? key,
    required this.controller,
    this.layout = CurrentTimeLayout.portrait,
  }) : super(key: key);
  final CurrentTimeControler controller;
  final CurrentTimeLayout layout;

  Widget _buildPortraitBody(BuildContext context, bool isAnalog) => SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment:
              isAnalog ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            _DigitalOrAnalogClock(
              isAnalog: isAnalog,
              controller: controller,
            ),
            _DateAndNextAlarm(controller: controller),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case CurrentTimeLayout.portrait:
        return controller.style
            .map((style) => style == ClockStyle.analog)
            .map((isAnalog) => _buildPortraitBody(context, isAnalog))
            .build();
      case CurrentTimeLayout.expandedCenterAligned:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            _DigitalOrAnalogClock(controller: controller),
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
        style: context.textTheme.titleMedium.copyWith(
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

class _DigitalOrAnalogClock extends StatelessWidget {
  const _DigitalOrAnalogClock({
    Key? key,
    this.isAnalog,
    required this.controller,
  }) : super(key: key);
  final CurrentTimeControler controller;
  final bool? isAnalog;

  Widget _buildFromController(BuildContext context) => controller.style
      .map(
        (style) => style == ClockStyle.analog
            ? _AnalogClock(controller: controller)
            : _DigitalClock(controller: controller),
      )
      .build();

  Widget _buildFromIsAnalog(BuildContext context, bool isAnalog) => isAnalog
      ? _AnalogClock(controller: controller)
      : _DigitalClock(controller: controller);

  @override
  Widget build(BuildContext context) => isAnalog == null
      ? _buildFromController(context)
      : _buildFromIsAnalog(context, isAnalog!);
}

class _AnalogClock extends StatelessWidget {
  const _AnalogClock({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final CurrentTimeControler controller;

  Widget _buildClock(BuildContext context) => controller.showSeconds
      .bind(
        (showSeconds) => showSeconds
            ? controller.currentMoment.map((moment) => AnalogClock(
                  time: moment.toTimeOfDay(),
                  seconds: moment.second,
                ))
            : controller.currentTime.map((time) => AnalogClock(
                  time: time,
                )),
      )
      .build();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 312,
      width: 312,
      child: AspectRatio(
        aspectRatio: 1,
        child: _buildClock(context),
      ),
    );
  }
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
    } else {
      numberStyle = MD3ClockTypography
          .instance.clockTextTheme.currentTimeDisplay
          .resolveTo(context.deviceType);
    }
    return controller.showSeconds
        .bind(
          (showSeconds) => showSeconds
              ? controller.currentMoment.map((moment) => MomentOfDayWidget(
                    momentOfDay: moment,
                    padHours: true,
                    numberStyle: numberStyle,
                  ))
              : controller.currentTime.map((time) => TimeOfDayWidget(
                    timeOfDay: time,
                    padHours: true,
                    numberStyle: numberStyle,
                  )),
        )
        .build();
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
