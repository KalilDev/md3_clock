import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/vector_drawable.dart';

class ActivatableAnimatedVectorIcon extends StatefulWidget {
  const ActivatableAnimatedVectorIcon({
    Key? key,
    required this.icon,
    this.color,
    this.opacity,
    this.style,
    this.isActive = false,
    this.reverse = false,
  }) : super(key: key);
  final AnimatedVector icon;
  final Color? color;
  final double? opacity;
  final StyleResolver? style;
  final bool isActive;
  final bool reverse;

  @override
  _ActivatableAnimatedVectorIconState createState() =>
      _ActivatableAnimatedVectorIconState();
}

class _ActivatableAnimatedVectorIconState
    extends State<ActivatableAnimatedVectorIcon> {
  final GlobalKey<AnimatedVectorState> vectorKey = GlobalKey();

  @override
  void didUpdateWidget(ActivatableAnimatedVectorIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowActive = widget.isActive;
    if (oldWidget.isActive == isNowActive) {
      return;
    }
    final state = vectorKey.currentState!;
    if (isNowActive) {
      state.start(forward: !widget.reverse, fromStart: true);
    } else {
      // TODO: reverse?
      state.stop(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedVectorIcon(
        vectorKey: vectorKey,
        icon: widget.icon,
        color: widget.color,
        opacity: widget.opacity,
        style: widget.style,
      );
}

class VectorIcon extends StatelessWidget {
  const VectorIcon({
    Key? key,
    required this.icon,
    this.color,
    this.opacity,
    this.style,
  }) : super(key: key);
  final Vector icon;
  final Color? color;
  final double? opacity;
  final StyleResolver? style;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context).copyWith(
      color: color,
      opacity: opacity,
    );
    final mapping = _IconThemeStyleResolver(iconTheme, style);
    return VectorWidget(
      vector: icon,
      styleMapping: mapping,
    );
  }
}

class AnimatedVectorIcon extends StatelessWidget {
  const AnimatedVectorIcon({
    Key? key,
    required this.icon,
    this.vectorKey,
    this.color,
    this.opacity,
    this.style,
  }) : super(key: key);
  final AnimatedVector icon;
  final GlobalKey<AnimatedVectorState>? vectorKey;
  final Color? color;
  final double? opacity;
  final StyleResolver? style;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context).copyWith(
      color: color,
      opacity: opacity,
    );
    final mapping = _IconThemeStyleResolver(iconTheme, style);
    return AnimatedVectorWidget(
      animatedVector: icon,
      key: vectorKey,
      styleMapping: mapping,
    );
  }
}

class _IconThemeStyleResolver extends StyleMapping with Diagnosticable {
  final IconThemeData iconTheme;
  final StyleResolver? style;
  _IconThemeStyleResolver(this.iconTheme, this.style);

  static final _kProperties = {
    const StyleProperty('', 'iconOpacity'),
    const StyleProperty('', 'iconColor'),
  };

  @override
  bool containsAny(Iterable<StyleProperty> props) =>
      props.any(_kProperties.contains) || (style?.containsAny(props) ?? false);

  @override
  T? resolve<T>(StyleProperty property) {
    if (property.namespace.isNotEmpty) {
      return style?.resolve<T>(property);
    }
    switch (property.name) {
      case 'iconColor':
        return iconTheme.color as T?;
      case 'iconOpacity':
        return iconTheme.opacity as T?;
      default:
        return style?.resolve<T>(property);
    }
  }

  @override
  bool contains(StyleProperty prop) =>
      _kProperties.contains(prop) || (style?.containsAny([prop]) ?? false);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('iconTheme', iconTheme));
    properties.add(DiagnosticsProperty('style', style));
  }
}
