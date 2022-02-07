import 'package:material_widgets/material_widgets.dart';
import
// Conditionals are not working as specified on
// https://spec.dart.dev/DartLangSpecDraft.pdf#subsection.19.7
// uncomment if it starts working as expected!
    /*'fallback.dart'
    if (md3_clock_typography.custom_typography)*/
    'package:md3_clock_typography/md3_clock_typography.dart'
    show md3ClockTypography;

class MD3ClockTextTheme {
  const MD3ClockTextTheme({
    required this.largeTimeDisplay,
    required this.mediumTimeDisplay,
    required this.currentTimeDisplay,
    required this.stopwatchDisplay,
    required this.stopwatchMilisDisplay,
  });
  final MD3TextStyle largeTimeDisplay;
  final MD3TextStyle mediumTimeDisplay;
  final MD3TextStyle currentTimeDisplay;
  final MD3TextStyle stopwatchDisplay;
  final MD3TextStyle stopwatchMilisDisplay;
}

class MD3ClockTypography {
  const MD3ClockTypography({
    required this.adaptativeTextTheme,
    required this.clockTextTheme,
  });
  final MD3TextAdaptativeTheme adaptativeTextTheme;
  final MD3ClockTextTheme clockTextTheme;
  static const MD3ClockTypography instance = md3ClockTypography;
}
