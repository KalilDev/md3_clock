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

class AddSectionController
    extends SubcontrollerBase<TimerPageController, AddSectionController>
    with IConnectToAnFABGroup {
  final ValueNotifier<bool> _canCancel;
  final EventNotifier<TimeKeypadResult> _didStart = EventNotifier();
  final ActionNotifier _didCancel = ActionNotifier();
  final TimeKeypadController _keypadController = TimeKeypadController.zero();

  AddSectionController.from(
    bool canCancel,
  ) : _canCancel = ValueNotifier(canCancel);

  ControllerHandle<TimeKeypadController> get keypadController =>
      _keypadController.handle;

  @override
  ValueListenable<bool> get showFabLeftIcon => _canCancel.view();
  ValueListenable<TimeKeypadResult> get didStart => _didStart.viewNexts();
  ValueListenable<void> get didCancel => _didCancel.view();
  @override
  ValueListenable<bool> get showFabRightIcon => SingleValueListenable(false);

  @override
  ValueListenable<CenterFABState> get centerFabState =>
      _keypadController.isResultEmpty.map((isResultEmpty) =>
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
  void onFabCenter() => _didStart.add(_keypadController.result.value);

  void setCanCancel(bool value) => _canCancel.value = value;

  void clear() => _keypadController.onClear();

  @override
  void dispose() {
    IDisposable.disposeAll([
      _canCancel,
      _didCancel,
      _keypadController,
      _didStart,
    ]);
    super.dispose();
  }
}

class _ActiveTimerSectionInfo {
  final int? currentPage;
  final bool showAddPage;

  _ActiveTimerSectionInfo(this.currentPage, this.showAddPage);
  _ActiveTimerSectionInfo withCurrentPage(int? currentPage) =>
      _ActiveTimerSectionInfo(currentPage, showAddPage);
  _ActiveTimerSectionInfo withShowAddPage(bool showAddPage) =>
      _ActiveTimerSectionInfo(currentPage, showAddPage);
  int get hashCode => Object.hashAll([
        currentPage,
        showAddPage,
      ]);
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is _ActiveTimerSectionInfo) {
      return true &&
          currentPage == other.currentPage &&
          showAddPage &&
          other.showAddPage;
    }
    return false;
  }
}

class TimerSectionController
    extends SubcontrollerBase<TimerPageController, TimerSectionController>
    implements IConnectToAnFABGroup {
  final ValueNotifier<TimerSectionState> _state;
  final Duration _timerDuration;
  final ValueNotifier<Duration> _elapsedTimerDuration;
  final ValueNotifier<Duration> _extraTime;
  final ActionNotifier _didPressAdd = ActionNotifier();
  final ActionNotifier _didDelete = ActionNotifier();
  final ITick _ticker;
  // Late final because withInitial causes an side effect.
  late final ValueListenable<Duration> _totalDuration = extraTime.map(
    (extra) {
      final timerAndExtra = _timerDuration + extra;
      final timerWithExtraAndElapsed =
          timerAndExtra - elapsedTimerDuration.value;
      return timerWithExtraAndElapsed;
    },
  ).withInitial(_timerDuration);

  factory TimerSectionController.create(
    Duration timerDuration,
    ITick ticker,
  ) =>
      TimerSectionController.from(
        timerDuration,
        Duration.zero,
        Duration.zero,
        TimerSectionState.idle,
        ticker,
      );

  TimerSectionController.from(
    this._timerDuration,
    Duration elapsedDuration,
    Duration extraTime,
    TimerSectionState state,
    ITick ticker,
  )   : _state = ValueNotifier(state),
        _elapsedTimerDuration = ValueNotifier(elapsedDuration),
        _extraTime = ValueNotifier(extraTime),
        _ticker = ticker {
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
    _ticker.elapsedTick.tap(_onTick);
    isOvershooting.tap(_onIsOvershooting);
    _ticker.start(paused: _state.value != TimerSectionState.running);
    super.init();
  }

  @override
  void dispose() {
    IDisposable.disposeAll([
      _didDelete,
      _didPressAdd,
      _state,
      _elapsedTimerDuration,
      _ticker,
    ]);
    super.dispose();
  }

  void _onIsOvershooting(bool isOvershooting) {
    if (isOvershooting) {
      _setState(TimerSectionState.beeping);
      return;
    }
    if (_state.value == TimerSectionState.beeping) {
      _setState(TimerSectionState.running);
    }
  }

  void _setState(TimerSectionState state) => _state.value = state;
  void _onTick(Duration elapsedTime) {
    final elapsedTimer = _elapsedTimerDuration.value;
    final elapsedWithTick = elapsedTimer + elapsedTime;
    _elapsedTimerDuration.value = elapsedWithTick;
  }
}

