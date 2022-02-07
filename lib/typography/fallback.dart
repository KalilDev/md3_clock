import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';

import 'typography.dart';

const MD3ClockTypography md3ClockTypography = MD3ClockTypography(
  clockTextTheme: MD3ClockTextTheme(
    largeTimeDisplay: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 70, height: 79),
      ),
    ),
    mediumTimeDisplay: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 52, height: 52),
      ),
    ),
    currentTimeDisplay: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 70, height: 114),
      ),
    ),
    stopwatchDisplay: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 70, height: 90),
      ),
    ),
    stopwatchMilisDisplay: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 57, height: 72),
      ),
    ),
  ),
  adaptativeTextTheme: MD3TextAdaptativeTheme(
    displayLarge: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 57, height: 64),
      ),
    ),
    displayMedium: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 45, height: 52),
      ),
    ),
    displaySmall: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 36, height: 44),
      ),
    ),
    headlineLarge: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 32, height: 40),
      ),
    ),
    headlineMedium: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 28, height: 36),
      ),
    ),
    headlineSmall: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 24, height: 32),
      ),
    ),
    titleLarge: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 22, height: 28),
      ),
    ),
    titleMedium: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 16, height: 24),
      ),
    ),
    titleSmall: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 14, height: 20),
      ),
    ),
    labelLarge: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 14, height: 20),
      ),
    ),
    labelMedium: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 12, height: 16),
      ),
    ),
    labelSmall: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 11, height: 6),
      ),
    ),
    bodyLarge: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 16, height: 24),
      ),
    ),
    bodyMedium: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 14, height: 20),
      ),
    ),
    bodySmall: MD3TextStyle(
      base: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      scale: MD3TextAdaptativeScale.single(
        MD3TextAdaptativeProperties(size: 12, height: 16),
      ),
    ),
  ),
);
