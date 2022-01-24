import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';

class _ClockRingColors {
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color activeThumbColor;
  final Color inactiveThumbColor;

  _ClockRingColors(
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.activeThumbColor,
    this.inactiveThumbColor,
  );
  static _ClockRingColors lerp(
    _ClockRingColors? a,
    _ClockRingColors? b,
    double t,
  ) {
    if (a == null) {
      return b!;
    }
    if (b == null) {
      return a;
    }
    return _ClockRingColors(
      Color.lerp(a.activeTrackColor, b.activeTrackColor, t)!,
      Color.lerp(a.inactiveTrackColor, b.inactiveTrackColor, t)!,
      Color.lerp(a.activeThumbColor, b.activeThumbColor, t)!,
      Color.lerp(a.inactiveThumbColor, b.inactiveThumbColor, t)!,
    );
  }
}

class _ClockRingColorsTween extends Tween<_ClockRingColors> {
  _ClockRingColorsTween({
    _ClockRingColors? begin,
    _ClockRingColors? end,
  }) : super(
          begin: begin,
          end: end,
        );
  @override
  _ClockRingColors transform(double t) =>
      _ClockRingColors.lerp(begin!, end!, t);
}

class ClockRing extends StatelessWidget {
  const ClockRing({
    Key? key,
    this.trackColor,
    this.markColor,
    required this.fraction,
    this.markFraction,
    this.animationDuration = kThemeChangeDuration,
    this.child,
  }) : super(key: key);
  final MaterialStateProperty<Color?>? trackColor;
  final MaterialStateProperty<Color?>? markColor;
  final double? fraction;
  final double? markFraction;
  final Duration animationDuration;
  final Widget? child;

  static MaterialStateProperty<Color> defaultTrackColor(
          MonetColorScheme scheme) =>
      MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return scheme.primary;
        }
        return scheme.surfaceVariant;
      });

  static MaterialStateProperty<Color> defaultMarkColor(
          MonetColorScheme scheme) =>
      MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return scheme.onPrimary;
        }
        return scheme.onSurfaceVariant;
      });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final defaultTrackColor = ClockRing.defaultTrackColor(scheme);
    final defaultMarkColor = ClockRing.defaultMarkColor(scheme);
    final effectiveTrackColor = this.trackColor == null
        ? defaultTrackColor
        : MaterialStateProperty.resolveWith((states) =>
            this.trackColor!.resolve(states) ??
            defaultTrackColor.resolve(states));
    final effectiveMarkColor = this.markColor == null
        ? defaultMarkColor
        : MaterialStateProperty.resolveWith((states) =>
            this.markColor!.resolve(states) ??
            defaultMarkColor.resolve(states));
    const active = {MaterialState.selected};
    const inactive = <MaterialState>{};
    final colors = _ClockRingColors(
      effectiveTrackColor.resolve(active),
      effectiveTrackColor.resolve(inactive),
      effectiveMarkColor.resolve(active),
      effectiveMarkColor.resolve(inactive),
    );
    return AspectRatio(
      aspectRatio: 1,
      child: TweenAnimationBuilder<_ClockRingColors>(
        duration: animationDuration,
        tween: _ClockRingColorsTween(end: colors),
        builder: (context, colors, child) => DecoratedBox(
          decoration: _TimerFracDecoration(
            fraction: fraction == double.nan ? null : fraction,
            markFraction: markFraction == double.nan ? null : markFraction,
            colors: colors,
          ),
          child: child,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(_TimerFracDecorationPainter.kStrokeWidth),
          child: child,
        ),
      ),
    );
  }
}

class _TimerFracDecoration extends Decoration {
  final double? fraction;
  final double? markFraction;
  final _ClockRingColors colors;

  _TimerFracDecoration({
    required this.fraction,
    required this.markFraction,
    required this.colors,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TimerFracDecorationPainter(fraction, markFraction, colors);
}

class _TimerFracDecorationPainter extends BoxPainter {
  final double? fraction;
  final double? markFraction;
  final _ClockRingColors colors;

  _TimerFracDecorationPainter(
    this.fraction,
    this.markFraction,
    this.colors,
  );

  static const kStrokeWidth = 8.0;
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    const start = -pi / 2;
    final normalFrac = fraction == null ? null : fraction!.clamp(0.0, 1.0);
    final normalMarkFrac = markFraction == null ? null : markFraction! % 1.0;

    // one degree
    final markAngle = pi / 180;
    final trackPaint = Paint()
      ..strokeWidth = kStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final markPaint = Paint()
      ..strokeWidth = kStrokeWidth
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final rect = (offset & configuration.size!).deflate(kStrokeWidth / 2);
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      trackPaint..color = colors.inactiveTrackColor,
    );
    if (markFraction != null) {
      canvas.drawArc(
        rect,
        start + (2 * pi * markFraction!),
        markAngle,
        false,
        markPaint..color = colors.inactiveThumbColor,
      );
    }
    if (fraction != null) {
      canvas.drawArc(
        rect,
        start,
        (2 * pi * fraction!),
        false,
        trackPaint..color = colors.activeTrackColor,
      );
    }
    if (markFraction != null &&
        fraction != null &&
        normalMarkFrac! <= normalFrac!) {
      canvas.drawArc(
        rect,
        start + (2 * pi * markFraction!),
        markAngle,
        false,
        markPaint..color = colors.activeThumbColor,
      );
    }
  }
}
