import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/fab_group/controller.dart';
import 'package:md3_clock/components/fab_group/widget.dart';
import 'package:md3_clock/model/duration_components.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/widgets/blinking.dart';
import 'package:md3_clock/widgets/clock_ring.dart';
import 'package:md3_clock/widgets/duration.dart';
import 'package:md3_clock/widgets/fab_safe_area.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/lap.dart';
import '../../utils/chrono.dart';
import '../stopwatch/controller.dart';

class _LapTextStyle extends StatelessWidget {
  const _LapTextStyle({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        style: context.textTheme.bodyMedium.copyWith(
          color: context.colorScheme.onSurface,
          fontWeight: FontWeight.w300,
        ),
        child: child,
      );
}

class _LapDurationText extends StatelessWidget {
  const _LapDurationText(
    this.duration, {
    Key? key,
    required this.componentWidths,
  }) : super(key: key);
  final Duration duration;
  final List<int> componentWidths;

  String _padded(int num, int width) => num.toString().padLeft(width, '0');

  static const _kSeparator = SizedBox(width: 4.0);

  List<String> _numAndSep(int num, int width) => [
        _padded(num, width),
        ' ',
      ];
  @override
  Widget build(BuildContext context) {
    final comps = DurationComponents.fromDuration(duration);
    final daysWidth = componentWidths[0],
        hoursWidth = componentWidths[1],
        minutesWidth = componentWidths[2],
        secondsWidth = componentWidths[3],
        milisWidth = componentWidths[4];
    final texts = [
      if (daysWidth != 0) ..._numAndSep(comps.days, daysWidth),
      if (hoursWidth != 0) ..._numAndSep(comps.hours, hoursWidth),
      if (minutesWidth != 0) ..._numAndSep(comps.minutes, minutesWidth),
      if (secondsWidth != 0) ..._numAndSep(comps.seconds, secondsWidth),
      if (milisWidth != 0) ...[
        ',',
        _padded(
          comps.miliseconds ~/ 10,
          milisWidth,
        ),
      ],
    ];
    return Text(texts.join());
  }
}

extension on StopwatchPageController {
  ValueListenable<int> get lapNumberWidth => currentLap
      .map((lap) => lap.number)
      .unique()
      .map((lapNum) => lapNum.toString().length)
      .unique();
  ValueListenable<UnmodifiableListView<int>> get durationComponentWidths =>
      totalElapsedTime
          .map(DurationComponents.fromDuration)
          .map((dur) => [
                // days
                dur.days == 0
                    ? 0
                    : dur.days > 9
                        ? 2
                        : 1,
                // hours
                dur.hours == 0
                    ? 0
                    : dur.hours > 9
                        ? 2
                        : 1,
                // min
                dur.minutes.toString().length,
                // sec
                2,
                // mili
                2,
                // micro
                0
              ])
          .unique(listEquals)
          .map(UnmodifiableListView.new);
  ValueListenable<_LapWidthInfo> get widthInfo => lapNumberWidth.bind(
        (lapNumberWidth) => durationComponentWidths.map(
          (durationComponentWidths) => _LapWidthInfo(
            lapNumberWidth,
            durationComponentWidths,
          ),
        ),
      );
}

class _InheritedLapWidthInfo extends InheritedWidget {
  final _LapWidthInfo widthInfo;

  const _InheritedLapWidthInfo({
    Key? key,
    required this.widthInfo,
    required Widget child,
  }) : super(
          child: child,
          key: key,
        );

  static _LapWidthInfo of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedLapWidthInfo>()!
      .widthInfo;

  @override
  bool updateShouldNotify(_InheritedLapWidthInfo oldWidget) =>
      widthInfo != oldWidget.widthInfo;
}

class _Lap extends StatelessWidget {
  const _Lap({
    Key? key,
    required this.lap,
    this.widthInfo,
  }) : super(key: key);
  final Lap lap;
  final _LapWidthInfo? widthInfo;

  static const _kDurationSepWidth = 12.0;
  static const _kLapNumberSepWidth = 4.0;