class TimerPageController extends ControllerBase<TimerPageController>
    with FABGroupConnectionManagerMixin {
  final ListValueNotifier<TimerSectionController> __timers;
  late final AddSectionController _addSectionController;
  final ValueNotifier<_ActiveTimerSectionInfo> _activeTimerSectionInfo;
  final EventNotifier<int> _didMoveToSection = EventNotifier();
  final ICreateTickers _tickerFactory;

  @override
  late final FABGroupController fabGroupController = addChild(
    FABGroupController.from(
      showLeftIcon: false,
      centerState: CenterFABState.hidden,
      showRightIcon: false,
    ),
  );

  factory TimerPageController({
    required ICreateTickers vsync,
  }) =>
      TimerPageController.from(
        [],
        vsync: vsync,
      );

  TimerPageController.from(
    List<TimerSectionController> controllers, {
    int? currentPage,
    required ICreateTickers vsync,
  })  : __timers = ListValueNotifier.of(controllers),
        _activeTimerSectionInfo = ValueNotifier(_ActiveTimerSectionInfo(
          controllers.isEmpty ? null : (currentPage ?? 0),
          controllers.isEmpty,
        )),
        _tickerFactory = vsync {
    _addSectionController =
        addSubcontroller(AddSectionController.from(controllers.isNotEmpty));
    init();
  }

  ValueListenable<UnmodifiableListView<TimerSectionController>> get _timers =>
      __timers.view();
  ValueListenable<
          UnmodifiableListView<ControllerHandle<TimerSectionController>>>
      get timerControllers => __timers.view().map(
            (e) => UnmodifiableListView(
              e.map((e) => e.handle).toList(),
            ),
          );
  ControllerHandle<AddSectionController> get addSectionController =>
      _addSectionController.handle;
  ValueListenable<int> get didMoveToSection => _didMoveToSection.viewNexts();

  ValueListenable<bool> get showAddPage =>
      _activeTimerSectionInfo.view().map((info) => info.showAddPage);
  ValueListenable<int?> get currentPage =>
      _activeTimerSectionInfo.view().map((info) => info.currentPage);

  void onPageChange(int currentPage) => _activeTimerSectionInfo.value =
      _activeTimerSectionInfo.value.withCurrentPage(currentPage);

  late final MergingIDisposable _bindings;

  @override
  void init() {
    super.init();
    for (final controller in __timers) {
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
      __timers,
      _activeTimerSectionInfo,
      _addSectionController,
      _didMoveToSection,
    ]);
    super.dispose();
  }

  ValueListenable<bool> get _hasTimers =>
      _timers.map((timers) => timers.isNotEmpty);

  ValueListenable<ControllerHandle<TimerSectionController>?>
      get _currentSection => _timers.bind((timers) =>
          currentPage.map((page) => page == null ? null : timers[page].handle));

  ValueListenable<IConnectToAnFABGroup> get _currentlyConnectedToTheFab =>
      _currentSection
          .bind(
            (currentSection) => showAddPage.map((showAddPage) =>
                showAddPage ? _addSectionController : currentSection!.unwrap),
          )
          .unique()
          .castNotNull()
          .cast();

  void _registerTimer(TimerSectionController timer) {
    registerSubcontroller(timer);
    // No need to add it to be disposed because when the parent object (timer)
    // is disposed, the views to it are rendered useless.
    timer.didDelete.listen(() => _onDelete(timer));
    timer.didPressAdd.listen(_onAdd);
  }

  void _onAdd() {
    _activeTimerSectionInfo.value =
        _activeTimerSectionInfo.value.withShowAddPage(true);
    _addSectionController.clear();
  }

  void _onCancelAdd() {
    _activeTimerSectionInfo.value =
        _activeTimerSectionInfo.value.withShowAddPage(false);
    _addSectionController.clear();
  }

  void _onStartAdded(TimeKeypadResult result) {
    final timerDuration = result.toDuration();
    final timerController = TimerSectionController.create(
      timerDuration,
      _tickerFactory.createTicker(),
    );
    _registerTimer(timerController);
    timerController.onStart();
    _addAndSetToTimer(timerController);
  }

  void _addAndSetToTimer(TimerSectionController timer) {
    __timers.add(timer);
    final targetPage = __timers.length - 1;
    // Already set it because the view is expected to instantly move to the view
    _activeTimerSectionInfo.value = _ActiveTimerSectionInfo(targetPage, false);
    _didMoveToSection.add(targetPage);
  }

  void _onDelete(TimerSectionController timer) {
    // Wrap everything in a mutate block so that notify listeners is called only
    // after the other state
    __timers.mutate((timers) {
      final index = timers.indexOf(timer);
      if (timers.isEmpty) {
        _activeTimerSectionInfo.value = _ActiveTimerSectionInfo(null, true);
        _addSectionController.clear();
      } else {
        final currentPage = _activeTimerSectionInfo.value.currentPage;
        final targetPage =
            currentPage! >= index ? currentPage - 1 : currentPage;
        _activeTimerSectionInfo.value =
            _activeTimerSectionInfo.value.withCurrentPage(targetPage);
      }
    });
    timer.dispose();
  }
}
