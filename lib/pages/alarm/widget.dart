import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/sorted_animated_list/controller.dart';
import 'package:md3_clock/components/sorted_animated_list/widget.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/widgets/fab_safe_area.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../components/alarm_item/controller.dart';
import '../../components/alarm_item/widget.dart';
import '../../model/alarm.dart';
import '../../model/weekday.dart';
import '../../utils/theme.dart';
import 'controller.dart';

const kAnimatedListDuration = Duration(milliseconds: 500);

class _AnimationStatusNotifier extends StatefulWidget {
  const _AnimationStatusNotifier({
    Key? key,
    required this.onStatus,
    required this.animation,
    required this.status,
    required this.child,
  }) : super(key: key);
  final VoidCallback onStatus;
  final AnimationStatus status;
  final Animation<Object?> animation;
  final Widget child;

  @override
  __AnimationStatusNotifier createState() => __AnimationStatusNotifier();
}

class __AnimationStatusNotifier extends State<_AnimationStatusNotifier> {
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  AnimationStatus? _lastNotified;
  void _onStatus(AnimationStatus status) {
    if (_lastNotified == status) {
      return;
    }
    _lastNotified = status;
    widget.onStatus();
  }

  @override
  void didUpdateWidget(_AnimationStatusNotifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_onStatus);
      _lastNotified = null;
    }
  }

  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
    required this.onAnimationFinish,
    required this.child,
  }) : super(key: key);
  final Animation<double> animation;
  final VoidCallback onAnimationFinish;
  final Widget child;

  @override
  Widget build(BuildContext context) => _AnimationStatusNotifier(
        animation: animation,
        onStatus: onAnimationFinish,
        status: AnimationStatus.completed,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Interval(2 / 3, 1),
            ),
            child: child,
          ),
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
        child: AlarmItemCard(
          controller: controller,
          useSmallPadding:
              MediaQuery.of(context).orientation != Orientation.landscape,
        ),
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
  }

  void didUpdateWidget(AlarmPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void dispose() {
    super.dispose();
  }

  Widget _cardTheme(
    BuildContext context, {
    required Widget child,
  }) {
    return FilledCardTheme(
      data: FilledCardThemeData(
        style: CardStyle(
            clipBehavior: Clip.antiAlias,
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
      child: SortedAnimatedList<AlarmItemController>(
        key: listKey,
        controller: widget.controller.alarmItemListController,
        padding: const EdgeInsets.only(
          top: CardStyle.kMaxCardSpacing / 2,
          bottom: 24,
        ).add(FabSafeArea.fabPaddingFor(context)),
        removingItemBuilder: (context, value, animation) => _ListExitTransition(
          key: ObjectKey(animation),
          animation: animation,
          child: _AlarmItemCard(
            controller: value,
          ),
        ),
        itemBuilder: (context, value, animation) => _ListEntranceTransition(
          key: ObjectKey(value),
          animation: animation,
          onAnimationFinish: value.requestScrollToTop,
          child: _AlarmItemCard(
            controller: value,
          ),
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
      style: ButtonStyle(fixedSize: MaterialStateProperty.all(Size.square(72))),
      onPressed: onPressed,
      colorScheme: primarySchemeOf(context),
      child: child,
    );
  }
}
