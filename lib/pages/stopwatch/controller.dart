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

class StopwatchPageController extends IDisposableBase {
  final ValueNotifier<StopwatchState> _state;
  ValueListenable<StopwatchState> get state => _state.view();
  factory StopwatchPageController() => StopwatchPageController.from(
        StopwatchState.idle,
        Duration.zero,
        Duration.zero,
      );

  StopwatchPageController.from(
    StopwatchState state,
    Duration totalElapsedTime,
    Duration lapElapsedTime,
  )   : _state = ValueNotifier(state),
        _laps = ValueNotifier([]),
        _totalElapsedTime = ValueNotifier(totalElapsedTime),
        _lapElapsedTime = ValueNotifier(lapElapsedTime) {
    init();
  }

  void init() {
    fabController.didPressCenter.listen(_onFabCenter);
    fabController.didPressLeft.listen(onReset);
    fabController.didPressRight.listen(onAddLap);
    fabCenterState.tap(fabController.setCenterState, includeInitial: true);
    canReset.tap(fabController.setShowLeftIcon, includeInitial: true);
    canAddLap.tap(fabController.setShowRightIcon, includeInitial: true);
  }

  ValueListenable<CenterFABState> get fabCenterState => state.map((state) {
        switch (state) {
          case StopwatchState.idle:
          case StopwatchState.paused:
            return CenterFABState.play;
          case StopwatchState.running:
            return CenterFABState.pause;
        }
      });

  late final ValueListenable<Lap> _currentLap =
      laps.map((laps) => laps.length).bind(
            (number) => totalElapsedTime.bind(
              (totalElapsedTime) => lapElapsedTime.map(
                (lapElapsedTime) => Lap(
                  number,
                  lapElapsedTime,
                  totalElapsedTime,
                ),
              ),
            ),
          );

  ValueListenable<Lap> get currentLap => _currentLap.view();

  Duration? get _firstLapDuration =>
      _laps.value.isEmpty ? null : _laps.value.first.duration;

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
    ticker.pause();
    _lapElapsedTime.value = Duration.zero;
    _totalElapsedTime.value = Duration.zero;
    _laps.value.clear();
    _laps.notifyListeners();
    _setState(StopwatchState.idle);
  }

  void onAddLap() {
    final lap = currentLap.value;
    _lapElapsedTime.value = Duration.zero;
    _laps.value.add(lap);
    _laps.notifyListeners();
  }

  void onStart() {
    assert(_state.value == StopwatchState.idle);
    ticker.resume();
    _setState(StopwatchState.running);
  }

  void onPause() {
    assert(_state.value == StopwatchState.running);
    ticker.pause();
    _setState(StopwatchState.paused);
  }

  void onResume() {
    assert(_state.value == StopwatchState.paused);
    ticker.resume();
    _setState(StopwatchState.running);
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

  final ValueNotifier<Duration> _totalElapsedTime;
  ValueListenable<Duration> get totalElapsedTime => _totalElapsedTime.view();
  final ValueNotifier<Duration> _lapElapsedTime;
  ValueListenable<Duration> get lapElapsedTime => _lapElapsedTime.view();

  void _onTick(Duration elapsed) {
    _totalElapsedTime.value += elapsed;
    _lapElapsedTime.value += elapsed;
  }

  // start the ticker paused
  late final StreamSubscription<Duration> ticker =
      createTickerStream().listen(_onTick)..pause();

  final FABGroupController fabController = FABGroupController.from(
    false,
    false,
    CenterFABState.play,
  );

  final ValueNotifier<List<Lap>> _laps;

  ValueListenable<UnmodifiableListView<Lap>> get laps =>
      _laps.view().map(UnmodifiableListView.new);

  ValueListenable<bool> get hasLaps =>
      laps.map((laps) => laps.isNotEmpty).unique();
}
