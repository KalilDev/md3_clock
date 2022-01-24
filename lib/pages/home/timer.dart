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

import '../../model/duration_components.dart';
import '../../utils/chrono.dart';
import '../../widgets/blinking.dart';
import '../../widgets/clock_ring.dart';
import '../../widgets/duration.dart';
import '../../widgets/fab_safe_area.dart';
import 'keypad.dart';

enum TimerSectionState {
  idle,
  running,
  paused,
  beeping,
}

class _AddSectionController extends IDisposableBase with IConnectToAnFABGroup {
  _AddSectionController.from(bool canCancel)
      : _canCancel = ValueNotifier(canCancel);

  final ValueNotifier<bool> _canCancel;
  final TimeKeypadController keypadController = TimeKeypadController.zero();

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

  @override
  ValueListenable<bool> get showFabLeftIcon => _canCancel.view();

  @override
  ValueListenable<bool> get showFabRightIcon => SingleValueListenable(false);

  final ActionNotifier _didCancel = ActionNotifier();
  ValueListenable<void> get didCancel => _didCancel.view();

  final EventNotifier<TimeKeypadResult> _didStart = EventNotifier();
  ValueListenable<TimeKeypadResult> get didStart => _didStart.viewNexts();

  void clear() => keypadController.onClear();

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

class _TimerSectionController extends IDisposableBase
    with IConnectToAnFABGroup {
  factory _TimerSectionController.create(Duration timerDuration) =>
      _TimerSectionController.from(
        timerDuration,
        Duration.zero,
        Duration.zero,
        TimerSectionState.idle,
      );

  _TimerSectionController.from(
    this._timerDuration,
    Duration elapsedDuration,
    Duration extraTime,
    TimerSectionState state,
  )   : _state = ValueNotifier(state),
        _elapsedTimerDuration = ValueNotifier(elapsedDuration),
        _extraTime = ValueNotifier(extraTime) {
    if (state == TimerSectionState.running) {
      ticker.resume();
    }
    isOvershooting.tap(_onIsOvershooting);
  }

  void _onIsOvershooting(bool isOvershooting) {
    if (isOvershooting) {
      _setState(TimerSectionState.beeping);
    }
  }

  final ValueNotifier<TimerSectionState> _state;
  ValueListenable<TimerSectionState> get state => _state.view();
  final Duration _timerDuration;
  final ValueNotifier<Duration> _elapsedTimerDuration;
  Duration get timerDuration => _timerDuration;
  ValueListenable<Duration> get elapsedTimerDuration =>
      _elapsedTimerDuration.view();
  ValueListenable<Duration> get remainingTimerDuration =>
      // TODO: binding to elapsed and mapping total does not work!!
      totalDuration.bind((totalDuration) => elapsedTimerDuration.map(
            (elapsed) => totalDuration - elapsed,
          ));

  final ValueNotifier<Duration> _extraTime;
  ValueListenable<Duration> get extraTime => _extraTime.view();

  // Late final because withInitial causes an side effect.
  late final ValueListenable<Duration> _totalDuration = extraTime.map(
    (extra) {
      final timerAndExtra = _timerDuration + extra;
      final timerWithExtraAndElapsed =
          timerAndExtra - elapsedTimerDuration.value;
      return timerWithExtraAndElapsed;
    },
  ).withInitial(_timerDuration);
  ValueListenable<Duration> get totalDuration => _totalDuration.view();
  ValueListenable<bool> get isOvershooting =>
      remainingTimerDuration.map((remaining) => remaining.isNegative).unique();
  ValueListenable<double> get elapsedDurationFrac => totalDuration.bind(
        (totalDuration) => elapsedTimerDuration.map(
            (elapsed) => elapsed.inMicroseconds / totalDuration.inMicroseconds),
      );

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

  void _setState(TimerSectionState state) => _state.value = state;

  void onPause() {
    assert(state.value == TimerSectionState.running);
    ticker.pause();
    _setState(TimerSectionState.paused);
  }

  void onResume() {
    assert(state.value == TimerSectionState.paused);
    ticker.resume();
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
    // TODO: why the fuck is setting this to zero breaking the ticker???????
    _extraTime.value = Duration.zero;
    ticker.pause();
    _setState(TimerSectionState.idle);
  }

  void onStart() {
    assert(state.value == TimerSectionState.idle);
    _extraTime.value = Duration.zero;
    ticker.resume();
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

  void _onTick(Duration elapsedTime) {
    _elapsedTimerDuration.value += elapsedTime;
  }

  // start the ticker paused
  late final StreamSubscription<Duration> ticker =
      createTickerStream().listen(_onTick)..pause();

  @override
  ValueListenable<bool> get showFabLeftIcon => SingleValueListenable(true);

  @override
  ValueListenable<bool> get showFabRightIcon => SingleValueListenable(true);

  final ActionNotifier _didPressAdd = ActionNotifier();
  ValueListenable<void> get didPressAdd => _didPressAdd.view();

  final ActionNotifier _didDelete = ActionNotifier();
  ValueListenable<void> get didDelete => _didDelete.view();

  void dispose() {
    IDisposable.disposeAll([
      _didDelete,
      _didPressAdd,
      _state,
      _elapsedTimerDuration,
    ]);
    ticker.cancel();
    super.dispose();
  }
}

class TimerPageController extends IDisposableBase
    with FABGroupConnectionManagerMixin {
  factory TimerPageController() => TimerPageController.from([]);
  TimerPageController.from(List<_TimerSectionController> controllers,
      [int? currentPage])
      : __timers = ValueNotifier(controllers),
        _addSectionController =
            _AddSectionController.from(controllers.isNotEmpty),
        _showAddPage = ValueNotifier(controllers.isEmpty),
        _currentPage =
            ValueNotifier(controllers.isEmpty ? null : (currentPage ?? 0)) {
    init();
  }

  // This is already owned by [_timers], only use this as an writable view to
  // the list.
  final ValueNotifier<List<_TimerSectionController>> __timers;
  late final ValueListenable<UnmodifiableListView<_TimerSectionController>>
      _timers = __timers.map(UnmodifiableListView.new);
  ValueListenable<UnmodifiableListView<_TimerSectionController>> get timers =>
      _timers.view();
  ValueListenable<bool> get _hasTimers =>
      _timers.view().map((timers) => timers.isNotEmpty);

  final ValueNotifier<bool> _showAddPage;
  ValueListenable<bool> get showAddPage => _showAddPage.view();

  final _AddSectionController _addSectionController;
  _AddSectionController get addSectionController => _addSectionController;

  void _registerTimer(_TimerSectionController timer) {
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
    final timerController = _TimerSectionController.create(timerDuration);
    _registerTimer(timerController);
    timerController.onStart();
    _addAndSetToTimer(timerController);
    // set it last because otherwise we would fail an null assert
    // when adding the first timer.
    _showAddPage.value = false;
  }

  void _addAndSetToTimer(_TimerSectionController timer) {
    __timers.value.add(timer);
    __timers.notifyListeners();
    final targetPage = __timers.value.length - 1;
    print(targetPage);
    // Already set it because the view is expected to instantly move to the view
    _currentPage.value = targetPage;
    _didMoveToSection.add(targetPage);
  }

  final ValueNotifier<int?> _currentPage;
  ValueListenable<_TimerSectionController?> get _currentSection =>
      timers.bind((timers) => _currentPage
          .view()
          .map((page) => page == null ? null : timers[page]));

  ValueListenable<IConnectToAnFABGroup> get _currentlyConnectedToTheFab =>
      _currentSection
          .view()
          .bind(
            (currentSection) => showAddPage.map((showAddPage) =>
                showAddPage ? _addSectionController : currentSection!),
          )
          .unique()
          .cast();

  void onPageChange(int currentPage) => _currentPage.value = currentPage;

  final EventNotifier<int> _didMoveToSection = EventNotifier();
  ValueListenable<int> get didMoveToSection => _didMoveToSection.viewNexts();

  void _onDelete(_TimerSectionController timer) {
    final timers = __timers.value;
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
    __timers.notifyListeners();
    timer.dispose();
  }

  late final MergingIDisposable _bindings;
  void init() {
    for (final controller in __timers.value) {
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
  final FABGroupController fabGroupController = FABGroupController.from(
    false,
    false,
    CenterFABState.hidden,
  );

  void dispose() {
    disposeFabConnection();
    _bindings.dispose();
    IDisposable.disposeAll([
      _timers,
      _currentPage,
      _currentSection,
      _currentlyConnectedToTheFab,
      _addSectionController,
      _didMoveToSection,
      _hasTimers,
    ]);
    super.dispose();
  }
}

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
    final initialPage = widget.controller._currentPage.value!;
    _pageController = PageController(
      initialPage: widget.controller._currentPage.value!,
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

  Widget _buildTimer(BuildContext cotext, _TimerSectionController timer) =>
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

  final _TimerSectionController controller;

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

  final _TimerSectionController controller;

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

  final _TimerSectionController controller;
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
          controller: controller.addSectionController.keypadController));
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
