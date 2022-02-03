// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:md3_clock/utils/utils.dart';

import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';

class RawPrototypeText extends LeafRenderObjectWidget {
  RawPrototypeText({
    Key? key,
    required this.reference,
    required this.target,
    this.textStyle,
    this.initialCharacterSet,
    this.characterAlignment = 0.0,
    this.textDirection,
    this.textScaleFactor = 1.0,
    this.locale,
    this.strutStyle,
    this.textHeightBehavior,
  })  : assert(textScaleFactor != null),
        assert(reference.length == target.length),
        super(key: key);
  final String reference;
  final String target;
  final TextStyle? textStyle;
  final Set<String>? initialCharacterSet;
  final double characterAlignment;
  final TextDirection? textDirection;
  final double textScaleFactor;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final ui.TextHeightBehavior? textHeightBehavior;

  @override
  _RenderPrototypeText createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    return _RenderPrototypeText(
      reference: reference,
      target: target,
      textStyle: textStyle,
      initialCharacterSet: initialCharacterSet,
      characterAlignment: characterAlignment,
      textDirection: textDirection ?? Directionality.of(context),
      textScaleFactor: textScaleFactor,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
      locale: locale ?? Localizations.maybeLocaleOf(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderPrototypeText renderObject) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    renderObject
      ..reference = reference
      ..target = target
      ..textStyle = textStyle
      ..characterAlignment = characterAlignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..textScaleFactor = textScaleFactor
      ..strutStyle = strutStyle
      ..textHeightBehavior = textHeightBehavior
      ..locale = locale ?? Localizations.maybeLocaleOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('reference', reference));
    properties.add(StringProperty('target', target));
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle));
    properties.add(DoubleProperty('characterAlignment', characterAlignment,
        defaultValue: 0.0));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(DiagnosticsProperty<StrutStyle>('strutStyle', strutStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextHeightBehavior>(
        'textHeightBehavior', textHeightBehavior,
        defaultValue: null));
  }
}

