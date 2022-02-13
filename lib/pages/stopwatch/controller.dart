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

enum StopwatchState {
  idle,
  running,
  paused,
}

class StopwatchPageController extends ControllerBase<StopwatchPageController> {
  final ValueNotifier<StopwatchState> _state;
  final ListValueNotifier<Lap> _laps;
  final ValueNotifier<Duration> _totalElapsedTime;
  final ValueNotifier<Duration> _lapElapsedTime;
  final FABGroupController fabController = FABGroupController.from(
    showLeftIcon: false,
    centerState: CenterFABState.play,
    showRightIcon: false,
  );
  final ITick _ticker;

  factory StopwatchPageController(ITick ticker) => StopwatchPageController.from(
        StopwatchState.idle,
        Duration.zero,
        Duration.zero,
        ticker,
      );

  StopwatchPageController.from(
    StopwatchState state,
    Duration totalElapsedTime,
    Duration lapElapsedTime,
    ITick ticker,
  )   : _state = ValueNotifier(state),
        _laps = ListValueNotifier.empty(),
        _totalElapsedTime = ValueNotifier(totalElapsedTime),
        _lapElapsedTime = ValueNotifier(lapElapsedTime),
        _ticker = ticker;

  ValueListenable<StopwatchState> get state => _state.view();
  ValueListenable<UnmodifiableListView<Lap>> get laps => _laps.view();
  ValueListenable<Duration> get totalElapsedTime => _totalElapsedTime.view();
  ValueListenable<Duration> get lapElapsedTime => _lapElapsedTime.view();
  ValueListenable<Lap> get currentLap => _currentLap.view();

  ValueListenable<bool> get hasLaps =>
      laps.map((laps) => laps.isNotEmpty).unique();
  ValueListenable<CenterFABState> get fabCenterState => state.map((state) {
        switch (state) {
          case StopwatchState.idle:
          case StopwatchState.paused:
            return CenterFABState.play;
          case StopwatchState.running:
            return CenterFABState.pause;
        }
      });
  ValueListenable<double?> get lapFraction => currentLap
      .map((l) => _firstLapDuration == null
          ? null
          : l.duration.inMicroseconds / _firstLapDuration!.inMicroseconds)
      .unique();
  ValueListenable<double?> get lastLapFraction => laps.map(
        (laps) => laps.length <= 1
            ? null
            : laps.last.duration.inMicroseconds /
                _firstLapDuration!.inMicroseconds,
      );
  ValueListenable<bool> get canReset =>
      state.map((state) => state != StopwatchState.idle);
  ValueListenable<bool> get canAddLap =>
      state.map((state) => state == StopwatchState.running);

  void onReset() {
    assert(_state.value != StopwatchState.idle);
    _ticker.pause();
    _lapElapsedTime.value = Duration.zero;
    _totalElapsedTime.value = Duration.zero;
    _laps.clear();
    _setState(StopwatchState.idle);
  }

  void onAddLap() {
    final lap = currentLap.value;
    _lapElapsedTime.value = Duration.zero;
    _laps.add(lap);
  }

  void onStart() {
    assert(_state.value == StopwatchState.idle);
    _ticker.resume();
    _setState(StopwatchState.running);
  }

  void onPause() {
    assert(_state.value == StopwatchState.running);
    _ticker.pause();
    _setState(StopwatchState.paused);
  }

  void onResume() {
    assert(_state.value == StopwatchState.paused);
    _ticker.resume();
    _setState(StopwatchState.running);
  }

  @override
  void init() {
    super.init();
    fabController.didPressCenter.listen(_onFabCenter);
    fabController.didPressLeft.listen(onReset);
    fabController.didPressRight.listen(onAddLap);
    fabCenterState.tap(fabController.setCenterState, includeInitial: true);
    canReset.tap(fabController.setShowLeftIcon, includeInitial: true);
    canAddLap.tap(fabController.setShowRightIcon, includeInitial: true);
    _ticker.elapsedTick.tap(_onTick);
    _ticker.start(paused: true);
  }

  @override
  void dispose() {
    IDisposable.disposeAll([
      _state,
      _laps,
      _totalElapsedTime,
      _lapElapsedTime,
      _currentLap,
      fabController,
      _ticker
    ]);
    super.dispose();
  }

  // Use it as an late final because this particular [ValueListenable] can have
  // many listeners, and it is relatively expensive because of the bind calls
  // and very frequent updates.
  late final ValueListenable<Lap> _currentLap =
      laps.map((laps) => laps.length).bind(
            (number) => totalElapsedTime.bind(
              (totalElapsedTime) => lapElapsedTime.map(
                (lapElapsedTime) => Lap(
                  number + 1,
                  lapElapsedTime,
                  totalElapsedTime,
                ),
              ),
            ),
          );

  Duration? get _firstLapDuration =>
      _laps.isEmpty ? null : _laps.first.duration;

  void _onTick(Duration elapsed) {
    _totalElapsedTime.value += elapsed;
    _lapElapsedTime.value += elapsed;
  }

  void _setState(StopwatchState state) => _state.value = state;
  void _onFabCenter() {
    switch (_state.value) {
      case StopwatchState.idle:
        return onStart();
      case StopwatchState.running:
        return onPause();
      case StopwatchState.paused:
        return onResume();
    }
  }
}
