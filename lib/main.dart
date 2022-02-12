import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/navigation_manager/controller.dart';
import 'package:md3_clock/components/navigation_manager/widget.dart';
import 'package:md3_clock/pages/home/home.dart';
import 'package:md3_clock/utils/utils.dart';
import 'package:value_notifier/value_notifier.dart';
import 'package:value_notifier/src/frame.dart';
import 'pages/preferences/controller.dart';
import 'pages/preferences/widget.dart';
import 'typography/typography.dart';
import 'utils/theme.dart';

void main() {
  runPlatformThemedApp(
    const MyApp(),
    initialOrFallback: () => const PlatformPalette.fallback(
      primaryColor: Color(0xDEADBEEF),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static Widget _preferencesRouteBuilder(BuildContext context) =>
      PreferencesPage(
        controller: InheritedController.of(context),
      );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final monetTheme = (palette.source != PaletteSource.platform || kDebugMode)
        ? ClockTheme.baseline
        : ClockTheme.fromPlatform(palette);
    const themeMode = kDebugMode ? ThemeMode.dark : ThemeMode.system;
    return InheritedControllerInjector(
      factory: (_) => PreferencesController(),
      child: ControllerInjectorBuilder<NavigationManagerController>(
        inherited: true,
        factory: (_) => NavigationManagerController(),
        builder: (context, controller) => NavigationManager(
          navigatorKey: navigatorKey,
          controller: controller,
          child: MD3Themes(
            targetPlatform: TargetPlatform.android,
            monetThemeForFallbackPalette: monetTheme,
            textTheme: MD3ClockTypography.instance.adaptativeTextTheme,
            usePlatformPalette: false,
            builder: (context, light, dark) => MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Relógio',
              theme: light,
              darkTheme: dark,
              themeMode: themeMode,
              debugShowCheckedModeBanner: false,
              routes: const {'/preferences': _preferencesRouteBuilder},
              home: const _DesktopOverlays(
                child: ClockHomePage(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopOverlays extends StatelessWidget {
  const _DesktopOverlays({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  static const _kDesktopPlatforms = {
    TargetPlatform.macOS,
    TargetPlatform.linux,
    TargetPlatform.windows,
    TargetPlatform.fuchsia,
  };

  static const _kAppbarHeight = 28.0;
  static const _kBottomBarHeight = 46.0;

  @override
  Widget build(BuildContext context) {
    if (!_kDesktopPlatforms.contains(Theme.of(context).platform)) {
      return child;
    }
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final padding = mediaQuery.viewPadding +
        EdgeInsets.only(
          top: _kAppbarHeight,
          bottom: isPortrait ? _kBottomBarHeight : 0,
        );
    // TODO: should be handled by scaffold?
    var size = mediaQuery.size;
    if (!isPortrait) {
      size = Size(size.width - _kBottomBarHeight, size.height);
    }
    return Stack(
      children: [
        Positioned.fill(
          // TODO: should be handled by scaffold?
          right: isPortrait ? 0 : _kBottomBarHeight,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              viewPadding: padding,
              padding: padding,
              viewInsets: padding,
              systemGestureInsets: padding,
              size: size,
            ),
            child: child,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: isPortrait ? 0 : _kBottomBarHeight,
          height: _kAppbarHeight,
          child: Material(
            type: MaterialType.transparency,
            child: _StatusBar(),
          ),
        ),
        Positioned(
          bottom: 0,
          left: isPortrait ? 0 : null,
          top: isPortrait ? null : 0,
          right: 0,
          height: isPortrait ? _kBottomBarHeight : null,
          width: isPortrait ? null : _kBottomBarHeight,
          child: Material(
            type: MaterialType.transparency,
            child: _BottomNavbar(
              isVertical: !isPortrait,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({Key? key}) : super(key: key);

  Widget _leftIcons(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '15:50',
            style: TextStyle(fontSize: 12, height: 1),
          ),
          const SizedBox(width: 16),
          ...<Widget>[
            Icon(Icons.play_arrow),
            Icon(Icons.message),
            Text(
              '•',
              style: TextStyle(fontSize: 12, height: 1),
            ),
          ].interleaved((_) => const SizedBox(width: 8))
        ],
      );
  Widget _rightIcons(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ...<Widget>[
            Icon(Icons.alarm),
            Icon(Icons.wifi),
            Icon(Icons.network_cell),
            Icon(
              Icons.battery_alert,
              color: context.colorScheme.error,
            ),
          ].interleaved((_) => const SizedBox(width: 8)),
          Text(
            '5%',
            style: TextStyle(fontSize: 12, height: 1),
          ),
        ],
      );
  Widget _buildMainRow(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _leftIcons(context),
          Spacer(),
          _rightIcons(context),
        ],
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: IconTheme(
          data: IconThemeData(
            color: context.colorScheme.onSurface,
            opacity: 1,
            size: 12,
          ),
          child: _buildMainRow(context),
        ),
      );
}

class _BottomNavbar extends StatelessWidget {
  const _BottomNavbar({
    Key? key,
    required this.isVertical,
  }) : super(key: key);

  final bool isVertical;

  static const _kIconHeight = 10.0;

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.white;
    final children = [
      Icon(Icons.chevron_left),
      Material(
        elevation: 0,
        shape: StadiumBorder(),
        color: iconColor.withOpacity(0.8),
        child: SizedBox(
          width: 28,
          height: _kIconHeight,
        ),
      ),
      Icon(null),
    ];
    return Container(
      color: Colors.black,
      child: IconTheme(
        data: const IconThemeData(
          color: iconColor,
          opacity: 0.8,
          size: 12,
        ),
        child: isVertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
                verticalDirection: VerticalDirection.up,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
              ),
      ),
    );
  }
}