  Widget _row(
    BuildContext context,
    int lapNumberWidth,
    List<int> durationComponentWidths,
  ) {
    final lapNumberStyle = TextStyle(
      color: context.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        const Spacer(),
        Text('Nº', style: lapNumberStyle),
        const SizedBox(width: _kLapNumberSepWidth),
        Text(
          lap.number.toString().padLeft(lapNumberWidth, '0'),
          style: lapNumberStyle,
        ),
        const SizedBox(width: _kDurationSepWidth),
        _LapDurationText(
          lap.duration,
          componentWidths: durationComponentWidths,
        ),
        const SizedBox(width: _kDurationSepWidth),
        _LapDurationText(
          lap.endTime,
          componentWidths: durationComponentWidths,
        ),
        const Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = this.widthInfo ?? _InheritedLapWidthInfo.of(context);
    return _LapTextStyle(
      child: _row(
        context,
        width.lapNumberWidth,
        width.durationComponentsWidth,
      ),
    );
  }
}

class _CurrentLap extends StatelessWidget {
  const _CurrentLap({
    Key? key,
    required this.controller,
    this.widthInfo,
  }) : super(key: key);
  final StopwatchPageController controller;
  final _LapWidthInfo? widthInfo;
  @override
  Widget build(BuildContext context) => controller.currentLap.build(
        builder: (context, lap, _) => _Lap(
          lap: lap,
          widthInfo: widthInfo,
        ),
      );
}

class _LapWidthInfo {
  final int lapNumberWidth;
  final List<int> durationComponentsWidth;

  const _LapWidthInfo(this.lapNumberWidth, this.durationComponentsWidth);

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is _LapWidthInfo) {
      return true &&
          lapNumberWidth == other.lapNumberWidth &&
          listEquals(durationComponentsWidth, other.durationComponentsWidth);
    }
    return false;
  }
}

class _LapsList extends StatelessWidget {
  const _LapsList({
    Key? key,
    required this.controller,
    this.shrinkWrap = false,
  }) : super(key: key);
  final StopwatchPageController controller;
  final bool shrinkWrap;

  Widget _wrapWithInheritedWidth(
    BuildContext context, {
    required Widget child,
  }) =>
      controller.widthInfo.build(
        builder: (context, width, child) => _InheritedLapWidthInfo(
          widthInfo: width,
          child: child!,
        ),
        child: child,
      );

  Widget _list(BuildContext context) => controller.laps.build(
        builder: (context, laps, _) => ListView.builder(
          primary: false,
          padding: FabSafeArea.fabPaddingFor(context),
          shrinkWrap: shrinkWrap,
          prototypeItem: const _Lap(
            lap: Lap.zero,
            widthInfo: _LapWidthInfo(
              1,
              [2, 2, 2, 2, 2, 2],
            ),
          ),
          itemBuilder: (c, i) {
            switch (i) {
              case 0:
                return _CurrentLap(controller: controller);
              default:
                i = i - 1;
                return _Lap(lap: laps[laps.length - 1 - i]);
            }
          },
          itemCount: laps.length + 1,
        ),
      );

  @override
  Widget build(BuildContext context) => _wrapWithInheritedWidth(
        context,
        child: _list(context),
      );
}

class _LapAndLastLapFraction {
  final double? lapFraction;
  final double? lastLapFraction;

  _LapAndLastLapFraction(
    this.lapFraction,
    this.lastLapFraction,
  );

  double? get normalizedLap =>
      lapFraction == null ? null : lapFraction!.clamp(0.0, 1.0);
}

class _StopwatchDurationText extends StatelessWidget {
  const _StopwatchDurationText({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final StopwatchPageController controller;

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
        style: TextStyle(color: context.colorScheme.onSurface),
        child: BlinkingTextStyle(
          canBlink:
              controller.state.map((state) => state == StopwatchState.paused),
          child: controller.totalElapsedTime.build(
            builder: (context, duration, _) =>
                _body(context, DurationComponents.fromDuration(duration)),
          ),
        ),
      );

  Column _body(BuildContext context, DurationComponents duration) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          DurationWidget(
            duration: duration.toDuration(),
            numberStyle: context.textTheme.displayLarge,
            separatorStyle: context.textTheme.displayMedium,
            padSeconds: true,
          ),
          Text(
            (duration.miliseconds ~/ 10)
                .clamp(0, 99)
                .toString()
                .padLeft(2, '0'),
            style: context.textTheme.displayMedium,
          )
        ],
      );
}

