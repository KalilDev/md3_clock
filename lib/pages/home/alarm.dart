import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../components/alarm_item/controller.dart';
import '../../components/alarm_item/widget.dart';
import '../../model/alarm.dart';
import '../../model/weekday.dart';

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
  final EventNotifier<_IndexAndController> _didRemoveItem = EventNotifier();
  IDisposableValueListenable<_IndexAndController> get didRemoveItem =>
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
    _didRemoveItem.add(_IndexAndController(index, controller));
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
      Future.delayed(_kAnimatedListDuration)
          .then((_) => print('Awaited animation'));

  void _registerAlarmItemController(AlarmItemController controller) {
    controller.didDelete.tap((_) => _deleteController(controller));
    controller.time.tap((_) => _onControllerTimeChanged(controller));
  }
}

class _IndexAndController {
  final int index;
  final AlarmItemController controller;

  _IndexAndController(this.index, this.controller);
}

const _kAnimatedListDuration = Duration(milliseconds: 500);

class _ListExitTransition extends StatelessWidget {
  const _ListExitTransition({
    Key? key,
    required this.animation,
    required this.child,
  }) : super(key: key);
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Interval(2 / 3, 1),
          ),
          child: child,
        ),
      );
}

class _ListEntranceTransition extends StatelessWidget {
  const _ListEntranceTransition({
    Key? key,
    required this.animation,
    required this.child,
  }) : super(key: key);
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Interval(2 / 3, 1),
          ),
          child: child,
        ),
      );
}

class _AlarmItemCard extends StatelessWidget {
  const _AlarmItemCard({Key? key, required this.controller}) : super(key: key);
  final AlarmItemController controller;

  @override
  Widget build(BuildContext context) {
    final didRequestScrollToTop = controller.didRequestScrollToTop;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: CardStyle.kMaxCardSpacing / 2,
      ),
      child: EventListener<void>(
        key: ObjectKey(didRequestScrollToTop),
        event: didRequestScrollToTop,
        onEvent: (_) => focusScrollviewOnContext(context),
        child: AlarmItemCard(controller: controller),
      ),
    );
  }
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({Key? key, required this.controller}) : super(key: key);
  final AlarmPageController controller;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  final listKey = GlobalKey<AnimatedListState>();

  late IDisposable _itemInsertHandler;
  late IDisposable _itemRemoveHandler;

  void initState() {
    super.initState();
    _updateController(widget.controller);
  }

  void didUpdateWidget(AlarmPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _detachController();
      _updateController(widget.controller);
    }
  }

  void _updateController(AlarmPageController controller) {
    _itemInsertHandler = controller.didInsertItem.tap(_onItemInserted);
    _itemRemoveHandler = controller.didRemoveItem.tap(_onItemRemoved);
  }

  void _detachController() {
    _itemInsertHandler.dispose();
    _itemRemoveHandler.dispose();
  }

  void _onItemInserted(int index) {
    listKey.currentState!.insertItem(
      index,
      duration: _kAnimatedListDuration,
    );
  }

  void _onItemRemoved(_IndexAndController indexAndController) {
    final index = indexAndController.index;
    final controller = indexAndController.controller;
    listKey.currentState!.removeItem(
      index,
      (context, animation) => _ListExitTransition(
        key: ObjectKey(animation),
        animation: animation,
        child: _AlarmItemCard(
          controller: controller,
        ),
      ),
      duration: _kAnimatedListDuration,
    );
  }

  void dispose() {
    _detachController();
    super.dispose();
  }

  Widget _cardTheme(BuildContext context, {required Widget child}) =>
      FilledCardTheme(
        data: FilledCardThemeData(
          style: CardStyle(
              clipBehavior: Clip.antiAlias,
              padding: MaterialStateProperty.all(
                EdgeInsets.symmetric(
                  horizontal: 16,
                ),
              ),
              backgroundColor: MD3ElevationTintableColor(
                context.colorScheme.surface,
                MD3ElevationLevel.surfaceTint(context.colorScheme),
                MaterialStateProperty.all(context.elevation.level1),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                ),
              )),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return _cardTheme(
      context,
      child: widget.controller.itemControllers.buildView(
        builder: (context, itemControllers, _) => AnimatedList(
          key: listKey,
          padding: const EdgeInsets.symmetric(
            vertical: CardStyle.kMaxCardSpacing / 2,
          ),
          itemBuilder: (c, i, a) {
            final itemController = widget.controller.itemControllers.value[i];
            return _ListEntranceTransition(
              key: ObjectKey(itemController),
              animation: a,
              child: _AlarmItemCard(
                controller: itemController,
              ),
            );
          },
          initialItemCount: itemControllers.length,
        ),
      ),
    );
  }
}

class AlarmPageFab extends StatelessWidget {
  const AlarmPageFab({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final AlarmPageController controller;

  @override
  Widget build(BuildContext context) {
    const child = Icon(Icons.add);
    void onPressed() {
      showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      ).then((value) => value == null ? null : controller.addNewAlarm(value));
    }

    if (useLargeFab(context)) {
      return MD3FloatingActionButton.large(
        onPressed: onPressed,
        child: child,
      );
    }
    return MD3FloatingActionButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