/// A render object that displays a line text that has each character sized
/// according to another text.
class _RenderPrototypeText extends RenderBox
    with RelayoutWhenSystemFontsChangeMixin {
  double _characterAlignment;
  String _reference;
  String _target;
  final Map<String, TextPainter> _characterPainters = {};
  final Set<String> _characterSet = {};
  _RenderPrototypeText({
    required double characterAlignment,
    required String reference,
    required String target,
    required TextStyle? textStyle,
    required TextDirection textDirection,
    required double textScaleFactor,
    required Locale? locale,
    required StrutStyle? strutStyle,
    required ui.TextHeightBehavior? textHeightBehavior,
    required Set<String>? initialCharacterSet,
  })  : _characterAlignment = characterAlignment,
        _reference = reference,
        _target = target,
        _textStyle = textStyle,
        _updateReferencePainter = TextPainter(
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          locale: locale,
          strutStyle: strutStyle,
          textHeightBehavior: textHeightBehavior,
        ) {
    Set<String> toBeInitialCharacterSet = {
      if (initialCharacterSet != null) ...initialCharacterSet,
      for (var i = 0; i < target.length; i++) target[i],
      for (var i = 0; i < reference.length; i++) reference[i],
    };
    _addToCharacterSet(toBeInitialCharacterSet);
  }

  TextStyle? _textStyle;
  TextStyle? get textStyle => _textStyle;
  set textStyle(TextStyle? value) {
    if (_textStyle == value) {
      return;
    }
    _textStyle = value;
    _forEachPainter((p) => p.text = p.text == null
        ? null
        : TextSpan(style: value, text: (p.text as TextSpan).text));

    markNeedsLayout();
  }

  double get characterAlignment => _characterAlignment;
  set characterAlignment(double value) {
    if (_characterAlignment == value) {
      return;
    }
    _characterAlignment = value;
    markNeedsPaint();
  }

  set reference(String reference) {
    if (_reference == reference) {
      return;
    }
    _reference = reference;

    final toBeAddedToCharSet = <String>[];
    for (var i = 0; i < reference.length; i++) {
      final char = reference[i];
      if (_characterSet.contains(char)) {
        continue;
      }
      toBeAddedToCharSet.add(char);
    }

    _addToCharacterSet(toBeAddedToCharSet);
    markNeedsLayout();
  }

  set target(String target) {
    if (_target == target) {
      return;
    }
    _target = target;

    final toBeAddedToCharSet = <String>[];
    for (var i = 0; i < target.length; i++) {
      final char = target[i];
      if (_characterSet.contains(char)) {
        continue;
      }
      toBeAddedToCharSet.add(char);
    }

    if (_addToCharacterSet(toBeAddedToCharSet)) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  TextDirection get textDirection => _updateReferencePainter.textDirection!;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_updateReferencePainter.textDirection == value) return;
    _forEachPainter((p) => p.textDirection = value);
    markNeedsLayout();
  }

  double get textScaleFactor => _updateReferencePainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_updateReferencePainter.textScaleFactor == value) return;
    _forEachPainter((p) => p.textScaleFactor = value);
    markNeedsLayout();
  }

  Locale? get locale => _updateReferencePainter.locale;

  /// The value may be null.
  set locale(Locale? value) {
    if (_updateReferencePainter.locale == value) return;
    _forEachPainter((p) => p.locale = value);
    markNeedsLayout();
  }

  StrutStyle? get strutStyle => _updateReferencePainter.strutStyle;

  /// The value may be null.
  set strutStyle(StrutStyle? value) {
    if (_updateReferencePainter.strutStyle == value) return;
    _forEachPainter((p) => p.strutStyle = value);
    markNeedsLayout();
  }

  /// {@macro dart.ui.textHeightBehavior}
  ui.TextHeightBehavior? get textHeightBehavior =>
      _updateReferencePainter.textHeightBehavior;
  set textHeightBehavior(ui.TextHeightBehavior? value) {
    if (_updateReferencePainter.textHeightBehavior == value) return;
    _forEachPainter((p) => p.textHeightBehavior = value);
    markNeedsLayout();
  }

  TextPainter _updateReferencePainter;

  void _layoutPainters() {
    _forEachPainter((p) => p.layout());
  }

  void _forEachReferenceUniquePainter(void Function(TextPainter) fn) {
    Set<String> _visited = {};
    for (var i = 0; i < _reference.length; i++) {
      final char = _reference[i];
      if (_visited.contains(char)) {
        continue;
      }
      _visited.add(char);
      fn(_characterPainters[char]!);
    }
  }

  void _forEachReferencePainter(void Function(TextPainter) fn) {
    for (var i = 0; i < _reference.length; i++) {
      final char = _reference[i];
      fn(_characterPainters[char]!);
    }
  }

  void _forEachPainter(void Function(TextPainter) fn) {
    fn(_updateReferencePainter);
    _characterPainters.values.forEach(fn);
  }

  TextPainter _textPainterForChar(String char) => TextPainter(
      text: TextSpan(text: char, style: _textStyle),
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
      locale: locale,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior);

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final Paint paint = Paint()..color = debugCurrentRepaintColor.toColor();
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());

    _paintText(offset, context.canvas);
  }

  void _paintText(Offset offset, Canvas canvas) {
    // foreach [sizeReferenceChar, targetChar] in zip(reference, target)
    for (var i = 0; i < _target.length; i++) {
      final sizeReferenceChar = _reference[i];
      final targetChar = _target[i];

      final targetCharacterPainter = _characterPainters[targetChar]!;
      final targetWidth = targetCharacterPainter.width;
      if (sizeReferenceChar == targetChar) {
        // Easy path, just paint the target character
        targetCharacterPainter.paint(canvas, offset);
        if (debugPaintSizeEnabled) {
          canvas.drawRect(
            offset & targetCharacterPainter.size,
            Paint()
              ..color = Color(0xff0000ff)
              ..style = PaintingStyle.stroke,
          );
        }
        offset += ui.Offset(targetWidth, 0);
        continue;
      }

      final referenceCharacterPainter = _characterPainters[sizeReferenceChar]!;
      final referenceWidth = referenceCharacterPainter.width;

      final dx = referenceWidth - targetWidth;
      final halfDx = dx / 2;
      final alignDt = characterAlignment * halfDx;
      final paintingStartOffset = offset.translate(halfDx + alignDt, 0);
      targetCharacterPainter.paint(canvas, paintingStartOffset);
      if (debugPaintSizeEnabled) {
        canvas.drawRect(
          offset & referenceCharacterPainter.size,
          Paint()
            ..color = Color(0xff00ff00)
            ..style = PaintingStyle.stroke,
        );
        canvas.drawRect(
          paintingStartOffset & targetCharacterPainter.size,
          Paint()
            ..color = Color(0xffff0000)
            ..style = PaintingStyle.stroke,
        );
      }
      offset += ui.Offset(referenceWidth, 0);
    }
  }

  bool _addToCharacterSet(Iterable<String> toBeAdded) {
    if (toBeAdded.isEmpty) {
      return false;
    }

    _characterSet.addAll(toBeAdded);
    _updateReferencePainter.text = TextSpan(
      text: _characterSet.join('\n'),
      style: _textStyle,
    );
    for (final added in toBeAdded) {
      if (!_characterPainters.containsKey(added)) {
        _characterPainters[added] = _textPainterForChar(added);
      }
    }

    return true;
  }

  @override
  void performLayout() {
    _layoutPainters();
    var width = 0.0, height = 0.0;
    // foreach sizeReferenceChar in reference
    for (var i = 0; i < _reference.length; i++) {
      final sizeReferenceChar = _reference[i];

      final referenceCharacterPainter = _characterPainters[sizeReferenceChar]!;
      final referenceWidth = referenceCharacterPainter.width;
      final referenceHeight = referenceCharacterPainter.height;
      width += referenceWidth;
      height = math.max(height, referenceHeight);
    }
    size = constraints.constrain(Size(width, height));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutPainters();
    double minIntrinsic = 0;
    _forEachReferencePainter((p) => minIntrinsic += p.minIntrinsicWidth);
    return minIntrinsic;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutPainters();
    double maxIntrinsic = 0;
    _forEachReferencePainter((p) => maxIntrinsic += p.maxIntrinsicWidth);
    return maxIntrinsic;
  }

  double _computeIntrinsicHeight(double width) {
    _layoutPainters();
    double height = 0;
    _forEachReferencePainter((p) => height = math.max(height, p.height));
    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    // TODO: better than only checking the first painter
    final painter = _characterPainters[_reference[0]]!;
    painter.layout();
    // TODO(garyq): Since our metric for ideographic baseline is currently
    // inaccurate and the non-alphabetic baselines are based off of the
    // alphabetic baseline, we use the alphabetic for now to produce correct
    // layouts. We should eventually change this back to pass the `baseline`
    // property when the ideographic baseline is properly implemented
    // (https://github.com/flutter/flutter/issues/22625).
    return painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // TODO: Hit test text spans.
    /*
    final TextPosition textPosition =
        _textPainter.getPositionForOffset(position);
    final InlineSpan? span =
        _textPainter.text!.getSpanForPosition(textPosition);
    if (span != null && span is HitTestTarget) {
      result.add(HitTestEntry(span as HitTestTarget));
      return true;
    }*/
    return false;
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    markNeedsLayout();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
    properties.add(
      DoubleProperty(
        'textScaleFactor',
        textScaleFactor,
        defaultValue: 1.0,
      ),
    );
    properties.add(
      DiagnosticsProperty<Locale>(
        'locale',
        locale,
        defaultValue: null,
      ),
    );
  }
}