class _ClockRing extends StatelessWidget {
  const _ClockRing({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);
  final StopwatchPageController controller;
  final Widget child;

  Widget _clockRing(
    BuildContext context, {
    required Widget child,
  }) =>
      controller.lapFraction
          .bind(
            (lapFraction) => controller.lastLapFraction.map(
              (lastLapFraction) =>
                  _LapAndLastLapFraction(lapFraction, lastLapFraction),
            ),
          )
          .build(
            builder: (context, fracs, child) => ClockRing(
              fraction: fracs.normalizedLap,
              markFraction: fracs.lastLapFraction,
              child: child,
            ),
            child: child,
          );

  Widget _paddingTransition(
    BuildContext context, {
    required Widget child,
  }) =>
      controller.hasLaps.build(
        builder: (context, hasPadding, child) =>
            TweenAnimationBuilder<EdgeInsetsGeometry>(
          tween: EdgeInsetsGeometryTween(
            end: hasPadding
                ? EdgeInsets.zero
                : FabSafeArea.fabPaddingFor(context),
          ),
          duration: kSizeAnimationDuration,
          builder: (context, padding, child) => Padding(
            padding: padding,
            child: child,
          ),
          child: child,
        ),
        child: child,
      );

  Widget _sizeTransition(
    BuildContext context, {
    required Widget child,
  }) =>
      _paddingTransition(
        context,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: SizedBox.square(
              dimension: FABGroup.kMaxHorizontalLayoutLargeWidth,
              child: child,
            ),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(4.0),
        child: _sizeTransition(
          context,
          child: _clockRing(
            context,
            child: child,
          ),
        ),
      );
}

const double kPaddingOverTheFAB = 24.0;
const Duration kSizeAnimationDuration = Duration(milliseconds: 300);

class _LapsListSection extends StatelessWidget {
  const _LapsListSection({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final StopwatchPageController controller;

  Widget _opacityAnimation(
    BuildContext context, {
    required bool isVisible,
    required Widget child,
  }) =>
      TweenAnimationBuilder<double>(
        duration: kSizeAnimationDuration,
        curve: const Interval(2 / 3, 1),
        tween: Tween(end: isVisible ? 1.0 : 0.0),
        builder: (context, opacity, child) => Opacity(
          opacity: opacity,
          child: child,
        ),
        child: child,
      );
  Widget _sizeAnimation(
    BuildContext context, {
    required bool isExpanded,
    required Widget child,
  }) =>
      TweenAnimationBuilder<double>(
        duration: kSizeAnimationDuration,
        tween: Tween(end: isExpanded ? 1.0 : 0.0),
        builder: (context, size, child) => size == 0.0
            ? const SizedBox(
                width: double.infinity,
                height: 0,
              )
            : _SizeTransitioned(
                axisAlignment: -1,
                sizeFactor: size,
                child: child,
              ),
        child: child,
      );

  @override
  Widget build(BuildContext context) => controller.hasLaps.build(
        builder: (context, hasLaps, child) => _opacityAnimation(
          context,
          isVisible: hasLaps,
          child: _sizeAnimation(
            context,
            isExpanded: hasLaps,
            child: child!,
          ),
        ),
        child: _LapsList(
          controller: controller,
        ),
      );
}

class _SizeTransitioned extends StatelessWidget {
  const _SizeTransitioned({
    Key? key,
    this.axis = Axis.vertical,
    required this.sizeFactor,
    this.axisAlignment = 0.0,
    this.child,
  })  : assert(axis != null),
        assert(sizeFactor != null),
        assert(axisAlignment != null),
        super(key: key);
  final Axis axis;
  final double sizeFactor;
  final double axisAlignment;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AlignmentDirectional alignment;
    if (axis == Axis.vertical)
      alignment = AlignmentDirectional(-1.0, axisAlignment);
    else
      alignment = AlignmentDirectional(axisAlignment, -1.0);
    return ClipRect(
      child: Align(
        alignment: alignment,
        heightFactor: axis == Axis.vertical ? max(sizeFactor, 0.0) : null,
        widthFactor: axis == Axis.horizontal ? max(sizeFactor, 0.0) : null,
        child: child,
      ),
    );
  }
}

class _FabScrim extends StatelessWidget {
  const _FabScrim({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          const Positioned(
            bottom: kPaddingOverTheFAB,
            left: 0,
            right: 0,
            child: FabScrim(),
          )
        ],
      );
}

class StopwatchPage extends StatelessWidget {
  const StopwatchPage({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final StopwatchPageController controller;

  Widget _buildPortrait(BuildContext context) => _FabScrim(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ClockRing(
              controller: controller,
              child: Center(
                child: _StopwatchDurationText(
                  controller: controller,
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: kPaddingOverTheFAB),
                child: _LapsListSection(controller: controller),
              ),
            ),
          ],
        ),
      );

  Widget _buildLandscape(BuildContext context) => Center(
        child: controller.hasLaps.build(
          builder: (context, hasLaps, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: hasLaps
                ? Center(
                    child: _LapsList(
                      controller: controller,
                      shrinkWrap: true,
                    ),
                  )
                : _StopwatchDurationText(controller: controller),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait
          ? _buildPortrait(context)
          : _buildLandscape(context);
}

class StopwatchPageFab extends StatelessWidget {
  const StopwatchPageFab({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final StopwatchPageController controller;

  @override
  Widget build(BuildContext context) => FABGroup(
        controller: controller.fabController,
        leftIcon: Icon(Icons.restart_alt),
        rightIcon: const Icon(Icons.timer_outlined),
      );
}
