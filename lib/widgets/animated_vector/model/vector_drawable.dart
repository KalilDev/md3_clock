import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

import '../parsing/util.dart';
import '../parsing/vector_drawable.dart';
import 'resource.dart';

// TODO: pt, mm, in
enum DimensionKind { dip, dp, px, sp }

class Dimension {
  final double value;
  final DimensionKind kind;

  Dimension(this.value, this.kind);
}

class VectorDrawable extends Resource {
  final Vector body;

  VectorDrawable(this.body, ResourceReference? source) : super(source);
  static VectorDrawable parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseVectorDrawable(document, source);
  static VectorDrawable parseElement(XmlElement element) =>
      parseVectorDrawable(element, null);
}

// https://developer.android.com/reference/android/graphics/drawable/VectorDrawable
abstract class VectorDrawableNode {
  final String? name;
  VectorDrawableNode({
    this.name,
  });
}

abstract class VectorPart extends VectorDrawableNode {
  VectorPart({required String? name}) : super(name: name);
}

class Vector extends VectorDrawableNode {
  final Dimension width;
  final Dimension height;
  final double viewportWidth;
  final double viewportHeight;
  final Color? tint;
  final BlendMode tintMode;
  final bool autoMirrored;
  final double opacity;
  final List<VectorPart> children;

  Vector({
    required String? name,
    required this.width,
    required this.height,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.tint,
    this.tintMode = BlendMode.srcIn,
    this.autoMirrored = false,
    this.opacity = 1.0,
    required this.children,
  }) : super(name: name);

  Iterable<StyleColor> _expandColorsFromVectorPart(VectorPart part) =>
      part is Group
          ? part.children.expand(_expandColorsFromVectorPart)
          : part is Path
              ? [
                  if (part.strokeColor?.styleColor != null)
                    part.strokeColor!.styleColor!,
                  if (part.fillColor?.styleColor != null)
                    part.fillColor!.styleColor!,
                ]
              : [];

  late final Set<StyleColor> usedColors =
      (children.expand(_expandColorsFromVectorPart)).toSet();
}

class PathData {
  PathData.fromString(String asString) : _asString = asString;
  PathData.fromSegments(Iterable<PathSegmentData> segments)
      : _segments = segments.toList();
  String? _asString;
  List<PathSegmentData>? _segments;
  static List<PathSegmentData> _parse(String asString) {
    final SvgPathStringSource parser = SvgPathStringSource(asString);
    try {
      return parser.parseSegments().toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  static String _toString(List<PathSegmentData> segments) {
    final result = StringBuffer();
    throw UnimplementedError('TODO');
    return result.toString();
  }

  UnmodifiableListView<PathSegmentData> get segments =>
      UnmodifiableListView(_segments ??= _parse(_asString!));

  String get asString => _asString ??= _toString(segments);
}

class Group extends VectorPart {
  final double? rotation;
  final double? pivotX;
  final double? pivotY;
  final double? scaleX;
  final double? scaleY;
  final double? translateX;
  final double? translateY;
  final List<VectorPart> children;

  Group({
    required String? name,
    required this.rotation,
    required this.pivotX,
    required this.pivotY,
    required this.scaleX,
    required this.scaleY,
    required this.translateX,
    required this.translateY,
    required this.children,
  }) : super(name: name);
}

class ColorOrStyleColor {
  final Color? color;
  final StyleColor? styleColor;

  ColorOrStyleColor.styleColor(this.styleColor) : color = null;
  ColorOrStyleColor.color(this.color) : styleColor = null;
  factory ColorOrStyleColor.parse(String colorOrThemeColor) {
    if (colorOrThemeColor.startsWith('#')) {
      return ColorOrStyleColor.color(parseHexColor(colorOrThemeColor));
    } else if (colorOrThemeColor.startsWith('?')) {
      return ColorOrStyleColor.styleColor(
          StyleColor.fromString(colorOrThemeColor));
    } else {
      throw UnimplementedError();
    }
  }
}

class StyleColor {
  final String namespace;
  final String name;

  const StyleColor(this.namespace, this.name);
  factory StyleColor.fromString(String themeColor) {
    if (!themeColor.startsWith('?')) {
      throw StateError('');
    }
    final split = themeColor.split(':');
    if (split.length != 2 && split.length != 1) {
      throw StateError('');
    }
    return StyleColor(split.length == 1 ? '' : split[0].substring(1),
        split.length == 1 ? split[0].substring(1) : split[1]);
  }
  int get hashCode => Object.hashAll([namespace, name]);
  bool operator ==(other) =>
      other is StyleColor && other.namespace == namespace && other.name == name;
}

enum FillType { nonZero, evenOdd }
enum StrokeLineCap {
  butt,
  round,
  square,
}
enum StrokeLineJoin {
  miter,
  round,
  bevel,
}

class Path extends VectorPart {
  final PathData pathData;
  final ColorOrStyleColor? fillColor;
  final ColorOrStyleColor? strokeColor;
  final double strokeWidth;
  final double strokeAlpha;
  final double fillAlpha;
  final double trimPathStart;
  final double trimPathEnd;
  final double trimPathOffset;
  final StrokeLineCap strokeLineCap;
  final StrokeLineJoin strokeLineJoin;
  final double strokeMiterLimit;
  final FillType fillType;

  Path({
    required String? name,
    required this.pathData,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 0,
    this.strokeAlpha = 1,
    this.fillAlpha = 1,
    this.trimPathStart = 0,
    this.trimPathEnd = 1,
    this.trimPathOffset = 0,
    this.strokeLineCap = StrokeLineCap.butt,
    this.strokeLineJoin = StrokeLineJoin.miter,
    this.strokeMiterLimit = 4,
    this.fillType = FillType.nonZero,
  }) : super(name: name);
}
