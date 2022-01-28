import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../components/fab_group/controller.dart';
import '../../components/keypad/controller.dart';
import '../../utils/chrono.dart';

enum TimerSectionState {
  idle,
  running,
  paused,
  beeping,
}

class _AddSectionController extends ControllerBase with IConnectToAnFABGroup {
  final ValueNotifier<bool> _canCancel;
  final EventNotifier<TimeKeypadResult> _didStart = EventNotifier();
  final ActionNotifier _didCancel = ActionNotifier();
  final TimeKeypadController keypadController = TimeKeypadController.zero();

  _AddSectionController.from(bool canCancel)
      : _canCancel = ValueNotifier(canCancel);

  @override
  ValueListenable<bool> get showFabLeftIcon => _canCancel.view();
  ValueListenable<TimeKeypadResult> get didStart => _didStart.viewNexts();
  ValueListenable<void> get didCancel => _didCancel.view();
  @override
  ValueListenable<bool> get showFabRightIcon => SingleValueListenable(false);

  @override
  ValueListenable<CenterFABState> get centerFabState =>
      keypadController.isResultEmpty.map((isResultEmpty) =>
          isResultEmpty ? CenterFABState.hidden : CenterFABState.play);

  @override
  void onFabLeft() {
    _didCancel.notify();
  }

  @override
  void onFabRight() {
    assert(false);
  }

  @override
  void onFabCenter() => _didStart.add(keypadController.result.value);

  void setCanCancel(bool value) => _canCancel.value = value;

  void clear() => keypadController.onClear();

  @override
  void dispose() {
    IDisposable.disposeAll([
      _canCancel,
      _didCancel,
      keypadController,
      _didStart,
    ]);
    super.dispose();
  }
}

class TimerSectionController extends ControllerBase with IConnectToAnFABGroup {
  final ValueNotifier<TimerSectionState> _state;
  final Duration _timerDuration;
  final ValueNotifier<Duration> _elapsedTimerDuration;
  final ValueNotifier<Duration> _extraTime;
  final ActionNotifier _didPressAdd = ActionNotifier();
  final ActionNotifier _didDelete = ActionNotifier();
  // start the ticker paused
  late final StreamSubscription<Duration> _ticker =
      createTickerStream().listen(_onTick)..pause();
  // Late final because withInitial causes an side effect.
  late final ValueListenable<Duration> _totalDuration = extraTime.map(
    (extra) {
      final timerAndExtra = _timerDuration + extra;
      final timerWithExtraAndElapsed =
          timerAndExtra - elapsedTimerDuration.value;
      return timerWithExtraAndElapsed;
    },
  ).withInitial(_timerDuration);

  factory TimerSectionController.create(Duration timerDuration) =>
      TimerSectionController.from(
        timerDuration,
        Duration.zero,
        Duration.zero,
        TimerSectionState.idle,
      );

  TimerSectionController.from(
    this._timerDuration,
    Duration elapsedDuration,
    Duration extraTime,
    TimerSectionState state,
  )   : _state = ValueNotifier(state),
        _elapsedTimerDuration = ValueNotifier(elapsedDuration),
        _extraTime = ValueNotifier(extraTime) {
    init();
  }

  ValueListenable<TimerSectionState> get state => _state.view();
  Duration get timerDuration => _timerDuration;
  ValueListenable<Duration> get elapsedTimerDuration =>
      _elapsedTimerDuration.view();
  ValueListenable<Duration> get extraTime => _extraTime.view();
  ValueListenable<Duration> get totalDuration => _totalDuration.view();
  @override
  ValueListenable<bool> get showFabLeftIcon => SingleValueListenable(true);
  @override
  ValueListenable<bool> get showFabRightIcon => SingleValueListenable(true);
  ValueListenable<void> get didPressAdd => _didPressAdd.view();
  ValueListenable<void> get didDelete => _didDelete.view();

  ValueListenable<bool> get isOvershooting =>
      remainingTimerDuration.map((remaining) => remaining.isNegative).unique();
  ValueListenable<double> get elapsedDurationFrac => totalDuration.bind(
        (totalDuration) => elapsedTimerDuration.map(
            (elapsed) => elapsed.inMicroseconds / totalDuration.inMicroseconds),
      );
  ValueListenable<Duration> get remainingTimerDuration =>
      // TODO: binding to elapsed and mapping total does not work!!
      totalDuration.bind((totalDuration) => elapsedTimerDuration.map(
            (elapsed) => totalDuration - elapsed,
          ));
  @override
  ValueListenable<CenterFABState> get centerFabState => state.map(
        (state) {
          switch (state) {
            case TimerSectionState.paused:
            case TimerSectionState.idle:
              return CenterFABState.play;
            case TimerSectionState.running:
              return CenterFABState.pause;
            case TimerSectionState.beeping:
              return CenterFABState.stop;
          }
        },
      );

  @override
  void onFabLeft() {
    _didDelete.notify();
  }

  @override
  void onFabRight() {
    _didPressAdd.notify();
  }

  void onPause() {
    assert(state.value == TimerSectionState.running);
    _ticker.pause();
    _setState(TimerSectionState.paused);
  }

  void onResume() {
    assert(state.value == TimerSectionState.paused);
    _ticker.resume();
    print(' resumed ticker');
    _setState(TimerSectionState.running);
  }

  void onAddMinute() {
    _extraTime.value += const Duration(minutes: 1);
  }

  void onReset() {
    assert(state.value == TimerSectionState.paused ||
        state.value == TimerSectionState.beeping);
    _elapsedTimerDuration.value = Duration.zero;
    _extraTime.value = Duration.zero;
    _ticker.pause();
    _setState(TimerSectionState.idle);
  }

