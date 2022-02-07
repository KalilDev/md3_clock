import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/fab_group/controller.dart';
import 'package:md3_clock/components/fab_group/widget.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/typography/typography.dart';
import 'package:md3_clock/utils/layout.dart';
import 'package:md3_clock/widgets/switcher.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../components/keypad/widget.dart';
import '../../model/duration_components.dart';
import '../../utils/chrono.dart';
import '../../widgets/blinking.dart';
import '../../widgets/clock_ring.dart';
import '../../widgets/duration.dart';
import '../../widgets/fab_safe_area.dart';
import 'controller.dart';

class _TimersView extends StatefulWidget {
  const _TimersView({Key? key, required this.controller}) : super(key: key);
  final TimerPageController controller;

  @override
  __TimersViewState createState() => __TimersViewState();
}

class __TimersViewState extends State<_TimersView> {
  late final PageController _pageController;
  late final IDisposable _connections;
  void initState() {
    super.initState();
    final initialPage = widget.controller.currentPage.value ?? 0;
    _pageController = PageController(
      initialPage: initialPage,
    );
    _connections = IDisposable.merge([
      widget.controller.didMoveToSection.tap(_onJumpToSection),
      _pageController.listen(_onPageController),
    ]);
  }

  void dispose() {
    IDisposable.disposeAll([
      _connections,
      _pageController,
    ]);
    super.dispose();
  }

  void _onJumpToSection(int section) {
    _pageController.jumpTo(section.toDouble());
  }

  void _onPageController() {
    final page = _pageController.page!.round();
    widget.controller.onPageChange(page);
  }

  Widget _buildTimer(BuildContext cotext, TimerSectionController timer) =>
      _TimerSectionPage(
        controller: timer,
      );
  @override
  Widget build(BuildContext context) => widget.controller.timers.buildView(
      builder: (context, timers, _) => PageView.builder(
            controller: _pageController,
            itemBuilder: (context, i) => _buildTimer(context, timers[i]),
            itemCount: timers.length,
            scrollDirection: Axis.vertical,
            pageSnapping: true,
          ));
}

