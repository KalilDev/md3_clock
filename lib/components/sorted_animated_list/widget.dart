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

  void _onRemoveItem(IndexAndValue<T> info) {
    final builder = widget.removingItemBuilder ?? widget.itemBuilder;
    listKey.currentState!.removeItem(
      info.index,
      (context, animation) => builder(
        context,
        info.value,
        animation,
      ),
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
      newController.didRemoveItem.map((e) => e.value).tap(_onRemoveItem),
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
