import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:material_widgets/src/md3_appBar/controller.dart';
import 'package:value_notifier/value_notifier.dart';

bool useLargeFab(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.portrait;
bool useVerticalFab(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.landscape;

class ClockNavigationDelegate extends MD3NavigationDelegate {
  final PreferredSizeWidget appBar;
  final Widget floatingActionButton;

  ClockNavigationDelegate({
    required this.floatingActionButton,
    required this.appBar,
  });

  static const kBodyMinimumMargin = MD3SizeClassProperty<double?>.every(
    compact: 16,
    medium: 16,
    expanded: 16,
  );
  static const kBodyMaximumMargin = MD3SizeClassProperty<double?>.every(
    compact: 16,
    medium: 16,
    expanded: 16,
  );
  MD3AdaptativeScaffoldSpec _build(
    BuildContext context,
    MD3NavigationSpec spec,
    Widget body,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTiny = MediaQuery.of(context).size.shortestSide < 360;
    final useSmallAppBars = isTiny && isLandscape;
    final bottomNavigationBar = Builder(
      builder: (context) => MD3AppBarScope.of(context)
          .isScrolledUnder
          .buildView(
            builder: (context, isScrolledUnder, child) => NavigationBarTheme(
              data: NavigationBarTheme.of(context).copyWith(
                labelBehavior: useSmallAppBars
                    ? NavigationDestinationLabelBehavior.alwaysHide
                    : null,
                height: useSmallAppBars ? 52 : 79,
                backgroundColor: MD3ElevationTintableColor(
                  context.colorScheme.surface,
                  MD3ElevationLevel.surfaceTint(context.colorScheme),
                  MD3MaterialStateElevation.resolveWith(
                    (states) => states.contains(MaterialState.scrolledUnder)
                        ? context.elevation.level2
                        : context.elevation.level1,
                  ),
                ).resolve({
                  if (isScrolledUnder) MaterialState.scrolledUnder,
                }),
              ),
              child: child!,
            ),
            child: buildNavigationBar(spec),
          ),
    );
    if (isLandscape) {
      return MD3AdaptativeScaffoldSpec(
        appBar: useSmallAppBars ? null : appBar,
        bottomNavigationBar: bottomNavigationBar,
        body: MD3ScaffoldBody.noMargin(
          minimumMargin: kBodyMinimumMargin,
          maximumMargin: kBodyMaximumMargin,
          child: SafeArea(
            child: _HomePageLandscapeLayout(
              floatingActionButton: floatingActionButton,
              child: body,
            ),
          ),
        ),
      );
    }
    return MD3AdaptativeScaffoldSpec(
      appBar: useSmallAppBars ? null : appBar,
      floatingActionButton: floatingActionButton,
      properties: const MD3ScaffoldProperties(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: MD3ScaffoldBody(
        minimumMargin: kBodyMinimumMargin,
        maximumMargin: kBodyMaximumMargin,
        child: SafeArea(child: body),
      ),
    );
  }

  @override
  MD3AdaptativeScaffoldSpec buildCompact(
    BuildContext context,
    MD3NavigationSpec spec,
    Widget body,
  ) =>
      _build(context, spec, body);

  @override
  MD3AdaptativeScaffoldSpec buildExpanded(
    BuildContext context,
    MD3NavigationSpec spec,
    Widget body,
  ) =>
      _build(context, spec, body);

  @override
  MD3AdaptativeScaffoldSpec buildMedium(
    BuildContext context,
    MD3NavigationSpec spec,
    Widget body,
  ) =>
      _build(context, spec, body);
}

class _HomePageLandscapeLayout extends StatelessWidget {
  const _HomePageLandscapeLayout({
    Key? key,
    required this.floatingActionButton,
    required this.child,
  }) : super(key: key);
  final Widget floatingActionButton;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final oneFourth = size.width / 4;
          const double spacing = 80;
          const double fabSize = 56;
          const double maxSize = spacing + fabSize + spacing;
          const double minSizeWithEndSpacing = fabSize + spacing;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: InheritedMD3BodyMargin.of(context).padding,
                  child: child,
                ),
              ),
              SizedBox(
                width: oneFourth,
                child: Center(child: floatingActionButton),
              )
            ],
          );
        },
      );
}
