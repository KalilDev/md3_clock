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
import '../../utils/theme.dart';
import 'controller.dart';

const kAnimatedListDuration = Duration(milliseconds: 500);

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
      duration: kAnimatedListDuration,
    );
  }

  void _onItemRemoved(IndexAndController indexAndController) {
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
      duration: kAnimatedListDuration,
    );
  }

  void dispose() {
    _detachController();
    super.dispose();
  }

  Widget _cardTheme(
    BuildContext context, {
    required Widget child,
  }) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTiny = MediaQuery.of(context).size.shortestSide < 360;
    final useLargerPadding = isLandscape;
    return FilledCardTheme(
      data: FilledCardThemeData(
        style: CardStyle(
            clipBehavior: Clip.antiAlias,
            padding: MaterialStateProperty.all(
              EdgeInsets.symmetric(
                horizontal: useLargerPadding ? 44 : 16,
              ),
            ),
            backgroundColor: MD3ElevationTintableColor(
              context.colorScheme.surface,
              MD3ElevationLevel.surfaceTint(context.colorScheme),
              MaterialStateProperty.all(context.elevation.level2),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  26,
                ),
              ),
            )),
      ),
      child: child,
    );
  }

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
        colorScheme: primarySchemeOf(context),
        child: IconTheme.merge(
          data: const IconThemeData(size: 24),
          child: child,
        ),
      );
    }
    return MD3FloatingActionButton(
      onPressed: onPressed,
      colorScheme: primarySchemeOf(context),
      child: child,
    );
  }
}
