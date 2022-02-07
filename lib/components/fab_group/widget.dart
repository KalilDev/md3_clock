import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/utils/theme.dart';
import 'package:md3_clock/widgets/switcher.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../pages/home/navigation_delegate.dart';
import 'controller.dart';

class _VerticalFabGroupLayout extends StatelessWidget {
  const _VerticalFabGroupLayout({
    Key? key,
    required this.left,
    required this.center,
    required this.right,
  }) : super(key: key);
  final Widget left;
  final Widget center;
  final Widget right;

  Widget _buildLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final spacingHeight = constraints.maxHeight / 8;
    final spacing = SizedBox(height: spacingHeight);
    final children = [left, spacing, center, spacing, right];
    return Column(
      children: children,
      verticalDirection: VerticalDirection.up,
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);
}

class _HorizontalFabGroupLayout extends StatelessWidget {
  const _HorizontalFabGroupLayout({
    Key? key,
    required this.left,
    required this.center,
    required this.right,
    required this.isStarted,
  }) : super(key: key);
  final Widget left;
  final Widget center;
  final Widget right;
  final ValueListenable<bool> isStarted;

  Widget _spacing(
    BuildContext context,
    double spacing,
    double startedSpacing,
  ) =>
      isStarted.buildView(
        builder: (context, isStarted, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: isStarted ? startedSpacing : spacing),
          duration: kFabAnimationDuration,
          builder: (context, spacerWidth, _) => SizedBox.square(
            dimension: spacerWidth,
          ),
        ),
      );

  Widget _buildLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final spacing = constraints.maxWidth / 8;
    final startedSpacing = constraints.maxWidth / 10;

    final children = [
      left,
      _spacing(context, spacing, startedSpacing),
      center,
      _spacing(context, spacing, startedSpacing),
      right,
    ];
    return Row(
      children: children,
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);
}

class FABGroup extends StatelessWidget {
  const FABGroup({
    Key? key,
    required this.controller,
    required this.leftIcon,
    required this.rightIcon,
  }) : super(key: key);
  final FABGroupController controller;
  final Widget leftIcon;
  final Widget rightIcon;

  static const double kMaxHorizontalLayoutLargeWidth = 56 + 48 + 152 + 48 + 56;
  static const double kMaxHorizontalLayoutSmallWidth = 40 + 48 + 72 + 48 + 40;
  static const double kMaxVerticalLayoutLargeWidth = 152;
  static const double kMaxVerticalLayoutSmallWidth = 72;

  Widget _centerFab(BuildContext context) => controller.centerState.buildView(
        builder: (context, state, _) => _CenterFab(
          state: state,
          onPressed: controller.onCenter,
        ),
      );

  Widget _leftFab(BuildContext context) => controller.showLeftIcon.buildView(
        builder: (context, showLeftIcon, _) => _NormalOrSmallFab(
          showPlaceholder: !showLeftIcon,
          isSmall: !useLargeFab(context),
          onPressed: controller.onLeft,
          child: leftIcon,
        ),
      );

  Widget _rightFab(BuildContext context) => controller.showRightIcon.buildView(
        builder: (context, showRightIcon, _) => _NormalOrSmallFab(
          showPlaceholder: !showRightIcon,
          isSmall: !useLargeFab(context),
          onPressed: controller.onRight,
          child: rightIcon,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final left = _leftFab(context),
        center = _centerFab(context),
        right = _rightFab(context);
    if (useVerticalFab(context)) {
      return _VerticalFabGroupLayout(
        left: left,
        center: center,
        right: right,
      );
    }
    return _HorizontalFabGroupLayout(
      left: left,
      center: center,
      right: right,
      isStarted: controller.centerState.map(const {
        CenterFABState.pause,
        CenterFABState.stop,
      }.contains),
    );
  }
}

const kFabAnimationDuration = Duration(milliseconds: 400);

class _NormalOrSmallFab extends StatelessWidget {
  const _NormalOrSmallFab({
    Key? key,
    required this.showPlaceholder,
    required this.isSmall,
    required this.onPressed,
    required this.child,
  }) : super(key: key);
  final bool showPlaceholder;
  final bool isSmall;
  final VoidCallback onPressed;
  final Widget child;

