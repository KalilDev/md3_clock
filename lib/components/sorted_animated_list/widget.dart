import 'package:flutter/material.dart';
import 'package:value_notifier/value_notifier.dart';

import 'controller.dart';

const Duration _kDuration = Duration(milliseconds: 300);

class SortedAnimatedList<T> extends StatefulWidget {
  const SortedAnimatedList({
    Key? key,
    required this.controller,
    required this.itemBuilder,
    this.removingItemBuilder,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.clipBehavior = Clip.hardEdge,
    this.insertionDuration = _kDuration,
    this.removalDuration = _kDuration,
  }) : super(key: key);

  final SortedAnimatedListController<T> controller;
  final Widget Function(BuildContext, T, Animation<double>) itemBuilder;
  final Widget Function(BuildContext, T, Animation<double>)?
      removingItemBuilder;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? scrollController;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final Duration insertionDuration;
  final Duration removalDuration;

  @override
  State<SortedAnimatedList<T>> createState() => _SortedAnimatedListState<T>();
}

class _SortedAnimatedListState<T> extends State<SortedAnimatedList<T>> {
  IDisposable _connections = IDisposable.merge([]);
  SortedAnimatedListController<T>? controller;
  final GlobalKey<AnimatedListState> listKey = GlobalKey();

  void _onInsertItem(int index) {
    listKey.currentState!.insertItem(
      index,
      duration: widget.insertionDuration,
    );
  }

  void _onRemoveItem(IsMoveStepAndValue<IndexAndValue<T>> info) {
    final targetInfo = IsMoveStepAndValue(info.isMoveStep, info.value.value);
    void onDiscard() {
      if (info.isMoveStep) {
        return;
      }
      controller!.onDiscardItem(info.value.value);
    }

    final baseBuilder = widget.removingItemBuilder ?? widget.itemBuilder;

    Widget itemBuilder(
      BuildContext context,
      Animation<double> animation,
    ) =>
        _ItemDiscardNotifier(
          onDiscard: onDiscard,
          animation: animation,
          child: baseBuilder(
            context,
            info.value.value,
            animation,
          ),
        );
    listKey.currentState!.removeItem(
      info.value.index,
      itemBuilder,
      duration: widget.removalDuration,
    );
  }

  @override
  void didUpdateWidget(SortedAnimatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateController(widget.controller);
  }

  @override
  void initState() {
    super.initState();
    _updateController(widget.controller);
  }

  void _updateController(SortedAnimatedListController<T> newController) {
    if (controller != newController) {
      _connections.dispose();
    }
    controller = newController;
    _connections = IDisposable.merge([
      newController.didInsertItem.map((e) => e.value).tap(_onInsertItem),
      newController.didRemoveItem.tap(_onRemoveItem),
    ]);
  }

  @override
  void dispose() {
    _connections.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => controller!.values.build(
        builder: (context, values, _) => AnimatedList(
          key: listKey,
          itemBuilder: (context, i, animation) => widget.itemBuilder(
            context,
            values[i],
            animation,
          ),
          initialItemCount: values.length,
          scrollDirection: widget.scrollDirection,
          reverse: widget.reverse,
          controller: widget.scrollController,
          primary: widget.primary,
          physics: widget.physics,
          shrinkWrap: widget.shrinkWrap,
          padding: widget.padding,
          clipBehavior: widget.clipBehavior,
        ),
      );
}

class _ItemDiscardNotifier extends StatefulWidget {
  _ItemDiscardNotifier({
    required this.onDiscard,
    required this.animation,
    required this.child,
  }) : super(key: ObjectKey(animation));
  final VoidCallback onDiscard;
  final Animation<Object?> animation;
  final Widget child;

  @override
  __ItemDiscardNotifier createState() => __ItemDiscardNotifier();
}

class __ItemDiscardNotifier extends State<_ItemDiscardNotifier> {
  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  bool didDiscard = false;
  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || didDiscard) {
      return;
    }
    didDiscard = true;
    widget.onDiscard();
  }

  @override
  void didUpdateWidget(_ItemDiscardNotifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      throw StateError('invalid state');
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    if (!didDiscard) {
      widget.onDiscard();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
