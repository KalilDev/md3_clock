import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/pages/home/home.dart';
import 'package:value_notifier/value_notifier.dart';
import 'package:value_notifier/src/frame.dart';

void main() {
  runPlatformThemedApp(
    const MyApp(),
    initialOrFallback: () => const PlatformPalette.fallback(
      primaryColor: Color(0xDEADBEEF),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MD3Themes(
      targetPlatform: TargetPlatform.android,
      monetThemeForFallbackPalette: MonetTheme.baseline3p,
      builder: (context, light, dark) => MaterialApp(
        title: 'Relógio',
        theme: light,
        darkTheme: dark,
        debugShowCheckedModeBanner: false,
        home: const ClockHomePage(),
      ),
    );
  }
}
