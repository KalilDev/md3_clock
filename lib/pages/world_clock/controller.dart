import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/current_time/controller.dart';
import 'package:md3_clock/components/sorted_animated_list/controller.dart';
import 'package:md3_clock/model/city.dart';
import 'package:md3_clock/model/time.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/utils/chrono.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/weekday.dart';
import '../preferences/controller.dart';

int _compareCity(City a, City b) {
  {
    final nameResult = a.name.compareTo(b.name);
    if (nameResult != 0) {
      return nameResult;
    }
  }

  if (a.stateName != null && b.stateName != null) {
    final stateResult = a.stateName!.compareTo(b.stateName!);
    if (stateResult != 0) {
      return stateResult;
    }
  }
  {
    final countryResult = a.countryName.compareTo(b.countryName);
    if (countryResult != 0) {
      return countryResult;
    }
  }
  final offsetResult = a.timeZoneOffset.compareTo(b.timeZoneOffset);
  return offsetResult;
}

int _compareCityViewModel(CityViewModel a, CityViewModel b) {
  return _compareCity(a.city, b.city);
}

bool _dateTimeEqualsByMinute(DateTime a, DateTime b) =>
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day &&
    a.hour == b.hour &&
    a.minute == b.minute;

// The current time is stored in the model because every city can be mutated
// in a single [SortedAnimatedListController.mutate] call and rebuilding the
// entire list, instead of many calls with numerous notifyListeners and
// AnimatedBuilders.
class CityViewModel {
  final City city;
  final Duration timeZoneOffsetLocal;
  final MomentOfDay currentOffsetTime;

  const CityViewModel(
    this.city,
    this.timeZoneOffsetLocal,
    this.currentOffsetTime,
  );
  factory CityViewModel.fromCity(City city) {
    final now = DateTime.now();
    return CityViewModel(
      city,
      Duration.zero,
      MomentOfDay(hour: 0, minute: 0, second: 0),
    ).withUtcTime(
      now.toUtc(),
      now.timeZoneOffset,
    );
  }
  Duration get timeZoneOffsetUtc => city.timeZoneOffset;
  CityViewModel withUtcTime(
    DateTime utcTime,
    Duration currentTimeZoneUtcOffset,
  ) =>
      CityViewModel(
        city,
        timeZoneOffsetUtc - currentTimeZoneUtcOffset,
        MomentOfDay.fromDateTime(
          utcTime.add(timeZoneOffsetUtc),
        ),
      );
}

class ClockPageController extends ControllerBase<ClockPageController> {
  final SortedAnimatedListController<CityViewModel> clocksList;
  final ITick _ticker;
  final CurrentTimeControler currentTimeController;
  final ValueNotifier<ClockStyle> _clockStyle;
  final ValueNotifier<bool> _showSeconds;
  final ValueNotifier<bool> _autoHomeTimezoneClock;
  final ValueNotifier<Timezone?> _homeTimezone;

  ClockPageController({
    Iterable<City> initialCities = const [],
    NextAlarmViewModel? nextAlarm,
    required ClockStyle clockStyle,
    required bool showSeconds,
    required bool autoHomeTimezoneClock,
    required Timezone? homeTimezone,
    required ICreateTickers vsync,
  })  : clocksList = SortedAnimatedListController.from(
          initialCities.map(CityViewModel.fromCity),
          _compareCityViewModel,
        ),
        _ticker = vsync.createTicker(),
        currentTimeController = CurrentTimeControler(
          nextAlarm: nextAlarm,
        ),
        _clockStyle = ValueNotifier(clockStyle),
        _showSeconds = ValueNotifier(showSeconds),
        _autoHomeTimezoneClock = ValueNotifier(autoHomeTimezoneClock),
        _homeTimezone = ValueNotifier(homeTimezone) {
          AnimatedIcon
        }

  ValueListenable<DateTime> get currentLocalTime => _ticker.elapsedTick
      .map((_) => DateTime.now())
      .withInitial(DateTime.now());

  ValueListenable<DateTime> get currentUTCTime =>
      currentLocalTime.map((time) => time.toUtc());
  ValueListenable<DateTime> get currentLocalTimeByMinute =>
      currentLocalTime.unique(_dateTimeEqualsByMinute);
  ValueListenable<DateTime> get currentUTCTimeByMinute =>
      currentLocalTimeByMinute.map((time) => time.toUtc());
  ValueListenable<DateTime> get currentLocalTimeTick =>
      showSeconds.bind((showSeconds) =>
          showSeconds ? currentLocalTime : currentLocalTimeByMinute);
  ValueListenable<DateTime> get currentUTCTimeTick => showSeconds.bind(
      (showSeconds) => showSeconds ? currentUTCTime : currentUTCTimeByMinute);

  ValueListenable<ClockStyle> get clockStyle => _clockStyle.view();
  ValueListenable<bool> get showSeconds => _showSeconds.view();
  ValueListenable<bool> get autoHomeTimezoneClock =>
      _autoHomeTimezoneClock.view();
  ValueListenable<Timezone?> get homeTimezone => _homeTimezone.view();

  late final setClockStyle = _clockStyle.setter;
  late final setShowSeconds = _showSeconds.setter;
  late final setAutoHomeTimezoneClock = _autoHomeTimezoneClock.setter;
  late final setHomeTimezone = _homeTimezone.setter;

  void onAddCity(City city) {
    clocksList.insert(CityViewModel.fromCity(city));
  }

  void onRemoveCity(CityViewModel city) {
    clocksList.remove(city);
  }

  void onUpdateNextAlarm(NextAlarmViewModel? nextAlarm) {
    currentTimeController.updateNextAlarm(nextAlarm);
  }

  ValueListenable<DateTime> get _clockListTimeTick => showSeconds.bind(
        (showSeconds) => !showSeconds
            ? currentLocalTimeByMinute
            : clockStyle.bind(
                (style) => style == ClockStyle.analog
                    ? currentLocalTime
                    : currentLocalTimeByMinute,
              ),
      );

  void init() {
    super.init();
    currentLocalTimeTick.connect(_updateCurrentTime);
    _clockListTimeTick.connect(_updateClocksList);
    _ticker.start();
    clockStyle.connect(currentTimeController.setStyle);
    showSeconds.connect(currentTimeController.setShowSeconds);
  }

  void _updateClocksList(DateTime now) {
    final nowUtc = now.toUtc();
    final currentTimeZoneUtcDifference = now.timeZoneOffset;
    final timeOfDayUtc = DateTime.utc(
      nowUtc.year,
      nowUtc.month,
      nowUtc.day,
      now.hour,
      now.minute,
      now.second,
    );
    clocksList.mutate((clocks) {
      for (var i = 0; i < clocks.length; i++) {
        clocks[i] = clocks[i].withUtcTime(
          timeOfDayUtc,
          currentTimeZoneUtcDifference,
        );
      }
    });
  }

  void _updateCurrentTime(DateTime now) {
    currentTimeController.updateLocalTime(now);
  }
}