  static const _kPlaceholderKey = ObjectKey(false);
  static const _kFabKey = ObjectKey(true);

  Widget _buildFabOrPlaceholder(BuildContext context) {
    if (showPlaceholder) {
      return SizedBox.square(
        key: _kPlaceholderKey,
        dimension: isSmall ? 40 : 56,
      );
    }
    if (isSmall) {
      return MD3FloatingActionButton(
        key: _kFabKey,
        onPressed: onPressed,
        fabColorScheme: MD3FABColorScheme.tertiary,
        child: child,
      );
    }
    return MD3FloatingActionButton(
      key: _kFabKey,
      style: ButtonStyle(
        fixedSize: MaterialStateProperty.all(Size.fromHeight(72)),
      ),
      onPressed: onPressed,
      fabColorScheme: MD3FABColorScheme.tertiary,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => FadeThroughSwitcher(
        child: _buildFabOrPlaceholder(context),
      );
}

class _NormalOrLargeFab extends StatelessWidget {
  const _NormalOrLargeFab({
    Key? key,
    required this.isLarge,
    required this.onPressed,
    required this.child,
    this.style,
  }) : super(key: key);
  final bool isLarge;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLarge) {
      return MD3FloatingActionButton.large(
        onPressed: onPressed,
        colorScheme: primarySchemeOf(context),
        style: style,
        child: IconTheme.merge(
          data: const IconThemeData(size: 24),
          child: child,
        ),
      );
    }
    return MD3FloatingActionButton(
      onPressed: onPressed,
      colorScheme: primarySchemeOf(context),
      style: ButtonStyle(
        fixedSize: MaterialStateProperty.all(Size.fromHeight(72)),
      ).merge(style),
      child: child,
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({
    Key? key,
    required this.state,
    required this.onPressed,
  }) : super(key: key);
  final CenterFABState state;
  final VoidCallback onPressed;

  Widget _fabWidthAnimation(
    BuildContext context, {
    required bool isLarge,
    required bool isStarted,
    required Widget child,
  }) {
    double targetFabWidth;
    if (isLarge) {
      targetFabWidth = isStarted ? 152 : 96;
    } else {
      targetFabWidth = isStarted ? 96 : 72;
    }
    return TweenAnimationBuilder<double>(
      // Restart the tween on changing the layout
      key: ObjectKey(isLarge),
      duration: kFabAnimationDuration,
      tween: Tween(end: targetFabWidth), child: child,
      builder: (context, targetFabWidth, child) => SizedBox(
        width: targetFabWidth,
        child: child,
      ),
    );
  }

  ButtonStyle _style(bool isStarted, bool isLarge) => ButtonStyle(
        shape: MaterialStateProperty.all(
          isStarted
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLarge ? 32 : 16,
                  ),
                )
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLarge ? 48 : 36,
                  ),
                ),
        ),
      );

  Widget? _iconForState(BuildContext context) {
    switch (state) {
      case CenterFABState.play:
        return const Icon(Icons.play_arrow);
      case CenterFABState.pause:
        return const Icon(Icons.pause);
      case CenterFABState.stop:
        return const Icon(Icons.stop);
      case CenterFABState.hidden:
        throw StateError('Unreachable');
    }
  }

  Widget _buildFab(BuildContext context) {
    final isLarge = useLargeFab(context);
    if (state == CenterFABState.hidden) {
      return SizedBox.square(
        key: const ObjectKey(false),
        dimension: isLarge ? 96 : 72,
      );
    }

    return KeyedSubtree(
      key: const ObjectKey(true),
      child: _fabWidthAnimation(
        context,
        isLarge: isLarge,
        isStarted: state != CenterFABState.play,
        child: _NormalOrLargeFab(
          isLarge: isLarge,
          onPressed: onPressed,
          style: _style(state != CenterFABState.play, isLarge),
          child: _iconForState(context)!,
        ),
      ),
    );
  }

  Widget build(BuildContext context) => FadeThroughSwitcher(
        child: _buildFab(context),
      );
}
