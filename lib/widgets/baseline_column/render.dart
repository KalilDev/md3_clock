// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

bool? _startIsTopLeft(Axis direction, TextDirection? textDirection,
    VerticalDirection? verticalDirection) {
  assert(direction != null);
  // If the relevant value of textDirection or verticalDirection is null, this returns null too.
  switch (direction) {
    case Axis.horizontal:
      switch (textDirection) {
        case TextDirection.ltr:
          return true;
        case TextDirection.rtl:
          return false;
        case null:
          return null;
      }
    case Axis.vertical:
      switch (verticalDirection) {
        case VerticalDirection.down:
          return true;
        case VerticalDirection.up:
          return false;
        case null:
          return null;
      }
  }
}

/// Parent data for use with [RenderBaselineColumn].
class ColumnParentData extends ContainerBoxParentData<RenderBox> {
  @override
  String toString() => '${super.toString()};';
}

typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

/// Displays its children in a vertical one-dimensional array with each children
/// touching the baseline of the previous one.
///
/// ## Layout algorithm
///
/// TODO: document
///
/// _See [BoxConstraints] for an introduction to box layout models._
class RenderBaselineColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ColumnParentData>,
        DebugOverflowIndicatorMixin {
  /// Creates a baseline column render object.
  ///
  /// By default, children are aligned to the center of the cross axis.
  RenderBaselineColumn({
    List<RenderBox>? children,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    required TextBaseline textBaseline,
    Clip clipBehavior = Clip.none,
  })  : assert(crossAxisAlignment != null),
        assert(clipBehavior != null),
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _verticalDirection = verticalDirection,
        _textBaseline = textBaseline,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  /// How the children should be placed along the cross axis.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    assert(value != null);
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// This controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] must not be null.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// This controls which order children
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  /// Which baseline to use when aligning the children.
  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(crossAxisAlignment != null);
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      assert(verticalDirection != null,
          'Vertical $runtimeType with multiple children has a null verticalDirection, so the layout order is undefined.');
    }
    assert(verticalDirection != null,
        'Vertical $runtimeType with MainAxisAlignment.baseline has a null verticalDirection, so the alignment cannot be resolved.');

    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      assert(textDirection != null,
          'Vertical $runtimeType with $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0;
  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ColumnParentData)
      child.parentData = ColumnParentData();
  }

  bool get _canComputeIntrinsics =>
      crossAxisAlignment != CrossAxisAlignment.baseline;

  double _getIntrinsicSize({
    required double
        height, // the extent in the direction that isn't the sizing direction
    required _ChildSizingFunction
        childSize, // a method to find the size in the sizing direction
  }) {
    if (!_canComputeIntrinsics) {
      // Intrinsics cannot be calculated without a full layout for
      // baseline alignment. Throw an assertion and return 0.0 as documented
      // on [RenderBox.computeMinIntrinsicWidth].
      assert(
        RenderObject.debugCheckingIntrinsics,
        'Intrinsics are not available for CrossAxisAlignment.baseline.',
      );
      return 0.0;
    }
    // INTRINSIC CROSS SIZE
    // Intrinsic cross size is the max of the intrinsic cross sizes of the
    // children, after the flexible children are fit into the available space,
    // with the children sized using their max intrinsic dimensions.

    // Get inflexible space using the max intrinsic dimensions of fixed children in the main direction.
    final double availableMainSpace = height;
    double inflexibleSpace = 0.0;
    double maxCrossSize = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      final double mainSize = child.getMaxIntrinsicHeight(double.infinity);
      final double crossSize = childSize(child, mainSize);

      inflexibleSpace += mainSize;
      maxCrossSize = math.max(maxCrossSize, crossSize);
      final ColumnParentData childParentData =
          child.parentData! as ColumnParentData;
      child = childParentData.nextSibling;
    }

    return maxCrossSize;
  }

  /// Throws an exception saying that the object does not support returning
  /// intrinsic dimensions if, in debug mode, we are not in the
  /// [RenderObject.debugCheckingIntrinsics] mode.
  ///
  /// This is used by [computeMinIntrinsicWidth] et al because viewports do not
  /// generally support returning intrinsic dimensions. See the discussion at
  /// [computeMinIntrinsicWidth].
  @protected
  bool debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        assert(this is! RenderShrinkWrappingViewport); // it has its own message
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              '$runtimeType does not support returning intrinsic dimensions.'),
          ErrorDescription(
            'Calculating the intrinsic dimensions would require instantiating every child of '
            'the viewport, which defeats the point of viewports being lazy.',
          ),
          ErrorHint(
            'If you are merely trying to shrink-wrap the viewport in the main axis direction, '
            'consider a RenderShrinkWrappingViewport render object (ShrinkWrappingViewport widget), '
            'which achieves that effect without implementing the intrinsic dimension API.',
          ),
        ]);
      }
      return true;
    }());
    return true;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      height: height,
      childSize: (RenderBox child, double extent) =>
          child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      height: height,
      childSize: (RenderBox child, double extent) =>
          child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  double _getCrossSize(Size size) {
    return size.width;
  }

  double _getMainSize(Size size) {
    return size.height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
      reason:
          'Dry layout cannot be computed for MainAxisAlignment.baseline, which requires a full layout.',
    ));
    return Size.zero;
  }

  _LayoutSizes _computeSizes(
      {required BoxConstraints constraints,
      required BaselineChildLayouter layoutChild}) {
    assert(_debugHasNecessaryDirections);
    assert(constraints != null);

    // flipMainAxis is used to decide whether to lay out left-to-right/top-to-bottom (false), or
    // right-to-left/bottom-to-top (true). The _startIsTopLeft will return null if there's only
    // one child and the relevant direction is null, in which case we arbitrarily decide not to
    // flip, but that doesn't have any detectable effect.
    final bool flipMainAxis =
        !(_startIsTopLeft(Axis.vertical, textDirection, verticalDirection) ??
            true);

    bool isFirst = true;
    double baselineDelta = 0.0;

    double crossSize = 0.0;
    double allocatedSize =
        0.0; // Sum of the sizes of the non-flexible children.
    RenderBox? child = firstChild;

    while (child != null) {
      final ColumnParentData childParentData =
          child.parentData! as ColumnParentData;
      final BoxConstraints innerConstraints;
      if (crossAxisAlignment == CrossAxisAlignment.stretch) {
        innerConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
      } else {
        innerConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
      }
      final childLayoutInfo =
          layoutChild(child, innerConstraints, textBaseline);
      final Size childSize = childLayoutInfo.size;
      final childHeight = _getMainSize(childSize);
      if (flipMainAxis && !isFirst) {
        // Inform the current child baseline delta so that it can be removed for
        // itself.
        baselineDelta = childHeight - childLayoutInfo.baseline;
      }
      // Remove the diff between the height of the previous child baseline and
      // height.
      allocatedSize -= baselineDelta;
      // Add the current child height
      allocatedSize += childHeight;
      if (!flipMainAxis) {
        // Inform the current child baseline delta so that it can be removed for
        // the next children.
        baselineDelta = childHeight - childLayoutInfo.baseline;
      }
      crossSize = math.max(crossSize, _getCrossSize(childSize));
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
      isFirst = false;
    }

    return _LayoutSizes(
      crossSize: crossSize,
      allocatedSize: allocatedSize,
    );
  }

  static _ChildLayoutInfo _layoutChild(
    RenderBox child,
    BoxConstraints constraints,
    TextBaseline textBaseline,
  ) {
    child.layout(constraints, parentUsesSize: true);
    return _ChildLayoutInfo(
      child.size,
      child.getDistanceToBaseline(textBaseline)!,
    );
  }

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);
    final BoxConstraints constraints = this.constraints;

    final _LayoutSizes sizes = _computeSizes(
      layoutChild: _layoutChild,
      constraints: constraints,
    );

    final double allocatedSize = sizes.allocatedSize;
    double crossSize = sizes.crossSize;
    double actualSize = allocatedSize;

    // Align items along the main axis under the previous baseline.

    size = constraints.constrain(Size(crossSize, actualSize));
    actualSize = size.height;
    crossSize = size.width;
    final double actualSizeDelta = actualSize - allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);
    final double remainingSpace = math.max(0.0, actualSizeDelta);
    final double leadingSpace = 0.0;
    // flipMainAxis is used to decide whether to lay out left-to-right/top-to-bottom (false), or
    // right-to-left/bottom-to-top (true). The _startIsTopLeft will return null if there's only
    // one child and the relevant direction is null, in which case we arbitrarily decide not to
    // flip, but that doesn't have any detectable effect.
    final bool flipMainAxis =
        !(_startIsTopLeft(Axis.vertical, textDirection, verticalDirection) ??
            true);

    // Position elements
    bool isFirst = true;
    double childMainPosition =
        flipMainAxis ? actualSize - leadingSpace : leadingSpace;
    RenderBox? child = firstChild;
    while (child != null) {
      final ColumnParentData childParentData =
          child.parentData! as ColumnParentData;

      // Position in the cross axis
      final double childCrossPosition;
      switch (_crossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition = _startIsTopLeft(flipAxis(Axis.vertical),
                      textDirection, verticalDirection) ==
                  (_crossAxisAlignment == CrossAxisAlignment.start)
              ? 0.0
              : crossSize - _getCrossSize(child.size);
          break;
        case CrossAxisAlignment.center:
          childCrossPosition =
              crossSize / 2.0 - _getCrossSize(child.size) / 2.0;
          break;
        case CrossAxisAlignment.stretch:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.baseline:
          childCrossPosition = 0.0;
          break;
      }
      // position in the main axis
      final mainSize = _getMainSize(child.size);
      final mainBaselineDistance = child.getDistanceToBaseline(textBaseline)!;
      final mainBaselineDelta = mainSize - mainBaselineDistance;
      if (flipMainAxis) {
        childMainPosition -= mainSize;
        childMainPosition -= isFirst ? 0.0 : -mainBaselineDelta;
      }

      childParentData.offset = Offset(childCrossPosition, childMainPosition);

      if (flipMainAxis) {
        //childMainPosition -= betweenSpace;
      } else {
        childMainPosition += mainBaselineDistance;
      }

      isFirst = false;
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) return;

    if (clipBehavior == Clip.none) {
      _clipRectLayer.layer = null;
      defaultPaint(context, offset);
    } else {
      // We have overflow and the clipBehavior isn't none. Clip it.
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        defaultPaint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    }

    assert(() {
      // Only set this if it's null to save work. It gets reset to null if the
      // _direction changes.
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
          'The overflowing $runtimeType has an orientation of ${Axis.vertical}.',
        ),
        ErrorDescription(
          'The edge of the $runtimeType that is overflowing has been marked '
          'in the rendering with a yellow and black striped pattern. This is '
          'usually caused by the contents being too big for the $runtimeType.',
        ),
        ErrorHint(
          'Consider applying a flex factor (e.g. using an Expanded widget) to '
          'force the children of the $runtimeType to fit within the available '
          'space instead of being sized to their natural size.',
        ),
        ErrorHint(
          'This is considered an error condition because it indicates that there '
          'is content that cannot be seen. If the content is legitimately bigger '
          'than the available space, consider clipping it with a ClipRect widget '
          'before putting it in the flex, or using a scrollable container rather '
          'than a Flex, like a ListView.',
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      final Rect overflowChildRect;

      overflowChildRect = Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
      paintOverflowIndicator(
          context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (!kReleaseMode) {
      if (_hasOverflow) header += ' OVERFLOWING';
    }
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', Axis.vertical));
    properties.add(EnumProperty<CrossAxisAlignment>(
        'crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>(
        'verticalDirection', verticalDirection,
        defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline,
        defaultValue: null));
  }
}

typedef BaselineChildLayouter = _ChildLayoutInfo Function(
  RenderBox child,
  BoxConstraints constraints,
  TextBaseline textBaseline,
);

class _ChildLayoutInfo {
  final Size size;
  final double baseline;

  _ChildLayoutInfo(this.size, this.baseline);
}

class _LayoutSizes {
  const _LayoutSizes({
    required this.crossSize,
    required this.allocatedSize,
  });

  final double crossSize;
  final double allocatedSize;
}
