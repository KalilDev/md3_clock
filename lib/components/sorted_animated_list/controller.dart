import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:value_notifier/value_notifier.dart';

class SortedAnimatedListController<T> extends ControllerBase {
  late final ListValueNotifier<T> _values;
  final EventNotifier<IsMoveStepAndValue<IndexAndValue<T>>> _didRemoveItem =
      EventNotifier();
  final EventNotifier<IsMoveStepAndValue<int>> _didInsertItem = EventNotifier();
  final int Function(T, T) _compare;
  SortedAnimatedListController.from(
    Iterable<T> elements,
    this._compare,
  ) : _values = ListValueNotifier.of(elements) {
    init();
  }
  ValueListenable<UnmodifiableListView<T>> get values => _values.view();
  ValueListenable<IsMoveStepAndValue<IndexAndValue<T>>> get didRemoveItem =>
      _didRemoveItem.viewNexts();
  ValueListenable<IsMoveStepAndValue<int>> get didInsertItem =>
      _didInsertItem.viewNexts();

  void insert(T value) {
    // Sorted list linear scan for maybe finding the sorted target index.
    // time complexity: O(n)
    // space complexity: O(1)
    //
    // An possible improvement would be to binary search the target pos. But
    // hey! this does not matter, the slow part is the ui.

    int sortedItemIndex = -1;
    for (var i = 0; i < _values.length; i++) {
      final valueAtI = _values[i];
      final comparissionResult = _compare(value, valueAtI);
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
      sortedItemIndex = _values.length - 1;
    }
    _insertValue(value, sortedItemIndex);
  }

  void reSortValue(T value) {
    if (_values.length == 1) {
      return;
    }

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

    for (var i = 0; i < _values.length; i++) {
      final valueAtI = _values[i];
      if (valueAtI == value) {
        currentItemIndex = i;
        // continue until we find the sorted index.
        if (sortedItemIndex == -1) {
          continue;
        } else {
          break;
        }
      }
      final comparissionResult = _compare(value, valueAtI);
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
      sortedItemIndex = _values.length - 1;
    }
    isControllerSorted ??= currentItemIndex == sortedItemIndex;

    if (isControllerSorted) {
      return;
    }
    _removeValue(value, true);
    _insertValue(value, sortedItemIndex, true);
  }

  void _removeValue(T value, [bool isPartOfMove = false]) {
    final index = _values.indexOf(value);
    _values.removeAt(index);
    _didRemoveItem.add(IsMoveStepAndValue(
      isPartOfMove,
      IndexAndValue(index, value),
    ));
  }

  void _insertValue(T controller, int index, [bool isPartOfMove = false]) {
    _values.insert(index, controller);
    _didInsertItem.add(IsMoveStepAndValue(isPartOfMove, index));
  }

  void init() {
    _values.sort(_compare);
  }
}

class IsMoveStepAndValue<T> {
  final bool isMoveStep;
  final T value;

  IsMoveStepAndValue(this.isMoveStep, this.value);
}

class IndexAndValue<T> {
  final int index;
  final T value;

  IndexAndValue(this.index, this.value);
}
