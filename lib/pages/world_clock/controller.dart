import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/current_time/controller.dart';
import 'package:md3_clock/components/sorted_animated_list/controller.dart';
import 'package:md3_clock/model/city.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/utils/chrono.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/weekday.dart';

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

// The current time is stored in the model because every city can be mutated
// in a single [SortedAnimatedListController.mutate] call and rebuilding the
// entire list, instead of many calls with numerous notifyListeners and
// AnimatedBuilders.
class CityViewModel {
  final City city;
  final Duration timeZoneOffsetLocal;
  final TimeOfDay currentOffsetTime;

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
      TimeOfDay(hour: 0, minute: 0),
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
        TimeOfDay.fromDateTime(
          utcTime.add(timeZoneOffsetUtc),
        ),
      );
}

class ClockPageController extends ControllerBase<ClockPageController> {
  final SortedAnimatedListController<CityViewModel> clocksList;
  final ITick _ticker;
  final CurrentTimeControler currentTimeController;

  ClockPageController({
    Iterable<City> initialCities = const [],
    NextAlarmViewModel? nextAlarm,
    required ICreateTickers vsync,
  })  : clocksList = SortedAnimatedListController.from(
          initialCities.map(CityViewModel.fromCity),
          _compareCityViewModel,
        ),
        _ticker = vsync.createTicker(),
        currentTimeController = CurrentTimeControler(
          nextAlarm: nextAlarm,
        ) {
    init();
  }

  ValueListenable<DateTime> get currentLocalTime => _ticker.elapsedTick
      .map((_) => DateTime.now())
      .withInitial(DateTime.now());
  ValueListenable<TimeOfDay> get currentUtcTimeOfDay => currentLocalTime
      .map((time) => time.toUtc())
      .map(TimeOfDay.fromDateTime)
      .unique();

  void onAddCity(City city) {
    clocksList.insert(CityViewModel.fromCity(city));
  }

  void onRemoveCity(CityViewModel city) {
    clocksList.remove(city);
  }

  void onUpdateNextAlarm(NextAlarmViewModel? nextAlarm) {
    currentTimeController.updateNextAlarm(nextAlarm);
  }

  void init() {
    currentUtcTimeOfDay.tap(_onCurrentUtcTimeUpdate, includeInitial: true);
    _ticker.start();
  }

  void _onCurrentUtcTimeUpdate(TimeOfDay time) {
    final now = DateTime.now();
    currentTimeController.updateLocalTime(now);
    final nowUtc = now.toUtc();
    final currentTimeZoneUtcDifference = now.timeZoneOffset;
    final timeOfDayUtc = DateTime.utc(
      nowUtc.year,
      nowUtc.month,
      nowUtc.day,
      time.hour,
      time.minute,
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
}
