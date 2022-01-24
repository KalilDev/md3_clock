import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:monet_theme/monet_theme.dart';

int _androidToTone(int android) => 100 - (android ~/ 10);
int _toneToAndroid(int tone) => 1000 - (tone * 10);
TonalPalette _commonTonalPaletteFromAndroidPalette(Map<int, int> map) {
  final tones = TonalPalette.commonTones.map((e) {
    final mappedIndex = _toneToAndroid(e);
    return map[mappedIndex] ?? missing.value;
  }).toList();
  final tonalPalette = TonalPalette.fromList(tones);
  for (final androidTone in map.keys) {
    final result = tonalPalette.get(_androidToTone(androidTone));
    final expected = map[androidTone]!;
    assert(result == expected);
  }
  return tonalPalette;
}

const missing = Colors.orange;

abstract class ClockTheme {
  static final raw_error = _commonTonalPaletteFromAndroidPalette(
    {
      0: 0xffffffff,
      200: 0xfff2b8b5,
      600: 0xffb3261e,
      800: 0xff601410,
    },
  );
  static final raw_primary = _commonTonalPaletteFromAndroidPalette(
    {
      0: 0xffffffff,
      100: 0xffd3e3fd,
      200: 0xffa8c7fa,
      300: 0xff7cacf8,
      600: 0xff0b57d0,
      700: 0xff0842a0,
      800: 0xff062e6f,
      900: 0xff041e49,
    },
  );
  static final raw_secondary = _commonTonalPaletteFromAndroidPalette(
    {
      0: 0xffffffff,
      100: 0xffc2e7ff,
      200: 0xff7fcfff,
      300: 0xff5ab3f0,
      600: 0xff00639b,
      700: 0xff004a77,
      800: 0xff003355,
      900: 0xff001d35,
    },
  );
  static final raw_tertiary = _commonTonalPaletteFromAndroidPalette(
    {
      100: 0xffc4eed0,
      900: 0xff072711,
    },
  );
  static final raw_neutralVariant = _commonTonalPaletteFromAndroidPalette(
    {
      100: 0xffe1e3e1,
      200: 0xffc4c7c5,
      400: 0xff8e918f,
      500: 0xff747775,
      700: 0xff444746,
    },
  );
  static final raw_neutral = _commonTonalPaletteFromAndroidPalette(
    {
      0: 0xffffffff,
      10: 0xfffdfcfb,
      100: 0xffe3e3e3,
      200: 0xffc7c7c7,
      50: 0xfff2f2f2,
      500: 0xff757575,
      800: 0xff303030,
      900: 0xff1f1f1f,
    },
  );
  static final RawMonetTheme raw_baseline = generateRawThemeFrom(
    null,
    primary: raw_primary,
    secondary: raw_secondary,
    tertiary: raw_tertiary,
    neutral: raw_neutral,
    neutralVariant: raw_neutralVariant,
    error: raw_error,
  );

  // Uses some tones differently than the baseline MD3 theme!
  static MonetTheme fromPlatform(PlatformPalette platformPalette) {
    final theme = generateTheme(platformPalette.primaryColor);
    return theme.override(
      dark: (scheme) => scheme.copyWith(
        onInverseSurface: theme.neutral[_androidToTone(800)],
        onPrimaryContainer: theme.primary[_androidToTone(900)],
        onSecondaryContainer: theme.secondary[_androidToTone(900)],
        onTertiaryContainer: theme.tertiary[_androidToTone(900)],
        primaryContainer: theme.primary[_androidToTone(100)],
        surfaceVariant: theme.neutralVariant[_androidToTone(700)],
        secondaryContainer: theme.secondary[_androidToTone(300)],
        tertiaryContainer: theme.tertiary[_androidToTone(100)],
        outline: theme.neutralVariant[_androidToTone(400)],
      ),
      light: (scheme) => scheme.copyWith(
        background: theme.neutral[_androidToTone(0)],
        surface: theme.neutral[_androidToTone(0)],
        tertiaryContainer: theme.tertiary[_androidToTone(100)],
        onSurfaceVariant: theme.neutralVariant[_androidToTone(700)],
      ),
    );
  }

  // Uses some tones differently than the baseline MD3 theme and there is some
  // state mutation bug preventing [RawMonetTheme] generation from working
  // properly with outline and onSurfaceVariant.
  // TODO: fix this.
  static final MonetTheme baseline = MonetTheme.fromRaw(raw_baseline).override(
    dark: (scheme) => scheme.copyWith(
      onInverseSurface: Color(raw_neutral.get(_androidToTone(800))),
      onPrimaryContainer: Color(raw_primary.get(_androidToTone(900))),
      onSecondaryContainer: Color(raw_secondary.get(_androidToTone(900))),
      onTertiaryContainer: Color(raw_tertiary.get(_androidToTone(900))),
      primaryContainer: Color(raw_primary.get(_androidToTone(100))),
      surfaceVariant: Color(raw_neutralVariant.get(_androidToTone(700))),
      secondaryContainer: Color(raw_secondary.get(_androidToTone(300))),
      tertiaryContainer: Color(raw_tertiary.get(_androidToTone(100))),
      outline: Color(raw_neutralVariant.get(_androidToTone(400))),
    ),
    light: (scheme) => scheme.copyWith(
      background: Color(raw_neutral.get(_androidToTone(0))),
      surface: Color(raw_neutral.get(_androidToTone(0))),
      tertiaryContainer: Color(raw_tertiary.get(_androidToTone(100))),
      onSurfaceVariant: Color(raw_neutralVariant.get(_androidToTone(700))),
    ),
  );
}