class _TimerSectionTitle extends StatelessWidget {
  const _TimerSectionTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: InkWell(
            onTap: () => print('TODO'),
            child: SizedBox(
              height: kMinInteractiveDimension,
              child: Text(
                'Marcador',
                style: context.textTheme.headlineSmall.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
}

class _TimerSectionPage extends StatelessWidget {
  const _TimerSectionPage({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TimerSectionController controller;

  static const _kBottomPadding = 16.0;
  static const _kHorizontalPadding = 24.0;

  Widget _buildLandscape(BuildContext context) {
    final tinyLayout = isTiny(context);
    final adaptativeTextStyle =
        MD3ClockTypography.instance.clockTextTheme.largeTimeDisplay;
    final textStyle = adaptativeTextStyle.resolveTo(context.deviceType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TimerSectionTitle(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (tinyLayout)
                _TimerResetOrAddMinuteButton(
                  controller: controller,
                  style: ButtonStyle(
                    textStyle: MaterialStateProperty.all(
                      context.textTheme.labelLarge,
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: tinyLayout
                      ? _TimerDurationText(
                          controller: controller,
                        )
                      : _TimerClockRingBody(
                          controller: controller,
                          style: textStyle,
                        ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPortrait(BuildContext context) {
    final adaptativeTextStyle =
        MD3ClockTypography.instance.clockTextTheme.largeTimeDisplay;
    final textStyle = adaptativeTextStyle.resolveTo(context.deviceType);
    return FabSafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: _kBottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: SizedBox.expand(
                child: _TimerSectionTitle(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _kHorizontalPadding,
                ),
                child: SizedBox(
                  width: 360,
                  child: _TimerClockRingBody(
                    controller: controller,
                    style: textStyle,
                  ),
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait
          ? _buildPortrait(context)
          : _buildLandscape(context);
}

class _TimerResetOrAddMinuteButton extends StatelessWidget {
  const _TimerResetOrAddMinuteButton({
    Key? key,
    required this.controller,
    this.style,
  }) : super(key: key);
  final TimerSectionController controller;
  final ButtonStyle? style;

  Widget _button(BuildContext context, ButtonStyle style) =>
      controller.state.buildView(builder: (context, state, _) {
        switch (state) {
          case TimerSectionState.paused:
            return TextButton(
              onPressed: controller.onReset,
              style: style,
              child: Text('Zerar'),
            );
          case TimerSectionState.beeping:
          case TimerSectionState.running:
            return TextButton(
              onPressed: controller.onAddMinute,
              style: style,
              child: Text('+ 1:00'),
            );
          default:
            return SizedBox();
        }
      });

  @override
  Widget build(BuildContext context) => _button(
        context,
        (style ?? const ButtonStyle()).merge(
          ButtonStyle(
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: 24,
              ),
            ),
          ),
        ),
      );
}

class _ClockRingChildLayout extends StatelessWidget {
  const _ClockRingChildLayout({
    Key? key,
    required this.button,
    required this.durationText,
  }) : super(key: key);
  final Widget button;
  final Widget durationText;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Center(
            child: durationText,
          ),
          Positioned(
            // 56/*targetHeight*/ -4/*padding outside*/ -10 /*stroke width*/
            bottom: 42,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [button],
            ),
          )
        ],
      );
}

class _TimerDurationText extends StatelessWidget {
  const _TimerDurationText({
    Key? key,
    required this.controller,
    this.style,
  }) : super(key: key);

  final TimerSectionController controller;
  final TextStyle? style;

  DefaultTextStyle _buildDurationWrapper(
    BuildContext context, {
    required Widget child,
  }) =>
      DefaultTextStyle(
        style: context.textTheme.displayLarge.copyWith(
          color: context.colorScheme.onSurface,
        ),
        child: BlinkingTextStyle(
          canBlink: controller.state
              .map((state) => state == TimerSectionState.paused),
          child: child,
        ),
      );
  @override
  Widget build(BuildContext context) => _buildDurationWrapper(
        context,
        child: controller.remainingTimerDuration.build(
          builder: (context, duration, _) => DurationWidget(
            duration: duration,
            numberStyle: style,
          ),
        ),
      );
}

class _TimerClockRingBody extends StatelessWidget {
  const _TimerClockRingBody({
    Key? key,
    required this.controller,
    this.style,
  }) : super(key: key);

  final TimerSectionController controller;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(4.0),
        child: _ClockRing(
          controller: controller,
          child: _ClockRingChildLayout(
            button: _TimerResetOrAddMinuteButton(
              controller: controller,
              style: ButtonStyle(
                fixedSize: MaterialStateProperty.all(const Size.fromHeight(42)),
                textStyle: MaterialStateProperty.all(
                  context.textTheme.labelMedium,
                ),
              ),
            ),
            durationText: _TimerDurationText(
              controller: controller,
              style: style,
            ),
          ),
        ),
      );
}

class _ClockRing extends StatelessWidget {
  const _ClockRing({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  final TimerSectionController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => BlinkingWidgetBuilder(
        canBlink:
            controller.state.map((state) => state == TimerSectionState.beeping),
        child: child,
        builder: (context, isVisible, child) =>
            controller.elapsedDurationFrac.buildView(
          builder: (context, frac, child) => ClockRing(
            fraction: 1.0 - frac.clamp(0.0, 0.9999),
            trackColor: isVisible
                ? null
                : MaterialStateProperty.all(Colors.transparent),
            animationDuration: Duration.zero,
            child: child!,
          ),
          child: child!,
        ),
      );
}

class TimerPage extends StatelessWidget {
  const TimerPage({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final TimerPageController controller;

  Widget _buildAddPage(BuildContext context) => FabSafeArea(
        key: const ObjectKey(true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TimeKeypadAndVisor(
            controller: controller.addSectionController.keypadController,
            isLandscape:
                MediaQuery.of(context).orientation == Orientation.landscape,
          ),
        ),
      );
  Widget _buildTimersView(BuildContext context) => _TimersView(
        key: const ObjectKey(false),
        controller: controller,
      );

  @override
  Widget build(BuildContext context) => controller.showAddPage.buildView(
        builder: (context, showAddPage, _) => SharedAxisSwitcher(
          child:
              showAddPage ? _buildAddPage(context) : _buildTimersView(context),
        ),
      );
}

class TimerPageFab extends StatelessWidget {
  const TimerPageFab({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final TimerPageController controller;

  @override
  Widget build(BuildContext context) => FABGroup(
        controller: controller.fabGroupController,
        leftIcon: Icon(Icons.delete_outline),
        rightIcon: Icon(Icons.add),
      );
}
