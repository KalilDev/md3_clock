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
    print('init timers view');
    final initialPage = widget.controller.currentPageValue!;
    _pageController = PageController(
      initialPage: widget.controller.currentPageValue!,
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

class _TimerSectionPage extends StatelessWidget {
  const _TimerSectionPage({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TimerSectionController controller;

  Widget _title(BuildContext context) => Text(
        'Marcador',
        style: context.textTheme.titleLarge
            .copyWith(color: context.colorScheme.onSurfaceVariant),
      );
  static const _kBottomPadding = 16.0;
  static const _kHorizontalPadding = 24.0;
  @override
  Widget build(BuildContext context) => FabSafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: _kBottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: SizedBox.expand(
                child: _title(context),
              )),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kHorizontalPadding,
                  ),
                  child: _ClockRing(
                    controller: controller,
                    child: _TimerSectionBody(
                      controller: controller,
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

class _TimerSectionBody extends StatelessWidget {
  const _TimerSectionBody({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TimerSectionController controller;

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
  Widget build(BuildContext context) => Stack(
        children: [
          Center(
            child: _buildDurationWrapper(
              context,
              child: controller.remainingTimerDuration.build(
                builder: (context, duration, _) => DurationWidget(
                  duration: duration,
                  numberStyle: context.textTheme.displayLarge,
                  separatorStyle: context.textTheme.displayMedium,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8 + 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _button(
                  context,
                  ButtonStyle(
                    fixedSize:
                        MaterialStateProperty.all(const Size.fromHeight(32)),
                    textStyle: MaterialStateProperty.all(
                      context.textTheme.labelMedium
                          .copyWith(fontWeight: FontWeight.w400),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      );

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
        child: TimeKeypad(
            controller: controller.addSectionController.keypadController),
      );
  Widget _buildTimersView(BuildContext context) =>
      _TimersView(controller: controller);

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
