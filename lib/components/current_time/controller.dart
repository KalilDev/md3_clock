import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:md3_clock/model/date.dart';
import 'package:md3_clock/model/time.dart';
import 'package:md3_clock/model/weekday.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
import 'package:value_notifier/value_notifier.dart';

class NextAlarmViewModel {
  final Weekday weekday;
  final TimeOfDay time;

  NextAlarmViewModel(this.weekday, this.time);
}

class CurrentTimeControler extends ControllerBase<CurrentTimeControler> {
  ValueNotifier<DateTime> _localTime;
  ValueNotifier<NextAlarmViewModel?> _nextAlarm;
  ValueNotifier<ClockStyle> _style;
  ValueNotifier<bool> _showSeconds;

  CurrentTimeControler({
    DateTime? localTime,
    NextAlarmViewModel? nextAlarm,
    ClockStyle? style,
    bool? showSeconds,
  })  : _localTime = ValueNotifier(localTime ?? DateTime.now()),
        _nextAlarm = ValueNotifier(nextAlarm),
        _style = ValueNotifier(style ?? ClockStyle.digital),
        _showSeconds = ValueNotifier(showSeconds ?? false);

  ValueListenable<DateTime> get localTime => _localTime.view();
  ValueListenable<NextAlarmViewModel?> get nextAlarm => _nextAlarm.view();
  ValueListenable<ClockStyle> get style => _style.view();
  ValueListenable<bool> get showSeconds => _showSeconds.view();

  ValueListenable<TimeOfDay> get currentTime =>
      localTime.map(TimeOfDay.fromDateTime).unique();
  ValueListenable<MomentOfDay> get currentMoment =>
      localTime.map(MomentOfDay.fromDateTime).unique();
  ValueListenable<Date> get currentDate =>
      localTime.map(Date.fromDateTime).unique();
  ValueListenable<Weekday> get currentWeekday => localTime
      .map((time) => time.weekday)
      .unique()
      .map((weekdayNum) => _kWeekdayTable[weekdayNum - 1]);
  ValueListenable<bool> get hasNextAlarm =>
      nextAlarm.map((e) => e != null).unique();

  void updateLocalTime(DateTime localTime) => _localTime.value = localTime;
  void updateNextAlarm(NextAlarmViewModel? nextAlarm) =>
      _nextAlarm.value = nextAlarm;
  late final setStyle = _style.setter;
  late final setShowSeconds = _showSeconds.setter;

  void dispose() {
    IDisposable.disposeAll([
      _localTime,
      _nextAlarm,
      _style,
    ]);
    super.dispose();
  }
}

const _kWeekdayTable = [
  Weekday.monday,
  Weekday.tuesday,
  Weekday.wednsday,
  Weekday.thursday,
  Weekday.friday,
  Weekday.saturday,
  Weekday.sunday,
];
