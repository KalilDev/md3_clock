import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:md3_clock/components/alarm_item/controller.dart';
import 'package:md3_clock/components/sorted_animated_list/controller.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/alarm.dart';
import '../../model/weekday.dart';

const kDefaultAlarm = Alarm('BusyBugs', true, AlarmSource.sounds);

class AlarmPageController extends ControllerBase<AlarmPageController> {
  late final SortedAnimatedListController<AlarmItemController> _itemControllers;

  AlarmPageController()
      : _itemControllers = SortedAnimatedListController.from(
          Iterable.generate(
            48,
            (i) => AlarmItemController.from(
              TimeOfDay(
                hour: i ~/ 2,
                minute: (i % 2) * 30,
              ),
              '',
              kDefaultAlarm,
              Weekdays({}),
              i.isEven,
              true,
              false,
              DateTime.now(),
            ),
          ),
          _compareItemControllers,
        ) {
    init();
  }

  SortedAnimatedListController<AlarmItemController>
      get alarmItemListController => _itemControllers;

  void addNewAlarm(TimeOfDay initialTime) async {
    final controller = AlarmItemController.create(initialTime, kDefaultAlarm);
    _registerAlarmItemController(controller);

    _itemControllers.insert(controller);
  }

  @override
  void init() {
    for (final controller in _itemControllers.values.value) {
      _registerAlarmItemController(controller);
    }
    _itemControllers.didDiscardItem.tap(IDisposable.disposeObj);
    super.init();
  }

  @override
  void dispose() {
    IDisposable.disposeAll(_itemControllers.values.value);
    _itemControllers.dispose();
    super.dispose();
  }

  void _deleteController(AlarmItemController controller) {
    _itemControllers.remove(controller);
  }

  void _onControllerTimeChanged(AlarmItemController controller) {
    _itemControllers.reSortValue(controller);
  }

  void _registerAlarmItemController(AlarmItemController controller) {
    controller.didDelete.tap((_) => _deleteController(controller));
    controller.time.tap((_) => _onControllerTimeChanged(controller));
  }
}

int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
  if (b.hour != a.hour) {
    return a.hour > b.hour ? 1 : -1;
  }
  if (a.minute == b.minute) {
    return 0;
  }
  return a.minute > b.minute ? 1 : -1;
}

int _compareItemControllers(AlarmItemController a, AlarmItemController b) {
  if (identical(a, b)) {
    return 0;
  }
  final currentTimeComparission = _compareTimeOfDay(a.time.value, b.time.value);
  if (currentTimeComparission != 0) {
    return currentTimeComparission;
  }
  return a.itemCreationTime.compareTo(b.itemCreationTime);
}
