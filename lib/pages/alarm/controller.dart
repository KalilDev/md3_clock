import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:md3_clock/components/alarm_item/controller.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/alarm.dart';
import '../../model/weekday.dart';
// TODO: get rid of this bs asap
import 'widget.dart' show kAnimatedListDuration;

const kDefaultAlarm = Alarm('BusyBugs', true, AlarmSource.sounds);

class AlarmPageController extends ControllerBase {
  late final ListValueNotifier<AlarmItemController> _itemControllers;
  final EventNotifier<IndexAndController> _didRemoveItem = EventNotifier();
  final EventNotifier<int> _didInsertItem = EventNotifier();

  AlarmPageController()
      : _itemControllers = ListValueNotifier.generate(
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
        ) {
    init();
  }

  ValueListenable<UnmodifiableListView<AlarmItemController>>
      get itemControllers => _itemControllers.view();
  ValueListenable<IndexAndController> get didRemoveItem =>
      _didRemoveItem.viewNexts();
  ValueListenable<int> get didInsertItem => _didInsertItem.viewNexts();

  void addNewAlarm(TimeOfDay initialTime) async {
    final controller = AlarmItemController.create(initialTime, kDefaultAlarm);
    _registerAlarmItemController(controller);

    final currentItemControllers = _itemControllers.value;

    // Sorted list linear scan for maybe finding the sorted target index.
    // time complexity: O(n)
    // space complexity: O(1)
    //
    // An possible improvement would be to binary search the target pos. But
    // hey! this does not matter, the slow part is the ui.

    int sortedItemIndex = -1;
    for (var i = 0; i < currentItemControllers.length; i++) {
      final controllerAtI = currentItemControllers[i];
      final comparissionResult =
          _compareItemControllers(controller, controllerAtI);
      if (comparissionResult != -1) {
        // We did not reach the item right after the sorted position yet.
        continue;
      }
      sortedItemIndex = i;
      break;
    }
    if (sortedItemIndex == -1) {
      // If we did not find an item that is after the target position, then the
      // target position is the end of the list.
      sortedItemIndex = currentItemControllers.length - 1;
    }
    _insertController(controller, sortedItemIndex);
    await _listAnimationFuture;
    controller.requestScrollToTop();
  }

  void init() {
    for (final controller in _itemControllers) {
      _registerAlarmItemController(controller);
    }
    super.init();
  }

  void dispose() {
    IDisposable.disposeAll(
      _itemControllers,
    );

    IDisposable.disposeAll(
      [
        _itemControllers,
        _didRemoveItem,
        _didInsertItem,
      ],
    );
    super.dispose();
  }

  void _removeController(AlarmItemController controller) {
    final index = _itemControllers.indexOf(controller);
    _itemControllers.removeAt(index);
    _didRemoveItem.add(IndexAndController(index, controller));
  }

  void _insertController(AlarmItemController controller, int index) {
    _itemControllers.insert(index, controller);
    _didInsertItem.add(index);
  }

  void _deleteController(AlarmItemController controller) async {
    _removeController(controller);
    await _listAnimationFuture;
    WidgetsBinding.instance!.addPostFrameCallback((_) => controller.dispose());
  }

  void _onControllerTimeChanged(AlarmItemController controller) async {
    if (_itemControllers.length == 1) {
      return;
    }
    final currentItemControllers = _itemControllers.value;

    // Sorted list linear scan for maybe finding the current index, and finding
    // the target sorted index.
    // time complexity: O(n)
    // space complexity: O(1)
    //
    // An possible improvement would be to binary search the target pos and
    // check if [controller] occupies pos. But hey! this does not matter, the
    // slow part is the ui. It was fun making it a bit better than just cloning
    // the list and calling list.sort!

    int currentItemIndex = -1;
    int sortedItemIndex = -1;

    bool? isControllerSorted;

    for (var i = 0; i < currentItemControllers.length; i++) {
      final controllerAtI = currentItemControllers[i];
      if (controllerAtI == controller) {
        currentItemIndex = i;
        // continue until we find the sorted index.
        if (sortedItemIndex == -1) {
          continue;
        } else {
          break;
        }
      }
      final comparissionResult =
          _compareItemControllers(controller, controllerAtI);
      if (comparissionResult != -1) {
        // We did not reach the item right after the sorted position yet.
        continue;
      }
      final didPassThroughCurrent = currentItemIndex != -1;
      final indexOffset = didPassThroughCurrent ? -1 : 0;
      sortedItemIndex = i + indexOffset;
      // We reached the item that is after the target position of the
      // controller before reaching the controller, therefore, it is not sorted.
      isControllerSorted = false;
      break;
    }
    if (sortedItemIndex == -1) {
      // If we did not find an item that is after the target position, then the
      // target position is the end of the list.
      sortedItemIndex = currentItemControllers.length - 1;
    }
    isControllerSorted ??= currentItemIndex == sortedItemIndex;

    if (isControllerSorted) {
      return;
    }
    _removeController(controller);
    _insertController(controller, sortedItemIndex);
    await _listAnimationFuture;
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) => controller.requestScrollToTop(),
    );
  }

  // TODO: do this properly, FUCK,this.
  static Future<void> get _listAnimationFuture =>
      Future.delayed(kAnimatedListDuration)
          .then((_) => print('Awaited animation'));

  void _registerAlarmItemController(AlarmItemController controller) {
    controller.didDelete.tap((_) => _deleteController(controller));
    controller.time.tap((_) => _onControllerTimeChanged(controller));
  }
}

class IndexAndController {
  final int index;
  final AlarmItemController controller;

  IndexAndController(this.index, this.controller);
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
