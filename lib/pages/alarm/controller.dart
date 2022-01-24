import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:md3_clock/components/alarm_item/controller.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/alarm.dart';
import '../../model/weekday.dart';
// TODO: get rid of this bs asap
import 'widget.dart' show kAnimatedListDuration;

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

class AlarmPageController extends IDisposableBase {
  // dont reference/use this directly, as it is not owned by the
  // [_AlarmPageListController]. only use it to set values on the
  // [_itemControllers] view.
  late final ValueNotifier<List<AlarmItemController>> __itemControllers =
      ValueNotifier(
    List.generate(
      48,
      (i) {
        final controller = AlarmItemController.from(
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
        );
        _registerAlarmItemController(controller);
        return controller;
      },
    ),
  );
  late final IDisposableValueListenable<
          UnmodifiableListView<AlarmItemController>> _itemControllers =
      __itemControllers.map(
    (items) => UnmodifiableListView(items),
  );
  IDisposableValueListenable<UnmodifiableListView<AlarmItemController>>
      get itemControllers => _itemControllers;
  final EventNotifier<IndexAndController> _didRemoveItem = EventNotifier();
  IDisposableValueListenable<IndexAndController> get didRemoveItem =>
      _didRemoveItem.viewNexts();
  final EventNotifier<int> _didInsertItem = EventNotifier();
  IDisposableValueListenable<int> get didInsertItem =>
      _didInsertItem.viewNexts();

  void dispose() {
    IDisposable.disposeAll(
      __itemControllers.value,
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
    final index = __itemControllers.value.indexOf(controller);
    __itemControllers.value.removeAt(index);
    // ignore: invalid_use_of_protected_member
    __itemControllers.notifyListeners();
    _didRemoveItem.add(IndexAndController(index, controller));
  }

  void _insertController(AlarmItemController controller, int index) {
    __itemControllers.value.insert(index, controller);
    // ignore: invalid_use_of_protected_member
    __itemControllers.notifyListeners();
    _didInsertItem.add(index);
  }

  void _deleteController(AlarmItemController controller) async {
    _removeController(controller);
    await listAnimationFuture;
    WidgetsBinding.instance!.addPostFrameCallback((_) => controller.dispose());
  }

  void _onControllerTimeChanged(AlarmItemController controller) async {
    if (__itemControllers.value.length == 1) {
      return;
    }
    final currentItemControllers = __itemControllers.value;

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
    await listAnimationFuture;
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) => controller.requestScrollToTop(),
    );
  }

  static const kDefaultAlarm = Alarm('BusyBugs', true, AlarmSource.sounds);

  void addNewAlarm(TimeOfDay initialTime) async {
    final controller = AlarmItemController.create(initialTime, kDefaultAlarm);
    _registerAlarmItemController(controller);

    final currentItemControllers = __itemControllers.value;

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
    await listAnimationFuture;
    controller.requestScrollToTop();
  }

  // TODO: do this properly, FUCK,this.
  static Future<void> get listAnimationFuture =>
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