  void onStart() {
    assert(state.value == TimerSectionState.idle);
    _extraTime.value = Duration.zero;
    _ticker.resume();
    _setState(TimerSectionState.running);
  }

  void onStop() => onReset();

  @override
  void onFabCenter() {
    switch (state.value) {
      case TimerSectionState.idle:
        return onStart();
      case TimerSectionState.running:
        return onPause();
      case TimerSectionState.paused:
        return onResume();
      case TimerSectionState.beeping:
        return onStop();
    }
  }

  @override
  void init() {
    if (_state.value == TimerSectionState.running) {
      _ticker.resume();
    }
    isOvershooting.tap(_onIsOvershooting);
    super.init();
  }

  @override
  void dispose() {
    IDisposable.disposeAll([
      _didDelete,
      _didPressAdd,
      _state,
      _elapsedTimerDuration,
    ]);
    _ticker.cancel();
    super.dispose();
  }

  void _onIsOvershooting(bool isOvershooting) {
    if (isOvershooting) {
      _setState(TimerSectionState.beeping);
    }
  }

  void _setState(TimerSectionState state) => _state.value = state;
  void _onTick(Duration elapsedTime) {
    _elapsedTimerDuration.value += elapsedTime;
  }
}

class TimerPageController extends ControllerBase
    with FABGroupConnectionManagerMixin {
  final ListValueNotifier<TimerSectionController> _timers;
  final _AddSectionController _addSectionController;
  final ValueNotifier<bool> _showAddPage;
  final ValueNotifier<int?> _currentPage;
  final EventNotifier<int> _didMoveToSection = EventNotifier();

  @override
  final FABGroupController fabGroupController = FABGroupController.from(
    showLeftIcon: false,
    centerState: CenterFABState.hidden,
    showRightIcon: false,
  );

  factory TimerPageController() => TimerPageController.from([]);

  TimerPageController.from(List<TimerSectionController> controllers,
      [int? currentPage])
      : _timers = ListValueNotifier.of(controllers),
        _addSectionController =
            _AddSectionController.from(controllers.isNotEmpty),
        _showAddPage = ValueNotifier(controllers.isEmpty),
        _currentPage =
            ValueNotifier(controllers.isEmpty ? null : (currentPage ?? 0)) {
    init();
  }

  ValueListenable<UnmodifiableListView<TimerSectionController>> get timers =>
      _timers.view();
  _AddSectionController get addSectionController => _addSectionController;
  ValueListenable<bool> get showAddPage => _showAddPage.view();
  ValueListenable<int?> get currentPage => _currentPage.view();
  ValueListenable<int> get didMoveToSection => _didMoveToSection.viewNexts();

  void onPageChange(int currentPage) => _currentPage.value = currentPage;

  late final MergingIDisposable _bindings;

  @override
  void init() {
    super.init();
    for (final controller in _timers) {
      _registerTimer(controller);
    }
    _bindings = IDisposable.merge([
      _hasTimers.tap(_addSectionController.setCanCancel),
      _addSectionController.didCancel.listen(_onCancelAdd),
      _addSectionController.didStart.tap(_onStartAdded),
      _currentlyConnectedToTheFab.tap(connectFabTo, includeInitial: true)
    ]);
  }

  @override
  void dispose() {
    disposeFabConnection();
    IDisposable.disposeAll([
      _bindings,
      _timers,
      _currentPage,
      _addSectionController,
      _didMoveToSection,
    ]);
    super.dispose();
  }

  ValueListenable<bool> get _hasTimers =>
      timers.map((timers) => timers.isNotEmpty);

  ValueListenable<TimerSectionController?> get _currentSection =>
      timers.bind((timers) =>
          currentPage.map((page) => page == null ? null : timers[page]));

  ValueListenable<IConnectToAnFABGroup> get _currentlyConnectedToTheFab =>
      _currentSection
          .bind(
            (currentSection) => showAddPage.map((showAddPage) =>
                showAddPage ? _addSectionController : currentSection!),
          )
          .unique()
          .cast();

  void _registerTimer(TimerSectionController timer) {
    // No need to add it to be disposed because when the parent object (timer)
    // is disposed, the views to it are rendered useless.
    timer.didDelete.listen(() => _onDelete(timer));
    timer.didPressAdd.listen(_onAdd);
  }

  void _onAdd() {
    _showAddPage.value = true;
    _addSectionController.clear();
  }

  void _onCancelAdd() {
    _showAddPage.value = false;
    _addSectionController.clear();
  }

  void _onStartAdded(TimeKeypadResult result) {
    final timerDuration = result.toDuration();
    final timerController = TimerSectionController.create(timerDuration);
    _registerTimer(timerController);
    timerController.onStart();
    _addAndSetToTimer(timerController);
    // set it last because otherwise we would fail an null assert
    // when adding the first timer.
    _showAddPage.value = false;
  }

  void _addAndSetToTimer(TimerSectionController timer) {
    _timers.add(timer);
    final targetPage = _timers.length - 1;
    print(targetPage);
    // Already set it because the view is expected to instantly move to the view
    _currentPage.value = targetPage;
    _didMoveToSection.add(targetPage);
  }

  void _onDelete(TimerSectionController timer) {
    // Wrap everything in a mutate block so that notify listeners is called only
    // after the other state
    _timers.mutate((timers) {
      final index = timers.indexOf(timer);
      timers.removeAt(index);
      if (timers.isEmpty) {
        _currentPage.value = null;
        _showAddPage.value = true;
        _addSectionController.clear();
      } else {
        _currentPage.value = _currentPage.value! >= index
            ? _currentPage.value! - 1
            : _currentPage.value;
      }
    });
    timer.dispose();
  }
}
