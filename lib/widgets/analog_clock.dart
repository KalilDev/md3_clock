import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';

class AnalogClock extends StatelessWidget {
  const AnalogClock({
    Key? key,
    required this.time,
    this.seconds,
  })  : assert(seconds == null || seconds >= 0 && seconds < 60),
        super(key: key);
  final TimeOfDay time;
  final int? seconds;

  @override
  Widget build(BuildContext context) {
    final secondsFrac = (seconds ?? 0) / 60;
    var minutesFrac = time.minute / 60;
    minutesFrac += secondsFrac / 60;
    var hoursFrac = time.hour / 12;
    hoursFrac += minutesFrac / 60;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _AnalogClockPainter(
          ringColor: context.colorScheme.onSurface,
          hoursColor: context.colorScheme.primary,
          minutesColor: context.colorScheme.primary,
          secondsColor: context.colorScheme.secondary,
          hoursFrac: hoursFrac,
          minutesFrac: minutesFrac,
          secondsFrac: seconds == null ? null : secondsFrac,
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final Color ringColor;
  final Color hoursColor;
  final Color minutesColor;
  final Color secondsColor;
  final double hoursFrac;
  final double minutesFrac;
  final double? secondsFrac;

  _AnalogClockPainter({
    required this.ringColor,
    required this.hoursColor,
    required this.minutesColor,
    required this.secondsColor,
    required this.hoursFrac,
    required this.minutesFrac,
    required this.secondsFrac,
  });

  static const _kRingThicknessFrac = 1 / 40;
  static const _kHoursThicknessFrac = 1 / 65;
  static const _kMinutesThicknessFrac = 1 / 68;
  static const _kSecondsThicknessFrac = 1 / 114;

  static const _kHoursSmallFrac = 1 / 18;
  static const _kMinutesSmallFrac = 1 / 18;
  static const _kSecondsSmallFrac = 1 / 7;

  static const _kHoursLargeFrac = 1 / 5;
  static const _kMinutesLargeFrac = 2 / 5;
  static const _kSecondsLargeFrac = 2 / 5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final measure = size.width;
    {
      // ring
      final strokeWidth = _kRingThicknessFrac * measure;
      final paint = Paint()
        ..strokeWidth = strokeWidth
        ..color = ringColor
        ..style = PaintingStyle.stroke;
      canvas.drawOval((Offset.zero & size).deflate(strokeWidth / 2), paint);
    }
    {
      // hours
      final paint = Paint()
        ..strokeWidth = _kHoursThicknessFrac * measure
        ..color = hoursColor
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawLine(
        canvas,
        center,
        hoursFrac,
        _kHoursLargeFrac * measure,
        _kHoursSmallFrac * measure,
        paint,
      );
    }
    {
      // minutes
      final paint = Paint()
        ..strokeWidth = _kMinutesThicknessFrac * measure
        ..color = minutesColor
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawLine(
        canvas,
        center,
        minutesFrac,
        _kMinutesLargeFrac * measure,
        _kMinutesSmallFrac * measure,
        paint,
      );
    }
    if (secondsFrac != null) {
      // seconds
      final paint = Paint()
        ..strokeWidth = _kSecondsThicknessFrac * measure
        ..color = secondsColor
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawLine(
        canvas,
        center,
        secondsFrac!,
        _kSecondsLargeFrac * measure,
        _kSecondsSmallFrac * measure,
        paint,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Offset center,
    double frac,
    double largeSize,
    double smallSize,
    Paint paint,
  ) {
    final theta = -(frac * 2 * pi) + pi;
    final rotatedUnit = Offset(sin(theta), cos(theta));
    final start = center + (rotatedUnit * largeSize);
    final end = center - (rotatedUnit * smallSize);
    canvas.drawLine(start, end, paint);
  }

  // TODO
  @override
  bool shouldRepaint(_AnalogClockPainter oldDelegate) => true;
}
